-- See seed 20260123000003_create_contact_attachments_bucket.sql for bucket insert

-- Create storage policies for the bucket
-- Drop policies if they exist (for idempotency)
DROP POLICY IF EXISTS "contact_attachments_upload_policy" ON storage.objects;
DROP POLICY IF EXISTS "contact_attachments_read_policy" ON storage.objects;
DROP POLICY IF EXISTS "contact_attachments_delete_policy" ON storage.objects;

-- Policy: Allow authenticated users to upload files
-- The API controls the path structure, so we just need to ensure it's the right bucket
CREATE POLICY "contact_attachments_upload_policy"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'contact_attachments'
);

-- Policy: Allow authenticated users to read files they have access to
-- This checks that the user has access to the contact associated with the attachment
-- Note: storage_path in contact_attachment table is just the path within the bucket (e.g., "123/file.pdf")
-- The name column in storage.objects is also just the path within the bucket
CREATE POLICY "contact_attachments_read_policy"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'contact_attachments' AND
  EXISTS (
    SELECT 1 FROM public.contact_attachment ca
    JOIN public.contact c ON ca.contact_id = c.id
    WHERE ca.storage_path = name
    AND ca.deleted_at IS NULL
    AND (
      -- Contact has no organizer (public access)
      c.organizer IS NULL
      OR
      -- User's organizer_tag matches contact's organizer
      EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND p.organizer_tag IS NOT NULL
        AND c.organizer ILIKE '%' || p.organizer_tag || '%'
      )
      OR
      -- User has organizer tag in profile_organizer_tags that matches
      EXISTS (
        SELECT 1 FROM public.profile_organizer_tags pot
        WHERE pot.profile_id = auth.uid()
        AND pot.tag IS NOT NULL
        AND c.organizer ILIKE '%' || pot.tag || '%'
      )
      OR
      -- User is admin
      EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND p.role = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])
      )
    )
  )
);

-- Policy: Allow authenticated users to delete files they uploaded
-- Only the uploader or admins can delete
CREATE POLICY "contact_attachments_delete_policy"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'contact_attachments' AND
  EXISTS (
    SELECT 1 FROM public.contact_attachment ca
    WHERE ca.storage_path = name
    AND (
      ca.uploaded_by = auth.uid() OR
      EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND p.role = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])
      )
    )
  )
);
