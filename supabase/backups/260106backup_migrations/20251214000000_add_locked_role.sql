-- Add 'locked' role to role_type enum

ALTER TYPE public.role_type ADD VALUE IF NOT EXISTS 'locked';


