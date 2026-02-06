-- Allow authenticated users to update their own profile
-- This policy allows users to update their personal details (first_name, surname, phone, etc.)
-- but they can only update their own profile (auth.uid() = id)

CREATE POLICY "Allow authenticated update own profile" ON public.profiles
    FOR UPDATE 
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Create a trigger function to prevent updates to sensitive fields
-- This adds an extra layer of security beyond RLS
-- Admins (super_admin/admin) and service_role can update any field
CREATE OR REPLACE FUNCTION prevent_sensitive_profile_updates()
RETURNS TRIGGER AS $$
DECLARE
    user_role text;
BEGIN
    -- Check if current user is an admin (allows service_role operations too)
    -- This is a quick lookup by primary key
    SELECT role::text INTO user_role
    FROM public.profiles
    WHERE id = auth.uid();
    
    -- Allow admins and service_role (when auth.uid() is NULL, it's likely service_role)
    -- to update any field
    IF user_role IN ('super_admin', 'admin') OR auth.uid() IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Prevent updates to sensitive fields for regular authenticated users
    IF OLD.id IS DISTINCT FROM NEW.id THEN
        RAISE EXCEPTION 'Cannot update profile id';
    END IF;
    
    IF OLD.email IS DISTINCT FROM NEW.email THEN
        RAISE EXCEPTION 'Cannot update email. Please contact an administrator.';
    END IF;
    
    IF OLD.role IS DISTINCT FROM NEW.role THEN
        RAISE EXCEPTION 'Cannot update role. Please contact an administrator.';
    END IF;
    
    IF OLD.organizer_tag IS DISTINCT FROM NEW.organizer_tag THEN
        RAISE EXCEPTION 'Cannot update organizer_tag. Please contact an administrator.';
    END IF;
    
    IF OLD.created_at IS DISTINCT FROM NEW.created_at THEN
        RAISE EXCEPTION 'Cannot update created_at';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
CREATE TRIGGER prevent_sensitive_profile_updates_trigger
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION prevent_sensitive_profile_updates();

