-- The GL top-level list items
SELECT '*AE UCD Ledger-Dept-Approver' AS "List_Name",
  '*AE UCD Ledger-Dept-Approver' AS "List_Category_Name",
  'GL/Financial Department' AS "Level_01_Code",
  '' AS "Level_02_Code",
  '' AS "Level_03_Code",
  'GL/Financial Department' AS "Value",
  'N' AS "Delete_List_Item",
  timestamp '2023-01-01' AS last_update_date
UNION ALL
-- The POET top-level list items
SELECT '*AE UCD Ledger-Dept-Approver' AS "List_Name",
  '*AE UCD Ledger-Dept-Approver' AS "List_Category_Name",
  'PPM/Project' AS "Level_01_Code",
  '' AS "Level_02_Code",
  '' AS "Level_03_Code",
  'PPM/Project' AS "Value",
  'N' AS "Delete_List_Item",
  timestamp '2023-01-01' AS last_update_date
UNION ALL
-- GL financial department level 3 list items
SELECT '*AE UCD Ledger-Dept-Approver' AS "List_Name",
  '*AE UCD Ledger-Dept-Approver' AS "List_Category_Name",
  'GL/Financial Department' AS "Level_01_Code",
  d.code AS "Level_02_Code",
  '' AS "Level_03_Code",
  d.name AS "Value",
  CASE
    WHEN d.status = 'valid' THEN 'N'
    ELSE 'Y'
  END AS "Delete_List_Item",
  d.last_update_date
FROM #{int_db_erp_schema}.gl_segments d
WHERE segment_type = 'erp_fin_dept'
  AND summary_flag = 'N'
UNION ALL
-- POET Project-Task level 3 list items
SELECT '*AE UCD Ledger-Dept-Approver' AS "List_Name",
  '*AE UCD Ledger-Dept-Approver' AS "List_Category_Name",
  'PPM/Project' AS "Level_01_Code",
  s.code AS "Level_02_Code",
  '' AS "Level_03_Code",
  s.name AS "Value",
  CASE
    WHEN s.status = 'valid' THEN 'N'
    ELSE 'Y'
  END AS "Delete_List_Item",
  s.last_update_date
FROM #{int_db_erp_schema}.ppm_segments s
  JOIN #{int_db_erp_schema}.ppm_project p ON p.project_number = SUBSTR(s.code,1,10)
WHERE segment_type = 'ppm_project_task'
UNION ALL
-- GL financial department approvers
SELECT '*AE UCD Ledger-Dept-Approver' AS "List_Name",
  '*AE UCD Ledger-Dept-Approver' AS "List_Category_Name",
  'GL/Financial Department' AS "Level_01_Code",
  d.code AS "Level_02_Code",
  COALESCE(a.employee_id, '99999999') AS "Level_03_Code",
  COALESCE(a.display_name, 'MISSING APPROVER') AS "Value",
  CASE
    WHEN d.status IS NULL THEN 'N'
    WHEN d.status = 'valid'
    AND a.enabled_flag = 'Y' THEN 'N'
    ELSE 'Y'
  END AS "Delete_List_Item",
  d.last_update_date
FROM #{int_db_erp_schema}.gl_segments d
  LEFT OUTER JOIN #{int_db_erp_schema}.erp_fin_dept_approver a
  ON a.fin_dept_code = d.code
  AND a.role_type_name = 'Fiscal Officer Approver'
WHERE segment_type = 'erp_fin_dept'
  AND summary_flag = 'N'
UNION ALL
-- PPM Project Managers (approver)
SELECT '*AE UCD Ledger-Dept-Approver' AS "List_Name",
  '*AE UCD Ledger-Dept-Approver' AS "List_Category_Name",
  'PPM/Project' AS "Level_01_Code",
  s.code AS "Level_02_Code",
  CASE
    WHEN CHAR_LENGTH(pp.person_number) = 8 THEN pp.person_number
    ELSE '99999999'
  END AS "Level_03_Code",
  CASE
    WHEN CHAR_LENGTH(pp.person_number) = 8 THEN pp.display_name
    ELSE 'MISSING APPROVER'
  END AS "Value",
  CASE
    WHEN s.status = 'valid' THEN 'N'
    ELSE 'Y'
  END AS "Delete_List_Item",
  s.last_update_date
FROM #{int_db_erp_schema}.ppm_segments      s
  JOIN #{int_db_erp_schema}.ppm_project       p ON p.project_number = SUBSTR(s.code,1,10)
  LEFT OUTER JOIN #{int_db_erp_schema}.per_all_people_f pp ON pp.email_address = p.primary_project_manager_email
WHERE segment_type = 'ppm_project_task' -- Single Level segments (except PPM Expense Org)
UNION ALL
SELECT TRIM(
    CASE
      WHEN segment_type = 'erp_entity' THEN '*AE UCD Entity'
      WHEN segment_type = 'erp_fund' THEN '*AE UCD Fund'
      WHEN segment_type = 'erp_purpose' THEN '*AE UCD Purpose'
      WHEN segment_type = 'erp_activity' THEN '*AE UCD Activity'
      WHEN segment_type = 'erp_program' THEN '*AE UCD Program'
      WHEN segment_type = 'gl_project' THEN '*AE UCD GL Project'
    END
  ) AS "List_Name",
  TRIM(
    CASE
      WHEN segment_type = 'erp_entity' THEN '*AE UCD Entity'
      WHEN segment_type = 'erp_fund' THEN '*AE UCD Fund'
      WHEN segment_type = 'erp_purpose' THEN '*AE UCD Purpose'
      WHEN segment_type = 'erp_activity' THEN '*AE UCD Activity'
      WHEN segment_type = 'erp_program' THEN '*AE UCD Program'
      WHEN segment_type = 'gl_project' THEN '*AE UCD GL Project'
    END
  ) AS "List_Category_Name",
  code AS "Level_01_Code",
  '' AS "Level_02_Code",
  '' AS "Level_03_Code",
  SUBSTRING(name, 1, 64) AS "Value",
  CASE
    WHEN STATUS = 'valid' THEN 'N'
    ELSE 'Y'
  END AS "Delete_List_Item",
  last_update_date
FROM #{int_db_erp_schema}.gl_segments
WHERE segment_type IN (
    'erp_entity',
    'erp_fund',
    'erp_purpose',
    'erp_activity',
    'erp_program',
    'gl_project'
  )
  AND summary_flag = 'N'
UNION ALL
-- PPM Expense Org
SELECT '*AE UCD Expenditure Organization' AS "List_Name",
  '*AE UCD Expenditure Organization' AS "List_Category_Name",
  gl.code AS "Level_01_Code",
  '' AS "Level_02_Code",
  '' AS "Level_03_Code",
  SUBSTRING(gl.name, 1, 64) AS "Value",
  CASE
    WHEN gl.status = 'valid'
    AND ppm.enabled_flag = 'Y' THEN 'N'
    ELSE 'Y'
  END AS "Delete_List_Item",
  gl.last_update_date
FROM #{int_db_erp_schema}.gl_segments gl
  JOIN #{int_db_erp_schema}.ppm_organization ppm ON ppm.code = gl.code
WHERE gl.segment_type = 'erp_fin_dept'
  AND gl.summary_flag = 'N'
ORDER BY "List_Name",
  "Level_01_Code",
  "Level_02_Code",
  "Level_03_Code"
