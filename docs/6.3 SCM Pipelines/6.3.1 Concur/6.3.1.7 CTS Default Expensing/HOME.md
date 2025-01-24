# 6.3.1.7 CTS Default Expensing

### Overview

We receive files from our travel agency partner(s) with expenses charged to our ghost cards used for paying for airfare and hotel expenses on special UCD programs.  The data in these files must be expensed to the ledger based on the home department of the employee and the nature of the expense.  (E.g., airfare, hotel, etc...)  These will be expensed to GL strings only which are maintained by HR department code in the travel and entertainment approver maintenance application.

* **Functional Spec:** <https://ucdavis.app.box.com/file/947317608126?s=6in1fw0c5wfipqc7a3ri5gh0utzpj7tl>

### Data Flow (Current)

1. SCM staff receive the data file from the travel agency via email.
2. SCM Staff upload the CSV file to the TP database.
3. A Trigger on that table copies the data over to AIT_INT for use by the integration servers.
4. A Batch job processes the new data in that table
   1. Identify the employee and expense type for each record.
   2. Look up the main department for that employee from the department approver system.
   3. Look up the default cost center for that department.
   4. Derive the correct object code for the expense type.
   5. Generate an expense line for each record to charge the department.
   6. Offset to a liability account related to this process.
5. The journal is uploaded to the financial system.

### Final Future State

> This will require substantial additional development to the CTS Maintenance application, as we need to provide it a data upload and validation capability it does not currently have.

1. SCM staff receive the data file from the travel agency via email.
2. SCM staff upload the file via the CTS Maintenance application.
   1. This prompts for any data corrections that are needed before allowing it to continue.
   2. Data validations will be performed against the GraphQL APIs for Oracle and UCPath
3. The data is loaded into a staging table in the Integration Platform database.
4. A NiFi process reads unprocessed data from that table.
   1. Look up the main department for that employee from the department approver system.
   2. Look up the default cost center for that department from a support table with that information.
   3. Derive the correct natural account for the expense type.
   4. Generate an expense line for each record to charge the department.
   5. Validate the cost center information and redirect to a kickout cost center if invalid.
   6. Offset to a liability account related to this process.
   7. Submit the entry as a Quick Expense to Concur.
5. Submit the completed journal to the validated GL-PPM queue for continued processing and submission.
6. Send an email summary to the SCM team with the results of the processing.

### Initial (MVP) Implementation and Flow

#### Data Flow

1. SCM staff receive the data file from the travel agency via email.
2. SCM Staff upload the CSV file to the TP database.
3. A Trigger on that table copies the data over to AIT_INT for use by the integration servers.
4. _A NiFi process will move new data from that table to a staging table in the Integration Platform database on a regular basis._
   1. _(THIS IS A TEMP STEP UNTIL WE CAN GET THE CTS MAINTENANCE APP TO DO THIS - QueryDatabaseTable on insert_dt from AIT_INT and insert into `concur_cts_transaction`)_
5. A NiFi process reads unprocessed data from that table.
   1. flag the records as in process
   2. Look up the main department for that employee from: ???
      1. Need to check if we can get this information from the Oracle person extract or if we need to get it from UCPath / AIT_INT.
   3. Look up the default cost center for that department from `concur_cts_dept_cost_center`.
   4. Derive the correct natural account for the expense type.
   5. Generate an expense line for each record to charge the department.
   6. Validate the cost center information and redirect to a kickout cost center if invalid.
   7. Offset to a liability account related to this process.
6. Submit the completed journal to the validated GL-PPM queue for continued processing and submission.
7. flag the inprocess records as processed
8. Send an email summary to the SCM team with the results of the processing.

#### Required Infrastructure Objects

* **Database Table: `concur_cts_dept_cost_center`**

```js
      t.string('department_code', 25);
      t.string('sub_department_code', 25);

      t.string('entity',4);
      t.string('fund',5);
      t.string('fin_dept',7);
      t.string('account',6);
      t.string('purpose',2);
      t.string('program',3);
      t.string('project',10);
      t.string('activity',6);
      t.string('inter_entity',4);
      t.string('flex1',6);
      t.string('flex2',6);
```

* **Database Table: `concur_cts_transaction`**

```sql
CREATE TABLE concur_cts_transaction (
    id                   bigserial,
    merchant_nm          varchar(40),
    traveler_id          varchar(9),
    traveler_nm          varchar(40),
    trans_dt             date,
    trans_amt            decimal(12,2),
    card_id              varchar(4),
    ticket_nbr           varchar(13),
    agency_nm            varchar(30),
    invoice_nbr          varchar(15),
    reservation_cd       varchar(6),
    depart_dt            date,
    trans_unique_id      varchar(40),
    arranger_nm          varchar(40),
    file_rec_nbr         decimal,
    load_dt              date,
    trans_type           varchar(10),
    card_type            varchar(4),
    biid                 varchar(4),
    insert_dt            timestamp default NOW(),
    processing_status    varchar(20) DEFAULT 'UNPROCESSED',
    processed_job_id     varchar(40),
    processing_message   text,
    processed_dt         timestamp,
    PRIMARY KEY(id)
)
/
ALTER TABLE concur_cts_transaction ADD CONSTRAINT concur_cts_transaction_u1
  UNIQUE(traveler_id,trans_dt,trans_amt,ticket_nbr,agency_nm,invoice_nbr)
/
CREATE INDEX concur_cts_transaction_i2 ON concur_cts_transaction (processing_status)
/
```

#### Items to Include in the notification email

* Number of records processed
* Number of records which had to use kickout accounts
* total amount of records processed
* Date of processing
* name of input file
* generated journal name


## CTS Default Expensing Design

There are two pipelines required for this until the CTS Maintenance application is able to insert directly into the staging table.

1. Copy the data from the AIT_INT database table loaded by existing processes into the Postgres staging database.
2. Process the data from the staging table to generate the journal.

### Copy CTS Data to Staging Table

1. Based on the insert date, pull records from the AIT_INT database table (`FD_TE_CNXS_LDR_T`) into the staging table (`concur_cts_transaction`). (`QueryDatabaseTable`)
2. Insert the records into the staging table. (`PutDatabaseRecord`)
   1. Ignore key violations.

### Process Pending CTS Data

1. Query the staging table for records which are in `UNPROCESSED` status.
2. Generate the job run IDs and insert a record into `pipeline_request`.
3. Update the status to `INPROCESS` for the records being processed.
4. Run a lookup to get the HR department from the given employee ID on the record.
   1. If the lookup has no match, add a message to the record, mark the record status as `BAD_EMPLOYEE_ID` and continue to the next record.  (These must be fixed manually for the employee ID or to mark as `UNPROCESSED`.)
5. Look up the cost center for the transaction from the `concur_cts_dept_cost_center` table.
   1. If the lookup has no match, add a message to the record, mark the record status as `MISSING_COST_CENTER` and continue to the next record.  (These must be fixed manually to add the cost center data and then mark as `UNPROCESSED`.)
6. Derive the natural account from the travel type on the record.
   1. (**Need Logic for this from the existing application**)
7. Convert the record into the GL-PPM Flattened format for the transaction and the offset.
8. Prepare the journal for submission to the GL-PPM validation topic.
9. Send the journal onto the GL-PPM validation topic.
10. Mark the INPROCESS records as PROCESSED and tag with the job run ID.
11. Query the staging table for records which have the current job run ID or an invalid status to include on a report.
12. Use the information to generate a report of the records processed.
    1. Send the report via email.
    2. Update the request_report column on the pipeline_request record with the report.

### GL-PPM Mapping

| GL-PPM Field                | Transaction                                       | Offset                       |
| --------------------------- | ------------------------------------------------- | ---------------------------- |
| **Request Header Fields**   |                                                   |                              |
| `consumerId`                | UCD Concur                                        | (same)                       |
| `boundaryApplicationName`   | CTS Default Expensing                             | (same)                       |
| `consumerReferenceId`       | CONCUR_CTS_yyyyMMdd                               | (same)                       |
| `consumerTrackingId`        | CONCUR_CTS_yyyyMMddHHmmss                         | (same)                       |
| `consumerNotes`             | (unset)                                           | (same)                       |
| `requestSourceType`         | sftp                                              | (same)                       |
| `requestSourceId`           | journal.UCD_Concur.CONCUR_CTS_yyyyMMddHHmmss.json | (same)                       |
| **Journal Header Fields**   |                                                   |                              |
| `journalSourceName`         | UCD Concur                                        | (same)                       |
| `journalCategoryName`       | UCD Recharge                                      | (same)                       |
| `journalName`               | CTS Default Expenses yyyy-MM-dd                   | (same)                       |
| `journalDescription`        | (unset)                                           | (same)                       |
| `journalReference`          | CTS Default Expenses yyyy-MM-dd                   | (same)                       |
| `accountingDate`            | (unset)                                           | (same)                       |
| `accountingPeriodName`      | (unset)                                           | (same)                       |
| **Line Fields**             |                                                   |                              |
| `debitAmount`               | trans_amt (if positive)                           | ABS(trans_amt) (if negative) |
| `creditAmount`              | ABS(trans_amt) (if negative)                      | trans_amt (if positive)      |
| `externalSystemIdentifier`  | card_id                                           | (same)                       |
| `externalSystemReference`   | reservation_cd / ticket_nbr                       | (same)                       |
| `ppmComment`                | (unset)                                           |                              |
| **GL Segment Fields**       |                                                   |                              |
| `entity`                    | From Department                                   | **????**                     |
| `fund`                      | From Department                                   | **????**                     |
| `department`                | From Department                                   | **????**                     |
| `account`                   | Derived from trans_type?                          | **????**                     |
| `purpose`                   | From Department                                   | **????**                     |
| `glProject`                 | 0000000000                                        | 0000000000                   |
| `program`                   | 000                                               | 000                          |
| `activity`                  | 000000                                            | 000000                       |
| `interEntity`               | 0000                                              | 0000                         |
| `flex1`                     | 000000                                            | 000000                       |
| `flex2`                     | 000000                                            | 000000                       |
| **PPM Segment Fields**      |                                                   |                              |
| `ppmProject`                | (unset)                                           |                              |
| `task`                      | (unset)                                           |                              |
| `organization`              | (unset)                                           |                              |
| `expenditureType`           | (unset)                                           |                              |
| `award`                     | (unset)                                           |                              |
| `fundingSource`             | (unset)                                           |                              |
| **Internal Control Fields** |                                                   |                              |
| `lineType`                  | `glSegments`                                      | `glSegments`                 |
| **GLIDe Fields**            |                                                   |                              |
| `lineDescription`           | merchant_nm                                       |                              |
| `journalLineNumber`         |                                                   |                              |
| `transactionDate`           | trans_dt                                          |                              |
| `udfNumeric1`               |                                                   |                              |
| `udfNumeric2`               |                                                   |                              |
| `udfNumeric3`               |                                                   |                              |
| `udfDate1`                  | depart_dt                                         |                              |
| `udfDate2`                  |                                                   |                              |
| `udfString1`                | traveler_nm                                       |                              |
| `udfString2`                | traveler_id                                       |                              |
| `udfString3`                | trans_unique_id                                   |                              |
| `udfString4`                | agency_nm                                         |                              |
| `udfString5`                |                                                   |                              |


#### Offset


## Reference Information for CTS Processing

### Staging table used by current batch process

```sql
      CREATE TABLE FD_TE_CNXS_LDR_T (
        MERCHANT_NM          VARCHAR2(40),
        TRAVELER_ID          VARCHAR2(9),
        TRAVELER_NM          VARCHAR2(40),
        TRANS_DT             DATE,
        TRANS_AMT            NUMBER(12,2),
        CARD_ID              VARCHAR2(4),
        TICKET_NBR           VARCHAR2(13),
        AGENCY_NM            VARCHAR2(30),
        INVOICE_NBR          VARCHAR2(15),
        RESERVATION_CD       VARCHAR2(6),
        DEPART_DT            DATE,
        TRANS_UNIQUE_ID      VARCHAR2(40),
        ARRANGER_NM          VARCHAR2(40),
        FILE_REC_NBR         NUMBER,
        LOAD_DT              DATE,
        TRANS_TYPE           VARCHAR2(10),
        CARD_TYPE            VARCHAR2(4),
        BIID                 VARCHAR2(4),
        INSERT_DT       DATE DEFAULT TRUNC(SYSDATE),
        CONSTRAINT FD_TE_CNXS_LDR_TP1 PRIMARY KEY(TRAVELER_ID,TRANS_DT,TRANS_AMT,TICKET_NBR,AGENCY_NM,INVOICE_NBR)
      )
```


![diagram](cts-data-flow-new.svg)

![diagram](cts-data-flow-old.svg)