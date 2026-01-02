-- Support invited signup flow with partial records
ALTER TABLE signup_requests
  ALTER COLUMN password_hash DROP NOT NULL,
  ALTER COLUMN first_name DROP NOT NULL,
  ALTER COLUMN surname DROP NOT NULL,
  ALTER COLUMN phone DROP NOT NULL,
  ALTER COLUMN street_address DROP NOT NULL,
  ALTER COLUMN postal_code DROP NOT NULL,
  ALTER COLUMN birth_year DROP NOT NULL,
  ALTER COLUMN birth_month DROP NOT NULL,
  ALTER COLUMN birth_day DROP NOT NULL,
  ALTER COLUMN comms_consent DROP NOT NULL,
  ALTER COLUMN signup_consent DROP NOT NULL,
  ALTER COLUMN wants_student_club DROP NOT NULL;

ALTER TABLE signup_requests
  ADD COLUMN invited_by uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  ADD COLUMN invited_role text DEFAULT 'member',
  ADD COLUMN invited_campus_clubs text[] NOT NULL DEFAULT '{}',
  ADD COLUMN invite_completed_at timestamptz;
