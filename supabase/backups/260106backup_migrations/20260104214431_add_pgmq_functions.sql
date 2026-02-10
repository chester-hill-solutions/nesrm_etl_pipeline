-- Create PGMQ wrapper functions for survey send queue operations
-- These functions can be called via Supabase RPC

-- Function to send a job to the PGMQ queue
CREATE OR REPLACE FUNCTION public.pgmq_send_survey_job(
  queue_name text,
  message jsonb
)
RETURNS TABLE(msg_id bigint)
LANGUAGE plpgsql
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

-- Function to read jobs from the PGMQ queue
CREATE OR REPLACE FUNCTION public.pgmq_read_survey_jobs(
  queue_name text,
  vt integer DEFAULT 300,
  qty integer DEFAULT 10
)
RETURNS TABLE(msg_id bigint, message jsonb)
LANGUAGE plpgsql
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

-- Function to archive a completed job
CREATE OR REPLACE FUNCTION public.pgmq_archive_survey_job(
  queue_name text,
  msg_id_param bigint
)
RETURNS boolean
LANGUAGE plpgsql
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

-- Function to delete a failed job
CREATE OR REPLACE FUNCTION public.pgmq_delete_survey_job(
  queue_name text,
  msg_id_param bigint
)
RETURNS boolean
LANGUAGE plpgsql
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

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.pgmq_send_survey_job(text, jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION public.pgmq_send_survey_job(text, jsonb) TO authenticated;

GRANT EXECUTE ON FUNCTION public.pgmq_read_survey_jobs(text, integer, integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.pgmq_read_survey_jobs(text, integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.pgmq_archive_survey_job(text, bigint) TO service_role;
GRANT EXECUTE ON FUNCTION public.pgmq_archive_survey_job(text, bigint) TO authenticated;

GRANT EXECUTE ON FUNCTION public.pgmq_delete_survey_job(text, bigint) TO service_role;
GRANT EXECUTE ON FUNCTION public.pgmq_delete_survey_job(text, bigint) TO authenticated;

-- Function to mark a campaign job as complete and update progress
CREATE OR REPLACE FUNCTION public.mark_campaign_job_complete(
  campaign_id_param bigint,
  instance_id_param bigint,
  success_param boolean,
  error_message text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
  contact_id_val bigint;
  current_sent_count integer;
  total_recipients_val integer;
BEGIN
  -- Update survey instance status
  IF success_param THEN
    UPDATE public.survey_instances
    SET 
      status = 'sent',
      sent_at = now()
    WHERE id = instance_id_param;
  ELSE
    UPDATE public.survey_instances
    SET status = 'failed'
    WHERE id = instance_id_param;
  END IF;

  -- Get contact ID from instance
  SELECT contact_id INTO contact_id_val
  FROM public.survey_instances
  WHERE id = instance_id_param;

  IF success_param AND campaign_id_param IS NOT NULL THEN
    -- Update campaign progress atomically
    UPDATE public.campaigns
    SET sent_count = sent_count + 1
    WHERE id = campaign_id_param
    RETURNING sent_count, total_recipients INTO current_sent_count, total_recipients_val;

    -- Check if campaign is complete
    IF current_sent_count >= total_recipients_val THEN
      UPDATE public.campaigns
      SET status = 'sent'
      WHERE id = campaign_id_param;
    END IF;
  ELSIF NOT success_param AND campaign_id_param IS NOT NULL AND contact_id_val IS NOT NULL THEN
    -- Track failed contact
    UPDATE public.campaigns
    SET failed_contact_ids = COALESCE(failed_contact_ids, '[]'::jsonb) || jsonb_build_array(contact_id_val)
    WHERE id = campaign_id_param
    AND NOT (failed_contact_ids @> jsonb_build_array(contact_id_val));
  END IF;

  RETURN true;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error and return false
    RAISE WARNING 'Failed to mark campaign job complete: %', SQLERRM;
    RETURN false;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.mark_campaign_job_complete(bigint, bigint, boolean, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.mark_campaign_job_complete(bigint, bigint, boolean, text) TO authenticated;

