SELECT
  j.job_indicator
, j.emplid
, j.empl_rcd
, j.effdt
, j.effseq
, j.per_org
, j.empl_status
-- Use of 1957 is arbitrary - just has to be greater than the effective dates of control data in the HCM module
, CASE WHEN j.hire_dt       < date'1957-01-01' THEN date'1957-01-01' ELSE j.hire_dt       END AS hire_dt
, CASE WHEN j.last_hire_dt  < date'1957-01-01' THEN date'1957-01-01' ELSE j.last_hire_dt  END AS last_hire_dt
, CASE WHEN j.asgn_start_dt < date'1957-01-01' THEN date'1957-01-01' ELSE j.asgn_start_dt END AS asgn_start_dt
-- HDL requires an end date - but UCpath does not include them on career records
-- We default to the old oracle max date of 4712-12-31
, COALESCE(j.asgn_end_dt, date'4712-12-31') AS asgn_end_dt
, j.termination_dt
, j.jobcode
-- Pull the email address from UCPath First - then fall-back to IAM person record
, LOWER(COALESCE(e.email_addr, TO_CHAR(p.email)))        AS email_addr
, SUBSTR(COALESCE(TRIM(n.last_name), 'UNKNOWN'), 1, 50)  AS last_name
, SUBSTR(COALESCE(TRIM(n.first_name), 'UNKNOWN'), 1, 50) AS first_name
, SUBSTR(TRIM(n.middle_name), 1, 50)                     AS middle_name
-- Name suffix is not part of the Lived Name changes in UCPath - so we can not include it
, ''                                                     AS name_suffix
, p.userid
, CASE
    --WHEN j.business_unit        = 'DVMED' THEN 'UC Davis Medical Center'
    WHEN j.business_unit        = 'UCANR' THEN '#{emp_load_legal_entity_anr}'    --'Agriculture and Natural Resources'
    WHEN SUBSTR(j.deptid, 1, 3) = '049'   THEN '#{emp_load_legal_entity_som}'    --'UC Davis Schools of Health'
                                          ELSE '#{emp_load_legal_entity_campus}' --'UC Davis - Excluding Schools of Health'
  END AS legal_employer_name
-- Since we do not use HR department codes in Oracle - we use placeholders for UCD and ANR
, CASE j.business_unit
    --WHEN 'DVMED' THEN '132000B - UCD Medical Center'
    WHEN 'UCANR' THEN '#{emp_load_dept_anr}'    --'991000B - ANR'
    WHEN 'DVCMP' THEN '#{emp_load_dept_campus}' --'100000B - UC Davis Campus'
  END AS department_name
, CASE
    WHEN j.per_org = 'CWR' THEN 'CT' ELSE 'ET'
  END AS assignment_type
, CASE
    WHEN j.per_org = 'CWR' THEN 'C' ELSE 'E'
  END AS worker_type
, j.FTE
--, j.upd_bt_dtm AS job_last_updt_dt
--, e.upd_bt_dtm AS email_last_updt_dt
--, n.upd_bt_dtm AS name_last_updt_dt
, GREATEST(j.upd_bt_dtm,e.upd_bt_dtm,n.upd_bt_dtm) AS last_updt_dt
, EXTRACT( DAY FROM SYSDATE - GREATEST(j.upd_bt_dtm,e.upd_bt_dtm,n.upd_bt_dtm)) AS days_since_last_update
--, 'UNSET' AS derived_action
FROM #{ait_int_db_ucpath_schema}.ps_job j
-- Run a Sub-Query to get only the current name records for employees
JOIN (
    SELECT
      emplid
    -- The NVLs here should never trigger - but the data from UCPath is presently missing the last name
    -- so this is to ensure the data coming into Oracle has a last name
    , NVL(TRIM(partner_last_name), last_name ) AS last_name
    , NVL(TRIM(pref_first_name), first_name)   AS first_name
    , second_last_name                         AS middle_name
    , upd_bt_dtm
    FROM #{ait_int_db_ucpath_schema}.ps_names
    WHERE ( emplid, name_type, effdt ) IN (
      SELECT emplid, name_type, MAX(effdt)
      FROM #{ait_int_db_ucpath_schema}.ps_names
      WHERE effdt <= SYSDATE
        AND name_type = 'PRI' -- Only Primary Names
        AND eff_status = 'A'  -- Only active records
        AND dml_ind != 'D'
      GROUP BY emplid, name_type
    )
    AND dml_ind != 'D'
)                                                              n ON n.emplid     = j.emplid
-- Pull An Email Address For Each Employee
LEFT OUTER JOIN (
  SELECT DISTINCT
    emplid
   -- This pulls the first email address when sorted using the clause below
   -- The CASE causes the query to prefer @ucdavis over any other ucdavis or ANR email address
 , LOWER(TRIM(FIRST_VALUE(email_addr) OVER (
    PARTITION BY emplid
    ORDER BY
        CASE WHEN email_addr LIKE '%@ucdavis.edu' THEN 1 ELSE 2 END
      , PREF_EMAIL_FLAG DESC
   ))) AS email_addr
 , FIRST_VALUE(UPD_BT_DTM) OVER (
    PARTITION BY emplid
    ORDER BY
        CASE WHEN email_addr LIKE '%@ucdavis.edu' THEN 1 ELSE 2 END
      , PREF_EMAIL_FLAG DESC
   ) AS UPD_BT_DTM
  FROM #{ait_int_db_ucpath_schema}.ps_email_addresses
  WHERE dml_ind != 'D'
    -- Since we only allow these domains, filter to them.  If no email with these addresses exists
    -- in UCPath, it will cause a fall-back to look into the IAM table joined below.
    AND (LOWER(EMAIL_ADDR) LIKE '%ucdavis.edu' OR LOWER(EMAIL_ADDR) LIKE '%ucanr.edu')
) e ON e.emplid     = j.emplid
-- Ensure that there is only one record per employee
-- Analytic function gets the user ID associated with the most recent computing account created for that person
INNER JOIN (
  SELECT DISTINCT
    employeeid
 , FIRST_VALUE(userid) OVER (PARTITION BY employeeid ORDER BY uuid DESC) AS userid
 , FIRST_VALUE(email) OVER (PARTITION BY employeeid ORDER BY uuid DESC) AS email
  FROM #{ait_int_db_iam_schema}.iam_person
  WHERE employeeid IS NOT NULL
    AND userid IS NOT NULL
  )                                       p ON p.employeeid = j.emplid
WHERE
  -- Only look at the current effective record in the PS_JOB table
  ( j.emplid, j.empl_rcd, j.effdt, j.effseq ) IN (
    SELECT emplid, empl_rcd, TO_DATE(SUBSTR(effdtseq,1,INSTR(effdtseq,'_')-1),'YYYYMMDD') AS effdt, TO_NUMBER(SUBSTR(effdtseq,INSTR(effdtseq,'_')+1,10)) AS effseq
    FROM (
    SELECT emplid, empl_rcd, MAX(TO_CHAR(effdt,'YYYYMMDD')||'_'||effseq) AS effdtseq
        FROM #{ait_int_db_ucpath_schema}.ps_job
        WHERE effdt <= SYSDATE
          AND dml_ind != 'D'
          GROUP BY emplid, empl_rcd
    )
  )
  AND j.poi_type       = ' '      -- Exclude Person-Of-Interest records
  AND j.business_unit != 'DVMED'  -- Exclude Med Center
  and j.annual_rt     != 0        -- Exclude Without Salary (WOS) positions
  AND j.dml_ind       != 'D'      -- Ignore Deleted Records
  -- Filter to only include persons with UCD or ANR email addresses
  AND (COALESCE(e.email_addr, TO_CHAR(p.email)) LIKE '%ucdavis.edu'
    OR COALESCE(e.email_addr, TO_CHAR(p.email)) LIKE '%ucanr.edu')
  -- Used for testing initial extracts
  --AND j.job_indicator = 'P' -- Primary Job Only
  --AND j.empl_status NOT IN ( 'T', 'U', 'R', 'D' ) -- active employes only
  --AND GREATEST(j.upd_bt_dtm,NVL(e.upd_bt_dtm,date'1901-01-01'),n.upd_bt_dtm) >= CURRENT_TIMESTAMP - INTERVAL '5' YEAR
  -- e.upd_bt_dtm is NULL when contingent worker.
  --AND GREATEST(j.upd_bt_dtm,NVL(e.upd_bt_dtm,date'1901-01-01'),n.upd_bt_dtm) >= CURRENT_TIMESTAMP - INTERVAL ${lookback_interval}

ORDER BY emplid
