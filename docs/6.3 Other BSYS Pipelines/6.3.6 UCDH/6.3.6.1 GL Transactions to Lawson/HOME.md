# 6.3.6.1 GL Transactions to Lawson

### Overview

Lawson needs to receive the GL transaction extracted from Oracle on a regular basis.  This extract is used to feed their internal financial system.  The extract will contain all GL information which affects the UCDH entities except for that data which was itself fed into Oracle from Lawson.

When the job runs, it will pull all the records in the `gl_je_batches` which have a posted_date in a buffer period.  Each batch in the pull will be compared to a tracking table which records the batches which have been sent to Lawson.  If a completed record is found in that table, it will be skipped.

The extract will by default run using the posting date range of yesterday through today.  (This covers the overnight runs.)  A special runner will be included in the job to allow for a run using manual dates.  All jobs will use the tracking table to avoid duplicates.

* Functional Specification: <https://ucdavis.app.box.com/file/917244081312>

### High-Level Flow

1. Calculate the job start date from today and the lookback days parameter and generate a job ID UUID.  Set an end date of today.
   1. Add an alternate disabled processor which allows setting of the start and end dates manually.  (For recovery purposes.)
2. Run the query to get all the data posted between those dates.
3. Run lookups against `gl_export_batch_tracking` using the `je_batch_id` and destination system ID.
   1. This will need to be done via the view defined below due to how lookup processors work.
4. Run the batch IDs through an update to insert the records in the tracking table, leaving the complete flag as "N".
5. Format for transmission to Lawson and set `avro.schema` to the `lawson_transactions` schema given in section 6.3.6.A.
   1. Only non-blank, non-default fields need to be included, as the Avro schema will generate the rest in the Writer.
6. Use Convert Record to build the CSV file with all needed columns for Lawson.
7. Write the resulting file to an S3 bucket.  (An Operations process will pickup and SFTP to Lawson.)
8. Update the job_complete_flag to `Y` in the tracking table for the current job ID.

### Transaction Batch Tracking Table

To ensure that we do not send duplicate transactions to Lawson, we need to track the batches that have been sent.  This table will track each batch ID and the timestamp of the job id was sent on.  This table is designed to be used for multiple downstream boundary applications.

**Table Name:** `<env>_staging.gl_export_batch_tracking`

| Column Name              | Data Type           | Notes                                                       |
| ------------------------ | ------------------- | ----------------------------------------------------------- |
| destination_system_id    | varchar(20)         |                                                             |
| je_batch_id              | bigint              |                                                             |
| export_job_id            | uuid                | ID of the job which this batch ID was include in            |
| export_job_ts            | timestamptz         | Job start time                                              |
| export_job_complete_flag | char(1) default 'N' | Set when the job is completed.  Used to detect failed jobs. |

* **Indexes**
  * destination_system_id, je_batch_id, export_job_id (PK)
  * export_job_id, destination_system_id

### Lookup View and Controller Service

> We need this view to support the nature of the lookup service in only allowing a single-field key.  BUT, if this results in performance issues, we can either perform the lookup on the batch ID and then scan for the destination system ID.  OR, we can also add the composite key to the above table in addition to the separate key columns.

#### View Definition

```sql
CREATE OR REPLACE VIEW <env>_staging.gl_export_batch_tracking_view AS
SELECT
  destination_system_id||'-'||je_batch_id AS id,
  export_job_id
FROM <env>_staging.gl_export_batch_tracking
WHERE export_job_complete_flag = 'Y'
```

#### Controller Service

Create a controller service against the above view.  The `id` column will be the key and the `export_job_id` will be the returned value.

### Reference Data

* Destination System ID: `ucdh_lawson`
* Excluded Journal Sources:
  * `UCD Lawson`
  * `Assets`
  * `UCD Conversion`
* Excluded Journal Source/Entity Combinations:
  * `Project Accounting` / `3210`
* Exclude InterEntity Transactions: **No**
* Included Entity Codes:
  * `3210` - UCDH
  * `3111` - SOM
* Actuals Only: Yes - value A only
* Excluded Zero $ Transactions: **Yes**
* Excluded Accounts:
  * `16000B` - Capital Assets
  * `16500B` - Accumulated Depreciation
  * `54200B` - Depreciation Expenses
* Output S3 Location: `<env>/out/ucdhLawson`
* Output Schema Name: `lawson_transactions`

### Parameters

> Parameter Context: `UCDH Integrations (6.3.6)`

* `transaction_lookback_days` - Number of days to look back for transactions.  Default: 1

### Table References

The tables below are the tables that will need to be used during this process.

* `<env>_erp.gl_je_batches`
  * PK: `je_batch_id`
  * Posted Status: `status` (= `P` for posted)
  * Posted Date Field: `posted_date`
  * Journal Source field (for filtering): `je_source`
  * Transaction Type field (for filtering): `actual_flag` (= `A` for actuals)
* `<env>_erp.gl_je_headers`
  * PK: `je_header_id`
  * FK: `je_batch_id`
* `<env>_erp.gl_je_lines`
  * PK: `je_header_id`, `je_line_num`
  * FK: `je_header_id`
  * GL Segment Values Join Field: `code_combination_id`
* `<env>_erp.gl_code_combination`
  * PK: `code_combination_id`
  * `segment1` = entity
  * `segment2` = fund
  * `segment3` = fin_dept
  * `segment4` = account
  * `segment5` = purpose
  * `segment6` = program
  * `segment7` = project
  * `segment8` = activity
  * `segment9` = inter_entity
  * `segment10` = flex1
  * `segment11` = flex2

### Query for Journal Transactions Extract

```sql
SELECT
-- For these free-text entry fields, we need to ensure that only characters allowed
-- in the lawson input file are sent.  (ASCII 32-126)
  LEFT(TRIM(REGEXP_REPLACE(h.name, '[^\x20-\x7E]', ' ', 'g')), 30)               AS journal_name
, LEFT(TRIM(REGEXP_REPLACE(h.external_reference, '[^\x20-\x7E]', ' ', 'g')), 32) AS journal_reference
, TO_CHAR(l.effective_date, 'YYYYMMDD')   AS effective_date
, TO_CHAR(l.creation_date, 'YYYYMMDD')    AS creation_date
, c.segment1                              AS entity
, c.segment3                              AS fin_dept
, c.segment4                              AS account
-- , LPAD(c.segment9, 4, '0')                AS inter_entity
, COALESCE(l.entered_dr, -l.entered_cr)   AS line_amt
, b.je_batch_id                           AS je_batch_id
, LEFT(COALESCE(js.key, b.je_source), 32) AS je_source
, p.effective_period_num                  AS accounting_period
FROM      gl_je_batches           b
     JOIN gl_je_headers           h  ON h.je_batch_id         = b.je_batch_id
     JOIN gl_period               p  ON p.period_name         = h.period_name
     JOIN gl_je_lines             l  ON l.je_header_id        = h.je_header_id
     JOIN gl_code_combination     c  ON c.code_combination_id = l.code_combination_id
LEFT JOIN gl_segments             s  ON s.segment_type        = 'erp_account'
                                    AND s.code                = c.segment4
LEFT JOIN gl_journal_source      js  ON js.name               = b.je_source
WHERE b.status = 'P'      -- posted only
  AND h.status = 'P'      -- posted only
  AND l.status = 'P'      -- posted only
  AND b.actual_flag = 'A' -- actuals only
  -- only transactions starting in January 2024 (FY 24, Period 07)
  AND p.effective_period_num >= #{extract_start_eff_period_num}
  -- Exclude journals from Lawson and those for fixed asset transactions
  AND COALESCE(js.key, b.je_source) NOT IN ( 'UCD Lawson', 'Assets', 'UCD Conversion' )
  -- Exclude Adjustment Journals entered by Central Finance
  AND h.je_category NOT IN ( '100000D_CENTRAL_MC_ADJUSTMENTS' )
  -- Exclude UCDH entries from the PPM Module
  AND NOT ( c.segment1 = '3210' AND b.je_source = 'Project Accounting' )
  -- Only UCDH and SOM Entity Codes
  AND c.segment1 IN ( '3210', '3111' )
  -- Exclude inter-entity transactions
  --AND c.segment9 IN ( '0', '0000' )
  -- Exclude fixed asset accounts
  AND COALESCE(s.parent_level_2_code,'X') NOT IN ( '16000B', '16500B', '54200B' )
  -- No point in including zero $ transactions
  AND COALESCE(l.entered_dr, -l.entered_cr) != 0
  -- Look for transactions in the given range
  AND b.posted_date >= '${start.date}'
ORDER BY b.je_batch_id
```



## Oracle GL to Lawson Flow Design

### Parameter Context: UCDH Integrations (6.3.6)

| Parameter                    | Value                              | Description                                                                                                           |
| ---------------------------- | ---------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `transaction_lookback_days`  | 1                                  | Number of days to look back for transactions.                                                                         |
| `pipeline_id`                | `ucdh`                             | Pipeline ID used in feedback messages.                                                                                |
| `success_notification_email` | <hs-maestroipa@ou.ad3.ucdavis.edu> | Email of UCDH team member to notify after file is sent.                                                               |
| `failure_notification_email` | <hs-maestroipa@ou.ad3.ucdavis.edu> | Email address sent to when there is an error in the pipeline processing that prevents the upload of the file to UCDH. |
| `bcc_notification_email`     | <jhkeller@ucdavis.edu>             | Email of AdminIT team member to BCC on all emails from this proces.                                                   |
| `destination_id`             | `ucdh_lawson`                      | Destination system ID used when tracking prior sent batches.                                                          |

### Scheduling

Trigger runs every 2 hours at 50 minutes after the hour and looks for all transactions posted in the last 2 days.  Already processed transactions are skipped.

### Controller Services

#### LookupService - SQL - Export Batch ID

* Table: #{int_db_staging_schema}.gl_export_batch_tracking_view
* Key: id
* Result: export_job_id

#### Writer - CSV - Lawson Transactions

* CSV writer using the avro.schema attribute. `lawson_transactions.avsc`

### Pipeline Flow

1. Trigger flow and calculate the start date to look for transaction batches to process. (`GenerateFlowFile`)
   1. Use the `transaction_lookback_days` parameter to calculate the start date.

    ```txt
    ${now()
    :toNumber()
    :minus(
      ${#{transaction_lookback_days}
      :multiply(86400000)}
    ):format('yyyy-MM-dd')}
    ```

2. Query for all posted batches that have a `posted_date` greater than or equal to the start date. (`ExecuteSQLRecord`)
   1. Include filters that will eliminate transactions which should not be fed back to Lawson.  See high-level design for rules.

3. Run a lookup on the je_batch_id to see if the batch has already been processed. (`LookupRecord`)
   1. If the batch has already been processed, then route to the `matched` relationship.  These records will be thrown away.
   2. If the batch has not been processed, then route to the `unmatched` relationship.

4. Extract the distinct batch IDs in the file and route to insert records in the `gl_export_batch_tracking` table. (`PartitionRecord`)
   1. `je.batch.id` = `/je_batch_id`

5. From the split files, process via `PutSQL` to insert the needed records.

6. Re-Merge the records using the defragment process: (`DefragmentRecord`)

7. Reformat the data into the Lawson Output Format and convert to CSV
   1. Reformat and generate field names (`QueryRecord`)
      1. This also includes remappings of certain department values per Lawson requirements.
   2. Attach the output schema (`UpdateAttribute`)
   3. Reformat to CSV (`ConvertRecord`)
   4. Update Column headers to remove underscores (`ReplaceText`)

8. Upload file to S3 (`PutS3Object`)

9. Update the `gl_export_batch_tracking` table to indicate the batch has been processed. (`PutSQL`)

10. Email functional users with the success message and some file metrics. (`PutEmail`)

#### Lawson Data Conversion Rules

1. If Entity is 3210 (UCDH) and the account starts with 1, 2, or 3, then the department must be changed to '9500000'.
2. If Entity is 3210 (UCDH) and the account is one of 9500000, 1000001, 1000002, 1000003, 1000004, 1000005, 1000006, or 1000007, then the department must be changed to '1009893'.
3. If Entity is 3111 (SOM) and the account starts with 1, 2, or 3, then the department must be changed to '1000002'.
4. If Entity is 3111 and the account does not start with 1, 2, or 3, and the department is one of 1000001, 1000002, 1000003, 1000004, 1000005, 1000006, or 1000007, then the department must be changed to '1009894'.

#### 4. SQL To Insert Batch Tracking Records

```sql
INSERT INTO #{int_db_staging_schema}.gl_export_batch_tracking
  ( destination_system_id
  , je_batch_id
  , export_job_id
  , export_job_ts
  ) VALUES (
  '#{destination_id}'
  , ${je.batch.id}
  , '${export.job.id}'
  , '${export.job.timestamp}'
  )
```

#### 7. QueryRecord SQL To Reformat Data

```sql
SELECT
  'OR${now():format('yyyyMMddHHmm', '#{TZ}')}' AS Run_Group
, ROW_NUMBER() OVER ()                         AS Sequence_Number
, entity                                       AS Company
, entity||
  CASE
    -- UCDH Entity Rules
    WHEN entity = '3210' AND account LIKE '1%' THEN '9500000'
    WHEN entity = '3210' AND account LIKE '2%' THEN '9500000'
    WHEN entity = '3210' AND account LIKE '3%' THEN '9500000'
    WHEN entity = '3210'
     AND fin_dept IN ('9500000', '1000001', '1000002', '1000003', '1000004', '1000005', '1000006', '1000007') THEN '1009893'
    -- SOM Entity Rules
    WHEN entity = '3111' AND account LIKE '1%' THEN '1000002'
    WHEN entity = '3111' AND account LIKE '2%' THEN '1000002'
    WHEN entity = '3111' AND account LIKE '3%' THEN '1000002'
    WHEN entity = '3111'
     AND fin_dept IN ('1000001', '1000002', '1000003', '1000004', '1000005', '1000006', '1000007') THEN '1009894'
    -- Otherwise use the Oracle Financial Department
    ELSE fin_dept
  END               AS Old_Company
, account           AS Old_Account_Number
, creation_date     AS Trans_Date
, journal_name      AS Description
, line_amt          AS Transaction_Amount
, line_amt          AS Base_Amount
, effective_date    AS Posting_Date
, journal_reference AS Attribute_Value_1
, je_source         AS Attribute_Value_2
, accounting_period -- Used for file splitting only
FROM FLOWFILE
```

#### 9. SQL To Update Batch Tracking Records

```sql
UPDATE #{int_db_staging_schema}.gl_export_batch_tracking
   SET export_job_complete_flag = 'Y'
 WHERE export_job_id = '${export.job.id}'
   AND destination_system_id = '#{destination_id}'
```

#### 10. Success Email Notification

* `To:      #{success_notification_email}`
* `Subject: [#{instance_id}] Oracle GL to Lawson Successful Feed Creation (${entity})`
* Body:

```txt
Successful Creation of Oracle GL to Lawson Feed File

Company/Entity:       ${entity}
Filename:             ${filename}
Record Count:         ${record.count}
Export Job ID:        ${export.job.id}
Export Job Timestamp: ${export.job.timestamp}

Transactions Posted On Or After: ${start.date}
(Previously Exported Transactions Excluded)
```


### Lawson Format and Mapping

> Format: CSV File, Headers as below, in order

| CSV Header                 | Type and Length | Oracle Field Mapping                   | Description                                                                                                                                                                                                                                                                                              |
| :------------------------- | :-------------- | :------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Run Group                  | Alpha 15        | `OR`+yyyyMMddHHmm                      | A user-defined unique identifier used to group together a set of records to process selectively or concurrently.                                                                                                                                                                                         |
| Sequence Number            | Numeric 6       | (blank)                                | A user-defined unique identifier assigned to each transaction to be transferred into the Lawson system. If all other key fields are alike, this may be used so that no duplicates will occur.                                                                                                            |
| Company                    | Numeric 4       | gl_code_combination.segment1 (entity)  | The "from company" on intercompany transactions. If the transaction is not intercompany, this field will equal the GTR-OLD-COMPANY (Lawson company portion or Lawson company being mapped to).                                                                                                           |
| Old Company                | Alpha 35        | gl_code_combination.segment1 +         | A user-defined field that contains the old company structure to be associated with the Lawson company and accounting unit. This field determines what company and accounting unit a record will convert to.                                                                                              |
|                            |                 | gl_code_combination.segment3 (dept)    |                                                                                                                                                                                                                                                                                                          |
| Old Account Number         | Alpha 25        | gl_code_combination.segment4 (account) | A user-defined field that contains the old account structure to be associated with the new account and subaccount within the Lawson system. This field determines what account and subaccount a record will convert to, within the company and accounting unit that was determined with GTR-OLD-COMPANY. |
| Source Code                | Alpha 2         | `OR`                                   | Used to indicate where the transaction was created. The source code must be a valid source code in the GLCODES (UNIX/Windows) DBIFGCD (System i)  database file.                                                                                                                                         |
| Trans Date                 | yyyymmdd 8      | creation_date                          | Contains the system creation date. If the field is not filled in, the date of running the GL165 will be assigned in its place.                                                                                                                                                                           |
| Reference                  | AlphaLower 10   | (blank)                                | The reference number associated with the transaction. User-defined field used to categorize transactions.                                                                                                                                                                                                |
| Description                | AlphaLower 30   | gl_je_headers.name                     | User-defined description of the transaction record.                                                                                                                                                                                                                                                      |
| Currency Code              | Alpha 5         | `USD`                                  | User-defined currency code used if the transaction is not in the company's base currency.                                                                                                                                                                                                                |
| Units Amount               | Signed 15.2     | (blank)                                | Contains the transaction units amount.                                                                                                                                                                                                                                                                   |
| Transaction Amount         | Signed 18.2     | gl_je_lines.entered_cr or entered_dr   | Transaction amount (positive or negative) in currency to be posted. This amount creates a CUAMOUNT (UNIX/Windows) DBGLCAM (System i)  type 1 record.                                                                                                                                                     |
| Base Amount                | Signed 18.2     | gl_je_lines.entered_cr or entered_dr   | Transaction amount (positive or negative) in base currency to be posted to the GL Master file.                                                                                                                                                                                                           |
| Base Rate                  | Signed 14.7     | (blank)                                | The exchange rate at time of creation (for non-base currency transactions). If left blank, the current exchange rate will default.                                                                                                                                                                       |
| System                     | Alpha 2         | GL                                     | A two-character code representing an application used within the Lawson system (for example, GL=General Ledger, AP=Accounts Payable). It must be a valid system code in the GLCODES (UNIX/Windows) DBIFGCD (System i)  database file.                                                                    |
| Program Code               | Alpha 5         | (blank)                                | Used to identify where a program was created. You may define this as any five characters.                                                                                                                                                                                                                |
| Auto Reverse               | Alpha 1         | (blank)                                | Auto reversal is the process of reversing the transaction. If you select auto reverse, Period Closing (GL199) creates a reversing journal entry in the next period for this transaction.                                                                                                                 |
| Posting Date               | yyyymmdd 8      | gl_je_lines.effective_date             | This date, assigned to the journal entry, determines what period and year the transaction (journal entry) will reside in after completing the Transaction Conversion process.                                                                                                                            |
| Activity                   | Alpha 15        | (blank) - _pending UCDH review_        | Activities are the processes or procedures that produce work. Cost objects (products, services, customers) are the reasons for performing the activity.                                                                                                                                                  |
| Account Category           | Alpha 5         | (blank)                                | Account categories are groupings of costs, revenues, or a combination of both used for reporting and inquiries for activities in Project Accounting.                                                                                                                                                     |
| Document Number            | Alpha 27        | (blank)                                | A reference field used for sub-system journaling by document. If the company you are converting to is journaling by document, this field will be used to determine where to batch a new journal entry.                                                                                                   |
| To Base Amount             | Signed 18.2     | (blank)                                | Contains the To Company base amount. Transaction amount for intercompany transactions (to be used with the GTR-COMPANY ).                                                                                                                                                                                |
| Effect Date                | yyyymmdd 8      | (blank)                                | The effective date of the transaction, used with Average Daily Balance. For conversion, fill with spaces or the posting date.                                                                                                                                                                            |
| Journal Book Number        | Alpha 12        | (blank)                                | The journal book assigned to the transaction.                                                                                                                                                                                                                                                            |
| Attribute Value 1          | Alpha 32        | gl_je_headers.external_reference       | Contains the attribute value.                                                                                                                                                                                                                                                                            |
| Attribute Value 2          | Alpha 32        | gl_je_batches.je_source                | Contains the attribute value.                                                                                                                                                                                                                                                                            |
| Attribute Value 3          | Alpha 32        | (blank)                                | Contains the attribute value.                                                                                                                                                                                                                                                                            |
| Sequence Number            | Numeric 10      | (blank)                                | The next available journal book sequence number assigned to an interfaced transaction when added to the Lawson system.                                                                                                                                                                                   |
| Negative Adjustment        | Alpha 1         | (blank)                                | Indicates a negative adjustment for auto-reversing interfaced transactions; used if you have defined your company as requiring single type accounts.                                                                                                                                                     |
| User Analysis              | Alpha 103       | (blank)                                | The user analysis fields included in the transaction. User analysis fields are defined in the Lawson Strategic Ledger application.                                                                                                                                                                       |
| Report Currency One Amount | Signed 18.2     | (blank)                                | The transaction amount for Report Currency One.                                                                                                                                                                                                                                                          |
| Exchange Rate One          | Signed 14.7     | (blank)                                | The exchange rate to convert the transaction amount to Report Currency One.                                                                                                                                                                                                                              |
| Decimal One                | Numeric 1       | (blank)                                | The number of decimal positions allowed for the Report Currency One amount.                                                                                                                                                                                                                              |
| Report Currency Two Amount | Signed 18.2     | (blank)                                | The transaction amount for Report Currency Two.                                                                                                                                                                                                                                                          |
| Exchange Rate Two          | Signed 14.7     | (blank)                                | The exchange rate to convert the transaction amount to Report Currency Two.                                                                                                                                                                                                                              |
| Decimal Two                | Numeric 1       | (blank)                                | The number of decimal positions allowed for the Report Currency Two amount.                                                                                                                                                                                                                              |
