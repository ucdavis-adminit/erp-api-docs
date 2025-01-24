# 6.3.7.2 Labor Ledger to Oracle

### Overview

On a daily basis, we must extract the transactions from the UCPath Labor Ledger extract and related reference tables and post to Oracle.  This journal will post to both the GL and PPM sub-ledgers as well as potentially track data for use on the I-703 Writeback file.

This process must be able to proceed regardless of any problems with the transactions.  And, transactions must be well-validated before they are submitted to Oracle.  Any transactions which are deemed to be invalid will be adjusted to a valid kickout chartstring before being submitted to Oracle.

### Mapping Components

1. Salary Posting to GL Chartstrings
2. Salary Posting to PPM Chartstrings
3. Benefit Posting to GL Chartstrings
4. Benefit Posting to PPM Chartstrings
5. Other Transaction Posting to GL Chartstrings

### Notes

* Split incoming data by Run ID, Journal ID, and business unit.
* Possibly split also by employee for more granular processing.
* Most data processing will need to be done at the salary and fringe detail levels.
* The transformations needed on the incoming data has yet to be defined.
* Assumption: we will use the UCD Recharge journal source.
* CGA wants more payroll details to post to PPM.  The attributes and where to include them in the PPM Expense information is yet to be defined.



### OSHPD Account Derivation for UCDH

> (Pronounced "osh-pod")

As part of posting any salary transactions from the UCPath labor ledger which will post to the UCDH entity code in Oracle, we need to derive the account number for the transaction from attributes about the type of pay and the job code.  This will replace the account code derived within UCPath.

#### Rule Summary

For transactions which will post to the UCDH entity, we need to derive the account code based on whether the earnings activity is deemed "Productive" or "Non-Productive".  All Non-Productive transactions are posted to the single non-productive account.  Productive transactions are posted to an account based on an OSHPD code stored on the UCPath Job Code table.  Non-salary transactions, or transactions which have earn codes or job codes which have not been set up properly will be posted to the account provided from UCPath.

#### OSHPD Derivation Rules

> If, at any point, rules say to stop the process, then the original account value from UCPath should be used.

1. Rules only apply to salary transactions.  That is, transactions read from the `PS_UC_LL_SAL_DTL` table.
2. Rules only apply to the UCDH entity code.  (`3210`)  For any other entity code, stop the derivation process.
3. For the `ERNCD` on the record, look up the `UC_OSHPD_EARNS` value in the `UC_ERNCD_TBL` table.
4. If no record is found, or the field is not a `P` or `N`, then stop the derivation process.
5. If the value is `N`, then use `502901` for the account code.
6. If the value is `P`, then:
   1. Look up the `UC_OSHPD_CODE` from the `UC_JOBCODE_CURRENT` table.
   2. If no record is found, or it is not a 2-character code, then stop the derivation process.
   3. Look up the code in the lookup table below to get the OSHPD account.  If no match found, then stop the derivation process.
   4. If an account is found, then use that for the account code.


#### OSHPD Account Lookup Table

| UC_OSHPD_CODE | Account | Meaning                    |
| ------------- | ------- | -------------------------- |
| 00            | 502000  | Management and Supervisors |
| 01            | 502100  | Tech and Specialists       |
| 02            | 502200  | RN                         |
| 03            | 502300  | LVN                        |
| 04            | 502400  | AIDS & ORD                 |
| 05            | 502500  | Clerical                   |
| 06            | 502600  | ENV & FOOD                 |
| 07            | 502700  | Physicians                 |
| 08            | 502800  | Non-Physician              |
| 09            | 502900  | Other                      |


### Get Most Recent Journal Partitions
 >(Partitons are upd_bt_nbr, run_id, substr(journal_id,3), business_unit, journal_type)

Periodically get the max batch number from ucpath_labor_ledger_job_status
and look for partition data from LL_SUM_DTL and LL_FRNG_DTL that have
batch numbers greater than the max batch number in the job status table.
If found, insert the partitions with a 'LOADED' status.

### Data Flow Design
#### 1. Get max batch number from ucpath_labor_ledger_job_status from the staging schema in the postgres database
```sql
   select max(batch_nbr) as max_batch_nbr
from #{int_db_staging_schema}.ucpath_labor_ledger_job_status
```
#### 2. Set batch number as an attribute
#### 3. Look for partition data from SAL_DTL and FRNG_DTL having batch number greater than the max batch number
```sql
    SELECT distinct UPD_BT_NBR as batch_nbr
    , RUN_ID
    , SUBSTR(JOURNAL_ID,3) JOURNAL_PARTITION
    , BUSINESS_UNIT
    , APPL_JRNL_ID
    , CASE WHEN appl_jrnl_id = 'PAYROLL' AND JOURNAL_ID LIKE 'PJ%' AND  run_id not like '%BB' THEN 'EXPENSE'
          WHEN appl_jrnl_id = 'PAYROLL' AND JOURNAL_ID LIKE 'PT%' THEN 'COST_TRANSFER'
          WHEN appl_jrnl_id = 'ACCRUAL' AND JOURNAL_ID LIKE 'PJ%' THEN 'ACCRUAL'
          WHEN appl_jrnl_id = 'ACCRL_RVSL' AND JOURNAL_ID LIKE 'PJ%' THEN 'ACCRUAL'
          ELSE 'UNKNOWN' END AS journal_type
    ,'LOADED' as status
    ,sysdate as loaded_timestamp
    FROM #{ait_int_db_ucpath_schema}.ps_uc_ll_sal_dtl
    WHERE upd_bt_nbr > ${max.batch.nbr} AND LENGTH(OPERATING_UNIT) > 1
    UNION
    SELECT distinct UPD_BT_NBR
    , RUN_ID
    , SUBSTR(JOURNAL_ID,3) JOURNAL_PARTITION
    , BUSINESS_UNIT
    , APPL_JRNL_ID
    , CASE WHEN appl_jrnl_id = 'PAYROLL' AND JOURNAL_ID LIKE 'PJ%' AND  run_id not like '%BB' THEN 'EXPENSE'
          WHEN appl_jrnl_id = 'PAYROLL' AND JOURNAL_ID LIKE 'PT%' THEN 'COST_TRANSFER'
          WHEN appl_jrnl_id = 'ACCRUAL' AND JOURNAL_ID LIKE 'PJ%' THEN 'ACCRUAL'
          WHEN appl_jrnl_id = 'ACCRL_RVSL' AND JOURNAL_ID LIKE 'PJ%' THEN 'ACCRUAL'
          ELSE 'UNKNOWN' END AS journal_type
    ,'LOADED' as status
    , sysdate as loaded_timestamp
    FROM #{ait_int_db_ucpath_schema}.ps_uc_ll_frng_dtl
    WHERE upd_bt_nbr > ${max.batch.nbr} AND LENGTH(OPERATING_UNIT) >1

```

#### 4. If found, insert partition data into the ucpath_labor_ledger_job_status table




### Load UCPath Data into ucpath_labor_ledger having a 'LOADED' status from ucpath_labor_ledger_job_status
Periodically, find partition data in ucpath_labor_ledger_job_status
with a 'LOADED' status.  If found, query ucpath PS_UC_LL_SAL_DTL,
PS_UC_LL_FRNG_DTL, PS_UC_LL_DED_DTL tables for labor ledger data by
partitions (upd_bt_nbr, run_id, journal_partition, business_unit_gl, appl_jrnl_id)
and insert data into ucpath_labor_ledger.  Run the stored procedure which does
the following:
1) Identify PPM projects in SAL and FRNG tables and mark as such
2) Populate line_type - ppmSegments, glSegments
3) Update task if PPM project and task not populated
4) Identify OSHPD records and and update oshpd_account field
5) Identify RPNI records and update rpni fields
6) Identify BiWeekly Accruals fund, department, purpose and update as such
7) Populate ppm chart string values
8) Populate kickout chartstring values
   Mark rows in
   ucpath_labor_ledger_job_status with status = 'READY'

### Data Flow Design
#### 1.  Get partition records from ucpath_labor_ledger_job_status in 'LOADED' status
```sql
  SELECT batch_nbr
  , run_id
  , journal_partition
  , business_unit
  , appl_jrnl_id
  FROM #{int_db_staging_schema}.ucpath_labor_ledger_job_status
  WHERE status = 'LOADED'

```
#### 2.  Split Partitions
#### 3.  Set Partitions as attributes
#### 4.  Get Salary data from ps_uc_ll_sal_dtl table in AIT_INT
```sql
   SELECT
  RUN_ID
  , JOURNAL_ID
  , SUBSTR(JOURNAL_ID,3) JOURNAL_PARTITION
  , CASE WHEN appl_jrnl_id = 'PAYROLL' AND JOURNAL_ID LIKE 'PJ%' AND  run_id not like '%BB' THEN 'EXPENSE'
        WHEN appl_jrnl_id = 'PAYROLL' AND JOURNAL_ID LIKE 'PT%' THEN 'COST_TRANSFER'
        WHEN appl_jrnl_id = 'ACCRUAL' AND JOURNAL_ID LIKE 'PJ%' THEN 'ACCRUAL'
        WHEN appl_jrnl_id = 'ACCRL_RVSL' AND JOURNAL_ID LIKE 'PJ%' THEN 'ACCRUAL'
        ELSE 'UNKNOWN' END AS journal_type
  , JOURNAL_LINE
  , JRNL_LN_REF
  , to_char(BUDGET_DT, 'yyyy/mm/dd') as budget_dt
  , to_char(JOURNAL_DATE, 'yyyy/mm/dd') as journal_date
  , SAL.EMPLID
  , TRIM(SUBSTR(OPERATING_UNIT,1,4)) AS OPERATING_UNIT_ENTITY
  , TRIM(SUBSTR(PROJECT_ID,1,10)) AS PROJECT
  , TRIM(SUBSTR(PRODUCT,1,6)) AS PRODUCT_TASK
  , TRIM(SUBSTR(ACCOUNT,1,6)) AS ACCOUNT
  , TRIM(SUBSTR(FUND_CODE,1,5)) AS FUND
  , TRIM(SUBSTR(DEPTID_CF,1,7)) AS FIN_DEPT
  , TRIM(SUBSTR(PROGRAM_CODE,1,3)) AS PROGRAM
  , TRIM(SUBSTR(CLASS_FLD,1,2)) AS CLASS_FLD_PURPOSE
  , TRIM(SUBSTR(CHARTFIELD1,1,6)) AS CHARTFIELD1_ACTIVITY
  , TRIM(SUBSTR(CHARTFIELD2,1,7)) AS CHARTFIELD_2_AWARD
  , SAL.BUSINESS_UNIT
  , UC_DECODE
  , UC_OSHPD_CODE
  , to_char(UC_EARN_END_DT, 'yyyy/mm/dd') as uc_earn_end_dt
  , to_char(ACCOUNTING_DT, 'yyyy/mm/dd') as accounting_dt
  , MONETARY_AMOUNT
  , SAL.upd_bt_nbr
  , HOURS1
  , UC_DRV_EFT_PCT
  , JOBCODE
  , FTE
  , UC_PAY_RUN_DESCR
  , ERNCD
  , UC_SCT_ID
  , IN_PROCESS_FLG
  , LINE_DESCR
  , to_char(SAL.CR_BT_DTM, 'yyyy/mm/dd') AS CR_BT_DTM
  ,'SALARY' as source
  FROM #{ait_int_db_ucpath_schema}.PS_UC_LL_SAL_DTL SAL
  LEFT JOIN #{ait_int_db_ucpath_schema}.PS_job JOB ON SAL.EMPLID = JOB.EMPLID AND SAL.EMPL_RCD = JOB.EMPL_RCD
  WHERE (job.EMPLID, job.EMPL_RCD, job.EFFDT, job.EFFSEQ) IN (
              SELECT EMPLID, EMPL_RCD, TO_DATE(SUBSTR(EFFDTSEQ,1,INSTR(EFFDTSEQ,'_')-1),'YYYYMMDD') AS EFFDT, TO_NUMBER(SUBSTR(EFFDTSEQ,INSTR(EFFDTSEQ,'_')+1,10)) AS EFFSEQ
              FROM (
                SELECT EMPLID, EMPL_RCD, MAX(TO_CHAR(EFFDT,'YYYYMMDD')||'_'||EFFSEQ) AS EFFDTSEQ
                  FROM #{ait_int_db_ucpath_schema}.PS_JOB
                  WHERE EFFDT <= SYSDATE
                    AND DML_IND != 'D'
                  GROUP BY EMPLID, EMPL_RCD
              )
          )
  AND job.DML_IND != 'D'
  AND SAL.UPD_BT_NBR = ${batch_nbr}
  and SAL.run_id = '${run_id}'
  and SAL.journal_id IN ( 'PJ' || '${journal_partition}', 'PT' || '${journal_partition}' )
  and appl_jrnl_id = '${appl_jrnl_id}'
  and SAL.business_unit = '${business_unit}'
  and length(OPERATING_UNIT) > 1


```
#### 5.  Load data into ucpath_labor_ledger (postgres)
#### 6.  Get Fringe data from ps_uc_ll_frng_dtl table in AIT_INT
```sql
  SELECT
  RUN_ID
  , JOURNAL_ID
  , SUBSTR(JOURNAL_ID,3) JOURNAL_PARTITION
  , CASE WHEN appl_jrnl_id = 'PAYROLL' AND JOURNAL_ID LIKE 'PJ%' AND  run_id not like '%BB' THEN 'EXPENSE'
        WHEN appl_jrnl_id = 'PAYROLL' AND JOURNAL_ID LIKE 'PT%' THEN 'COST_TRANSFER'
        WHEN appl_jrnl_id = 'ACCRUAL' AND JOURNAL_ID LIKE 'PJ%' THEN 'ACCRUAL'
        WHEN appl_jrnl_id = 'ACCRL_RVSL' AND JOURNAL_ID LIKE 'PJ%' THEN 'ACCRUAL'
        ELSE 'UNKNOWN' END AS journal_type
  , JOURNAL_LINE
  , JRNL_LN_REF
  , TO_CHAR(BUDGET_DT, 'YYYY/MM/DD') as budget_dt
  , TO_CHAR(JOURNAL_DATE, 'YYYY/MM/DD') as journal_date
  , FRNG.EMPLID
  , TRIM(SUBSTR(OPERATING_UNIT,1,4)) AS OPERATING_UNIT_ENTITY
  , TRIM(SUBSTR(PROJECT_ID,1,10)) AS PROJECT
  , TRIM(SUBSTR(PRODUCT,1,6)) AS PRODUCT_TASK
  , TRIM(SUBSTR(ACCOUNT,1,6)) AS ACCOUNT
  , TRIM(SUBSTR(FUND_CODE,1,5)) AS FUND
  , TRIM(SUBSTR(DEPTID_CF,1,7)) AS FIN_DEPT
  , TRIM(SUBSTR(PROGRAM_CODE,1,3)) AS PROGRAM
  , TRIM(SUBSTR(CLASS_FLD,1,2)) AS CLASS_FLD_PURPOSE
  , TRIM(SUBSTR(CHARTFIELD1,1,6)) AS CHARTFIELD1_ACTIVITY
  , TRIM(SUBSTR(CHARTFIELD2,1,7)) AS CHARTFIELD_2_AWARD
  , CHARTFIELD3 AS CHARTFIELD3_BUSINESS_UNIT_GL
  , FRNG.BUSINESS_UNIT
  , to_char(UC_EARN_END_DT, 'yyyy/mm/dd') as uc_earn_end_dt
  , TO_CHAR(ACCOUNTING_DT, 'YYYY/MM/DD')  as accounting_dt
  , MONETARY_AMOUNT
  , FRNG.upd_bt_nbr
  , JOBCODE
  , FTE
  , UC_PAY_RUN_DESCR
  , UC_SCT_ID
  , IN_PROCESS_FLG
  , LINE_DESCR
  , to_char(FRNG.CR_BT_DTM, 'yyyy/mm/dd') AS CR_BT_DTM
  ,'FRINGE' as source
  FROM #{ait_int_db_ucpath_schema}.PS_UC_LL_FRNG_DTL FRNG
  LEFT JOIN #{ait_int_db_ucpath_schema}.PS_job JOB ON FRNG.EMPLID = JOB.EMPLID AND FRNG.EMPL_RCD = JOB.EMPL_RCD
  WHERE (job.EMPLID, job.EMPL_RCD, job.EFFDT, job.EFFSEQ) IN (
              SELECT EMPLID, EMPL_RCD, TO_DATE(SUBSTR(EFFDTSEQ,1,INSTR(EFFDTSEQ,'_')-1),'YYYYMMDD') AS EFFDT, TO_NUMBER(SUBSTR(EFFDTSEQ,INSTR(EFFDTSEQ,'_')+1,10)) AS EFFSEQ
              FROM (
                SELECT EMPLID, EMPL_RCD, MAX(TO_CHAR(EFFDT,'YYYYMMDD')||'_'||EFFSEQ) AS EFFDTSEQ
                  FROM #{ait_int_db_ucpath_schema}.PS_JOB
                  WHERE EFFDT <= SYSDATE
                    AND DML_IND != 'D'
                  GROUP BY EMPLID, EMPL_RCD
              )
          )
  AND job.DML_IND != 'D'
  AND FRNG.UPD_BT_NBR = ${batch_nbr}
  and FRNG.run_id = '${run_id}'
  and FRNG.journal_id IN ( 'PJ' || '${journal_partition}', 'PT' || '${journal_partition}' )
  and appl_jrnl_id = '${appl_jrnl_id}'
  and FRNG.business_unit = '${business_unit}'
  and length(OPERATING_UNIT) > 1




```
#### 7.  Load data into ucpath_labor_ledger (postgres)
#### 8.  Get Deduction data from ps_uc_ll_ded_dtl table in AIT_INT
```sql
    SELECT
    RUN_ID
    , JOURNAL_ID
    , SUBSTR(JOURNAL_ID,3) JOURNAL_PARTITION
    , CASE WHEN appl_jrnl_id = 'PAYROLL' AND JOURNAL_ID LIKE 'XX%' AND  run_id not like '%BB' THEN 'EXPENSE'
          WHEN appl_jrnl_id = 'PAYROLL' AND JOURNAL_ID LIKE 'XT%' THEN 'COST_TRANSFER'
          WHEN appl_jrnl_id = 'ACCRUAL' AND JOURNAL_ID LIKE 'XX%' THEN 'ACCRUAL'
          WHEN appl_jrnl_id = 'ACCRL_RVSL' AND JOURNAL_ID LIKE 'XX%' THEN 'ACCRUAL'
          ELSE 'UNKNOWN' END AS journal_type
    , JOURNAL_LINE
    , JRNL_LN_REF
    , TO_CHAR(BUDGET_DT, 'YYYY/MM/DD') as budget_dt
    , TO_CHAR(JOURNAL_DATE, 'YYYY/MM/DD') as journal_date
    , DED.EMPLID
    , TRIM(SUBSTR(OPERATING_UNIT,1,4)) AS OPERATING_UNIT_ENTITY
    , TRIM(SUBSTR(PROJECT_ID,1,10)) AS PROJECT
    , TRIM(SUBSTR(PRODUCT,1,6)) AS PRODUCT_TASK
    , TRIM(SUBSTR(ACCOUNT,1,6)) AS ACCOUNT
    , TRIM(SUBSTR(FUND_CODE,1,5)) AS FUND
    , TRIM(SUBSTR(DEPTID_CF,1,7)) AS FIN_DEPT
    , TRIM(SUBSTR(PROGRAM_CODE,1,3)) AS PROGRAM
    , TRIM(SUBSTR(CLASS_FLD,1,2)) AS CLASS_FLD_PURPOSE
    , TRIM(SUBSTR(CHARTFIELD1,1,6)) AS CHARTFIELD1_ACTIVITY
    , TRIM(SUBSTR(CHARTFIELD2,1,7)) AS CHARTFIELD_2_AWARD
    , DED.BUSINESS_UNIT
    , TO_CHAR(ACCOUNTING_DT, 'YYYY/MM/DD')  as accounting_dt
    , MONETARY_AMOUNT
    , DED.upd_bt_nbr
    , JOBCODE
    , FTE
    , UC_PAY_RUN_DESCR
    , UC_SCT_ID
    , IN_PROCESS_FLG
    , LINE_DESCR
    , to_char(DED.CR_BT_DTM, 'yyyy/mm/dd') AS CR_BT_DTM
    ,'DEDUCTION' as source
    FROM #{ait_int_db_ucpath_schema}.PS_UC_LL_DED_DTL DED
    LEFT JOIN #{ait_int_db_ucpath_schema}.PS_job JOB ON DED.EMPLID = JOB.EMPLID AND DED.EMPL_RCD = JOB.EMPL_RCD
    WHERE (job.EMPLID, job.EMPL_RCD, job.EFFDT, job.EFFSEQ) IN (
                SELECT EMPLID, EMPL_RCD, TO_DATE(SUBSTR(EFFDTSEQ,1,INSTR(EFFDTSEQ,'_')-1),'YYYYMMDD') AS EFFDT, TO_NUMBER(SUBSTR(EFFDTSEQ,INSTR(EFFDTSEQ,'_')+1,10)) AS EFFSEQ
                FROM (
                  SELECT EMPLID, EMPL_RCD, MAX(TO_CHAR(EFFDT,'YYYYMMDD')||'_'||EFFSEQ) AS EFFDTSEQ
                    FROM #{ait_int_db_ucpath_schema}.PS_JOB
                    WHERE EFFDT <= SYSDATE
                      AND DML_IND != 'D'
                    GROUP BY EMPLID, EMPL_RCD
                )
            )
    AND job.DML_IND != 'D'
    AND DED.UPD_BT_NBR = ${batch_nbr}
    and DED.run_id = '${run_id}'
    and DED.journal_id IN ( 'XX' || '${journal_partition}', 'XT' || '${journal_partition}' )
    and appl_jrnl_id = '${appl_jrnl_id}'
    and DED.business_unit = '${business_unit}'
    and length(OPERATING_UNIT) > 1


```
#### 9.  Load data into ucpath_labor_ledger (postgres)
#### 10. Run stored procedure (ucpath_labor_ledger_transformation_rules)
```sql
CREATE PROCEDURE test_staging.ucpath_labor_ledger_transformation_rules ()
LANGUAGE 'sql'
AS $$
  update test_staging.ucpath_labor_ledger a
  set is_ppm = 'Y'
  ,business_unit_name = b.business_unit_name
  from (select project_number,business_unit_name from test_erp.ppm_project) b
  where a.project = b.project_number
  AND SOURCE IN ('SALARY', 'FRINGE');

  update test_staging.ucpath_labor_ledger a
  set line_type = 'ppmSegments'
  from (select project_number,business_unit_name from test_erp.ppm_project ) b
  where a.project = b.project_number;

  update test_staging.ucpath_labor_ledger a
  set line_type = 'glSegments'
  where line_type is null;

  update test_staging.ucpath_labor_ledger
  set product_task = 'TASK01'
  where is_ppm = 'Y'and (product_task is null or length(product_task) <> 6);

  update test_staging.ucpath_labor_ledger a
  set oshpd_account = '502901'
  where  source = 'SALARY' and journal_type = 'EXPENSE'
  AND OPERATING_UNIT_ENTITY = '3210'
  and ERNCD in ('FEN', 'FEL') and uc_decode = 'N';

  update test_staging.ucpath_labor_ledger a
  set oshpd_account = b.account
  from (select account, code from test_staging.ucpath_labor_ledger_oshpd) b
   where
   a.uc_oshpd_code = b.code
   and a.journal_type = 'EXPENSE'
   and a.source = 'SALARY'
   AND a.operating_unit_entity = '3210'
   AND a.ERNCD in ('FEN', 'FEL')
   and a.uc_decode  = 'P';

  update test_staging.ucpath_labor_ledger a
  set rpni_fund = b.fund,
  rpni_department = b.department,
  rpni_purpose = b.purpose
  from(select fund, department, purpose, entity from test_staging.ucpath_labor_ledger_rpni)b
  where
  a.operating_unit_entity = b.entity
  and substr(journal_id,1,2) in ('XX', 'XT')
  and account = '213925';

  update test_staging.ucpath_labor_ledger a
  set bwa_fund = b.fund,
  bwa_department = b.department,
  bwa_purpose = b.purpose
  from(select fund, department, purpose, entity, journal_prefix, account from test_staging.ucpath_labor_ledger_bi_weekly_accrual)b
  where
  a.operating_unit_entity = b.entity
  and substr(journal_id,1,2)  = b.journal_prefix
  and a.account = b.account;

  update test_staging.ucpath_labor_ledger set
  ppm_to_gl_fund = '13U10',
  ppm_to_gl_dept = '1000005',
  ppm_to_gl_account = '238X00',
  ppm_to_gl_purpose = '00',
  ppm_to_gl_program = '000',
  ppm_to_gl_project = '0000000000',
  ppm_to_gl_activity =  '000000'
  where line_type = 'ppmSegments';

  update test_staging.ucpath_labor_ledger set
  kickout_entity = '3110',
  kickout_account= '102030',
  kickout_fund=  '13U10',
  kickout_department = '1000003',
  kickout_purpose = '00',
  kickout_program = '000',
  kickout_project = '0000000000',
  kickout_activity = '000000'
  where  business_unit = 'DVCMP';


  update test_staging.ucpath_labor_ledger set
  kickout_entity = '3210',
  kickout_account= '102030',
  kickout_fund=  '13U10',
  kickout_department = '1000003',
  kickout_purpose = '00',
  kickout_program = '000',
  kickout_project = '0000000000',
  kickout_activity = '000000'
  where business_unit = 'DVMED';

  update test_staging.ucpath_labor_ledger set
  kickout_entity = '3310',
  kickout_account= '102120',
  kickout_fund=  '13U10',
  kickout_department = '1000003',
  kickout_purpose = '00',
  kickout_program = '000',
  kickout_project = '0000000000',
  kickout_activity = '000000'
  where business_unit = 'UCANR';
  $$

```
#### 11. Update partitions to 'READY' status in ucpath_labor_ledger_job_status
```sql
  UPDATE #{int_db_staging_schema}.ucpath_labor_ledger_job_status
  SET status = 'READY',
  ready_timestamp = current_timestamp
  WHERE status = 'LOADED'

```





### Process and Send Labor Ledger data to Oracle
Gets the partitions in the ready status.Within a loop, flow processes each partition
by fetching a configurable number of emplIds. Continue processing in
a second loop until all emplids are processed.

Within second loop, flow validates GL records and PPM records.  If PPM records
don't pass validation, they are converted to GL. GL records are balanced and sent
to kafka.  PPM records from the SAL and FRNG tables are sent to PPM via kafka


### Data Flow Design
#### 1.  Get partitions from ucpath_labor_ledger_run_stats that are in 'READY' status
```sql
    SELECT batch_nbr
    , run_id
    , journal_partition
    , journal_type
    , business_unit
    FROM #{int_db_staging_schema}.ucpath_labor_ledger_job_status
    WHERE status = 'READY'
    ORDER BY batch_nbr, run_id, journal_partition, journal_type, business_unit
    LIMIT 1
```
#### 2.  Start while loop for partitions in ready status. break out on condition (${executesql.row.count:equals(0)})
#### 3.  Set Partitions as attributes
#### 4.  Update subset of emplids  status to READY in ucpath_labor_ledger
```sql
    update
    #{int_db_staging_schema}.ucpath_labor_ledger
    set empl_process = 'READY'
    where upd_bt_nbr = ${batch_nbr}
    and journal_type = '${journal_type}'
    and run_id = '${run_id}'
    and journal_partition = '${journal_partition}'
    and business_uniT = '${business_unit}'
    AND EMPLID IN (SELECT DISTINCT EMPLID FROM #{int_db_staging_schema}.ucpath_labor_ledger
    WHERE
    upd_bt_nbr = ${batch_nbr}
    and journal_type = '${journal_type}'
    and run_id = '${run_id}'
    and journal_partition = '${journal_partition}'
    and business_unit = '${business_unit}'
    and empl_process  is null
    order by emplid
    LIMIT #{empl_batch_size})
```

#### 5.  Get records in 'READY' status

```sql
SELECT
coalesce( ppm_to_gl_dept, rpni_department, fin_dept) as department
        ,coalesce(ppm_to_gl_account, oshpd_account, account ) as account
        ,coalesce(ppm_to_gl_purpose,bwa_purpose, rpni_purpose,class_fld_purpose) as  purpose
        ,coalesce(ppm_to_gl_program, program) as program
        ,coalesce(ppm_to_gl_fund, bwa_fund, rpni_fund,fund) as fund
        ,coalesce(ppm_to_gl_project, project) as gl_project
        ,project as ppm_project
        ,coalesce(oshpd_account,account) as ppm_account
        ,coalesce(bwa_department, rpni_department, fin_dept) as ppm_deptid
        ,coalesce(rpni_fund, fund) as ppm_fund
        ,emplid
        ,product_task
        ,hours1
        ,jobcode
        ,fte
        ,uc_drv_eft_pct
        ,chartfield1_activity as activity
        ,chartfield2_award as award
        ,kickout_entity
        ,kickout_account
        ,kickout_fund
        ,kickout_department
        ,kickout_purpose
        ,kickout_program
        ,kickout_project
        ,kickout_activity
        ,run_id
        ,journal_id
        ,journal_partition
        ,journal_line
        ,jrnl_ln_ref
        ,line_descr
        ,business_unit
        ,uc_pay_run_descr
        ,uc_earn_end_dt
        ,journal_date
        ,accounting_dt
        ,operating_unit_entity as entity
        ,upd_bt_nbr
        ,journal_type
        ,line_type
        ,is_ppm
        ,source
        ,business_unit_name
        ,in_process_flg
        ,cr_bt_dtm
        ,sum(monetary_amount) as monetary_amount
FROM #{int_db_staging_schema}.ucpath_labor_ledger
where  journal_type = '${journal_type}'
and run_id = '${run_id}'
and journal_partition = '${journal_partition}'
and business_unit = '${business_unit}'
AND EMPL_PROCESS = 'READY'
GROUP BY
coalesce( ppm_to_gl_dept, rpni_department, fin_dept)
        ,coalesce(ppm_to_gl_account, oshpd_account, account )
        ,coalesce(ppm_to_gl_purpose,bwa_purpose, rpni_purpose,class_fld_purpose)
        ,coalesce(ppm_to_gl_program, program)
        ,coalesce(ppm_to_gl_fund, bwa_fund, rpni_fund,fund)
        ,coalesce(ppm_to_gl_project, project)
        ,project
        ,coalesce(oshpd_account,account)
        ,coalesce(bwa_department, rpni_department, fin_dept)
        ,coalesce(rpni_fund, fund)
        ,emplid
        ,product_task
        ,hours1
        ,jobcode
        ,fte
        ,uc_drv_eft_pct
        ,chartfield1_activity
        ,chartfield2_award
        ,kickout_entity
        ,kickout_account
        ,kickout_fund
        ,kickout_department
        ,kickout_purpose
        ,kickout_program
        ,kickout_project
        ,kickout_activity
        ,run_id
        ,journal_id
        ,journal_partition
        ,journal_line
        ,jrnl_ln_ref
        ,line_descr
        ,business_unit
        ,uc_pay_run_descr
        ,uc_earn_end_dt
        ,journal_date
        ,accounting_dt
        ,operating_unit_entity
        ,upd_bt_nbr
        ,journal_type
        ,line_type
        ,is_ppm
        ,source
        ,business_unit_name
        ,in_process_flg
        ,cr_bt_dtm

```
#### 6.  Start second loop for emplids not processed within journal partitions. break out on condition (${executesql.row.count:equals(0)})
#### 7.  Convert to JSON
#### 8.  Transform Records for Validation
```sql
    select department
    ,account
    ,purpose
    ,program
    ,fund
    ,gl_project as glProject
    ,ppm_project as ppmProject
    ,ppm_account as expenditureType
    ,ppm_deptid as organization
    ,ppm_fund as fundingSource
    ,emplid
    ,product_task as task
    ,hours1
    ,jobcode
    ,fte
    ,uc_drv_eft_pct
    ,activity
    ,award
    ,kickout_entity
    ,kickout_account
    ,kickout_fund
    ,kickout_department
    ,kickout_purpose
    ,kickout_program
    ,kickout_project
    ,kickout_activity
    ,run_id
    ,journal_id
    ,journal_partition
    ,journal_line
    ,jrnl_ln_ref
    ,line_descr
    ,business_unit
    ,business_unit_name
    ,uc_pay_run_descr
    ,uc_earn_end_dt
    ,journal_date
    ,accounting_dt
    ,entity
    ,upd_bt_nbr
    ,journal_type
    ,line_type as lineType
    ,is_ppm
    ,in_process_flg
    ,cr_bt_dtm
    ,source
    ,monetary_amount
    from flowfile
```
#### 9.  Attach schema
#### 10. Validate GL Segments
#### 11. Replace invalid gl objects with GL-Kickout string
```groovy script

def checkIfAnyInvalidResults(record) {
  if ( record.getValue("line_valid")== false)  {
    record.setValue("entity", record.getValue("kickout_entity") );
    record.setValue("fund", record.getValue("kickout_fund") );
    record.setValue("department", record.getValue("kickout_department") );
    record.setValue("account", record.getValue("kickout_account") );
    record.setValue("purpose", record.getValue("kickout_purpose") );
    record.setValue("program", record.getValue("kickout_program"));
    record.setValue("glProject", record.getValue("kickout_project") );
    record.setValue("activity", record.getValue("kickout_activity") );
   }
}

checkIfAnyInvalidResults(record);
return record;
```
#### 12. Validate PPM Segments
#### 13. Replace invalid ppm objects with GL-Kickout string and convert line-type to 'glSegments'
```groovy script

def checkIfAnyInvalidResults(record) {
   if ( record.getValue("lineType")=="ppmSegments" && record.getValue("line_valid" )== false) {
    record.setValue("entity", record.getValue("kickout_entity") );
    record.setValue("fund", record.getValue("kickout_fund") );
    record.setValue("department", record.getValue("kickout_department") );
    record.setValue("account", record.getValue("kickout_account") );
    record.setValue("purpose", record.getValue("kickout_purpose") );
    record.setValue("program", record.getValue("kickout_program"));
    record.setValue("glProject", record.getValue("kickout_project") );
    record.setValue("activity", record.getValue("kickout_activity") );
    record.setValue("lineType", "glSegment" );
   }
}

checkIfAnyInvalidResults(record);
return record;

```
#### 14. Split into PPM and GL Lines
#### 15. For PPM create group id attribute
#### 16. For PPM summarize data
```sql
 select
       run_id
       ,journal_id
       ,journal_partition
       ,journal_line
        ,jrnl_ln_ref
       ,journal_date
       ,emplid
       ,jobcode
       ,hours1
       ,uc_drv_eft_pct
       ,ppmProject
       ,task
       ,expenditureType
       ,organization
       ,award
       ,uc_earn_end_dt
       ,accounting_dt
       ,fte
       ,upd_bt_nbr
	   ,business_unit_name
       ,fundingSource
       ,sum(monetary_amount) as monetary_amount
      from flowfile
      where is_ppm = 'Y' and lineType = 'ppmSegments'
       group by
         run_id
       ,journal_id
       ,journal_partition
       ,journal_line
       ,jrnl_ln_ref
       ,journal_date
       ,emplid
       ,jobcode
       ,hours1
       ,uc_drv_eft_pct
       ,ppmProject
       ,task
       ,expenditureType
       ,organization
       ,award
       ,uc_earn_end_dt
       ,accounting_dt
       ,fte
       ,upd_bt_nbr
       ,business_unit_name
       ,fundingSource


```
#### 17. For PPM set schema and filename
#### 18. For PPM convert to FBDI format
```sql
  SELECT
   BUSINESS_UNIT_NAME AS BUSINESS_UNIT
  ,'UC Path' as USER_TRANSACTION_SOURCE
  ,'UC Path' as DOCUMENT_NAME
  ,'UC Path' as DOC_ENTRY_NAME
  , RUN_ID as BATCH_NAME
  , '${group_id}' AS BATCH_DESCRIPTION
  , JOURNAL_DATE AS EXPENDITURE_ITEM_DATE
  , PPMPROJECT AS PROJECT_NUMBER
  , TASK TASK_NUMBER
  , EXPENDITURETYPE AS EXPENDITURE_TYPE
  , ORGANIZATION AS ORGANIZATION_NAME
  , UC_EARN_END_DT AS EXPENDITURE_COMMENT
  , ACCOUNTING_DT AS GL_DATE
  , MONETARY_AMOUNT AS DENOM_RAW_COST
  , UPD_BT_NBR AS USER_DEF_ATTRIBUTE1
  , HOURS1 AS USER_DEF_ATTRIBUTE2
  , UC_DRV_EFT_PCT AS USER_DEF_ATTRIBUTE3
  , JOBCODE AS USER_DEF_ATTRIBUTE4
  , EMPLID AS PERSON_NUMBER
  , FTE AS USER_DEF_ATTRIBUTE5
  , FUNDINGSOURCE AS FUNDING_SOURCE_NUMBER
  ,'${ppm.transaction.ref.prefix}'||'-' || ROW_NUMBER() OVER()||'-'|| JOURNAL_LINE as ORIG_TRANSACTION_REFERENCE
  FROM FLOWFILE

```
#### 19. For PPM publish to kafka
#### 20. For PPM update ppm_completed timestamp
```sql
    update #{int_db_staging_schema}.ucpath_labor_ledger_job_status
    set ppm_completed_timestamp = current_timestamp
    where
    BATCH_NBR = ${batch_nbr}
    and RUN_ID = ${run_id}
    and JOURNAL_PARTITION = '${journal_partition}'
    and appl_jrnl_id = '${appl_jrnl_id}'
    and business_unit = '${business_unit}'
```
#### 21. For GL Route Flowfiles according to journal_type (Expense, Accrual) vs (Cost_Transfer)
#### 22. For GL Transform Expense, Accrual objects
```sql
select  department
        ,account
        ,purpose
        ,program
        ,fund
        ,glProject
        ,activity
        ,kickout_entity
        ,kickout_account
        ,kickout_fund
        ,kickout_department
        ,kickout_purpose
        ,kickout_program
        ,kickout_project
        ,kickout_activity
        ,run_id
        ,journal_id
        ,journal_partition
        ,case when lineType = 'ppmSegments' then 0 else journal_line end as journal_line
        ,jrnl_ln_ref
        ,business_unit
        ,uc_pay_run_descr
        ,journal_date
        ,accounting_dt
        ,entity
        ,upd_bt_nbr
        ,monetary_amount
        ,case when lineType = 'ppmSegments' then null else line_descr end as line_descr
        ,cr_bt_dtm
        ,lineType
        from flowfile
```
#### 23. For GL Transform Cost Transfer objects
```sql
select  department
        ,account
        ,purpose
        ,program
        ,fund
        ,glProject
        ,activity
        ,kickout_entity
        ,kickout_account
        ,kickout_fund
        ,kickout_department
        ,kickout_purpose
        ,kickout_program
        ,kickout_project
        ,kickout_activity
        ,run_id
        ,journal_id
        ,journal_partition
        ,case when lineType = 'ppmSegments' then 0 else journal_line end as journal_line
        ,jrnl_ln_ref
        ,business_unit
        ,uc_pay_run_descr
        ,journal_date
        ,accounting_dt
        ,entity
        ,upd_bt_nbr
        ,monetary_amount
        ,case when lineType = 'ppmSegments' then null else line_descr end as line_descr
        ,cr_bt_dtm
        ,lineType
         from flowfile
         where in_process_flg <> 'Z'
```
#### 24. For GL Create Debits and Credits
```sql
select  department
        ,account
        ,purpose
        ,program
        ,fund
        ,glProject
        ,activity
        ,kickout_entity
        ,kickout_account
        ,kickout_fund
        ,kickout_department
        ,kickout_purpose
        ,kickout_program
        ,kickout_project
        ,kickout_activity
        ,run_id
        ,journal_id
        ,journal_partition
        ,journal_line
        ,jrnl_ln_ref
        ,business_unit
        ,uc_pay_run_descr
        ,journal_date
        ,line_descr
        ,accounting_dt
        ,entity
        ,cr_bt_dtm
        ,case when monetary_amount < 0 then abs(monetary_amount) else null end as creditAmount
        ,case when monetary_amount > 0 then abs(monetary_amount) else null end as debitAmount
       from flowfile
```
#### 25. For GL Validate debits equal credits
```groovy script
def flowFile = session.get();
if(!flowFile) return;
try {
  def inputStream = session.read(flowFile);
  def journalData = new groovy.json.JsonSlurper().parse(inputStream);
  def debitTotal  = 0.00;
  def creditTotal = 0.00;
  //def totalCost = Double.parseDouble(flowFile.getAttribute('UpdatedTotalCost'));

  journalData.each {
    if ( it.debitAmount ) debitTotal += it.debitAmount;
    if ( it.creditAmount ) creditTotal += it.creditAmount;
  }

  inputStream.close();

  flowFile = session.putAttribute(flowFile, 'laborLedger.balanced', String.valueOf(debitTotal== creditTotal));
flowFile = session.putAttribute(flowFile, 'laborLedger.debitTotal', String.valueOf(debitTotal));
flowFile = session.putAttribute(flowFile, 'laborLedger.creditTotal', String.valueOf(creditTotal));
flowFile = session.putAttribute(flowFile, 'laborLedger.total', String.valueOf(debitTotal - creditTotal));
  session.transfer(flowFile, REL_SUCCESS);
} catch(e) {
  log.error("Error while validating journal entries", e);
  session.transfer(flowFile, REL_FAILURE);
}

```
#### 26. For GL Route according to Balanced/Unbalanced objects
#### 27. For GL, out of balance records, create a balancing record to the flowfile
```sql

      select  department
        ,account
        ,purpose
        ,program
        ,fund
        ,glProject
        ,activity
        ,entity
        ,run_id
        ,journal_id
        ,journal_partition
        ,journal_line
        ,jrnl_ln_ref
        ,business_unit
        ,uc_pay_run_descr
        ,journal_date
        ,line_descr
        ,accounting_dt
        ,cr_bt_dtm
        ,debitAmount
        ,creditAmount
      from flowfile
union all
	SELECT distinct kickout_department
	    ,kickout_account
	    ,kickout_purpose
	    ,kickout_program
	    ,kickout_fund
	    ,kickout_Project
	    ,kickout_activity
        ,kickout_entity
        ,run_id
        ,first_value(journal_id) over (order by journal_id)
        ,journal_partition
        ,0 as journal_line
        ,jrnl_ln_ref
        ,business_unit
        ,'Balancing Line' as uc_pay_run_descr
        ,first_value(journal_date) over (order by journal_date)
        ,'Balancing Line' as line_descr
        ,first_value(accounting_dt) over (order by accounting_dt)
        ,first_value(cr_bt_dtm) over (order by cr_bt_dtm)
       ,case when cast(${laborLedger.total} as double) < 0 then abs(cast(${laborLedger.total} as double)) else null end as debitAmount
       ,case when cast(${laborLedger.total} as double) > 0 then abs(cast(${laborLedger.total} as double)) else null end as creditAmount
FROM FLOWFILE
```
#### 28. For GL Re-Validate
#### 29. For GL, if balanced, route to GL Summary, else send to failure
#### 30. For GL balanced records, summarize the data
```sql
select department
       ,activity
       ,purpose
       ,program
       ,fund
       ,glProject
       ,account
       ,run_id
       ,journal_id
       ,journal_line
       ,jrnl_ln_ref
       ,uc_pay_run_descr
       ,journal_date
       ,line_descr
       ,accounting_dt
       ,entity
       ,cr_bt_dtm
       ,NULL as debitamount
       ,sum(creditamount) as creditamount
from flowfile
where creditAmount is not null
GROUP BY
       department
       ,activity
       ,purpose
       ,program
       ,fund
       ,glProject
       ,account
       ,run_id
       ,journal_id
       ,journal_line
       ,jrnl_ln_ref
       ,uc_pay_run_descr
       ,journal_date
       ,line_descr
       ,accounting_dt
       ,entity
       ,cr_bt_dtm
 UNION ALL
       select department
       ,activity
       ,purpose
       ,program
       ,fund
       ,glProject
       ,account
       ,run_id
       ,journal_id
       ,journal_line
       ,jrnl_ln_ref
       ,uc_pay_run_descr
       ,journal_date
       ,line_descr
       ,accounting_dt
       ,entity
       ,cr_bt_dtm
       ,sum (debitamount) as debitamount
       ,NULL as creditamount
from flowfile
where debitamount is not null
GROUP BY
       department
       ,activity
       ,purpose
       ,program
       ,fund
       ,glProject
       ,account
       ,run_id
       ,journal_id
       ,journal_line
       ,jrnl_ln_ref
       ,uc_pay_run_descr
       ,journal_date
       ,line_descr
       ,accounting_dt
       ,entity
       ,cr_bt_dtm
```
#### 31. For GL Create group_id attribute
#### 32. For GL set schema and filename
#### 33. For GL convert to FBDI format
```sql
  SELECT RUN_ID AS ATTRIBUTE6
  , JOURNAL_ID AS REFERENCE6
  , JOURNAL_LINE AS ATTRIBUTE1
  , LINE_DESCR AS ATTRIBUTE2
  , UC_PAY_RUN_DESCR AS ATTRIBUTE3
  , JOURNAL_DATE AS DATE_CREATED
  , ACCOUNTING_DT AS ACCOUNTING_DATE
  , ENTITY AS SEGMENT1
  , ACCOUNT AS SEGMENT4
  , FUND AS SEGMENT2
  , DEPARTMENT AS SEGMENT3
  , GLPROJECT AS SEGMENT7
  , PROGRAM AS SEGMENT6
  , PURPOSE AS SEGMENT5
  , ACTIVITY AS SEGMENT8
  , CR_BT_DTM AS ATTRIBUTE5
  , DEBITAMOUNT AS ENTERED_DR
  , CREDITAMOUNT AS ENTERED_CR
  , 'UCD UCPath' AS USER_JE_SOURCE_NAME
  , 'UCD Recharge' AS USER_JE_CATEGORY_NAME
  , '${group_id }'  AS GROUP_ID
  , '${group_id }' AS REFERENCE4
  ,'UCD RECHARGES' AS ATTRIBUTE_CATEGORY
  FROM FLOWFILE
```
#### 34. For GL Set Kafka and job attributes
#### 35. For GL publish to GL FBDI outbound topic
#### 36. Update Records in 'READY' status to 'PROCESSED' status in ucpath_labor_ledger
```sql
update
#{int_db_staging_schema}.ucpath_labor_ledger
set empl_process = 'PROCESSED'
,group_id = '${group_id}'
where journal_type = '${journal_type}'
and run_id = '${run_id}'
and journal_partition = '${journal_partition}'
and business_unit = '${business_unit}'
and upd_bt_nbr = ${batch_nbr}
AND empl_process = 'READY'
```
#### 37. Grab the next set of emplids to process
#### 38. If no more to process then update the journal partion record in ucpath_labor_ledger_job_status to 'COMPLETED'
```sql
update
#{int_db_staging_schema}.ucpath_labor_ledger_job_status
set status = 'COMPLETED'
where journal_type = '${journal_type}'
and run_id = '${run_id}'
and journal_partition = '${journal_partition}'
and business_unit = '${business_unit}'
and batch_nbr = ${batch_nbr}
```
#### 39. If there are more to ucpath_labor_ledger_job_status records to process, grab the next row in 'READY' status
#### 40. When all records are processed/sent to kafka, copy records from ucpath_labor_ledger to ucpath_labor_ledger_history
```sql
insert into #{int_db_staging_schema}.ucpath_labor_ledger_history
	(run_id
	,journal_id
	,journal_partition
	,journal_line
	,jrnl_ln_ref
	,erncd
	,budget_dt
	,journal_date
	,emplid
	,operating_unit_entity
	,project
	,product_task
	,account
	,fund
	,fin_dept
	,program
	,chartfield1_activity
	,chartfield2_award
	,uc_earn_end_dt
	,accounting_dt
	,monetary_amount
	,hours1
	,uc_drv_eft_pct
	,jobcode
	,fte
	,uc_pay_run_descr
	,source
	,journal_type
	,is_ppm
	,upd_bt_nbr
	,legal_entity_name
	,uc_oshpd_code
	,uc_decode
	,business_unit
	,legal_entity_code
	,uc_sct_id
	,in_process_flg
	,oshpd_account
	,rpni_fund
	,rpni_department
	,rpni_purpose
	,bwa_fund
	,bwa_department
	,bwa_purpose
	,ppm_to_gl_dept
	,ppm_to_gl_account
	,ppm_to_gl_purpose
	,ppm_to_gl_program
	,ppm_to_gl_fund
	,ppm_to_gl_project
	,class_fld_purpose
	,kickout_account
	,kickout_fund
	,kickout_department
	,kickout_purpose
	,kickout_program
	,kickout_project
	,kickout_activity
	,empl_process
	,empl_group
	,kickout_entity
	,group_id
	,ppm_to_gl_activity
	,sponsored_project_flag
	,business_unit_name
	,line_descr
	,cr_bt_dtm
	,line_type
	)
select
run_id
	,journal_id
	,journal_partition
	,journal_line
	,jrnl_ln_ref
	,erncd
	,budget_dt
	,journal_date
	,emplid
	,operating_unit_entity
	,project
	,product_task
	,account
	,fund
	,fin_dept
	,program
	,chartfield1_activity
	,chartfield2_award
	,uc_earn_end_dt
	,accounting_dt
	,monetary_amount
	,hours1
	,uc_drv_eft_pct
	,jobcode
	,fte
	,uc_pay_run_descr
	,source
	,journal_type
	,is_ppm
	,upd_bt_nbr
	,legal_entity_name
	,uc_oshpd_code
	,uc_decode
	,business_unit
	,legal_entity_code
	,uc_sct_id
	,in_process_flg
	,oshpd_account
	,rpni_fund
	,rpni_department
	,rpni_purpose
	,bwa_fund
	,bwa_department
	,bwa_purpose
	,ppm_to_gl_dept
	,ppm_to_gl_account
	,ppm_to_gl_purpose
	,ppm_to_gl_program
	,ppm_to_gl_fund
	,ppm_to_gl_project
	,class_fld_purpose
	,kickout_account
	,kickout_fund
	,kickout_department
	,kickout_purpose
	,kickout_program
	,kickout_project
	,kickout_activity
	,empl_process
	,empl_group
	,kickout_entity
	,group_id
	,ppm_to_gl_activity
	,sponsored_project_flag
	,business_unit_name
	,line_descr
	,cr_bt_dtm
	,line_type
	from #{int_db_staging_schema}.ucpath_labor_ledger
```
#### 41. Delete all records from ucpath_labor_ledger
```sql
delete from #{int_db_staging_schema}.ucpath_labor_ledger
```










