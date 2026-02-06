
COMMENT ON TABLE respondent_email_templates IS 'Admin-managed email templates for post-survey respondent emails. body_format allows future HTML support.';
COMMENT ON COLUMN respondent_email_templates.body_format IS 'plain = body is plain text (escaped for HTML when sending). html = body is HTML (future).';

-- Seed default volunteer onboarding template (matches current hard-coded default in survey modal)
INSERT INTO respondent_email_templates (name, subject, body, body_format, is_default)
VALUES (
  'Volunteer onboarding',
  'Thanks for raising your hand – next steps',
  $body$Thanks for raising your hand to help out with Team Nate. We're excited to have you on board.

The campaign is building quickly, and the most important thing right now is helping bring new people into the movement.

Here's how to get started:

1. Help us sign up supporters
Growing the campaign is critical at this stage. Share your organizer link with friends, family, and colleagues who might be interested in the leadership race.
[Organizer link]

2. Join our upcoming campaign meeting
We're holding a volunteer meeting on February 11, where we'll walk through the campaign plan, priorities, and how volunteers can make the biggest impact. We strongly encourage you to attend if you're able.
[Meeting details / RSVP link]

3. Register for your Team Nate account
Our Organizer platform will help you get in touch with Ontario Liberals near you. Request your account at data.teamnate.ca/signup and get ready to start organizing.

Thanks again for your support. We'll be in touch soon.$body$,
  'plain',
  true
);
  
