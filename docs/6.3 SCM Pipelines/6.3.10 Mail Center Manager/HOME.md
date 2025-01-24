# 6.3.10 Mail Center Manager

### Overview

Link to Functional Spec: <https://ucdavis.app.box.com/file/948480655452>

Mail Center Manager (MCM) is the software used in conjunction with postage metering machines to add postage to outgoing US Mail pieces for UCD and UCDH campuses.  The system is utilized on premise by Senior Mail Processors.  Oracle GL chartstring information will be maintained within the MCM software and associated with a short code.  The maintenance of the GL chartstrings will be performed by Mail Services Supervisors.

Customers submit physical mail pieces with a short code noted above the return address. This code is entered by the Mail Processor and postage is expended.  The value and type of postage is recorded in the software as a transaction against short code provided by customer.

Monthly, these transactions will be downloaded and processed by the integration infrastructure.  At this time, surcharge transactions will be added to support Mail Services operations.  The extract will join against the control table which interprets the shortcodes into GL Segment strings.  These will be used to determine the cost center segments when loaded into Oracle Financial System.

### General Process Flow

1. Monthly, extract the new transactions from the MCM database.
2. Reformat the lines into the flattened GL format required by the GL-PPM Line validation pipeline.
3. Generate surcharge revenue summary transaction for the month.
   1. Transactions should only be included in the total if they are marked as such.
4. Validate the GL segments on each line.  Replace with the kickout chartstring if any required segment is invalid.
5. Publish the resulting journal to the middle stage of the GL-PPM Inbound pipeline.

### Logical Integration Flow

1. Run a query to extract the new transactions from the MCM database.  This should run for a given prior period of time.  The time range for execution should be configurable in addition to automatically determined to allow for recovery if a job fails.
2. (check if needed) Save the extract to the integration database for generating reports or extract to the reporting database.  (Or just route to be saved to the reporting database.)
3. Use transform processors to restructure the extract into the flattened GL format required by the GL-PPM Line validation pipeline.  Some values from the input will be placed in GLIDe attributes.
4. Run the lines through the GL and PPM validation components.  For any lines that are invalid, replace the segments with the kickout chartstring.
5. Add surcharge transactions for lines which require them.  There is a flag on the entries which indicates this.
6. Publish the resulting journal to the middle stage of the GL-PPM Inbound pipeline.


### Data Flow Design

#### 1. MCM Data Extract

On a daily basis, extract the data from MDM for the previous day for conversion into a GL Journal.  MCM uses a SQL server database and two master schemas.  One schema holds the campus bulk mail expenses (MCMG2) and the other holds the UCDH expenses (MCMG3).  These should be processed seprately, but can be extracted from their schemas at the same time.

1. Daily, calculate the date to run for and attach as a attributes on a flowfile.  (`GenerateFlowFile`)
   1. `extract.start.date` = 'YYYY-MM-DD'
   2. `extract.end.date` = 'YYYY-MM-DD'
   3. _Note: An alternate generator can be created to inject arbitrary dates in the case that data is missed or needs to be re-processed._
2. Pull all transactions between the given dates from the MCM database per the query below. (`QueryDatabaseTable`)
   1. There will be two of these processors connected to the above generator.  These will run in parallel and will each extract the data from one of the two schemas.
3. Set an attribute on the flow file to identify the source of the data (campus or UCDH).  (`UpdateAttribute`)
4. Merge the flows back together into the data conversion steps below.  (Keep the flowfiles separate.)

#### 2. Update Pipeline request Table

For each job we would insert the status in pipeline request table.

1. Add property key as pipeline_insert_sql and value as below. (`UpdateAttribute`)

```sql
INSERT INTO #{int_db_api_schema}.pipeline_request
( source_request_type, source_request_id, consumer_id, request_date_time, request_status )
VALUES
( 'sftp', '${source.id}', 'UCD Bulk Mail Recharges', CURRENT_TIMESTAMP, 'INPROCESS' )
```

2. Run the above query using `PutSQL` processor.

| Attribute Key             | Attribute Value         |
| ------------------------- | ----------------------- |
| JDBC Connection Pool - DB | Postgres - Integrations |
| SQL Statement             | ${pipeline_insert_sql}  |

1. Add retry logic for any failures.

#### 3. Mail Center Manager logical NiFi flow

1. Extract the mail data using the below configurations - (`ExecuteSQL`)

    a. Database Connection Pooling Service : DB - MSSQL - CFO

    b. SQL select query :

```sql
SELECT          main.machine_key_vc + '00' + Cast(main.trans_id AS VARCHAR) AS transaction_id,
                acct.acct_number1_vc                                        AS segment_string,
                acct.acct_name1_vc                                          AS account_name,
                LEFT(COALESCE(acct.acct_group_vc,'S'),1)                    AS surcharge_flag,
                main.carrier_id                                             AS carrier_id,
                carrier.carriername                                         AS carrier_name,
                CASE
                                WHEN main.number_of_pieces_in <> 0 THEN Abs(main.number_of_pieces_in)
                                ELSE 1
                END AS num_pieces,
                (main.total_charges_mn /
                CASE
                                WHEN main.number_of_pieces_in <> 0 THEN Abs(main.number_of_pieces_in)
                                ELSE 1
                END)                    AS base_rate,
                main.total_charges_mn   AS total_charges,
                main.meter_date_time_dt AS trans_date_time
FROM            ${mcm.schema.name}.dbo.transaction_main_t main
JOIN            ${mcm.schema.name}.dbo.transaction_account_t acct
ON              acct.trans_id = main.trans_id
JOIN            ${mcm.schema.name}.dbo.carrier_info_t carrier
ON              carrier.carriernumber = main.carrier_id
LEFT OUTER JOIN ${mcm.schema.name}.dbo.transaction_flags_t flags
ON              flags.trans_id = main.trans_id
WHERE           CONVERT( date, main.meter_date_time_dt ) BETWEEN '${strt_date}' AND '${end_date}'
                -- Only process S and N type billings
AND             LEFT(COALESCE(acct.acct_group_vc,'S'),1) IN ('S','N')
                -- Excluded voided transactions
AND             isnull(flags.void_bt,0) != 1
ORDER BY        transaction_id
```

2. Convert the biling ID to segments (`LookupRecord`)

| Attribute Key  | Attribute Value                                 |
| -------------- | ----------------------------------------------- |
| Record Reader  | Reader - Avro - Use Embedded Schema             |
| Record Writer  | Writer - Avro - Inherit and Embed               |
| Lookup Service | LookupService - SQL - KFS Billing ID Conversion |
| key            | /segment_string                                 |

1. Connect the output of the above success connection to two processors.

2. First connection is routed to a `QueryRecord` processor to find the segment Stings < 10 and terminate the connection.

    ```sql
      SELECT *
      FROM   flowfile
      WHERE  Char_length(segment_string) < 10
    ```

3. Set Header Props as Attributes. (`UpdateAttribute`)

| Attribute Key           | Attribute Value                                         |
| ----------------------- | ------------------------------------------------------- |
| accountingDate          | ${now():toNumber():format('yyyy-MM-dd')}                |
| accountingPeriodName    | ${literal('')}                                          |
| boundaryApplicationName | Mail Services MCM                                       |
| consumerId              | UCD Bulk Mail Recharges                                 |
| consumerNotes           | ${literal('')}                                          |
| consumerReferenceId     | \${source}_${now():toNumber():format('yyyyMMdd')}       |
| consumerTrackingId      | \${source}_${now():toNumber():format('yyyyMMddHHmmss')} |
| externalSystemReference | ${literal('')}                                          |
| journalCategoryName     | UCD Recharge                                            |
| journalDescription      | ${literal('')}                                          |
| journalName             | \${source} Mail Services ${strt_date} to ${end_date}    |
| journalReference        | \${source} Mail Services ${strt_date} to ${end_date}    |
| journalSourceName       | UCD Bulk Mail Recharges                                 |
| requestSourceId         | ${source.id}                                            |
| requestSourceType       | sftp                                                    |

6. Split one record to each flow file. (`SplitAvro`)
7. Convert each acro record to json. (`ConvertAvroToJSON`)
8. Pull all Record Fields to Attributes. (`ExecuteGroovyScript`)

  ```groovy
  import org.apache.commons.io.IOUtils
  import java.nio.charset.*
  def flowFile = session.get();
  if (flowFile == null) {
      return;
  }
  def slurper = new groovy.json.JsonSlurper()
  def attrs = [:] as Map<String,String>
  session.read(flowFile,
      { inputStream ->
          def text = IOUtils.toString(inputStream, StandardCharsets.UTF_8)
          def obj = slurper.parseText(text)
          obj.each {k,v ->
             attrs[k] = v.toString()
          }
      } as InputStreamCallback)
  flowFile = session.putAllAttributes(flowFile, attrs)
  session.transfer(flowFile, REL_SUCCESS)
  ```

9. Create line attributes. (`UpdateAttribute`)

| Attribute Key            | Attribute Value                                                        |
| ------------------------ | ---------------------------------------------------------------------- |
| debitAmount              | ${total_charges:toDecimal():multiply(100):math("round"):divide(100.0)} |
| externalSystemIdentifier | ${transaction_id:substring(0,10)}                                      |
| journalLineNumber        | ${fragment.index}                                                      |
| kickout.chartstring      | ${#{'MCM Kickout Chartstring'}}                                        |
| lineDescription          | ${carrier_name}                                                        |
| lineType                 | glSegments                                                             |
| markup_amount            | 0.00                                                                   |
| ppmComment               | ${carrier_name}                                                        |
| transactionDate          | ${trans_date_time:substring(0,10)}                                     |
| udfDate1                 | ${trans_date_time:substring(0,10)}                                     |
| udfNumeric1              | ${num_pieces}                                                          |
| udfNumeric2              | ${base_rate}                                                           |
| udfString1               | ${segment_string:getDelimitedField(3,'-')}                             |
| udfString2               | ${carrier_id}                                                          |
| udfString3               | ${transaction_id:substring(0,50)}                                      |
| udfString4               | ${surcharge_flag}                                                      |
| udfString5               | ${segment_string:substring(0,50)}                                      |

10. Round the markup amount. (`UpdateAttribute`)

| Attribute Key | Attribute Value                                                        |
| ------------- | ---------------------------------------------------------------------- |
| markup_amount | ${markup_amount:toDecimal():multiply(100):math("round"):divide(100.0)} |

11.  Add markup amount.  (`UpdateAttribute`)

| Attribute Key | Attribute Value                        |
| ------------- | -------------------------------------- |
| debitAmount   | \${debitAmount:plus(${markup_amount})} |

12. Rebuild content from attributes. (`AttributesToJSON`)

| Attribute Key   | Attribute Value                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Attributes List | consumerId, boundaryApplicationName, consumerReferenceId, consumerTrackingId, consumerNotes, requestSourceType, requestSourceId, journalSourceName, journalCategoryName, journalName, journalDescription, journalReference, accountingDate, accountingPeriodName, debitAmount, creditAmount, externalSystemIdentifier, externalSystemReference, ppmComment, entity, fund, department, account, purpose, glProject, program, activity, interEntity, flex1, flex2, ppmProject, task, organization, expenditureType, award, fundingSource, lineType, lineDescription, journalLineNumber, transactionDate, udfNumeric1, udfNumeric2, udfNumeric3, udfDate1, udfDate2, udfString1, udfString2, udfString3, udfString4, udfString5, markup_amount |
| Destination     | flowfile-content                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |

13. Add gl flattened schema name. (`UpdateAttribute`)

| Attribute Key | Attribute Value                                            |
| ------------- | ---------------------------------------------------------- |
| schema.name   | in.#{instance_id}.internal.json.gl_journal_flattened-value |

14. Merge the flowfiles to one. (`MergeRecord`)

| Attribute Key  | Attribute Value                      |
| -------------- | ------------------------------------ |
| Record Reader  | Reader - JSON - Infer Schema         |
| Record Writer  | Writer - JSON Array - Inherit Schema |
| Merge Strategy | Defragment                           |

15. Assign unique id to the flow file. (`UpdateAttribute`)

| Attribute Key | Attribute Value |
| ------------- | --------------- |
| uniqueID      | ${UUID()}       |

16. Generate passthru and markup offsets

| Attribute Key | Attribute Value                   |
| ------------- | --------------------------------- |
| Record Reader | Reader - JSON - Infer Schema      |
| Record Writer | Writer - JSON Array - Schema Name |

Records With Offsets:
```sql
-- Pull all records from the flow file
SELECT
  consumerId
, boundaryApplicationName
, consumerReferenceId
, consumerTrackingId
, requestSourceType
, requestSourceId
, journalSourceName
, journalCategoryName
, journalName
, journalReference
, accountingDate
, debitAmount
, NULL AS creditAmount
, externalSystemIdentifier
, entity
, fund
, department
, account
, purpose
, glProject
, program
, activity
, interEntity
, flex1
, flex2
, lineType
, lineDescription
, transactionDate
, udfDate1
, ppmProject
, task
, organization
, expenditureType
, award
, fundingSource
, ppmComment
, udfNumeric1
, udfNumeric2
, udfString1
, udfString2
, udfString3
, udfString4
, udfString5
FROM FLOWFILE
-- Add the pass through expenses line
UNION ALL
SELECT
  CAST(consumerId              AS VARCHAR) AS consumerId
, CAST(boundaryApplicationName AS VARCHAR) AS boundaryApplicationName
, CAST(consumerReferenceId     AS VARCHAR) AS consumerReferenceId
, CAST(consumerTrackingId      AS VARCHAR) AS consumerTrackingId
, CAST(requestSourceType       AS VARCHAR) AS requestSourceType
, CAST(requestSourceId         AS VARCHAR) AS requestSourceId
, CAST(journalSourceName       AS VARCHAR) AS journalSourceName
, CAST(journalCategoryName     AS VARCHAR) AS journalCategoryName
, CAST(journalName             AS VARCHAR) AS journalName
, CAST(journalReference        AS VARCHAR) AS journalReference
, CAST(accountingDate          AS VARCHAR) AS accountingDate
, NULL AS debitAmount
, CAST(sum(debitAmount-markup_amount)        AS VARCHAR) AS creditAmount
, 'PASSTHRU'                               AS externalSystemIdentifier
, CAST('${#{'MCM Pass Thru Chartstring'}:getDelimitedField(1,"-")}' AS VARCHAR) AS entity
, CAST('${#{'MCM Pass Thru Chartstring'}:getDelimitedField(2,"-")}' AS VARCHAR) AS fund
, CAST('${#{'MCM Pass Thru Chartstring'}:getDelimitedField(3,"-")}' AS VARCHAR) AS department
, CAST('${#{'MCM Pass Thru Chartstring'}:getDelimitedField(4,"-")}' AS VARCHAR) AS account
, CAST('${#{'MCM Pass Thru Chartstring'}:getDelimitedField(5,"-")}' AS VARCHAR) AS purpose
, CAST('${#{'MCM Pass Thru Chartstring'}:getDelimitedField(7,"-")}' AS VARCHAR) AS glProject
, CAST('${#{'MCM Pass Thru Chartstring'}:getDelimitedField(6,"-")}' AS VARCHAR) AS program
, CAST('${#{'MCM Pass Thru Chartstring'}:getDelimitedField(8,"-")}' AS VARCHAR) AS activity
, '0000'   AS interEntity
, '000000' AS flex1
, '000000' AS flex2
, 'glSegments' as lineType
, 'Mail Services Recharges Pass Thru' as lineDescription
, CAST(max(transactionDate) AS VARCHAR) as transactionDate
, CAST(max(transactionDate) AS VARCHAR) as udfDate1
, NULL AS ppmProject
, NULL AS task
, NULL AS organization
, NULL AS expenditureType
, NULL AS award
, NULL AS fundingSource
, NULL AS ppmComment
, NULL AS udfNumeric1
, NULL AS udfNumeric2
, NULL AS udfString1
, NULL AS udfString2
, NULL AS udfString3
, NULL AS udfString4
, NULL AS udfString5
FROM FLOWFILE
GROUP BY
  consumerId
, boundaryApplicationName
, consumerReferenceId
, consumerTrackingId
, requestSourceType
, requestSourceId
, journalSourceName
, journalCategoryName
, journalName
, journalReference
, accountingDate
UNION ALL
-- Add the markup fee income line
SELECT
  CAST(consumerId              AS VARCHAR) AS consumerId
, CAST(boundaryApplicationName AS VARCHAR) AS boundaryApplicationName
, CAST(consumerReferenceId     AS VARCHAR) AS consumerReferenceId
, CAST(consumerTrackingId      AS VARCHAR) AS consumerTrackingId
, CAST(requestSourceType       AS VARCHAR) AS requestSourceType
, CAST(requestSourceId         AS VARCHAR) AS requestSourceId
, CAST(journalSourceName       AS VARCHAR) AS journalSourceName
, CAST(journalCategoryName     AS VARCHAR) AS journalCategoryName
, CAST(journalName             AS VARCHAR) AS journalName
, CAST(journalReference        AS VARCHAR) AS journalReference
, CAST(accountingDate          AS VARCHAR) AS accountingDate
, NULL AS debitAmount
, CAST(SUM(markup_amount)      AS VARCHAR) AS creditAmount
, 'REVENUE' AS externalSystemIdentifier
, CAST('${#{'MCM Revenue Chartstring'}:getDelimitedField(1,"-")}' AS VARCHAR) AS entity
, CAST('${#{'MCM Revenue Chartstring'}:getDelimitedField(2,"-")}' AS VARCHAR) AS fund
, CAST('${#{'MCM Revenue Chartstring'}:getDelimitedField(3,"-")}' AS VARCHAR) AS department
, CAST('${#{'MCM Revenue Chartstring'}:getDelimitedField(4,"-")}' AS VARCHAR) AS account
, CAST('${#{'MCM Revenue Chartstring'}:getDelimitedField(5,"-")}' AS VARCHAR) AS purpose
, CAST('${#{'MCM Revenue Chartstring'}:getDelimitedField(7,"-")}' AS VARCHAR) AS glProject
, CAST('${#{'MCM Revenue Chartstring'}:getDelimitedField(6,"-")}' AS VARCHAR) AS program
, CAST('${#{'MCM Revenue Chartstring'}:getDelimitedField(8,"-")}' AS VARCHAR) AS activity
, '0000'   as interEntity
, '000000' as flex1
, '000000' as flex2
, 'glSegments' as lineType
, 'Mail Services Markup Revenue' as lineDescription
, CAST(max(transactionDate) AS VARCHAR) as transactionDate
, CAST(max(transactionDate) AS VARCHAR) as udfDate1
, NULL AS ppmProject
, NULL AS task
, NULL AS organization
, NULL AS expenditureType
, NULL AS award
, NULL AS fundingSource
, NULL AS ppmComment
, NULL AS udfNumeric1
, NULL AS udfNumeric2
, NULL AS udfString1
, NULL AS udfString2
, NULL AS udfString3
, NULL AS udfString4
, NULL AS udfString5
FROM FLOWFILE
GROUP BY
  consumerId
, boundaryApplicationName
, consumerReferenceId
, consumerTrackingId
, requestSourceType
, requestSourceId
, journalSourceName
, journalCategoryName
, journalName
, journalReference
, accountingDate
```

17. Use the `Validate GL Segments` process group to perform validations on GL segemnts.
18. Replace Invalid GL with Kickout. (`ScriptedTransformRecord`)

| Attribute Key | Attribute Value                      |
| ------------- | ------------------------------------ |
| Record Reader | Reader - JSON - Infer Schema         |
| Record Writer | Writer - JSON Array - Inherit Schema |

Script Body:

```groovy
#{groovy.getFullGlChartstringFromFields}
#{groovy.getFullPpmChartstringFromFields}

def warnings = []
def LINE_TYPE = "glSegments"

// Only run for the above segment type
if ( record.getValue("lineType") == LINE_TYPE ) {

  // If the line is not valid, then we extract the errors from the record and attach them as warnings
  if ( !record.getValue("line_valid") ) {

    // Loop over the status and usage fields and extract the errors
    for ( String field : record.getRawFieldNames() ) {
      if ((field.endsWith("_status") || field.endsWith("_usage")) && record.getValue(field) != "" && record.getValue(field) != "valid") {
        // prefix each with the field name
        fieldName = field.substring(0, field.indexOf("_"));
        warnings << fieldName + " : " + record.getValue(fieldName) + " : " + record.getValue(field);
      }

      // special case for the account since it uses a child object
      if (field == "account_info" && record.getValue(field).getValue("status") != "valid") {
        fieldName = "account";
        warnings << fieldName + " : " + record.getValue(fieldName) + " : " + record.getValue(field).getValue("status");
      }
    }

    // since the line is invalid, we replace all segment values with the kickout values
    warnings << "Invalid Segment Values Found.  Replaced with Kickout Chartstring : " + getFullGlChartstringFromFields(record);

    // First, save the string to the GLIDe field.
    record.setValue("udfString5", getFullGlChartstringFromFields(record).take(50));
    def segmentValues = attributes["kickout.chartstring"].split("-");
    record.setValue("entity", segmentValues[0] );
    record.setValue("fund", segmentValues[1] );
    record.setValue("department", segmentValues[2] );
    record.setValue("account", segmentValues[3] );
    record.setValue("purpose", segmentValues[4] );
    record.setValue("program", segmentValues[5] );
    record.setValue("glProject", segmentValues[6] );
    record.setValue("activity", segmentValues[7] );


    // kickout strings never use PPM
    record.setValue("ppmProject", null);
    record.setValue("task", null);
    record.setValue("organization", null);
    record.setValue("expenseType", null);
    record.setValue("award", null);
    record.setValue("fundingSource", null);

  } else {

    // if there were only warnings, then extract those and attach them to the record
    for ( String field : record.getRawFieldNames() ) {

      if (field.endsWith("_defaulted") && record.getValue(field) && record.getValue(field) != "") {

        warnings << record.getValue(field);

      }
    }
  }
}

record.setValue("warning_messages", warnings.join('\n'));
return record;
```

19. Drop validation fields. (`ConvertRecord`)

| Attribute Key | Attribute Value                   |
| ------------- | --------------------------------- |
| Record Reader | Reader - JSON - Infer Schema      |
| Record Writer | Writer - JSON Array - Schema Name |

20. Use the `Validate PPM Segments` process group to perform validations of PPM segemnts.
21. Replace Invalid GL with Kickout. (`ScriptedTransformRecord`)

| Attribute Key | Attribute Value                      |
| ------------- | ------------------------------------ |
| Record Reader | Reader - JSON - Infer Schema         |
| Record Writer | Writer - JSON Array - Inherit Schema |

Script Body:

```groovy
#{groovy.getFullGlChartstringFromFields}
#{groovy.getFullPpmChartstringFromFields}

def warnings = []
def LINE_TYPE = "ppmSegments"

// Only run for the above segment type
if ( record.getValue("lineType") == LINE_TYPE ) {

  // If the line is not valid, then we extract the errors from the record and attach them as warnings
  if ( !record.getValue("line_valid") ) {

    // Loop over the status and usage fields and extract the errors
    for ( String field : record.getRawFieldNames() ) {

      if ((field.endsWith("_status") || field.endsWith("_usage")) && record.getValue(field) != "" && record.getValue(field) != "valid") {

        // prefix each with the field name
        fieldName = field.substring(0, field.indexOf("_"));
        warnings << fieldName + " : " + record.getValue(fieldName) + " : " + record.getValue(field);
      }

      // special case for the account since it uses a child object
      if (field == "account_info" && record.getValue(field).getValue("status") != "valid") {

        fieldName = "account";
        warnings << fieldName + " : " + record.getValue(fieldName) + " : " + record.getValue(field).getValue("status");

      }
    }

    // since the line is invalid, we replace all segment values with the kickout values
    warnings << "Invalid Segment Values Found.  Replaced with Kickout Chartstring : " + getFullPpmChartstringFromFields(record);
    // First, save the string to the GLIDe field.
    record.setValue("udfString5", getFullPpmChartstringFromFields(record).take(50));
    def segmentValues = attributes["kickout.chartstring"].split("-");
    record.setValue("entity", segmentValues[0] );
    record.setValue("fund", segmentValues[1] );
    record.setValue("department", segmentValues[2] );
    record.setValue("account", segmentValues[3] );
    record.setValue("purpose", segmentValues[4] );
    record.setValue("program", segmentValues[5] );
    record.setValue("glProject", segmentValues[6] );
    record.setValue("activity", segmentValues[7] );
    record.setValue("interEntity", segmentValues[8] );
    record.setValue("flex1", segmentValues[9] );
    record.setValue("flex2", segmentValues[10] );
    record.setValue("lineType", "glSegments" );

    // kickout strings never use PPM
    record.setValue("ppmProject", null);
    record.setValue("task", null);
    record.setValue("organization", null);
    record.setValue("expenseType", null);
    record.setValue("award", null);
    record.setValue("fundingSource", null);

  } else {

    // if there were only warnings, then extract those and attach them to the record
    for ( String field : record.getRawFieldNames() ) {

      if (field.endsWith("_defaulted") && record.getValue(field) && record.getValue(field) != "") {

        warnings << record.getValue(field);
      }
    }
  }
}

record.setValue("flowfileRecordNumber", recordIndex + 1);
record.setValue("warning_messages", warnings.join('\n'));
return record;
```

22. Drop validation fields. (`ConvertRecord`)

| Attribute Key | Attribute Value                   |
| ------------- | --------------------------------- |
| Record Reader | Reader - JSON - Infer Schema      |
| Record Writer | Writer - JSON Array - Schema Name |

23. Add gl flattened required attributes. (`UpdateAttribute`)

| Attribute Key               | Attribute Value            |
| --------------------------- | -------------------------- |
| accounting.date             | ${accountingDate}          |
| boundary.system             | ${boundaryApplicationName} |
| consumer.id                 | ${consumerId}              |
| consumer.ref.id             | ${consumerReferenceId}     |
| consumer.tracking.id        | ${consumerTrackingId}      |
| data.source                 | ${requestSourceType}       |
| fragment.count              | 2                          |
| glide.extract.enabled       | Y                          |
| glide.summarization.enabled | Y                          |
| journal.category            | ${journalCategoryName}     |
| journal.name                | ${journalName}             |
| journal.source              | ${journalSourceName}       |
| priority                    | 1                          |
| record.count                | ${fragment.count}          |
| source.id                   | ${requestSourceId}         |

24. Calculate journal totals. (`ExecuteScript`)

```groovy
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

25. Publish to validated topic. (`PublishKafka`)

| Attribute Key | Attribute Value                                      |
| ------------- | ---------------------------------------------------- |
| Kafka Brokers | #{kafka_broker_list}                                 |
| Topic Name    | in.#{instance_id}.internal.json.gl_journal_validated |
| Kafka Key     | ${source.id}                                         |


## Mail Stop Charge Journal

On a monthly basis, some departments are charged for the services of picking up mail for outside delivery.  This amount is stored in the group code after the surcharge flag in the MCM database.  This flow is to run monthly to generate an expense per account definition in the MCM database.

### High Level Flow

1. Get the list of mail stops which sent mail during the month.
2. Map the records into the GL-PPM Format.
3. Validate the segments and replace any invalid ones with the kickout chartstring.
4. Generate the revenue offset chartstring
5. Post to the GL-PPM Validated Topic.

### Process Flow

#### 1. MCM Data Extract

1. Daily, calculate the date to run for and attach as a attributes on a flowfile.  (`GenerateFlowFile`)
   1. Calculate the first and last day of the previous month.
   2. `extract.start.date` = 'YYYY-MM-DD'
   3. `extract.end.date` = 'YYYY-MM-DD'
   4. _Note: An alternate generator can be created to inject arbitrary dates in the case that data is missed or needs to be re-processed._
2. Pull all transactions between the given dates from the MCM database per the query below. (`QueryDatabaseTable`)
   1. There will be two of these processors connected to the above generator.  These will run in parallel and will each extract the data from one of the two schemas.
3. Set an attribute on the flow file to identify the source of the data (campus or UCDH).  (`UpdateAttribute`)
4. Merge the flows back together into the data conversion steps below.  (Keep the flowfiles separate.)

##### Groovy Script to Get the First and Last Day of the Previous Month

```groovy
import java.time.LocalDate;

def flowFile = session.get();
if(!flowFile) return;

// retrieve details of the current date
def today = LocalDate.now();
def lastMonth = today.minusMonths(1);
def startOfLastMonth = lastMonth.withDayOfMonth(1);
def endOfLastMonth = lastMonth.withDayOfMonth(lastMonth.lengthOfMonth());

String previousMonthStartFormatted = startOfLastMonth.format('yyyy-MM-dd');
String previousMonthEndFormatted = endOfLastMonth.format('yyyy-MM-dd');

flowFile["extract.start.date"] = previousMonthStartFormatted;
flowFile["extract.end.date"] = previousMonthEndFormatted;
REL_SUCCESS << flowFile;
```

### 2. Extract Segment Values

1. Convert the concatenated accounting segment values into individual record properties. (`ExecuteGroovyScript`)
   1. Also calculate and attach the total attributes as required.  (see prior journal flow)
2. Attach the kickout chartstring to the flow file. (`UpdateAttribute`)  This may then be used to replace segments on bad lines with the kickout segments.

### 3. Reformat and Generate Offsets

1. Convert the overall format of the data into the format required by the GL-PPM Line validation pipeline. (`QueryRecord`)
   1. See [Section 6.2.5](#/6%20Data%20Pipelines/6.2%20Common%20Inbound%20Pipelines/6.2.5%20GL-PPM%20Flattened/HOME ':ignore') for details on the format.
   2. Generate an offset record for the total of the `mail_stop_charge` on all records.  Use the `MCM Revenue Chartstring` for the segment values.
2. Add the journal header attributes to the flowfile.  See table in the previous sections.  (`PartitionRecord`)
3. Validate the segment values by using the `Validate GL Segments` and `Validate PPM Segments` process groups.
    1. Disable the `Validation Error Records` and `Passed Validation` output ports and set their relationships to expire flowfiles after one second.
    2. Enable the `All Records` output port and remove any expiration time on the relationship.
    3. Between each process group, update any records where line_valid = 'false' to the kickout chartstring. (`QueryRecord` or `UpdateRecord`)
4. Post the flowfile to the validated topic with appropriate retry.
    1. Topic: `in.#{instance_id}.internal.json.gl_ppm_validated`
    2. Headers: `.*`
    3. Kafka Key: `${source.id}`


#### SQL To Generate Offset Record

```sql
SELECT
  consumerId
, boundaryApplicationName
, consumerReferenceId
, consumerTrackingId
, requestSourceType
, requestSourceId
, journalSourceName
, journalCategoryName
, journalName
, journalReference
, accountingDate
, debitAmount
, NULL AS creditAmount
, externalSystemIdentifier
, entity
, fund
, department
, account
, purpose
, glProject
, program
, activity
, interEntity
, flex1
, flex2
, lineType
, lineDescription
, journalLineNumber
, transactionDate
, udfNumeric1
, udfNumeric2
, udfDate1
, udfString1
, udfString2
, udfString5
, ppmProject
, task
, organization
, expenditureType
, award
, fundingSource
, ppmComment
FROM FLOWFILE
UNION ALL
SELECT
  CAST(consumerId              AS VARCHAR) AS consumerId
, CAST(boundaryApplicationName AS VARCHAR) AS boundaryApplicationName
, CAST(consumerReferenceId     AS VARCHAR) AS consumerReferenceId
, CAST(consumerTrackingId      AS VARCHAR) AS consumerTrackingId
, CAST(requestSourceType       AS VARCHAR) AS requestSourceType
, CAST(requestSourceId         AS VARCHAR) AS requestSourceId
, CAST(journalSourceName       AS VARCHAR) AS journalSourceName
, CAST(journalCategoryName     AS VARCHAR) AS journalCategoryName
, CAST(journalName             AS VARCHAR) AS journalName
, CAST(journalReference        AS VARCHAR) AS journalReference
, CAST(accountingDate          AS VARCHAR) AS accountingDate
, NULL AS debitAmount
, CAST(SUM(debitAmount)      AS VARCHAR) AS creditAmount
, 'REVENUE' AS externalSystemIdentifier
, CAST('${#{'MCM Mail Sort Revenue Chartstring'}:getDelimitedField(1,"-")}' AS VARCHAR) AS entity
, CAST('${#{'MCM Mail Sort Revenue Chartstring'}:getDelimitedField(2,"-")}' AS VARCHAR) AS fund
, CAST('${#{'MCM Mail Sort Revenue Chartstring'}:getDelimitedField(3,"-")}' AS VARCHAR) AS department
, CAST('${#{'MCM Mail Sort Revenue Chartstring'}:getDelimitedField(4,"-")}' AS VARCHAR) AS account
, CAST('${#{'MCM Mail Sort Revenue Chartstring'}:getDelimitedField(5,"-")}' AS VARCHAR) AS purpose
, CAST('${#{'MCM Mail Sort Revenue Chartstring'}:getDelimitedField(7,"-")}' AS VARCHAR) AS glProject
, CAST('${#{'MCM Mail Sort Revenue Chartstring'}:getDelimitedField(6,"-")}' AS VARCHAR) AS program
, CAST('${#{'MCM Mail Sort Revenue Chartstring'}:getDelimitedField(8,"-")}' AS VARCHAR) AS activity
, '0000'   as interEntity
, '000000' as flex1
, '000000' as flex2
, 'glSegments' as lineType
, 'Mail Services Mail Sort Fee Revenue' as lineDescription
, 0 AS journalLineNumber
, '${extract.end.date}' as transactionDate
, NULL AS udfNumeric1
, NULL AS udfNumeric2
, '${extract.end.date}' as udfDate1
, '' AS udfString1
, 'Mail Sort Feed Revenue' AS udfString2
, NULL AS udfString5
, NULL AS ppmProject
, NULL AS task
, NULL AS organization
, NULL AS expenditureType
, NULL AS award
, NULL AS fundingSource
, NULL AS ppmComment
FROM FLOWFILE
GROUP BY
  consumerId
, boundaryApplicationName
, consumerReferenceId
, consumerTrackingId
, requestSourceType
, requestSourceId
, journalSourceName
, journalCategoryName
, journalName
, journalReference
, accountingDate
```

### Query to pull Monthly Mail Stop Charges


```sql
SELECT
  acct.Acct_Number1_VC                                                        AS segment_string,
  acct.Acct_Name1_VC                                                          AS account_name,
  MAX(CAST(SUBSTRING(acct.Acct_Group_VC,2,50) AS decimal(5,2)))               AS mail_stop_charge,
  COUNT(DISTINCT main.Machine_Key_VC + '00' + cast(main.Trans_ID as varchar)) AS num_trans,
  SUM(case
    when main.Number_Of_Pieces_IN <> 0
      then abs(main.Number_Of_Pieces_IN)
      else 1
  end)                                                                        AS num_pieces
FROM            ${mcm.schema.name}.dbo.Transaction_Main_T    main
           JOIN ${mcm.schema.name}.dbo.Transaction_Account_T acct  ON acct.Trans_ID  = main.Trans_ID
LEFT OUTER JOIN ${mcm.schema.name}.dbo.Transaction_Flags_T   flags ON flags.Trans_ID = main.Trans_ID
where CONVERT(DATE, main.Meter_Date_Time_DT) between '${extract.start.date}' and '${extract.end.date}'
  -- Excluded voided transactions
  AND ISNULL(flags.Void_BT,0) != 1
  -- Only process S and N type billings
  AND LEFT(COALESCE(acct.Acct_Group_VC,'S'),1) IN ( 'S', 'N' )
  -- Acct_Group_VC contains the amount, only process if it is numeric
  AND ISNUMERIC(SUBSTRING(acct.Acct_Group_VC,2,50)) = 1
GROUP BY acct.Acct_Number1_VC, acct.Acct_Name1_VC
ORDER BY segment_string
```

#### Sample Results (KFS Billing IDs)

```csv
"segment_string","account_name","mail_stop_charge","num_trans","num_pieces"
"0011","A&FS ACCOUNTS PAYABLE","73.5","120","880"
"001D","CAHFS","49","45","346"
"0020","CASHIERS OFFICE","49","10","43"
"0034","ADMISSIONS","49","8","136"
"0071","ARM: ORMP","49","8","11"
"0187","ARCHITECTS & ENGINEE","49","2","3"
"0205","AG. ECONOMICS","49","1","3"
"020C","OILED WILDLIFE CARE","49","1","1"
"0280","POLITICAL SCIENCE","49","2","2"
"0305","CALIFORNIA CROP","49","15","108"
"0340","ANIMAL SCIENCE","49","11","18"
"0380","NPB(NEURO PHYSIO & BEHAVIOR)","49","1","1"
"0390","MOLECULLAR & CELL BI","49","1","1"
"0583","CHILD FAMILY STUDY CENTER","49","6","10"
"0655","PLANT PATHOLOGY","49","6","9"
"0791","F.P.M.S.(FOUNDATION PLT.MATERIALS)","49","6","190"
"0801","VITICULTURE & ENOLOG","49","1","1"
"0869","ART-","49","2","2"
"0875","MICROBIOLOGY","49","1","1"
"0942","PLANT BIOLOGY","49","2","2"
"0965","ECONOMICS","49","3","3"
"0975","ENGLISH","49","7","23"
"0995","GEOLOGY","49","1","1"
"1000","HISTORY","49","9","10"
"1015","MATHEMATICS","49","1","1"
"1080","EVOLUTION & ECOLOGY","49","8","8"
"1118","LIB. - REFERENCE","98","11","80"
"1220","PARKING OPERATIONS","49","5","41"
"1222","AIRPORT","49","2","12"
"1409","VM:DEAN","49","13","37"
"1415","VM:CCEHP","49","4","4"
"1425","VETERINARY GENETICS LAB","49","123","1412"
"1855","ENGR. - CIVIL & ENVI","49","1","2"
"236N","INSTITUTE OF TRANS.","49","1","1"
"2503","STUDENT JUDICIAL AFFAIRS","49","1","1"
"2527","ENTOMOLOGY","49","7","7"
"261X","GRAD SCHOOL MANAGEMENT","49","12","70"
"3X50","GRAD DIVISION(G.S.ADMIN SERV)","49","1","1"
"4342","L&S DEVELOPMENT","49","8","29"
"4372","STUDENT AID ACCOUNTING","49","3","3"
"4500","HOUSING-STUDENT","245","1","1"
"4690","STATISTICS","49","3","7"
"492J","BIOMEDICAL ENGINEERING","49","1","1"
"4SSC","SHARED SERVICE CENTER","98","4","12"
"6009","MED. MICROBIOLOGY","49","15","15"
"613U","INTERCOLLEGIATE ATHLETICS","49","28","52"
"661G","LAW - ADMINISTRATION","49","10","17"
"7402","EYE CENTER-DAVIS","49","9","99"
"7N03","LAW CLINIC","49","9","60"
"8015","DAVIS CAMPUS CLINIC","49","9","14"
"8326","CROCKER NUCLEAR LAB","98","12","12"
"9051","NUTRITION","49","1","1"
"986H","DEAN - AGRICULTURE/STUDENT FARMS","98","3","3"
"A110","VM:TEACHING HOSPITAL","49","226","254"
"AM39","ARBORETUM","49","15","322"
"CH01","CHEMISTRY","49","1","1"
"CHS7","CHSSP","16.3","8","8"
"D01X","VM ANATOMY PHSIOLOGY & CELL BIOLOGY","49","2","3"
"EHSP","ENVIRON. HEALTH & SAFETY","98","7","12"
"EOFC","PLANT SCIENCES","245","22","24"
"ETSC","CLASSIC TALENT SEARCH","49","1","17"
"GSUP","POLICE","49","40","75"
"HBAR","HERBARIUM-PLANT SCIENCE","49","3","3"
"ICRT","JOHN MUIR INSTUTE FOR THE ENVIRONMENT","98","3","3"
"INCR","CENTER FOR HEALTH & THE ENVIRONMENT","49","1","1"
"INTS","SERV INTL STUD & SCH","49","5","7"
"M933","COMMUNICATIONS RESOURCES","49","2","4"
"MAIL","EDUCATION","147","9","71"
"OM09","O & M UTILITIES","49","1","1"
"OURM","REGISTRAR/TRANSCRIPT","49","49","2222"
"RECM","CAMPUS RECREATIONS","49","5","46"
"SB69","ENVIRONMENTAL TOXICOLOGY","49","3","11"
"SEND","FLEET SERVICES","49","4","5"
"SHIP","MECHANICAL AERO ENGR","49","1","1"
"SOFC","CHANCELLORS OFFICE","49","4","4"
"SPAD","Lang & Lit","49","4","4"
"TCKT","MONDAVI CENTER","49","1","1"
"UB17","UPWARD BOUND","49","1","6"
"Y192","ASUCD UNITRANS","49","1","1"
```


### Process Reference Information

#### Data Extract SQL

> Cleaned up version of the transaction extract SQL from the existing MCM extract process which was part of the `mdrecharge` application.
> This can (and should) only be used as a starting point.  Column names may be changed.  Columns which are unneeded by the current process can be removed.

```sql
SELECT
  main.Machine_Key_VC + '00' + cast(main.Trans_ID as varchar)   AS sTransNum,
  acct.Acct_Number1_VC                                          AS sAcctNum,
  acct.Acct_Name1_VC                                            AS sAcctName,
  case
    when COALESCE(acct.Acct_Group_VC, ' ') in ('',' ')
      then 'S'
      else acct.Acct_Group_VC
  end                                                           AS sGroupNum,
  case
    when COALESCE(strs.Machine_Operator_VC, ' ') in ('',' ')
      then ' '
      else strs.Machine_Operator_VC
  end                                                           AS sOperator,
  case
    when COALESCE(meter.Meter_Number_VC, ' ') in ('',' ')
      then ' '
      else  meter.Meter_Number_VC
  end                                                           AS sMeterID,
  main.Carrier_ID                                               AS iCarrier,
  carrier.CarrierName                                           AS CarrierName,
  case
    when main.Number_Of_Pieces_IN <> 0
      then abs(main.Number_Of_Pieces_IN)
      else 1
  end                                                           AS lNumPieces,
  main.Base_Rate_MN                                             AS cBaseRate,
  (main.Total_Charges_MN /
    case
      when main.Number_Of_Pieces_IN <> 0
        then abs(main.Number_Of_Pieces_IN)
        else 1
    end)                                                        AS cBaseRate2,
  main.Total_Charges_MN                                         AS cTotalCharges,
  isnull(ss.COD_Amount_MN,0)                                    AS cCODAmt,
  isnull(ss.COD_Fee_MN,0)                                       AS cCODFee,
  isnull(ss.Insurance_Amount_MN,0)                              AS cInsuranceAmt,
  isnull(ss.Insurance_Fee_MN,0)                                 AS cInsuranceFee,
  isnull(ss.Alternate_Insurance_Amount_MN,0)                    AS cAltInsuranceAmt,
  isnull(ss.Alternate_Insurance_Fee_MN,0)                       AS cAltInsuranceFee,
  isnull(ss.Registered_Amount_MN,0)                             AS cRegisteredAmt,
  isnull(ss.Registered_Fee_MN,0)                                AS cRegisteredFee,
  isnull(ss.Certified_Fee_MN,0)                                 AS cCertifiedFee,
  isnull(ss.Return_Receipt_Fee,0)                               AS cReturnRecFee,
  isnull(ss.Return_Receipt_Merchandise_Fee_MN,0)                AS cReturnRecMerchFee,
  isnull(ss.Special_Delivery_Fee_MN,0)                          AS cSpecDeliveryFee,
  isnull(ss.Special_Handling_Fee_MN,0)                          AS cSpecHandlingFee,
  isnull(ss.Restricted_Delivery_Fee_MN,0)                       AS cRestrictedDelvFee,
  isnull(ss.Call_Tag_Fee_MN,0)                                  AS cCallTagFee,
  isnull(ss.Proof_Of_Delivery_Fee_MN,0)                         AS cPODFee,
  isnull(ss.Hazardous_Material_Fee_MN,0)                        AS cHazMatFee,
  isnull(ss.Saturday_Delivery_Fee_MN,0)                         AS cSatDeliveryFee,
  isnull(ss.Saturday_Pickup_Fee_MN,0)                           AS cSatPickupFee,
  isnull(ss.Sunday_Delivery_Fee_MN,0)                           AS cSunDeliveryFee,
  isnull(ss.Acknowledgement_Of_Delivery_Fee_MN,0)               AS cAODFee,
  isnull(ss.Courier_Pickup_Fee_MN,0)                            AS cCourierPickupFee,
  isnull(ss.Oversize_Fee_MN,0)                                  AS cOversizeFee,
  isnull(ss.Ship_Notification_Fee_MN,0)                         AS cShipNotificationFee,
  isnull(ss.Delivery_Confirmation_Fee_MN,0)                     AS cDelvConfirmFee,
  isnull(ss.Signature_Confirmation_Fee_MN,0)                    AS cSignatureConfirmFee,
  isnull(ss.PAL_Fee_MN,0)                                       AS cPALFee,
  isnull(ss.Barcode_Discount_MN,0)                              AS cBarcodeDiscount,
  isnull(ss.Misc_Postage_MN,0)                                  AS cMiscPostage,
  isnull(ss.Handling_Charge_MN + ss.Area_Surcharge_MN,0)        AS cHandlingCharge,
  isnull(ss.Residual_Shape_Surcharge_MN,0.00)                   AS cResidualShapeSurcharge,
  CONVERT(VARCHAR(8), main.System_Date_Time_DT, 112)            AS sSysDate,
  CONVERT(VARCHAR(8), main.System_Date_Time_DT, 108)            AS sSysTime,
  main.Manifest_Date_Time_DT                                    AS sSysDateTime,
  (CONVERT(VARCHAR(8), main.Manifest_Date_Time_DT , 112)
    + replace(CONVERT(VARCHAR(8), main.Manifest_Date_Time_DT , 108),':','')) AS sManDateTime
FROM            Transaction_Main_T            main
           JOIN Transaction_Account_T         acct     ON acct.Trans_ID         = main.Trans_ID
           JOIN Carrier_Info_T                carrier  ON carrier.CarrierNumber = main.Carrier_ID
LEFT OUTER JOIN Transaction_Strings_T         strs     ON strs.Trans_ID         = main.Trans_ID
LEFT OUTER JOIN Transaction_Meter_T           meter    ON meter.Trans_ID        = main.Trans_ID
LEFT OUTER JOIN Transaction_Special_Service_T ss       ON ss.Trans_ID           = main.Trans_ID
LEFT OUTER JOIN Transaction_Flags_T           flags    ON flags.Trans_ID        = main.Trans_ID
--LEFT OUTER JOIN Transaction_Ship_To_T         ship     ON ship.Trans_ID     = main.Trans_ID
--LEFT OUTER JOIN Transaction_Modified_T        mod      ON mod.Trans_ID      = main.Trans_ID
--FULL OUTER JOIN Transaction_Comments_T        comments ON comments.Trans_ID = main.Trans_ID
where main.System_Date_Time_DT between '2022-06-01' and '2022-06-30'
  and isnull(flags.Void_BT,0) != 1
order by sTransNum
```

#### PL/SQL References

The original process ran in stages, starting with the above SQL to pull the data and store it to `md_trns_dtl_t`.  This table was then the source for remaining processing.

1. Extract data to `md_trns_dtl_t`
2. Do something with the fee accounts (still applicable?)
3. Handle missing carrier information (still applicable?)
4. Run PL/SQL proc `md_scrub_trns_dtl` to create the GL transaction records in another staging table.
5. Run PL/SQL proc `md_scrub_sort_fee` to generate the surcharge records in the staging table.
6. ColdFusion extracts contents of table, formats for the GL collector, and sends the file to the GL server.


### Outstanding MCM Integration Issues

1. Should transactions be extracted monthly or would we like to extract more frequently?
   1. If monthly, when should it run, and how should it identify the transactions to extract?
   2. The above depends on the accounting period close schedule in Oracle.  I.e., do we need to run this process before the end of the calendar month?
2. Is there any pre-process which needs to be performed before the process can be run?  Or can we reliably run this on a schedule?
3. Requirements note that the posting date should be based on the file creation date.  And that we should post in that date's period.  However, in Oracle July 1 is part of July, not June.  Is that what you want?
4. Design notes use of POET segments, will those be in use here?  If so, we need to decide on how they will be stored and how to tell the difference between them and the GL segments during processing.
5. What is the suspense chartstring?
6. If there are processing errors creating the journal, who should be notified?
7. Assumption: If a PPM project has expired, we will use the PPM failover logic and post using GL segments.
8. What are the natural accounts for the expenses?  Do they vary by anything in the source data?
9. What are the natural accounts for the surcharge transactions?
10. What is/are the chartstring(s) for recording the income?  Do we record the credits using different accounts for the surcharge vs. expense offsets?
11. Do the transactions need to be exported to the BI systems for local reporting?
12. What attributes of the source data should be included in the generated journals and on which lines?
    1. `externalSystemIdentifier` will appear in the Oracle GL
    2. Other attributes are likely to be GLIDe-only.
13. Should/can any records from the source be summarized?
14. Should we summarize the income/recharge offsets?

#### Sample Output Record from MCM

| Column Name             | Sample Value          |
| ----------------------- | --------------------- |
| sTransNum               | `22135900614030`      |
| sAcctNum                | `6M90`                |
| sAcctName               | `VET MED- MED EPI`    |
| sGroupNum               | `S`                   |
| sOperator               | `Steve`               |
| sMeterID                | `011E12650149`        |
| iCarrier                | `2000`                |
| lNumPieces              | `18`                  |
| cBaseRate               | `0.53`                |
| cBaseRate2              | `0.58`                |
| cTotalCharges           | `10.44`               |
| cCODAmt                 | `0`                   |
| cCODFee                 | `0`                   |
| cInsuranceAmt           | `0`                   |
| cInsuranceFee           | `0`                   |
| cAltInsuranceAmt        | `0`                   |
| cAltInsuranceFee        | `0`                   |
| cRegisteredAmt          | `0`                   |
| cRegisteredFee          | `0`                   |
| cCertifiedFee           | `0`                   |
| cReturnRecFee           | `0`                   |
| cReturnRecMerchFee      | `0`                   |
| cSpecDeliveryFee        | `0`                   |
| cSpecHandlingFee        | `0`                   |
| cRestrictedDelvFee      | `0`                   |
| cCallTagFee             | `0`                   |
| cPODFee                 | `0`                   |
| cHazMatFee              | `0`                   |
| cSatDeliveryFee         | `0`                   |
| cSatPickupFee           | `0`                   |
| cSunDeliveryFee         | `0`                   |
| cAODFee                 | `0`                   |
| cCourierPickupFee       | `0`                   |
| cOversizeFee            | `0`                   |
| cShipNotificationFee    | `0`                   |
| cDelvConfirmFee         | `0`                   |
| cSignatureConfirmFee    | `0`                   |
| cPALFee                 | `0`                   |
| cBarcodeDiscount        | `0`                   |
| cMiscPostage            | `0`                   |
| cHandlingCharge         | `0.05`                |
| cResidualShapeSurcharge | `0`                   |
| sSysDate                | `20220602`            |
| sSysTime                | `09:55:53`            |
| sSysDateTime            | `2022-06-02 09:55:53` |
| sManDateTime            | `20220602095553`      |


### Assumptions

#### Entry Generation

For each transaction, we will create 2-3 transactions (prior to any summarization).

1. Postage Expense: This would be the direct expense incurrent for the mailing service.
2. Surcharge Expense: If subject to a surcharge, an additional expense to the same chartstring as the above.
3. Mail Division Income: Offset to the above entries, credit to a Mail Division chartstring.

### Design Notes extracted from Functional Spec

1. journal posting date = file transmission date (which would be data extract date)
   1. journal posting date = accountingDate
