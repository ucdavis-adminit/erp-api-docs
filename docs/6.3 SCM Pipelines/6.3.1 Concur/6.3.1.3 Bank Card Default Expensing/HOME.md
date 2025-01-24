# 6.3.1.3 Bank Card Default Expensing

### Overview

For the US Bank Travel and Purchasing card programs, we receive a file from the bank with all the transactions since the last file.  These expenses are deducted from the University's bank account immediately.  As such, the expenses must be assigned to the departments whose employees control the cards.  This process uses the default accounting string assigned to each card within the Concur application to charge the department using a default account code.

When a traveller or employee reconciles the expenses, the amounts are transferred from this chartstring to the one specified in the expense report.

> See Section 6.3.1.A Vendor File Specifications for the US Bank file format.

> See Section 6.3.1.C for KFS implementation design and implementation code.

### High Level Flow

1. Receive the file from the bank and upload into the integration system.
2. Rebuild the file into a usable data structure from the different line types.
   1. E.g., transactions have card numbers, but no employee ID.  Card Accounts may not be of a type to process.  We need all this information to know whether to and how to process a transaction.
3. For each record, look up the card information in the Concur data extract by the employee ID from the US Bank file and the last 4 digits of the card number as well as the card program code if known.  Get the default account code from that record.
   1. If no match, then use a default segment string provided by SCM.
4. Create a transaction record for GL from the transaction using the default account and a per-card-program natural account.
5. Generate a single offset line covering all transactions to the cash account used to pay the bank using a segment string provided by SCM.
6. Validate the GL segment data.
7. Replace any invalid strings with the kickout segment string provided by SCM.
8. Attach all required attributes for FBDI processing.
9. Submit journal to the GL-PPM validated process for submission.


### Implementation Notes

The parsing of the file will likely take a custom groovy processor.  The existing logic can be reviewed in the implementation references section.  However, a potential implementation of this could be done as follows:

1. **Initial Parsing**
   1. Read in the flowfile contents to a buffer in a Scripted processor.
      1. This is not a record-based processor, so we need to process it as text.  If NiFi has a way to stream the flowfile into memory line-by-line, that would be best to avoid excessive use of ram.
   2. Read through and parse the records which contain the card information, save off the records with the appropriate card type into an in-memory structure.
   3. Read through and parse the records which contain the cardholder information.  Add the cardholder information to the previous in-memory structure.
   4. Read through and parse the transaction records.  Discard any which are not referenced in the earlier structure.  Merge the card/cardholder information onto the transaction data.
   5. Write out each transaction record as a line to the output.  Each line would have all the information needed about the transaction, the card, and cardholder for future processing.
   6. Attach the schema name to the file to use in further processing.
2. **Enrichment**
   1. Parition the data by the card and cardholder information.
   2. Perform a lookup on each flowfile's card information to get the default expense segment string from the Concur data extract card account table.
   3. For unmatched records, attach a default expense segment string.
   4. Update each transaction in the flowfile with the looked up or defaulted segment string.
   5. Merge the flowfiles (defragment) before further processing.
3. **Conversion**
   1. Perform the operations needed to convert the transactions into the format needed for the GL-PPM process.
   2. Generate an offset line using a segment string provided by SCM.

### NOTES: Output Report Requirements

> From Eddie:  (not to be duplicated - to show the types of information we need to collect during processing.)

```txt
Thanks, Jonathan. Other than potential Job ID codes or time of receipt, I'm just copying from the current email what I believe would be critical for us to show:

US Bank File Summary: usbank20220831.043740.txt

        ---------------------------------------- : ------------
        Total Transactions in File               :          169
        Processed Transactions                   :          168
        Processed Transaction Total              :    45,332.34
        ---------------------------------------- : ------------
        Duplicate Transactions Ignored           :            1 (curious to know what these are)

Account Assignment Summary

                                                           :        Count     $ Amount
        -------------------------------------------------- : ------------ ------------
        Total Processed Records                            :          168    45,332.34
        Total Failed Records                               :            0         0.00
        Processed Using Card-Level Account                 :          163    44,659.15
        Processed Using Central Office Account             :            5       673.19
        -------------------------------------------------- : ------------ ------------


Account Assignment Error Messages:
BAD CARD ACCOUNT: 3-HUMPH19 failed KFS validation on Employee/Card: 10228591/4911
BAD CARD ACCOUNT: Clearing account code for employee/card# was blank: 10241762/9975
BAD CARD ACCOUNT: null failed KFS validation on Employee/Card: 10241762/9975
BAD CARD ACCOUNT: Clearing account code for employee/card# was blank: 10246716/6139
BAD CARD ACCOUNT: null failed KFS validation on Employee/Card: 10246716/6139
BAD CARD ACCOUNT: 3-TNEDMAJ. failed KFS validation on Employee/Card: 10546654/5105
BAD CARD ACCOUNT: 3-TNEDMAJ. failed KFS validation on Employee/Card: 10546654/5105
```


### Travel Card Data Mapping

!> This is incomplete as SCM is still obtaining the existing file for this and PCard for review to determine what elements need to be mapped.

The clearing account field on Concur will contain Entity-Fund-Department-Purpose.  This is not the usual ordering the the segment fields, but is required due to length limitations in the column which will not allow the account to be included.

The account will be coded into the pipeline configuration as it is a constant based on the card type (Travel Card, Purchasing Card, etc).

#### Header Field Mappings

| GL-PPM Field              | Value                                 | Notes                                |
| ------------------------- | ------------------------------------- | ------------------------------------ |
| **Request Header Fields** |                                       |                                      |
| `consumerId`              | UCD Concur                            |                                      |
| `boundaryApplicationName` | US Bank Travel Card Default Expensing |                                      |
| `consumerReferenceId`     | USBANKTC_yyyyMMdd                     | Today's date                         |
| `consumerTrackingId`      | USBANKTC_yyyyMMddHHmmss               | If timestamp on input file, use that |
| `consumerNotes`           | (unset)                               |                                      |
| `requestSourceType`       | sftp                                  |                                      |
| `requestSourceId`         | (**TBD**)                             |                                      |
| **Journal Header Fields** |                                       |                                      |
| `journalSourceName`       | UCD Concur                            |                                      |
| `journalCategoryName`     | UCD Recharges                         |                                      |
| `journalName`             | US Bank Travel Card yyyy-MM-dd        | (**TBD**)                            |
| `journalDescription`      | (unset)                               |                                      |
| `journalReference`        | US Bank Travel Card yyyy-MM-dd        | (**TBD**)                            |
| `accountingDate`          | (today)                               |                                      |
| `accountingPeriodName`    | (unset)                               |                                      |

#### Transaction Line Mapping

| GL-PPM Field                | Value                          | Notes     |
| --------------------------- | ------------------------------ | --------- |
| **Line Fields**             |                                |           |
| `debitAmount`               | (transaction amount)           | if debit  |
| `creditAmount`              | (transaction amount)           | if credit |
| `externalSystemIdentifier`  | transactionId                  |           |
| `externalSystemReference`   | merchantName                   |           |
| `ppmComment`                | (unset)                        |           |
| **GL Segment Fields**       |                                |           |
| `entity`                    | (from card clearing account)   |           |
| `fund`                      | (from card clearing account)   |           |
| `department`                | (from card clearing account)   |           |
| `account`                   | (**TBD**)                      |           |
| `purpose`                   | (from card clearing account)   |           |
| `program`                   | 000                            |           |
| `glProject`                 | 0000000000                     |           |
| `activity`                  | 000000                         |           |
| `interEntity`               | 0000                           |           |
| `flex1`                     | 000000                         |           |
| `flex2`                     | 000000                         |           |
| **PPM Segment Fields**      |                                |           |
| `ppmProject`                | (unset)                        |           |
| `task`                      | (unset)                        |           |
| `organization`              | (unset)                        |           |
| `expenditureType`           | (unset)                        |           |
| `award`                     | (unset)                        |           |
| `fundingSource`             | (unset)                        |           |
| **Internal Control Fields** |                                |           |
| `lineType`                  | glSegments                     |           |
| **GLIDe Fields**            |                                |           |
| `lineDescription`           | employeeId '-'  cardholderName |           |
| `journalLineNumber`         | line number from input file    |           |
| `transactionDate`           | (transaction date)             |           |
| `udfNumeric1`               | (**TBD**)                      |           |
| `udfNumeric2`               | (**TBD**)                      |           |
| `udfNumeric3`               | (**TBD**)                      |           |
| `udfDate1`                  | transactionDate                |           |
| `udfDate2`                  | postingDate                    |           |
| `udfString1`                | cardholderName                 |           |
| `udfString2`                | employeeId                     |           |
| `udfString3`                | cardNumLast4                   |           |
| `udfString4`                | merchantName                   |           |
| `udfString5`                | (**TBD**)                      |           |

#### Offset Line Mapping

This is the line which (usually) credits back to the cash offset account for the amounts expensed to departments.

!> **TODO**

| GL-PPM Field                | Value                          | Notes                            |
| --------------------------- | ------------------------------ | -------------------------------- |
| **Line Fields**             |                                |                                  |
| `debitAmount`               | (transaction amount)           | if overall transaction credit    |
| `creditAmount`              | (transaction amount)           | if overall transaction credit    |
| `externalSystemIdentifier`  | transactionId                  |                                  |
| `externalSystemReference`   | merchantName                   |                                  |
| `ppmComment`                | (unset)                        |                                  |
| **GL Segment Fields**       |                                |                                  |
| `entity`                    | (from card clearing account)   | From provided offset chartstring |
| `fund`                      | (from card clearing account)   |                                  |
| `department`                | (from card clearing account)   |                                  |
| `account`                   | (**TBD**)                      |                                  |
| `purpose`                   | (from card clearing account)   |                                  |
| `program`                   | 000                            |                                  |
| `glProject`                 | 0000000000                     |                                  |
| `activity`                  | 000000                         |                                  |
| `interEntity`               | 0000                           |                                  |
| `flex1`                     | 000000                         |                                  |
| `flex2`                     | 000000                         |                                  |
| **PPM Segment Fields**      |                                |                                  |
| `ppmProject`                | (unset)                        |                                  |
| `task`                      | (unset)                        |                                  |
| `organization`              | (unset)                        |                                  |
| `expenditureType`           | (unset)                        |                                  |
| `award`                     | (unset)                        |                                  |
| `fundingSource`             | (unset)                        |                                  |
| **Internal Control Fields** |                                |                                  |
| `lineType`                  | glSegments                     |                                  |
| **GLIDe Fields**            |                                |                                  |
| `lineDescription`           | employeeId '-'  cardholderName |                                  |
| `journalLineNumber`         |                                |                                  |
| `transactionDate`           | (file date) transactionDate    |                                  |
| `udfNumeric1`               | (**TBD**)                      |                                  |
| `udfNumeric2`               | (**TBD**)                      |                                  |
| `udfNumeric3`               | (**TBD**)                      |                                  |
| `udfDate1`                  | postingDate                    |                                  |
| `udfDate2`                  | (**TBD**)                      |                                  |
| `udfString1`                | cardholderName                 |                                  |
| `udfString2`                | employeeId                     |                                  |
| `udfString3`                | cardNumLast4                   |                                  |
| `udfString4`                | merchantName                   |                                  |
| `udfString5`                | (**TBD**)                      |                                  |


### Data Flow Design

#### 1.Bank Card Default Data Extract

1. Receive the file from the bank and upload into the integration system via  Kafka with topic: `in.#{instance_id}.sftp.dat.concurCard`.
2. In order to parse bank file we will use ExecuteGroovyScript. In a script we will reuse work that was done in java, and at the end of processing we will have following flow:

    ```txt
    [
    {
        "transactionTypeCode": "10",
        "transactionId": "24326885286206166100650-1",
        "cardholderName": "STEVE MCELWYN",
        "transactionDate": "2005-10-13T00:00:00+0000",
        "cardNumLast4": "9999",
        "merchantName": "URBAN LAND INSTITUTE",
        "transactionDescription": "VZMA0CF3FCE7",
        "employeeId": "943306440",
        "cardIssueDate": "2005-08-03T00:00:00+0000",
        "transactionAmount": 190.0,
        "employeeName": null,
        "employeeDepartmentCode": null,
        "postingDate": "2005-10-14T00:00:00+0000",
        "departmentalChartAccount": null
    },
    {
        "transactionTypeCode": "10",
        "transactionId": "24492795286148000010076-2",
        "cardholderName": "STEVE MCELWYN",
        "transactionDate": "2005-10-13T00:00:00+0000",
        "cardNumLast4": "9999",
        "merchantName": "KOSMAN SUPPLY INC",
        "transactionDescription": "",
        "employeeId": "943306440",
        "cardIssueDate": "2005-08-03T00:00:00+0000",
        "transactionAmount": 489.48,
        "employeeName": null,
        "employeeDepartmentCode": null,
        "postingDate": "2005-10-14T00:00:00+0000",
        "departmentalChartAccount": null
    },
    {
        "transactionTypeCode": "10",
        "transactionId": "24445005307281268039409-1",
        "cardholderName": "STEVE MCELWYN",
        "transactionDate": "2005-11-02T00:00:00+0000",
        "cardNumLast4": "9999",
        "merchantName": "FEDEX KINKO'S #5160",
        "transactionDescription": "pr06re0004",
        "employeeId": "943306440",
        "cardIssueDate": "2005-08-03T00:00:00+0000",
        "transactionAmount": 180.0,
        "employeeName": null,
        "employeeDepartmentCode": null,
        "postingDate": "2005-11-03T00:00:00+0000",
        "departmentalChartAccount": null
    },
    {
        "transactionTypeCode": "10",
        "transactionId": "24492795311148000010026-1",
        "cardholderName": "STEVE MCELWYN",
        "transactionDate": "2005-11-07T00:00:00+0000",
        "cardNumLast4": "9999",
        "merchantName": "KOSMAN SUPPLY INC",
        "transactionDescription": "",
        "employeeId": "943306440",
        "cardIssueDate": "2005-08-03T00:00:00+0000",
        "transactionAmount": 92.3,
        "employeeName": null,
        "employeeDepartmentCode": null,
        "postingDate": "2005-11-08T00:00:00+0000",
        "departmentalChartAccount": null
    }
    ]
    ```

3. Run flow thru Lookup Record to obtain departmental default account. Use `Lookup Service - Concur Clearing Account` with key set to: `concat(/employeeId,'_${payment.type}_',/cardNumLast4)` to obtain default account. Default account will be added to each json under defaultDepartmentalAccount.
4. Run flow thru `Query Record` processor named: `Generate GL Flattened Records` to create necessarily parts of gl journal. We will have to create only gl part for journal.

    ```txt
    SELECT
    ROW_NUMBER() over() AS journalLineNumber, * FROM (
    SELECT   '${consumer.id}' as consumerId
    , '${boundary.system}' as boundaryApplicationName
    , '${consumer.ref.id}' as consumerReferenceId
    , '${consumer.tracking.id}' as consumerTrackingId
    , '${data.source}' as requestSourceType
    , 'journal.USBANKTC_' || '${now():format('yyyyMMddHHmmss')}' || '.json' as requestSourceId

    // Journal Header Fields
    , '${journal.source}' as journalSourceName
    , '${journal.category}' as journalCategoryName
    , '${journal.name}' as journalName
    //,  postingDate ||'_Journal'  as journalReference
    , '${journal.reference}' as journalReference
    ,  '${accounting.date}' as accountingDate
    ,  CASE  
        WHEN CAST(transactionAmount AS DOUBLE) > 0 THEN  CAST(transactionAmount AS DOUBLE)
        ELSE null
    END AS debitAmount
    ,  CASE 
        WHEN CAST(transactionAmount AS DOUBLE) <= 0 THEN CAST(transactionAmount * (-1) AS DOUBLE)
        ELSE null
    END as creditAmount
    , transactionId as externalSystemIdentifier
    , merchantName as externalSystemReference
    , CAST (null AS VARCHAR)  as ppmComment
    // GL Segment Fields
    , CASE
        WHEN (defaultDepartmentalAccount IS NOT NULL AND defaultDepartmentalAccount <> '') THEN SUBSTRING(defaultDepartmentalAccount,1,4)
        ELSE '${concur.default.chartstring:getDelimitedField(1,"-")}'
    END AS entity
    , CASE
        WHEN defaultDepartmentalAccount IS NOT NULL AND defaultDepartmentalAccount <> '' THEN SUBSTRING(defaultDepartmentalAccount,14,5)
        ELSE '${concur.default.chartstring:getDelimitedField(2,"-")}'
    END AS fund
    , CASE
        WHEN defaultDepartmentalAccount IS NOT NULL AND defaultDepartmentalAccount <> '' THEN SUBSTRING(defaultDepartmentalAccount,6,7)
        ELSE '${concur.default.chartstring:getDelimitedField(3,"-")}'
    END AS department

    , CASE WHEN '${payment.type}' = 'PCRD' THEN '${concur.p.card.clearing.account}'
    ELSE '${concur.t.card.clearing.account}'
    END as account
    , CASE
        WHEN defaultDepartmentalAccount IS NOT NULL AND defaultDepartmentalAccount <> '' THEN SUBSTRING(defaultDepartmentalAccount,20,2)
        ELSE '${concur.default.chartstring:getDelimitedField(5,"-")}'
    END AS purpose
    , CAST('0000000000' AS VARCHAR) as glProject
    , CAST( '000' AS VARCHAR ) as program
    , CAST('000000' AS VARCHAR ) as activity
    , '0000' as interEntity
    , '000000' as flex1
    , '000000' as flex2
    // PPM Segment Fields
    , CAST(NULL AS VARCHAR) as ppmProject
    , CAST(NULL AS VARCHAR) as task
    , CAST(NULL AS VARCHAR) as organization
    , CAST(NULL AS VARCHAR) as expenditureType
    , CAST(NULL AS VARCHAR) as award
    , CAST(NULL AS VARCHAR)  as fundingSource
    , 'glSegments' as lineType
    ,  EmployeeId || '-' || cardholderName as lineDescription
    , transactionDate as transactionDate

    //, CAST(ReportKey_20 AS ) as udfNumeric1
    , transactionDate as udfDate1
    , postingDate  as udfDate2

    , cardholderName as udfString1
    , EmployeeId as udfString2
    , cardNumLast4 as udfString3
    , merchantName as udfString4
    , 'CorpCard' as udfString5
    FROM FLOWFILE

    UNION ALL
    SELECT   '${consumer.id}' as consumerId
    , '${boundary.system}' as boundaryApplicationName
    , '${consumer.ref.id}' as consumerReferenceId
    , '${consumer.tracking.id}' as consumerTrackingId
    , '${data.source}' as requestSourceType
    , 'journal.USBANKTC_' || '${now():format('yyyyMMddHHmmss')}' || '.json' as requestSourceId

    // Journal Header Fields
    , '${journal.source}' as journalSourceName
    , '${journal.category}' as journalCategoryName
    , '${journal.name}' as journalName
    // ,  postingDate ||'_Journal'  as journalReference
    , '${journal.reference}' as journalReference
    ,  '${accounting.date}' as accountingDate
    ,  CASE  
        WHEN CAST(transactionAmount AS DOUBLE) < 0 THEN  CAST(transactionAmount * (-1) AS DOUBLE)
        ELSE null
    END AS debitAmount
    ,  CASE 
        WHEN CAST(transactionAmount AS DOUBLE) >= 0 THEN CAST(transactionAmount AS DOUBLE)
        ELSE null
    END as creditAmount
    , transactionId as externalSystemIdentifier
    , merchantName as externalSystemReference
    , CAST (null AS VARCHAR)  as ppmComment
    // GL Segment Fields
    , '${concur.corpCard.clearing.chartstring:getDelimitedField(1,"-")}' AS entity
    , '${concur.corpCard.clearing.chartstring:getDelimitedField(2,"-")}' AS fund
    , '${concur.corpCard.clearing.chartstring:getDelimitedField(3,"-")}' AS department
    //, '${concur.corpCard.clearing.chartstring:getDelimitedField(4,"-")}' as account
    , CASE WHEN '${payment.type}' = 'PCRD' THEN '${concur.p.card.clearing.account}'
    ELSE '${concur.t.card.clearing.account}'
    END as account
    , '${concur.corpCard.clearing.chartstring:getDelimitedField(5,"-")}'AS purpose
    , CAST('0000000000' AS VARCHAR) as glProject
    , CAST( '000' AS VARCHAR ) as program
    , CAST('000000' AS VARCHAR ) as activity
    , '0000' as interEntity
    , '000000' as flex1
    , '000000' as flex2
    // PPM Segment Fields
    , CAST(NULL AS VARCHAR) as ppmProject
    , CAST(NULL AS VARCHAR) as task
    , CAST(NULL AS VARCHAR) as organization
    , CAST(NULL AS VARCHAR) as expenditureType
    , CAST(NULL AS VARCHAR) as award
    , CAST(NULL AS VARCHAR)  as fundingSource
    , 'glSegments' as lineType
    ,  EmployeeId || '-' || cardholderName as lineDescription
    , transactionDate as transactionDate

    //, CAST(ReportKey_20 AS ) as udfNumeric1
    , transactionDate  as udfDate1
    , postingDate  as udfDate2

    , cardholderName as udfString1
    , EmployeeId as udfString2
    , cardNumLast4 as udfString3
    , merchantName as udfString4
    , 'CorpCard' as udfString5
    FROM FLOWFILE
    ) AS TBL
    ORDER BY journalLineNumber
    ```

5. Run records thru `Validate Records`  process group:
   1. Validate records against schema for gl journal (must validate agains `in.#{instance_id}.internal.json.gl_journal_flattened-value`)
   2. Run records thru `Validate Gl Segments` to verify if each record is valid
   3. Replace invalid lines with kick out account
6. Calculate journal totals as groovy to obtain values for:  `journal.credits`, `journal.debits`, `gl.total`, `ppm.total`, `gl.count` and `ppm.count` and set them as attributes in order for gl-journal processing to work.

```txt
   def flowFile = session.get();
if(!flowFile) return;
try {
  def inputStream = session.read(flowFile);
  def journalData = new groovy.json.JsonSlurper().parse(inputStream);
  BigDecimal debitTotal  = new BigDecimal("0.00");
  BigDecimal creditTotal = new BigDecimal("0.00");
  BigDecimal glTotal     = new BigDecimal("0.00");
  BigDecimal ppmTotal    = new BigDecimal("0.00");
  def ppmCount    = 0;
  def glCount     = 0;

  journalData.each {
    if ( it.debitAmount ) debitTotal += BigDecimal.valueOf(it.debitAmount).setScale(2, BigDecimal.ROUND_HALF_UP);
    if ( it.creditAmount ) creditTotal += BigDecimal.valueOf(it.creditAmount).setScale(2, BigDecimal.ROUND_HALF_UP);
    if ( it.lineType == "ppmSegments" ) {
      if ( it.debitAmount ) ppmTotal += BigDecimal.valueOf(it.debitAmount).setScale(2, BigDecimal.ROUND_HALF_UP);
      if ( it.creditAmount ) ppmTotal -= BigDecimal.valueOf(it.creditAmount).setScale(2, BigDecimal.ROUND_HALF_UP);
      ppmCount++;
    } else {
      if ( it.debitAmount ) glTotal += BigDecimal.valueOf(it.debitAmount).setScale(2, BigDecimal.ROUND_HALF_UP);
      if ( it.creditAmount ) glTotal -= BigDecimal.valueOf(it.creditAmount).setScale(2, BigDecimal.ROUND_HALF_UP);
      glCount++;
    }
  }

  inputStream.close();
  flowFile = session.putAttribute(flowFile, 'journal.debits', debitTotal.setScale(2, BigDecimal.ROUND_HALF_UP).toString());
  flowFile = session.putAttribute(flowFile, 'journal.credits', creditTotal.setScale(2, BigDecimal.ROUND_HALF_UP).toString());
  flowFile = session.putAttribute(flowFile, 'gl.total', glTotal.setScale(2, BigDecimal.ROUND_HALF_UP).toString());
  flowFile = session.putAttribute(flowFile, 'ppm.total', ppmTotal.setScale(2, BigDecimal.ROUND_HALF_UP).toString());
  flowFile = session.putAttribute(flowFile, 'gl.count', glCount.toString());
  flowFile = session.putAttribute(flowFile, 'ppm.count', ppmCount.toString());
  session.transfer(flowFile, REL_SUCCESS);
} catch(e) {
  log.error("Error while totaling journal entries", e);
  session.transfer(flowFile, REL_FAILURE);
}
```

7. Don't have to provide kickout account - it is provided in consumer_mapping
8.  Feed into the validated input into an interim topic `in.<env>.internal.json.apPaymentRequest`
    1. Topic: `n.<env>.internal.json.gl_journal_validated`
    2. Headers: `.*`
    3. Kafka Key: `${kafka.key}`

### Questions


### Default Bank to gl-journal mapping


#### Header Field Mappings

| GL-PPM Field              | Value                                 | Notes                                |
| ------------------------- | ------------------------------------- | ------------------------------------ |
| **Request Header Fields** |                                       |                                      |
| `consumerId`              | UCD Concur                            |                                      |
| `boundaryApplicationName` | US Bank Travel Card Default Expensing |                                      |
| `consumerReferenceId`     | USBANKTC_yyyyMMdd                     | Today's date                         |
| `consumerTrackingId`      | USBANKTC_yyyyMMddHHmmss               | If timestamp on input file, use that |
| `consumerNotes`           | (unset)                               |                                      |
| `requestSourceType`       | sftp                                  |                                      |
| `requestSourceId`         | (**TBD**)                             |                                      |
| **Journal Header Fields** |                                       |                                      |
| `journalSourceName`       | UCD Concur                            |                                      |
| `journalCategoryName`     | UCD Recharges                         |                                      |
| `journalName`             | US Bank Travel Card yyyy-MM-dd        | (**TBD**)                            |
| `journalDescription`      | (unset)                               |                                      |
| `journalReference`        | US Bank Travel Card yyyy-MM-dd        | (**TBD**)                            |
| `accountingDate`          | (today)                               |                                      |
| `accountingPeriodName`    | (unset)                               |                                      |

#### Transaction Line Mapping

| GL-PPM Field                | Value                          | Notes     |
| --------------------------- | ------------------------------ | --------- |
| **Line Fields**             |                                |           |
| `debitAmount`               | (transaction amount)           | if debit  |
| `creditAmount`              | (transaction amount)           | if credit |
| `externalSystemIdentifier`  | transactionId                  |           |
| `externalSystemReference`   | merchantName                   |           |
| `ppmComment`                | (unset)                        |           |
| **GL Segment Fields**       |                                |           |
| `entity`                    | (from card clearing account)   |           |
| `fund`                      | (from card clearing account)   |           |
| `department`                | (from card clearing account)   |           |
| `account`                   | (**TBD**)                      |           |
| `purpose`                   | (from card clearing account)   |           |
| `program`                   | 000                            |           |
| `glProject`                 | 0000000000                     |           |
| `activity`                  | 000000                         |           |
| `interEntity`               | 0000                           |           |
| `flex1`                     | 000000                         |           |
| `flex2`                     | 000000                         |           |
| **PPM Segment Fields**      |                                |           |
| `ppmProject`                | (unset)                        |           |
| `task`                      | (unset)                        |           |
| `organization`              | (unset)                        |           |
| `expenditureType`           | (unset)                        |           |
| `award`                     | (unset)                        |           |
| `fundingSource`             | (unset)                        |           |
| **Internal Control Fields** |                                |           |
| `lineType`                  | glSegments                     |           |
| **GLIDe Fields**            |                                |           |
| `lineDescription`           | employeeId '-'  cardholderName |           |
| `journalLineNumber`         | line number from input file    |           |
| `transactionDate`           | (transaction date)             |           |
| `udfNumeric1`               | (**TBD**)                      |           |
| `udfNumeric2`               | (**TBD**)                      |           |
| `udfNumeric3`               | (**TBD**)                      |           |
| `udfDate1`                  | transactionDate                |           |
| `udfDate2`                  | postingDate                    |           |
| `udfString1`                | cardholderName                 |           |
| `udfString2`                | employeeId                     |           |
| `udfString3`                | cardNumLast4                   |           |
| `udfString4`                | merchantName                   |           |
| `udfString5`                | (**TBD**)                      |           |


### Outbound Flowfile Attributes

| Attribute Name                | Attribute Value               |
| ----------------------------- | ----------------------------- |
| `consumer.id`                 | UCD Concur                    |
| `data.source`                 | sftp                          |
| `accounting.date`             | ${now():format('yyyy-MM-dd')} |
| `gl.total`                    | (***calculate***)             |
| `ppm.total`                   | (***calculate***)             |
| `journal.source`              | UCD Concur                    |
| `journal.debits`              | (***calculate***)             |
| `glide.extract.enabled`       | Y                             |
| `glide.summarization.enabled` | Y                             |
 
### Sample Data

[ {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : 190.0,
  "creditAmount" : null,
  "externalSystemIdentifier" : "00000000000000000000001-1",
  "externalSystemReference" : "URBAN LAND INSTITUTE",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200002-SOMEONE ELSE",
  "journalLineNumber" : 1,
  "transactionDate" : "2005-10-13",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2005-10-13",
  "udfDate2" : "2020-02-07",
  "udfString1" : "SOMEONE ELSE",
  "udfString2" : "11200002",
  "udfString3" : "1234",
  "udfString4" : "URBAN LAND INSTITUTE",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : 489.48,
  "creditAmount" : null,
  "externalSystemIdentifier" : "00000000000000000000002-2",
  "externalSystemReference" : "KOSMAN SUPPLY INC",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200002-SOMEONE ELSE",
  "journalLineNumber" : 2,
  "transactionDate" : "2005-10-13",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2005-10-13",
  "udfDate2" : "2020-02-07",
  "udfString1" : "SOMEONE ELSE",
  "udfString2" : "11200002",
  "udfString3" : "1234",
  "udfString4" : "KOSMAN SUPPLY INC",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : 180.0,
  "creditAmount" : null,
  "externalSystemIdentifier" : "00000000000000000000003-1",
  "externalSystemReference" : "FEDEX KINKO'S #5160",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200002-SOMEONE ELSE",
  "journalLineNumber" : 3,
  "transactionDate" : "2005-11-02",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2005-11-02",
  "udfDate2" : "2020-02-07",
  "udfString1" : "SOMEONE ELSE",
  "udfString2" : "11200002",
  "udfString3" : "1234",
  "udfString4" : "FEDEX KINKO'S #5160",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : 92.3,
  "creditAmount" : null,
  "externalSystemIdentifier" : "00000000000000000000004-1",
  "externalSystemReference" : "KOSMAN SUPPLY INC",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200002-SOMEONE ELSE",
  "journalLineNumber" : 4,
  "transactionDate" : "2005-11-07",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2005-11-07",
  "udfDate2" : "2020-02-07",
  "udfString1" : "SOMEONE ELSE",
  "udfString2" : "11200002",
  "udfString3" : "1234",
  "udfString4" : "KOSMAN SUPPLY INC",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : 323.84,
  "creditAmount" : null,
  "externalSystemIdentifier" : "00000000000000000000005-1",
  "externalSystemReference" : "SOUTHWEST",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200003-YET ANOTHER CARDHOLDER",
  "journalLineNumber" : 5,
  "transactionDate" : "2005-10-13",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2005-10-13",
  "udfDate2" : "2020-02-07",
  "udfString1" : "YET ANOTHER CARDHOLDER",
  "udfString2" : "11200003",
  "udfString3" : "1212",
  "udfString4" : "SOUTHWEST",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : 1489.48,
  "creditAmount" : null,
  "externalSystemIdentifier" : "00000000000000000000006-2",
  "externalSystemReference" : "HILTON",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200005-IMA BAD ACCOUNT",
  "journalLineNumber" : 6,
  "transactionDate" : "2005-10-13",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2005-10-13",
  "udfDate2" : "2020-02-07",
  "udfString1" : "IMA BAD ACCOUNT",
  "udfString2" : "11200005",
  "udfString3" : "3434",
  "udfString4" : "HILTON",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : 8.0,
  "creditAmount" : null,
  "externalSystemIdentifier" : "00000000000000000000007-1",
  "externalSystemReference" : "DOS COYOTES",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200006-IDUNNO MY ACCOUNT",
  "journalLineNumber" : 7,
  "transactionDate" : "2005-11-02",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2005-11-02",
  "udfDate2" : "2020-02-07",
  "udfString1" : "IDUNNO MY ACCOUNT",
  "udfString2" : "11200006",
  "udfString3" : "5656",
  "udfString4" : "DOS COYOTES",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : 22.3,
  "creditAmount" : null,
  "externalSystemIdentifier" : "00000000000000000000008-1",
  "externalSystemReference" : "UBER",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200007-OLD CARDHOLDER",
  "journalLineNumber" : 8,
  "transactionDate" : "2005-11-07",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2005-11-07",
  "udfDate2" : "2020-02-07",
  "udfString1" : "OLD CARDHOLDER",
  "udfString2" : "11200007",
  "udfString3" : "7979",
  "udfString4" : "UBER",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : 58.31,
  "creditAmount" : null,
  "externalSystemIdentifier" : "00000000000000000000008-1",
  "externalSystemReference" : "WOODSTOCKS PIZZA",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200888-ANOTHER CARDHOLDER",
  "journalLineNumber" : 9,
  "transactionDate" : "2020-02-17",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2020-02-17",
  "udfDate2" : "2020-02-18",
  "udfString1" : "ANOTHER CARDHOLDER",
  "udfString2" : "11200888",
  "udfString3" : "8888",
  "udfString4" : "WOODSTOCKS PIZZA",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : 17.73,
  "creditAmount" : null,
  "externalSystemIdentifier" : "00000000000000000000008-1",
  "externalSystemReference" : "PANERA",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200777-EXPIRING CARDHOLDER",
  "journalLineNumber" : 10,
  "transactionDate" : "2020-02-16",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2020-02-16",
  "udfDate2" : "2020-02-18",
  "udfString1" : "EXPIRING CARDHOLDER",
  "udfString2" : "11200777",
  "udfString3" : "7777",
  "udfString4" : "PANERA",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : 3.65,
  "creditAmount" : null,
  "externalSystemIdentifier" : "00000000000000000000008-1",
  "externalSystemReference" : "PANERA",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200999-UNKNOWN CARDHOLDER",
  "journalLineNumber" : 11,
  "transactionDate" : "2020-02-16",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2020-02-16",
  "udfDate2" : "2020-02-18",
  "udfString1" : "UNKNOWN CARDHOLDER",
  "udfString2" : "11200999",
  "udfString3" : "9999",
  "udfString4" : "PANERA",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : null,
  "creditAmount" : 190.0,
  "externalSystemIdentifier" : "00000000000000000000001-1",
  "externalSystemReference" : "URBAN LAND INSTITUTE",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200002-SOMEONE ELSE",
  "journalLineNumber" : 12,
  "transactionDate" : "2005-10-13",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2005-10-13",
  "udfDate2" : "2020-02-07",
  "udfString1" : "SOMEONE ELSE",
  "udfString2" : "11200002",
  "udfString3" : "1234",
  "udfString4" : "URBAN LAND INSTITUTE",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : null,
  "creditAmount" : 489.48,
  "externalSystemIdentifier" : "00000000000000000000002-2",
  "externalSystemReference" : "KOSMAN SUPPLY INC",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200002-SOMEONE ELSE",
  "journalLineNumber" : 13,
  "transactionDate" : "2005-10-13",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2005-10-13",
  "udfDate2" : "2020-02-07",
  "udfString1" : "SOMEONE ELSE",
  "udfString2" : "11200002",
  "udfString3" : "1234",
  "udfString4" : "KOSMAN SUPPLY INC",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : null,
  "creditAmount" : 180.0,
  "externalSystemIdentifier" : "00000000000000000000003-1",
  "externalSystemReference" : "FEDEX KINKO'S #5160",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200002-SOMEONE ELSE",
  "journalLineNumber" : 14,
  "transactionDate" : "2005-11-02",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2005-11-02",
  "udfDate2" : "2020-02-07",
  "udfString1" : "SOMEONE ELSE",
  "udfString2" : "11200002",
  "udfString3" : "1234",
  "udfString4" : "FEDEX KINKO'S #5160",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : null,
  "creditAmount" : 92.3,
  "externalSystemIdentifier" : "00000000000000000000004-1",
  "externalSystemReference" : "KOSMAN SUPPLY INC",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200002-SOMEONE ELSE",
  "journalLineNumber" : 15,
  "transactionDate" : "2005-11-07",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2005-11-07",
  "udfDate2" : "2020-02-07",
  "udfString1" : "SOMEONE ELSE",
  "udfString2" : "11200002",
  "udfString3" : "1234",
  "udfString4" : "KOSMAN SUPPLY INC",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : null,
  "creditAmount" : 323.84,
  "externalSystemIdentifier" : "00000000000000000000005-1",
  "externalSystemReference" : "SOUTHWEST",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200003-YET ANOTHER CARDHOLDER",
  "journalLineNumber" : 16,
  "transactionDate" : "2005-10-13",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2005-10-13",
  "udfDate2" : "2020-02-07",
  "udfString1" : "YET ANOTHER CARDHOLDER",
  "udfString2" : "11200003",
  "udfString3" : "1212",
  "udfString4" : "SOUTHWEST",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : null,
  "creditAmount" : 1489.48,
  "externalSystemIdentifier" : "00000000000000000000006-2",
  "externalSystemReference" : "HILTON",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200005-IMA BAD ACCOUNT",
  "journalLineNumber" : 17,
  "transactionDate" : "2005-10-13",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2005-10-13",
  "udfDate2" : "2020-02-07",
  "udfString1" : "IMA BAD ACCOUNT",
  "udfString2" : "11200005",
  "udfString3" : "3434",
  "udfString4" : "HILTON",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : null,
  "creditAmount" : 8.0,
  "externalSystemIdentifier" : "00000000000000000000007-1",
  "externalSystemReference" : "DOS COYOTES",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200006-IDUNNO MY ACCOUNT",
  "journalLineNumber" : 18,
  "transactionDate" : "2005-11-02",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2005-11-02",
  "udfDate2" : "2020-02-07",
  "udfString1" : "IDUNNO MY ACCOUNT",
  "udfString2" : "11200006",
  "udfString3" : "5656",
  "udfString4" : "DOS COYOTES",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : null,
  "creditAmount" : 22.3,
  "externalSystemIdentifier" : "00000000000000000000008-1",
  "externalSystemReference" : "UBER",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200007-OLD CARDHOLDER",
  "journalLineNumber" : 19,
  "transactionDate" : "2005-11-07",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2005-11-07",
  "udfDate2" : "2020-02-07",
  "udfString1" : "OLD CARDHOLDER",
  "udfString2" : "11200007",
  "udfString3" : "7979",
  "udfString4" : "UBER",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : null,
  "creditAmount" : 58.31,
  "externalSystemIdentifier" : "00000000000000000000008-1",
  "externalSystemReference" : "WOODSTOCKS PIZZA",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200888-ANOTHER CARDHOLDER",
  "journalLineNumber" : 20,
  "transactionDate" : "2020-02-17",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2020-02-17",
  "udfDate2" : "2020-02-18",
  "udfString1" : "ANOTHER CARDHOLDER",
  "udfString2" : "11200888",
  "udfString3" : "8888",
  "udfString4" : "WOODSTOCKS PIZZA",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : null,
  "creditAmount" : 17.73,
  "externalSystemIdentifier" : "00000000000000000000008-1",
  "externalSystemReference" : "PANERA",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200777-EXPIRING CARDHOLDER",
  "journalLineNumber" : 21,
  "transactionDate" : "2020-02-16",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2020-02-16",
  "udfDate2" : "2020-02-18",
  "udfString1" : "EXPIRING CARDHOLDER",
  "udfString2" : "11200777",
  "udfString3" : "7777",
  "udfString4" : "PANERA",
  "udfString5" : "CorpCard"
}, {
  "consumerId" : "UCD Concur",
  "boundaryApplicationName" : "US Bank Purchasing Card Default",
  "consumerReferenceId" : "USBANKPC_2022-12-22",
  "consumerTrackingId" : "USBANKPC_20221222190932",
  "consumerNotes" : null,
  "requestSourceType" : "sftp",
  "requestSourceId" : "journal.USBANKTC_20221222190932.json",
  "journalSourceName" : "UCD Concur",
  "journalCategoryName" : "UCD Recharge",
  "journalName" : "US Bank Purchasing Card 2022-12-22",
  "journalDescription" : null,
  "journalReference" : "US Bank Purchasing Card 2022-12-22",
  "accountingDate" : "2022-12-22",
  "accountingPeriodName" : null,
  "debitAmount" : null,
  "creditAmount" : 3.65,
  "externalSystemIdentifier" : "00000000000000000000008-1",
  "externalSystemReference" : "PANERA",
  "ppmComment" : null,
  "entity" : "3110",
  "fund" : "99U99",
  "department" : "SCDS000",
  "account" : "238590",
  "purpose" : "80",
  "glProject" : "0000000000",
  "program" : "000",
  "activity" : "000000",
  "interEntity" : "0000",
  "flex1" : "000000",
  "flex2" : "000000",
  "ppmProject" : null,
  "task" : null,
  "organization" : null,
  "expenditureType" : null,
  "award" : null,
  "fundingSource" : null,
  "lineType" : "glSegments",
  "lineDescription" : "11200999-UNKNOWN CARDHOLDER",
  "journalLineNumber" : 22,
  "transactionDate" : "2020-02-16",
  "udfNumeric1" : null,
  "udfNumeric2" : null,
  "udfNumeric3" : null,
  "udfDate1" : "2020-02-16",
  "udfDate2" : "2020-02-18",
  "udfString1" : "UNKNOWN CARDHOLDER",
  "udfString2" : "11200999",
  "udfString3" : "9999",
  "udfString4" : "PANERA",
  "udfString5" : "CorpCard"
} ]