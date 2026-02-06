import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Configuration
const POLL_INTERVAL_SECONDS = parseInt(Deno.env.get("POLL_INTERVAL_SECONDS") || "10");
const BATCH_SIZE = parseInt(Deno.env.get("BATCH_SIZE") || "10");
const MAX_RETRIES = parseInt(Deno.env.get("MAX_RETRIES") || "3");
const VISIBILITY_TIMEOUT = 300; // 5 minutes

// Process a single webhook job
async function processJob(
  supabase: ReturnType<typeof createClient>,
  job: { msg_id: number; message: any },
  webhookUrl: string,
): Promise<{ success: boolean; shouldRetry: boolean }> {
  const { type, requestId, formData, organizerTag } = job.message;

  try {
    if (type !== "pending_application") {
      console.error(`Unknown webhook job type: ${type}`);
      return { success: false, shouldRetry: false }; // Don't retry unknown types
    }

    // Build webhook payload
    const payload = {
      event: "pending_application_created",
      request_id: requestId,
      email: formData.email,
      first_name: formData.firstName,
      surname: formData.surname,
      organizer_tag: organizerTag,
      phone: formData.phone,
      province: formData.province,
      associations: formData.associations,
      wants_student_club: formData.wantsStudentClub,
      campus_club: formData.campusClub,
      created_at: new Date().toISOString(),
    };

    // Send webhook request
    const response = await fetch(webhookUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const errorText = await response.text().catch(() => "Unknown error");
      console.error(`Webhook request failed for job ${job.msg_id}:`, {
        status: response.status,
        statusText: response.statusText,
        error: errorText,
      });

      // Retry on 5xx errors (server errors), don't retry on 4xx (client errors)
      const shouldRetry = response.status >= 500;
      return { success: false, shouldRetry };
    }

    return { success: true, shouldRetry: false };
  } catch (error) {
    console.error(`Error processing webhook job ${job.msg_id}:`, error);
    // Retry on network errors
    return { success: false, shouldRetry: true };
  }
}

// Main handler
serve(async (req) => {
  try {
    // Get environment variables
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const webhookUrl = Deno.env.get("PENDING_APPLICATION_WEBHOOK_URL");

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({
          error: "Missing required environment variables: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY",
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Webhook URL is optional - if not set, skip processing
    if (!webhookUrl) {
      return new Response(
        JSON.stringify({
          message: "PENDING_APPLICATION_WEBHOOK_URL not configured, skipping webhook processing",
          processed: 0,
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Initialize Supabase client
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Read jobs from queue
    const { data: jobs, error: readError } = await supabase.rpc("pgmq_read_webhook_jobs", {
      queue_name: "webhook_send",
      vt: VISIBILITY_TIMEOUT,
      qty: BATCH_SIZE,
    });

    if (readError) {
      console.error("Error reading jobs from queue:", readError);
      return new Response(
        JSON.stringify({
          error: "Failed to read jobs from queue",
          details: readError.message,
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    if (!jobs || jobs.length === 0) {
      return new Response(
        JSON.stringify({
          message: "No jobs to process",
          processed: 0,
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Process each job
    const results = {
      processed: 0,
      succeeded: 0,
      failed: 0,
      archived: 0,
      retried: 0,
    };

    for (const job of jobs) {
      const result = await processJob(supabase, job, webhookUrl);

      if (result.success) {
        // Archive successful job
        await supabase.rpc("pgmq_archive_webhook_job", {
          queue_name: "webhook_send",
          msg_id_param: job.msg_id,
        });
        results.succeeded++;
        results.archived++;
      } else if (result.shouldRetry) {
        // For retry logic, PGMQ handles retries via visibility timeout
        // Jobs that fail but should be retried are not deleted/archived
        // They will become visible again after the visibility timeout expires
        results.retried++;
      } else {
        // Don't retry - delete the job
        await supabase.rpc("pgmq_delete_webhook_job", {
          queue_name: "webhook_send",
          msg_id_param: job.msg_id,
        });
        results.failed++;
      }

      results.processed++;
    }

    return new Response(
      JSON.stringify({
        message: "Jobs processed",
        ...results,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        details: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      },
    );
  }
});

