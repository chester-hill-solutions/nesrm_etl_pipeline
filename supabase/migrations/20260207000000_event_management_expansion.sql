-- Migration: Event Management Expansion
-- Purpose: Add ticketing, promo codes, and registration capabilities to events system.
-- Enables event capacity management, ticket types, promotional codes, and attendee registration tracking.

--------------------------------------------------------------------------------
-- 1. Add columns to existing events table
--------------------------------------------------------------------------------

ALTER TABLE public.events ADD COLUMN IF NOT EXISTS capacity integer;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS registration_open_at timestamptz;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS registration_close_at timestamptz;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS require_approval boolean DEFAULT false NOT NULL;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS image_url text;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS short_description text;

COMMENT ON COLUMN public.events.capacity IS 'Maximum number of attendees allowed for this event';
COMMENT ON COLUMN public.events.registration_open_at IS 'When registration opens for this event';
COMMENT ON COLUMN public.events.registration_close_at IS 'When registration closes for this event';
COMMENT ON COLUMN public.events.require_approval IS 'If true, registrations require admin approval before confirmation';
COMMENT ON COLUMN public.events.created_by IS 'Profile ID of the user who created this event';
COMMENT ON COLUMN public.events.image_url IS 'URL to the event banner/cover image';
COMMENT ON COLUMN public.events.short_description IS 'Brief description for event listings and previews';

--------------------------------------------------------------------------------
-- 2. Create event_ticket_types table
--------------------------------------------------------------------------------

CREATE TABLE public.event_ticket_types (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id text NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    name text NOT NULL,
    description text,
    price numeric(10,2) NOT NULL DEFAULT 0,
    capacity integer,
    sold_count integer NOT NULL DEFAULT 0,
    reserved_count integer NOT NULL DEFAULT 0,
    sort_order integer NOT NULL DEFAULT 0,
    sales_start_at timestamptz,
    sales_end_at timestamptz,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.event_ticket_types OWNER TO postgres;

COMMENT ON TABLE public.event_ticket_types IS 'Ticket types/tiers for events. Supports multiple pricing tiers, capacity limits, and time-based availability.';
COMMENT ON COLUMN public.event_ticket_types.event_id IS 'The event this ticket type belongs to';
COMMENT ON COLUMN public.event_ticket_types.name IS 'Display name for the ticket type (e.g., Early Bird, General Admission)';
COMMENT ON COLUMN public.event_ticket_types.description IS 'Optional description of what this ticket includes';
COMMENT ON COLUMN public.event_ticket_types.price IS 'Price in CAD. Use 0 for free tickets.';
COMMENT ON COLUMN public.event_ticket_types.capacity IS 'Maximum tickets available for this type. NULL means unlimited.';
COMMENT ON COLUMN public.event_ticket_types.sold_count IS 'Number of tickets sold (completed registrations)';
COMMENT ON COLUMN public.event_ticket_types.reserved_count IS 'Number of tickets reserved (pending payment)';
COMMENT ON COLUMN public.event_ticket_types.sort_order IS 'Display order for ticket types in listings';
COMMENT ON COLUMN public.event_ticket_types.sales_start_at IS 'When this ticket type becomes available for purchase';
COMMENT ON COLUMN public.event_ticket_types.sales_end_at IS 'When this ticket type stops being available';
COMMENT ON COLUMN public.event_ticket_types.is_active IS 'Whether this ticket type is currently active and visible';

-- Indexes for event_ticket_types
CREATE INDEX idx_event_ticket_types_event_id ON public.event_ticket_types(event_id);
CREATE INDEX idx_event_ticket_types_is_active ON public.event_ticket_types(is_active) WHERE is_active = true;

-- Updated_at trigger for event_ticket_types
CREATE TRIGGER update_event_ticket_types_updated_at
    BEFORE UPDATE ON public.event_ticket_types
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

--------------------------------------------------------------------------------
-- 3. Create event_promo_codes table
--------------------------------------------------------------------------------

CREATE TABLE public.event_promo_codes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id text NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    code text NOT NULL,
    discount_type text NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value numeric(10,2) NOT NULL,
    max_uses integer,
    used_count integer NOT NULL DEFAULT 0,
    valid_from timestamptz,
    valid_until timestamptz,
    ticket_type_ids uuid[],
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(event_id, code)
);

ALTER TABLE public.event_promo_codes OWNER TO postgres;

COMMENT ON TABLE public.event_promo_codes IS 'Promotional codes for event discounts. Supports percentage or fixed discounts with usage limits and validity periods.';
COMMENT ON COLUMN public.event_promo_codes.event_id IS 'The event this promo code applies to';
COMMENT ON COLUMN public.event_promo_codes.code IS 'The promo code string (case-insensitive in application)';
COMMENT ON COLUMN public.event_promo_codes.discount_type IS 'Type of discount: percentage (e.g., 20% off) or fixed (e.g., $10 off)';
COMMENT ON COLUMN public.event_promo_codes.discount_value IS 'Discount amount. For percentage: 20 means 20%. For fixed: 10.00 means $10 off.';
COMMENT ON COLUMN public.event_promo_codes.max_uses IS 'Maximum number of times this code can be used. NULL means unlimited.';
COMMENT ON COLUMN public.event_promo_codes.used_count IS 'Number of times this code has been used';
COMMENT ON COLUMN public.event_promo_codes.valid_from IS 'When this promo code becomes valid';
COMMENT ON COLUMN public.event_promo_codes.valid_until IS 'When this promo code expires';
COMMENT ON COLUMN public.event_promo_codes.ticket_type_ids IS 'Array of ticket type IDs this code applies to. NULL means all ticket types.';
COMMENT ON COLUMN public.event_promo_codes.is_active IS 'Whether this promo code is currently active';

-- Indexes for event_promo_codes
CREATE INDEX idx_event_promo_codes_event_id ON public.event_promo_codes(event_id);
CREATE INDEX idx_event_promo_codes_code ON public.event_promo_codes(code);
CREATE INDEX idx_event_promo_codes_is_active ON public.event_promo_codes(is_active) WHERE is_active = true;

-- Updated_at trigger for event_promo_codes
CREATE TRIGGER update_event_promo_codes_updated_at
    BEFORE UPDATE ON public.event_promo_codes
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

--------------------------------------------------------------------------------
-- 4. Create event_registrations table
--------------------------------------------------------------------------------

CREATE TABLE public.event_registrations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id text NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    contact_id bigint NOT NULL REFERENCES public.contact(id) ON DELETE CASCADE,
    ticket_type_id uuid REFERENCES public.event_ticket_types(id) ON DELETE SET NULL,
    promo_code_id uuid REFERENCES public.event_promo_codes(id) ON DELETE SET NULL,
    status text NOT NULL DEFAULT 'registered' CHECK (status IN (
        'invited', 'rsvp_yes', 'rsvp_no', 'rsvp_maybe',
        'registered', 'checked_in', 'attended', 'no_show', 'cancelled'
    )),
    payment_status text NOT NULL DEFAULT 'not_required' CHECK (payment_status IN (
        'not_required', 'pending', 'paid', 'refunded', 'comped', 'failed'
    )),
    stripe_payment_intent_id text,
    amount_paid numeric(10,2) DEFAULT 0,
    registration_source text NOT NULL DEFAULT 'admin' CHECK (registration_source IN (
        'admin', 'self', 'import', 'invite'
    )),
    checked_in_at timestamptz,
    checked_in_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    notes text,
    metadata jsonb DEFAULT '{}',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(event_id, contact_id)
);

ALTER TABLE public.event_registrations OWNER TO postgres;

COMMENT ON TABLE public.event_registrations IS 'Event registrations linking contacts to events. Tracks RSVP status, payments, check-ins, and attendance.';
COMMENT ON COLUMN public.event_registrations.event_id IS 'The event being registered for';
COMMENT ON COLUMN public.event_registrations.contact_id IS 'The contact who is registered';
COMMENT ON COLUMN public.event_registrations.ticket_type_id IS 'The ticket type selected for this registration';
COMMENT ON COLUMN public.event_registrations.promo_code_id IS 'Promo code used for this registration (if any)';
COMMENT ON COLUMN public.event_registrations.status IS 'Registration status: invited, rsvp_yes/no/maybe, registered, checked_in, attended, no_show, cancelled';
COMMENT ON COLUMN public.event_registrations.payment_status IS 'Payment status: not_required, pending, paid, refunded, comped, failed';
COMMENT ON COLUMN public.event_registrations.stripe_payment_intent_id IS 'Stripe PaymentIntent ID for paid registrations';
COMMENT ON COLUMN public.event_registrations.amount_paid IS 'Total amount paid for this registration';
COMMENT ON COLUMN public.event_registrations.registration_source IS 'How the registration was created: admin, self, import, invite';
COMMENT ON COLUMN public.event_registrations.checked_in_at IS 'When the attendee was checked in';
COMMENT ON COLUMN public.event_registrations.checked_in_by IS 'Profile ID of staff who performed check-in';
COMMENT ON COLUMN public.event_registrations.notes IS 'Internal notes about this registration';
COMMENT ON COLUMN public.event_registrations.metadata IS 'Additional JSON metadata for custom fields or integration data';

-- Indexes for event_registrations
CREATE INDEX idx_event_registrations_event_id ON public.event_registrations(event_id);
CREATE INDEX idx_event_registrations_contact_id ON public.event_registrations(contact_id);
CREATE INDEX idx_event_registrations_ticket_type_id ON public.event_registrations(ticket_type_id);
CREATE INDEX idx_event_registrations_status ON public.event_registrations(status);
CREATE INDEX idx_event_registrations_payment_status ON public.event_registrations(payment_status);
CREATE INDEX idx_event_registrations_checked_in_at ON public.event_registrations(checked_in_at) WHERE checked_in_at IS NOT NULL;

-- Updated_at trigger for event_registrations
CREATE TRIGGER update_event_registrations_updated_at
    BEFORE UPDATE ON public.event_registrations
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

--------------------------------------------------------------------------------
-- 5. Enable Row Level Security
--------------------------------------------------------------------------------

ALTER TABLE public.event_ticket_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_registrations ENABLE ROW LEVEL SECURITY;

--------------------------------------------------------------------------------
-- 6. RLS Policies for event_ticket_types
--------------------------------------------------------------------------------

-- Public/authenticated users can read active ticket types
CREATE POLICY "allow authenticated read event_ticket_types"
    ON public.event_ticket_types
    FOR SELECT
    TO authenticated
    USING (true);

-- Admins with dashboard access can manage ticket types
CREATE POLICY "allow admin manage event_ticket_types"
    ON public.event_ticket_types
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
            AND p.role IN ('super_admin', 'admin', 'developer')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
            AND p.role IN ('super_admin', 'admin', 'developer')
        )
    );

-- Service role has full access
CREATE POLICY "allow service_role manage event_ticket_types"
    ON public.event_ticket_types
    TO service_role
    USING (true)
    WITH CHECK (true);

--------------------------------------------------------------------------------
-- 7. RLS Policies for event_promo_codes
--------------------------------------------------------------------------------

-- Admins can read promo codes (not publicly visible)
CREATE POLICY "allow admin read event_promo_codes"
    ON public.event_promo_codes
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
            AND p.role IN ('super_admin', 'admin', 'developer')
        )
    );

-- Admins with dashboard access can manage promo codes
CREATE POLICY "allow admin manage event_promo_codes"
    ON public.event_promo_codes
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
            AND p.role IN ('super_admin', 'admin', 'developer')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
            AND p.role IN ('super_admin', 'admin', 'developer')
        )
    );

-- Service role has full access
CREATE POLICY "allow service_role manage event_promo_codes"
    ON public.event_promo_codes
    TO service_role
    USING (true)
    WITH CHECK (true);

--------------------------------------------------------------------------------
-- 8. RLS Policies for event_registrations
--------------------------------------------------------------------------------

-- Admins can read all registrations
CREATE POLICY "allow admin read event_registrations"
    ON public.event_registrations
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
            AND p.role IN ('super_admin', 'admin', 'developer')
        )
    );

-- Admins with dashboard access can manage registrations
CREATE POLICY "allow admin manage event_registrations"
    ON public.event_registrations
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
            AND p.role IN ('super_admin', 'admin', 'developer')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
            AND p.role IN ('super_admin', 'admin', 'developer')
        )
    );

-- Service role has full access for registrations
CREATE POLICY "allow service_role manage event_registrations"
    ON public.event_registrations
    TO service_role
    USING (true)
    WITH CHECK (true);

--------------------------------------------------------------------------------
-- 9. Add feature permissions for events management
--------------------------------------------------------------------------------

-- See seed 20260207000000_event_management_expansion.sql for feature and permission inserts

--------------------------------------------------------------------------------
-- 10. Grant table permissions
--------------------------------------------------------------------------------

-- Grant permissions for event_ticket_types
GRANT ALL ON TABLE public.event_ticket_types TO anon;
GRANT ALL ON TABLE public.event_ticket_types TO authenticated;
GRANT ALL ON TABLE public.event_ticket_types TO service_role;

-- Grant permissions for event_promo_codes
GRANT ALL ON TABLE public.event_promo_codes TO anon;
GRANT ALL ON TABLE public.event_promo_codes TO authenticated;
GRANT ALL ON TABLE public.event_promo_codes TO service_role;

-- Grant permissions for event_registrations
GRANT ALL ON TABLE public.event_registrations TO anon;
GRANT ALL ON TABLE public.event_registrations TO authenticated;
GRANT ALL ON TABLE public.event_registrations TO service_role;
