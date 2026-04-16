-- Setup pgmq queue for segment_membership if extension exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pgmq'
  ) THEN
    PERFORM * FROM pgmq.create('segment_membership');
  END IF;
END $$;
