-- Add invited flag to signup_requests
ALTER TABLE signup_requests ADD COLUMN invited boolean NOT NULL DEFAULT false;