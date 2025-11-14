# 3.2.3.0 Common Types

### Common Action Request Data Types

#### Input Types

##### `ActionRequestHeaderInput`

> This is the default field set for all action requests.  It part of all action requests as the `header` attribute.

| Property Name           | Type                     | Notes                                                                                                                                                                                                                                                             |
| ----------------------- | ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| consumerTrackingId      | NonEmptyTrimmedString80  | For ID internal to consumer system to allow tracking. Will not be transmitted to Oracle.                                                                                                                                                                          |
| consumerReferenceId     | NonEmptyTrimmedString80! | Identifier provided by the consumer which usually references the source record within their system.  Does not need to be unique. Will not be transmitted to Oracle.                                                                                               |
| consumerNotes           | NonEmptyTrimmedString240 | Consumer text which will be stored in the API system. Will not be transmitted to Oracle.                                                                                                                                                                          |
| boundaryApplicationName | NonEmptyTrimmedString80! | Identifier for the boundary application originating the request.                                                                                                                                                                                                  |
| consumerId              | NonEmptyTrimmedString80  | ID of the consumer which must match the authentication data.  Not required for API calls as will be filled in by the server.                                                                                                                                      |
| batchRequest            | Boolean                  | If set to true, allows processing of this request to be delayed and combined with other compatible requests if supported by the request type.  It will be ignored if not supported.  Length of delay and pickup time is determined during integration processing. |

<!-- | callbackURL             | URL                      | URL for which to send back results when this journal is processed.                                                                                                  | -->


#### Support Types

##### `GlSegmentInput`

| Property Name | Type               | Notes |
| ------------- | ------------------ | ----- |
| entity        | ErpEntityCode!     |       |
| fund          | ErpFundCode!       |       |
| department    | ErpDepartmentCode! |       |
| account       | ErpAccountCode!    |       |
| purpose       | ErpPurposeCode     |       |
| project       | ErpProjectCode     |       |
| program       | ErpProgramCode     |       |
| activity      | ErpActivityCode    |       |

<!-- | interEntity   | ErpInterEntityCode |       | -->
<!-- | flex1   | ErpFlex1Code |       | -->
<!-- | flex2   | ErpFlex2Code |       | -->

##### `PpmSegmentInput`

| Property Name   | Type                    | Notes |
| --------------- | ----------------------- | ----- |
| project         | PpmProjectNumber!       |       |
| organization    | PpmOrganizationCode!    |       |
| expenditureType | PpmExpenditureTypeCode! |       |
| task            | PpmTaskNumber!          |       |
| award           | PpmAwardNumber          |       |
| fundingSource   | PpmFundingSourceNumber  |       |

##### `GlideInput`

| Property Name     | Type                    | Notes           |
| ----------------- | ----------------------- | --------------- |
| lineDescription   | String                  | 100 Characters  |
| journalLineNumber | Float                   |                 |
| transactionDate   | Date                    | yyyy-mm-dd      |
| udfNumeric1       | Float                   |                 |
| udfNumeric2       | Float                   |                 |
| udfNumeric3       | Float                   |                 |
| udfDate1          | Date                    | yyyy-mm-dd      |
| udfDate1          | Date                    | yyyy-mm-dd      |
| udfString1        | String                  | 50 Characters   |
| udfString2        | String                  | 50 Characters   |
| udfString3        | String                  | 50 Characters   |
| udfString4        | String                  | 50 Characters   |
| udfString5        | String                  | 50 Characters   |

#### Output Types

##### `XxxxxxxxRequestStatusOutput`

> Each action request operation will have a matching Output type named like the above.  Each of these will have the properties shown below and possibly additional values available for completed requests if it is possible to extract generated values from the ERP.
>
> An example of one of these additional values would be for submitted journals, that we would be able to return the ERP-generated journal ID created during data import.

| Property Name     | Type                 | Notes                                                                                                          |
| ----------------- | -------------------- | -------------------------------------------------------------------------------------------------------------- |
| requestStatus     | ActionRequestStatus! | Overall status of the action request                                                                           |
| validationResults | ValidationResponse   | Errors found when validatating the payload data.  These must be corrected before the request will be accepted. |

##### `ActionRequestStatus`

> Response provided when the consumer submits a request.  This will be the `requestStatus` property under any action request response.

| Property Name           | Type                     | Notes                                                                       |
| ----------------------- | ------------------------ | --------------------------------------------------------------------------- |
| requestId               | UUID                     | Unique Request ID generated by API server.                                  |
| consumerId              | NonEmptyTrimmedString80! | Identifier of the API consumer making the request.                          |
| consumerTrackingId      | NonEmptyTrimmedString80  | Tracking ID provided by the consumer                                        |
| consumerReferenceId     | NonEmptyTrimmedString80! | Reference ID provided by the consumer                                       |
| consumerNotes           | NonEmptyTrimmedString240 | Notes provided by consumer when they made the request.                      |
| boundaryApplicationName | NonEmptyTrimmedString80! | Identifier for the boundary application originating the request.            |
| operationName           | String!                  | Name of the operation called.                                               |
| requestDateTime         | DateTime!                | Server-recorded time the request was received.                              |
| requestStatus           | RequestStatus!           | Current Status of the request. (enum)                                       |
| lastStatusDateTime      | DateTime!                | Timestamp of the last time the status changed.                              |
| processedDateTime       | DateTime                 | Timestamp when the request finished processing.                             |
| errorMessages           | \[String!\]              | Array of error messages, if any.                                            |
| statusRequestPayload    | JSON                     | Full JSON of the GraphQL request needed to check the status of the request. |
| actionRequestPayload    | JSON                     | Full JSON of the original GraphQL action request.                           |
| resultAttributes        | JSON                     | JSON object with key/value pairs containing Oracle-generated identifiers.   |

##### `ValidationResponse`

> Common data structure for reporting back issues found when validating data against ERP requirements.  This does not include GraphQL formatting or content problems, which are reported back in an `errors` object per the GraphQL specification.

| Property Name     | Type        | Notes                                                                                                                            |
| ----------------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------- |
| valid             | Boolean!    | Whether the overall validation succeeded or failed.                                                                              |
| errorMessages     | \[String!\] | Array of all errors found during validation.  The failed property is in the matching index in the `messageProperties` list.      |
| messageProperties | \[String!\] | Property names which failed validation.  May be blank if the validation applies to the entire payload or no particular property. |

##### `enum RequestStatus`

##### `RequestStatus`

> Status options within the [ActionRequestStatus]({{Types.ActionRequestStatus}}) that reflect the states a request can be in.

| Enum Value  | Description                                                                                                                                                           |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `COMPLETE`  | If Callback URL Provided: Request has been processed, and the callback was successfully contacted.  Or, request has been processed, and no callback URL was provided. |
| `ERROR`     | There was an error processing the request after it was picked up.                                                                                                     |
| `INPROCESS` | Request has been picked up for processing                                                                                                                             |
| `PENDING`   | Request has been submitted to the server, but not validated or processed.                                                                                             |
| `PROCESSED` | Request has been processed, but the callback has not been completed.                                                                                                  |
| `REJECTED`  | There was a validation error in the request payload data.                                                                                                             |
| `STALE`     | If Callback URL Provided: Request has been processed, but repeated attempts to contact the callback have failed and no more will be tried.                            |


<!--BREAK-->
### Data Object: ProcessingCheckpoint

Tracked points along the processing of a request.  May be used for troubleshooting requests which fail or never complete processing.

#### Access Controls

* Required Role: `PUBLIC`

#### Data Source

* Local Table/View: `PIPELINE_REQUEST_CHECKPOINT`
* Data Origin:
  * System: N/A
  * Extract Objects:
  * Underlying Database Objects:

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| pipelineId         | NonEmptyTrimmedString50!  |                |                 |               | Identifier of the pipeline which generated the checkpoint.  Multiple pipelines may be used in the processing of a request. |
| checkpointId       | NonEmptyTrimmedString50!  |                |                 |               | Identifier of the checkpoint.  This is an arbirtary string which is unique within a pipeline and roughly indicates the activity that completed just before the checkpoint.  It is mainly meaningful to the integrations team. |
| checkpointType     | ProcessingCheckpointType! |                |                 |               | Whether the checkpoint was reached in the normal processing path or in an error or failure path. |
| checkpointDateTime | DateTime!                 |                |                 |               | Time this checkpoint entry was logged to the database. |

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ProcessingResult

Result of the attempt to process the action request in the destination system

#### Access Controls

* Required Role: `PUBLIC`

#### Data Source

* Local Table/View: `PIPELINE_REQUEST`
* Data Origin:
  * System: N/A
  * Extract Objects:
  * Underlying Database Objects:

##### Properties

| Property Name           | Data Type               | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ----------------------- | ----------------------- | :------------: | :-------------: | ------------- | ----- |
| status                  | String!                 |                |                 |               |  |
| requestDateTime         | DateTime!               |                |                 |               |  |
| lastStatusCheckDateTime | DateTime                |                |                 |               |  |
| processedDateTime       | DateTime                |                |                 |               | Time the request was noted as completed processing, whether successful or not. |
| errorMessages           | String                  |                |                 |               | Any error messages generated during processing. |
| hasWarnings             | Boolean!                |                |                 |               | Whether any warnings were generated during processing. |
| warningMessages         | JSON                    |                |                 |               | Array of warnings generated during processing. |
| jobs                    | [RequestJobResult!]     |                |                 |               | List of the individual destination-system jobs that were required to process this request. |
| checkpoints             | [ProcessingCheckpoint!] |                |                 |               | Checkpoints reached during the processing of the request.  Not all action requests will have checkpoints. |

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: RequestJobResult

Results of the job as submitted to the ERP system.

#### Access Controls

* Required Role: `PUBLIC`

#### Data Source

* Local Table/View: `PIPELINE_JOB_STATUS`
* Data Origin:
  * System: N/A
  * Extract Objects:
  * Underlying Database Objects:

##### Properties

| Property Name     | Data Type | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ----------------- | --------- | :------------: | :-------------: | ------------- | ----- |
| jobId             | String!   |                |                 |               | Identifier of the type of job submitted. |
| jobStatus         | String!   |                |                 |               | Current status of the oracle job. |
| assignedJobId     | String    |                |                 |               | Optional value which the pipeline generates as part of the data file to identify the records that need to be processed.  This is the Group ID for GL entries and the Batch Name for PPM Costs.  Not all jobs will have a value to place here. |
| jobReport         | String    |                |                 |               | Job report or log output from executing the request on the ERP system. |
| failedRecords     | String    |                |                 |               | Records which caused the job to fail. |
| completedDateTime | DateTime  |                |                 |               | Time the job completion was recorded. |

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: RequestJobResultValues

Generated values related to request which have been extracted from the downstream system.  This property may not be filled in until some time after the process has completed, as data may have to be retrieved from scheduled data extracts.

#### Access Controls

* Required Role: `PUBLIC`

#### Data Source

* Local Table/View: `undefined`

##### Properties

| Property Name | Data Type              | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------- | ---------------------- | :------------: | :-------------: | ------------- | ----- |
| jobType       | String!                |                |                 |               | The identifier of the type of job executed that generated the values.  This will be a value like 'gl_journal' or 'ppm_costs'. |
| values        | [RequestResultValue!]! |                |                 |               | The values extracted from the downstream system for the given job. |

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: RequestResultValue

A single value extracted from the downstream system.

#### Access Controls

* Required Role: `PUBLIC`

#### Data Source

* Local Table/View: `undefined`

##### Properties

| Property Name | Data Type | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------- | --------- | :------------: | :-------------: | ------------- | ----- |
| name          | String!   |                |                 |               | Integration determined name of the value.  This will match the name in the downstream system if possible. |
| value         | String    |                |                 |               | Value extracted from the downstream system. |

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: RequestResultValues

Values related to request which have been extracted from the downstream system.  This property may not be filled in until some time after the process has completed, as data may have to be retrieved from scheduled data extracts.

#### Access Controls

* Required Role: `PUBLIC`

#### Data Source

* Local Table/View: `undefined`

##### Properties

| Property Name   | Data Type                  | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| --------------- | -------------------------- | :------------: | :-------------: | ------------- | ----- |
| valuesExtracted | Boolean!                   |                |                 |               | Whether the Values have yet been extracted from the downstream system. |
| jobs            | [RequestJobResultValues!]! |                |                 |               | The values extracted from the downstream system. |

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.
