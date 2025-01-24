# 6.3.1.1 Card Allocations

### Data Flow Design

#### 1. Card allocation Data Extract

1. We will be getting flow from Card Allocations funnel after Split SAE processing.
2. Find accounting segment values by querying database using last 4 digits of credit card and employee ID and transaction type properties. (`ExecuteGroovyScript`)
3. Attach the kickout chartstring to the flow file. (`UpdateAttribute`)  This may then be used to replace segments on bad lines with the kickout segments.
4. Convert the overall format of the data into the format required by the GL-PPM Line validation pipeline. (`QueryRecord`)
   1. See [Section 6.2.5](#/6%20Data%20Pipelines/6.2%20Common%20Inbound%20Pipelines/6.2.5%20GL-PPM%20Flattened/HOME ':ignore') for details on the format.
5. Add the journal header attributes to the flowfile.  (`PartitionRecord`)
6. Validate the segment values by using the `Validate GL Segments` and `Validate PPM Segments` process groups.
    1. Disable the `Validation Error Records` and `Passed Validation` output ports and set their relationships to expire flowfiles after one second.
    2. Enable the `All Records` output port and remove any expiration time on the relationship.
    3. Between each process group, update any records where line_valid = 'false' to the kickout chartstring. (`QueryRecord` or `UpdateRecord`)
7. Post the flowfile to the validated topic:
    1. Topic: `in.#{instance_id}.internal.json.gl_ppm_validated`
    2. Headers: `.*`
    3. Kafka Key: `${source.id}`

**TODO: Add the offset to balance the journal**

### Chartstring Parsing Groovy Script

This script must extract the value of the last4 digits of credit card and convert into either a PPM or GL set of segments fields.  To avoid issues with schema inference, all segment fields should be added to each record of the flowfile, regardless of whether they have mapped values.  The script must also set the `lineType` to `glSegments` or `ppmSegments` as appropriate.

```groovy
// get value of 4last digits of credit card
// query database to obtain GL or PPM
// if neither, then populate GL fields with kickout values
// Populate lineType with either glSegments or ppmSegments

// This script can also include the calculation of the totals on the line as required by the GL-PPM validated input topic.  See section 6.2.1 for the script which performs the calculation of the 4 attributes required.
```

### MCM Query to GL-PPM Flattened Mapping

| GL-PPM Field                | Concur Query Field                                   | Notes                |
| --------------------------- | ---------------------------------------------------- | -------------------- |
| **Request Header Fields**   |                                                      |                      |
| `consumerId`                | UCD Concur                                           |                      |
| `boundaryApplicationName`   | Concur                                               |                      |
| `consumerReferenceId`       | Concur_yyyyMMddHHmmss                                |                      |
| `consumerTrackingId`        | Concur_yyyyMMddHHmmss                                |                      |
| `consumerNotes`             | (unset)                                              |                      |
| `requestSourceType`         | sftp                                                 |                      |
| `requestSourceId`           | journal.Concur_yyyyMMddHHmmss.json                   |                      |
| **Journal Header Fields**   |                                                      |                      |
| `journalSourceName`         | UCD Concur                                           |                      |
| `journalCategoryName`       | UCD Recharges                                        |                      |
| `journalName`               | Batch_ID2 _BatchDate_3_Journal                       |                      |
| `journalDescription`        | (unset)                                              |                      |
| `journalReference`          | BatchID_2                                            |                      | '_'  |  | BatchDate_3                       |                       | '_Journal' |  |
| `accountingDate`            | BatchDate_3                                          |                      |
| `accountingPeriodName`      | (unset)                                              |                      |
| **Line Fields**             |                                                      |                      |
| `debitAmount`               | JournalAmount_169                                    | If positive          |
| `creditAmount`              | JournalAmount_169                                    | If negative          |
| `externalSystemIdentifier`  | ReportID_19                                          |                      |
| `externalSystemReference`   | PC_ReportKey_20   (when PCard) or TC-ReportKey_20    |                      |
| `ppmComment`                | EmployeeLastName_6                                   |                      | ', ' |  | EmployeeFirstName_7               |                       | ' '        |  | EmployeeID_5 |  |
| **GL Segment Fields**       | it is GL segment when AllocationCustom17_207 is NULL |                      |
| `entity`                    | AllocationCustom10_200 AllocationCustom14_204                               |                      |
| `fund`                      | AllocationCustom11_201 AllocationCustom7_197                              |                      |
| `department`                | AllocationCustom12_202  AllocationCustom8_198                             |                      |
| `account`                   | JournalAccountCode_167                               |                      |
| `purpose`                   | AllocationCustom13_203  AllocationCustom13_203                             |                      |
| `glProject`                 | COALESCE(AllocationCustom14_204,'0000000000') AllocationCustom9_199        |                      |
| `program`                   | COALESCE(AllocationCustom15_205, '000' ) AllocationCustom15_205           |                      |
| `activity`                  | COALESCE(AllocationCustom16_206, '000000' )  AllocationCustom16_206        |                      |
| `interEntity`               | 0000                                                 |                      |
| `flex1`                     | 000000                                               |                      |
| `flex2`                     | 000000                                               |                      |
| **PPM Segment Fields**      | PPM segment when AllocationCustom17_207 is NOT NULL  |                      |
| `ppmProject`                | COALESCE(AllocationCustom14_204,'0000000000')   AllocationCustom10_200 (first part before /)     |                      |
| `task`                      | AllocationCustom17_207  AllocationCustom10_200 (second part after /)                             |                      |
| `organization`              | AllocationCustom18_208 AllocationCustom11_201                              |                      |
| `expenditureType`           | JournalAccountCode_167                               |                      |
| `award`                     | AllocationCustom20_210 (or blank)  (blank)                  |                      |
| `fundingSource`             | (blank)                              |                      |
| **Internal Control Fields** |                                                      |                      |
| `lineType`                  | based on segment_string                              |                      |
| **GLIDe Fields**            |                                                      |                      |
| `lineDescription`           | ReportName_27                                        |                      | '_'  |  | BilledCreditCardAccountNumber_130 |                       |
| `journalLineNumber`         | row number in journal                                | ROW_NUMBER() OVER () |
| `transactionDate`           | ReportUserDefinedDate_25                             |                      |
| `udfNumeric1`               |                                                      |                      |
| `udfNumeric2`               |                                                      |                      |
| `udfNumeric3`               |                                                      |                      |
| `udfDate1`                  | ReportUserDefinedDate_25                             |                      |
| `udfDate2`                  |                                                      |                      |
| `udfString1`                | EmployeeLastName_6                                   |                      | ', ' |  | EmployeeFirstName_7               | Trim to 50 characters |
| `udfString2`                | EmployeeID_5                                         |                      |
| `udfString3`                | ReportKey_20                                         |                      |

### Outbound Flowfile Attributes

| Attribute Name                | Attribute Value                |
| ----------------------------- | ------------------------------ |
| `record.count`                |                                |
| `consumer.id`                 | Concur Card Recharges          |
| `data.source`                 | sftp                           |
| `source.id`                   | same as `requestSourceId`      |
| `boundary.system`             | Concur                         |
| `consumer.ref.id`             | same as `consumerReferenceId`  |
| `consumer.tracking.id`        | same as `consumerTrackingId`   |
| `glide.extract.enabled`       | Y                              |
| `glide.summarization.enabled` | Y                              |
| `journal.name`                | same as `journalName`          |
| `journal.source`              | same as `journalSourceName`    |
| `journal.category`            | same as `journalCategoryName`  |
| `accounting.date`             | same as `accountingDate`       |
| `accounting.period`           | same as `accountingPeriodName` |
| `journal.debits`              | (calculated)                   |
| `journal.credits`             | (calculated)                   |
| `gl.total`                    | (calculated)                   |
| `ppm.total`                   | (calculated)                   |

### Sample Data



### Allocate Card Expenses To Departments

#### Summary

Generates the GL and PPM costing documents to allocate expenses per data entered on the expense report.  Offsets the expense using the default location per the card account data in concur.  Where the allocation is to a PPM Project, a PPM cost will be generated and an offsetting GL transaction will be included.


#### Flow Summary

1. Read flowfile containing a report's set of records to allocate card expenses from the input topic.
2.


### Concur Card Reimbursements

#### Summary

Sub-pipeline to handle the generation of the GL and PPM FBDI files needed to reallocate the expenses on the travel card and the purchasing card to the accounts listed in the expense report.  This will offset the entry in the SAE using the clearing account noted on the concur card account table extracts.

#### Input

This flow accepts flowfiles containing a single report's entries which are allocating expenses made on the travel or purchasing cards.  These flowfiles may have multiple records which match this criteria.

#### Additional Requirements

This flow requires a lookup table of the concur card account data.  This must be a specialized key-value pair table which combines the employee ID, card type (PCard/TCard), and last 4 of the card number into a single key field.  This must be linked through a lookup service for use by NiFi processors.

#### High-Level Flow Summary

1. Read in the flow file with the records
2. Run a lookup on each record to obtain the clearing account and store into the record.
   1. If account number is missing, flow into a retry queue with a 24 hour delay (waiting for card data to get loaded from concur)
3. Update each record in the file to mark as a PPM or GL entry.
4. For each PPM string set in the file:
   1. Duplicate the line
   2. On duplicate: flag as PPM Offset
   3. On duplicate: set the GL segments to the PPM offset
   4. On duplicate: clear any PPM segments
5. Partition the flowfile based on the GL/PPM flag:
   1. GL Flow:
      1. Duplicate each GL record, making the follwing changes to the duplicate:
         1. Mark as an offset record.
         2. Flip the sign on the amount.
         3. Set the account to the proper account for the offset
         4. Copy the clearing account into the account record
         5. Blank out any other allocation fields.  (GL and PPM)
      2. Summarize records by chart of accounts and card type
      3. Reformat flowfile into GL Journal Lines JSON (sub-format of API format)
   2. PPM Flow:
      1. Reformat flowfile into GL Journal Lines JSON (sub-format of API format) filling in the PPM segments and other attributes.

**TBD: Do we want to go straight to FBDI here?**

#### Flow Summary

> Input: CSV Flow File with records for single report and CBCP entries for a single card number.

1. Strip record down to just fields needed for processing, summarizing the amounts.
   * `ReportKey_20` AS report_key
   * `EmployeeID_5` AS emplid
   * `UPPER(EmployeeLastName_6+'/'+SUBSTRING(EmployeeFirstName_7, 1))` AS empl_name
   * `CASE ReportPolicyName_33 WHEN '*PCard' THEN 'PC'+'-'+ReportName_27 ELSE 'TC'+'-'+ReportName_27 END` AS report_name
   * `SUBSTRING(BilledCreditCardAccountNumber_130 FROM 13)` AS CC_LAST_4
   * `EmployeeID_5||'_'||SUBSTRING(BilledCreditCardAccountNumber_130 FROM 13)` AS card_lookup_key
   * JournalAccountCode_167 AS erp_account
   * `AllocationCustom1_191` - `AllocationCustom20_210` (as needed)
     * `AllocationCustom10_200` as erp_entity
     * `AllocationCustom11_201` as erp_fund
     * `AllocationCustom12_202` as erp_department
     * `AllocationCustom13_203` as erp_purpose
     * `COALESCE(AllocationCustom14_204,'0000000000')` as erp_project
     * `COALESCE(AllocationCustom15_205, '000' )` as program
     * `COALESCE(AllocationCustom16_206, '000000' )` as activity
     * `AllocationCustom17_207` as ppm_project_task
   * `CASE WHEN AllocationCustom17_207 IS NULL THEN 'GL' ELSE 'PPM' END` AS segment_type
   * `'SAE'` AS record_type
   * '' AS credit_card_offset_chartstring
   * ROUND(SUM(JournalAmount_169),2) AS alloc_amount
2. Process the file, creating offset lines for each `/segment_type` = 'PPM' record.  Leave all GL lines alone. (`QueryRecord`)
   1. Clone the record. (UNION ALL)  All changes below are only to the cloned record.
   2. Update record field: `/record_type` = 'PPMOffset'
   3. Update record field: `/segment_type` = 'GL'
   4. Clear values from all GL and PPM segments.
   5. Set GL segments to the established PPM offset chartstring values.
3. `PartitionRecord` based on the `/segment_type` field.
   1. `/segment_type` = PPM
      1. Restructure records into property names needed for GL Journal Line inputs using the ppmSegments sub-object.
         1. `/erp_department`, `/erp_account`, `/ppm_project_task` into ppmSegments
         2. `/alloc_amount` into debitAmount (if positive) or creditAmount (if negative)
         3. **TODO on PPM FIELDS**
         4. `/report_key` into the externalSystemIdentifier
         5. `/report_name` into externalSystemReference
         6. ???? into ppmComment
         7. `/emplid` into ????
   2. `/segment_type` = GL
      1. Perform `LookupRecord` call using record path `/card_lookup_key`
         1. Route failures to a `RetryFlowFile` processor which re-runs every 24 hours.
         2. On Success, save the offset account to a new record field: `/credit_card_offset_chartstring`
      2. Clone each record to generate the balancing offsets: (`QueryRecord`)  The below is the change to the cloned records.
         1. Add record field: `/record_type` = 'GLOffset'
         2. Change the sign on the journal amount.
         3. Clear values from all GL and PPM segments.
         4. Parse the offset account in `/credit_card_offset_chartstring` into the GL fields: `/erp_entity`, `/erp_fund`, `/erp_department`, `/erp_purpose`
         5. Set the `/erp_account` segment from the established account per configuration.
      3. Restructure records into property names needed for GL Journal Line inputs using the glSegments sub-object.
         1. `/erp_xxxx` into glSegments
         2. `/report_key` into the externalSystemIdentifier
         3. `/report_name` into externalSystemReference
         4. `/alloc_amount` into debitAmount (if positive) or creditAmount (if negative)

> **At this point we have transactions which are ready to include in files.  The header information is missing.  However, at this point, we probably want the transactions to be blended back together so that we are not sending through hundreds of documents for a day's feed.  It _would_ be OK if the feed were split up into multiple journals due to streaming latency.**

#### Notes

> Experimental QueryRecord SQL

```sql
SELECT
  ReportKey_20
, EmployeeID_5
, EmployeeLastName_6
, EmployeeFirstName_7
, ReportName_27
, ReportPolicyName_33
, SUBSTRING(BilledCreditCardAccountNumber_130 FROM 13) AS CC_LAST_4
, JournalPayeePaymentTypeName_165
, CAST(JournalAccountCode_167 AS VARCHAR) AS JournalAccountCode_167
, AllocationCustom1_191
, ReportEntryPaymentTypeName_250
, ROUND(SUM(JournalAmount_169),2) AS JournalAmount_169
FROM FLOWFILE
GROUP BY
  ReportKey_20
, EmployeeID_5
, EmployeeLastName_6
, EmployeeFirstName_7
, ReportName_27
, ReportPolicyName_33
, SUBSTRING(BilledCreditCardAccountNumber_130 FROM 13)
, JournalPayeePaymentTypeName_165
, CAST(JournalAccountCode_167 AS VARCHAR)
, AllocationCustom1_191
, ReportEntryPaymentTypeName_250
UNION ALL
SELECT
  ReportKey_20
, EmployeeID_5
, EmployeeLastName_6
, EmployeeFirstName_7
, ReportName_27
, ReportPolicyName_33
, SUBSTRING(BilledCreditCardAccountNumber_130 FROM 13) AS CC_LAST_4
, JournalPayeePaymentTypeName_165
, CAST('0000' AS VARCHAR) AS JournalAccountCode_167
, '${offset.chartstring}' AS AllocationCustom1_191
, ReportEntryPaymentTypeName_250
, -ROUND(SUM(JournalAmount_169),2) AS JournalAmount_169
FROM FLOWFILE
GROUP BY
  ReportKey_20
, EmployeeID_5
, EmployeeLastName_6
, EmployeeFirstName_7
, ReportName_27
, ReportPolicyName_33
, SUBSTRING(BilledCreditCardAccountNumber_130 FROM 13)
, JournalPayeePaymentTypeName_165
, ReportEntryPaymentTypeName_250
```
