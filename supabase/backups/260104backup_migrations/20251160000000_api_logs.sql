-- Create API logs table for storing API request logs
CREATE TABLE IF NOT EXISTS public.api_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id text NOT NULL,
    method text NOT NULL,
    path text NOT NULL,
    ip text NOT NULL,
    user_agent text,
    profile_id uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
    token_id uuid REFERENCES public.api_tokens (id) ON DELETE SET NULL,
    status integer,
    duration_ms numeric,
    response_size_bytes integer,
    error_message text,
    error_stack text,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_api_logs_token_id ON public.api_logs (token_id) WHERE token_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_api_logs_profile_id ON public.api_logs (profile_id) WHERE profile_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_api_logs_created_at ON public.api_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_api_logs_request_id ON public.api_logs (request_id);
CREATE INDEX IF NOT EXISTS idx_api_logs_status ON public.api_logs (status) WHERE status >= 400;

-- Enable RLS
ALTER TABLE public.api_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view logs for their own tokens, super_admins can view all
CREATE POLICY "Users can view logs for own tokens, super_admins can view all" ON public.api_logs
    FOR SELECT
    TO authenticated
    USING (
        -- Users can see logs for their own tokens
        (token_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM public.api_tokens
            WHERE api_tokens.id = api_logs.token_id
            AND api_tokens.profile_id = auth.uid()
        )) OR
        -- Users can see logs for their own profile (session-based requests)
        (token_id IS NULL AND profile_id = auth.uid()) OR
        -- Super admins can see all logs
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    );







