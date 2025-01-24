# 6.3.8 EPM

### EPM (Oracle Enterprise Performance Management) Integrations

#### Overview


#### Integration Components

1. Oracle GL Segments into EPM
2. Oracle GL Actuals into EPM
3. Something about a Budgetary Control Cube
4. UCPath Reference Data into EPM
5. UCPath Position Funding Data into EPM



#### EPM Segment Extract SQL

##### Main Table: `erp_account`

```sql
SELECT
     LEFT('AC_' || code, 80)  as  "Account"
    ,CASE WHEN code  in ('30000X', '40000X', '50000X', '60000X','70000X')  THEN 'GL Account'
     ELSE LEFT('AC_' || parent, 80) END as "Parent"
    ,LEFT(code || ' ' || description,80)   "Alias: Default"
    , 'FALSE' as "Valid for Consolidations"
    ,CASE WHEN summary_flag = 'N' THEN 'Store' ELSE 'Dynamic Calc' END as "Data Storage"
    , 'HSP_NOLINK' as "UDA"
    , 'Currency' as "Data Type"
    ,CASE WHEN account_type_code = '1' THEN 'Asset'
          WHEN account_type_code = '2' THEN 'Liability'
          when account_type_code = '3' THEN 'Equity'
          WHEN account_type_code ='4' or account_type_code ='7'  THEN 'Revenue'
          WHEN account_type_code = '5'  or account_type_code = '6' THEN 'Expense'
          ELSE 'Unknown' END as "Account Type"
    , 'UCD_BSO1' as "Source Plan Type"
    , 'TRUE' as "Plan Type (UCD_BSO1)"
    , '+' as "Aggregation (UCD_BSO1)"
    , 'TRUE' as "Plan Type (UCD_ASO1)"
    , '+' as "Aggregation (UCD_ASO1)"
    , 'FALSE' as "Plan Type (OEP_FS)"
    , '+' as "Aggregation (OEP_FS)"
    , 'FALSE' as "Plan Type (OEP_WFP)"
    , '+' as "Aggregation (OEP_WFP)"
    , 'FALSE' as "Plan Type (OEP_WPSC)"
    , '+' as "Aggregation (OEP_WPSC)"
    , 'FALSE' as "Plan Type (OEP_REP)"
    , '+' as "Aggregation (OEP_REP)"
FROM
(SELECT regexp_replace(a.code, '[^\w]+',' ','g') as code
        ,regexp_replace(a.description, '[^\w]+',' ','g') as description
        ,a.summary_flag
        ,substring(b.dep31_pk1_value,1,1) as account_type_code
        ,LEFT(regexp_replace(COALESCE(case when b.distance -1 = 0 then b.dep31_pk1_value
              when b.distance -1 = 1 then b.dep30_pk1_value
              when b.distance -1 = 2 then b.dep29_pk1_value
              when b.distance -1 = 3 then b.dep28_pk1_value
              when b.distance -1 = 4 then b.dep27_pk1_value
              when b.distance -1 = 5 then b.dep26_pk1_value
              when b.distance -1 = 6 then b.dep25_pk1_value
              when b.distance -1 = 7 then b.dep24_pk1_value
              when b.distance -1 = 8 then b.dep23_pk1_value
        end, 'GL Account'),'[^\w]+',' ','g'),80) as parent
FROM dev4_ERP.erp_account a
JOIN dev4_erp.gl_seg_val_hier_cf b on a.code = b.dep0_pk1_value
AND b.dep0_pk2_value = 'UCD Account'
AND b.tree_structure_code = 'GL_ACCT_FLEX'
JOIN dev4_erp.fnd_tree_and_version_vo c ON ((((c.tree_structure_code)::text = (b.tree_structure_code)::text)
AND ((c.tree_code)::text = (b.tree_code)::text)
AND ((c.tree_version_id)::text = (b.tree_version_id)::text)
AND ((c.status)::text = 'ACTIVE'::text)
AND ((CURRENT_DATE >=c.effective_start_date)
AND (CURRENT_DATE <= c.effective_end_date))))
WHERE a.code not in ('10000X', '20000X', '90000X')
) S1
where parent not like '1%' and parent not like '2%' and parent not like '9%'
ORDER BY "Parent", "Account"  ```

##### Main Table: `erp_fin_dept`

```sql
SELECT  LEFT('DP_' || regexp_replace(a.code, '[^\w]+',' ','g'),80) as "Financial Dept"
        ,LEFT(regexp_replace(COALESCE(case when b.distance -1 = 0 then 'DP_' || b.dep31_pk1_value
            when b.distance -1 = 1 then 'DP_' || b.dep30_pk1_value
            when b.distance -1 = 2 then 'DP_' || b.dep29_pk1_value
            when b.distance -1 = 3 then 'DP_' || b.dep28_pk1_value
            when b.distance -1 = 4 then 'DP_' || b.dep27_pk1_value
            when b.distance -1 = 5 then 'DP_' || b.dep26_pk1_value
            when b.distance -1 = 6 then 'DP_' || b.dep25_pk1_value
            when b.distance -1 = 7 then 'DP_' || b.dep24_pk1_value
            when b.distance -1 = 8 then 'DP_' || b.dep23_pk1_value
        end, 'OEP_Total Entity'), '[^\w]+',' ','g'), 80) as "Parent"
        ,regexp_replace(a.code, '[^\w]+',' ','g') || ' ' ||regexp_replace(a.description, '[^\w]+',' ','g') as "Alias: Default"
        , 'FALSE' as "Valid for Consolidations"
        , CASE WHEN summary_flag = 'N' THEN 'Store' ELSE 'Dynamic Calc' END as "Data Storage"
        , 'Unspecified' as "Data Type"
        , 'TRUE' as "Plan Type (UCD_BSO1)"
        , '+' as "Aggregation (UCD_BSO1)"
        , 'TRUE' as "Plan Type UCD_ASO1)"
        , '+' as "Aggregation (UCD_ASO1)"
        , 'TRUE' as "Plan Type OEP_FS)"
        , '+' as "Aggregation (OEP_FS)"
        , 'TRUE' as "Plan Type OEP_WFP)"
        , '+' as "Aggregation (OEP_WFP)"
        , 'TRUE' as "Plan Type OEP_WPSC)"
        , '+' as "Aggregation (OEP_WPSC)"
        , 'TRUE' as "Plan Type OEP_REP)"
        , '+' as "Aggregation (OEP_REP)"
FROM ERP.erp_fin_dept a
JOIN erp.gl_seg_val_hier_cf b on a.code = b.dep0_pk1_value
AND b.dep0_pk2_value = 'UCD Financial Department'
AND b.tree_structure_code = 'GL_ACCT_FLEX'
JOIN erp.fnd_tree_and_version_vo c ON ((((c.tree_structure_code)::text = (b.tree_structure_code)::text)
AND ((c.tree_code)::text = (b.tree_code)::text)
AND ((c.tree_version_id)::text = (b.tree_version_id)::text)
AND ((c.status)::text = 'ACTIVE'::text)
AND ((CURRENT_DATE >=c.effective_start_date)
AND (CURRENT_DATE <= c.effective_end_date))))
ORDER by "Parent", "Financial Dept"
```

##### Main Table: `erp_fund`

```sql
SELECT LEFT( 'FD_' || regexp_replace(a.code, '[^\w]+',' ','g'),80) as "Fund"
        ,LEFT(regexp_replace(COALESCE(case when b.distance -1 = 0 then 'FD_' ||b.dep31_pk1_value
            when b.distance -1 = 1 then 'FD_' ||b.dep30_pk1_value
            when b.distance -1 = 2 then 'FD_' ||b.dep29_pk1_value
            when b.distance -1 = 3 then 'FD_' ||b.dep28_pk1_value
            when b.distance -1 = 4 then 'FD_' ||b.dep27_pk1_value
            when b.distance -1 = 5 then 'FD_' ||b.dep26_pk1_value
            when b.distance -1 = 6 then 'FD_' ||b.dep25_pk1_value
            when b.distance -1 = 7 then 'FD_' ||b.dep24_pk1_value
            when b.distance -1 = 8 then 'FD_' ||b.dep23_pk1_value
        end, 'Fund_GL'), '[^\w]+',' ','g'),80) as "Parent"
        ,LEFT(regexp_replace(a.code, '[^\w]+',' ','g') || ' ' || regexp_replace(a.description, '[^\w]+',' ','g'),80) as "Alias: Default"
        , 'FALSE' as "Valid for Consolidations"
        , CASE WHEN summary_flag = 'N' THEN 'Store' ELSE 'Dynamic Calc' END as "Data Storage"
        , 'Unspecified' as "Data Type"
        , 'TRUE' as "Plan Type (UCD_BSO1)"
        , '+' as "Aggregation (UCD_BSO1)"
        , 'TRUE' as "Plan Type (UCD_ASO1)"
        , '+' as "Aggregation (UCD_ASO1)"
        , 'FALSE' as "Plan Type (OEP_FS)"
        , '+' as "Aggregation (OEP_FS)"
        , 'FALSE' as "Plan Type (OEP_WFP)"
        , '+' as "Aggregation (OEP_WFP)"
        , 'FALSE' as "Plan Type (OEP_WPSC)"
        , '+' as "Aggregation (OEP_WPSC)"
        , 'FALSE' as "Plan Type (OEP_REP)"
        , '+' as "Aggregation (OEP_REP)"
FROM ERP.erp_fund a
JOIN erp.gl_seg_val_hier_cf b on a.code = b.dep0_pk1_value
AND b.dep0_pk2_value = 'UCD Fund'
AND b.tree_structure_code = 'GL_ACCT_FLEX'
JOIN erp.fnd_tree_and_version_vo c ON ((((c.tree_structure_code)::text = (b.tree_structure_code)::text)
AND ((c.tree_code)::text = (b.tree_code)::text)
AND ((c.tree_version_id)::text = (b.tree_version_id)::text)
AND ((c.status)::text = 'ACTIVE'::text)
AND ((CURRENT_DATE >=c.effective_start_date)
AND (CURRENT_DATE <= c.effective_end_date))))
ORDER BY "Parent", "Fund"
```
##### Main Table: `erp_purpose`

```sql
SELECT  LEFT( 'PP_' || regexp_replace(a.code, '[^\w]+',' ','g'),80) as "Purpose"
        ,LEFT(regexp_replace(COALESCE(case when b.distance -1 = 0 then 'PP_' || b.dep31_pk1_value
            when b.distance -1 = 1 then 'PP_' || b.dep30_pk1_value
            when b.distance -1 = 2 then 'PP_' || b.dep29_pk1_value
            when b.distance -1 = 3 then 'PP_' || b.dep28_pk1_value
            when b.distance -1 = 4 then 'PP_' || b.dep27_pk1_value
            when b.distance -1 = 5 then 'PP_' || b.dep26_pk1_value
            when b.distance -1 = 6 then 'PP_' || b.dep25_pk1_value
            when b.distance -1 = 7 then 'PP_' || b.dep24_pk1_value
            when b.distance -1 = 8 then 'PP_' || b.dep23_pk1_value
           end, 'GL_Purpose'), '[^\w]+',' ','g'),80)as "Parent"
        ,regexp_replace(a.code, '[^\w]+',' ','g') || ' ' || regexp_replace(a.description, '[^\w]+',' ','g') as "Alias: Default"
        , 'FALSE' as "Valid for Consolidations"
        , CASE WHEN summary_flag = 'N' THEN 'Store' ELSE 'Dynamic Calc' END as "Data Storage"
        , 'Unspecified' as "Data Type"
        , 'TRUE' as "Plan Type (UCD_BSO1)"
        , '+' as "Aggregation (UCD_BSO1)"
        , 'TRUE' as "Plan Type UCD_ASO1)"
        , '+' as "Aggregation (UCD_ASO1)"
FROM ERP.erp_purpose a
JOIN erp.gl_seg_val_hier_cf b on a.code = b.dep0_pk1_value
AND b.dep0_pk2_value = 'UCD Purpose'
AND b.tree_structure_code = 'GL_ACCT_FLEX'
JOIN erp.fnd_tree_and_version_vo c ON ((((c.tree_structure_code)::text = (b.tree_structure_code)::text)
AND ((c.tree_code)::text = (b.tree_code)::text)
AND ((c.tree_version_id)::text = (b.tree_version_id)::text)
AND ((c.status)::text = 'ACTIVE'::text)
AND ((CURRENT_DATE >=c.effective_start_date)
AND (CURRENT_DATE <= c.effective_end_date))))
ORDER BY "Parent", "Purpose"
```
##### Main Table: `erp_project`

```sql
SELECT  LEFT('PJ_' ||  regexp_replace(code, '[^\w]+',' ','g'),80) as "Project"
        ,LEFT(regexp_replace(COALESCE(case when hierarchy_depth -1 = 0 then 'PJ_' ||parent_level_0_code
            when hierarchy_depth -1 = 1 then 'PJ_' || parent_level_1_code
            when hierarchy_depth -1 = 2 then 'PJ_' || parent_level_2_code
            when hierarchy_depth -1 = 3 then 'PJ_' || parent_level_3_code
            when hierarchy_depth -1 = 4 then 'PJ_' || parent_level_4_code
            when hierarchy_depth -1 = 5 then 'PJ_' || parent_level_5_code
        end, 'GL_Project'),'[^\w]+',' ','g'),80) as "Parent"
        ,regexp_replace(code, '[^\w]+',' ','g') || ' ' ||regexp_replace(description, '[^\w]+',' ','g') as "Alias: Default"
        , 'FALSE' as "Valid for Consolidations"
        , CASE WHEN summary_flag = 'N' THEN 'Store' ELSE 'Dynamic Calc' END as "Data Storage"
        , 'Unspecified' as "Data Type"
        , 'TRUE' as "Plan Type (UCD_BSO1)"
        , '+' as "Aggregation (UCD_BSO1)"
        , 'TRUE' as "Plan Type UCD_ASO1)"
        , '+' as "Aggregation (UCD_ASO1)"
        from dev4_erp.erp_project
```

##### Main Table: `erp_program`

```sql
SELECT  LEFT('PG_' ||  regexp_replace(a.code, '[^\w]+',' ','g'),80) as "Program"
       ,LEFT(regexp_replace(COALESCE(case when b.distance -1 = 0 then 'PG_' || b.dep31_pk1_value
            when b.distance -1 = 1 then 'PG_' ||b.dep30_pk1_value
            when b.distance -1 = 2 then 'PG_' ||b.dep29_pk1_value
            when b.distance -1 = 3 then 'PG_' ||b.dep28_pk1_value
            when b.distance -1 = 4 then 'PG_' ||b.dep27_pk1_value
            when b.distance -1 = 5 then 'PG_' ||b.dep26_pk1_value
            when b.distance -1 = 6 then 'PG_' ||b.dep25_pk1_value
            when b.distance -1 = 7 then 'PG_' ||b.dep24_pk1_value
            when b.distance -1 = 8 then 'PG_' ||b.dep23_pk1_value
        end, 'GL_Program'),'[^\w]+',' ','g'),80) as "Parent"
        ,LEFT(regexp_replace(a.code, '[^\w]+',' ','g') || ' ' || regexp_replace(a.description, '[^\w]+',' ','g'),80) as "Alias: Default"
        , 'FALSE' as "Valid for Consolidations"
        , CASE WHEN summary_flag = 'N' THEN 'Store' ELSE 'Dynamic Calc' END as "Data Storage"
        , 'Unspecified' as "Data Type"
        , 'TRUE' as "Plan Type (UCD_BSO1)"
        , '+' as "Aggregation (UCD_BSO1)"
        , 'TRUE' as "Plan Type UCD_ASO1)"
        , '+' as "Aggregation (UCD_ASO1)"
FROM ERP.erp_program a
JOIN erp.gl_seg_val_hier_cf b on a.code = b.dep0_pk1_value
AND b.dep0_pk2_value = 'UCD Program'
AND b.tree_structure_code = 'GL_ACCT_FLEX'
JOIN erp.fnd_tree_and_version_vo c ON ((((c.tree_structure_code)::text = (b.tree_structure_code)::text)
AND ((c.tree_code)::text = (b.tree_code)::text)
AND ((c.tree_version_id)::text = (b.tree_version_id)::text)
AND ((c.status)::text = 'ACTIVE'::text)
AND ((CURRENT_DATE >=c.effective_start_date)
AND (CURRENT_DATE <= c.effective_end_date))))
ORDER BY "Parent", "Program"
```
##### Main Table: `erp_activity`

```sql
SELECT  LEFT('AV_' || regexp_replace(a.code, '[^\w]+',' ','g'),80) as "Activity"
       ,LEFT(regexp_replace(COALESCE(case when b.distance -1 = 0 then 'AV_' || b.dep31_pk1_value
                    when b.distance -1 = 1   then 'AV_' || b.dep30_pk1_value
                    when b.distance -1 = 2   then 'AV_' || b.dep29_pk1_value
                    when b.distance -1 = 3   then 'AV_' || b.dep28_pk1_value
                    when b.distance -1 = 4   then 'AV_' || b.dep27_pk1_value
                    when b.distance -1 = 5   then 'AV_' || b.dep26_pk1_value
                    when b.distance -1 = 6   then 'AV_' || b.dep25_pk1_value
                    when b.distance -1 = 7   then 'AV_' || b.dep24_pk1_value
                    when b.distance -1 = 8   then 'AV_' || b.dep23_pk1_value
                    end, 'GL_Activity'),'[^\w]+',' ','g'),80) as "Parent"
        ,regexp_replace(a.code, '[^\w]+',' ','g') || ' ' || regexp_replace(a.description, '[^\w]+',' ','g') as "Alias: Default"
        , 'FALSE' as "Valid for Consolidations"
        , CASE WHEN summary_flag = 'N' THEN 'Store' ELSE 'Dynamic Calc' END as "Data Storage"
        , 'Unspecified' as "Data Type"
        , 'TRUE' as "Plan Type (UCD_BSO1)"
        , '+' as "Aggregation (UCD_BSO1)"
        , 'TRUE' as "Plan Type UCD_ASO1)"
        , '+' as "Aggregation (UCD_ASO1)"
FROM ERP.erp_activity a
JOIN erp.gl_seg_val_hier_cf b ON a.code = b.dep0_pk1_value
AND b.dep0_pk2_value = 'UCD Activity'
AND b.tree_structure_code = 'GL_ACCT_FLEX'
JOIN erp.fnd_tree_and_version_vo c ON ((((c.tree_structure_code)::text = (b.tree_structure_code)::text)
AND ((c.tree_code)::text = (b.tree_code)::text)
AND ((c.tree_version_id)::text = (b.tree_version_id)::text)
AND ((c.status)::text = 'ACTIVE'::text)
AND ((CURRENT_DATE >=c.effective_start_date)
AND (CURRENT_DATE <= c.effective_end_date))))
ORDER BY "Parent", "Activity"
```
##### Main Table: `erp_entity`

```sql
SELECT
LEFT('EN_' || regexp_replace(a.code, '[^\w]+',' ','g'), 80) AS  "UCD Entity"
, LEFT(regexp_replace(COALESCE(case when b.distance -1 = 0 then 'EN_' ||b.dep31_pk1_value
            when b.distance -1 = 1 then 'EN_' ||b.dep30_pk1_value
            when b.distance -1 = 2 then 'EN_' ||b.dep29_pk1_value
            when b.distance -1 = 3 then 'EN_' ||b.dep28_pk1_value
            when b.distance -1 = 4 then 'EN_' ||b.dep27_pk1_value
            when b.distance -1 = 5 then 'EN_' ||b.dep26_pk1_value
            when b.distance -1 = 6 then 'EN_' ||b.dep25_pk1_value
            when b.distance -1 = 7 then 'EN_' ||b.dep24_pk1_value
            when b.distance -1 = 8 then 'EN_' ||b.dep23_pk1_value
        end, 'GL_Entity'),'[^\w]+',' ','g') ,80) as "Parent"
, LEFT(regexp_replace(a.code, '[^\w]+',' ','g') || ' ' || regexp_replace(a.description, '[^\w]+',' ','g'), 80) as "Alias: Default"
, 'FALSE' as "Valid for Consolidations"
, CASE WHEN summary_flag = 'N' THEN 'Store' ELSE 'Dynamic Calc' END as "Data Storage"
, 'TRUE' as "Plan Type (UCD_BSO1)"
, '+' as "Aggregation (UCD_BSO1)"
, 'TRUE' as "Plan Type (UCD_ASO1)"
, '+' as "Aggregation (UCD_ASO1)"
, 'FALSE' as "Plan Type (UCD_ASO1)"
, '+' as "Aggregation (UCD_ASO1)"
, 'FALSE' as "Plan Type (OEP_REP)"
, '+' as "Aggregation (OEP_REP)"
FROM erp.erp_entity a
JOIN erp.gl_seg_val_hier_cf b on a.code = b.dep0_pk1_value
AND b.dep0_pk2_value = 'UCD Entity'
AND b.tree_structure_code = 'GL_ACCT_FLEX'
JOIN erp.fnd_tree_and_version_vo c ON ((((c.tree_structure_code)::text = (b.tree_structure_code)::text)
AND ((c.tree_code)::text = (b.tree_code)::text)
AND ((c.tree_version_id)::text = (b.tree_version_id)::text)
AND ((c.status)::text = 'ACTIVE'::text)
AND ((CURRENT_DATE >=c.effective_start_date)
AND (CURRENT_DATE <= c.effective_end_date))))
order by "Parent", "UCD Entity"
```


#### EPM Segment Extract SQL

#####  Table: `UC_JOB`

```sql
select  'JB_' || EMPL_CLASS AS "Job"
, 'OWP_Total Jobs' AS  "Parent"
, DESCR AS  "Alias: Default"
,'FALSE' AS  "Valid for Consolidations"
, 'Dynamic Calc' AS "Data Storage"
, 'Unspecified' as "Data Type"
, 'TRUE' AS "Plan Type (OEP_WFP)"
, '+' AS "Aggregation (OEP_WFP)"
, 'TRUE' AS "Plan Type (OEP_WFSC)"
, '+' as "Aggregation (OEP_WFSC)"
FROM UCPATH.UC_EMPLOYEE_CLASS_CURRENT
where EMPL_CLASS IS NOT NULL

UNION all

SELECT DISTINCT 'JB_' || JOBCODE AS "Job"
, 'JB_' || EMPL_CLASS AS  "Parent"
, JOBCODE ||' '|| JOBCODE_DESCR AS "Alias: Default"
,'FALSE' AS  "Valid for Consolidations"
, 'Dynamic Calc' AS "Data Storage"
, 'Unspecified' as "Data Type"
, 'TRUE' AS "Plan Type (OEP_WFP)"
, '+' AS "Aggregation(OEP_WFP)"
, 'TRUE' AS "Plan Type (OEP_WFSC)"
, '+' as "Aggregation (OEP_WFSC)"
FROM UCPATH.UC_JOB
WHERE JOBCODE != 'CONV'
/
```


#### EPM Segment Extract SQL

#####  Table: `UC_POSITION_FUNDING`

```sql
SELECT
   'FY' || SUBSTR(PF.FISCAL_YEAR, 3) AS "Fiscal Year"
   ,CASE WHEN JC.JOBCODE IS NULL OR JC.JOBCODE  = ' ' THEN 'No Job' ELSE 'JB_' || JC.JOBCODE  END AS "Job"
   ,CASE WHEN PF.DEPTID  IS NULL OR PF.DEPTID = ' '  THEN 'No Entity' ELSE 'DP_' || PF.DEPTID END AS "Department"
    ,CASE WHEN PF.UC_FUND_NBR IS NULL OR PF.UC_FUND_NBR= ' ' THEN 'No Fund' ELSE 'FD_' || PF.UC_FUND_NBR END AS "Fund"
    ,CASE WHEN PF.PROJECT_CD IS NULL OR  PF.PROJECT_CD = ' ' THEN 'No Project' ELSE 'PJ_' ||  PF.PROJECT_CD END AS "Project"
   ,'No Purpose' AS "Purpose"
   ,'No Activity' AS "Activity"
   , SUM(CASE WHEN JC.EMPLID IS NULL OR JC.EMPLID = ' ' THEN 0 ELSE 1 END) HEAD_COUNT
   , SUM(CASE WHEN JC.FTE != 1 OR JC.FTE IS NULL THEN 0 ELSE 1 END) FTE_COUNT
   , JC.ANNUAL_RT
   ,'OWP Unspecified Employee' AS "Employee"
   , CASE WHEN JC.UNION_CD IS NULL OR JC.UNION_CD = ' ' THEN 'No Union' ELSE 'UN_' ||JC. UNION_CD END AS "Union"
    FROM UC_POSITION_FUNDING PF
  LEFT OUTER JOIN  UC_JOB_CURRENT JC ON JC.POSITION_NBR = PF.POSITION_NBR
   GROUP BY
   PF.FISCAL_YEAR
   , JC.JOBCODE
   , PF.DEPTID
   , PF.UC_FUND_NBR
   , PF.PROJECT_CD
   , JC.ANNUAL_RT
   , JC.UNION_CD
```
#### EPM_006_EPCBS_WORKFORCE_BUDGET_INTEGRATION

#####  Table: `UC_JOB_CURRENT, UC_POSITION_FUNDING,EPM_ALTERNATE_FUND_V`
```sql
 SELECT
'JB_'  || JOBCODE as "Job"
, 'OEP_WFP' as "Data Load Cube Name"
,'OEP_Plan,'  || 'OEP_Working,' ||  'FY' || substr( (EXTRACT(Year FROM SYSDATE)) + 1, 3,4) || ',Jul,DP_' ||ERP_DEPT_CODE || ',' ||
 entity || ',' || fund_category || ',OWP_Basic Salary'
  as "Point-of-View"
 ,TO_CHAR(COMPRATE,'FM9999990D00') AS "OWP_Value"
 ,CASE WHEN COMPFREQUENCY = 1 THEN 'Monthly'
       WHEN COMPFREQUENCY = 2 THEN 'Bi_Weekly'
       WHEN COMPFREQUENCY = 3 THEN 'Hourly'
       WHEN COMPFREQUENCY = 4 THEN 'Annual'
       WHEN COMPFREQUENCY = 5 THEN  'Unknown' end as "OWP_Salary Basis"
   FROM
 (select distinct
 jobcode
 ,erp_dept_code
 ,CASE WHEN BUSINESS_UNIT = 'DVCMP' OR BUSINESS_UNIT = 'DVMED' THEN  'EN_PO_01' ELSE 'EN_PO_02' END as entity
 ,fund_category
 ,FIRST_VALUE(compfrequency) OVER (PARTITION BY JOBCODE,ERP_DEPT_CODE,BUSINESS_UNIT,FUND_CATEGORY ORDER BY compfrequency) AS compfrequency
 ,FIRST_VALUE(comprate) OVER (PARTITION BY JOBCODE,ERP_DEPT_CODE,BUSINESS_UNIT,FUND_CATEGORY ORDER BY compfrequency) AS comprate
 from
 (SELECT  distinct
 jobcode
 ,ERP_DEPT_CODE
 ,BUSINESS_UNIT
 ,CASE WHEN C.FUND_CATEGORY IS NULL THEN 'FD_PO_09' ELSE FUND_CATEGORY END AS FUND_CATEGORY
 ,avg(comprate) over (partition by jobcode, erp_dept_code, business_unit, fund_category, comp_frequency) as comprate
  , CASE WHEN A.COMP_FREQUENCY = 'A' THEN 4
        WHEN A.COMP_FREQUENCY = 'B' THEN 2
        WHEN A.COMP_FREQUENCY = 'H' THEN 3
        WHEN A.COMP_FREQUENCY = 'M'
        OR   A.COMP_FREQUENCY = 'UC_10'
        OR   A.COMP_FREQUENCY = 'UC_11'
        OR   A.COMP_FREQUENCY = 'UC_12'
        OR   A.COMP_FREQUENCY = 'UC_9M'
        OR   A.COMP_FREQUENCY = 'UC_FY'
        OR   A.COMP_FREQUENCY = 'UC912' THEN 1
       ELSE 5 end compfrequency
 FROM UC_JOB_CURRENT A
 JOIN UC_POSITION_FUNDING_CURRENT B ON A.POSITION_NBR = B.POSITION_NBR and a.DEPTID = b.DEPTID AND a.BUSINESS_UNIT= b.SETID
 JOIN CBGERMIN.COA_FIN_DEPT_MAPPING_V M ON M.FIN_COA_CD = B.FIN_COA_CD AND M.ACCOUNT_NBR = B.ACCOUNT_NBR
 LEFT OUTER JOIN CBGERMIN.EPM_ALTERNATE_FUND_V C ON B.UC_FUND_NBR = C.FUND
))

```

```sql

select
'JB_' || JOBCODE as "Job"
,'OEP_WFP' AS "Data Load Cube Name"
,'OEP_Plan,OEP_Working,FY' || substr(extract(year from sysdate) + 1, 3) || ',Jul,DP_'|| ERP_DEPT_CODE || ',' || entity || ',' || fund_category || ',No Property' as "Point-of-View"
, '07-01-' ||CASE WHEN extract(month from sysdate) < 7 THEN extract(year from sysdate) -1  else extract(year from sysdate) end as  "OWP_Start Date"
, 'Jul' AS "OWP_Start Month"
, Headcount as "OWP_Regular Headcount"
, FTE as "OWP_FTE"
, UC_CBR_GROUP2 || ' ' || CBR_GROUP_NAME AS "OWP_Pay Type"
, union_cd as "OWP_Skill Set"
from
(select distinct
  jobcode
 ,ERP_DEPT_CODE
 ,entity
 ,FUND_CATEGORY
 ,count(emplid) over (partition by jobcode, ERP_DEPT_CODE, entity, fund_category) as headcount
 ,first_value(union_cd) over (partition by jobcode, ERP_DEPT_CODE, entity, fund_category order by union_cd_count desc) as union_cd
 ,first_value(UC_CBR_GROUP2) over (partition by jobcode, ERP_DEPT_CODE, entity, fund_category order by cbr_count desc) as UC_CBR_GROUP2
 ,first_value(CBR_GROUP_NAME) over (partition by jobcode, ERP_DEPT_CODE, entity, fund_category order by cbr_count desc) as CBR_GROUP_NAME
 ,sum(fte) over (partition by jobcode, ERP_DEPT_CODE, entity, fund_category) as fte
 from
 (SELECT  distinct
 a.jobcode
 ,emplid
 ,ERP_DEPT_CODE
 ,CASE WHEN a.BUSINESS_UNIT = 'DVCMP' OR a.BUSINESS_UNIT = 'DVMED' THEN  'EN_PO_01' ELSE 'EN_PO_02' END as entity
 ,CASE WHEN C.FUND_CATEGORY IS NULL THEN 'FD_PO_09' ELSE FUND_CATEGORY END AS FUND_CATEGORY
 ,REPLACE(UNION_CD, '%', 3) AS union_cd
 ,count(a.UNION_CD) over (partition by a.jobcode, erp_dept_code, a.business_unit, fund_category, a.union_cd) as union_cd_count
 ,d.UC_CBR_GROUP2
 ,count(d.UC_CBR_GROUP2) over (partition by a.jobcode, erp_dept_code, a.business_unit, fund_category, a.UC_CBR_GROUP2) as cbr_count
 ,case when fte= 1 then 1 else 0 end fte
, replace(d.UC_CBR_GROUP_descr, '/', '-') as cbr_group_name
 FROM UC_JOB_CURRENT A
 JOIN UC_POSITION_FUNDING_CURRENT B ON A.POSITION_NBR = B.POSITION_NBR and a.DEPTID = b.DEPTID AND a.BUSINESS_UNIT= b.SETID
 JOIN CBGERMIN.COA_FIN_DEPT_MAPPING_V M ON M.FIN_COA_CD = B.FIN_COA_CD AND M.ACCOUNT_NBR = B.ACCOUNT_NBR
 LEFT OUTER JOIN CBGERMIN.EPM_ALTERNATE_FUND_V C ON B.UC_FUND_NBR = C.FUND
 LEFT OUTER JOIN cbgermin.jobcode_cbr d on a.JOBCODE = d.JOBCODE and a.BUSINESS_UNIT = d.BUSINESS_UNIT
))
```
