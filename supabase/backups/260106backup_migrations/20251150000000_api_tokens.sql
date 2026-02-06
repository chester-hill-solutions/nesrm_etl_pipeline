-- Create API tokens table for token-based authentication
CREATE TABLE IF NOT EXISTS public.api_tokens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    token_hash text NOT NULL UNIQUE,
    name text NOT NULL,
    profile_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    created_by uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
    created_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz,
    last_used_at timestamptz,
    is_active boolean NOT NULL DEFAULT true
);

-- Create index on token_hash for fast lookups
CREATE INDEX IF NOT EXISTS idx_api_tokens_token_hash ON public.api_tokens (token_hash);

-- Create index on profile_id for listing user's tokens
CREATE INDEX IF NOT EXISTS idx_api_tokens_profile_id ON public.api_tokens (profile_id);

-- Create index on is_active for filtering active tokens
CREATE INDEX IF NOT EXISTS idx_api_tokens_is_active ON public.api_tokens (is_active) WHERE is_active = true;

-- Enable RLS
ALTER TABLE public.api_tokens ENABLE ROW LEVEL SECURITY;

-- Policy: Only super_admins can create tokens
CREATE POLICY "Only super_admins can create tokens" ON public.api_tokens
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    );

-- Policy: Users can view their own tokens, super_admins can view all
CREATE POLICY "Users can view own tokens, super_admins can view all" ON public.api_tokens
    FOR SELECT
    TO authenticated
    USING (
        profile_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    );

-- Policy: Users can update their own tokens, super_admins can update any
CREATE POLICY "Users can update own tokens, super_admins can update any" ON public.api_tokens
    FOR UPDATE
    TO authenticated
    USING (
        profile_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    )
    WITH CHECK (
        profile_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    );

-- Policy: Users can delete their own tokens, super_admins can delete any
CREATE POLICY "Users can delete own tokens, super_admins can delete any" ON public.api_tokens
    FOR DELETE
    TO authenticated
    USING (
        profile_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    );

