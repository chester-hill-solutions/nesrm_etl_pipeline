-- Database query optimization indexes
-- This migration adds indexes to improve query performance based on common filter patterns
-- and reduce query execution time for frequently accessed data.

-- Composite index on contact_custom_fields for common filter queries
-- Used when filtering by column_id and then joining on contact_id
CREATE INDEX IF NOT EXISTS contact_custom_fields_column_contact_idx 
ON public.contact_custom_fields (column_id, contact_id);

-- Indexes on value columns for custom field filtering
-- These help when filtering by specific values in custom fields
CREATE INDEX IF NOT EXISTS contact_custom_fields_value_text_idx 
ON public.contact_custom_fields (value_text) 
WHERE value_text IS NOT NULL;

CREATE INDEX IF NOT EXISTS contact_custom_fields_value_number_idx 
ON public.contact_custom_fields (value_number) 
WHERE value_number IS NOT NULL;

CREATE INDEX IF NOT EXISTS contact_custom_fields_value_date_idx 
ON public.contact_custom_fields (value_date) 
WHERE value_date IS NOT NULL;

CREATE INDEX IF NOT EXISTS contact_custom_fields_value_boolean_idx 
ON public.contact_custom_fields (value_boolean) 
WHERE value_boolean IS NOT NULL;

-- Composite index on request table for common filter combinations
-- Frequently used: filtering by status and ordering by created_at
CREATE INDEX IF NOT EXISTS request_status_created_at_idx 
ON public.request (status, created_at DESC) 
WHERE status IS NOT NULL;

-- Ensure indexes exist on profile access tables for profile_id lookups
-- These are critical for loading team member access data
CREATE INDEX IF NOT EXISTS profile_riding_access_profile_id_idx 
ON public.profile_riding_access (profile_id);

CREATE INDEX IF NOT EXISTS profile_region_access_profile_id_idx 
ON public.profile_region_access (profile_id);

CREATE INDEX IF NOT EXISTS profile_campus_club_access_profile_id_idx 
ON public.profile_campus_club_access (profile_id);

-- Index on contact.last_request for efficient lookups when fetching contact info for requests
-- This foreign key is frequently used in joins
CREATE INDEX IF NOT EXISTS contact_last_request_idx 
ON public.contact (last_request) 
WHERE last_request IS NOT NULL;

-- Composite index for common contact filter combinations
-- division_electoral_district + status-related fields are frequently filtered together
CREATE INDEX IF NOT EXISTS contact_division_status_idx 
ON public.contact (division_electoral_district, organizer) 
WHERE division_electoral_district IS NOT NULL;

-- Index for profile lookups by email (used in auth resolution)
CREATE INDEX IF NOT EXISTS profiles_email_idx 
ON public.profiles (email) 
WHERE email IS NOT NULL;

