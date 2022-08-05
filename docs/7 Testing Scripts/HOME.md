# 7 Testing Scripts

### SIT1 Testing Scenarios

| Test Scenario ID | Summary                                                | Description                                                                                      |
| ---------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------ |
| TEC-001          | TEC-001 GL-PPM Combined API GL-Only Simple Journal     | Validate GL-only 2-line journal loads as a journal in Oracle.                                    |
| TEC-002          | TEC-002 GL-PPM Combined API PPM-Only Simple Journal    | Validate PPM-only 2-line journal loads as pair of PPM costs in Oracle.                           |
| TEC-003          | TEC-003 GL-PPM Combined API GL-PPM Simple Journal      | Validate GL and PPM 2-line journal loads into both modules.                                      |
| TEC-004          | TEC-004 GL-PPM Combined API PPM-Only Two BU Journal    | Validate that a PPM journal which references projects in both business units loads into Oracle.  |
| TEC-005          | TEC-005 GL-PPM Combined API Journal Rejected by Oracle | Validate that a journal that rejects during Oracle job processing provides appropriate feedback. |
| TEC-006          | TEC-006 GL-PPM Combined SFTP Journal Processed         | Validate GL-only 2-line journal submitted via SFTP loads as a journal in Oracle.                 |
| TEC-007          | TEC-007 GL-PPM Combined SFTP Journal Rejected          | Validate that a SFTP journal rejected during pipeline processing sends feedback.                 |
| TEC-008          | TEC-008 Scm Invoice Payment Create                     | Validate that  Invoice Payment is created and that GL Journal is created                         |

[](Integrations_Test_Scenarios.csv ':include')

### SIT1 Testing Scripts

| Summary                                                | Action                                                                                                                                   | Expected Result                                                                                                                                                         |
| ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| TEC-001 GL-PPM Combined GL-Only Simple Journal         | Launch test case ERP API Testing / SIT1 / TEC-001 In Postman against SIT1 API Instance.  Record returned requestId for checking results. | "JSON Response indicating request is PENDING"                                                                                                                           |
|                                                        | Wait up to 1 minute.  Then run the query to check the action_request_status table.                                                       | "After a short time, the status of the request should be INPROCESS."                                                                                                    |
|                                                        | Wait up to 1 minute.  Run the query to check the pipeline_request table.                                                                 | A record should have been created for the request in the table.                                                                                                         |
|                                                        | Wait up to 1 minute.  Run the query to check the pipeline_job_status table.                                                              | A record with the gl_journal type should be in the table for the request.                                                                                               |
|                                                        | Wait up to 1 minute.  Run the query to check the oracle_job_status table.                                                                | A record with the gl_journal type should be in the table for the request with status INPROCESS.                                                                         |
|                                                        | Wait up to 5 minutes.  Run the query to check the oracle_job_status table.                                                               | "After the job results are generated, received and processed.  Record should now have a SUCCESS status.  job_report column should have the output report from the job." |
|                                                        | Run the query to check the pipeline_job_status table.                                                                                    | pipeline_job_status record should have changed to PROCESSED.                                                                                                            |
|                                                        | Wait up to 2 minutes.  Run the query to check the pipeline_request table.                                                                | pipeline_request record should be SUCCESS.                                                                                                                              |
|                                                        | Run the query to check the action_request_status table.                                                                                  | Status in action_request_status has changed to COMPLETE.                                                                                                                |
|                                                        | Launch ERP API Testing / SIT1 / Get Last Request Status in Postman                                                                       | Should retrieve the results and contain the job report and results.                                                                                                     |
| TEC-002 GL-PPM Combined API PPM-Only Simple Journal    | Launch test case ERP API Testing / SIT1 / TEC-002 In Postman against SIT1 API Instance.  Record returned requestId for checking results. | "JSON Response indicating request is PENDING"                                                                                                                           |
|                                                        | Wait up to 1 minute.  Then run the query to check the action_request_status table.                                                       | "After a short time, the status of the request should be INPROCESS."                                                                                                    |
|                                                        | Wait up to 1 minute.  Run the query to check the pipeline_request table.                                                                 | A record should have been created for the request in the table.                                                                                                         |
|                                                        | Wait up to 1 minute.  Run the query to check the pipeline_job_status table.                                                              | A record with the gl_journal type should be in the table for the request.                                                                                               |
|                                                        | Wait up to 1 minute.  Run the query to check the oracle_job_status table.                                                                | A record with the gl_journal type should be in the table for the request with status INPROCESS.                                                                         |
|                                                        | Wait up to 5 minutes.  Run the query to check the oracle_job_status table.                                                               | "After the job results are generated, received and processed.  Record should now have a SUCCESS status.  job_report column should have the output report from the job." |
|                                                        | Run the query to check the pipeline_job_status table.                                                                                    | pipeline_job_status record should have changed to PROCESSED.                                                                                                            |
|                                                        | Wait up to 2 minutes.  Run the query to check the pipeline_request table.                                                                | pipeline_request record should be SUCCESS.                                                                                                                              |
|                                                        | Run the query to check the action_request_status table.                                                                                  | Status in action_request_status has changed to COMPLETE.                                                                                                                |
|                                                        | Launch ERP API Testing / SIT1 / Get Last Request Status in Postman                                                                       | Should retrieve the results and contain the job report and results.                                                                                                     |
| TEC-003 GL-PPM Combined API GL-PPM Simple Journal      | Launch test case ERP API Testing / SIT1 / TEC-003 In Postman against SIT1 API Instance.  Record returned requestId for checking results. | "JSON Response indicating request is PENDING"                                                                                                                           |
|                                                        | Wait up to 1 minute.  Then run the query to check the action_request_status table.                                                       | "After a short time, the status of the request should be INPROCESS."                                                                                                    |
|                                                        | Wait up to 1 minute.  Run the query to check the pipeline_request table.                                                                 | A record should have been created for the request in the table.                                                                                                         |
|                                                        | Wait up to 1 minute.  Run the query to check the pipeline_job_status table.                                                              | A record with the gl_journal type should be in the table for the request.                                                                                               |
|                                                        | Wait up to 1 minute.  Run the query to check the oracle_job_status table.                                                                | A record with the gl_journal type should be in the table for the request with status INPROCESS.                                                                         |
|                                                        | Wait up to 5 minutes.  Run the query to check the oracle_job_status table.                                                               | "After the job results are generated, received and processed.  Record should now have a SUCCESS status.  job_report column should have the output report from the job." |
|                                                        | Run the query to check the pipeline_job_status table.                                                                                    | pipeline_job_status record should have changed to PROCESSED.                                                                                                            |
|                                                        | Wait up to 2 minutes.  Run the query to check the pipeline_request table.                                                                | pipeline_request record should be SUCCESS.                                                                                                                              |
|                                                        | Run the query to check the action_request_status table.                                                                                  | Status in action_request_status has changed to COMPLETE.                                                                                                                |
|                                                        | Launch ERP API Testing / SIT1 / Get Last Request Status in Postman                                                                       | Should retrieve the results and contain the job report and results.                                                                                                     |
| TEC-004 GL-PPM Combined API PPM-Only Two BU Journal    | Launch test case ERP API Testing / SIT1 / TEC-004 In Postman against SIT1 API Instance.  Record returned requestId for checking results. | "JSON Response indicating request is PENDING"                                                                                                                           |
|                                                        | Wait up to 1 minute.  Then run the query to check the action_request_status table.                                                       | "After a short time, the status of the request should be INPROCESS."                                                                                                    |
|                                                        | Wait up to 1 minute.  Run the query to check the pipeline_request table.                                                                 | A record should have been created for the request in the table.                                                                                                         |
|                                                        | Wait up to 1 minute.  Run the query to check the pipeline_job_status table.                                                              | A record with the gl_journal type should be in the table for the request.                                                                                               |
|                                                        | Wait up to 1 minute.  Run the query to check the oracle_job_status table.                                                                | A record with the gl_journal type should be in the table for the request with status INPROCESS.                                                                         |
|                                                        | Wait up to 5 minutes.  Run the query to check the oracle_job_status table.                                                               | "After the job results are generated, received and processed.  Record should now have a SUCCESS status.  job_report column should have the output report from the job." |
|                                                        | Run the query to check the pipeline_job_status table.                                                                                    | pipeline_job_status record should have changed to PROCESSED.                                                                                                            |
|                                                        | Wait up to 2 minutes.  Run the query to check the pipeline_request table.                                                                | pipeline_request record should be SUCCESS.                                                                                                                              |
|                                                        | Run the query to check the action_request_status table.                                                                                  | Status in action_request_status has changed to COMPLETE.                                                                                                                |
|                                                        | Launch ERP API Testing / SIT1 / Get Last Request Status in Postman                                                                       | Should retrieve the results and contain the job report and results.                                                                                                     |
| TEC-005 GL-PPM Combined API Journal Rejected by Oracle | Launch test case ERP API Testing / SIT1 / TEC-005 In Postman against SIT1 API Instance.  Record returned requestId for checking results. | "JSON Response indicating request is PENDING"                                                                                                                           |
|                                                        | Wait up to 1 minute.  Then run the query to check the action_request_status table.                                                       | "After a short time, the status of the request should be INPROCESS."                                                                                                    |
|                                                        | Wait up to 1 minute.  Run the query to check the pipeline_request table.                                                                 | A record should have been created for the request in the table.                                                                                                         |
|                                                        | Wait up to 1 minute.  Run the query to check the pipeline_job_status table.                                                              | A record with the gl_journal type should be in the table for the request.                                                                                               |
|                                                        | Wait up to 1 minute.  Run the query to check the oracle_job_status table.                                                                | A record with the gl_journal type should be in the table for the request with status INPROCESS.                                                                         |
|                                                        | Wait up to 5 minutes.  Run the query to check the oracle_job_status table.                                                               | "After the job results are generated, received and processed.  Record should now have a ERROR status.  job_report column should have the output report from the job."   |
|                                                        | Run the query to check the pipeline_job_status table.                                                                                    | pipeline_job_status record should have changed to ERROR.                                                                                                                |
|                                                        | Wait up to 2 minutes.  Run the query to check the pipeline_request table.                                                                | pipeline_request record should be ERROR.                                                                                                                                |
|                                                        | Run the query to check the action_request_status table.                                                                                  | Status in action_request_status has changed to ERROR.                                                                                                                   |
|                                                        | Launch ERP API Testing / SIT1 / Get Last Request Status in Postman                                                                       | Should retrieve the results and contain the job report and results.                                                                                                     |
| TEC-006 GL-PPM Combined SFTP Journal Processed         | Upload file journal.UCD_Touchnet.TEC006_(timestamp).json to GoAnywhere.                                                                  | "File is uploaded successfully"                                                                                                                                         |
|                                                        | Look in S3 to confirm that file was transfered from GoAnywhere                                                                           | journal.UCD_Touchnet.TEC006_(timestamp).json will be present in S3 location.                                                                                            |
|                                                        | Wait up to 1 minute.  Run the query to check the pipeline_request table.                                                                 | A record should have been created for the request in the table with a source type of sftp and source ID of the file name.                                               |
|                                                        | Wait up to 1 minute.  Run the query to check the pipeline_job_status table.                                                              | A record with the gl_journal type should be in the table for the request.                                                                                               |
|                                                        | Wait up to 1 minute.  Run the query to check the oracle_job_status table.                                                                | A record with the gl_journal type should be in the table for the request with status INPROCESS.                                                                         |
|                                                        | Wait up to 5 minutes.  Run the query to check the oracle_job_status table.                                                               | "After the job results are generated, received and processed.  Record should now have a SUCCESS status.  job_report column should have the output report from the job." |
|                                                        | Run the query to check the pipeline_job_status table.                                                                                    | pipeline_job_status record should have changed to PROCESSED.                                                                                                            |
|                                                        | Wait up to 2 minutes.  Run the query to check the pipeline_request table.                                                                | pipeline_request record should be SUCCESS.                                                                                                                              |
|                                                        | Check inbox of email used in the UCD Touchnet consumer ID.                                                                               | Email was received and contains correct contents.                                                                                                                       |
| TEC-007 GL-PPM Combined SFTP Journal Rejected          | Upload file journal.UCD_Touchnet.TEC007_(timestamp).json to GoAnywhere.                                                                  | "File is uploaded successfully"                                                                                                                                         |
|                                                        | Look in S3 to confirm that file was transfered from GoAnywhere                                                                           | journal.UCD_Touchnet.TEC007_(timestamp).json will be present in S3 location.                                                                                            |
|                                                        | Wait up to 1 minute.  Run the query to check the pipeline_request table.                                                                 | A record should have been created for the request in the table.                                                                                                         |
|                                                        | Wait up to 1 minute.  Run the query to check the pipeline_job_status table.                                                              | A record with the gl_journal type should be in the table for the request.                                                                                               |
|                                                        | Wait up to 1 minute.  Run the query to check the oracle_job_status table.                                                                | A record with the gl_journal type should be in the table for the request with status INPROCESS.                                                                         |
|                                                        | Wait up to 5 minutes.  Run the query to check the oracle_job_status table.                                                               | "After the job results are generated, received and processed.  Record should now have a ERROR status.  job_report column should have the output report from the job."   |
|                                                        | Run the query to check the pipeline_job_status table.                                                                                    | pipeline_job_status record should have changed to ERROR.                                                                                                                |
|                                                        | Wait up to 2 minutes.  Run the query to check the pipeline_request table.                                                                | pipeline_request record should be ERROR.                                                                                                                                |
|                                                        | Check inbox of email used in the UCD Touchnet consumer ID.                                                                               | Email was received and contains correct contents.                                                                                                                       |
| TEC-008 Scm Invoice Payment Create                     | Create AP Invoices and GL Journal Payment           | Check in Postman requestStatus  : "PENDING"                                                                                                                                         |
|                                                        | Wait up to 1 minute.  Run the query to check the pipeline_request table.                                                                 | A record should have been created for the request in the table.                                                                                                         |
|                                                        | Wait up to 1 minute.  Run the query to check the pipeline_job_status table.                                                              | Two records with the gl_journal and ap_invoices types should be in the table for the request.                                                                                               |
|                                                        | Wait up to 1 minute.  Run the query to check the oracle_job_status table.                                                                | A record with the gl_journal and ap_invoices type should be in the table for the request with status INPROCESS.                                                                         |
|                                                        | Wait up to 5 minutes.  Run the query to check the oracle_job_status table.                                                               | "After the job results are generated, received and processed.  Both record should now have a SUCCESS status."   |
|                                                        | Run the query to check the pipeline_job_status table.                                                                                    | pipeline_job_status record should have changed to PROCESSED.                                                                                                                |
|                                                        | Wait up to 2 minutes.  Run the query to check the pipeline_request table.                                                                | pipeline_request record should be PROCESSED.                                                                                                                                |

[](Integrations_Test_Scripts.csv ':include')

<!-- Regex Search/Replace to convert CSV to Markdown table
Search: ([^",]*|"[^"]*"),([^",]*|"[^"]*"),([^",]*|"[^"]*"),([^",]*|"[^"]*"),([^",]*|"[^"]*"),([^",]*|"[^"]*"),([^",]*|"[^"]*"),([^",]*|"[^"]*"),([^",]*|"[^"]*"),.*
Replace: | $5 | $7 | $9 |
-->

### Scripts to Use to Confirm Results

#### Get Action Request Information

```sql
SET search_path to dev4_api
/
select 'action_request_status' AS table_name, id, request_id, consumer_id, operation_name, request_date_time, request_status, last_status_date_time
from action_request_status
WHERE request_date_time > now() - make_interval(hours => 1)
order by id desc
/
```

#### Get Pipeline Request Information

```sql
select 'pipeline_request' AS table_name, id, source_request_type, source_request_id, consumer_id, request_status, request_date_time, error_messages
from pipeline_request
WHERE request_date_time > now() - make_interval(hours => 1)
order by id desc limit 5
/
```

#### Get Pipeline Job Status Information

```sql
select 'pipeline_job_status' AS table_name, id, source_request_type, source_request_id, job_id, job_status, processed_date_time, assigned_job_id
from pipeline_job_status
WHERE insert_date_time > DATE_TRUNC('day', now())
ORDER BY id desc limit 10
/
```

#### Get Oracle Job Status Information

```sql
select 'oracle_job_status' AS table_name, id, job_request_id, job_type_name, source_name, job_submit_ts, job_status, notification_sent_flag, request_source_type, request_source_id, job_report
from oracle_job_status --where notification_sent_flag = 'Y' order by 1 desc
WHERE job_submit_ts > DATE_TRUNC('day', now())
order by id desc limit 10
/
```

### SIT1 Test Data

#### GraphQL Mutation to Send GL Journal

```graphql
mutation ($data: GlJournalRequestInput!) {
    glJournalRequest(data: $data) {
        requestStatus {
            consumerTrackingId
            requestDateTime
            processedDateTime
            requestId
            requestStatus
            errorMessages
        }
        validationResults {
            valid
            errorMessages
            messageProperties
        }
    }
}
```

#### TEC-001 Simple 2-Line GL-Only Journal

```json
{ "data": {
  "header": {
    "boundaryApplicationName": "TESTING_APP",
    "consumerId": "UCD Touchnet",
    "consumerReferenceId": "CONSUMER_BATCH_NBR",
    "consumerTrackingId": "{{consumerTrackingId}}",
    "consumerNotes": ""
  },
  "payload": {
    "journalSourceName": "UCD Touchnet",
    "journalCategoryName": "UCD Recharge",
    "journalName": "MySystem Recharges for July 2022",
    "journalReference": "BATCH_12345",
    "accountingDate": "2022-05-01",
    "accountingPeriodName": "Apr-22",
    "journalLines": [
      {
        "glSegments": {
          "entity": "3110",
          "fund": "13U00",
          "department": "9304510",
          "purpose": "68",
          "account": "536400"
        },
        "debitAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      },
      {
        "glSegments": {
          "entity": "3110",
          "fund": "13U00",
          "department": "9300531",
          "purpose": "68",
          "account": "770000"
        },

        "creditAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      }
    ]
  }
}}
```

#### TEC-002 Simple 2-Line PPM-Only Journal

```json
{ "data": {
  "header": {
    "boundaryApplicationName": "TESTING_APP",
    "consumerId": "UCD Touchnet",
    "consumerReferenceId": "CONSUMER_BATCH_NBR",
    "consumerTrackingId": "{{consumerTrackingId}}",
    "consumerNotes": ""
  },
  "payload": {
    "journalSourceName": "UCD Touchnet",
    "journalCategoryName": "UCD Recharge",
    "journalName": "MySystem Recharges for July 2022",
    "journalReference": "BATCH_12345",
    "accountingDate": "2022-05-01",
    "accountingPeriodName": "Apr-22",
    "journalLines": [
      {
        "ppmSegments": {
            "project": "K30LEV8D70",
            "task": "TASK01",
            "organization": "1600121",
            "expenditureType": "770000",
            "award": "K328D70",
            "fundingSource": "20008"
        },
        "debitAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      },
      {
        "ppmSegments": {
            "project": "KS0JLOSFEL",
            "task": "TASK01",
            "organization": "1600121",
            "expenditureType": "770000",
            "award": "K334D16",
            "fundingSource": "26060"
        },

        "creditAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      }
    ]
  }
}}
```

#### TEC-003 Simple GL-PPM Combined Journal

```json
{ "data": {
  "header": {
    "boundaryApplicationName": "TESTING_APP",
    "consumerId": "UCD Touchnet",
    "consumerReferenceId": "CONSUMER_BATCH_NBR",
    "consumerTrackingId": "{{consumerTrackingId}}",
    "consumerNotes": ""
  },
  "payload": {
    "journalSourceName": "UCD Touchnet",
    "journalCategoryName": "UCD Recharge",
    "journalName": "MySystem Recharges for July 2022",
    "journalReference": "BATCH_12345",
    "accountingDate": "2022-05-01",
    "accountingPeriodName": "Apr-22",
    "journalLines": [
      {
        "glSegments": {
          "entity": "3110",
          "fund": "13U00",
          "department": "9304510",
          "purpose": "68",
          "account": "536400"
        },
        "creditAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      },
      {
        "ppmSegments": {
            "project": "KS0JLOSFEL",
            "task": "TASK01",
            "organization": "1600121",
            "expenditureType": "770000",
            "award": "K334D16",
            "fundingSource": "26060"
        },

        "debitAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      }
    ]
  }
}}
```

#### TEC-004 GL-PPM Combined API PPM-Only Two BU Journal

**TODO** Find non-sponsored project to test with

#### TEC-005 GL-PPM Combined API Journal Rejected by Oracle

**TODO** Find CVR rule which is not checked by API or pipeline

#### TEC-006 GL-PPM Combined SFTP Journal Processed

[](journal.UCD_Touchnet.TEC006_timestamp.json ':include')

#### TEC-007 GL-PPM Combined SFTP Journal Rejected

> Same as the TEC-006 payload but with an invalid fund number on one line.

[](journal.UCD_Touchnet.TEC007_timestamp.json ':include')

#### TEC-008 Scm Invoice Payment Sample

```json
{
  "data": {
    "header": {
      "boundaryApplicationName": "TESTING_APP",
      "consumerId": "UCD Aggieship",
      "consumerReferenceId": "A_UNIQUE_ID1",
       "consumerTrackingId": "{{consumerTrackingId}}"
    },
    "payload": {
        "invoiceSourceCode": "UCD Aggieship",
      "invoiceNumber": "111113",
      "businessUnit": "SCM",
      "invoiceDate": "2022-01-01",
      "supplierNumber": "1055566",
      "supplierSiteCode": "PAY-1",
      "invoiceDescription": "Office Supply",
      "invoiceType": "STANDARD",
      "invoiceAmount": 1.25,
      "paymentTerms" : "Immediate",
      "invoiceLines": [
        {
          "itemName": "ITEM_X",
          "itemDescription": "Something meaningful",
          "lineAmount": 1.25,
          "lineType": "ITEM",
          "unitOfMeasure": "FOOT",
          "purchaseOrderLineNumber": 1,
          "quantity": 1,
          "unitPrice": 1.25,
          "glSegments": {
            "activity": "210521",
            "purpose": "68",
            "program": "000",
            "department": "9100000",
            "entity": "3110",
            "fund": "13U00",
            "account": "770000"
          }
        }
      ]
    }
  }
}
```
