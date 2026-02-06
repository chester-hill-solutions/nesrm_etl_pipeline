-- Add AI research capability to contact table
-- This migration adds fields for storing AI-powered research results
-- following the contact-research skill specification

ALTER TABLE contact 
ADD COLUMN IF NOT EXISTS research_data JSONB DEFAULT NULL,
ADD COLUMN IF NOT EXISTS research_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
ADD COLUMN IF NOT EXISTS research_status VARCHAR(20) DEFAULT NULL 
  CHECK (research_status IN ('pending', 'completed', 'failed'));

-- Add comment for documentation
COMMENT ON COLUMN contact.research_data IS 'AI research results following contact-research skill format, stored as JSONB with sections for basic information, public statements, advocacy, appearances, contributions, and sources';
COMMENT ON COLUMN contact.research_updated_at IS 'Timestamp of when AI research was last updated or requested';
COMMENT ON COLUMN contact.research_status IS 'Current status of AI research: pending (in progress), completed (success), failed (error)';

-- Create index for research status filtering
CREATE INDEX IF NOT EXISTS idx_contact_research_status ON contact(research_status) WHERE research_status IS NOT NULL;

-- Create index for research timestamp filtering
CREATE INDEX IF NOT EXISTS idx_contact_research_updated_at ON contact(research_updated_at) WHERE research_updated_at IS NOT NULL;