# USBank Travel Card Default Expensing

Below is the design document from the implementation of this job for KFS.  Here are links to files from the current implementation to use as reference material when recreating this logic in NiFi and Groovy Scripted Processors.

* Job Definition: [ChargeUsBankExpensesToDefaultAccountsJob.xml](6%20Data%20Pipelines/6.3%20Custom%20Pipelines/6.3.1%20Concur/6.3.1.C%20KFS%20Implementation%20References/USBank%20Travel%20Card%20Default%20Expensing/ChargeUsBankExpensesToDefaultAccountsJob.xml ':ignore')
* Data Type Enum Classes:
  * [UsBankRecordType.java](6%20Data%20Pipelines/6.3%20Custom%20Pipelines/6.3.1%20Concur/6.3.1.C%20KFS%20Implementation%20References/USBank%20Travel%20Card%20Default%20Expensing/UsBankRecordType.java ':ignore')
  * [UsBankRowType.java](6%20Data%20Pipelines/6.3%20Custom%20Pipelines/6.3.1%20Concur/6.3.1.C%20KFS%20Implementation%20References/USBank%20Travel%20Card%20Default%20Expensing/UsBankRowType.java ':ignore')
  * [UsBankTransactionTypeCode.java](6%20Data%20Pipelines/6.3%20Custom%20Pipelines/6.3.1%20Concur/6.3.1.C%20KFS%20Implementation%20References/USBank%20Travel%20Card%20Default%20Expensing/UsBankTransactionTypeCode.java ':ignore')
* Record Processing Class: [UsBankRecordProcessor.java](6%20Data%20Pipelines/6.3%20Custom%20Pipelines/6.3.1%20Concur/6.3.1.C%20KFS%20Implementation%20References/USBank%20Travel%20Card%20Default%20Expensing/UsBankRecordProcessor.java ':ignore')
* Record to Journal Mapping Class: [UsBankRecordToGljvProcessor.java](6%20Data%20Pipelines/6.3%20Custom%20Pipelines/6.3.1%20Concur/6.3.1.C%20KFS%20Implementation%20References/USBank%20Travel%20Card%20Default%20Expensing/UsBankRecordToGljvProcessor.java ':ignore')


# US Bank Direct Debit File Processing

JIRA: <https://afs-dev.ucdavis.edu/jira/browse/CONCUR-511>

## Project Scope

> Provide a short description of the software being specified and its purpose, including relevant benefits, objectives, and goals.

UCD will be converting the existing corporate card model to a direct debit model where USBank will extract the funds when they want to from our bank account and then send us a file of what they just withdrew.  This file will be the previous day's posted transactions and will match what they withdrew from our bank account.  This allows them to get their money immediately instead of when the traveller reconciles the charge in Concur.  The file sent by USBank will have a summary of the charges which will allow us to credit the campus cash account (representing the removed funds) and debit the default account associated with each card.

When a traveller reconciles their trip expenses, the accounting entry used on the report will be used to transfer the funds from the default listed for the card to that given in the allocations.  This is identical to how we handle CTS expenses except for the source of the source account when we process reports from AggieTravel.  And the payment-to-the-bank side is almost identical to how we handle PCard and PMT+ payments to the bank.

The process for handling personal expenses is fundamentally different in this model.  Previously, UC would simply not pay the card, leaving the traveller responsible for paying the balance.  In the new model, US Bank debits UC for all charges which hit the corporate card, leaving the traveller owing UC for the personal expenses.  A new process will need to be set up for tracking personal expenses made on each card and to generate a receivable balance for repayment.

## Design Scope

This design covers the processing of a new file we will receive from US Bank.  This file contains all the expenses charged to corporate cards.  We will use the information to expense the charges to the default account for each card number.

## Project Dependencies and Assumptions

### Dependencies

1. The `AGGIETRAVEL%` schemas data has been imported into the AIT_INT database identical to how they have been loaded into FIS_DS.
2. Grants to the needed `AGGIETRAVEL` schema tables on AIT_INT.

### Assumptions

1. The chart-account value for each card will exist in the `CT_CREDIT_CARD_ACCOUNT.CLEARING_ACCOUNT_CODE` column of the concur data extracts.
2. The file will be placed into a sub-folder within the `base.receive.directory` which already exists on the server by Operations MFT processes.
3. The US Bank file will provide the data at a transactional level so that we can match against it when processing the reconciliation on the SAE.

## Deviations from Requirements

> Please list any significant differences between the stated requirements and the design below. This could be for system standards reasons, technical difficulty/maintainability/impossibility, etc...
> Please include your reason for the change.

## Technology Stack

> List out the tech stack for the application.
> E.g., Java / Spring Boot / Spring Batch
> OR: JavaScript / Node / Express / React

N/A : New batch job on existing infrastructure.

## Types of Changes

* [X] Java Code
* [ ] JavaScript Code (server)
* [ ] JavaScript Code (client)
* [X] Oracle Database Structure
* [X] Oracle Database Data
* [ ] MongoDB Configuration
* [X] MongoDB Data
* [ ] React Components
* [ ] REST API Endpoints

### Referenced Libraries

> If the application requires the addition of libraries which are not already part of the application or the starter project, please list them out here along with a note as to their purpose/use within the application.

## Data Model

> Provide a comprehensive listing of the logical data model for the project.

### New Data Objects

#### UsBankFileRecord

Application representation of a row of data from the US Bank feed file.

#### GLJVLine

In-memory representation of an GL entry used for creating the output journal files.

## Database Objects (if applicable)

> Provide an overview of the table structures being created/altered for the application.

### New MongoDB Collection: `usBankFileRecord`

| Field Name             | Data Type | Additional Information                                  |
| ---------------------- | --------- | ------------------------------------------------------- |
| employeeId             | String    |                                                         |
| cardNumLast4           | String    |                                                         |
| transactionId          | String    |                                                         |
| sequenceNumber         | int       |                                                         |
| employeeName           | String    | Pull from employee collection                           |
| cardholderName         | String    |                                                         |
| transactionAmount      | double    | Use billing amount since this is always in USD.         |
| postingDate            | Date      |                                                         |
| transactionDate        | Date      |                                                         |
| merchantName           | String    | Supplier name in file                                   |
| cardIssueDate          | Date      | Just for reference since we don't have the whole card # |
| transactionTypeCode    | String    | Type of transaction in case we need to filter some out  |
| transactionDescription | String    |                                                         |
| employeeDepartmentCode | String    | Home dept code per employee collection.                 |
| departmentChartAccount | String    | Account used for expensing this transaction.            |
| expenseReportEntryKeys | int[]     |                                                         |
| reconciledAmount       | double    |                                                         |
| personalAmount         | double    |                                                         |
| reconciled             | boolean   |                                                         |
| reconcileDate          | Date      |                                                         |
| syncInfo               | SyncInfo  |                                                         |

#### Notes

* the class should extend the common `UpdateAware` class.
* The record should contain the employee ID and last 4 digits of the card number.
* The record needs to include fields for the account information.
* The record must contain some sort of identifier which we can track back to when processing the SAE.
* That identifier field should be indexed.
* Use the employee ID, last 4, transaction ID, and sequence number as the `_id`

### Data

> List out any needed data loads which will be needed.  (whether the application code loads the data on first run or it will be something which a DBA will need to do)

No new loads - additional data needs listed under dependencies.

### Accounts and Permissions

> List out any new database accounts and the permissions they will need to make the application work.

SELECT Grants needed to views in the `AGGIETRAVEL` schema:

* `CT_CREDIT_CARD_ACCOUNT`
* `CT_EMPLOYEE`
* `CT_PAYMENT_TYPE`

## Batch Jobs

### New Job: ChargeUsBankExpensesToDefaultAccountsJob

> Use ConcurSaeImportJob as a reference point.

#### Job Config

* jobDestination: `kfs`

#### Steps

1. `abortIfOtherInstanceAlreadyRunning` (see other jobs)
2. `importUsBankFile`
3. `encryptUsBankFile`
4. `applyDefaultAccounts`
5. `generateJournal`
6. `renameFileStep` (see other jobs)
7. `updateSyncInfoStep` (see other jobs)
8. `fileTransmitStep` (see other jobs)

#### Step Details

##### `importUsBankFile`

Extract the file and store in a mongo collection with a ready to process status.

1. Reader to extract the needed data from the file records into `UsBankFileRecord` objects.
2. Comparison processor to prevent import of duplicates.  (See configuration for `saeFlatEntryComparisonProcessor`)
3. Writer to write the records to MongoDB.  (Set up annotations on `UsBankFileRecord`)

The file format for US Bank is complicated.  It is a set of different record types, each with their own format.  On its own, this might be manageable with a configuration as shown here, which uses the line prefix to deal with the format.  (<https://stackoverflow.com/questions/29121789/spring-batch-read-multi-record-file>)  However, one of the values in the last record before each set of record type 4 indicates which format that group then has.  So, the parsing of type 4 records is itself dependent on the value in a prior record.

This will require the reader to maintain some state within the step (the reader object should be stateless) to track what has been seen before.  Additionally, the person to card mapping data is in one record type, so it will need to build up that mapping as it processes one sub-section and before it processes another.  It might end up being easiest to just use a `PassThroughLineMapper` and dealing with all the logic within the reader.  It should still use spring's tokenizers, with ones injected for each of the record types we need.

So, for file processing:

1. Read in file lines
2. scan for a row type 8
3. Get the rec type from that record - it identifies the format of the row type 4s until the next row type 9
4. Pass the row type 4s into a tokenizer based on the saved record type
5. Interesting Record Types on row type 4: 03, 04, 05
   1. `03` : Card Account Information - use this to identify which cards in the file are the CBCP cards we need to process.
   2. `04` : Card Holder Information - Use to link the cards identified in type 03 to employees
   3. `05` : Card Transactions - only process if the card number was selected per the type 03 records above.
6. For each `05` record, populate a `UsBankFileRecord` object and store it to MongoDB.

> DevNotes:
> Create Enums for the Row and Record Types
> We don't care about any other data in the file.
> We should check if the transaction ID already exists in the database to prevent duplicate processing.
> Do not store credit card number data in the step context, that is persisted to the database.

##### `encryptUsBankFile`

> ref: encryptSaeFileStep - can use the same key as the SAE file

The USBank file *WILL* have full corporate card account numbers.  As such, we should keep it in an unencrypted state for as little time as possible.

##### `applyDefaultAccounts`

1. Reader to pull the `UsBankFileRecord` objects from MongoDB where they still need extract.  (see mongoNeedsExtractItemReader)
2. Processor to use the information on the record to pull the default account and store it back to the object.
   1. Using the information on the record, pull the `CLEARING_ACCOUNT_CODE` from `CT_CREDIT_CARD_ACCOUNT`.  This will likely require getting the employee ID from the record in the file and linking back to this table on the `EMP_KEY` where the `PAT_CODE` is a configured value.  (The credit card # is encrypted and we don't have the decryption key.)
      1. If multiple records match, fail the record and include information in the notification emails.
   2. If there is a valid clearing account and the account is valid in KFS, then set that on the record and return.
   3. If not, and there is a valid account on the department record (per the employee's department in the concurEmployee collection) from the approver application available, then set that on the record and return.
   4. If not, then set the default clearing account on the record and return.
   5. When returning, clear any error flag and set the employee name and department code from the concurEmployee collection on the record..
3. Writer to write the records back to MongoDB.

##### `generateJournal`

1. Reader to pull the `UsBankFileRecord` objects from MongoDB where they still need extract.  (see `mongoNeedsExtractItemReader`)
   1. These would be items which need extract, have an account value, and are not in error status.
2. Processor to convert each `UsBankFileRecord` into multiple `GLJVLine` objects.  (Use the `itemListWriter` bean.)
   1. Will need to pull current fiscal year and period from KFS data.
   2. Will need to derive the description from the record data.
   3. Will need to create an offset credit line for each department entry line created from the input data.
   4. Will need to copy selected reference data from the input data into the available fields.  (E.g., employee ID, transaction ID, etc...)
3. Writer to output the data to a file in the needed GLJV format.  See the `CTSAgencyPaymentJob` for the needed writer format.  A generic line aggregator and GL Entry class will need to be created, as we will need to use this setup in two separate jobs.

#### Notifications

The standard job notification system will be used to send a summary of data from each main processing step to Operations and SCM.  The contents of the email have been worked out by what can be extracted and with review from SCM Staff.  There are no formal requirements for this email.  Instead, below is a sample email from the run of a test job.  Deviations from the contents shown here will be handled as an enhancement.

##### Implementation Notes

The email takes advantage of the integration framework which collects data in the job context under the `jobEmailLog` property to include in the default output generated and sent to operations in the case of a failure.  Processors assist in the gathering of information where needed.  Step listeners intercept the output from the steps and format the results after each step has completed and adds the information to the log.

##### Sample Notification

```txt
Job Name: ChargeUsBankExpensesToDefaultAccountsJob
Job Parameters: input.file=file:///Users/kellerj/dev/projects/concur-batch-integration/target/work/usbank_corp_card_file_3.txt run.id=146
Job ID: 73
Job Instance: 73

Start Date: 2020-02-20
Start Time: 15:22:42
Duration: 00:00:01

Status: COMPLETED
Exit Code: COMPLETED
Exit Message: Job successfully completed WITH WARNINGS and file created with name: journal.AT.20200220152242.data

Job Log
US Bank File Summary: usbank_corp_card_file_3.txt

	---------------------------------------- : ------------
	Total Transactions in File               :           11
	Card Accounts                            :            8
	Card Holders                             :            8
	Processed Transactions                   :           11
	Excluded Transactions (not expense type) :            0
	Skipped Transactions (no emp ID)         :            0
	Processed Transaction Total              :     2,875.09
	---------------------------------------- : ------------
	Duplicate Transactions Ignored           :            0

Account Assignment Summary

	                                                   :        Count     $ Amount
	-------------------------------------------------- : ------------ ------------
	Total Processed Records                            :            9     2,547.60
	Total Failed Records                               :            2       327.49
	Processed Using Card-Level Account                 :            1        58.31
	Processed Using Central Office Account             :            8     2,489.29
	Card-Level Account Missing or Invalid              :            8     2,489.29
	Missing Employee ID                                :            0         0.00
	Unknown Employee ID                                :            1         3.65
	Multiple Cards                                     :            1       323.84
	Prior Error: Missing Employee ID                   :            0         0.00
	Prior Error: Unknown Employee ID                   :            0         0.00
	Prior Error: Multiple Cards                        :            0         0.00
	-------------------------------------------------- : ------------ ------------


Account Assignment Error Messages:
BAD CARD ACCOUNT: 3-BADACCT failed KFS validation on Employee/Card: 11200002/1234
BAD CARD ACCOUNT: 3-BADACCT failed KFS validation on Employee/Card: 11200002/1234
BAD CARD ACCOUNT: 3-BADACCT failed KFS validation on Employee/Card: 11200002/1234
BAD CARD ACCOUNT: 3-BADACCT failed KFS validation on Employee/Card: 11200002/1234
FAILED: Multiple matching card accounts found in concur.  Failing record until resolved: UsBankFileRecord [employeeId=11200003, cardNumLast4=1212, transactionId=00000000000000000000005, sequenceNumber=1, cardholderName=YET ANOTHER CARDHOLDER, transactionAmount=323.84, postingDate=Fri Feb 07 00:00:00 PST 2020, transactionDate=Thu Oct 13 00:00:00 PDT 2005, merchantName=SOUTHWEST, cardIssueDate=Wed Aug 03 00:00:00 PDT 2005, transactionTypeCode=10, transactionDescription=VZMA0CF3FCE7, error=false, reconciledAmount=0.0, personalAmount=0.0, reconciled=false]
BAD CARD ACCOUNT: WTF_IS_THIS? failed KFS validation on Employee/Card: 11200005/3434
BAD CARD ACCOUNT: Clearing account code for employee/card# was blank: 11200006/5656
BAD CARD ACCOUNT: null failed KFS validation on Employee/Card: 11200006/5656
MISSING CARD: Unable to find card in concur for employee ID and card number: 11200007/7979
BAD CARD ACCOUNT: null failed KFS validation on Employee/Card: 11200007/7979
BAD CARD ACCOUNT: 3-EXPACCT failed KFS validation on Employee/Card: 11200777/7777
FAILED: Unknown Employee ID on US Bank Card Transaction Record: UsBankFileRecord [employeeId=11200999, cardNumLast4=9999, transactionId=00000000000000000000008, sequenceNumber=1, cardholderName=UNKNOWN CARDHOLDER, transactionAmount=3.65, postingDate=Tue Feb 18 00:00:00 PST 2020, transactionDate=Sun Feb 16 00:00:00 PST 2020, merchantName=PANERA, cardIssueDate=Wed Aug 03 00:00:00 PDT 2005, transactionTypeCode=10, transactionDescription=, error=false, reconciledAmount=0.0, personalAmount=0.0, reconciled=false]

GLJV File: 18 lines written:

	Doc : Tracking : Account                 :       Credit        Debit
	---------------------------------------- : ------------ ------------
	TC200220 : 11200002 : 3-CSHACCT          :       951.78         0.00
	TC200220 : 11200002 : 3-EXPDFLT          :         0.00       951.78
	TC200220 : 11200005 : 3-CSHACCT          :     1,489.48         0.00
	TC200220 : 11200005 : 3-EXPDFLT          :         0.00     1,489.48
	TC200220 : 11200006 : 3-CSHACCT          :         8.00         0.00
	TC200220 : 11200006 : 3-EXPDFLT          :         0.00         8.00
	TC200220 : 11200007 : 3-CSHACCT          :        22.30         0.00
	TC200220 : 11200007 : 3-EXPDFLT          :         0.00        22.30
	TC200220 : 11200777 : 3-CSHACCT          :        17.73         0.00
	TC200220 : 11200777 : 3-EXPDFLT          :         0.00        17.73
	TC200220 : 11200888 : 3-CSHACCT          :        58.31         0.00
	TC200220 : 11200888 : 3-GOODACT          :         0.00        58.31
	---------------------------------------- : ------------ ------------
	Journal                                  :     2,547.60     2,547.60

Steps Executed: 8
Step Execution Information:
	Step Name                                Reads  Writes Duration Status
	abortIfOtherInstanceAlreadyRunning       0      0      00:00:00 COMPLETED
	importUsBankFile                         45     11     00:00:00 COMPLETED
	encryptUsBankFile                        0      0      00:00:00 COMPLETED
	applyDefaultAccounts                     11     11     00:00:00 COMPLETED
	generateJournal                          9      9      00:00:00 COMPLETED
	renameFileStep                           0      0      00:00:00 COMPLETED
	updateSyncInfoStep                       0      0      00:00:00 COMPLETED
	fileTransmitStep                         0      0      00:00:00 COMPLETED
```

## GL Entry Details

### Common GL Entry Values

> These values will be used for all GL entries.

| GL Entry Field | Value |
| :------------- | :---- |
| docType        | GLJV  |
| balanceType    | AC    |
| originCode     | TA    |

### GL Entry Details

> Details of the required GL entries.  Add more columns as needed.  Add additional tables for different entry situations.  Rename columns if it helps clarity as long as each table's entries balance to zero.
> Bold fields are required on all entries.
> Keep column widths minimal.  Add bullet points after the table to elaborate as needed.

| GL Entry Field      | Department Entry           | Cash Account Entry |
| :------------------ | :------------------------- | :----------------- |
| **docNum(14)**      | TCyymmdd                   | (same)             |
| **chart**           | (derived)                  | 3                  |
| **account**         | (derived)                  | 1101320            |
| subAccount          | -----                      | -----              |
| **object**          | TRVL                       | 0050               |
| subObject           | ----                       | ----               |
| project             | ----------                 | ----------         |
| **amount**          | From US Bank File          | (same)             |
| **debitCredit**     | D if above positive        | (opposite)         |
| **description(40)** | (transactionId)_(emp name) | (same)             |
| **transDate**       | Card Transaction Date      | (same)             |
| trackingNumber(10)  | Employee ID                | (same)             |
| referenceId(8)      | Card # Last 4              | (same)             |
| **fiscalYear**      | Current FY                 | (same)             |
| fiscalPeriod        | (blank)                    | (blank)            |

* **Account Derivation:**
  * See the test cases below for details.  Essentially the goal is to use the best available departmental account number sourcing data in this order:
    1. Card Account Record: clearing account number
    2. Employee's Home Department Default Account
        * This value is maintained in the travel approver application by home department code.
    3. Central Clearing Account

## Application Behavior / Flow

N/A : No UI changes

## Service Dependencies

> List out the dependencies which this application has on other services such as APIs and databases.
> Indicate whether each dependency is mandatory for full application function or just for certain operations within the application.  (E.g., The CTS application is only dependent on the Concur API when...)

## Application Permissions

N/A : Addition of new batch job only - only Ops access

## Background Jobs

(none)

## Configuration Properties

> List out the configuration properties this application requires for operation with an explanation of each and sample value(s).

* New Property: `usbank.receive.directory=${base.receive.directory}/usbank`
    > Directory to which the US Bank files will need to be uploaded.
* New Property: `cbcp.card.payment.type.code=CBCP`
    > Payment type code to allow the new card type to be identified when looking up card numbers by employee.
* New Property: `cbcp.disbursement.account.chart=3`
* New Property: `cbcp.disbursement.account=1101320`
    > Account to use for the cash side of the transaction.  (usually the credit side)
* New Property: `cbcp.cash.object.code=0050`
    > Object code to use for the cash side of the transaction.
* New Property: `cbcp.expense.default.chart.account=3-XXXXXXX`
    > Default account to use if the account number is bad or the card can not be found.
* New Property: `cbcp.expense.object.code=TRVL`
    > Object code to use when expensing the department (or default) account.
* New Property: `cbcp.personal.expense.clearing.account=3-XXXXXXX`
    > Account to which to expense personal expenses which need to be reimbursed to the university.
* New Property: `cbcp.personal.expense.clearing.object.code=YYYY`
    > Object code to which to expense personal expenses which need to be reimbursed to the university.

## Testing

Testing will require sample files from USBank with data we can correlate with information in the `AGGIETRAVEL` schema.  We will need various failure scenarios as well to ensure the process works as expected.  Manually crafted data can be used for unit testing, but we will need actual files from US Bank prior to full cutover for proper testing.

### Test Cases

1. Able to identify card record based on employee ID, last 4 of card number, and payment type.
   1. Account on card record is valid.
      * Amount is transferred to account from the cash clearing account.
      * Account is recorded on the file record for later use.
   2. Account on card record is valid.  Amount is negative.
      * Amount is transferred to account from the cash clearing account.
      * Account is recorded on the file record for later use.
      * Must debit cash clearing account and credit department account.  (I.e., signs aligned with source data.)
   3. Account on card record is invalid. (?) _See below for handling of missing card._
      * Amount is transferred to default account from the cash clearing account.
      * Account is recorded on the file record for later use.
   4. Account on card record is missing.
      * Amount is transferred to default account from the cash clearing account.
      * Account is recorded on the file record for later use.
2. Able to identify employee, but not card.
   1. Able to obtain the employee's home department code.
      1. Department Code has a default account listed.
         * Amount is transferred to department default account from the cash clearing account.
         * Account is recorded on the file record for later use.
      2. Department Code does not have a default account listed.
         * Amount is transferred to central clearing account from the cash clearing account.
         * Account is recorded on the file record for later use.
   2. Unable to obtain the employee's home department code.
      * Amount is transferred to central clearing account from the cash clearing account.
      * Account is recorded on the file record for later use.
3. Unable to identify Employee.
   * Amount is transferred to central clearing account from the cash clearing account.
   * Account is recorded on the file record for later use.
4. GI...
   * ...GO
5. Job creates a file using the AT origin code in the flat-file GL Scrubber format.

## Additional Information

> Provide supplemental information for the function that will be represented in the document. It may be necessary to include supplemental information for clarity to readers (e.g. definitions).

### Definitions

> If needed, provide terms that help define the function. They can be defined in any order desired, but generally alphabetical order provides the greatest accessibility.

### Questions/Issues

> Provide a list of items that are concerns to the Business Analyst, DM, Lead Developer or SME with regard to the function that will be represented in the document.
