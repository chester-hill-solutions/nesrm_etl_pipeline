-- Setup pgmq queue for webhook_send if extension exists
DO $$
BEGIN
  -- Check if pgmq extension exists
  IF EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pgmq'
  ) THEN
    -- Create queue if it doesn't exist
    PERFORM * FROM pgmq.create('webhook_send');
  END IF;
END $$;

-- Create RPC function to send webhook jobs
CREATE OR REPLACE FUNCTION "public"."pgmq_send_webhook_job"("queue_name" "text", "message" "jsonb") RETURNS TABLE("msg_id" bigint)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  result_msg_id bigint;
BEGIN
  -- Call pgmq.send and return the message ID
  SELECT msg_id INTO result_msg_id
  FROM pgmq.send(queue_name, message);
  
  RETURN QUERY SELECT result_msg_id;
EXCEPTION
  WHEN OTHERS THEN
    -- Re-raise the error with context
    RAISE EXCEPTION 'Failed to send job to queue %: %', queue_name, SQLERRM;
END;
$$;

ALTER FUNCTION "public"."pgmq_send_webhook_job"("queue_name" "text", "message" "jsonb") OWNER TO "postgres";

-- Create RPC function to read webhook jobs
CREATE OR REPLACE FUNCTION "public"."pgmq_read_webhook_jobs"("queue_name" "text", "vt" integer DEFAULT 300, "qty" integer DEFAULT 10) RETURNS TABLE("msg_id" bigint, "message" "jsonb")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Call pgmq.read and return messages
  RETURN QUERY
  SELECT 
    m.msg_id,
    m.message
  FROM pgmq.read(queue_name, vt, qty) m;
EXCEPTION
  WHEN OTHERS THEN
    -- Re-raise the error with context
    RAISE EXCEPTION 'Failed to read jobs from queue %: %', queue_name, SQLERRM;
END;
$$;

ALTER FUNCTION "public"."pgmq_read_webhook_jobs"("queue_name" "text", "vt" integer, "qty" integer) OWNER TO "postgres";

-- Create RPC function to archive webhook jobs
CREATE OR REPLACE FUNCTION "public"."pgmq_archive_webhook_job"("queue_name" "text", "msg_id_param" bigint) RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Call pgmq.archive
  PERFORM pgmq.archive(queue_name, msg_id_param);
  RETURN true;
EXCEPTION
  WHEN OTHERS THEN
    -- Return false on error
    RETURN false;
END;
$$;

ALTER FUNCTION "public"."pgmq_archive_webhook_job"("queue_name" "text", "msg_id_param" bigint) OWNER TO "postgres";

-- Create RPC function to delete webhook jobs
CREATE OR REPLACE FUNCTION "public"."pgmq_delete_webhook_job"("queue_name" "text", "msg_id_param" bigint) RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Call pgmq.delete
  PERFORM pgmq.delete(queue_name, msg_id_param);
  RETURN true;
EXCEPTION
  WHEN OTHERS THEN
    -- Return false on error
    RETURN false;
END;
$$;

ALTER FUNCTION "public"."pgmq_delete_webhook_job"("queue_name" "text", "msg_id_param" bigint) OWNER TO "postgres";

-- Grant permissions on RPC functions
GRANT ALL ON FUNCTION "public"."pgmq_send_webhook_job"("queue_name" "text", "message" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."pgmq_send_webhook_job"("queue_name" "text", "message" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgmq_send_webhook_job"("queue_name" "text", "message" "jsonb") TO "service_role";

GRANT ALL ON FUNCTION "public"."pgmq_read_webhook_jobs"("queue_name" "text", "vt" integer, "qty" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."pgmq_read_webhook_jobs"("queue_name" "text", "vt" integer, "qty" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgmq_read_webhook_jobs"("queue_name" "text", "vt" integer, "qty" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."pgmq_archive_webhook_job"("queue_name" "text", "msg_id_param" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."pgmq_archive_webhook_job"("queue_name" "text", "msg_id_param" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgmq_archive_webhook_job"("queue_name" "text", "msg_id_param" bigint) TO "service_role";

GRANT ALL ON FUNCTION "public"."pgmq_delete_webhook_job"("queue_name" "text", "msg_id_param" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."pgmq_delete_webhook_job"("queue_name" "text", "msg_id_param" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgmq_delete_webhook_job"("queue_name" "text", "msg_id_param" bigint) TO "service_role";

