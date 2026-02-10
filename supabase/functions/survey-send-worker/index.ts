import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Configuration
const POLL_INTERVAL_SECONDS = parseInt(Deno.env.get("POLL_INTERVAL_SECONDS") || "10");
const BATCH_SIZE = parseInt(Deno.env.get("BATCH_SIZE") || "10");
const MAX_RETRIES = parseInt(Deno.env.get("MAX_RETRIES") || "3");
const VISIBILITY_TIMEOUT = 300; // 5 minutes

// Helper function to escape HTML
function escapeHtml(text: string | null | undefined): string {
  if (!text) return "";
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

// Helper function to format date
function formatDate(dateString: string): string {
  try {
    const date = new Date(dateString);
    return date.toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  } catch {
    return dateString;
  }
}

// Send survey invite email via Resend
async function sendSurveyInviteEmail(params: {
  survey: { title: string; description: string | null };
  instance: { expires_at: string | null };
  contact: { firstname: string | null; email: string };
  sender: { first_name: string; surname: string };
  surveyUrl: string;
  resendApiKey: string;
}): Promise<{ success: boolean; error?: string }> {
  if (!params.contact.email) {
    return { success: false, error: "Contact does not have an email address." };
  }

  const contactName = params.contact.firstname || "Valued Contact";
  const senderName = `${params.sender.first_name} ${params.sender.surname}`;
  const surveyUrl = params.surveyUrl;

  const expiresAtText = params.instance.expires_at
    ? `This survey expires on ${formatDate(params.instance.expires_at)}.`
    : "";

  // Build HTML email
  const html = `
    <p>Hi ${escapeHtml(contactName)},</p>
    <p>${escapeHtml(senderName)} has invited you to complete a survey.</p>
    <h2>${escapeHtml(params.survey.title)}</h2>
    ${params.survey.description ? `<p>${escapeHtml(params.survey.description)}</p>` : ""}
    <p>Please visit the following link to take the survey:</p>
    <p><a href="${surveyUrl}">${surveyUrl}</a></p>
    ${expiresAtText ? `<p>${escapeHtml(expiresAtText)}</p>` : ""}
    <p>Best regards,<br>The NES Dashboard Team</p>
  `.trim();

  // Plain text version
  const text = `
Survey: ${params.survey.title}
${params.survey.description ? `\n${params.survey.description}\n` : ""}

Hi ${contactName},

${senderName} has invited you to complete a survey.

Please visit the following link to take the survey:
${surveyUrl}

${expiresAtText ? `\n${expiresAtText}\n` : ""}
Best regards,
The NES Dashboard Team
  `.trim();

  try {
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${params.resendApiKey}`,
      },
      body: JSON.stringify({
        from: "NES Dashboard <no-reply@meetnate.ca>",
        // Note: Avatar/profile picture for no-reply@meetnate.ca must be configured via Gravatar
        // See: docs/EMAIL_AVATAR_SETUP.md for setup instructions
        to: [params.contact.email],
        subject: `Survey: ${params.survey.title}`,
        html,
        text,
      }),
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      console.error("Resend API error:", errorData);
      return {
        success: false,
        error: "Failed to send survey invitation email.",
      };
    }

    return { success: true };
  } catch (error) {
    console.error("Error sending email:", error);
    return {
      success: false,
      error: error instanceof Error ? error.message : "Failed to send email",
    };
  }
}

// Process a single job
async function processJob(
  supabase: ReturnType<typeof createClient>,
  job: { msg_id: number; message: any },
  resendApiKey: string,
): Promise<{ success: boolean; shouldRetry: boolean }> {
  const { surveyId, instanceId, contactId, sentBy, baseUrl, campaignId } = job.message;

  try {
    // Load survey instance
    const { data: instance, error: instanceError } = await supabase
      .from("survey_instances")
      .select("*")
      .eq("id", instanceId)
      .single();

    if (instanceError || !instance) {
      console.error(`Instance ${instanceId} not found:`, instanceError);
      return { success: false, shouldRetry: false }; // Don't retry if instance doesn't exist
    }

    // Check if campaign is cancelled
    if (campaignId) {
      const { data: campaign } = await supabase
        .from("campaigns")
        .select("status")
        .eq("id", campaignId)
        .single();

      if (campaign?.status === "cancelled") {
        return { success: true, shouldRetry: false };
      }
    }

    // Load contact
    const { data: contact, error: contactError } = await supabase
      .from("contact")
      .select("id, firstname, email")
      .eq("id", contactId)
      .single();

    if (contactError || !contact) {
      console.error(`Contact ${contactId} not found:`, contactError);
      return { success: false, shouldRetry: false };
    }

    // Load survey
    const { data: survey, error: surveyError } = await supabase
      .from("surveys")
      .select("id, title, description")
      .eq("id", surveyId)
      .single();

    if (surveyError || !survey) {
      console.error(`Survey ${surveyId} not found:`, surveyError);
      return { success: false, shouldRetry: false };
    }

    // Load sender profile
    const { data: sender, error: senderError } = await supabase
      .from("profiles")
      .select("id, first_name, surname")
      .eq("id", sentBy)
      .single();

    if (senderError || !sender) {
      console.error(`Sender ${sentBy} not found:`, senderError);
      return { success: false, shouldRetry: false };
    }

    // Build survey URL
    const surveyUrl = `${baseUrl}/survey/${instance.token}`;

    // Send email
    const emailResult = await sendSurveyInviteEmail({
      survey,
      instance,
      contact,
      sender,
      surveyUrl,
      resendApiKey,
    });

    if (!emailResult.success) {
      console.error(`Failed to send email for instance ${instanceId}:`, emailResult.error);
      
      // Mark job as failed
      await supabase.rpc("mark_campaign_job_complete", {
        campaign_id_param: campaignId,
        instance_id_param: instanceId,
        success_param: false,
        error_message: emailResult.error || null,
      });
      
      return { success: false, shouldRetry: true }; // Retry email failures
    }

    // Update instance status and campaign progress via RPC
    const { error: updateError } = await supabase.rpc("mark_campaign_job_complete", {
      campaign_id_param: campaignId,
      instance_id_param: instanceId,
      success_param: true,
    });

    if (updateError) {
      // Fallback: Update directly if RPC doesn't exist
      await supabase
        .from("survey_instances")
        .update({
          status: "sent",
          sent_at: new Date().toISOString(),
        })
        .eq("id", instanceId);

      // Update campaign progress
      if (campaignId) {
        const { data: campaign } = await supabase
          .from("campaigns")
          .select("sent_count, total_recipients")
          .eq("id", campaignId)
          .single();

        if (campaign) {
          const newSentCount = campaign.sent_count + 1;
          const updateData: any = { sent_count: newSentCount };
          
          if (newSentCount >= campaign.total_recipients) {
            updateData.status = "sent";
          }

          await supabase
            .from("campaigns")
            .update(updateData)
            .eq("id", campaignId);
        }
      }
    }

    return { success: true, shouldRetry: false };
  } catch (error) {
    console.error(`Error processing job ${job.msg_id}:`, error);
    return { success: false, shouldRetry: true };
  }
}

// Main handler
serve(async (req) => {
  try {
    // Get environment variables
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const resendApiKey = Deno.env.get("RESEND_API_KEY");

    if (!supabaseUrl || !supabaseServiceKey || !resendApiKey) {
      return new Response(
        JSON.stringify({
          error: "Missing required environment variables",
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Initialize Supabase client
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Read jobs from queue
    const { data: jobs, error: readError } = await supabase.rpc("pgmq_read_survey_jobs", {
      queue_name: "survey_send",
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
      const result = await processJob(supabase, job, resendApiKey);

      if (result.success) {
        // Archive successful job
        await supabase.rpc("pgmq_archive_survey_job", {
          queue_name: "survey_send",
          msg_id_param: job.msg_id,
        });
        results.succeeded++;
        results.archived++;
      } else if (result.shouldRetry) {
        // For retry logic, we'd need to track retry count in the message
        // For now, we'll delete failed jobs after max retries
        // In production, you might want to implement retry tracking
        await supabase.rpc("pgmq_delete_survey_job", {
          queue_name: "survey_send",
          msg_id_param: job.msg_id,
        });
        results.failed++;
      } else {
        // Don't retry - delete the job
        await supabase.rpc("pgmq_delete_survey_job", {
          queue_name: "survey_send",
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

