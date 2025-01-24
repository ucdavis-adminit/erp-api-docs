# 6.3.7.4 Employee Export to Oracle

### Overview

Oracle financials requires an up-to-date extract of persons who can be referenced by the system.  Per previous implementations, this is the population of UCD employees and related personnel.  All of these persons are tracked in UCPath in some way.  As such, our person/employee extract is sourced primarily from UCPath.  Some additional data is loaded from IAM, mainly to obtain the UCD campus computing account information.

On a daily basis, this extract will pull all changes to job records from UCPath and translate them into updates needed for Oracle.

This import functions by loading the data into the HCM/HR module of Oracle.  As it is being loaded into essentially another HR system, it must be loaded in a way which represents the nature of the change of each person's changes.  That is, it needs to know whether it is a Hire, Termination, Rehire, or just some other data change.

Overall, the data needed by Oracle is fairly simple, but Oracle requires that data be loaded into several different tables for each employee update.  This is facilitated by the HCM Data Loader feature.  It allows all the data for a employees to be loaded in a single file using multiple record types within the same file.  The HCM Data Loader will then process the file and load the data into the appropriate tables.

### Data Mapping

The source for this process will be a query against the AIT_INT database where both the UCPath and IAM data is stored.  It will pull records which have been modified since the last time the extract was run.  The data will be loaded into a staging table in Postgres.  The staging table will be used to determine what action is needed for each employee.  The action will be one of the following:

* **Hire:** The employee is new to the system and needs to be added to Oracle.
* **Rehire:** The employee is present but inactive in oracle and needs to be reactivated.
* **Terminate:** The employee is no longer employed by UCD and needs to be removed from Oracle.
* **Update:** The employee's data has changed and needs to be updated in Oracle.

### Process Overview

1. Daily, after the AIT_INT data is loaded, the extract query will be executed.
2. Each record will have its EMPL_STATUS status checked against the staging table based on the employee ID.  This is used to derive the action code needed on the record.
3. A file will be started with the METADATA lines for each record type we will be including.
4. For each record, MERGE lines for each record type will be added to the file, built from the data sourced from AIT_INT and the derived value above.
5. The completed file will be submitted to the HCM Data Loader for processing.
6. Standard processes will monitor for completion and review the results for errors.
7. Upon completion, an appropriate notification will be logged.


## Employee Export Flow Design

* **Pipeline ID:** `emp_import`

### High Level

1. Extract data for recently updated employees from UCPath.
2. Lookup each employee in the staging table to determine the action needed.
3. Update the records with the action value.
4. Filter out records we should not send to Oracle.  (See calculated field logic below.)
5. Split the flow into a flow for each HDL record type plus one placeholder to generate the metadata records and another to use to update the staging table after successful file creation.
6. In each sub-flow, convert the records per the target record type.
7. In one placeholder flow, replace the flowfile contents with the METADATA records that define the output.
8. In the other, route the flowfile to a Wait processor to allow the file to be created before updating the staging table.
9. Merge the content back together into a single flowfile.
10. Upload the completed file to Oracle.
11. Upon confirmation of successful upload, send a signal to the earlier Wait processor via a Notify processor.
12. Use the original flowfile to update the staging table.


### Flow Design

1. Trigger process with a CRON GenerateFlowFile processor.  Execute at 7 am every day.
2. Assign attributes to the flowfile to identify the job.
   1. job.id = UUID
   2. job.run.date = ISO formatted current date
3. Calculate and format a date to use in the extract query - store as attribute for use in the SQL.
4. Insert appropriate record into pipeline_request
5. Execute the data extract query with ExecuteSQL.  (This will generate an Avro-formatted file.)
6. Run an update record to add support fields to the record:
   1. `last_submitted_status` field to each record with a blank value.
   2. `derived_action` field to each record with `DONOTSEND`.
7. Run the records through the LookupRecord processor to obtain the last seen status.
   1. Put the resulting information into the `last_submitted_status` attribute.
8. Derive the action for each record based on the difference between the current empl_status and previous empl_status.
9. Use QueryRecord to remove records with an action of `DONOTSEND` from the file.
10. Route the records to sub-flows for each of the record types and a supporting flow the staging table updates.  (We need this to retain the values in the source data we don't place in the output records.)
11. In the supporting flow noted above, route to a Wait processor.
    1. Release Signal Identifier: `emp_import_${job.id}`
    2. Wait Penalty Duration: `5 seconds`
12. Use UpdateAttribute to attach the needed attributes to each of these flows so they can be re-merged later.
13. Attach the appropriate `avro.schema` to each flowfile.
14. Run each flow through a QueryRecord to reformat the file into the proper field names and data formats for the HDL record type.
    1. Use the AVRO reader, but use a Pipe-delimited writer which uses the attached avro.schema.
    2. Constant values should NOT be in the SQL, they will be added by the writer per defaults defined in the avro.schema.
15. Merge all the records back together using MergeContent.
    1. Merge Strategy: `Defragment`
    2. Merge Format: `Binary Concatenation`
    3. Delimiter Strategy: `Text`
    4. Header: (The set of METADATA lines defined in the data mapping.)
    5. Footer: (none)
    6. Demarcator: (newline)
16. Insert a record for the job into `pipeline_job_status` (see below)
17. Route the result to a sub-flow to send the file to Oracle.
18. If successful send, route the flow to a Notify processor to send the signal to release the earlier waiting flowfile.
19. From the Wait processor, route the flowfile to perform the staging table updates.
    1. Use QueryRecord to format the rows as needed to update the staging table.  (See Staging Table Updates below for details.)
    2. Run through PutDatabaseRecord with an UPDATE operation to perform the updates.

<!-- 12. The one flow for the header records will be a ReplaceText and use the set of header lines defined in the data mapping. -->

#### Lookup Service

* **Name:** `LookupService - Employee Status`
* **Type:** `SimpleDatabaseLookupService`
* **Key:** `emplid`
* **Returns Field:** `emplstatus`


#### pipeline_request Values

| Column              | Value                  |
| ------------------- | ---------------------- |
| source_request_type | sftp                   |
| source_request_id   | emp_import_${job.id}   |
| consumer_id         | UCD AdminIT Operations |

#### pipeline_job_status Values

| Column              | Value                |
| ------------------- | -------------------- |
| source_request_type | sftp                 |
| source_request_id   | emp_import_${job.id} |
| job_id              | hcmDataLoader        |
| assigned_job_id     | emp_import_${job.id} |

### Checkpoints

| Checkpoint ID     | Description                                                    |
| ----------------- | -------------------------------------------------------------- |
| query_executed    |                                                                |
| lookups_completed |                                                                |
| statuses_derived  | After all statuses derived and DONOTSEND records filtered out. |
| data_formatted    | After all data formatted and re-merged into a single flowfile. |
| hdl_uploaded      |                                                                |
| staging_updated   |                                                                |


### Calculated Field Logic

All the calculated fields in this flow are based on the changes in the EMPL_STATUS since the last extract of an employee's data.

* Active Statuses: `A`, `L`, `P`, `W`
* Inactive Statuses: `T`, `U`, `R`, `D`

#### If No Prior Record in Staging Table

When there is no record in the staging table for the given employee, it will generally be a hire action.  (Unless the first status we get is an inactive status in which case we do not send the record.  These records ALSO do not get recorded to the staging table, as we would need the first action taken if they do become active to be a HIRE, not a REHIRE.)

| New EMPL_STATUS | New PER_ORG | Action Type | ActionCode | ReasonCode | RevokeUserAccess |
| --------------- | ----------- | ----------- | ---------- | ---------- | ---------------- |
| (Active)        | EMP         | Hire        | HIRE       | NEWHIRE    | (blank)          |
| (Active)        | CWR         | Hire        | ADD_CWK    | PLACE      | (blank)          |
| (Inactive)      | (any)       | N/A         | DONOTSEND  |            |                  |

#### If Record Exists in Staging Table

In this case, we need to compare the EMPL_STATUS and PER_ORG values to the staging table.  The codes used when the EMPL_STATUS changes depend on the PER_ORG values.  (For Rehires, we need to use the new PER_OR from UCPath.  For Terminations, we need to use the value we had stored in the staging table.)

If both statuses are active, then we are just sending a data

| Prior EMPL_STATUS | New EMPL_STATUS | Prior PER_ORG | New PER_ORG | Action Type | ActionCode          | ReasonCode   | RevokeUserAccess |
| ----------------- | --------------- | ------------- | ----------- | ----------- | ------------------- | ------------ | ---------------- |
| (Inactive)        | (Active)        | (any)         | EMP         | Rehire      | REHIRE              | REHIRE_WKR   | (blank)          |
| (Inactive)        | (Active)        | (any)         | CWR         | Rehire      | REN_CWK             | RENEW_CWK    | (blank)          |
| (Active)          | (Inactive)      | EMP           | (any)       | Termination | TERMINATION         | WORK_RELATED | Y                |
| (Active)          | (Inactive)      | CWR           | (any)       | Termination | TERMINATE_PLACEMENT | (blank)      | Y                |
| (Active)          | (Active)        | (any)         | (same)      | Data Change | ASG_CHANGE          | (blank)      | (blank)          |
| (Inactive)        | (Inactive)      | (any)         | (any)       | N/A         | DONOTSEND           |              |                  |

* **Potential TODO:** _If the EMPLID, EMPL_RCD, EFFDT, and EFFSEQ are all the same as the staging table, set the action to DONOTSEND, as we have already sent this information to Oracle and we know there have been no job changes.  May also need to check the last update dates of the name and email, since those could be updated without changing the job._

#### Special Case for Active->Active PER_ORG Changes

> Changing types is not supported by Oracle.  We must terminate the old record and hire or place the new record.  This means that two records will be created in the output files for the employee.

* Record 1: Action Code = TERMINATION, Reason Code = WORK_RELATED
* Record 2: Follow Rules for Incoming Record PER_ORG = Prior PER_ORG (REHIRE / REN_CWK)

#### EMPL_STATUS Code Meanings

| EMPL_STATUS | Name                    |
| :---------: | ----------------------- |
|             | **Active Statuses**     |
|      A      | Active                  |
|      L      | Unpaid Leave of Absence |
|      P      | Paid Leave of Absence   |
|      W      | Short Work Break        |
|             | **Inactive Statuses**   |
|      T      | Terminated              |
|      U      | Terminated With Pay     |
|      R      | Retired                 |
|      D      | Deceased                |


### Staging Table Updates

When updating the staging table, the following fields should be updated:

| Data Extract Field       | Staging Table Field | Notes                                                      |
| ------------------------ | ------------------- | ---------------------------------------------------------- |
| emplid                   | emplid              | (update key)                                               |
| empl_rcd                 | empl_rcd            |                                                            |
| empl_status              | empl_status         |                                                            |
| per_org                  | per_org             |                                                            |
| effdt                    | effdt               |                                                            |
| effseq                   | effseq              |                                                            |
| batch_update_date_time   | last_updt_dt        |                                                            |
| last_calculated_action   | (derived action)    | For PER_ORG changes, this should be the rehire action code |
| last_submitted_date_time | (job run date)      | (current date/time - all should have the same exact time)  |
| last_submitted_job_id    | (job id)            | UUID generated at start of job run                         |

* On the last_calculated_action above, the order of records _should_ make the rehire be the 2nd update run and work automatically.  Just ensure that when the record is being duplicated in the transform processors, that the rehire record is the 2nd record in the output.

### Notes

* Need to attach fragment attributes and use the defragment method to re-merge all the files.
* An Avro Schema will be needed for each record type to ensure fields are written in the correct order.
* Writers used will be pipe-delimited and must not have a header row.
* The Merge content should include an extra linefeed between each merged file.
* Data extract will just look back X days for changes.  This will be a parameter.
* Ensure the record lookup processor caches the results for at least an hour.
  * (This may be a performance issue for this flow...)
* The record updates need to set the reason and action status type, and revoke user access codes.
  * This should be done with either a QueryRecord or UpdateRecord processor based on the results from the lookup.
  * The lookup does not need to set the value, but can just add/update a field on all records that can be mapped to the proper value during the later reformatting.
* The metadata records must be the first lines in the file
* Each other record/line will start with `MERGE|` and then the record type.
* Use the schemas to include the hard-coded/Constant information for each record type.
  * An example schema for the Worker record has been created in the Schemas and Formats sub-directory.

### Metadata Headers

> Below are the header lines to include in the file which define the types of records which _may_be included and the order of the fields within each record type.

[](./metadata_headers.txt ':include')

### Staging Table (Postgres)

> The purpose of this table is to track prior statuses.  It is not used to store the person data which is or was sent to oracle.  It is here to faciliate the logic of determining what action is needed for each employee.

* **Table Name:** `xxx_staging.ucpath_employee_status`

| Field Name               | Data Type   | Description                                                         |
| ------------------------ | ----------- | ------------------------------------------------------------------- |
| emplid                   | varchar(11) | Employee ID                                                         |
| emplid                   | varchar(11) | Employee ID                                                         |
| empl_rcd                 | int         | Last seen Employee record number marked as a primary job            |
| empl_status              | char(1)     | Last seen employee status                                           |
| per_org                  | char(3)     | Last seen per_org on the primary job in UCPath                      |
| effdt                    | date        | reference only : last seen effective date                           |
| effseq                   | int         | reference only : last seen effective sequence                       |
| batch_update_date_time   | timestamp   | last update date from source data                                   |
| last_calculated_action   | varchar(20) | last action code sent to Oracle                                     |
| last_submitted_date_time | timestamp   | last date/time the employee's data was included in a file to Oracle |
| last_submitted_job_id    | varchar(80) | last job id used to submit the employee's data to Oracle            |

### Where to find record errors

1. One can check message icon in import and export window
2. Query following tables:
   1. hrc_dl_message_lines
   2. hrc_dl_physical_lines
   3. hrc_dl_data_sets
   4. hrc_dl_file_rows
   5. hrc_dl_file_lines


## AIT_INT Database to Oracle HDL Mappings

### Worker Record

* **Record Type:** `Worker`
* **Main Table:** `PS_JOB`
* **Metadata Line:** `METADATA|Worker|SourceSystemOwner|SourceSystemId|EffectiveStartDate|EffectiveEndDate|PersonNumber|StartDate|ActionCode`

| HDL Record Field Name | Value                                                                                                 |
| --------------------- | ----------------------------------------------------------------------------------------------------- |
| SourceSystemOwner     | Constant: `UCPATH`                                                                                    |
| SourceSystemId        | PS_JOB.EMPLID                                                                                         |
| EffectiveStartDate    | CASE WHEN PS_JOB.ASGN_START_DT < date'1957-01-01' THEN date'1957-01-01' ELSE PS_JOB.ASGN_START_DT END |
| EffectiveEndDate      | COALESCE(PS_JOB.ASGN_END_DT, date'4712-12-31')                                                        |
| PersonNumber          | PS_JOB.EMPLID                                                                                         |
| StartDate             | PS_JOB.HIRE_DT                                                                                        |
| ActionCode            | **(derived action - TBD)**                                                                            |

* **Where**
  * POI_TYPE = ' ' -- Exclude Persons of Interest
  * DML_IND != 'D' -- Exclude Deleted Records
  * JOB_INDICATOR = 'P' -- Primary Job Only
  * Current Record Only (By EFFDT/EFFSEQ)

### Person Name Record

* **Record Type:** `PersonName`
* **Main Table:** `PS_NAMES`
* **Join:** `PS_NAMES.EMPLID = PS_JOB.EMPLID`
  * To Current Record sub-view of `PS_NAMES`
* **Metadata Line:** `METADATA|PersonName|SourceSystemOwner|SourceSystemId|PersonId(SourceSystemId)|EffectiveStartDate|EffectiveEndDate|NameType|LegislationCode|LastName|FirstName|MiddleNames|Suffix|KnownAs`

| HDL Record Field Name    | Value                                                                                                 |
| ------------------------ | ----------------------------------------------------------------------------------------------------- |
| SourceSystemOwner        | Constant: `UCPATH`                                                                                    |
| SourceSystemId           | PS_JOB.EMPLID\|\|'_GLOBAL'                                                                            |
| PersonId(SourceSystemId) | PS_JOB.EMPLID                                                                                         |
| EffectiveStartDate       | CASE WHEN PS_JOB.ASGN_START_DT < date'1957-01-01' THEN date'1957-01-01' ELSE PS_JOB.ASGN_START_DT END |
| EffectiveEndDate         | COALESCE(PS_JOB.ASGN_END_DT, date'4712-12-31')                                                        |
| NameType                 | Constant: `GLOBAL`                                                                                    |
| LegislationCode          | Constant: `US`                                                                                        |
| LastName                 | SUBSTR(COALESCE(TRIM(PS_NAMES.PARTNER_LAST_NAME), TRIM(PS_NAMES.LAST_NAME), 'UNKNOWN'), 1, 50)        |
| FirstName                | SUBSTR(COALESCE(TRIM(PS_NAMES.PREF_FIRST_NAME),TRIM(PS_NAMES.FIRST_NAME), 'UNKNOWN'), 1, 50)          |
| MiddleNames              | SUBSTR(TRIM(PS_NAMES.SECOND_LAST_NAME), 1, 50)                                                        |
| Suffix                   | (empty string)                                                                                        |
| KnownAs                  | SUBSTR(COALESCE(TRIM(PS_NAMES.PREF_FIRST_NAME),TRIM(PS_NAMES.FIRST_NAME), 'UNKNOWN'), 1, 50)          |

* **Where**
  * NAME_TYPE = 'PRI' -- Primary Name
  * EFF_STATUS = 'A' -- Exclude Inactive Records
  * DML_IND != 'D' -- Exclude Deleted Records
  * Current Record Only (By EFFDT)

### Person Email Record

* **Record Type:** `PersonEmail`
* **Main Table:** `PS_EMAIL_ADDRESSES`
* **Join:**       `PS_EMAIL_ADDRESSES.EMPLID = PS_JOB.EMPLID`
* **Metadata Line:** `METADATA|PersonEmail|SourceSystemOwner|SourceSystemId|PersonId(SourceSystemId)|DateFrom|DateTo|EmailType|EmailAddress|PrimaryFlag`

| HDL Record Field Name    | Value                                          |
| ------------------------ | ---------------------------------------------- |
| SourceSystemOwner        | Constant: `UCPATH`                             |
| SourceSystemId           | PS_JOB.EMPLID\|\|'_PRSN_EMAIL'                 |
| PersonId(SourceSystemId) | PS_JOB.EMPLID                                  |
| DateFrom                 | PS_JOB.HIRE_DT                                 |
| DateTo                   | COALESCE(PS_JOB.ASGN_END_DT, date'4712-12-31') |
| EmailType                | Constant: `W1`                                 |
| EmailAddress             | TRIM(PS_EMAIL_ADDRESSES.EMAIL_ADDR)            |
| PrimaryFlag              | Constant: `Y`                                  |

* **Where**
  * E_ADDR_TYPE = 'BUSN' -- Business Email Address
  * DML_IND != 'D' -- Exclude Deleted Records

### Person Phone Record

* **Record Type:** `PersonPhone`
* **Main Table:** `PS_JOB`
* **Metadata Line:** `METADATA|PersonPhone|SourceSystemOwner|SourceSystemId|PersonId(SourceSystemId)|PhoneType|PhoneNumber|DateFrom|DateTo`

| HDL Record Field Name    | Value                                          |
| ------------------------ | ---------------------------------------------- |
| SourceSystemOwner        | Constant: `UCPATH`                             |
| SourceSystemId           | PS_JOB.EMPLID\|\|'_PHONE'                      |
| PersonId(SourceSystemId) | PS_JOB.EMPLID                                  |
| PhoneType                | Constant: `W1`                                 |
| PhoneNumber              | Constant: `1-530-752-1011`                     |
| DateFrom                 | PS_JOB.HIRE_DT                                 |
| DateTo                   | COALESCE(PS_JOB.ASGN_END_DT, date'4712-12-31') |

* **Where**
  * PHONE_TYPE = 'BUSN' -- Business Phone
  * DML_IND != 'D' -- Exclude Deleted Records -->

### Person Address Record

* **Record Type:** `PersonAddress`
* **Main Table:** `PS_JOB`
* **Metadata Line:** `METADATA|PersonAddress|SourceSystemOwner|SourceSystemId|PersonId(SourceSystemId)|AddressType|AddressLine1|TownOrCity|Region2|PostalCode|Country|EffectiveStartDate|EffectiveEndDate`

| HDL Record Field Name    | Value                                          |
| ------------------------ | ---------------------------------------------- |
| SourceSystemOwner        | Constant: `UCPATH`                             |
| SourceSystemId           | PS_JOB.EMPLID\|\|'_ADDRESS'                    |
| PersonId(SourceSystemId) | PS_JOB.EMPLID                                  |
| AddressType              | Constant: `MAIL`                               |
| AddressLine1             | Constant: `One Shields Avenue`                 |
| TownOrCity               | Constant: `Davis`                              |
| Region2                  | Constant: `CA`                                 |
| PostalCode               | Constant: `95616`                              |
| Country                  | Constant: `US`                                 |
| EffectiveStartDate       | PS_JOB.HIRE_DT                                 |
| EffectiveEndDate         | COALESCE(PS_JOB.ASGN_END_DT, date'4712-12-31') |

### Person User Information Record

* **Record Type:** `PersonUserInformation`
* **Main Table:** `IAM_PERSON`
* **Join:** `IAM_PERSON.EMPLOYEEID = PS_JOB.EMPLID`
* **Metadata Line:** `METADATA|PersonUserInformation|SourceSystemOwner|SourceSystemId|PersonId(SourceSystemId)|PersonNumber|StartDate|UserName`

| HDL Record Field Name    | Value                     |
| ------------------------ | ------------------------- |
| SourceSystemOwner        | Constant: `UCPATH`        |
| SourceSystemId           | PS_JOB.EMPLID\|\|'_USINF' |
| PersonId(SourceSystemId) | PS_JOB.EMPLID             |
| PersonNumber             | PS_JOB.EMPLID             |
| StartDate                | PS_JOB.HIRE_DT            |
| UserName                 | IAM_PERSON.USERID         |

**NOTES/OPEN QUESTIONS:**

PersonUserInformation can only be created when HIRE
When trying to change record, got following error: `After a worker is created, you can't update or delete the user information or roles through the Worker Service. Make updates through the User Service.`

### Work Relationship Record

* **Record Type:** `WorkRelationship`
* **Main Table:** `PS_JOB`
* **Metadata Line:** `METADATA|WorkRelationship|SourceSystemOwner|SourceSystemId|PersonId(SourceSystemId)|WorkerType|PrimaryFlag|DateStart|NewStartDate|ActualTerminationDate|RevokeUserAccess|ReasonCode|LegalEmployerName`

| HDL Record Field Name    | Value                                                  |
| ------------------------ | ------------------------------------------------------ |
| SourceSystemOwner        | Constant: `UCPATH`                                     |
| SourceSystemId           | PS_JOB.EMPLID\|\|'_POS'                                |
| PersonId(SourceSystemId) | PS_JOB.EMPLID                                          |
| WorkerType               | CASE WHEN PS_JOB.PER_ORG = 'CWR' THEN 'C' ELSE 'E' END |
| PrimaryFlag              | Constant: `Y`                                          |
| DateStart                | PS_JOB.HIRE_DT                                         |
| NewStartDate             | PS_JOB.LAST_HIRE_DT                                    |
| ActualTerminationDate    | PS_JOB.TERMINATION_DT                                  |
| RevokeUserAccess         | CASE WHEN derived_action = 'TER' THEN 'Y' ELSE '' END  |
| ReasonCode               | **(derived action - TBD)**                             |
| LegalEmployerName        | (See Below)                                            |

**OPEN QUESTIONS:**

1. What is the value for `ReasonCode`?
2. When should `RevokeUserAccess` be set, and to what value?

#### Legal Employer Name

```sql
CASE WHEN PS_JOB.BUSINESS_UNIT        = 'DVMED' THEN 'UC Davis Medical Center'
     WHEN PS_JOB.BUSINESS_UNIT        = 'UCANR' THEN 'Agricultural and Natural Resources'
     WHEN SUBSTR(PS_JOB.DEPTID, 1, 3) = '049'   THEN 'UC Davis Schools of Health'
                                                ELSE 'UC Davis - Excluding Schools of Health'
END
```

#### Reason Code

```sql
CASE
  WHEN PS_JOB.PER_ORG = 'EMP' THEN 'HIRE'
  WHEN PS_JOB.PER_ORG = 'CWR' THEN 'PLACE'
  ELSE ''
END
```

### Work Terms Record

* **Record Type:** `WorkTerms`
* **Main Table:** `PS_JOB`
* **Metadata Line:** `METADATA|WorkTerms|SourceSystemOwner|SourceSystemId|PersonId(SourceSystemId)|ActionCode|ReasonCode|EffectiveStartDate|EffectiveEndDate|PrimaryWorkTermsFlag|PositionOverrideFlag|EffectiveSequence|EffectiveLatestChange|AssignmentStatusTypeCode|AssignmentType|BusinessUnitShortCode|LegalEmployerName|PeriodOfServiceId(SourceSystemId)`

| HDL Record Field Name             | Value                                                                                                 |
| --------------------------------- | ----------------------------------------------------------------------------------------------------- |
| SourceSystemOwner                 | Constant: `UCPATH`                                                                                    |
| SourceSystemId                    | PS_JOB.EMPLID\|\|'_EMP_TERM'                                                                          |
| PersonId(SourceSystemId)          | PS_JOB.EMPLID                                                                                         |
| ActionCode                        | **(derived action - TBD)**                                                                            |
| ReasonCode                        | **(derived action - TBD)**                                                                            |
| EffectiveStartDate                | CASE WHEN PS_JOB.ASGN_START_DT < date'1957-01-01' THEN date'1957-01-01' ELSE PS_JOB.ASGN_START_DT END |
| EffectiveEndDate                  | COALESCE(PS_JOB.ASGN_END_DT, date'4712-12-31')                                                        |
| PrimaryWorkTermsFlag              | Constant: `Y`                                                                                         |
| PositionOverrideFlag              | Constant: `N`                                                                                         |
| EffectiveSequence                 | Constant: `1`                                                                                         |
| EffectiveLatestChange             | Constant: `Y`                                                                                         |
| AssignmentStatusTypeCode          | CASE WHEN derived_action = 'TER' THEN 'INACTIVE_PROCESS' ELSE 'ACTIVE_PROCESS' END                    |
| AssignmentType                    | CASE WHEN PS_JOB.PER_ORG = 'CWR' THEN 'CT' ELSE 'ET' END                                              |
| BusinessUnitShortCode             | Constant: `UCD Business Unit`                                                                         |
| LegalEmployerName                 | **(See Above)**                                                                                       |
| PeriodOfServiceId(SourceSystemId) | PS_JOB.EMPLID\|\|'_POS'                                                                               |

### Assignment Record

* **Record Type:** `Assignment`
* **Main Table:** `PS_JOB`
* **Metadata Line:** `METADATA|Assignment|SourceSystemOwner|SourceSystemId|PersonId(SourceSystemId)|WorkTermsAssignmentId(SourceSystemId)|EffectiveStartDate|EffectiveEndDate|AssignmentNumber|EffectiveSequence|JobCode|DepartmentName|LocationCode|AssignmentStatusTypeCode|PrimaryAssignmentFlag|AssignmentType|DefaultExpenseAccount|BusinessUnitShortCode|ActionCode|EffectiveLatestChange`

| HDL Record Field Name                 | Value                                                                                                 |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| SourceSystemOwner                     | Constant: `UCPATH`                                                                                    |
| SourceSystemId                        | PS_JOB.EMPLID\|\|'_EMP_ASG'                                                                           |
| PersonId(SourceSystemId)              | PS_JOB.EMPLID                                                                                         |
| WorkTermsAssignmentId(SourceSystemId) | PS_JOB.EMPLID\|\|'_EMP_TERM'                                                                          |
| EffectiveStartDate                    | CASE WHEN PS_JOB.ASGN_START_DT < date'1957-01-01' THEN date'1957-01-01' ELSE PS_JOB.ASGN_START_DT END |
| EffectiveEndDate                      | COALESCE(PS_JOB.ASGN_END_DT, date'4712-12-31')                                                        |
| AssignmentNumber                      | PS_JOB.EMPLID\|\|'_AN'                                                                                |
| EffectiveSequence                     | Constant: `1`                                                                                         |
| JobCode                               | PS_JOB.JOBCODE                                                                                        |
| DepartmentName                        | (see below)                                                                                           |
| Location Code                         | Constant: `UCD_ITEMORG`                                                                               |
| AssignmentStatusTypeCode              | CASE WHEN derived_action = 'TER' THEN 'INACTIVE_PROCESS' ELSE 'ACTIVE_PROCESS' END                    |
| PrimaryAssignmentFlag                 | Constant: `Y`                                                                                         |
| AssignmentType                        |                                                                                                       |
| DefaultExpenseAccount                 |                                                                                                       |
| BusinessUnitShortCode                 | Constant: `UCD Business Unit`                                                                         |
| ActionCode                            | **(derived action - TBD)**                                                                            |
| EffectiveLatestChange                 | Constant: `Y`                                                                                         |

#### Department Name

```sql
CASE PS_JOB.BUSINESS_UNIT
  WHEN 'DVCMP' THEN '100000B - UC Davis Campus'
  WHEN 'DVMED' THEN '132000B - UCD Medical Center'
  WHEN 'UCANR' THEN '991000B - ANR'
END
```

### Assignment Supervisor Record

* **Record Type:** `AssignmentSupervisor`
* **Main Table:** `PS_JOB`
* **Metadata Line:** `METADATA|AssignmentSupervisor|SourceSystemOwner|SourceSystemId|EffectiveStartDate|EffectiveEndDate|PrimaryFlag|AssignmentNumber|ManagerType|ManagerPersonNumber|ManagerAssignmentNumber`

| HDL Record Field Name   | Value                                                                                                 |
| ----------------------- | ----------------------------------------------------------------------------------------------------- |
| SourceSystemOwner       | Constant: `UCPATH`                                                                                    |
| SourceSystemId          | PS_JOB.EMPLID\|\|'_SUPERVISOR'                                                                        |
| EffectiveStartDate      | CASE WHEN PS_JOB.ASGN_START_DT < date'1957-01-01' THEN date'1957-01-01' ELSE PS_JOB.ASGN_START_DT END |
| EffectiveEndDate        | COALESCE(PS_JOB.ASGN_END_DT, date'4712-12-31')                                                        |
| PrimaryFlag             | Constant: `Y`                                                                                         |
| AssignmentNumber        | PS_JOB.EMPLID\|\|'_AN'                                                                                |
| ManagerType             | Constant: `LINE_MANAGER`                                                                              |
| ManagerPersonNumber     | Constant: `10`  (varies by environment)                                                               |
| ManagerAssignmentNumber | Constant: `E10` (varies by environment)                                                               |

### Data Extract Query

[](./employee_data_extract.sql ':include :type=code sql')


## Output Record Formatting

All records are pipe delimited using a fixed ordering of the columns.  The column order is defined by the METADATA record associated with the same record type.  The METADATA records are the first records in the file and is used to define the column orders for the remaining records.

Each row starts with an action command followed by the record type.  The action command is used to indicate the type of action to be performed on the record.

### Date Formatting

All dates are formatted as YYYY/MM/DD.

### Data Cleansing

* All extracted data should be trimmed of leading and trailing whitespace.

### Sample File

```txt
METADATA|Worker|SourceSystemOwner|SourceSystemId|EffectiveStartDate|EffectiveEndDate|PersonNumber|StartDate|ActionCode

METADATA|PersonName|SourceSystemOwner|SourceSystemId|PersonId(SourceSystemId)|EffectiveStartDate|EffectiveEndDate|NameType|LegislationCode|LastName|FirstName|MiddleNames|Suffix|KnownAs
METADATA|PersonEmail|SourceSystemOwner|SourceSystemId|PersonId(SourceSystemId)|DateFrom|EmailType|EmailAddress|PrimaryFlag
METADATA|PersonPhone|SourceSystemOwner|SourceSystemId|PersonId(SourceSystemId)|PhoneType|PhoneNumber|DateFrom
METADATA|PersonAddress|SourceSystemOwner|SourceSystemId|PersonId(SourceSystemId)|AddressType|AddressLine1|TownOrCity|Region2|PostalCode|Country|EffectiveStartDate|EffectiveEndDate
METADATA|PersonUserInformation|SourceSystemOwner|SourceSystemId|PersonId(SourceSystemId)|PersonNumber|StartDate|UserName

METADATA|WorkRelationship|SourceSystemOwner|SourceSystemId|PersonId(SourceSystemId)|WorkerType|PrimaryFlag|DateStart|NewStartDate|ActualTerminationDate|RevokeUserAccess|ReasonCode|LegalEmployerName
METADATA|WorkTerms|SourceSystemOwner|SourceSystemId|PersonId(SourceSystemId)|ActionCode|ReasonCode|EffectiveStartDate|EffectiveEndDate|PrimaryWorkTermsFlag|PositionOverrideFlag|EffectiveSequence|EffectiveLatestChange|AssignmentStatusTypeCode|AssignmentType|BusinessUnitShortCode|LegalEmployerName|PeriodOfServiceId(SourceSystemId)
METADATA|Assignment|SourceSystemOwner|SourceSystemId|PersonId(SourceSystemId)|WorkTermsAssignmentId(SourceSystemId)|EffectiveStartDate|EffectiveEndDate|AssignmentNumber|EffectiveSequence|JobCode|DepartmentName|LocationCode|AssignmentStatusTypeCode|PrimaryAssignmentFlag|AssignmentType|DefaultExpenseAccount|BusinessUnitShortCode|ActionCode|EffectiveLatestChange
METADATA|AssignmentSupervisor|EffectiveStartDate|EffectiveEndDate|PrimaryFlag|AssignmentNumber|ManagerType|ManagerPersonNumber|ManagerAssignmentNumber|SourceSystemOwner|SourceSystemId

MERGE|Worker|UCPATH|10249126|1999/12/13|4712/12/31|10249126|1999/12/13|HIRE

MERGE|PersonName|UCPATH|10249126_GLOBAL|10249126|1999/12/13|4712/12/31|GLOBAL|US|Badger|Kristy|G| |Kristy
MERGE|PersonEmail|UCPATH|10249126_PRSN_EMAIL|10249126|1999/12/13|W1|kgeer@ucdavis.edu|Y
MERGE|PersonPhone|UCPATH|10249126_PHONE|10249126|W1|1-503-752-1011|1999/12/13
MERGE|PersonAddress|UCPATH|10249126_ADDRESS|10249126|MAIL|One Shields Avenue|Davis|CA|95616|US|1999/12/13|4712/12/31
MERGE|PersonUserInformation|UCPATH|10249126_USINF|10249126|10249126|1999/12/13|kgeer

MERGE|WorkRelationship|UCPATH|10249126_POS|10249126|E|Y|1999/12/13|2022/10/24|||HIRE|UC Davis - Excluding Schools of Health
MERGE|WorkTerms|UCPATH|10249126_EMP_TERM|10249126|HIRE|HIRE|1999/12/13|4712/12/31|Y|N|1|Y|ACTIVE_PROCESS|ET|UCD Business Unit|UC Davis - Excluding Schools of Health|10249126_POS
MERGE|Assignment|UCPATH|10249126_EMP_ASG|10249126|10249126_EMP_TERM|1999/12/13|4712/12/31|10249126_AN|1|004725|100000B - UC Davis Campus|100|ACTIVE_PROCESS|Y|||UCD Business Unit|HIRE|Y
MERGE|AssignmentSupervisor|1999/12/13|4712/12/31|Y|10249126_AN|LINE_MANAGER|10|E10|UCPATH|10249126_EMP_ASG
```


### Oracle Action Code Values (DEV4/SIT3)

> Extracted 1/5/2023

| Action Code                  | Description                                   |
| :--------------------------- | --------------------------------------------- |
| ADD_ASSIGN                   | Add Assignment                                |
| ADD_CWK                      | Add Contingent Worker                         |
| ADD_CWK_WORK_RELATION        | Add Contingent Work Relationship              |
| ADD_EMP_TERMS                | Add Employment Terms                          |
| ADD_NON_WKR                  | Add Non-Worker                                |
| ADD_NON_WKR_WORK_RELATION    | Add Non-Worker Work Relationship              |
| ADD_PEN_WKR                  | Add Pending Worker                            |
| ADM_INDIV_CMP                | Administer Individual Compensation            |
| ALLOCATE_GRP_CMP             | Allocate Workforce Compensation               |
| ASG_CHANGE                   | Assignment Change                             |
| CHANGE_SALARY                | Change Salary                                 |
| CMP_GRADE_STEP_PROGRESSION   | Automated Grade Step Progression              |
| CMP_GSP_RATE_SYNCHRONIZATION | Grade Step Rate Synchronization               |
| CMP_GSP_UPD_SAL_ON_ASG_CHG   | Grade Step Change                             |
| CMP_RECALCULATE_RATES        | Recalculate Rates                             |
| CONTRACT_EXTENSION           | Contract Extension                            |
| DEATH                        | Death                                         |
| DEMOTION                     | Demotion                                      |
| EMPL_CANCEL_WR               | Cancel Work Relationship                      |
| EMPL_DELETE_CHANGE           | Delete Date Effective Change                  |
| EMPL_OFFER_CHANGE            | Change Offer                                  |
| EMPL_OFFER_CREATE            | Create Offer                                  |
| END_ASG                      | End Assignment                                |
| END_EMP_TERMS                | End Employment Terms                          |
| END_GLB_TEMP_ASG             | End Global Temporary Assignment               |
| END_PROBATION                | End Probation Period                          |
| END_TEMP_ASG                 | End Temporary Assignment                      |
| EXTEND_TEMP_ASG              | Extend Temporary Assignment                   |
| GLB_TEMP_ASG                 | Global Temporary Assignment                   |
| GLB_TRANSFER                 | Global Transfer                               |
| HIRE                         | Hire                                          |
| HIRE_ADD_WORK_RELATION       | Add Employee Work Relationship                |
| INVOLUNTARY_TERMINATION      | Involuntary Termination                       |
| INVOL_TERMINATE_PLACEMENT    | Involuntary Terminate Placement               |
| JOB_CHANGE                   | Job Change                                    |
| LOCATION_CHANGE              | Location Change                               |
| MANAGER_CHANGE               | Manager Change                                |
| MNG_CONTRIB                  | Manage Contributions                          |
| MNG_INDIV_CMP                | Manage Individual Compensation                |
| ORA_ADD_PWK_WORK_RELATION    | Add Pending Work Relationship                 |
| ORA_EMPL_CHG_HIRE_DATE       | Changes Hire Date                             |
| ORA_EMPL_CONTRACT_UPDATE     | Contract Update                               |
| ORA_EMPL_REV_TERMINATION     | Reverse Termination                           |
| ORA_EMPL_UPDATE_ASG_EFF      | Update Assignment EFF                         |
| ORA_IRC_ACCEPT_JOB_OFFER     | Move to HR                                    |
| ORA_PAY_REQUEST_PAY_ADVANCE  | Request Pay Advance                           |
| ORA_PER_EMPL_TERMINATE_OFFER | Terminate Offer                               |
| ORA_POS_SYNC                 | Synchronization From Position                 |
| ORA_SYNC_CONFIG_CHANGE       | Position Synchronization Configuration Change |
| ORA_SYNC_POS_TREE            | Synchronization from Position Tree            |
| PER_GRD_DELETE               | Delete                                        |
| PER_GRD_LDR_DELETE           | Delete                                        |
| PER_GRD_LDR_NEW              | Create                                        |
| PER_GRD_LDR_UPD              | Update                                        |
| PER_GRD_NEW                  | Create                                        |
| PER_GRD_RATE_DELETE          | Delete                                        |
| PER_GRD_RATE_NEW             | Create                                        |
| PER_GRD_RATE_UPD             | Update                                        |
| PER_GRD_UPD                  | Update                                        |
| PER_JOB_FAMILY_DELETE        | Delete                                        |
| PER_JOB_FAMILY_NEW           | Create                                        |
| PER_JOB_FAMILY_UPD           | Update                                        |
| PER_JOB_NEW                  | Create                                        |
| PER_JOB_UPD                  | Update                                        |
| PER_LOC_NEW                  | Create                                        |
| PER_LOC_UPD                  | Update                                        |
| PER_ORG_NEW                  | Create                                        |
| PER_ORG_UPD                  | Update                                        |
| PER_POS_DELETE               | Delete                                        |
| PER_POS_NEW                  | Create                                        |
| PER_POS_UPD                  | Update                                        |
| POSITION_CHANGE              | Position Change                               |
| PRIMARY_WR_CHANGE            | Primary Work Relationship Change              |
| PROBATION                    | Start Probation Period                        |
| PROMOTION                    | Promotion                                     |
| REDUCTION_FORCE              | Reduction in Force                            |
| REHIRE                       | Rehire an Employee                            |
| REN_CWK                      | Renew Placement                               |
| RESIGNATION                  | Resignation                                   |
| RETIREMENT                   | Retirement                                    |
| SUSP_ASSIGN                  | Suspend Assignment                            |
| SUSP_EMP_TERMS               | Suspend Employment Terms                      |
| TEMP_ASG                     | Temporary Assignment                          |
| TERMINATE_PLACEMENT          | Terminate Placement                           |
| TERMINATION                  | Termination                                   |
| TRANSFER                     | Transfer                                      |
| WORK_HOURS_CHANGE            | Working Hours Change                          |

### Oracle Action/Reason Code Allowed Combinations

| Action Code                  | Action Name                        | Reason Code                    | Reason Name                                          |
| ---------------------------- | ---------------------------------- | ------------------------------ | ---------------------------------------------------- |
| ADD_CWK                      | Add Contingent Worker              | PLACE                          | Placement to fill vacant position                    |
| ADD_CWK_WORK_RELATION        | Add Contingent Work Relationship   | PLACE_WORK_RELATION            | Additional work relationship for Contingent Worker   |
| ADD_NON_WKR                  | Add Non-Worker                     | NON_WKR                        | Creation of Non-Worker                               |
| ADD_NON_WKR_WORK_RELATION    | Add Non-Worker Work Relationship   | NON_WKR_WORK_RELATION          | Additional work relationship for Non-Worker          |
| ADD_PEN_WKR                  | Add Pending Worker                 | PENDWKR                        | Future hire to fill vacant position                  |
| ADM_INDIV_CMP                | Administer Individual Compensation | CMP_ADM_INDV                   | Administer Individual Compensation                   |
| CMP_GRADE_STEP_PROGRESSION   | Automated Grade Step Progression   | CMP_AUT_GSP                    | Automated Grade Step Progression                     |
| CMP_GSP_RATE_SYNCHRONIZATION | Grade Step Rate Synchronization    | CMP_GSP_RATE_SYNC              | Grade Step Rate Synchronization                      |
| CMP_GSP_UPD_SAL_ON_ASG_CHG   | Grade Step Change                  | CMP_GSP_UPD_SAL                | Grade Step Change                                    |
| DEATH                        | Death                              | WORK_RELATED                   | Work Incident or Work Related Illness                |
| END_ASG                      | End Assignment                     | ENDPROB                        | End Probation                                        |
| END_ASG                      | End Assignment                     | MGRREQ                         | Manager Request                                      |
| END_ASG                      | End Assignment                     | PLANEND                        | Planned End                                          |
| END_ASG                      | End Assignment                     | WORKERREQ                      | Worker Request                                       |
| HIRE                         | Hire                               | NEWHIRE                        | Hire to fill vacant position                         |
| HIRE_ADD_WORK_RELATION       | Add Employee Work Relationship     | HIRE_WORK_RELATION             | Additional work relationship for Employee            |
| MANAGER_CHANGE               | Manager Change                     | CORRECT_INVALID_SUP_ASG_PROC   | Correct Invalid Supervisor Assignments Process       |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_ADD_ASSIGN             | Addition of Assignment for Manager                   |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_ADD_CWK                | Addition of Contingent Worker for Manager            |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_ADD_CWK_WORK_RELATION  | Addition of Contingent Work Relationship for Manager |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_ADD_EMP_TERMS          | Addition of Employment Terms for Manager             |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_ADD_NON_WKR            | Addition of Nonworker for Manager                    |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_ADD_NON_WKR_WORK_RELAT | Addition of Nonworker Work Relationship for Manager  |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_ADD_PEN_WKR            | Addition of Pending Worker for Manager               |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_END_ASG                | End of Assignment for Manager                        |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_END_EMP_TERMS          | End of Employment Terms for Manager                  |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_END_GLB_TEMP_ASG       | End of Global Temporary Assignment for Manager       |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_END_TEMP_ASG           | End of Temporary Assignment for Manager              |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_GLB_TEMP_ASG           | Global Temporary Assignment for Manager              |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_GLB_TRANSFER           | Global Transfer of Manager                           |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_HIRE                   | New Hire of Manager                                  |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_HIRE_ADD_WORK_RELATION | Addition of Employee Work Relationship for Manager   |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_LOCATION_CHANGE        | Change of Location of Manager                        |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_MANAGER_CHANGE         | Change of Manager of Manager                         |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_PROMOTION              | Promotion of Manager                                 |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_RESIGNATION            | Resignation of Manager                               |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_TEMP_ASG               | Temporary Assignment of Manager                      |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_TERMINATION            | Termination of Manager                               |
| MANAGER_CHANGE               | Manager Change                     | MANAGER_TRANSFER               | Transfer of Manager                                  |
| MNG_INDIV_CMP                | Manage Individual Compensation     | CMP_INDV                       | Manage Individual Compensation                       |
| ORA_IRC_ACCEPT_JOB_OFFER     | Move to HR                         | ORA_IRC_CAND_ACCEPT_JOB_OFFER  | Job Offer Accepted                                   |
| PER_GRD_UPD                  | Update                             | PER_REORGANIZATION             | Reorganization                                       |
| PER_JOB_UPD                  | Update                             | PER_REORGANIZATION             | Reorganization                                       |
| PER_LOC_UPD                  | Update                             | PER_RELOCATION                 | Relocation                                           |
| PER_LOC_UPD                  | Update                             | PER_SEASONAL_CLOSURE           | Seasonal Closure                                     |
| PER_LOC_UPD                  | Update                             | PER_ZIPCHANGE                  | Postal Zone                                          |
| PER_ORG_UPD                  | Update                             | PER_REORGANIZATION             | Reorganization                                       |
| PER_POS_UPD                  | Update                             | PER_PROMOTION                  | Promotion                                            |
| PER_POS_UPD                  | Update                             | PER_REORGANIZATION             | Reorganization                                       |
| REHIRE                       | Rehire an Employee                 | REHIRE_WKR                     | Rehire to fill vacant position                       |
| REN_CWK                      | Renew Placement                    | RENEW_CWK                      | Renew of Contingent Worker placement                 |
| RESIGNATION                  | Resignation                        | RESIGN_PERSONAL                | Personal Reasons                                     |
| TERMINATION                  | Termination                        | WORK_RELATED                   | Work Incident or Work Related Illness                |
| TRANSFER                     | Transfer                           | CAREERPRO                      | Career Progression                                   |
| TRANSFER                     | Transfer                           | INTERNREC                      | Internal Recruitment                                 |
| TRANSFER                     | Transfer                           | LOCCHANGE                      | Location Change                                      |
| TRANSFER                     | Transfer                           | MGRREQ                         | Manager Request                                      |
| TRANSFER                     | Transfer                           | REORG                          | Reorganization                                       |
| TRANSFER                     | Transfer                           | WORKERREQ                      | Worker Request                                       |


## Notes (Remove this Section)

### Testing File Formats

The integration account has access to the UI to upload files.  If the automated system is not efficient for testing purposes, the UI may be used.

Go to Main Menu -> My Client Groups -> Data Exchange -> Section: HCM Data Loader -> Import and Load Data

Lists of the possible file record types and all possible fields are showw under the View Business Objects in the HCM Loader Section referenced above.

#### BIPub Queries to pull all Action/Reason Codes

```sql
SELECT
  av.action_code
, av.action_name
--, AR.ACTION_REASON_ID
, AR.ACTION_REASON_CODE
, AR.ACTION_REASON
--, AR.START_DATE,AR.END_DATE
--, H.*
FROM per_action_reasons_vl AR
JOIN hrc_integration_key_map H ON AR.ACTION_REASON_ID=H.SURROGATE_ID
JOIN per_action_reason_usages au ON au.action_reason_id=ar.action_reason_id
JOIN per_actions_vl av ON au.action_id=av.action_id
--WHERE av.action_code IN ( 'HIRE', 'REHIRE', 'TERMINATION', 'UPDATES' )
WHERE av.action_code NOT IN (
'ALLOCATE_GRP_CMP',
'CHANGE_SALARY',
'END_GLB_TEMP_ASG',
'END_TEMP_ASG',
'GLB_TEMP_ASG',
'GLB_TRANSFER',
'INVOLUNTARY_TERMINATION',
'MNG_CONTRIB',
'PER_GRD_LDR_UPD',
'PER_GRD_RATE_UPD',
'TEMP_ASG'
)
ORDER BY av.action_code, AR.ACTION_REASON_CODE
```

```sql
SELECT
  action_code
, action_name
, description
, start_date
, end_date
FROM per_actions_vl av
ORDER BY av.action_code
```

### High-Level

1. Create staging table to hold keys of employee/prmary job identifiers
2. Pull recently updated PS_JOB records from UCPath
3. Compare each against the staging table
4. Calculate the oracle action (HIR/REH/TER/DTA) based on the differences
5. Build the set of records for that person per the HDL import spec and data conversion mappings.
6. Upload to Oracle and monitor the job

### Open Questions

#### 12/9/22 Email

```txt
Ok.  Then we need to come up with a complete rule for the PS_JOB records I should be retrieving.

Assuming I will be looking at the most recent EFFDT/EFFSEQ record for each EMPLID / EMPL_RCD combination:

* Which records should I look at?  (We should probably define BU and job code filters...like to pull out the student assistant job codes...or are we loading them?)
* How does PER_ORG CWR record processing differ from PER records?  (I.e., per our prior discussions, they would all be seen as TER the first time this incremental runs.
* Title codes to exclude.  E.g., emeriti?

Of course, we can just load everyone...but should we?
```


#### Others

* We _are_ loading CWRs?  (Assuming those are the ones without positions.). And are we loading all CWRs or only ANR's?  And, is a CWR record ever marked as a "Primary" job?
* Explicit rules as to who we should and should not load.  These need to be immutable conditions for a given job or person, as we will not handle the case where a record disappears from the data set.  We need a properly updated record to be visible so we know to send a TER.

### Discussions

#### 12/9/22 Email

> I see I missed something on mine.  Line 2 probably needs to be T/P -> A/L/S to cover all conditions.
> [RG]: Agreed
>
> Actually - I did skip mentioning the "primary job" because I figured that is all I would load. What would this process need do if we have multiple records for an employee and the primary flag switches?  (Noting that we really won't know it "switched", but that a record that we had an entry for before now is no longer primary - and a new one appears that is primary.)
> [RG]: Good question; I would recommend that the combination of EMPLID and EMPL_RCD is extracted for most recent effective date and effective sequence row so one row needs to be compared to staging and that will be latest action on that EMPLID and EMPL_RCD combination.
>
> I would assume that if I see a non-primary, and there is no existing record in the staging table, that I would just ignore that.  But, if it switches between rows, do I send a TER for the one which is no longer primary, and a HIR for the other one?
> [RG]: Yes, That's correct.
>
> I should also note that we have had historical problems using the EMPL_RCD, as they get re-used.  Should we be basing this on EMPLID and POSITION_NBR instead?
> [RG]: if the EMPL_RCD is re-used then you can send a REH (rehire) row with all the job data attributes that may assists any co-teams to address any subsequent next steps to be addressed such as security provisioning as the staging record will have only primary job EMPL_RCD. If you replace empl_rcd to position number to be compared in staging record then you may run into multiple employee profiles to be created and it may lead to confusion for security team to assign what roles needs to be provisioned as there may be more than one row for the employee in oracle and additionally at UCANR - there are office managers who voluntarily work and do not have position numbers but are granted access to query and run any reports in DS and Kuali financial system in current state.

#### Jonathan / Raghuvir

> OK...so in this model - we would be retaining a staging table as part of integrations with at least the EMPLID, EMPL_RCD, and EMPL_STATUS values that were last used when sending data to Oracle.  This table would be queried for each employee found in the changed data since the last run.  And then the action to send to Oracle would be based on the difference between the EMPL_STATUS last seen for that employee and what is the most recent data load.

---

> Yes, I agree to your understanding. The staging record should also retain one more value that needs to be compared with incremental data received via RI and that is Job indicator = P (Primary Job).
> I did try to put it as below to buckets to provide myself more clarity and agree with your understanding and thought.

| #   | Staging Record EMPL_STATUS | New data received on incremental burst via RI | Translates to (for Oracle purpose) |
| --- | -------------------------- | --------------------------------------------- | ---------------------------------- |
| 01  | No Record                  | A/L/P/W                                       | HIR (Hire)                         |
| 02  | T/U/D/R                    | A/L/P/W                                       | REH (Rehire)                       |
| 03  | A/L/P/W                    | T/U/D/R                                       | TER (Termination)                  |
| 04  | A/L/P/W                    | A/L/P/W                                       | DTA (Data Change)                  |
| 05  | No Record                  | T/U/D/R                                       | Do Not Send                        |
| 06  | T/U/D/R                    | T/U/D/R                                       | Do Not Send                        |


### Considerations

* Per Scott Leaf: "For those that are only a contingent worker like many of our office managers, they don't have a primary job its flagged as Not Applicable."
* Is there any filtering on changes to employees which do not need to be sent?
* We need to load a supervisor record per discovery in December 2022 - still need mapping for that.
* We will need an initialization process to load all employees and their primary jobs into the reference table.

### EMPL_STATUS Codes

| EMPL_STATUS | Name                    |
| :---------: | ----------------------- |
|      A      | Active                  |
|      L      | Unpaid Leave of Absence |
|      P      | Paid Leave of Absence   |
|      W      | Short Work Break        |
|      D      | Deceased                |
|      R      | Retired                 |
|      T      | Terminated              |
|      U      | Terminated With Pay     |

### Sample Records

[](./Worker.dat ':include') <!-- Docsify Include Syntax -->
<<[](./Worker.dat) <!-- Marked 2 Renderer Syntax -->

### Query Notes

Extract will be a query of the following tables:

* PS_JOB
* PS_NAMES
* PS_EMAIL_ADDRESSES
* IAM_PERSON

It will utilize the base tables from UCPath exports to allow for portability to BISTG in the future.

The query will grab the data for ALL of the needed record types at once.  This will allow for a single query to be run, and then the data to be used to build the appropriate lines in the output file.

The mapping information from the data conversion team will be used to map from the UCPath Table/Columns to the HDL fields.

Data will be pulled based on changes in the PS_JOB (looking at the most recent version only).  All other data will be joined in.  In the initial version, we will not trigger on updates to the other tables, though that can be added easily enough.


### References

* <https://www.oracle.com/webfolder/technetwork/tutorials/obe/fusionapps/HCM/CreateLoadHDLFile/index.html>
* <https://docs.oracle.com/en/cloud/saas/human-resources/22d/fahdl/file-line-instructions-and-file-discriminators.html#s20055905>
* <https://docs.oracle.com/en/cloud/saas/human-resources/22d/fahbo/overview-of-loading-workers.html#s20057525>
* Oracle Action and Reason Codes: <https://support.oracle.com/epmos/faces/SearchDocDisplay?_adf.ctrl-state=15avr5medm_4&_afrLoop=383133750326937>
