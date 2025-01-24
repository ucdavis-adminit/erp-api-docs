# 6.3.20 ERS

### Overview

* **Implementation Epic:** <https://afs-dev.ucdavis.edu/jira/browse/INT-1407>

ERS (Effort Reporting System) requires a set of reference data from the financial system to be loaded into the ERS database.  (ERS also receives transactional data from UCPath - but that is a file created by the UCPath system.)

The data needed will be provided in 4 files as follows:

* 6.3.20.1 Accounting Segment Combinations
* 6.3.20.2 Financial Department Hierarchy
* 6.3.20.3 Project Principal Investigators
* 6.3.20.4 Financial Department / HR Department Crosswalk

Implementation will be performed by sourcing data from the Postgres database and generating files in the required format and uploading those to S3 per standard mechanisms.  The files will be handled manually from there by the Operations team.

* **Spec Requirements Document:** [ERS Data Requirements](#/6%20Data%20Pipelines/6.3%20Custom%20Pipelines/6.3.20%20ERS/ERS_Interface_Spec_20240223.pdf ':ignore')
* **Original Specification Update:** [ERS Interface Spec](#/6%20Data%20Pipelines/6.3%20Custom%20Pipelines/6.3.20%20ERS/ERS%20Interface%20SpecificationVx%20-%20yy.%2020230818.docx ':ignore')

### Dependencies

* Connection to AIT_INT/ODS for Financial/HR Department Mapping Data
  * Alternate: if both data elements exist in the labor ledger history table
* Data Extract of the HR department data from UCPath loaded into Postgres
* Data Extract of Project Principal Investigators from Oracle loaded into Postgres

### Pipeline Implementation Summary

1. Cron-processor to kick off the process on the 5th through 15th of each month.
2. All files are generated as part of the same job.  (Split flow after request entry and ID created to handle each file.  No merge needed - see note at end of flow.)
3. Create `pipeline_request` record for the job run.
4. Create `pipeline_job_status` records for each file.  (must be done all at once)
   1. Use the filename prefixes (as shown below) as the `job_id` value.
5. Run the file creation process below in parallel.
   1. Run the SQL to extract the data.  Format the data as expected by ERS in the SQL.
   2. Reformat into the needed fixed-width format.
      1. See: <https://stackoverflow.com/questions/76063254/can-we-write-prepare-fixed-width-length-file-type-in-nifi>
      2. Also: <https://nifi.apache.org/docs/nifi-docs/components/org.apache.nifi/nifi-record-serialization-services-nar/1.23.2/org.apache.nifi.text.FreeFormTextRecordSetWriter/index.html>
   3. Name the file as required and upload to S3.  If existing file blocks upload, delete and re-upload.
   4. Mark `pipeline_job_status` as PROCESSED.  Include metrics about the created file in the job report.
   5. Mark `pipeline_job_status` as ERROR if the file was not generated and uploaded.
6. Because Job records were created, common processing will complete the overall pipeline request.

### File Location and Naming

> Files are only dated by month and year.  The files which run during a month will overwrite each other....maybe...that's up to S3.

* **File Names:**
  * `fau_interface_yyyymm.txt`
  * `dept_hierarchy_yyyymm.txt`
  * `project_pi_yyyymm.txt`
  * `fin_hr_dept_map_yyyymm.txt`
* **S3 Path:** `<env>/out/ers/`

### Job Report Contents

Format a mini text report to include in the `job_report` column of `pipeline_job_status` records.  Include the following:

* Job ID
* Timestamp
* Output File Name and Path (in S3 bucket)
* Number of Records Included In the File


## 6.3.20.1 Expense Segment Combinations

This file is a list of all accounting segments which could have originated from UCPath.  We will define that by using the list of expense accounts used by UCPath in the last year.

### File Format

This file is a fixed-width formatted file with the following layout:

| Field                       | Field Len | Pad       | Description                                           | Example                      |
| --------------------------- | --------: | --------- | ----------------------------------------------------- | ---------------------------- |
| FAU                         |        30 | Right     | ERS-specific combination of segment values            | 3110ADIT001FP12345678K123456 |
| Project Number              |        30 | Right     | Project number                                        | FP12345678                   |
| Sponsored Flag              |         1 |           | Y/N flag indicating sponsored project type            | Y                            |
| Federal Fund Flag           |         1 |           | Y/N flag indicating whether a federal fund award type | Y                            |
| Certification Required Flag |         1 |           | Y/N flag indicating whether certification is required | Y                            |
| Effective Date              |        10 |           | Today's date formatted mm/dd/yyyy                     | 03/19/2024                   |
| Project Department Code     |        10 | Right     | Project Owning Department Code                        | ADIT001                      |
| Award Project Code          |        10 | Right     | Award Owning Department Code                          | ADIT000                      |
| Principal Investigator      |         9 | Left-zero | Employee ID if primary PI                             | 10220803                     |
| Award Sponsor Code          |        10 | Right     |                                                       |                              |
| Award Sponsor Name          |        90 |           |                                                       |                              |
| Award Number                |        30 | Right     | Award Number                                          | K123456                      |
| Project Name                |       135 | Right     |                                                       |                              |
| Alternate Project ID        |        50 | Right     | Concatanated project-award                            | FP12345678-K123456           |
| Alternate Project Name      |       200 | Right     | Project Name (again)                                  |                              |
| Fund Name                   |        50 | Right     | Award Name                                            |                              |
| FAU Reused Flag             |         1 |           | (unused)                                              |                              |
| Co-PI Employee ID           |         9 |           | (unused)                                              |                              | ) |

#### FAU Format

The FAU is a concatenation (without delimiter) of the following fields:

* Entity
* Department
* Project Number
* Award Number

### Mapping

| Field                       | Mapping                                                                            |
| --------------------------- | ---------------------------------------------------------------------------------- |
| FAU                         | `gl_code_combination`: `segment1`+`segment3`+`segment7`+`ppm_award_v.award_number` |
| Project Number              | `gl_code_combination.segment7`                                                     |
| Sponsored Flag              | `ppm_project.sponsored_project_flag`                                               |
| Federal Fund Flag           | `ppm_award_v.award_type` (derived:Y if award type is 1, 2, 3, 21-34)               |
| Certification Required Flag | `ppm_award_v.award_type` (derived: Y if award type is 1, 2, 3, 21-34)              |
| Effective Date              | (today)                                                                            |
| Project Department Code     | `ppm_project.project_owning_org` (left 7)                                          |
| Award Project Code          | `ppm_award_v.award_owning_org_name` (left 7)                                       |
| Principal Investigator      | `per_all_people_f.person_number` via `ppm_project_personnel.person_id`             |
| Award Sponsor Code          | `ppm_sponsor_reference.reference_value`  (see below for joining)                   |
| Award Sponsor Name          | `ppm_sponsor.sponsor_name`    (see below for joining)                              |
| Award Number                | `ppm_award.award_number`                                                           |
| Project Name                | `ppm_project.name`                                                                 |
| Alternate Project ID        | `gl_code_combination.segment7`-`ppm_award_v.award_number`                          |
| Alternate Project Name      | `ppm_project.name`                                                                 |
| Fund Name                   | `ppm_award_v.name`                                                                 |
| FAU Reused Flag             | (blank)                                                                            |
| Co-PI Employee ID           | (blank)                                                                            |

* **NOTE:** This will take a join from ppm_project to ppm_project_award.  This is not a 1:1 join.  As such, we could end up with multiple records per project code.  THIS IS OK.  There is no harm in including extra records.

#### Join Information

* GL Segments -> PPM Project
  * `gl_code_combination.segment7` -> `ppm_project.project_number`
* PPM Project -> Award View
  * `ppm_project.project_id` -> `ppm_award_v.project_id`
* Award View -> Award
  * `ppm_award_v.id` -> `ppm_award.id`
* Award View -> Sponsor
  * `ppm_award_v.party_id` -> `ppm_sponsor.party_id`
* Sponsor -> Sponsor Code
  * `ppm_sponsor_reference.sponsor_id` -> `ppm_sponsor.sponsor_id`
  * `ppm_sponsor_reference.reference_type_name` = 'UCOP Sponsor Code'
* Award View -> Award Team Member
  * `ppm_award_v.id` -> `ppm_award_team_member.award_id`
  * `ppm_award_team_member.role_name` = 'Principal Investigator' (**TBD - don't know PI role name**)
* Award Team Member -> Person
  * `ppm_award_team_member.person_id` -> `per_all_people_f.person_id`

### Source Tables

* `gl_code_combination`
* `ppm_project`
* `ppm_award_v`  / `ppm_award`
* `per_all_people_f`
* `ppm_sponsor`
* `ppm_sponsor_reference`
* `ppm_award_team_member` (new - does not exist)
<!-- * `ppm_project_personnel` (new - does not exist) -->

### Notes

This gets all expense accounts used when posting from UCPath in the last year.  This can be used to filter the combo codes which should be included in the file.

```sql
SELECT distinct
  cc.SEGMENT4 AS account
FROM gl_je_lines line
JOIN gl_je_headers hdr ON hdr.je_header_id = line.je_header_id
JOIN gl_code_combination cc ON cc.code_combination_id = line.code_combination_id
JOIN gl_journal_source s ON s.name = hdr.je_source
JOIN erp_account a ON a.code = cc.segment4
WHERE s.key = 'UCD UCPath'
  AND a.parent_level_0_code = '5XXXXX'
  AND posted_date > NOW() - INTERVAL '1 year'
ORDER BY 1
```


## 6.3.20.2 Department Hierarchy File

This file just lists all financial departments in Oracle and their parents.  If the `erp_fin_dept` view is not used, then care needs to be taken to ensure that the data is consistent with the view.  This file is a flat-format file.

### File Format

| Field             | Field Len | Pad   | Description            | Example           |
| ----------------- | --------: | ----- | ---------------------- | ----------------- |
| Department Code   |        10 | Right | Department Code        | ADIT001           |
| Parent Department |        10 | Right | Parent Department Code | ADIT00F           |
| Department Name   |        30 | Right | Department Name        | Administrative IT |

### Mapping

| Field             | Mapping                                      |
| ----------------- | -------------------------------------------- |
| Department Code   | `erp_fin_dept.code`                          |
| Parent Department | `erp_fin_dept.parent_level_X_code` (dynamic) |
| Department Name   | `erp_fin_dept.description`                   |

* The column to use depends on the hierarchy.  The parent is in `erp_fin_dept.parent_level_X_code` where X is the `hierarchy_depth` minus 1.

### Filtering

* enabled_flag = 'Y'


## 6.3.20.3 Project Principal Investigator File

This file is a list of project principal investigators.  It is a flat file with a fixed-width format.  Only projects with principal investigators on their award are included.

### File Format

| Field          | Field Len | Pad       | Description | Example    |
| -------------- | --------: | --------- | ----------- | ---------- |
| PI Employee ID |         9 | Left-zero |             | 010220803  |
| Project Number |        30 | Right     |             | FP12345678 |
| Action Code    |         1 |           | (blank)     |            |

### Mapping

| Field          | Mapping                          |
| -------------- | -------------------------------- |
| PI Employee ID | `per_all_people_f.person_number` |
| Project Number | `ppm_project.project_number`     |
| Action Code    | (blank)                          |

#### Join Information

* PPM Project -> Award View
  * `ppm_project.project_id` -> `ppm_award_v.project_id`
* Award View -> Award Team Member
  * `ppm_award_v.id` -> `ppm_award_team_member.award_id`
  * `ppm_award_team_member.role_name` = 'Principal Investigator' (**TBD - don't know PI role name**)
* Award Team Member -> Person
  * `ppm_award_team_member.person_id` -> `per_all_people_f.person_id`

### Source Tables

* `gl_code_combination`
* `ppm_project`
* `ppm_award_v`  / `ppm_award`
* `per_all_people_f`
* `ppm_sponsor`
* `ppm_sponsor_reference`
* `ppm_award_team_member` (new - does not exist)

### Filtering

* `ppm_project.status_code` != 'CLOSED'
* `ppm_project.status_code` != 'REJECTED'
* Exclude records where no PI is found.


## 6.3.20.4 Financial to HR Department Mapping File

> TBD if we will provide this automatically.  The below is a query against AIT_INT which can extract this data from some selected run IDs.  There are significant performance and load issues with the below.  We are waiting for functional feedback on the need for this file.

Here we obtain all the used mappings between a job's HR department and the funding source's financial department.  We take advantage that BOTH sets are in the UCPath department table.  (They exist in the same table, but with different SETIDs.)

### File Format

| Field                | Field Len | Pad   | Description | Example |
| -------------------- | --------: | ----- | ----------- | ------- |
| Financial Department |        10 | Right |             | ADIT001 |
| HR Department        |        10 | Right |             | 062005  |

### Mapping

| Field                | Mapping                      |
| -------------------- | ---------------------------- |
| Financial Department | `ps_uc_ll_sal_dtl.deptid_cf` |
| HR Department        | `ps_job.deptid`              |

### Notes

> This is a sample only showing the data.  We likely only need the inner-most query to generate this file.
> **TBD: How we limit the inner query - the list of RUNIDs was only valid when this was tested.  Will need more input to determine what subset of labor ledger records to use.**

```sql
WITH depts AS (
    SELECT DEPTID, MAX(DESCR) AS name
    from ucpath.PS_DEPT_TBL
    where ( setid, deptid, effdt ) IN (
        SELECT setid, deptid, MAX(effdt)
        FROM ucpath.PS_DEPT_TBL
        WHERE DML_IND != 'D'
          AND LENGTH(DEPTID) <= 7
          AND SETID IN ( 'DVCMP', 'UCANR', 'DVFIN','ANRFN')
        GROUP BY setid, deptid
    )
    AND DML_IND != 'D'
    GROUP BY DEPTID
)
SELECT
  main.HR_DEPT_CODE
, hrd.name AS HR_DEPT_NAME
, main.fin_dept_code
, fd.name AS fin_dept_name
FROM (
    SELECT DISTINCT
      j.DEPTID AS HR_DEPT_CODE
    , s.DEPTID_CF AS fin_dept_code
    FROM ucpath.ps_uc_ll_sal_dtl s
    JOIN ucpath.ps_job j ON j.emplid = s.emplid AND j.empl_rcd = s.EMPL_RCD AND j.effdt = s.EFFDT AND j.effseq = s.effseq
    WHERE s.run_id IN (
  '240203B1X'
, '240217B2X'
, '240229M0X'
    )
      AND LENGTH(s.OPERATING_UNIT) = 4
) main
JOIN depts hrd ON hrd.DEPTID = main.HR_DEPT_CODE
JOIN depts fd  ON fd.DEPTID = main.fin_dept_code
ORDER BY hr_dept_code, fin_dept_code
```

> Possible query to get all the RUN_ID values used in the last year.  NOTE: Our NiFi account does not have access to the used table.

```sql
select DISTINCT RUN_ID
from ucpath.PS_PAY_CALENDAR
where company = 'UCS'
AND run_id != ' '
AND PAY_CONFIRM_RUN = 'Y'
AND pay_end_dt > SYSDATE - INTERVAL '1' YEAR
ORDER BY RUN_ID DESC
```
