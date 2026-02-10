-- Query to check Edge Function errors and see which variables are missing
-- Run this to see detailed error information from recent location lookup attempts

SELECT 
  id,
  created,
  status_code,
  url,
  -- Extract error details from the response
  content::json->>'error' as error_message,
  content::json->>'missing' as missing_variables,
  content::json->>'details' as variable_details,
  content::json->>'message' as additional_message,
  error_msg as http_error
FROM net.http_request 
WHERE url LIKE '%location-lookup%'
ORDER BY created DESC 
LIMIT 20;

-- Summary of recent errors
SELECT 
  status_code,
  COUNT(*) as count,
  MAX(created) as last_occurrence
FROM net.http_request 
WHERE url LIKE '%location-lookup%'
  AND created > NOW() - INTERVAL '1 hour'
GROUP BY status_code
ORDER BY status_code;
