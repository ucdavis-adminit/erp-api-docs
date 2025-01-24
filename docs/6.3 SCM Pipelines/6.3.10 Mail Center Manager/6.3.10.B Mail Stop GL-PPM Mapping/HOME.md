# 6.3.10.B Mail Stop GL-PPM Mapping

### MCM Query to GL-PPM Flattened Mapping

#### Departmental Expenses

| GL-PPM Field                | MCM Query Field                                               | Notes                            |
| --------------------------- | ------------------------------------------------------------- | -------------------------------- |
| **Request Header Fields**   |                                                               |                                  |
| `consumerId`                | UCD Bulk Mail Recharges                                       |                                  |
| `boundaryApplicationName`   | Mail Services MCM                                             |                                  |
| `consumerReferenceId`       | MS_CAMPUS_yyyyMMdd                                            | If campus data extract           |
|                             | MS_UCDH_yyyyMMdd                                              | If UCDH data extract             |
| `consumerTrackingId`        | MS_CAMPUS_yyyyMMddHHmmss                                      | If campus data extract           |
|                             | MS_UCDH_yyyyMMddHHmmss                                        | If UCDH data extract             |
| `consumerNotes`             | (unset)                                                       |                                  |
| `requestSourceType`         | sftp                                                          |                                  |
| `requestSourceId`           | journal.UCD_Bulk_Mail_Recharges.CAMPUS_MS_yyyyMMddHHmmss.json | If Campus Data                   |
|                             | journal.UCD_Bulk_Mail_Recharges.UCDH_MS_yyyyMMddHHmmss.json   | If UCDH Data                     |
| **Journal Header Fields**   |                                                               |                                  |
| `journalSourceName`         | UCD Bulk Mail Recharges                                       |                                  |
| `journalCategoryName`       | UCD Recharge                                                  |                                  |
| `journalName`               | Mail Sorting Recharges yyyy-MM-dd to yyyy-MM-dd               | Use start and end date           |
| `journalDescription`        | (unset)                                                       |                                  |
| `journalReference`          | Mail Sorting Recharges yyyy-MM-dd to yyyy-MM-dd               |                                  |
| `accountingDate`            | (today)                                                       |                                  |
| `accountingPeriodName`      | (unset)                                                       |                                  |
| **Line Fields**             |                                                               |                                  |
| `debitAmount`               | mail_stop_charge                                              |                                  |
| `creditAmount`              |                                                               |                                  |
| `externalSystemIdentifier`  | ${source}_yyyy-MM-dd                                          |                                  |
| `externalSystemReference`   |                                                               |                                  |
| `ppmComment`                |                                                               |                                  |
| **GL Segment Fields**       |                                                               |                                  |
| `entity`                    | segment_string                                                |                                  |
| `fund`                      | segment_string                                                |                                  |
| `department`                | segment_string                                                |                                  |
| `account`                   | 770006 (ignore value in segment string if present)            |                                  |
| `purpose`                   | segment_string                                                |                                  |
| `glProject`                 | segment_string                                                |                                  |
| `program`                   | segment_string                                                |                                  |
| `activity`                  | segment_string                                                |                                  |
| `interEntity`               | 0000                                                          |                                  |
| `flex1`                     | 000000                                                        |                                  |
| `flex2`                     | 000000                                                        |                                  |
| **PPM Segment Fields**      |                                                               |                                  |
| `ppmProject`                | segment_string                                                |                                  |
| `task`                      | segment_string                                                |                                  |
| `organization`              | segment_string                                                |                                  |
| `expenditureType`           | 770006 (ignore value in segment string if present)            |                                  |
| `award`                     | segment_string (or blank)                                     |                                  |
| `fundingSource`             | segment_string (or blank)                                     |                                  |
| **Internal Control Fields** |                                                               |                                  |
| `lineType`                  | based on segment_string                                       |                                  |
| **GLIDe Fields**            |                                                               |                                  |
| `lineDescription`           | account_name                                                  |                                  |
| `journalLineNumber`         | row number in journal                                         | ROW_NUMBER() OVER ()             |
| `transactionDate`           | (last day of month)                                           |                                  |
| `udfNumeric1`               | 1                                                             |                                  |
| `udfNumeric2`               | mail_stop_charge                                              |                                  |
| `udfNumeric3`               |                                                               |                                  |
| `udfDate1`                  | (last day of month)                                           |                                  |
| `udfDate2`                  |                                                               |                                  |
| `udfString1`                | Month                                                         |                                  |
| `udfString2`                | Mail Sort Fee                                                 |                                  |
| `udfString3`                |                                                               |                                  |
| `udfString4`                |                                                               |                                  |
| `udfString5`                | segment_string                                                | Original segment string from MCM |

#### Pass Through Expense Offset

| GL-PPM Field                | MCM Query Field                                               | Notes                  |
| --------------------------- | ------------------------------------------------------------- | ---------------------- |
| **Request Header Fields**   |                                                               |                        |
| `consumerId`                | UCD Bulk Mail Recharges                                       |                        |
| `boundaryApplicationName`   | Mail Services MCM                                             |                        |
| `consumerReferenceId`       | MS_CAMPUS_yyyyMMdd                                            | If campus data extract |
|                             | MS_UCDH_yyyyMMdd                                              | If UCDH data extract   |
| `consumerTrackingId`        | MS_CAMPUS_yyyyMMddHHmmss                                      | If campus data extract |
|                             | MS_UCDH_yyyyMMddHHmmss                                        | If UCDH data extract   |
| `consumerNotes`             | (unset)                                                       |                        |
| `requestSourceType`         | sftp                                                          |                        |
| `requestSourceId`           | journal.UCD_Bulk_Mail_Recharges.CAMPUS_MS_yyyyMMddHHmmss.json | If Campus Data         |
|                             | journal.UCD_Bulk_Mail_Recharges.UCDH_MS_yyyyMMddHHmmss.json   | If UCDH Data           |
| **Journal Header Fields**   |                                                               |                        |
| `journalSourceName`         | UCD Bulk Mail Recharges                                       |                        |
| `journalCategoryName`       | UCD Recharge                                                  |                        |
| `journalName`               | Mail Sorting Recharges yyyy-MM-dd to yyyy-MM-dd               | Use start and end date |
| `journalDescription`        | (unset)                                                       |                        |
| `journalReference`          | Mail Sorting Recharges yyyy-MM-dd to yyyy-MM-dd               |                        |
| `accountingDate`            | (today)                                                       |                        |
| `accountingPeriodName`      | (unset)                                                       |                        |
| **Line Fields**             |                                                               |                        |
| `debitAmount`               |                                                               |                        |
| `creditAmount`              | SUM(mail_stop_charge)                                         |                        |
| `externalSystemIdentifier`  | REVENUE                                                       |                        |
| `externalSystemReference`   |                                                               |                        |
| `ppmComment`                |                                                               |                        |
| **GL Segment Fields**       |                                                               |                        |
| `entity`                    | from `MCM Mail Sort Revenue Chartstring`                      |                        |
| `fund`                      | from `MCM Mail Sort Revenue Chartstring`                      |                        |
| `department`                | from `MCM Mail Sort Revenue Chartstring`                      |                        |
| `account`                   | from `MCM Mail Sort Revenue Chartstring`                      |                        |
| `purpose`                   | from `MCM Mail Sort Revenue Chartstring`                      |                        |
| `glProject`                 | from `MCM Mail Sort Revenue Chartstring`                      |                        |
| `program`                   | from `MCM Mail Sort Revenue Chartstring`                      |                        |
| `activity`                  | from `MCM Mail Sort Revenue Chartstring`                      |                        |
| `interEntity`               | 0000                                                          |                        |
| `flex1`                     | 000000                                                        |                        |
| `flex2`                     | 000000                                                        |                        |
| **PPM Segment Fields**      |                                                               |                        |
| `ppmProject`                |                                                               |                        |
| `task`                      |                                                               |                        |
| `organization`              |                                                               |                        |
| `expenditureType`           |                                                               |                        |
| `award`                     |                                                               |                        |
| `fundingSource`             |                                                               |                        |
| **Internal Control Fields** |                                                               |                        |
| `lineType`                  | `glSegments`                                                  |                        |
| **GLIDe Fields**            |                                                               |                        |
| `lineDescription`           | Mail Services Mail Sort Fee Revenue                           |                        |
| `journalLineNumber`         | row number in journal                                         | ROW_NUMBER() OVER ()   |
| `transactionDate`           | (last day of month)                                           |                        |
| `udfNumeric1`               |                                                               |                        |
| `udfNumeric2`               |                                                               |                        |
| `udfNumeric3`               |                                                               |                        |
| `udfDate1`                  | (last day of month)                                           |                        |
| `udfDate2`                  |                                                               |                        |
| `udfString1`                |                                                               |                        |
| `udfString2`                | Mail Sort Fee Revenue                                         |                        |
| `udfString3`                |                                                               |                        |
| `udfString4`                |                                                               |                        |
| `udfString5`                |                                                               |                        |

