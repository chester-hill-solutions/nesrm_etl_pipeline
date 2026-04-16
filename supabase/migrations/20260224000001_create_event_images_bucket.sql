-- See seed 20260224000001_create_event_images_bucket.sql for bucket insert

-- Storage policies for event images (public read + staff uploads).
-- Drop policies if they exist (for idempotency).
DROP POLICY IF EXISTS "event_images_public_read_policy" ON storage.objects;
DROP POLICY IF EXISTS "event_images_upload_policy" ON storage.objects;
DROP POLICY IF EXISTS "event_images_delete_policy" ON storage.objects;

-- Policy: Public read access (needed for `events.image_url` to be used directly in <img src="...">).
CREATE POLICY "event_images_public_read_policy"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'event_images'
);

-- Policy: Allow authenticated uploads (app server uses service_role, but this keeps behavior consistent).
CREATE POLICY "event_images_upload_policy"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'event_images'
);

-- Policy: Allow admins to delete images.
CREATE POLICY "event_images_delete_policy"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'event_images'
  AND EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role IN ('super_admin'::text, 'admin'::text, 'developer'::text)
  )
);
