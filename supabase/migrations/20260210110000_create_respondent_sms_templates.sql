-- Migration: create-respondent-sms-templates
-- Purpose: Add respondent_sms_templates table for admin-managed SMS templates (e.g. survey send_sms blocks).
-- Mirrors respondent_email_templates pattern with name, body, and single default.

CREATE TABLE IF NOT EXISTS respondent_sms_templates (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  body TEXT NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT false
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_respondent_sms_templates_single_default
  ON respondent_sms_templates ((true))
  WHERE is_default = true;

COMMENT ON TABLE respondent_sms_templates IS 'Admin-managed SMS templates for respondent messages (e.g. send_sms survey blocks).';

-- See seed 20260210110000_create_respondent_sms_templates.sql for feature and permission inserts
