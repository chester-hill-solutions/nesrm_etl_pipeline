-- Migrate existing column update rules from survey_questions.validation_config to new table
-- This extracts column_update_rule and column_update_rules from validation_config JSONB
/*
DO $$
DECLARE
  question_record RECORD;
  rule_record JSONB;
  rule_config JSONB;
  rule_id_var bigint;
BEGIN
  -- Loop through all survey questions that have validation_config with column update rules
  FOR question_record IN 
    SELECT 
      id,
      validation_config
    FROM survey_questions
    WHERE validation_config IS NOT NULL
      AND (
        validation_config ? 'column_update_rule' OR
        validation_config ? 'column_update_rules'
      )
  LOOP
    -- Handle single rule (column_update_rule)
    IF question_record.validation_config ? 'column_update_rule' THEN
      rule_record := question_record.validation_config->'column_update_rule';
      
      -- Convert old format to new format
      -- Old: { "column": "ballot1", "answerValue": "Nate" }
      -- New: { "column": "ballot1", "match": { "operator": "equals", "value": "Nate" } }
      rule_config := jsonb_build_object(
        'column', rule_record->>'column',
        'operation', 'replace'
      );
      
      -- If answerValue exists, convert to match condition
      IF rule_record ? 'answerValue' AND rule_record->>'answerValue' IS NOT NULL THEN
        rule_config := rule_config || jsonb_build_object(
          'match', jsonb_build_object(
            'operator', 'equals',
            'value', rule_record->>'answerValue'
          )
        );
      END IF;
      
      -- Insert into new table
      INSERT INTO survey_column_update_rules (
        question_id,
        rule_config,
        enabled,
        priority,
        created_at,
        updated_at
      ) VALUES (
        question_record.id,
        rule_config,
        true,
        0,
        now(),
        now()
      );
    END IF;
    
    -- Handle multiple rules (column_update_rules array)
    IF question_record.validation_config ? 'column_update_rules' THEN
      FOR rule_record IN 
        SELECT * FROM jsonb_array_elements(question_record.validation_config->'column_update_rules')
      LOOP
        -- Convert old format to new format
        rule_config := jsonb_build_object(
          'column', rule_record->>'column',
          'operation', 'replace'
        );
        
        -- If answerValue exists, convert to match condition
        IF rule_record ? 'answerValue' AND rule_record->>'answerValue' IS NOT NULL THEN
          rule_config := rule_config || jsonb_build_object(
            'match', jsonb_build_object(
              'operator', 'equals',
              'value', rule_record->>'answerValue'
            )
          );
        END IF;
        
        -- Insert into new table
        INSERT INTO survey_column_update_rules (
          question_id,
          rule_config,
          enabled,
          priority,
          created_at,
          updated_at
        ) VALUES (
          question_record.id,
          rule_config,
          true,
          0,
          now(),
          now()
        );
      END LOOP;
    END IF;
  END LOOP;
END $$;

-- After migration, we can optionally remove column_update_rule from validation_config
-- But we'll leave it for now in case there are any issues - can be cleaned up later
-- Uncomment the following if you want to remove them immediately:
/*
UPDATE survey_questions
SET validation_config = validation_config - 'column_update_rule' - 'column_update_rules'
WHERE validation_config IS NOT NULL
  AND (
    validation_config ? 'column_update_rule' OR
    validation_config ? 'column_update_rules'
  );
*/

