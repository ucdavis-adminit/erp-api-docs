# 6.3.19 TSA Recharge

### Overview

On a configurable basis, this flow will query UCPath for TSA (department 062120) for Recharge information.
If new recharges are found, recharges and their offsets will be calculated for both GL and PPM projects. Recharges
will be posted to Oracle and detail information will be sent to Glide.


### Notes

 * Next Phase of development: Get position data for each emplid and position combination.  Create and send billing statements. Send billing
  statement data to TSA.



### Data Flow Design
#### 1. Get max batch number and max invoice number from ucpath_labor_ledger_job_status from the staging schema in the postgres database
```sql
   select batch_nbr, max_invoice_nbr
  from #{int_db_staging_schema}.tsa_recharge_job_status
  where batch_nbr = (select max(batch_nbr)
  from #{int_db_staging_schema}.tsa_recharge_job_status)

```
#### 2. Set batch number and invoice number as attributes
#### 3. Look for a single batch number greater than max batch number in tsa_recharge_job_status
```sql
   select distinct first_value(upd_bt_nbr) over(order by upd_bt_nbr ASC) as upd_bt_nbr from #{ait_int_db_ucpath_schema}.ps_uc_ll_sal_dtl
   where upd_bt_nbr > ${max.batch.nbr}
```

#### 4. If recharges found, continue with flow

#### 5. set next batch number as attribute

#### 6. Set Recharge Attributes
| Attribute Name                | Attribute Value                                                       |
| ----------------------------- | --------------------------------------------------------------------- |
| `consumer.id`                 | UCD Temp Svcs Application                                             |
| `consumer.notes.prefix`       | TSA Recharges for                                                     |
| `glide.extract.enabled`       | Y                                                                     |
| `glide.summarization.enabled` | Y                                                                     |
| `journal.category.name`       | UCD Recharge                                                          |
| `journal.reference.prefix`    | UCD TSA Recharges                                                     |
| `kafka.key`                   | ${UUID()}                                                             |
| `kafka.topic`                 | in.#{instance_id}.internal.json.gl_journal_flattened                  |
| `kickout.gl.chartstring`      | 3110-12101-HRTR005-775000-72-000-0000000000-000000-0000-000000-000000 |
| `kickout.gl.enabled`          | Y                                                                     |
| `offsetAccount`               | 775000                                                                |
| `offsetDepartment`            | HRTR005                                                               |
| `offsetEntity`                | 3110                                                                  |
| `offsetFund`                  | 12100                                                                 |
| `offsetProject`               | GLR0000002                                                            |
| `offsetPurpose`               | 72                                                                    |
| `request.source.prefix`       | UCD_TSA_RECHARGE                                                      |
| `request.source.type`         | sftp                                                                  |
| `schema.name`                 | in.#{instance_id}.internal.json.gl_journal_flattened-value            |
| `source.id`                   | UCD_TSA_RECHARGE_${now():format("yyyyMMddHHmmss")}                    |

#### 7. delete records from tsa_recharge

#### 8. Get recharge data
```sql
   SELECT
    SAL.EMPLID
    ,TO_CHAR(SAL.PAY_END_DT,'YYYY/MM/DD') AS PAY_END_DT
    ,SAL.POSITION_NBR
    ,SAL.ERNCD
    ,SAL.HOURS1
    ,job.HOURLY_RT
    , TRIM(SUBSTR(SAL.OPERATING_UNIT,1,4)) AS OPERATING_UNIT_ENTITY
    , TRIM(SUBSTR(SAL.PROJECT_ID,1,10)) AS PROJECT
    , TRIM(SUBSTR(SAL.PRODUCT,1,6)) AS PRODUCT_TASK
    , TRIM(SUBSTR(SAL.ACCOUNT,1,6)) AS ACCOUNT
    , TRIM(SUBSTR(SAL.FUND_CODE,1,5)) AS FUND
    , TRIM(SUBSTR(SAL.DEPTID_CF,1,7)) AS FIN_DEPT
    , TRIM(SUBSTR(SAL.PROGRAM_CODE,1,3)) AS PROGRAM
    , TRIM(SUBSTR(SAL.CLASS_FLD,1,2)) AS CLASS_FLD_PURPOSE
    , TRIM(SUBSTR(SAL.CHARTFIELD1,1,6)) AS CHARTFIELD1_ACTIVITY
    , NAME.FIRST_NAME
    ,NAME.LAST_NAME
    ,h.uc_prd_accrual AS ACCRUAL
    ,AR.UC_ASSESS_RATE 	AS CBR_RATE
    , MAX(TO_CHAR(JOB.EFFDT,'YYYYMMDD')||'_'||JOB.EFFSEQ) EFFDTSQ
    , sal.MONETARY_AMOUNT as salary_amount
    ,frng.cbr_amount
    ,frng.vla_amount
    FROM #{ait_int_db_ucpath_schema}.PS_UC_LL_SAL_DTL SAL
    JOIN #{ait_int_db_ucpath_schema}.PS_JOB JOB ON SAL.EMPLID = JOB.EMPLID AND SAL.EMPL_RCD = JOB.EMPL_RCD AND SAL.POSITION_NBR = JOB.POSITION_NBR
    LEFT OUTER JOIN #{ait_int_db_ucpath_schema}.UC_PERSON_NAME NAME ON SAL.EMPLID = NAME.EMPLID
    JOIN #{ait_int_db_ucpath_schema}.UC_JOB_ASSESS_RATE AR ON AR.EMPLID = SAL.EMPLID AND AR.EMPL_RCD = SAL.EMPL_RCD AND AR.EFFDT = JOB.EFFDT AND AR.EFFSEQ = JOB.EFFSEQ
    left outer join #{ait_int_db_ucpath_schema}.UC_EMPLOYEE_BALANCE_HISTORY h on h.emplid = sal.emplid and h.ASOFDATE = sal.PAY_END_DT and pin_code = 'UCAE SICK USA'
    left outer join (select EMPLID
    , POSITION_NBR
    , UPD_BT_NBR
    , sum(case when account = '508000' then MONETARY_AMOUNT else 0 end)  as cbr_amount
    , sum(case when account = '508300' then MONETARY_AMOUNT else 0 end)  as  vla_amount
    from #{ait_int_db_ucpath_schema}.ps_uc_ll_frng_dtl
    where DML_IND != 'D'
    and APPL_JRNL_ID = 'PAYROLL'
    and upd_bt_nbr = ${next.batch.nbr}
    group by
    EMPLID
    , POSITION_NBR
    , UPD_BT_NBR)  frng on sal.emplid = frng.emplid and sal.position_nbr = frng.position_nbr and frng.upd_bt_nbr = 40128
    WHERE
    SAL.UPD_BT_NBR = ${next.batch.nbr}
    AND SAL.APPL_JRNL_ID = 'PAYROLL'
    AND SAL.ACCOUNT NOT IN ('UCPT218', '2005000')
    AND JOB.DEPTID ='062120'
    AND JOB.DML_IND != 'D'
    and sal.dml_ind != 'D'
    AND LENGTH(SAL.OPERATING_UNIT) > 1
    GROUP BY
    SAL.EMPLID
    ,SAL.PAY_END_DT
    ,SAL.POSITION_NBR
    ,SAL.ERNCD
    ,SAL.HOURS1
    ,job.HOURLY_RT
    , SAL.OPERATING_UNIT
    , SAL.PROJECT_ID
    ,SAL.PRODUCT
    , SAL.ACCOUNT
    ,SAL.FUND_CODE
    ,SAL.DEPTID_CF
    , SAL.PROGRAM_CODE
    , SAL.CLASS_FLD
    , SAL.CHARTFIELD1
    ,NAME.FIRST_NAME
    ,NAME.LAST_NAME
    ,AR.UC_ASSESS_RATE
    ,h.uc_prd_accrual
    ,sal.MONETARY_AMOUNT
    ,frng.cbr_amount
    ,frng.vla_amount

```
#### 9. Insert into tsa_recharge

#### 10. Create Invoice Numbers for emplid, position_nbr combinations
```sql
     update  #{int_db_staging_schema}.tsa_recharge r
  set invoice_number = b.new_invoice_number
  from
  (select emplid, position_nbr, ${max.invoice.nbr} + ROW_NUMBER() OVER () as new_invoice_number from
  (select distinct emplid, position_nbr
  from #{int_db_staging_schema}.tsa_recharge)a)b
  where r.emplid = b.emplid
  and r.position_nbr = b.position_nbr
```
#### 11.Get Joined Recharge Data with ppm_project Data
```sql
     select
    SUBSTR( emplid || '_' || position_nbr || '_' ||last_name || '_' || first_name,0, 100)  as lineDescription
    ,pay_end_dt
    ,operating_unit_entity as entity
    ,project
    ,case when p.project_number is not null then 'ppmSegments' else 'glSegments' end as lineType
    ,account
    ,fund
    ,fin_dept
    ,program
    ,class_fld_purpose as purpose
    ,chartfield1_activity  as activity
    ,product_task as task
    ,sum(salary_amount) + sum(cbr_amount) + sum(vla_amount) as direct_expenses
    ,sum(accrual)*hourly_rt as sick_leave_wages
    ,sum(accrual)*hourly_rt*cbr_rate as cbr_on_sick_leave
    ,COALESCE(sum(accrual)*hourly_rt*cbr_rate + sum(accrual)*hourly_rt, 0) as total_sla
    ,sum(salary_amount) as earn_code_wages
    ,sum(cbr_amount) as cbr_amount
    ,sum(vla_amount) as vla_amount
    ,sum(accrual) as accrual
    ,hourly_rt
    ,cbr_rate
    ,CAST(invoice_number as BIGINT) AS invoice_number
    from #{int_db_staging_schema}.TSA_RECHARGE r
    left outer join #{int_db_erp_schema}.ppm_project p on r.project = p.project_number
    group by
    emplid
    ,position_nbr
    ,pay_end_dt
    ,operating_unit_entity
    ,project
    ,account
    ,fund
    ,fin_dept
    ,program
    ,class_fld_purpose
    ,chartfield1_activity
    ,product_task
    ,hourly_rt
    ,cbr_rate
    ,cbr_amount
    ,vla_amount
    ,first_name
    ,last_name
    ,p.project_number
    ,invoice_number
```
#### 12.Calculate Total Recharge
```sql
   select
  lineDescription
  ,pay_end_dt
  ,entity
  ,project
  ,account
  ,fund
  ,fin_dept
  ,program
  ,purpose
  ,activity
  ,task
  ,lineType
  ,invoice_number
  ,ROUND((direct_expenses + total_sla)*.07 + total_sla, 2) as total_recharge
from flowfile
```
#### 13.Create Debits and Credits
```sql

    select
    lineDescription
    ,pay_end_dt
    ,entity
    ,project
    ,account
    ,fin_dept
    ,fund
    ,task
    ,program
    ,purpose
    ,activity
    ,lineType
    ,invoice_number
    ,CAST(total_recharge AS DOUBLE) as debitAmount
    ,null as creditAmount
    from flowfile
    union all
    select
    lineDescription
    ,pay_end_dt
    ,'${offsetEntity}'
    ,'${offsetProject}'
    ,'${offsetAccount}'
    ,'${offsetDepartment}'
    ,'${offsetFund}'
    , null
    ,null
    ,null
    ,null
    ,lineType
    ,invoice_number
    ,null as debitAmount
    ,CAST(total_recharge AS DOUBLE) AS creditAmount
    from flowfile
    order by lineDescription
```
#### 14. Create GL/PPM Projects
```sql
       select
    lineDescription
    ,pay_end_dt
    ,entity
    ,case when lineType = 'glSegments'  then project  end as glProject
    ,case when lineType = 'ppmSegments' then project  end as ppmProject
    ,case when lineType = 'glSegments'  then fin_dept end as  department
    ,case when lineType = 'ppmSegments'  then fin_dept end as  organization
    ,case when lineType = 'glSegments'  then account  end as account
    ,case when lineType = 'ppmSegments' then account  end as expenditureType
    ,case when lineType = 'glSegments'  then fund     end as fund
    ,case when lineType = 'glSegments'  then program  end as program
    ,case when lineType = 'glSegments'  then purpose  end as purpose
    ,case when lineType = 'glSegments'  then activity end as activity
    ,case when lineType = 'ppmSegments' then task     end as task
    ,linetype
    ,invoice_number
    ,debitAmount
    ,creditAmount
    from flowfile

```
#### 15. Create Flattened Format
```sql

    SELECT
    ROW_NUMBER() over() AS journalLineNumber
    , *
    FROM (
    select
    '${consumer.id}' as consumerId
    ,'${consumer.id}' as boundaryApplicationName
    ,'${request.source.prefix}_${now():format('yyyyMMddHHmmss')}' as consumerReferenceId
    ,'${request.source.prefix}_${now():format('yyyyMMdd')}' as consumerTrackingId
    ,'${consumer.notes.prefix} ${now():format('yyyyMMdd')}' as consumerNotes
    ,'${request.source.type}' as requestSourceType
    ,'${source.id}' as requestSourceId
    ,'${consumer.id}' as journalSourceName
    ,'${journal.category.name}' as journalCategoryName
    ,'${consumer.notes.prefix} ${now():format('yyyyMMdd')}' as journalName
    ,'${journal.reference.prefix} ${now():format('yyyy-MM-dd')}' as journalReference
    ,lineDescription
    ,'${now():format('yyyy-MM-dd')}' as accountingDate
    ,'${now():format('yyyy-MM-dd')}' as transactionDate
    ,entity
    ,glProject
    ,account
    ,department
    ,fund
    ,program
    ,purpose
    ,activity
    ,ppmProject
    ,organization
    ,expenditureType
    ,task
    ,lineType
    ,invoice_number as externalSystemIdentifier
    ,debitAmount
    ,creditAmount
    from flowfile) as S

```
#### 16. Convert Avro to JSON


#### 17. Create GL and PPM totals and set as Attributes
#### 18. Set attributes to publish to GL/PPM flattened topic

| Attribute Name                | Attribute Value                |
| ----------------------------- | ------------------------------ |
| `accounting.date`             | $[0].accountingDate            |
| `accounting.period`           | $[0].accountingPeriod          |
| `boundary.system`             | $[0].boundaryApplicationName   |
| `consumer.ref.id`             | $[0].consumerReferenceId       |
| `consumer.tracking.id`        | $[0].consumerTrackingId        |
| `data.source`                 | $[0].consumerTrackingId        |
| `journal.category`            | $[0].journalCategoryName       |
| `journal.name`                | $[0].journalCategoryName       |
| `journal.source`              | $[0].journalSourceName         |
| `source.id`                   | $[0].requestSourceId           |

#### 19. Publish to Flattened Topic
#### 20. Get the last invoice number created in this flow
```sql
    select max(externalSystemIdentifier) as max_invoice_nbr
    from flowfile
```
#### 21. Set this last processed processed number as an attribute

#### 21. insert into tsa_recharge_job_status_table
```sql
    insert into  #{int_db_staging_schema}.tsa_recharge_job_status
    (batch_nbr, status, max_invoice_nbr)
    values
    (${next.batch.nbr}, 'COMPLETED', ${max.invoice.nbr})
```
