SELECT
  segment_type
, code
, name
, CASE
    WHEN status = 'valid' THEN 'Y'
    ELSE 'N'
  END AS status
, financial_approver_user_id AS approver_id 
, financial_approver_email   AS approver_email
, financial_approver_name    AS approver_name 
, last_update_date           AS last_update_date
FROM #{int_db_erp_schema}.gl_segments
WHERE segment_type IN (
  'erp_entity',
  'erp_fund',
  'erp_fin_dept',
  'erp_account',
  'erp_program',
  'erp_activity',
  'erp_purpose',
  'gl_project'
)
UNION ALL
SELECT
  segment_type
, code
, name
, CASE
    WHEN status = 'valid' THEN 'Y'
    ELSE 'N'
  END AS status
, financial_approver_user_id AS approver_id 
, financial_approver_email   AS approver_email
, financial_approver_name    AS approver_name 
, last_update_date           AS last_update_date
FROM #{int_db_erp_schema}.ppm_segments
WHERE segment_type IN ( 'ppm_project_task')
ORDER BY segment_type, code
