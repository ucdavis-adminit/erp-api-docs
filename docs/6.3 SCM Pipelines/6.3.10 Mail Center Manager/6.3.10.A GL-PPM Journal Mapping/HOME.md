# 6.3.10.A GL-PPM Journal Mapping

### MCM Query to GL-PPM Flattened Mapping

#### Departmental Expenses

| GL-PPM Field                | MCM Query Field                                            | Notes                                      |
| --------------------------- | ---------------------------------------------------------- | ------------------------------------------ |
| **Request Header Fields**   |                                                            |                                            |
| `consumerId`                | UCD Bulk Mail Recharges                                    |                                            |
| `boundaryApplicationName`   | Mail Services MCM                                          |                                            |
| `consumerReferenceId`       | CAMPUS_yyyyMMdd                                            | If campus data extract                     |
|                             | UCDH_yyyyMMdd                                              | If UCDH data extract                       |
| `consumerTrackingId`        | CAMPUS_yyyyMMddHHmmss                                      | If campus data extract                     |
|                             | UCDH_yyyyMMddHHmmss                                        | If UCDH data extract                       |
| `consumerNotes`             | (unset)                                                    |                                            |
| `requestSourceType`         | sftp                                                       |                                            |
| `requestSourceId`           | journal.UCD_Bulk_Mail_Recharges.CAMPUS_yyyyMMddHHmmss.json | If Campus Data                             |
|                             | journal.UCD_Bulk_Mail_Recharges.UCDH_yyyyMMddHHmmss.json   | If UCDH Data                               |
| **Journal Header Fields**   |                                                            |                                            |
| `journalSourceName`         | UCD Bulk Mail Recharges                                    |                                            |
| `journalCategoryName`       | UCD Recharge                                               |                                            |
| `journalName`               | Mail Services yyyy-MM-dd to yyyy-MM-dd                     | Use start and end date                     |
| `journalDescription`        | (unset)                                                    |                                            |
| `journalReference`          | Mail Services yyyy-MM-dd to yyyy-MM-dd                     |                                            |
| `accountingDate`            | (today)                                                    |                                            |
| `accountingPeriodName`      | (unset)                                                    |                                            |
| **Line Fields**             |                                                            |                                            |
| `debitAmount`               | total_charges                                              |                                            |
| `creditAmount`              |                                                            |                                            |
| `externalSystemIdentifier`  | transaction_id                                             |                                            |
| `externalSystemReference`   |                                                            |                                            |
| `ppmComment`                | carrier_name                                               |                                            |
| **GL Segment Fields**       |                                                            |                                            |
| `entity`                    | segment_string                                             |                                            |
| `fund`                      | segment_string                                             |                                            |
| `department`                | segment_string                                             |                                            |
| `account`                   | 770002 (ignore value in segment string if present)         |                                            |
| `purpose`                   | segment_string                                             |                                            |
| `glProject`                 | segment_string                                             |                                            |
| `program`                   | segment_string                                             |                                            |
| `activity`                  | segment_string                                             |                                            |
| `interEntity`               | 0000                                                       |                                            |
| `flex1`                     | 000000                                                     |                                            |
| `flex2`                     | 000000                                                     |                                            |
| **PPM Segment Fields**      |                                                            |                                            |
| `ppmProject`                | segment_string                                             |                                            |
| `task`                      | segment_string                                             |                                            |
| `organization`              | segment_string                                             |                                            |
| `expenditureType`           | segment_string                                             |                                            |
| `award`                     | segment_string (or blank)                                  |                                            |
| `fundingSource`             | segment_string (or blank)                                  |                                            |
| **Internal Control Fields** |                                                            |                                            |
| `lineType`                  | based on segment_string                                    |                                            |
| **GLIDe Fields**            |                                                            |                                            |
| `lineDescription`           | carrier_name                                               | Type of postage/service                    |
| `journalLineNumber`         | row number in journal                                      | ROW_NUMBER() OVER ()                       |
| `transactionDate`           | trans_date                                                 |                                            |
| `udfNumeric1`               | num_pieces                                                 |                                            |
| `udfNumeric2`               | base_rate                                                  |                                            |
| `udfNumeric3`               |                                                            |                                            |
| `udfDate1`                  | trans_date                                                 |                                            |
| `udfDate2`                  |                                                            |                                            |
| `udfString1`                | account_name (different from requirements)                 | Trim to 50 characters - name of department |
| `udfString2`                | carrier_id                                                 |                                            |
| `udfString3`                | transaction_id                                             |                                            |
| `udfString4`                | surcharge_flag                                             | N or S                                     |
| `udfString5`                | segment_string                                             | Original segment string from MCM           |

#### Pass Through Expense Offset

| GL-PPM Field                | MCM Query Field                                            | Notes                  |
| --------------------------- | ---------------------------------------------------------- | ---------------------- |
| **Request Header Fields**   |                                                            |                        |
| `consumerId`                | UCD Bulk Mail Recharges                                    |                        |
| `boundaryApplicationName`   | Mail Services MCM                                          |                        |
| `consumerReferenceId`       | CAMPUS_yyyyMMdd                                            | If campus data extract |
|                             | UCDH_yyyyMMdd                                              | If UCDH data extract   |
| `consumerTrackingId`        | CAMPUS_yyyyMMddHHmmss                                      | If campus data extract |
|                             | UCDH_yyyyMMddHHmmss                                        | If UCDH data extract   |
| `consumerNotes`             | (unset)                                                    |                        |
| `requestSourceType`         | sftp                                                       |                        |
| `requestSourceId`           | journal.UCD_Bulk_Mail_Recharges.CAMPUS_yyyyMMddHHmmss.json | If Campus Data         |
|                             | journal.UCD_Bulk_Mail_Recharges.UCDH_yyyyMMddHHmmss.json   | If UCDH Data           |
| **Journal Header Fields**   |                                                            |                        |
| `journalSourceName`         | UCD Bulk Mail Recharges                                    |                        |
| `journalCategoryName`       | UCD Recharge                                               |                        |
| `journalName`               | Mail Services yyyy-MM-dd to yyyy-MM-dd                     | Use start and end date |
| `journalDescription`        | (unset)                                                    |                        |
| `journalReference`          | Mail Services yyyy-MM-dd to yyyy-MM-dd                     |                        |
| `accountingDate`            | (today)                                                    |                        |
| `accountingPeriodName`      | (unset)                                                    |                        |
| **Line Fields**             |                                                            |                        |
| `debitAmount`               |                                                            |                        |
| `creditAmount`              | SUM(total_charges)                                         |                        |
| `externalSystemIdentifier`  | PASSTHRU                                                   |                        |
| `externalSystemReference`   |                                                            |                        |
| `ppmComment`                |                                                            |                        |
| **GL Segment Fields**       |                                                            |                        |
| `entity`                    | from `MCM Pass Thru Chartstring`                           |                        |
| `fund`                      | from `MCM Pass Thru Chartstring`                           |                        |
| `department`                | from `MCM Pass Thru Chartstring`                           |                        |
| `account`                   | from `MCM Pass Thru Chartstring`                           |                        |
| `purpose`                   | from `MCM Pass Thru Chartstring`                           |                        |
| `glProject`                 | from `MCM Pass Thru Chartstring`                           |                        |
| `program`                   | from `MCM Pass Thru Chartstring`                           |                        |
| `activity`                  | from `MCM Pass Thru Chartstring`                           |                        |
| `interEntity`               | 0000                                                       |                        |
| `flex1`                     | 000000                                                     |                        |
| `flex2`                     | 000000                                                     |                        |
| **PPM Segment Fields**      |                                                            |                        |
| `ppmProject`                |                                                            |                        |
| `task`                      |                                                            |                        |
| `organization`              |                                                            |                        |
| `expenditureType`           |                                                            |                        |
| `award`                     |                                                            |                        |
| `fundingSource`             |                                                            |                        |
| **Internal Control Fields** |                                                            |                        |
| `lineType`                  | `glSegments`                                               |                        |
| **GLIDe Fields**            |                                                            |                        |
| `lineDescription`           | Mail Services Recharges Pass Thru                          |                        |
| `journalLineNumber`         |                                                            |                        |
| `transactionDate`           | MAX(trans_date)                                            |                        |
| `udfNumeric1`               |                                                            |                        |
| `udfNumeric2`               |                                                            |                        |
| `udfNumeric3`               |                                                            |                        |
| `udfDate1`                  | MAX(trans_date)                                            |                        |
| `udfDate2`                  |                                                            |                        |
| `udfString1`                |                                                            |                        |
| `udfString2`                |                                                            |                        |
| `udfString3`                |                                                            |                        |
| `udfString4`                |                                                            |                        |
| `udfString5`                |                                                            |                        |

#### Mark-Up Revenue Offset

| GL-PPM Field                | MCM Query Field                                            | Notes                  |
| --------------------------- | ---------------------------------------------------------- | ---------------------- |
| **Request Header Fields**   |                                                            |                        |
| `consumerId`                | UCD Bulk Mail Recharges                                    |                        |
| `boundaryApplicationName`   | Mail Services MCM                                          |                        |
| `consumerReferenceId`       | CAMPUS_yyyyMMdd                                            | If campus data extract |
|                             | UCDH_yyyyMMdd                                              | If UCDH data extract   |
| `consumerTrackingId`        | CAMPUS_yyyyMMddHHmmss                                      | If campus data extract |
|                             | UCDH_yyyyMMddHHmmss                                        | If UCDH data extract   |
| `consumerNotes`             | (unset)                                                    |                        |
| `requestSourceType`         | sftp                                                       |                        |
| `requestSourceId`           | journal.UCD_Bulk_Mail_Recharges.CAMPUS_yyyyMMddHHmmss.json | If Campus Data         |
|                             | journal.UCD_Bulk_Mail_Recharges.UCDH_yyyyMMddHHmmss.json   | If UCDH Data           |
| **Journal Header Fields**   |                                                            |                        |
| `journalSourceName`         | UCD Bulk Mail Recharges                                    |                        |
| `journalCategoryName`       | UCD Recharge                                               |                        |
| `journalName`               | Mail Services yyyy-MM-dd to yyyy-MM-dd                     | Use start and end date |
| `journalDescription`        | (unset)                                                    |                        |
| `journalReference`          | Mail Services yyyy-MM-dd to yyyy-MM-dd                     |                        |
| `accountingDate`            | (today)                                                    |                        |
| `accountingPeriodName`      | (unset)                                                    |                        |
| **Line Fields**             |                                                            |                        |
| `debitAmount`               |                                                            |                        |
| `creditAmount`              | SUM(markup_amount)                                         |                        |
| `externalSystemIdentifier`  | REVENUE                                                    |                        |
| `externalSystemReference`   |                                                            |                        |
| `ppmComment`                |                                                            |                        |
| **GL Segment Fields**       |                                                            |                        |
| `entity`                    | from `MCM Revenue Chartstring`                             |                        |
| `fund`                      | from `MCM Revenue Chartstring`                             |                        |
| `department`                | from `MCM Revenue Chartstring`                             |                        |
| `account`                   | from `MCM Revenue Chartstring`                             |                        |
| `purpose`                   | from `MCM Revenue Chartstring`                             |                        |
| `glProject`                 | from `MCM Revenue Chartstring`                             |                        |
| `program`                   | from `MCM Revenue Chartstring`                             |                        |
| `activity`                  | from `MCM Revenue Chartstring`                             |                        |
| `interEntity`               | 0000                                                       |                        |
| `flex1`                     | 000000                                                     |                        |
| `flex2`                     | 000000                                                     |                        |
| **PPM Segment Fields**      |                                                            |                        |
| `ppmProject`                |                                                            |                        |
| `task`                      |                                                            |                        |
| `organization`              |                                                            |                        |
| `expenditureType`           |                                                            |                        |
| `award`                     |                                                            |                        |
| `fundingSource`             |                                                            |                        |
| **Internal Control Fields** |                                                            |                        |
| `lineType`                  | `glSegments`                                               |                        |
| **GLIDe Fields**            |                                                            |                        |
| `lineDescription`           | Mail Services Markup Revenue                               |                        |
| `journalLineNumber`         |                                                            |                        |
| `transactionDate`           | MAX(trans_date)                                            |                        |
| `udfNumeric1`               |                                                            |                        |
| `udfNumeric2`               |                                                            |                        |
| `udfNumeric3`               |                                                            |                        |
| `udfDate1`                  | MAX(trans_date)                                            |                        |
| `udfDate2`                  |                                                            |                        |
| `udfString1`                |                                                            |                        |
| `udfString2`                |                                                            |                        |
| `udfString3`                |                                                            |                        |
| `udfString4`                |                                                            |                        |
| `udfString5`                |                                                            |                        |
