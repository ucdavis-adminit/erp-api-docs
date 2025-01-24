# 6.3.1.C KFS Implementation References

### KFS SAE Integration Reference

#### Processing Exclusion Filter

> The below was used to extract records matching the rule from any processing.  Except for the personal entries, this may not be accurate for the future state.

```js
{
  'syncInfo.destinations.#{jobExecutionContext['job.destination']}.needsExtract': true,
  'error' : false,
  '$nor': [
    {'$and' : [
      {'journal.payerPaymentType' : { $eq: 'University'}},
      {'journal.payeePaymentType': { $eq: 'User'}},
      {'expenseTypeName' : { $eq: 'Personal or Non Reimbursable'}},
      {'paymentTypeCode' : { $eq: 'CBCP'}}
    ]}
  ]
}
```

#### Extract Type Filters

> These are the types of feeds we send into KFS today as separate items.  Filters are listed below for reference.

##### PCard Reconciliation

* Must have an allocation
* have the CBCP payment type
* Be on the Pcard policy

```js
{
  'syncInfo.destinations.${ReconciledPCardPaymentJob.export.destination}.needsExtract': true,
  'error' : false,
  'journals.allocation.allocationId' : { $exists : true },
  'paymentTypeCode' : '${sae.pcard.paymentTypeCode}',
  'batchReport.reportPolicyName' : '${pcard.batchReport.reportPolicyName}'
}
```

##### Travel Card Reconciliation

* have the CBCP payment type
* Not be on the pcard policy
* have an allocation or be a personal expense

```js
{
  'syncInfo.destinations.${ReconciledCorpCardPaymentJob.export.destination}.needsExtract': true,
  'error' : false,
  'paymentTypeCode' : '${sae.corpcard.paymentTypeCode}',
  'batchReport.reportPolicyName' : {'$ne' : '${pcard.batchReport.reportPolicyName}' },
  '$or' : [ { 'journals.allocation.allocationId' : { $exists : true } }, { 'expenseTypeName' : '${sae.personal.expenseTypeName}' } ]
}
```

##### Travel Agency Reconciliation

* Must have an allocation
* have the COPD payment type

```js
{
  'syncInfo.destinations.${ReconciledCTSPaymentJob.export.destination}.needsExtract': true,
  'error' : false,
  'journals.allocation.allocationId' : { $exists : true },
  'paymentTypeCode' : '${sae.cts.paymentTypeCode}',
  'batchReport.reportPolicyName' : {'$ne' : '${pcard.batchReport.reportPolicyName}' }
}
```

##### Traveller Reimbursement Payment

* User must be recipient (filters out credits)
* Must have an allocation
* have the CASH payment type

```js
{
  'syncInfo.destinations.${TravelerReimbursementPaymentJob.export.destination}.needsExtract': true,
  'error' : false,
  'journals.payeePaymentType' : 'User',
  'journals.allocation.allocationId' : { $exists : true },
  'paymentTypeCode' :  '${sae.travelerReimbursement.paymentTypeCode}'
}
```

##### Cash Advance Payments

```js
{
  'syncInfo.destinations.${CashAdvancePaymentJob.export.destination}.needsExtract': true,
  'error' : false,
  'journals.cashAdvance.cashAdvanceTransactionCode' : '1'
}
```

#### SAE Extracted Fields

> Current fields extracted from the SAE (by index number) and the property they were loaded into during integrations.

```xml
<bean parent="indexPropertyMapping" p:index="2"           p:name="batchReport.batchId" />
<bean parent="indexPropertyMapping" p:index="3"   p:type="DATE"   p:name="batchReport.batchDate" />
<bean parent="indexPropertyMapping" p:index="4"            p:name="journal.batchSequenceNumber" />
<bean parent="indexPropertyMapping" p:index="5"            p:name="employee.employeeId" />
<bean parent="indexPropertyMapping" p:index="6"           p:name="employee.lastName" />
<bean parent="indexPropertyMapping" p:index="7"            p:name="employee.firstName" />
<bean parent="indexPropertyMapping" p:index="8"            p:name="employee.middleName" />
<bean parent="indexPropertyMapping" p:index="9"            p:name="employee.groupCode" />
<bean parent="indexPropertyMapping" p:index="10"          p:name="employee.divisionCode" />
<bean parent="indexPropertyMapping" p:index="11"          p:name="employee.departmentCode" />
<bean parent="indexPropertyMapping" p:index="20"          p:name="batchReport.reportId" />
<bean parent="indexPropertyMapping" p:index="24"  p:type="DATE"   p:name="batchReport.submitDate" />
<bean parent="indexPropertyMapping" p:index="27"          p:name="batchReport.reportName" />
<bean parent="indexPropertyMapping" p:index="33"          p:name="batchReport.reportPolicyName" />
<bean parent="indexPropertyMapping" p:index="42"          p:name="tripType" />
<bean parent="indexPropertyMapping" p:index="45"          p:name="batchReport.checkHandling" />
<bean parent="indexPropertyMapping" p:index="59"          p:name="batchReport.destinationType" />
<bean parent="indexPropertyMapping" p:index="61"          p:name="entryId" />
<bean parent="indexPropertyMapping" p:index="63"          p:name="expenseTypeName" />

<bean parent="indexPropertyMapping" p:index="64" p:type="DATE"      p:name="transactionDate" />

<bean parent="indexPropertyMapping" p:index="71"          p:name="vendorDescription" />

<!-- Custom fields for pCard-->
<bean parent="indexPropertyMapping" p:index="${delivery.postal.code.index}"     p:name="deliveryPostalCode" />
<bean parent="indexPropertyMapping" p:index="${sales.tax.amount.index}"         p:name="salesTaxAmount" />
<bean parent="indexPropertyMapping" p:index="${tax.exempt.purchase.index}"      p:name="taxExemptPurchase" />
<bean parent="indexPropertyMapping" p:index="${taxable.index}"                  p:name="taxable" />
<bean parent="indexPropertyMapping" p:index="${agreement.number.index}"         p:name="agreementNumber" />


<bean parent="indexPropertyMapping" p:index="124" p:type="DOUBLE"  p:name="postedAmount" />
<bean parent="indexPropertyMapping" p:index="126"          p:name="paymentTypeCode" />
<bean parent="indexPropertyMapping" p:index="130"          p:name="creditCard.accountNumber" />
<bean parent="indexPropertyMapping" p:index="131"          p:name="creditCard.accountName" />
<bean parent="indexPropertyMapping" p:index="133"          p:name="creditCard.transactionReference" />

<bean parent="indexPropertyMapping" p:index="142" p:type="DATE"     p:name="creditCard.transactionDate" />
        <bean parent="indexPropertyMapping" p:index="143" p:type="DATE"     p:name="creditCard.postedDate" />
<bean parent="indexPropertyMapping" p:index="148"                   p:name="creditCard.merchantState" />
        <bean parent="indexPropertyMapping" p:index="149"                   p:name="creditCard.merchantCountryCode" />

<bean parent="indexPropertyMapping" p:index="163"          p:name="journal.payerPaymentType" />
<bean parent="indexPropertyMapping" p:index="165"          p:name="journal.payeePaymentType" />
<bean parent="indexPropertyMapping" p:index="167"          p:name="journal.allocation.financialObjectCode" />
<bean parent="indexPropertyMapping" p:index="168"          p:name="debitCreditCode" />
<bean parent="indexPropertyMapping" p:index="169" p:type="DECIMAL"  p:name="journal.journalAmountForParsing" />
<bean parent="indexPropertyMapping" p:index="170"          p:name="journal.journalId" />
<bean parent="indexPropertyMapping" p:index="177" p:type="DOUBLE"  p:name="journal.cashAdvance.cashAdvanceRequestAmount" />
<bean parent="indexPropertyMapping" p:index="183" p:type="DATE"   p:name="journal.cashAdvance.cashAdvanceIssuedDate" />
<bean parent="indexPropertyMapping" p:index="185"          p:name="journal.cashAdvance.cashAdvanceTransactionCode" />
<bean parent="indexPropertyMapping" p:index="187"          p:name="journal.cashAdvance.cashAdvanceId" />
<bean parent="indexPropertyMapping" p:index="189"          p:name="journal.allocation.allocationId" />
<bean parent="indexPropertyMapping" p:index="190" p:type="DOUBLE"  p:name="journal.allocation.allocationPercentage" />
<bean parent="indexPropertyMapping" p:index="191"          p:name="journal.allocation.chartAccount" />
<bean parent="indexPropertyMapping" p:index="192"          p:name="journal.allocation.subAccountNumber" />
<bean parent="indexPropertyMapping" p:index="193"          p:name="journal.allocation.projectCode" />
<bean parent="indexPropertyMapping" p:index="194"          p:name="journal.allocation.organizationReferenceId" />
<bean parent="indexPropertyMapping" p:index="259"          p:name="journal.cashAdvance.cashAdvanceName" />
<bean parent="indexPropertyMapping" p:index="270"          p:name="employee.mailingAddressLine1" />
<bean parent="indexPropertyMapping" p:index="271"          p:name="employee.mailingAddressLine2" />
<bean parent="indexPropertyMapping" p:index="272"          p:name="employee.mailingAddressLine3" />
<bean parent="indexPropertyMapping" p:index="273"          p:name="employee.mailingAddressCity" />
<bean parent="indexPropertyMapping" p:index="274"          p:name="employee.mailingAddressState" />
<bean parent="indexPropertyMapping" p:index="275"          p:name="employee.mailingAddressZip" />
<bean parent="indexPropertyMapping" p:index="276"          p:name="employee.mailingAddressCountry" />
<bean parent="indexPropertyMapping" p:index="283"          p:name="employee.defaultCheckHandling" />
<bean parent="indexPropertyMapping" p:index="327" p:type="DOUBLE"  p:name="batchReport.cashAdvanceReturnAmount" />
<bean parent="indexPropertyMapping" p:index="329" p:type="DOUBLE"  p:name="batchReport.cashAdvanceUtilizedAmount" />
```


# US Bank Transaction Reconciliation

JIRA: <https://afs-dev.ucdavis.edu/jira/browse/CONCUR-516>

## Project Scope

> Provide a short description of the software being specified and its purpose, including relevant benefits, objectives, and goals.

UCD will be converting the existing corporate card model to a direct debit model where USBank will extract the funds when they want to from our bank account and then send us a file of what they just withdrew.  This file will be the previous day's posted transactions and will match what they withdrew from our bank account.  This allows them to get their money immediately instead of when the traveller reconciles the charge in Concur.  The file sent by USBank will have a summary of the charges which will allow us to credit the campus cash account (representing the removed funds) and debit the default account associated with each card.

When a traveller reconciles their trip expenses, the accounting entry used on the report will be used to transfer the funds from the default listed for the card to that given in the allocations.  This is identical to how we handle CTS expenses except for the source of the source account when we process reports from AggieTravel.  And the payment-to-the-bank side is almost identical to how we handle PCard and PMT+ payments to the bank.

The process for handling personal expenses is fundamentally different in this model.  Previously, UC would simply not pay the card, leaving the traveller responsible for paying the balance.  In the new model, US Bank debits UC for all charges which hit the corporate card, leaving the traveller owing UC for the personal expenses.  A new process will need to be set up for tracking personal expenses made on each card and to generate a receivable balance for repayment.

## Design Scope

This design covers the batch job which extracts the reconciled expenses that reference the new direct-debit corporate card and moves the expense between the default account for the card and the account listed in the allocation on the expense report.  The result of this job will be a net-zero PDP payment which will move the expense in the ledger.  (This is the same as the process used to reconcile CTS transactions.)

## Project Dependencies and Assumptions

### Dependencies

### Assumptions

1. The expenses reconciled have already been sent to UCD on the US Bank file, imported into the `usBankFileRecord` collection and expensed to the general ledger via a separate batch job.
2. The chart-account value which was expensed by the US Bank file processing has been stored in the `usBankFileRecord` collection.
3. The SAE record will contain the needed information to identify a record in the `usBankFileRecord` collection from which to load the source account.

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
* [ ] Oracle Database Structure
* [ ] Oracle Database Data
* [ ] MongoDB Configuration
* [X] MongoDB Data
* [ ] React Components
* [ ] REST API Endpoints

### Referenced Libraries

> If the application requires the addition of libraries which are not already part of the application or the starter project, please list them out here along with a note as to their purpose/use within the application.

## Data Model

> Provide a comprehensive listing of the logical data model for the project.

### New Data Objects

(tbd)

### Database Objects (if applicable)

> Provide an overview of the table structures being created/altered for the application.

### Accounts and Permissions

> List out any new database accounts and the permissions they will need to make the application work.

## Batch Jobs

### New Job: ReconciledCorpCardPaymentJob

> Use ReconciledCTSPaymentJob as a reference point.

This job functions almost exactly like the CTS reconcilation job.  The CTS process is another where the expenses have already been paid by the university and the reconcilation is just to transfer the funds to the appropriate account afterwards.  As such, only two components of the job need to differ between the processes.

1. Data extraction from the `saeEntry` collection.
2. Processing of the entries to set additional data from the original transaction and net the amount of the payment detail out to zero.

#### Job Config

##### Job Listener

* jobDestination: `${ReconciledCorpCardPaymentJob.export.destination}`
* email on success: `${ReconciledCorpCardPaymentJob.emailSuccess}`
* email on failure: `true`
* file job tag: `${ReconciledCorpCardPaymentJob.file.job.tag}`
* SAE Entry Extract Query:
  1. Records which need extraction to KFS
  2. Not already errored out
  3. Have an allocation *or* are a personal expense (which never has allocations)
  4. Uses the CBCP Payment type code

    ```js
    {
        'syncInfo.destinations.${ReconciledCorpCardPaymentJob.export.destination}.needsExtract': true,
        'error' : false,
        '$or' : [ { 'journals.allocation.allocationId' : { $exists : true } }, { 'expenseTypeName' : '${sae.personal.expenseTypeName}' } ],
        'paymentTypeCode' : '${sae.corpcard.paymentTypeCode}'
    }
    ```

* `paymentOriginMetadata` : set to the card number, we need the last 4 digits when processing. (`creditCard.accountNumber`)
* `paymentSourceAdditionalId` : set to the unique transaction of the credit card transaction (`creditCard.transactionReference`)

##### Job Logging Listener

* logging level: `${ReconciledCorpCardPaymentJob.logLevel}`

##### Scheduler

* enabled: `${ReconciledCorpCardPaymentJob.scheduler.enabled}`
* cron: `${ReconciledCorpCardPaymentJob.scheduler.cron}`

#### Steps

1. `abortIfOtherInstanceAlreadyRunning` (common step - copy)
2. `convertReportsToPaymentsStep` (common step - reconfigure - see below)
3. `updateContinuationAccounts` (common step - copy)
4. `updateSaeEntrySyncInfoStep` (common step - copy)
5. **`offsetCorpCardPayment`**
6. `createPaymentXmlStep` (common step - copy)
7. `prettyPrintXmlStep` (common step - copy)
8. `movePaymentFileToDropOffAreaStep` (common step - copy)
9. `updateJobPaymentGroupSyncInfoStep` (common step - copy)
10. `deleteTempPaymentFileStep` (common step - copy)

#### Step Details

##### `convertReportsToPaymentsStep`

This step uses common configuration which allows it to be used unchanged.  What does need to be updated are the properties set on the job listener per the section above.

##### `offsetCorpCardPayment`

1. Pull up the transaction by its unique transaction ID from the `usBankFileRecord` collection.
   * This should be stored in the `paymentOriginMetadata` property of the SAE Entry.
2. Get the account expensed during the earlier file from that record.
3. If the transaction can not be found or account is not present on the record, log out an ERROR and skip the transaction.  Update the record with processed: false, error: true, and a relevant error message.
   1. Note: there is now a flag to control the above behavior.  If it is set, the transaction will be processed, but using default values for the offset FAU.  Details below.
4. Set the `organizationDocNbr` on the `PaymentDetail` object to the employee ID.
5. Set the `orgReferenceId` to the last 4 of the credit card number.
6. If NOT a Personal Expense:
   1. Debit Entry should use the allocation data provided in the `SaeEntry` record.
7. If a Personal Expense:
   1. Debit Entry should use the receivable account per the `cbcp.personal.expense.clearing.account` configuration property.  Object code should come from `cbcp.personal.expense.object.code`.
8. Offset entry should have the reversed amount from the debit entry and use the `cbcp.expense.object.code` object code.
9. Offset entry depends on whether the source transaction can be found.  If so:
   1. Pull the chart account from the `usBankFileRecord` transaction.
10. If not:
    1. Use the chart-account from `cbcp.expense.default.chart.account`.

## GL Entry Details - Reference Only

> This section is for reference only.  The GL entries are created by the PDP module of KFS.  We have limited control over the fields.

### Normal: With Transaction

| GL Entry Field      | Allocation Entry | Default Account Entry         |
| :------------------ | :--------------- | :---------------------------- |
| **chart**           | From Concur      | From Original US Bank Expense |
| **account**         | From Concur      | From Original US Bank Expense |
| subAccount          | From Concur      | -----                         |
| **object**          | From Concur      | Default Expense Object Code   |
| project             | From Concur      | ----------                    |
| **amount**          | From Concur      | From Concur                   |
| **debitCredit**     | D (if positive)  | C                             |
| **description(40)** |                  |                               |
| trackingNumber(10)  | Employee ID      | Employee ID                   |
| referenceId(8)      | Card Last 4      | Card Last 4                   |

### Personal: With Transaction

| GL Entry Field      | Allocation Entry             | Default Account Entry         |
| :------------------ | :--------------------------- | :---------------------------- |
| **chart**           | Personal Expense Chart       | From Original US Bank Expense |
| **account**         | Personal Expense Account     | From Original US Bank Expense |
| subAccount          | -----                        | -----                         |
| **object**          | Personal Expense Object Code | Default Expense Object Code   |
| project             | ----------                   | ----------                    |
| **amount**          | From Concur                  | From Concur                   |
| **debitCredit**     | D (if positive)              | C                             |
| **description(40)** |                              |                               |
| trackingNumber(10)  | Employee ID                  | Employee ID                   |
| referenceId(8)      | Card Last 4                  | Card Last 4                   |


### Normal: Missing Transaction

| GL Entry Field      | Allocation Entry | Default Account Entry         |
| :------------------ | :--------------- | :---------------------------- |
| **chart**           | From Concur      | Default Expense Account Chart |
| **account**         | From Concur      | Default Expense Account       |
| subAccount          | From Concur      | -----                         |
| **object**          | From Concur      | Default Expense Object Code   |
| project             | From Concur      | ----------                    |
| **amount**          | From Concur      | From Concur                   |
| **debitCredit**     | D (if positive)  | C                             |
| **description(40)** |                  |                               |
| trackingNumber(10)  | Employee ID      | Employee ID                   |
| referenceId(8)      | Card Last 4      | Card Last 4                   |

### Personal: Missing Transaction

| GL Entry Field      | Allocation Entry             | Default Account Entry         |
| :------------------ | :--------------------------- | :---------------------------- |
| **chart**           | Personal Expense Chart       | Default Expense Account Chart |
| **account**         | Personal Expense Account     | Default Expense Account       |
| subAccount          | -----                        | -----                         |
| **object**          | Personal Expense Object Code | Default Expense Object Code   |
| project             | ----------                   | ----------                    |
| **amount**          | From Concur                  | From Concur                   |
| **debitCredit**     | D (if positive)              | C                             |
| **description(40)** |                              |                               |
| trackingNumber(10)  | Employee ID                  | Employee ID                   |
| referenceId(8)      | Card Last 4                  | Card Last 4                   |

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

### `application.properties`

* New Property: `ReconciledCorpCardPaymentJob.export.destination=kfs`
* New Property: `ReconciledCorpCardPaymentJob.emailSuccess=false`
* New Property: `ReconciledCorpCardPaymentJob.file.job.tag=corpcard`
* New Property: `sae.corpcard.paymentTypeCode=CBCP`

### `instance.properties[.j2]`

* New Property: `ReconciledCorpCardPaymentJob.logLevel=INFO`
* New Property: `ReconciledCorpCardPaymentJob.scheduler.enabled=true`
* New Property: `ReconciledCorpCardPaymentJob.scheduler.cron=0 5 9 * * MON-FRI`
* New Property: `ReconciledCorpCardPaymentJob.useDefaultAccountOnMissingTransaction=true`

### `springbatch.properties` (new file)

```properties
site.name=AggieTravel Integration Batch Server
home.title=AggieTravel Integration Batch Server
company.url=https://adminit.ucdavis.edu
company.name=Admin IT, University of California, Davis
product.url=https://afs-dev.ucdavis.edu/stash/projects/AT/repos/concur-batch-integration/browse/docs/README.md
product.name=AggieTravel Integrations
copyright=Copyright 2020 Regents of the University of California. All Rights Reserved.
company.contact.url=mailto:ait-ops@ucdavis.edu
company.contact=Contact Admin IT Operations

ReconciledCorpCardPaymentJob.description=Processes Reconciled Corp Card payments into Net Zero PDP Payments
ChargeUsBankExpensesToDefaultAccountsJob.description=Creates Journal to move US Bank expenses to card default accounts
```

## Testing

1. Expense contains valid transaction ID which can be found in the the `usBankFileRecord` collection.
   1. `usBankFileRecord` contains a valid account
      * Generates a PaymentDetail record which nets out to zero.  Each side being the amount of the transaction, moving the funds from the account charged on the original journal to the one specified in the SAE file per the allocation data.
      * Sets the tracking number on the GL entry to the employee ID.
      * Sets the org ref ID on the GL entry to the last 4 digits of the credit card number.
   2. `usBankFileRecord` does not contain a valid account (useDefaultAccountOnMissingTransaction=false)
      * Record is marked as unprocessed, as an error, and contains an error message.
      * No PDP payment record should be created for these transactions.
2. Expense does not contain valid transaction ID which can be found in the the `usBankFileRecord` collection.
   1. (useDefaultAccountOnMissingTransaction=false)
      * Record is marked as unprocessed, as an error, and contains an error message.
   2. (useDefaultAccountOnMissingTransaction=true)
      * Generates a PaymentDetail record which nets out to zero.  Each side being the amount of the transaction, moving the funds from the default expense account to the one specified in the SAE file per the allocation data.
      * Sets the tracking number on the GL entry to the employee ID.
      * Sets the org ref ID on the GL entry to the last 4 digits of the credit card number.
3. Job creates a PDP XML file containing the succesfully procssed payments.

## Additional Information

> Provide supplemental information for the function that will be represented in the document. It may be necessary to include supplemental information for clarity to readers (e.g. definitions).

### Definitions

> If needed, provide terms that help define the function. They can be defined in any order desired, but generally alphabetical order provides the greatest accessibility.

### Questions/Issues

> Provide a list of items that are concerns to the Business Analyst, DM, Lead Developer or SME with regard to the function that will be represented in the document.


KFS PDP Payment Import
======================

Basics
------

* Baseline KFS provides a direct-to-PDP payment import job
  * Job name: **pdpLoadPaymentsJob**
  * XML Schema: **payment.xsd**
  * XML Data Dictionary: **ddTypes.xsd**
  * Digester: **paymentDigesterRules.xml**
  
* The XML digester parsing results in a single PaymentFileLoad object
  * **PaymentFileLoad**, which includes
    * Batch attributes
    * List of one or more **PaymentGroup** objects, each with
      * Group attributes
      * List of one or more **PaymentDetail** objects, each with
        * Detail attributes
        * List of one or more **PaymentAccountDetail** objects, each with
          * Account attributes
        * Optional list of **PaymentNoteText** objects, each with
          * Note attributes
          
* The PaymentFileLoad object is then validated, and, if validation passes, the object is persisted in the PDP tables
  
Assumptions
-----------

* The pdpLoadPaymentsJob is currently disabled. It can be easily re-enabled and will work as expected.
* In general, fields that are set by the current AP Feed direct-to-PDP job should be available in the XML schema used by the pdpLoadPaymentsJob. In other words, since the current MyTravel import from DaFIS sets these fields, we'll want them to be available for the AggieTravel payment import.

Consider
--------

* May need to add rules to the payment file validation.
  * Consider whether additional validation rules are needed for any attributes that we add to the baseline XML schema.
* ![Warning][warning_img] There is no validation to test whether a particular Payment Source (aka Customer) is permitted to submit payment XML files.
  * Could add a _Allow XML feed_ flag to the Customer Profile and add a validation test for the flag.
  * Similar issue for the following fields in the PaymentDetail object. Add validation tests?
    * financialSystemOriginCode: Should match the Customer Profile Feed Origin Code.
    * financialDocumentTypeCode: Should be PDP.
    * pymtOriginationCode: Should match the Customer Profile Feed Origin Code.
* In the AP Feed direct-to-PDP processing, there are a number of per-feed flags that control whether or not a feed partner is allowed to take certain actions. If we want to conditionally allow these actions when importing payments via the pdpLoadPaymentsJob, we may need a similar mechanism. The flags are listed here along with the current values for the MyTravel direct-to-PDP AP Feed.
  * | Flag                                    | Value for Direct-to-PDP MyTravel AP Feed | Notes |
    |-----------------------------------------|------------------------------------------|-------|
    | Can create CM document                  | No  |    |
    | Allow wire/draft payments               | Yes | ![Warning][warning_img] During AP Feed processing, wire/draft payments are redirected to a DV document for wire processing.<br>![Warning][warning_img] Wire/draft payments generated by AggieTravel will be handled by another process, not via this XML payment import process |
    | Allow vendor payee type                 | Yes |    |
    | Allow employee payee type               | Yes |    |
    | Allow student payee type                | No  |    |
    | Allow other payee type                  | Yes |    |
    | Allow employee not found                | Yes | Applicable only if payee type is employee   |
    | Allow inactive vendor                   | Yes | Applicable only if payee type is vendor     |
    | Auto-create Project Code if not found   | No  |    |

  * 
  
### Quick Comparison

At its core, the end result of the PDP payment import will be the same as the direct-to-PDP AP feed: directly populate PDP tables for payments.

Here is a summary of some differences between other aspects of the two jobs.

| MyTravel AP Feed                                                              | PDP Payment Import                                |
|-------------------------------------------------------------------------------|---------------------------------------------------|
| Feed result summary emailed to customer.                                      | Import summary emailed to AP.                     |
| We tried to make the customer email report fairly easy to read and interpret. | Import summary email isn't very friendly.         |
| AP feed files are moved to an archive directory.                              | Imported XML files are deleted.                   |
| AP feed processing occurs three times daily: 9 am, 1pm and 6pm.               | pdpLoadPaymentsJob will run once per day at 5 pm. |
| Other, related validation before calling baseline PaymentLoadFile validation. | Only baseline PaymentLoadFile validation.         |

Object-to-XML Mapping
---------------------

### XML Schema

| Symbol                               | Notes                                                                         |
|--------------------------------------|-------------------------------------------------------------------------------|
| ![Baseline][baseline_img] Baseline   | Already exists in baseline XML schema                                         |
| ![Add][add_img] Add                  | Add attribute to XML schema and digester                                      |
| ![Maybe][question_img] Maybe         | Add to XML schema/digester or set during post-parse / validation phase?       |
| N/A                                  | Do not import via XML; attribute is set during processing, after basic import |
| Not used in PDP                      | Apparently a dead attribute, not used in PDP processing                       |

### Required

| Symbol                                           | Notes                                                               |
|--------------------------------------------------|---------------------------------------------------------------------|
| ![Baseline][baseline_img] Baseline Required      | Already a required field in baseline XML schema                     |
| ![Configurable][info_img] Conditionally Required | Not required by XML, but conditionally required during validation   |
| ![Add][add_img] Add Required                     | Add required flag for this attributes in XML schema                 |
| ![Not Required][empty_img] Not Required          | Attribute available for import, but not a required attribute        |
| N/A                                              | Not imported via XML                                                |


[baseline_img]: images/thumbs_up.png "Baseline"
[add_img]:      images/add.png "Add"
[question_img]: images/help_16.png "Maybe"
[info_img]:     images/information.png "Configurable"
[empty_img]:    images/lightbulb.png "Not Required"
[warning_img]:  images/warning.png "Warning"

### PaymentFileLoad

| BO Attribute Name  | XML Schema                         | XML Attribute Name | Required                                    |
|--------------------|------------------------------------|--------------------|---------------------------------------------|
| chart              | ![Baseline][baseline_img] Baseline | chart              | ![Baseline][baseline_img] Baseline Required |
| unit               | ![Baseline][baseline_img] Baseline | unit               | ![Baseline][baseline_img] Baseline Required |
| subUnit            | ![Baseline][baseline_img] Baseline | sub_unit           | ![Baseline][baseline_img] Baseline Required |
| creationDate       | ![Baseline][baseline_img] Baseline | creation_date      | ![Baseline][baseline_img] Baseline Required |
| paymentCount       | ![Baseline][baseline_img] Baseline | detail_count       | ![Baseline][baseline_img] Baseline Required |
| paymentTotalAmount | ![Baseline][baseline_img] Baseline | detail_tot_amt     | ![Baseline][baseline_img] Baseline Required |
| batchId            | N/A                                |                    | N/A                                         |
| fileThreshold      | N/A                                |                    | N/A                                         |
| detailThreshold    | N/A                                |                    | N/A                                         |
| taxEmailRequired   | N/A                                |                    | N/A                                         |
| passedValidation   | N/A                                |                    | N/A                                         |

##### Duplicate batch detection

A batch is considered a duplicate when the following attributes match a previously processed batch. Duplicate batches are rejected.
* chart-unit-subUnit (Customer aka Payment Source)
* creationDate
* paymentCount
* paymentTotalAmount


### PaymentGroup

| BO Attribute Name                     | XML Schema                         | XML Attribute Name       | Required                                       |
|---------------------------------------|------------------------------------|--------------------------|------------------------------------------------|
| id                                    | N/A                                |                          | N/A                                            |
| batchId                               | N/A                                |                          | N/A                                            |
| processId                             | N/A                                |                          | N/A                                            |
| payeeName                             | ![Baseline][baseline_img] Baseline | payee_name               | ![Baseline][baseline_img] Baseline Required    |
| payeeId                               | ![Baseline][baseline_img] Baseline | payee_id                 | ![Conditional][info_img] Conditionally Required, determined by Payee ID Required flag of Customer Profile. |
| payeeIdTypeCd                         | ![Baseline][baseline_img] Baseline | id_type                  | ![Conditional][info_img] Conditionally Required, required whenever payee_id is specified        |
| alternatePayeeId                      | ![Add][add_img] Add                | _alternate_payee_id_     | ![Not Required][empty_img] Not Required        |
| alternatePayeeIdTypeCd                | ![Add][add_img] Add                | _alternate_id_type_      | ![Conditional][info_img] Conditionally Required, required whenever alternate_payee_id is specified        |
| employeeIndicator                     | ![Add][add_img] Add                | _employee_ind_           | ![Not Required][empty_img] Not Required, defaults to No |
| payeeOwnerCd                          | ![Baseline][baseline_img] Baseline | payee_own_cd             | ![Not Required][empty_img] Not Required        |
| line1Address                          | ![Baseline][baseline_img] Baseline | address1                 | ![Baseline][baseline_img] Baseline Required    |
| line2Address                          | ![Baseline][baseline_img] Baseline | address2                 | ![Not Required][empty_img] Not Required        |
| line3Address                          | ![Baseline][baseline_img] Baseline | address3                 | ![Not Required][empty_img] Not Required        |
| line4Address                          | ![Baseline][baseline_img] Baseline | address4                 | ![Not Required][empty_img] Not Required        |
| city                                  | ![Baseline][baseline_img] Baseline | city                     | ![Not Required][empty_img] Not Required        |
| state                                 | ![Baseline][baseline_img] Baseline | state                    | ![Not Required][empty_img] Not Required        |
| country                               | ![Baseline][baseline_img] Baseline | country                  | ![Not Required][empty_img] Not Required        |
| zipCd                                 | ![Baseline][baseline_img] Baseline | zip                      | ![Not Required][empty_img] Not Required        |
| taxCalculationCode                    | ![Add][add_img] Add                | _tax_calculation_code_   | ![Not Required][empty_img] Not Required        |
| campusAddress                         | ![Baseline][baseline_img] Baseline | campus_address_ind       | ![Not Required][empty_img] Not Required, defaults to No |
| pymtAttachment                        | ![Baseline][baseline_img] Baseline | attachment_ind           | ![Not Required][empty_img] Not Required, defaults to No |
| pymtSpecialHandling                   | ![Baseline][baseline_img] Baseline | special_handling_ind     | ![Not Required][empty_img] Not Required, defaults to No |
| taxablePayment                        | ![Baseline][baseline_img] Baseline | taxable_ind              | ![Not Required][empty_img] Not Required, defaults to No |
| nraPayment                            | ![Baseline][baseline_img] Baseline | nra_ind                  | ![Not Required][empty_img] Not Required, defaults to No |
| processImmediate                      | ![Baseline][baseline_img] Baseline | immediate_ind            | ![Not Required][empty_img] Not Required, defaults to No |
| combineGroups                         | ![Baseline][baseline_img] Baseline | combine_group_ind        | ![Not Required][empty_img] Not Required, defaults to No |
| paymentDate                           | ![Baseline][baseline_img] Baseline | payment_date             | ![Not Required][empty_img] Not Required, defaults to tomorrow |
| paymentStatusCode                     | N/A                                |                          | N/A                                            |
| physCampusProcessCd                   | N/A                                |                          | N/A                                            |
| sortValue                             | N/A                                |                          | N/A                                            |
| disbursementTypeCode (see note below) | ![Maybe][question_img] Maybe       | _disbursement_type_code_ | ![Not Required][empty_img] Not Required        |
| bankCode                              | ![Baseline][baseline_img] Baseline | bank_code                | ![Not Required][empty_img] Not Required        |
| disbursementNbr                       | N/A                                |                          | N/A                                            |
| disbursementDate                      | N/A                                |                          | N/A                                            |
| achAccountType                        | N/A                                |                          | N/A                                            |
| achServiceTypeCode                    | N/A                                |                          | N/A                                            |
| achBankRoutingNbr                     | N/A                                |                          | N/A                                            |
| achReferenceId                        | N/A                                |                          | N/A                                            |
| achTraceNumber                        | N/A                                |                          | N/A                                            |
| adviceEmailAddress                    | N/A                                |                          | N/A                                            |
| adviceEmailSentDate                   | N/A                                |                          | N/A                                            |
| epicPaymentCancelledExtractedDate     | N/A                                |                          | N/A                                            |
| epicPaymentPaidExtractedDate          | N/A                                |                          | N/A                                            |
| disbursementClaimedDate               | N/A                                |                          | N/A                                            |
| disbursementStaleDatedDate            | N/A                                |                          | N/A                                            |
| shipToCountryCode                     | Not used in PDP                    |                          | N/A                                            |
| shipToStateCode                       | Not used in PDP                    |                          | N/A                                            |
| shipToPostalCode                      | Not used in PDP                    |                          | N/A                                            |
| creditMemoNbr                         | Not used in PDP                    |                          | N/A                                            |
| creditMemoAmount                      | Not used in PDP                    |                          | N/A                                            |

##### disbursementTypeCode
The disbursementTypeCode attribute is set in one context during the AP Feed MyTravel import processing. When the payee is a vendor, the processor checks if the indicated vendor is a Payment Plus vendor. If so, the disbursementTypeCode is set to the PMT+ when the PDP payment group attributes are populated/created.

Depending on how we want to separate duties between the integration server (where the payment XML file will be generated) and KFS (where the payment XML file will be processed), we may want to put the logic to detect a Payment Plus vendor on one side or the other.

![Warning][warning_img] Will add to XML schema. If decision is made to handle in KFS post-parse, the attribute should be removed from the XML schema.

### PaymentDetail

| BO Attribute Name         | XML Schema                         | XML Attribute Name              | Required                                    |
|---------------------------|------------------------------------|---------------------------------|---------------------------------------------|
| id                        | N/A                                |                                 | N/A                                         |
| paymentGroupId            | N/A                                |                                 | N/A                                         |
| financialSystemOriginCode | ![Baseline][baseline_img] Baseline | fs_origin_cd                    | ![Add][add_img] Add Required, expect customer feed origin code<br>![Warning][warning_img] Consider validation. Or lookup from Customer Profile. |
| financialDocumentTypeCode | ![Baseline][baseline_img] Baseline | fdoc_typ_cd                     | ![Add][add_img] Add Required, expect 'PDP'.<br>![Warning][warning_img] Consider validation. Or set to constant after parse. |
| pymtOriginationCode       | ![Add][add_img] Add                | _pymt_origination_cd_           | ![Add][add_img] Add Required, expect customer feed origin code<br>![Warning][warning_img] Consider validation. Or lookup from Customer Profile. |
| custPaymentDocNbr         | ![Baseline][baseline_img] Baseline | source_doc_nbr                  | ![Baseline][baseline_img] Baseline Required |
| invoiceNbr                | ![Baseline][baseline_img] Baseline | invoice_nbr                     | ![Not Required][empty_img] Not Required     |
| invoiceDate               | ![Baseline][baseline_img] Baseline | invoice_date                    | ![Add][add_img] Add Required                |
| purchaseOrderNbr          | ![Baseline][baseline_img] Baseline | po_nbr                          | ![Not Required][empty_img] Not Required     |
| requisitionNbr            | ![Baseline][baseline_img] Baseline | req_nbr                         | ![Not Required][empty_img] Not Required     |
| customerInstitutionNumber | ![Baseline][baseline_img] Baseline | customer_institution_identifier | ![Not Required][empty_img] Not Required     |
| organizationDocNbr        | ![Baseline][baseline_img] Baseline | org_doc_nbr                     | ![Not Required][empty_img] Not Required     |
| netPaymentAmount          | ![Baseline][baseline_img] Baseline | net_payment_amt                 | ![Not Required][empty_img] Not Required, calculated if not supplied, validated if supplied | 
| origInvoiceAmount         | ![Baseline][baseline_img] Baseline | orig_invoice_amt                | ![Not Required][empty_img] Not Required, calculated if not supplied, validated if supplied |
| invTotDiscountAmount      | ![Baseline][baseline_img] Baseline | invoice_tot_discount_amt        | ![Not Required][empty_img] Not Required, zero if not supplied, validated if supplied     |
| invTotShipAmount          | ![Baseline][baseline_img] Baseline | invoice_tot_ship_amt            | ![Not Required][empty_img] Not Required, zero if not supplied, validated if supplied     |
| invTotOtherDebitAmount    | ![Baseline][baseline_img] Baseline | invoice_tot_other_debits        | ![Not Required][empty_img] Not Required, zero if not supplied, validated if supplied     |
| invTotOtherCreditAmount   | ![Baseline][baseline_img] Baseline | invoice_tot_other_credits       | ![Not Required][empty_img] Not Required, zero if not supplied, validated if supplied     |
| primaryCancelledPayment   | N/A                                |                                 | N/A                                         |


### PaymentAccountDetail

| BO Attribute Name  | XML Schema                         | XML Attribute Name | Required                                    |
|--------------------|------------------------------------|--------------------|---------------------------------------------|
| id                 | N/A                                |                    | N/A                                         |
| paymentDetailId    | N/A                                |                    | N/A                                         |
| accountNetAmount   | ![Baseline][baseline_img] Baseline | amount             | ![Baseline][baseline_img] Baseline Required |
| finChartCode       | ![Baseline][baseline_img] Baseline | coa_cd             | ![Add][add_img] Add Required                |
| accountNbr         | ![Baseline][baseline_img] Baseline | account_nbr        | ![Baseline][baseline_img] Baseline Required |
| subAccountNbr      | ![Baseline][baseline_img] Baseline | sub_account_nbr    | ![Not Required][empty_img] Not Required     |
| finObjectCode      | ![Baseline][baseline_img] Baseline | object_cd          | ![Baseline][baseline_img] Baseline Required |
| finSubObjectCode   | ![Baseline][baseline_img] Baseline | sub_object_cd      | ![Not Required][empty_img] Not Required     |      
| orgReferenceId     | ![Baseline][baseline_img] Baseline | org_ref_id         | ![Not Required][empty_img] Not Required     |
| projectCode        | ![Baseline][baseline_img] Baseline | project_cd         | ![Not Required][empty_img] Not Required     |


### PaymentNoteText
| BO Attribute Name   | XML Schema                         | XML Attribute Name | Required                                    |
|---------------------|------------------------------------|--------------------|---------------------------------------------|
| id                  | N/A                                |                    | N/A                                         |
| paymentDetailId     | N/A                                |                    | N/A                                         |
| customerNoteLineNbr | N/A                                |                    | N/A                                         |
| customerNoteText    | ![Baseline][baseline_img] Baseline | payment_text       | ![Not Required][empty_img] Not Required     |


