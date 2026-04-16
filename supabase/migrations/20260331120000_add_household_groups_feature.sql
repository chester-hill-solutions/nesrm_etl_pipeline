-- Gate contact household grouping (URL param + RPC) behind the feature permissions system.

INSERT INTO "public"."features" ("id", "name", "description", "category")
VALUES
  (
    'household_groups',
    'Household groups',
    'Group contacts table rows by household (shared email/phone/address clustering) and related RPC behavior.',
    'contacts'
  )
ON CONFLICT ("id") DO NOTHING;
