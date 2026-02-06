-- Migration: create-respondent-email-templates
-- Purpose: Add respondent_email_templates table for admin-managed email templates (post-survey / volunteer onboarding).
-- Enables future HTML body support via body_format column.

CREATE TABLE IF NOT EXISTS respondent_email_templates (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  subject TEXT NOT NULL,
  body TEXT NOT NULL,
  body_format TEXT NOT NULL DEFAULT 'plain' CHECK (body_format IN ('plain', 'html')),
  is_default BOOLEAN NOT NULL DEFAULT false
);

-- At most one template can be the default (partial unique index on constant)
CREATE UNIQUE INDEX IF NOT EXISTS idx_respondent_email_templates_single_default
  ON respondent_email_templates ((true))
  WHERE is_default = true;

