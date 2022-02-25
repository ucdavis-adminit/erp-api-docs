# GL-PPM Combined Inbound

### GL Transaction Input Format

GL Transaction input is processed via the Oracle SQL*Loader file given below.  It is a standard CSV file with optional quotations.  Any columns not needed after the last field needed by our import can be left off and oracle will set them to null.  (At the moment, it looks like we may use up though `PERIOD_NAME` in this format below.)


#### Oracle FBDI Control File: GL_INTERFACE

Link to file: [gl_interface.ctl](./gl_interface.ctl)

```txt
load data
append into table GL_INTERFACE
fields terminated by "," optionally enclosed by '"' trailing nullcols
(
   LOAD_REQUEST_ID                 CONSTANT '#LOADREQUESTID#',
   STATUS,
   LEDGER_ID   "decode(:LEDGER_ID,null,(select ledger_id from gl_ledgers where name = :LEDGER_NAME),:LEDGER_ID)",
   ACCOUNTING_DATE                 "to_date(:ACCOUNTING_DATE, 'YYYY/MM/DD')",
   USER_JE_SOURCE_NAME,
   USER_JE_CATEGORY_NAME,
   CURRENCY_CODE,
   DATE_CREATED                    "to_date(:DATE_CREATED, 'YYYY/MM/DD')",
   ACTUAL_FLAG,
   SEGMENT1,
   SEGMENT2,
   SEGMENT3,
   SEGMENT4,
   SEGMENT5,
   SEGMENT6,
   SEGMENT7,
   SEGMENT8,
   SEGMENT9,
   SEGMENT10,
   SEGMENT11,
   SEGMENT12,
   SEGMENT13,
   SEGMENT14,
   SEGMENT15,
   SEGMENT16,
   SEGMENT17,
   SEGMENT18,
   SEGMENT19,
   SEGMENT20,
   SEGMENT21,
   SEGMENT22,
   SEGMENT23,
   SEGMENT24,
   SEGMENT25,
   SEGMENT26,
   SEGMENT27,
   SEGMENT28,
   SEGMENT29,
   SEGMENT30,
   ENTERED_DR                     "fun_load_interface_utils_pkg.replace_decimal_char(:ENTERED_DR)",
   ENTERED_CR                     "fun_load_interface_utils_pkg.replace_decimal_char(:ENTERED_CR)",
   ACCOUNTED_DR                   "fun_load_interface_utils_pkg.replace_decimal_char(:ACCOUNTED_DR)",
   ACCOUNTED_CR                   "fun_load_interface_utils_pkg.replace_decimal_char(:ACCOUNTED_CR)",
   REFERENCE1,
   REFERENCE2,
   REFERENCE3,
   REFERENCE4,
   REFERENCE5,
   REFERENCE6,
   REFERENCE7,
   REFERENCE8   "decode(:REFERENCE8,
    null,null,
    decode(
      (select ENABLE_AVERAGE_BALANCES_FLAG from gl_ledgers where ledger_id = :LEDGER_ID)
        ,'N', :REFERENCE8
        ,'Y', to_date(:REFERENCE8,'YYYY/MM/DD' ),
        decode(
          (select ENABLE_AVERAGE_BALANCES_FLAG from gl_ledgers where name = :LEDGER_NAME)
          ,'N',:REFERENCE8
          ,'Y', to_date(:REFERENCE8,'YYYY/MM/DD' ),
          :REFERENCE8)))" ,
   REFERENCE9,
   REFERENCE10,
   REFERENCE21,
   REFERENCE22,
   REFERENCE23,
   REFERENCE24,
   REFERENCE25,
   REFERENCE26,
   REFERENCE27,
   REFERENCE28,
   REFERENCE29,
   REFERENCE30,
   STAT_AMOUNT                    "fun_load_interface_utils_pkg.replace_decimal_char(:STAT_AMOUNT)",
   USER_CURRENCY_CONVERSION_TYPE,
   CURRENCY_CONVERSION_DATE       "decode(:CURRENCY_CONVERSION_DATE,null,null,to_date(:CURRENCY_CONVERSION_DATE, 'YYYY/MM/DD'))",
   CURRENCY_CONVERSION_RATE       "fun_load_interface_utils_pkg.replace_decimal_char(:CURRENCY_CONVERSION_RATE)",
   GROUP_ID,
   ATTRIBUTE_CATEGORY,
   ATTRIBUTE1,
   ATTRIBUTE2,
   ATTRIBUTE3,
   ATTRIBUTE4,
   ATTRIBUTE5,
   ATTRIBUTE6,
   ATTRIBUTE7,
   ATTRIBUTE8,
   ATTRIBUTE9,
   ATTRIBUTE10,
   ATTRIBUTE11,
   ATTRIBUTE12,
   ATTRIBUTE13,
   ATTRIBUTE14,
   ATTRIBUTE15,
   ATTRIBUTE16,
   ATTRIBUTE17,
   ATTRIBUTE18,
   ATTRIBUTE19,
   ATTRIBUTE20,
   ATTRIBUTE_CATEGORY3,
   AVERAGE_JOURNAL_FLAG,
   ORIGINATING_BAL_SEG_VALUE,
   LEDGER_NAME,
   ENCUMBRANCE_TYPE_ID,
   JGZZ_RECON_REF,
   PERIOD_NAME                     "decode(trim(replace(replace(:PERIOD_NAME,chr(13),' '),chr(10),' ')),'END',null,:PERIOD_NAME)",
   REFERENCE18,
   REFERENCE19,
   REFERENCE20,
   ATTRIBUTE_DATE1 "to_date(decode(trim(replace(replace(:ATTRIBUTE_DATE1,chr(13),' '),chr(10),' ')),'END',null,null,null,'$null$','4712/12/31',:ATTRIBUTE_DATE1),'YYYY/MM/DD')",
   ATTRIBUTE_DATE2 "to_date(decode(:ATTRIBUTE_DATE2,null,null,'$null$','4712/12/31',:ATTRIBUTE_DATE2),'YYYY/MM/DD')",
   ATTRIBUTE_DATE3 "to_date(decode(:ATTRIBUTE_DATE3,null,null,'$null$','4712/12/31',:ATTRIBUTE_DATE3),'YYYY/MM/DD')",
   ATTRIBUTE_DATE4 "to_date(decode(:ATTRIBUTE_DATE4,null,null,'$null$','4712/12/31',:ATTRIBUTE_DATE4),'YYYY/MM/DD')",
   ATTRIBUTE_DATE5 "to_date(decode(:ATTRIBUTE_DATE5,null,null,'$null$','4712/12/31',:ATTRIBUTE_DATE5),'YYYY/MM/DD')",
   ATTRIBUTE_DATE6 "to_date(decode(:ATTRIBUTE_DATE6,null,null,'$null$','4712/12/31',:ATTRIBUTE_DATE6),'YYYY/MM/DD')",
   ATTRIBUTE_DATE7 "to_date(decode(:ATTRIBUTE_DATE7,null,null,'$null$','4712/12/31',:ATTRIBUTE_DATE7),'YYYY/MM/DD')",
   ATTRIBUTE_DATE8 "to_date(decode(:ATTRIBUTE_DATE8,null,null,'$null$','4712/12/31',:ATTRIBUTE_DATE8),'YYYY/MM/DD')",
   ATTRIBUTE_DATE9 "to_date(decode(:ATTRIBUTE_DATE9,null,null,'$null$','4712/12/31',:ATTRIBUTE_DATE9),'YYYY/MM/DD')",
   ATTRIBUTE_DATE10 "to_date(decode(:ATTRIBUTE_DATE10,null,null,'$null$','4712/12/31',:ATTRIBUTE_DATE10),'YYYY/MM/DD')",
   ATTRIBUTE_NUMBER1 "decode(:ATTRIBUTE_NUMBER1,null,null,'$null$','-999999999999999999',:ATTRIBUTE_NUMBER1)",
   ATTRIBUTE_NUMBER2 "decode(:ATTRIBUTE_NUMBER2,null,null,'$null$','-999999999999999999',:ATTRIBUTE_NUMBER2)",
   ATTRIBUTE_NUMBER3 "decode(:ATTRIBUTE_NUMBER3,null,null,'$null$','-999999999999999999',:ATTRIBUTE_NUMBER3)",
   ATTRIBUTE_NUMBER4 "decode(:ATTRIBUTE_NUMBER4,null,null,'$null$','-999999999999999999',:ATTRIBUTE_NUMBER4)",
   ATTRIBUTE_NUMBER5 "decode(:ATTRIBUTE_NUMBER5,null,null,'$null$','-999999999999999999',:ATTRIBUTE_NUMBER5)",
   ATTRIBUTE_NUMBER6 "decode(:ATTRIBUTE_NUMBER6,null,null,'$null$','-999999999999999999',:ATTRIBUTE_NUMBER6)",
   ATTRIBUTE_NUMBER7 "decode(:ATTRIBUTE_NUMBER7,null,null,'$null$','-999999999999999999',:ATTRIBUTE_NUMBER7)",
   ATTRIBUTE_NUMBER8 "decode(:ATTRIBUTE_NUMBER8,null,null,'$null$','-999999999999999999',:ATTRIBUTE_NUMBER8)",
   ATTRIBUTE_NUMBER9 "decode(:ATTRIBUTE_NUMBER9,null,null,'$null$','-999999999999999999',:ATTRIBUTE_NUMBER9)",
   ATTRIBUTE_NUMBER10 "decode(:ATTRIBUTE_NUMBER10,null,null,'$null$','-999999999999999999',:ATTRIBUTE_NUMBER10)",
   CREATED_BY                      CONSTANT              '#CREATEDBY#',
   CREATION_DATE                   expression            "systimestamp",
   LAST_UPDATE_DATE                expression            "systimestamp",
   LAST_UPDATE_LOGIN               CONSTANT              '#LASTUPDATELOGIN#',
   LAST_UPDATED_BY                 CONSTANT              '#LASTUPDATEDBY#',
   OBJECT_VERSION_NUMBER           CONSTANT                1
 )
```

#### Table Structure: GL_INTERFACE

> Table structure loaded by the above control file, for use in reference of data type lengths.

| Column Name                   | Data Type | Length | Precision | Non-Null | Description                                                                                                                                                                                                                                                                    |
| ----------------------------- | --------- | ------ | --------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| STATUS                        | VARCHAR2  | 50     |           | Yes      | Journal Import status. Use: NEW.                                                                                                                                                                                                                                               |
| GL_INTERFACE_ID               | NUMBER    |        | 18        |          | Interface Identifier. Oracle internal use only. Populated by the journal import program.                                                                                                                                                                                       |
| CREATION_DATE                 | TIMESTAMP |        |           |          | Who column: date and time of the creation of the row.                                                                                                                                                                                                                          |
| LAST_UPDATE_DATE              | TIMESTAMP |        |           |          | Who column: date and time of the last update of the row.                                                                                                                                                                                                                       |
| LAST_UPDATE_LOGIN             | VARCHAR2  | 32     |           |          | Who column: session login associated to the user who last updated the row.                                                                                                                                                                                                     |
| LAST_UPDATED_BY               | VARCHAR2  | 64     |           |          | Who column: user who last updated the row.                                                                                                                                                                                                                                     |
| OBJECT_VERSION_NUMBER         | NUMBER    |        | 9         |          | Used to implement optimistic locking. Incremented every time the row is updated. Compared at the start and end of a transaction to detect whether another session has updated the row since it was queried.                                                                    |
| LEDGER_ID                     | NUMBER    |        | 18        |          | Ledger identifier. Use the Manage Primary Ledgers task to find valid values.                                                                                                                                                                                                   |
| JE_SOURCE_NAME                | VARCHAR2  | 25     |           |          | Oracle internal use only. Use column USER_JE_SOURCE_NAME to populate journal source.                                                                                                                                                                                           |
| JE_CATEGORY_NAME              | VARCHAR2  | 25     |           |          | Oracle internal use only. Use column USER_JE_CATEGORY_NAME to populate journal category.                                                                                                                                                                                       |
| ACCOUNTING_DATE               | DATE      |        |           | Yes      | Effective date of the journal entry. Used to assign the accounting period.                                                                                                                                                                                                     |
| CURRENCY_CODE                 | VARCHAR2  | 15     |           | Yes      | Entered currency of the transaction. Use the Manage Currencies task to find valid values. Use the three character ISO currency code. Example: US Dollars is USD.                                                                                                               |
| DATE_CREATED                  | DATE      |        |           | Yes      | Who column: date the row was created.                                                                                                                                                                                                                                          |
| CREATED_BY                    | VARCHAR2  | 64     |           |          | Who column: user who created the row.                                                                                                                                                                                                                                          |
| ACTUAL_FLAG                   | VARCHAR2  | 1      |           | Yes      | Balance type of the journal. Use: A. Meaning: Actual.                                                                                                                                                                                                                          |
| REQUEST_ID                    | NUMBER    |        | 18        |          | Enterprise Service Scheduler: request ID of the job that created or last updated the row.                                                                                                                                                                                      |
| ENCUMBRANCE_TYPE_ID           | NUMBER    |        |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| BUDGET_VERSION_ID             | NUMBER    |        |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| CURRENCY_CONVERSION_DATE      | DATE      |        |           |          | Date of exchange rate. Date format: YYYY/MM/DD. Required if CURRENCY_CONVERSION_TYPE is not User.                                                                                                                                                                              |
| CURRENCY_CONVERSION_TYPE      | VARCHAR2  | 30     |           |          | Currency conversion type. Use Manage Currency Conversion Types task to identify valid values. For Fusion ERP in the Cloud, use USER_CURRENCY_CONVERSION_TYPE instead.                                                                                                          |
| CURRENCY_CONVERSION_RATE      | NUMBER    |        |           |          | Foreign currency exchange rate. Mandatory if CURRENCY_CONVERSION_TYPE is User.                                                                                                                                                                                                 |
| SEGMENT1                      | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT2                      | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT3                      | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT4                      | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT5                      | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT6                      | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT7                      | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT8                      | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT9                      | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT10                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT11                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT12                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT13                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT14                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT15                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT16                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT17                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT18                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT19                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT20                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT21                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT22                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT23                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT24                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT25                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT26                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT27                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT28                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT29                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| SEGMENT30                     | VARCHAR2  | 25     |           |          | Segment of the chart of accounts. Only use if assigned to the chart of accounts of the ledger. Validation: must be a valid value for the chart of accounts.                                                                                                                    |
| ENTERED_DR                    | NUMBER    |        |           |          | Transaction debit amount in the entered currency.                                                                                                                                                                                                                              |
| ENTERED_CR                    | NUMBER    |        |           |          | Transaction credit amount in the entered currency.                                                                                                                                                                                                                             |
| ACCOUNTED_DR                  | NUMBER    |        |           |          | Journal debit amount in the ledger currency.                                                                                                                                                                                                                                   |
| ACCOUNTED_CR                  | NUMBER    |        |           |          | Journal credit amount in the ledger currency.                                                                                                                                                                                                                                  |
| TRANSACTION_DATE              | DATE      |        |           |          | Oracle internal use only. Date of transaction.                                                                                                                                                                                                                                 |
| REFERENCE1                    | VARCHAR2  | 100    |           |          | Reference column: batch name. Free text field. Not validated.                                                                                                                                                                                                                  |
| REFERENCE2                    | VARCHAR2  | 240    |           |          | Reference column: batch description. Free text field. Not validated.                                                                                                                                                                                                           |
| REFERENCE3                    | VARCHAR2  | 100    |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| REFERENCE4                    | VARCHAR2  | 100    |           |          | Reference column: journal entry name. Free text field. Not validated.                                                                                                                                                                                                          |
| REFERENCE5                    | VARCHAR2  | 240    |           |          | Reference column: journal entry description. Free text field. Not validated.                                                                                                                                                                                                   |
| REFERENCE6                    | VARCHAR2  | 100    |           |          | Reference column: journal entry reference. Free text field. Not validated.                                                                                                                                                                                                     |
| REFERENCE7                    | VARCHAR2  | 100    |           |          | Reference column: journal entry reversal flag. Valid values: Y, N.                                                                                                                                                                                                             |
| REFERENCE8                    | VARCHAR2  | 100    |           |          | Reference column: journal entry reversal period. Validation: mandatory if REFERENCE7, journal entry reversal flag, is Y. If average balance processing is enabled, enter effective date for reversal. This will be used to determine the GL period.                            |
| REFERENCE9                    | VARCHAR2  | 100    |           |          | Reference column: journal reversal method. Valid values: Y, N. Meanings: Y changes sign, N switches debits/credits.                                                                                                                                                            |
| REFERENCE10                   | VARCHAR2  | 240    |           |          | Reference column: journal entry line description. Free text field. Not validated.                                                                                                                                                                                              |
| REFERENCE11                   | VARCHAR2  | 240    |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| REFERENCE12                   | VARCHAR2  | 100    |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| REFERENCE13                   | VARCHAR2  | 100    |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| REFERENCE14                   | VARCHAR2  | 100    |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| REFERENCE15                   | VARCHAR2  | 100    |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| REFERENCE16                   | VARCHAR2  | 100    |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| REFERENCE17                   | VARCHAR2  | 100    |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| REFERENCE18                   | VARCHAR2  | 100    |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| REFERENCE19                   | VARCHAR2  | 100    |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| REFERENCE20                   | VARCHAR2  | 100    |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| REFERENCE21                   | VARCHAR2  | 240    |           |          | Reference column: journal line. Free text field. Not validated.                                                                                                                                                                                                                |
| REFERENCE22                   | VARCHAR2  | 240    |           |          | Reference column: journal line. Free text field. Not validated.                                                                                                                                                                                                                |
| REFERENCE23                   | VARCHAR2  | 240    |           |          | Reference column: journal line. Free text field. Not validated.                                                                                                                                                                                                                |
| REFERENCE24                   | VARCHAR2  | 240    |           |          | Reference column: journal line. Free text field. Not validated.                                                                                                                                                                                                                |
| REFERENCE25                   | VARCHAR2  | 240    |           |          | Reference column: journal line. Free text field. Not validated.                                                                                                                                                                                                                |
| REFERENCE26                   | VARCHAR2  | 240    |           |          | Reference column: journal line. Free text field. Not validated.                                                                                                                                                                                                                |
| REFERENCE27                   | VARCHAR2  | 240    |           |          | Reference column: journal line. Free text field. Not validated.                                                                                                                                                                                                                |
| REFERENCE28                   | VARCHAR2  | 240    |           |          | Reference column: journal line. Free text field. Not validated.                                                                                                                                                                                                                |
| REFERENCE29                   | VARCHAR2  | 240    |           |          | Reference column: journal line. Free text field. Not validated.                                                                                                                                                                                                                |
| REFERENCE30                   | VARCHAR2  | 240    |           |          | Reference column: journal line. Free text field. Not validated.                                                                                                                                                                                                                |
| INTERFACE_RUN_ID              | NUMBER    |        | 18        |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| JE_BATCH_ID                   | NUMBER    |        | 18        |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| PERIOD_NAME                   | VARCHAR2  | 15     |           |          | Period name. Use the Manage Accounting Calendars task to identify valid values.                                                                                                                                                                                                |
| JE_HEADER_ID                  | NUMBER    |        | 18        |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| JE_LINE_NUM                   | NUMBER    |        | 18        |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| CHART_OF_ACCOUNTS_ID          | NUMBER    |        | 18        |          | Oracle internal use only. Chart of accounts identifier.                                                                                                                                                                                                                        |
| FUNCTIONAL_CURRENCY_CODE      | VARCHAR2  | 15     |           |          | Oracle internal use only. Ledger base currency.                                                                                                                                                                                                                                |
| CODE_COMBINATION_ID           | NUMBER    |        | 18        |          | Use the Manage Account Combinations task, column Account ID, to find valid values. Can be used instead of populating the SEGMENT columns individually. If CODE_COMBINATION_ID and the columns beginning with SEGMENT are populated, the SEGMENT column values take precedence. |
| DATE_CREATED_IN_GL            | DATE      |        |           |          | Oracle internal use only. Date journal import created batch. Populated by the journal import program.                                                                                                                                                                          |
| WARNING_CODE                  | VARCHAR2  | 4      |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| STATUS_DESCRIPTION            | VARCHAR2  | 240    |           |          | Oracle internal use only. Journal import status description. Populated by the journal import program.                                                                                                                                                                          |
| STAT_AMOUNT                   | NUMBER    |        |           |          | Statistical amount.                                                                                                                                                                                                                                                            |
| USER_JE_CATEGORY_NAME         | VARCHAR2  | 25     |           | Yes      | Journal entry category. Use the Manage Journal Categories task to find valid values.                                                                                                                                                                                           |
| USER_JE_SOURCE_NAME           | VARCHAR2  | 25     |           | Yes      | Journal entry source user defined name. Use the Manage Journal Sources page to find valid values.                                                                                                                                                                              |
| USER_CURRENCY_CONVERSION_TYPE | VARCHAR2  | 30     |           |          | Type of exchange rate. Use the Manage Conversion Rate Types task to find valid values. Translated value for CONVERSION_TYPE. Use either CURRENCY_CONVERSION_TYPE or USER_CURRENCY_CONVERSION_TYPE, but not both.                                                               |
| GROUP_ID                      | NUMBER    |        | 18        |          | Groups lines for journals. Use positive integers. Lines with the same GROUP_ID are grouped into the same journal.                                                                                                                                                              |
| SUBLEDGER_DOC_SEQUENCE_ID     | NUMBER    |        |           |          | Oracle internal use only. Sequential numbering sequence defining column. Populated by journal import program when journal is sequenced.                                                                                                                                        |
| SUBLEDGER_DOC_SEQUENCE_VALUE  | NUMBER    |        |           |          | Oracle internal use only. Sequential numbering sequence value. Populated by journal import program when journal is sequenced.                                                                                                                                                  |
| ATTRIBUTE1                    | VARCHAR2  | 150    |           |          | Segment value for Journals Lines descriptive flexfield.                                                                                                                                                                                                                        |
| ATTRIBUTE2                    | VARCHAR2  | 150    |           |          | Segment value for Journals Lines descriptive flexfield.                                                                                                                                                                                                                        |
| ATTRIBUTE3                    | VARCHAR2  | 150    |           |          | Segment value for Journals Lines descriptive flexfield.                                                                                                                                                                                                                        |
| ATTRIBUTE4                    | VARCHAR2  | 150    |           |          | Segment value for Journals Lines descriptive flexfield.                                                                                                                                                                                                                        |
| ATTRIBUTE5                    | VARCHAR2  | 150    |           |          | Segment value for Journals Lines descriptive flexfield.                                                                                                                                                                                                                        |
| ATTRIBUTE6                    | VARCHAR2  | 150    |           |          | Segment value for Journals Lines descriptive flexfield.                                                                                                                                                                                                                        |
| ATTRIBUTE7                    | VARCHAR2  | 150    |           |          | Segment value for Journals Lines descriptive flexfield.                                                                                                                                                                                                                        |
| ATTRIBUTE8                    | VARCHAR2  | 150    |           |          | Segment value for Journals Lines descriptive flexfield.                                                                                                                                                                                                                        |
| ATTRIBUTE9                    | VARCHAR2  | 150    |           |          | Segment value for Journals Lines descriptive flexfield.                                                                                                                                                                                                                        |
| ATTRIBUTE10                   | VARCHAR2  | 150    |           |          | Segment value for Journals Lines descriptive flexfield.                                                                                                                                                                                                                        |
| ATTRIBUTE11                   | VARCHAR2  | 150    |           |          | Segment value for Journals Captured Information descriptive flexfield.                                                                                                                                                                                                         |
| ATTRIBUTE12                   | VARCHAR2  | 150    |           |          | Segment value for Journals Captured Information descriptive flexfield.                                                                                                                                                                                                         |
| ATTRIBUTE13                   | VARCHAR2  | 150    |           |          | Segment value for Journals Captured Information descriptive flexfield.                                                                                                                                                                                                         |
| ATTRIBUTE14                   | VARCHAR2  | 150    |           |          | Segment value for Journals Captured Information descriptive flexfield.                                                                                                                                                                                                         |
| ATTRIBUTE15                   | VARCHAR2  | 150    |           |          | Segment value for Journals Captured Information descriptive flexfield.                                                                                                                                                                                                         |
| ATTRIBUTE16                   | VARCHAR2  | 150    |           |          | Segment value for Journals Captured Information descriptive flexfield.                                                                                                                                                                                                         |
| ATTRIBUTE17                   | VARCHAR2  | 150    |           |          | Segment value for Journals Captured Information descriptive flexfield.                                                                                                                                                                                                         |
| ATTRIBUTE18                   | VARCHAR2  | 150    |           |          | Segment value for Journals Captured Information descriptive flexfield.                                                                                                                                                                                                         |
| ATTRIBUTE19                   | VARCHAR2  | 150    |           |          | Segment value for Journals Captured Information descriptive flexfield.                                                                                                                                                                                                         |
| ATTRIBUTE20                   | VARCHAR2  | 150    |           |          | Segment value for Journals Captured Information descriptive flexfield.                                                                                                                                                                                                         |
| ATTRIBUTE_CATEGORY            | VARCHAR2  | 150    |           |          | Context code for Journals Lines descriptive flexfield. Use the Manage General Ledger Descriptive Flexfields task to identify valid values. Use ATTRIBUTE1 to ATTRIBUTE10 for the segment values.                                                                               |
| ATTRIBUTE_CATEGORY2           | VARCHAR2  | 150    |           |          | Context code for Journals Captured Information descriptive flexfield. Use the Manage General Ledger Descriptive Flexfields task to identify valid values. Use ATTRIBUTE11 to ATTRIBUTE20 for the segment values.                                                               |
| INVOICE_DATE                  | DATE      |        |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| TAX_CODE                      | VARCHAR2  | 15     |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| INVOICE_IDENTIFIER            | VARCHAR2  | 20     |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| INVOICE_AMOUNT                | NUMBER    |        |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| ATTRIBUTE_CATEGORY3           | VARCHAR2  | 150    |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| USSGL_TRANSACTION_CODE        | VARCHAR2  | 30     |           |          | Government transaction code. Oracle internal use only. Only applicable if Oracle Federal Financials is used.                                                                                                                                                                   |
| DESCR_FLEX_ERROR_MESSAGE      | VARCHAR2  | 240    |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| JGZZ_RECON_REF                | VARCHAR2  | 240    |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| AVERAGE_JOURNAL_FLAG          | VARCHAR2  | 1      |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| GL_SL_LINK_ID                 | NUMBER    |        |           |          | Link to associated subledger data. Oracle internal use only.                                                                                                                                                                                                                   |
| GL_SL_LINK_TABLE              | VARCHAR2  | 30     |           |          | Table containing associated subledger data. Oracle internal use only.                                                                                                                                                                                                          |
| ORIGINATING_BAL_SEG_VALUE     | VARCHAR2  | 25     |           |          | Originating balancing segment value for intercompany transaction. Overrides default balancing segment value. Should be a valid value for value set used for intercompany.                                                                                                      |
| REFERENCE_DATE                | DATE      |        |           |          | Reference Date for sequencing to meet statutory requirements in Italy. Date format: YYYY/MM/DD.                                                                                                                                                                                |
| SET_OF_BOOKS_ID               | NUMBER    |        | 18        |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| BALANCING_SEGMENT_VALUE       | VARCHAR2  | 25     |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| MANAGEMENT_SEGMENT_VALUE      | VARCHAR2  | 25     |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| FUNDS_RESERVED_FLAG           | VARCHAR2  | 1      |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| CODE_COMBINATION_ID_INTERIM   | NUMBER    |        | 18        |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| CURRENCY_CONV_DATE_INTER      | DATE      |        |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| CURRENCY_CONV_TYPE_INTER      | VARCHAR2  | 30     |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| CURRENCY_CONV_RATE_INTER      | NUMBER    |        | 18        |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| LOAD_REQUEST_ID               | NUMBER    |        | 18        |          | Enterprise Service Scheduler: request ID of the interface load job that created the row.                                                                                                                                                                                       |
| LEGAL_ENTITY_ID               | NUMBER    |        | 18        |          | Legal Entity Identifier. Foreign key to XLE_ENTITY_PROFILES                                                                                                                                                                                                                    |
| LEGAL_ENTITY_IDENTIFIER       | VARCHAR2  | 30     |           |          | Unique number used to identify a legal entity. Foreign key to XLE_ENTITY_PROFILES.LEGAL_ENTITY_IDENTIFIER.                                                                                                                                                                     |
| LEDGER_NAME                   | VARCHAR2  | 30     |           |          | Ledger name for the journal to be imported. Used in file based data import.                                                                                                                                                                                                    |
| ATTRIBUTE_DATE1               | DATE      |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_DATE2               | DATE      |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_DATE3               | DATE      |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_DATE4               | DATE      |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_DATE5               | DATE      |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_DATE6               | DATE      |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_DATE7               | DATE      |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_DATE8               | DATE      |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_DATE9               | DATE      |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_DATE10              | DATE      |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_NUMBER1             | NUMBER    |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_NUMBER2             | NUMBER    |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_NUMBER3             | NUMBER    |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_NUMBER4             | NUMBER    |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_NUMBER5             | NUMBER    |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_NUMBER6             | NUMBER    |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_NUMBER7             | NUMBER    |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_NUMBER8             | NUMBER    |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_NUMBER9             | NUMBER    |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| ATTRIBUTE_NUMBER10            | NUMBER    |        |           |          | Descriptive Flexfield: segment of the user descriptive flexfield.                                                                                                                                                                                                              |
| GLOBAL_ATTRIBUTE_CATEGORY     | VARCHAR2  | 30     |           |          | Global Descriptive Flexfield: structure definition of the global descriptive flexfield.                                                                                                                                                                                        |
| GLOBAL_ATTRIBUTE_DATE1        | DATE      |        |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE_DATE2        | DATE      |        |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE_DATE3        | DATE      |        |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE_DATE4        | DATE      |        |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE_DATE5        | DATE      |        |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE_NUMBER1      | NUMBER    |        |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE_NUMBER2      | NUMBER    |        |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE_NUMBER3      | NUMBER    |        |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE_NUMBER4      | NUMBER    |        |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE_NUMBER5      | NUMBER    |        |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE1             | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE2             | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE3             | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE4             | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE5             | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE6             | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE7             | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE8             | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE9             | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE10            | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE11            | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE12            | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE13            | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE14            | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE15            | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE16            | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE17            | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE18            | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE19            | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| GLOBAL_ATTRIBUTE20            | VARCHAR2  | 150    |           |          | Global Descriptive Flexfield: segment of the global descriptive flexfield.                                                                                                                                                                                                     |
| PARTITION_GROUP_CODE          | VARCHAR2  | 15     |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |
| PERIOD_NAME_INTERIM           | VARCHAR2  | 15     |           |          | Oracle internal use only.                                                                                                                                                                                                                                                      |

#### AVRO Schema: GL_INTERFACE

> This is the AVRO schema used to shape the records for export in the necessary format for Oracle.

Link to file: [gl_interface.avsc](./gl_interface.avsc)

```json
{
  "type": "record",
  "namespace": "edu.ucdavis.adminit",
  "name": "GL_INTERFACE",
  "fields": [
    {
      "name": "STATUS",
      "type": "string",
      "default": "NEW"
    },
    {
      "name": "LEDGER_ID",
      "type": "null"
    },
    {
      "name": "ACCOUNTING_DATE",
      "type": [
        "null",
        "string"
      ]
    },
    {
      "name": "USER_JE_SOURCE_NAME",
      "type": "string"
    },
    {
      "name": "USER_JE_CATEGORY_NAME",
      "type": "string"
    },
    {
      "name": "CURRENCY_CODE",
      "type": "string",
      "default": "USD"
    },
    {
      "name": "DATE_CREATED",
      "type": "string"
    },
    {
      "name": "ACTUAL_FLAG",
      "type": "string",
      "default": "A"
    },
    {
      "name": "SEGMENT1",
      "type": "string",
      "default": "0000",
      "doc": "Entity"
    },
    {
      "name": "SEGMENT2",
      "type": "string",
      "default": "00000",
      "doc": "Fund"
    },
    {
      "name": "SEGMENT3",
      "type": "string",
      "default": "0000000",
      "doc": "Department"
    },
    {
      "name": "SEGMENT4",
      "type": "string",
      "default": "000000",
      "doc": "Account"
    },
    {
      "name": "SEGMENT5",
      "type": "string",
      "default": "00",
      "doc": "Purpose"
    },
    {
      "name": "SEGMENT6",
      "type": "string",
      "default": "000",
      "doc": "Program"
    },
    {
      "name": "SEGMENT7",
      "type": "string",
      "default": "0000000000",
      "doc": "Project"
    },
    {
      "name": "SEGMENT8",
      "type": "string",
      "default": "000000",
      "doc": "Activity"
    },
    {
      "name": "SEGMENT9",
      "type": "string",
      "default": "0000",
      "doc": "InterEntity"
    },
    {
      "name": "SEGMENT10",
      "type": "string",
      "default": "000000",
      "doc": "Flex1"
    },
    {
      "name": "SEGMENT11",
      "type": "string",
      "default": "000000",
      "doc": "Flex2"
    },
    {
      "name": "SEGMENT12",
      "type": "null"
    },
    {
      "name": "SEGMENT13",
      "type": "null"
    },
    {
      "name": "SEGMENT14",
      "type": "null"
    },
    {
      "name": "SEGMENT15",
      "type": "null"
    },
    {
      "name": "SEGMENT16",
      "type": "null"
    },
    {
      "name": "SEGMENT17",
      "type": "null"
    },
    {
      "name": "SEGMENT18",
      "type": "null"
    },
    {
      "name": "SEGMENT19",
      "type": "null"
    },
    {
      "name": "SEGMENT20",
      "type": "null"
    },
    {
      "name": "SEGMENT21",
      "type": "null"
    },
    {
      "name": "SEGMENT22",
      "type": "null"
    },
    {
      "name": "SEGMENT23",
      "type": "null"
    },
    {
      "name": "SEGMENT24",
      "type": "null"
    },
    {
      "name": "SEGMENT25",
      "type": "null"
    },
    {
      "name": "SEGMENT26",
      "type": "null"
    },
    {
      "name": "SEGMENT27",
      "type": "null"
    },
    {
      "name": "SEGMENT28",
      "type": "null"
    },
    {
      "name": "SEGMENT29",
      "type": "null"
    },
    {
      "name": "SEGMENT30",
      "type": "null"
    },
    {
      "name": "ENTERED_DR",
      "type": [
        "null",
        "double"
      ]
    },
    {
      "name": "ENTERED_CR",
      "type": [
        "null",
        "double"
      ]
    },
    {
      "name": "ACCOUNTED_DR",
      "type": "null"
    },
    {
      "name": "ACCOUNTED_CR",
      "type": "null"
    },
    {
      "name": "REFERENCE1",
      "type": "null"
    },
    {
      "name": "REFERENCE2",
      "type": "null"
    },
    {
      "name": "REFERENCE3",
      "type": "null"
    },
    {
      "name": "REFERENCE4",
      "type": "string"
    },
    {
      "name": "REFERENCE5",
      "type": [
        "null",
        "string"
      ]
    },
    {
      "name": "REFERENCE6",
      "type": "string"
    },
    {
      "name": "REFERENCE7",
      "type": "null"
    },
    {
      "name": "REFERENCE8",
      "type": "null"
    },
    {
      "name": "REFERENCE9",
      "type": "null"
    },
    {
      "name": "REFERENCE10",
      "type": "string"
    },
    {
      "name": "REFERENCE21",
      "type": "null"
    },
    {
      "name": "REFERENCE22",
      "type": "null"
    },
    {
      "name": "REFERENCE23",
      "type": "null"
    },
    {
      "name": "REFERENCE24",
      "type": "null"
    },
    {
      "name": "REFERENCE25",
      "type": "null"
    },
    {
      "name": "REFERENCE26",
      "type": "null"
    },
    {
      "name": "REFERENCE27",
      "type": "null"
    },
    {
      "name": "REFERENCE28",
      "type": "null"
    },
    {
      "name": "REFERENCE29",
      "type": "null"
    },
    {
      "name": "REFERENCE30",
      "type": "null"
    },
    {
      "name": "STAT_AMOUNT",
      "type": "null"
    },
    {
      "name": "USER_CURRENCY_CONVERSION_TYPE",
      "type": "null"
    },
    {
      "name": "CURRENCY_CONVERSION_DATE",
      "type": "null"
    },
    {
      "name": "CURRENCY_CONVERSION_RATE",
      "type": "null"
    },
    {
      "name": "GROUP_ID",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE_CATEGORY",
      "type": "string"
    },
    {
      "name": "ATTRIBUTE1",
      "type": "string"
    },
    {
      "name": "ATTRIBUTE2",
      "type": [
        "null",
        "string"
      ]
    },
    {
      "name": "ATTRIBUTE3",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE4",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE5",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE6",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE7",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE8",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE9",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE10",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE11",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE12",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE13",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE14",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE15",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE16",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE17",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE18",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE19",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE20",
      "type": "null"
    },
    {
      "name": "ATTRIBUTE_CATEGORY3",
      "type": "null"
    },
    {
      "name": "AVERAGE_JOURNAL_FLAG",
      "type": "null"
    },
    {
      "name": "ORIGINATING_BAL_SEG_VALUE",
      "type": "null"
    },
    {
      "name": "LEDGER_NAME",
      "type": "string",
      "default": "UCD Primary Ledger"
    },
    {
      "name": "ENCUMBRANCE_TYPE_ID",
      "type": "null"
    },
    {
      "name": "JGZZ_RECON_REF",
      "type": "null"
    },
    {
      "name": "PERIOD_NAME",
      "type": [
        "null",
        "string"
      ]
    }
  ]
}
```
