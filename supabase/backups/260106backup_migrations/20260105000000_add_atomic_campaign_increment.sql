-- Add atomic increment function for campaign sent_count
-- This prevents race conditions when multiple workers update the same campaign

CREATE OR REPLACE FUNCTION public.increment_campaign_sent_count(
  campaign_id_param bigint,
  increment_amount integer DEFAULT 1
)
RETURNS TABLE(
  id bigint,
  sent_count integer,
  total_recipients integer,
  status text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_status text;
BEGIN
  -- Get current status to check if campaign is cancelled
  SELECT status INTO current_status
  FROM public.campaigns
  WHERE id = campaign_id_param;
  
  -- Don't update if campaign is cancelled
  IF current_status = 'cancelled' THEN
    RAISE EXCEPTION 'Cannot update progress for cancelled campaign';
  END IF;
  
  -- Atomically increment sent_count
  UPDATE public.campaigns
  SET sent_count = sent_count + increment_amount,
      updated_at = now()
  WHERE id = campaign_id_param
    AND status != 'cancelled';
  
  -- Return updated campaign data
  RETURN QUERY
  SELECT 
    c.id,
    c.sent_count,
    c.total_recipients,
    c.status::text
  FROM public.campaigns c
  WHERE c.id = campaign_id_param;
END;
$$;

-- Grant execute permission to service role
GRANT EXECUTE ON FUNCTION public.increment_campaign_sent_count(bigint, integer) TO service_role;

