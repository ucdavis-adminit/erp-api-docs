# 6.3.9.3 WebCRD Billing


#### Summary

WebCRD application has no internal billing integration, so we will utilize the vendor's SOAP API to pull all of the required transactional data for creating GL/PPM journals for recharge income and expense.

The NiFi pipeline will be scheduled to run daily, and the data that will be pulled is based on the ship date of the order in the system, providing some allowance for time that the business office might need to make adjustments to the order before it is posted to the ledger.

By persisting a list of all orders that have previously been processed, we can ensure that we only re-process failed orders, presumably after the department was notified of the failure and went into the vendor system to resolve the error.

#### Flow Summary

1. Request Data from SOAP API
  a. Date range is generated from EL in parameter context
2. Validate SOAP Request Status
3. Update Pipeline Request Table
4. Convert SOAP Response to JSON Orders
5. Filter Out Orders/Splits, and Create Credit Records
6. Convert to Flattened Format with GL-PPM Fields
7. Validate GL segments
8. Validate PPM segments
9. Ensure Full Orders Remain, removing partial based on updated total cost
10. Merge FlowFiles, Add Req'd Attributes/Schema 
11. Persist Orders in Tracking Table
12. Publish to Validated Topic
13. Mark Orders in Vendor System as Billed

#### Process Group Parameter Context
**Name:** WebCRD billing (6.3.9.3)
**Inheritance:** Environment - MAIN

##### Parameters

| Name | Value |
| ---- | ----- |
| BoundaryApplicationName | AggiePrint |
| ConsumerId | UCD WebCRD |
| CreditSegmentString | 3110-12100-9302530-775000-72-000-0000000000-000000-0000-000000-000000 |
| DebitNaturalAccount | 770000 |
| EndDateTime | ${now():toNumber():minus(86400000):format("yyyy-MM-dd'T'00:00:00.0000000")} |
| JournalCategoryName | UCD Recharge |
| JournalSourceName | UCD WebCRD |
| MaxBinAge | 1 min |
| RequestSourceType | sftp |
| SharedKey | ASDF1234GHJK5678 |
| StartDateTime | ${now():toNumber():minus(2678400000):format("yyyy-MM-dd'T'00:00:00.0000000")} |
| WebCRD SOAP API URL | https://aggieprint.ucdavis.edu/services/Order |
| pipeline_id | webcrd |

##### Controller Services

* **LookupService - SQL - WebCRD Staging** (SimpleDatabaseLookupService)

  | Property | Value |
  | -------- | ----- |
  | Database Connection Pooling Service | DB - Postgres - Integrations |
  | Table Name | #{instance_id}_staging.repo_webcrd_billing |
  | Lookup Key Column | order_id |
  | Lookup Value Column | last_update_date |

* **Record Sink - SQL - WebCRD Staging** (DatabaseRecordSink)

  | Property | Value |
  | -------- | ----- |
  | Database Connection Pooling Service | DB - Postgres - Integrations |
  | Schema Name | #{instance_id}_staging |
  | Table Name | repo_webcrd_billing |

* **WebCRD FreeFormText Writer** (FreeFormTextRecordSetWriter)

  | Property | Value |
  | -------- | ----- |
  | Text | \${order\_id}: ${message} |

* **WebCRD JSON Reader** (JsonTreeReader)

  | Property | Value |
  | -------- | ----- |
  | Schema Access Strategy | Use 'Schema Text' Property |
  | Schema Text | see 6.3.9.3.A |

* **WebCRD JSON Writer** (JsonRecordSetWriter)

  | Property | Value |
  | -------- | ----- |
  | Schema Access Strategy | Use 'Schema Text' Property |
  | Schema Text | see 6.3.9.3.A |

* **WebCRD XMLReader** (XMLReader)

  | Property | Value |
  | -------- | ----- |
  | Schema Access Strategy | Use 'Schema Text' Property |
  | Schema Text | see 6.3.9.3.A |
  | Timestamp Format | yyyy-MM-dd'T'HH:mm:ss.SSS |

#### Flow Walkthrough

* **XML Request Payload** (GenerateFlowFile)
```xml
    <?xml version="1.0" encoding="UTF-8"?>
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <soapenv:Body>
        <SearchOrders xmlns="http://www.rocsoft.com/services/order/types" xmlns:s="http://www.rocsoft.com/services/types">
          <s:SharedKey>#{SharedKey}</s:SharedKey>
          <SearchCriteria>
            <OrderStatusDateTimes>
              <CompletedStartDateTime>#{StartDateTime}</CompletedStartDateTime>
              <CompletedEndDateTime>#{EndDateTime}</CompletedEndDateTime>
            </OrderStatusDateTimes>
          </SearchCriteria>
        </SearchOrders>
      </soapenv:Body>
    </soapenv:Envelope>
```
* **Insert pipeline_request Attributes** (UpdateAttribute)

  | Property | Value |
  | -------- | ----- |
  | consumer.id | #{ConsumerId} |
  | data.source | #{RequestSourceType} |
  | source.id | journal.#{BoundaryApplicationName}_${now():format('yyyyMMddHHmmss')} |

* **WebCRD SOAP API** (InvokeHTTP) (w/RetryFlowFile)

  | Property | Value |
  | -------- | ----- |
  | HTTP Method | POST |
  | Remote URL | #{WebCRD SOAP API URL} |
  | SOAPAction | SearchOrders |

* **Extract Success to Attribute** (EvaluateXPath)

  | Property | Value |
  | -------- | ----- |
  | Destination | flowfile-attribute |
  | Return Type | string |
  | webcrd.api.success | //*[local-name()='Success']/text() |

* **Route on Success** (RouteOnAttribute)

  | Property | Value |
  | -------- | ----- |
  | Routing Strategy | Route to 'matched' if all match |
  | success | ${webcrd.api.success:equals('true')} |

* **Insert Pipeline Request** (PutSQL) (w/RetryFlowFile)

  | Property | Value |
  | -------- | ----- |
  | JDBC Connection Pool | DB - Postgres - Integrations |
  | SQL Statement | see below |
  ```sql
  INSERT INTO #{int_db_api_schema}.pipeline_request
  ( source_request_type, source_request_id, consumer_id, request_date_time, request_status )
  VALUES
  ( '${data.source}', '${source.id}', '${consumer.id}', CURRENT_TIMESTAMP, 'INPROCESS' )
  ```

* **Split into one Flowfile per Order** (EvaluateXQuery)

  | Property | Value |
  | -------- | ----- |
  | query | //*[local-name()='Order'] |

* **Extract Order Details** (EvaluateXPath)

  | Property | Value |
  | -------- | ----- |
  | Destination | flowfile-attribute |
  | Return Type | string |
  | externalSystemIdentifier | //*[local-name()='OrderID']/text() |
  | filename | //*[local-name()='OrderID']/text() |
  | lineDescription | //*[local-name()='OrderName']/text() |
  | TotalCost | //*[local-name()='Total']/text() |
  | udfDate1 | //*[local-name()='ReceivedDateTime']/text() |
  | udfDate2 | //*[local-name()='CompletedDateTime']/text() |
  | udfString3 | //*[local-name()='OrderID']/text() |
  | udfString5 | //*[local-name()='OrderPlacer']/text() |

* **Simplify Data Model** (EvaluateXQuery)

  | Property | Value |
  | -------- | ----- |
  | query | see below |
  ```xml
  <Order>
    <TotalCost>{//*[local-name()='Total']/text()}</TotalCost>
    <externalSystemIdentifier>{//*[local-name()='OrderID']/text()}</externalSystemIdentifier>
    {for $x in //*[local-name()='AccountingField'] return <AccountingFields><percent>{data($x/@percent)}</percent><value>{$x/text()}</value></AccountingFields>}
  </Order>
  ```

* **Convert and Flatten (XML->JSON)** (ForkRecord)

  | Property | Value |
  | -------- | ----- |
  | Record Reader | WebCRD XMLReader |
  | Record Writer | WebCRD JSON Writer |
  | Mode | Extract |
  | Include Parent Fields | true |
  | recordpath | /AccountingFields |

* **Filter out previously uploaded orders** (LookupRecord)

  | Property | Value |
  | -------- | ----- |
  | Record Reader | WebCRD JSON Reader |
  | Record Writer | WebCRD JSON Writer |
  | Lookup Service | LookupService - SQL - WebCRD Staging |
  | Routing Strategy | Route to 'matched' or 'unmatched' |
  | key | /externalSystemIdentifier |

* **Drop 0 Percent Splits** (QueryRecord)

  | Property | Value |
  | -------- | ----- |
  | Record Reader | WebCRD JSON Reader |
  | Record Writer | WebCRD JSON Writer |
  | Include Zero Record FlowFiles | false |
  | dropped | SELECT * FROM FLOWFILE WHERE "percent" = 0 |
  | query | SELECT * FROM FLOWFILE WHERE "percent" > 0 |

* **Extract to Credit and Debit records** (QueryRecord)

  | Property | Value |
  | -------- | ----- |
  | Record Reader | WebCRD JSON Reader |
  | Record Writer | WebCRD JSON Writer |
  | Include Zero Record FlowFiles | false |
  | query | see below |
  ```sql
  SELECT
  "externalSystemIdentifier",
  "TotalCost",
  "percent",
  "value",
  NULL AS "creditAmount",
  ROUND("TotalCost" * (CAST("percent" AS DOUBLE) / 100), 2) AS "debitAmount"
  FROM FLOWFILE
  UNION ALL
  SELECT
  "externalSystemIdentifier",
  "TotalCost",
  "percent",
  '#{CreditSegmentString}' AS "value",
  ROUND("TotalCost" * (CAST("percent" AS DOUBLE) / 100), 2) AS "creditAmount",
  NULL AS "debitAmount"
  FROM FLOWFILE
  ```

* **Save Updated Total Cost Attribute** (ExecuteGroovyScript)

  ```groovy
  def flowFile = session.get();
  if(!flowFile) return;
  try {
    def inputStream = session.read(flowFile);
    def journalData = new groovy.json.JsonSlurper().parse(inputStream);
    def debitTotal  = 0.00;
    
    journalData.each {
      if ( it.debitAmount ) debitTotal += it.debitAmount;
    }

    inputStream.close();
    
    flowFile = session.putAttribute(flowFile, 'UpdatedTotalCost', String.valueOf(debitTotal));
    session.transfer(flowFile, REL_SUCCESS);
  } catch(e) {
    log.error("Error calculating updated total cost", e);
    session.transfer(flowFile, REL_FAILURE);
  }

  ```

* **Set Schema to flattened** (UpdateAttribute)

  | Property | Value |
  | -------- | ----- |
  | schema.name | in.#{instance_id}.internal.json.gl_journal_flattened-value |

* **Parse Account Segment String** (LookupRecord)

  | Property | Value |
  | -------- | ----- |
  | Record Reader | WebCRD JSON Reader |
  | Record Writer | Writer - JSON Array - Schema Name |
  | Lookup Service | LookupService - Scripted - Segment String Extraction |
  | Result RecordPath | / |
  | Record Result Contents | Insert Record Fields |
  | segmentStringPath | /value |

* **Apply Debit Natural Account** (ScriptedTransformRecord)

  | Property | Value |
  | -------- | ----- |
  | Record Reader | Reader - JSON - Use Schema Registry |
  | Record Writer | Writer - JSON Array - Schema Name |
  | Script Language | Groovy |
  | Script Body | see below |
  ```groovy
  if(record.getValue('debitAmount') != null)
  {
    record.setValue(record.getValue('lineType') == 'glSegments' ? 'account' : 'expenditureType', '#{DebitNaturalAccount}')
  }
  record
  ```

* **Populate GL-PPM Fields** (UpdateRecord)

  | Property | Value |
  | -------- | ----- |
  | Record Reader | Reader - JSON - Use Schema Registry |
  | Record Writer | Writer - JSON Array - Inherit Schema |
  | /accountingDate | ${now():format('yyyy-MM-dd')} |
  | /boundaryApplicationName | #{BoundaryApplicationName} |
  | /consumerId | ${consumer.id} |
  | /consumerReferenceId | #{BoundaryApplicationName}_${now():format('yyyyMMdd')} |
  | /consumerTrackingId | #{BoundaryApplicationName}_${now():format('yyyyMMddHHmmss')} |
  | /journalCategoryName | #{JournalCategoryName} |
  | /journalName | #{BoundaryApplicationName} Recharges for ${now():format('yyyy-MM-dd')} |
  | /journalReference | #{BoundaryApplicationName} Recharges for ${now():format('yyyy-MM-dd')} |
  | /journalSourceName | #{JournalSourceName} |
  | /lineDescription | ${lineDescription} |
  | /requestSourceId | ${source.id} |
  | /requestSourceType | ${data.source} |
  | /udfDate1 | ${udfDate1:substring(0, 10)} |
  | /udfDate2 | ${udfDate2:substring(0, 10)} |
  | /udfString3 | ${externalSystemIdentifier} |
  | /udfString4 | #{BoundaryApplicationName} Order |

* **Validate GL Segments**
  See 6.4.16 GL Segment Validation
* **Validate PPM Segments**
  See 6.4.17 PPM Segment Validation
* **Validate Balance vs Total Cost** (ExecuteGroovyScript)

  | Property | Value |
  | -------- | ----- |
  | Script Body | see below |
  ```groovy
  def flowFile = session.get();
  if(!flowFile) return;
  try {
    def inputStream = session.read(flowFile);
    def journalData = new groovy.json.JsonSlurper().parse(inputStream);
    def debitTotal  = 0.00;
    def creditTotal = 0.00;
    def totalCost = Double.parseDouble(flowFile.getAttribute('UpdatedTotalCost'));
    
    journalData.each {
      if ( it.debitAmount ) debitTotal += it.debitAmount;
      if ( it.creditAmount ) creditTotal += it.creditAmount;
    }

    inputStream.close();
    
    flowFile = session.putAttribute(flowFile, 'webcrd.balanced', String.valueOf(debitTotal == totalCost && creditTotal == totalCost));
    session.transfer(flowFile, REL_SUCCESS);
  } catch(e) {
    log.error("Error while validating journal entries", e);
    session.transfer(flowFile, REL_FAILURE);
  }
  ```

* **Route on Validation Result** (RouteOnAttribute)

  | Property | Value |
  | -------- | ----- |
  | Routing Strategy | Route to 'matched' if all match |
  | webcrd.balanced | ${webcrd.balanced:equals('true')} |

* **Merge to Single FlowFile (60 secs)** (MergeRecord)

  | Property | Value |
  | -------- | ----- |
  | Record Reader | Reader - JSON - Use Schema Registry |
  | Record Writer | Writer - JSON Array - Schema Name |
  | Minimum Number of Records | 1000000 |
  | Maximum Number of Records | 1000000 |
  | Max Bin Age | #{MaxBinAge} |
  | Maximum Number of Bins | 1 |

* **Remove Unnecessary Attributes** (UpdateAttribute)

  | Property | Value |
  | -------- | ----- |
  | Delete Attributes Expression | (webcrd\.api\.success\|webcrd\.balanced\|writer\.schema\.name\|reader\.schema\.name) |

* **Query Consumer Features** (LookupRecord)

  | Property | Value |
  | -------- | ----- |
  | Record Reader | Reader - JSON - Infer Schema |
  | Record Writer | Writer - JSON Array - Inherit Schema |
  | Lookup Service | LookupService - SQL - Consumer Journal Features |
  | Result RecordPath | / |
  | Record Result Contents | Insert Record Fields |
  | key | concat(/consumerId,'\_',/journalSourceName,'\_',/journalCategoryName) |

* **Req'd Flattened Journal Attributes** (PartitionRecord)

  | Property | Value |
  | -------- | ----- |
  | Record Reader | Reader - JSON - Infer Schema |
  | Record Writer | Writer - JSON Array - Inherit Schema |
  | accounting.date | /accountingDate |
  | accounting.period | /accountingPeriod |
  | boundary.system | /boundaryApplicationName |
  | consumer.ref.id | /consumerReferenceId |
  | consumer.tracking.id | /consumerTrackingId |
  | glide.extract.enabled | /glide_extract_enabled_flag |
  | glide.summarization.enabled | /glide_summarization_enabled_flag |
  | journal.category | /journalCategoryName |
  | journal.name | /journalName |
  | journal.source | /journalSourceName |
  | kafka.key | /requestSourceId |

* **Req'd Validated Journal Attributes** (ExecuteGroovyScript)

  | Property | Value |
  | -------- | ----- |
  | Script Body | see below |
  ```groovy
  def flowFile = session.get();
  if(!flowFile) return;
  try {
    def inputStream = session.read(flowFile);
    def journalData = new groovy.json.JsonSlurper().parse(inputStream);
    def debitTotal  = 0.00;
    def creditTotal = 0.00;
    def glTotal     = 0.00;
    def ppmTotal    = 0.00;

    journalData.each {
      if ( it.debitAmount ) debitTotal += it.debitAmount;
      if ( it.creditAmount ) creditTotal += it.creditAmount;
      if ( it.lineType == "ppmSegments" ) {
        if ( it.debitAmount ) ppmTotal += it.debitAmount;
        if ( it.creditAmount ) ppmTotal -= it.creditAmount;
      } else {
        if ( it.debitAmount ) glTotal += it.debitAmount;
        if ( it.creditAmount ) glTotal -= it.creditAmount;
      }
    }

    inputStream.close();
    flowFile = session.putAttribute(flowFile, 'journal.debits', debitTotal.toString());
    flowFile = session.putAttribute(flowFile, 'journal.credits', creditTotal.toString());
    flowFile = session.putAttribute(flowFile, 'gl.total', glTotal.toString());
    flowFile = session.putAttribute(flowFile, 'ppm.total', ppmTotal.toString());
    session.transfer(flowFile, REL_SUCCESS);
  } catch(e) {
    log.error("Error while totaling journal entries", e);
    session.transfer(flowFile, REL_FAILURE);
  }
  ```

* **Set Schema to validated** (UpdateAttribute)

  | Property | Value |
  | -------- | ----- |
  | schema.name | in.#{instance_id}.internal.json.gl_journal_validated-value |

* **Remove Extra Fields** (ConvertRecord)

  | Property | Value |
  | -------- | ----- |
  | Record Reader | Reader - JSON - Infer Schema |
  | Record Writer | Writer - JSON Array - Schema Name |

* ***WAIT/NOTIFY SPLIT PATH - INPUT GOES TO "Get Fields Required for Staging" AND "Wait for successful persistence"***

* **Get Fields Required for Staging** (QueryRecord)

  | Property | Value |
  | -------- | ----- |
  | Record Reader | Reader - JSON - Infer Schema |
  | Record Writer | Writer - JSON Array - Inherit Schema |
  | query | SELECT DISTINCT externalSystemIdentifier AS "order_id", CURRENT_TIMESTAMP AS "last_update_date" FROM FLOWFILE |

* **Insert into Staging as Complete** (PutDatabaseRecord) (w/RetryFlowFile)

  | Property | Value |
  | -------- | ----- |
  | Record Reader | Reader - JSON - Infer Schema |
  | Database Type | PostgreSQL |
  | Statement Type | INSERT |
  | Database Connection Pooling Service | DB - Postgres - Integrations |
  | Schema Name | #{instance_id}_staging |
  | Table Name | repo_webcrd_billing |

* **Notify persistence successful** (Notify)

  | Property | Value |
  | -------- | ----- |
  | Release Signal Identifier | ${fragment.identifier} |
  | Distributed Cache Service | DistributedCacheClient - Memory Only |

* **Wait for successful persistence** (Wait)

  | Property | Value |
  | -------- | ----- |
  | Release Signal Identifier | ${fragment.identifier} |
  | Target Signal Count | ${fragment.count} |
  | Distributed Cache Service | DistributedCacheClient - Memory Only |

* **Publish to Validated Topic** (PublishKafka)

  | Property | Value |
  | -------- | ----- |
  | Kafka Brokers | #{kafka_broker_list} |
  | Topic Name | in.#{instance_id}.internal.json.gl_journal_validated |
  | Delivery Guarantee | Guarantee Replicated Delivery |
  | Attributes to Send as Headers (Regex) | .* |
  | Kafka Key | ${kafka.key} |

* **Split to 1 Record per FlowFile** (SplitRecord)

  | Property | Value |
  | -------- | ----- |
  | Record Reader | Reader - JSON - Infer Schema |
  | Record Writer | Writer - JSON Array - Inherit Schema |
  | Record Per Split | 1 |

* **Select Distinct OrderId** (QueryRecord)

  | Property | Value |
  | -------- | ----- |
  | Record Reader | Reader - JSON - Infer Schema |
  | Record Writer | Writer - JSON One-Per-Line - Inherit Schema |
  | Include Zero Record FlowFiles | false |
  | query | SELECT DISTINCT ExternalSystemIdentifier AS "OrderId" FROM FlowFile |

* **Extract OrderId to Attribute** (EvaluateJsonPath)

  | Property | Value |
  | -------- | ----- |
  | Destination | flowfile-attribute |
  | Path Not Found Behavior | warn |
  | OrderId | $.OrderId |

* **Search Orders XML Request** (ReplaceText)

  | Property | Value |
  | -------- | ----- |
  | Replacement Value | see below |
  | Replacement Strategy | Always Replace |
  | Evaluation Mode | Entire text |
  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <soapenv:Body>
          <SearchOrders xmlns="http://www.rocsoft.com/services/order/types" xmlns:s="http://www.rocsoft.com/services/types">
              <s:SharedKey>#{SharedKey}</s:SharedKey>
              <SearchCriteria>
                  <OrderIds><s:Value>${OrderId}</s:Value></OrderIds>
              </SearchCriteria>
          </SearchOrders>
      </soapenv:Body>
  </soapenv:Envelope>
  ```

* **Search Orders HTTP POST** (InvokeHTTP) (w/RetryFlowFile)

  | Property | Value |
  | -------- | ----- |
  | HTTP Method | POST |
  | Remote URL | #{WebCRD SOAP API URL} |
  | SOAPAction | SearchOrders |

* **Extract ShippingId to Attribute** (EvaluateXPath)

  | Property | Value |
  | -------- | ----- |
  | Destination | flowfile-attribute |
  | Return Type | string |
  | ShippingId | //*[local-name()='ShippingID']/text() |

* **Update Order XML Request** (ReplaceText)

  | Property | Value |
  | -------- | ----- |
  | Replacement Value | see below |
  | Replacement Strategy | Always Replace |
  | Evaluation Mode | Entire text |
  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <soapenv:Body>
          <UpdateOrder xmlns="http://www.rocsoft.com/services/order/types" xmlns:s="http://www.rocsoft.com/services/types">
              <s:SharedKey>#{SharedKey}</s:SharedKey>
              <s:Order xmlns:s="http://www.rocsoft.com/order" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="Order.xsd">
                  <s:OrderID>${OrderId}</s:OrderID>
                  <s:OrderName useDefault="true"></s:OrderName>
                  <s:OrderPlacer></s:OrderPlacer>
                  <s:Site useDefault="true"></s:Site>
                  <s:Billing></s:Billing>
                  <s:Documents></s:Documents>
                  <s:Recipients>
                      <s:Recipient>
                          <s:ShippingID>${ShippingId}</s:ShippingID>
                          <s:RecipientDocuments></s:RecipientDocuments>
                          <s:TrackingNumber>${now():format("yyyy-MM-dd")}</s:TrackingNumber>
                      </s:Recipient>
                  </s:Recipients>
              </s:Order>
          </UpdateOrder>
      </soapenv:Body>
  </soapenv:Envelope>
  ```

* **Update Order HTTP POST** (InvokeHTTP) (w/RetryFlowFile)

  | Property | Value |
  | -------- | ----- |
  | HTTP Method | POST |
  | Remote URL | #{WebCRD SOAP API URL} |
  | SOAPAction | UpdateOrder |

* **Extract Success to Attribute** (EvaluateXPath)

  | Property | Value |
  | -------- | ----- |
  | Destination | flowfile-attribute |
  | Return Type | string |
  | webcrd.api.success | //*[local-name()='Success']/text() |

* **Route on Success** (RouteOnAttribute)

  | Property | Value |
  | -------- | ----- |
  | Routing Strategy | Route to 'matched' if all match |
  | success | ${webcrd.api.success:equals('true')} |

#### Pipeline Dependencies

* WebCRD server hosted in AdminIT IM (SOAP API)
* Integrations PgSQL Database
  * Schema: staging
    * Table: repo_webcrd_billing
* LookupService - SQL - Consumer Journal Features
* LookupService - Scripted - Segment String Extraction (6.6.2)
* Update Pipeline Request Table PG
* Validate GL Segments PG
* Validate PPM Segments PG
* Schema Registry
  * in.#{instance_id}.internal.json.gl_journal_flattened-value
  * in.#{instance_id}.internal.json.gl_journal_validated-value
* Kafka topics
  * in.#{instance_id}.internal.json.gl_journal_validated
  * feedback.#{instance_id}.request.sftp.error
  * feedback.#{instance_id}.internal.webcrd.failure