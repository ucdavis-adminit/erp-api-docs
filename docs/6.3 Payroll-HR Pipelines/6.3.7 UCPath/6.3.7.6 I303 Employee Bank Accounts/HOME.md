# 6.3.7.6 I303 Employee Bank Accounts

## Overview

UCPath issues I-303 files daily to UCD, which include changes to Employee Bank Accounts, for purposes of payment via ACH.

This pipeline accepts these files, parses them, and builds a new file for transmission to Concur.

This Concur file will be either 800 or 810 record type.

### File Contents from UCPath

These files will be "incremental" files, with only the records changed since the last export.

We will also need to support a manually run "full export" process, where we request that the full file (rather than incremental) gets sent over, and processed.

### Note About Sensitive Data

IMPORTANT NOTE: This file from UCPath contains extremely sensitive data, in the form of bank routing numbers and account numbers.

We will receive the file encrypted from S3, and will need to decrypt it before processing.

We will then re-encrypt the payload before we persist it back to S3.

## Input File Format

The incoming file from UCPath has the following format.

| Field # | Field Name       | Max Length | Req | Description                                                                          |
|:--------|:-----------------|-----------:|:---:|:-------------------------------------------------------------------------------------|
| 1       | BUSINESS_UNIT    |          5 |  X  | Business being processed                                                             |
| 2       | **EMPLID**       |          8 |  X  | Employee ID                                                                          |
| 3       | NAME             |         50 |  X  | Employee Name                                                                        |
| 4       | LAST_HIRE_DT     |         10 |  X  | Hire date from most recent active appointmentFormat MMDDYYYY                         |
| 5       | LAST_UPDATE_DATE |         10 |     | The date of the most recent direct deposit action based onemployee idFormat MMDDYYYY |
| 6       | PRENOTE_STATUS   |          1 |     | Current row based on employee id                                                     |
| 7       | EFFDT            |         10 |     | Current row based on employee idFormat MMDDYYYY                                      |
| 8       | **BANK_CD**      |         11 |     | Bank Routing Number                                                                  |
| 9       | **ACCOUNT_NUM**  |         17 |     | Bank Account Number                                                                  |
| 10      | **ACCOUNT_TYPE** |          1 |     | Checking 'C' or Savings 'S'                                                          |
| 11      | EMPL_STATUS      |          1 |  X  | Employee status from current active primary position row on PS_JOB                   |
| 12      | DEPT_ID          |         10 |  X  | Department from current active primary position row on PS_JOB                        |
| 13      | ADDRESS1         |         55 |  X  | Address1 from Location based upon an employee’s primary job department               |
| 14      | ADDRESS2         |         55 |  X  | Address2 from Location based upon an employee’s primary job department               |
| 15      | CITY             |         30 |  X  | City from Location based upon an employee’s primary job department                   |
| 16      | STATE            |          6 |  X  | State from Location based upon an employee’s primary job department                  |
| 17      | POSTAL           |         12 |  X  | POSTAL from Location based upon an employee’s primary job department                 |

## Output File Format

We are unsure if we are going to be sending 800 or 810 records, so we will document both here.

Also, a 100 record needs to be first on the file, so that is also documented.

### File Characteristics

The file is a delimited type file, with the following characteristics:

* UTF8
* Comma or Pipe Delimited
* CRLF for record delimiter
* Enclosing Character: To "escape" a reserved character, such as a slash, use a quotation mark, for example: "/"

### File Name

Concur spec says:

```The import file name should be of the format "jobtype_entitycode". The employee job type for a employee import data file is "employee." If an entity has the code t00082678yhu, then the file name for a employee import data file would be "employee_t0000123abcd" to which is appended the date and timestamp as “YYYYMMDDHHMMSS.”```

Use entity code: `t00082678yhu`

Filename will look like: `employee_t00082678yhu_YYYYMMDDHHMMSS.txt`

### 100 Record

This must be the first line of the file.

`100,0,SSO,UPDATE,EN,N,N`

### 800 Record

| Field # | Field Name         | Max Length | Req | Description                                           |
|:--------|:-------------------|-----------:|:---:|:------------------------------------------------------|
| 1       | TRX TYPE           |          3 |  X  | Always:  800                                          |
| 2       | Employee ID        |         48 |  X  | UCPath EmployeeID                                     |
| 3       | Unused             |          0 |     | Leave empty                                           |
| 4       | Unused             |          0 |     | Leave empty                                           |
| 5       | Bank Acct Nbr      |         20 |  X  | Employee bank account number                          |
| 6       | Bank Routing Nbr   |          9 |  X  | Employee bank routing number                          |
| 7       | Bank Acct Type     |          2 |  X  | `CH` for Checking, `SA` for Savings                   |
| 8       | Bank Currency Code |          3 |  X  | Use: `USD`                                            |
| 9       | Is Active?         |          1 |  X  | `Y` or `N` - Use `N` if bank account is being removed |

### 810 Record

NOTE: The values and descriptions below are for US banks only.

| Field # | Field Name            | Max Length | Req | Description                                           |
|:--------|:----------------------|-----------:|:---:|:------------------------------------------------------|
| 1       | TRX TYPE              |          3 |  X  | Always: `810`                                         |
| 2       | Employee ID           |         48 |  X  | UCPath EmployeeID                                     |
| 3       | Bank Country          |          2 |  X  | Always: `US`                                          |
| 4       | Bank ID Nbr (Routing) |          9 |  X  | Employee bank routing number                          |
| 5       | IBAN Nbr (Account)    |          9 |  X  | Employee bank account number                          |
| 6       | Branch Name           |         48 |     | Leave blank                                           |
| 7       | Branch Location       |         30 |     | Leave blank                                           |
| 8       | Bank Acct Type        |          2 |  X  | `CH` for Checking, `SA` for Savings                   |
| 9       | Bank Currency Code    |          3 |  X  | Use: `USD`                                            |
| 10      | Name on Bank Acct     |         48 |     | Leave blank                                           |
| 11      | Address Line 1        |         48 |     | Leave Blank                                           |
| 12      | Address Line 2        |         48 |     | Leave Blank                                           |
| 13      | City                  |         24 |     | Leave Blank                                           |
| 14      | Region                |         24 |     | Leave Blank                                           |
| 15      | Postal Code           |         20 |     | Leave Blank                                           |
| 16      | Is Active?            |          1 |  X  | `Y` or `N` - Use `N` if bank account is being removed |

## Validations in NiFi

We will be doing the following validations per-record in NiFi:

1. EmplID is present
2. Emp Name is present
3. Account Type is present and within expected values (C or S)
4. Routing Number is present and <= 9 digits numeric
5. Account Number is present and <= 20 digits numeric
6. PreNote value is C

## NiFi Pipeline

### Main Daily Incremental Processing Pipeline

The following is the rough design for the NiFi pipeline.

1. Read I-303 file from UCPath (ConsumeKafka_2.6)
2. Decrypt File (EncryptContent)
3. Apply Schema Name & Defaults (UpdateAttribute)
4. Validate File against Schema (ValidateRecord)
5. Convert from CSV to JSON (ConvertRecord)
6. Validate JSON against Schema (ValidateRecord)
7. Add Validation Defaults (JoltTransformRecord)
8. Store Original Record Count (UpdateAttribute)
9. Validate Records (ScriptedTransformRecord)
10. Filter Out Invalid Records (QueryRecord)
   1. Invalid Records Generate (email?) report??? (TBD)
   2. Invalid Records go to Failed Validation sink to store in pipeline db table
11. Remove Temporary Fields (ConvertRecord)
12. Convert to Concur 810 Format (QueryRecord)
13. Set Concur Schema (UpdateAttribute)
14. Validate Schema (ValidateRecord)
15. Encrypt payload (EncryptContent)
16. Set Attributes and Kafka Topic (UpdateAttribute)
17. Publish to S3 (PutS3Object)

### Error Reporting

*NOTE: This is still TBD. For version 1 of this, we will only be doing #2*

Records which fail from the I303 file will be handled in two ways:

1. A report will be generated for all the records which were failed or skipped (wrong prenote) and emailed ???
2. Validation failures will be submitted to kafka topic for inclusion in `pipeline_job_status` table for file

### Full File Processing Pipeline

TBD:  Not sure if manual requested files will drop in S3 with a predictable folder/name?

But otherwise should be able to just pass it into the regular pipeline.

The entire pipeline should be operating in record-by-record mode for the most part, so should be safe for even large files, though havent confirmed that.

## Questions

1. What do we do with failed files or records?  Do we send an email out to someone?
   1. Collect and set aside for now
2. Is EmployeeID from UCPath the same value as that within Concur?
   1. Yes
3. Are we just forwarding every row from UCPath to Concur?  Or do we need to check against Concur data like we did in the KFS job?
   1. Yes, everything matching the same rule as we had before...something about the "remainder" account if someone has multiple.
4. Do we need to care about employee status like we did with the KFS job?
   1. I would say that if the employee status is in the file, and it's inactive, that we send through the delete record.
5. Are we only processing rows that have PRENOTE_STATUS of `C` like we did with the KFS job?
   1. yes
6. Should we limit to max number of records changed per job like we did in KFS?
   1. not this time, since it is now incremental
7. Will we receive the file encrypted or decrypted?  Is this pipeline responsible for doing whole file encryption/decryption?
   1. Assume the file in S3 will be encrypted

