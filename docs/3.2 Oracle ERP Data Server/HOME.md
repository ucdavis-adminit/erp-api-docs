# 3.2 Oracle ERP Data Server

This server is responsible for exposing data from a local copy of the Oracle ERP data through a GraphQL API.  It will connect directly to a local database as needed to retrieve the data.  This database will be populated regularly from the Oracle ERP.  Retrievals from the database will be cached within the server for a configured period of time.

It will also provide operations for "Action Requests" for sending updates into Oracle.  Action Requests are asynchronous in that the request will not be sent to Oracle during the initial call.  The request will be recorded and queued for submission to the ERP system.  Each request will be assigned a unique identifier, and the caller given a location to call back to check on the status and obtain results of the call once it has completed.

### Using the API (IN PROGRESS)

The ERP data and operations are exposed to boundary systems via a GraphQL API.  GraphQL is a specification for executing queries and mutations in a standard manner.  The underlying technology is just JSON over HTTP.  GraphQL is a specification for the contents of the JSON messages.  GraphQL allows us to tightly define the data model and the allowed contents within fields of the data model.  As such it is (almost) impossible to send incorrectly formatted data to the API when using a GraphQL-aware tool.

See: <https://graphql.org/>

This document will contain the system-specific payload specifications and examples of sending those payloads.  However, describing the full specification of GraphQL is out of scope for this document and you should refer to the above URL for more information.

#### Connecting

For connecting to the API, you will be provided with an URL as the endpoint.  You use the same URL for all calls to the API.  GraphQL uses a single `https://<host name>/graphql` endpoint.  To that URL, you will sent HTTP post operations using the required JSON payload to execute the needed operation.  Authentication will be accepted in the form of a token in an HTTP header.  The nature of the token is still under development, but plan for it to be a JWT token, as that is the largest token option we are considering.

Once connected, your access roles will be determined.  They will identify what operations you have permissions to execute and what data elements you are able to retrieve.

#### Clients

There are a number of clients for various languages available from package repositories.

See: <https://graphql.org/graphql-js/graphql-clients/>

While a GraphQL client is not needed to access the API, it can make the use of the API easier.  A client can inspect the data model you are about to send and provide validation before sending them to the API.  Some can generate client stubs for calling provided operations.

Ultimately, a GraphQL call is an HTTP POST operation to a single endpoint.  The GraphQL specification dictates the structure of the JSON payload sent in the body of the HTTP POST and where in that body you need to include the operation-specfic data.

The below is a sample of that payload for submitting a journal feed.  It is 100% JSON.  The only GraphQL-specific syntax is in the `query` property and will generally be the same or similar for all action request operations.  Comments may not be included, they are there for illustration purposes only.

The GraphQL specification for each operation defines the structure of the data which must be submitted.  Development sandboxes can be used to test any payload formats.

```jsonc
{
  // Name of the operation
  "operationName": "glJournalRequest",
  // GraphQL String defining the data variable and requesting the properties to return from the result
  "query": "mutation glJournalRequest($data: GlJournalRequestInput!) {  glJournalRequest(data: $data) {    requestStatus {      requestId      consumerId      requestDateTime      requestStatus      operationName    }   }}",
  // payload data
  "variables": {
    // payload object named in the operation definition
    "data": {
      // header common to all operations identifying the API user and
      // providing reference information to allow for tracking by the boundary system
      "header": {
        "boundaryApplicationName": "TESTING_APP",
        "consumerId": "CONSUMER_ID",
        "consumerReferenceId": "A_UNIQUE_ID",
        "consumerTrackingId": "CONSUMER_ORDER_NBR"
      },
      // the operation-specific payload for the operation
      "payload": {
        "journalSourceName": "A_BOUNDARY_SYSTEM",
        "journalCategoryName": "Recharge",
        "journalDescription": "Journal Description For Oracle",
        "journalName": "Journal Name For Oracle",
        "journalReference": "JournalReference",
        "accountingDate": "2021-09-10",
        "journalLines": [
            {
                "glSegments": {
                    "entity": "1311",
                    "fund": "12345",
                    "department": "1234567",
                    "purpose": "68",
                    "account": "700002"
                },
                "externalSystemIdentifier": "ORDER123",
                "debitAmount": 123.45
            },
            {
                "glSegments": {
                    "entity": "1311",
                    "fund": "12345",
                    "department": "1234567",
                    "account": "200001"
                },
                "externalSystemIdentifier": "ORDER123",
                "creditAmount": 123.45
            }
        ]
      }
    }
  }
}
```

#### Testing Operations

Because every GraphQL server publishes its operations and schema, it is simple to point a GraphQL-aware tool at the server and get a full description of the API as well as (usually) a dynamic editor which can validate your request and payload contents in real-time based on the schema definitions.  You can utilize tools like Postman, Insomnia, or GraphiQL.  We might also be able to provide a playground as part of our API Portal.  (time permitting)

You will just need to provide your credentials in the HTTP header per the tool's configuration to be sent as part of the requests to allow for retrieval of the schema and submission of operations.

#### Obtaining Action Request Results

In order to provide an infrastructure with minimum downtime from the perspective of our boundary applications, API data submissions to Oracle are performed an an asynchronous manner.  The submission is validated and stored within the integration platform.  The API then immediately returns the necessary information to follow-up on the request in its response.  The caller is responsible for checking in on the success or failure of the request.  (If possible, we may also provide a service to post a status message back to a URL provided by the caller.)

So, in the case where this type of request is submitted to the API, it will be validated and (if valid), queued for execution.  The operation will respond to the call at that point with a unique identifier you can use to track the status of the request.  This UUID has no meaning to the ERP system, but can be used against these APIs to check on the status.  Depending on the type of operation, you may be able to get an Oracle-generated identifier back once the request has been successfully processed.

Below are some examples of responses from the API.  Successful response data is wrapped by a `data.<operation name>` property.  If there are any errors, they are reported in a top-level `errors` property looking like the 2nd response below.

```json
{
    "data": {
        "glJournalRequest": {
            "requestStatus": {
                "requestId": "5c928b62-d729-4fdf-bc10-c313fe28386d",
                "consumerId": "CONSUMER_ID",
                "requestDateTime": "2022-01-20T00:42:38.908Z",
                "requestStatus": "PENDING",
                "operationName": "glJournalRequest"
            },
        }
    }
}
```

```json
{
  "error": {
    "errors": [
      {
        "message": "Variable \"$data\" got invalid value \"Journal Reference\" at \"data.payload.journalReference\"; Expected type \"GlReferenceField25\". Value is not a valid GlReferenceField25. (Journal Reference)  Must match pattern: /^[A-Za-z0-9_-]{0,25}$/",
        "extensions": {
          "code": "BAD_USER_INPUT"
        }
      }
    ]
  }
}
```

#### Example of Action Request Flow



<!--BREAK-->
### Data Objects Provided

#### Key Accounting Field Segments

* [`ErpEntity`](3.2.1%20Data%20Objects/ErpEntity.md)
  * Chartstring element representing the sub-entity of the University to which a transaction belongs.
* [`ErpFinancialDepartment`](3.2.1%20Data%20Objects/ErpFinancialDepartment.md)
  * Campus department to which a transaction belongs.  Aligned with, but not always the same as, the UCPath HR Department.
* [`ErpFund`](3.2.1%20Data%20Objects/ErpFund.md)
  * Fund which the transaction debits or credits.  Replacement for the legacy OP Fund.
* [`ErpAccount`](3.2.1%20Data%20Objects/ErpAccount.md)
  * Classification of the transaction (revenue/expense/asset/libility).  Cooresponds to the KFS Object Code.
* [`ErpPurpose`](3.2.1%20Data%20Objects/ErpPurpose.md)
  * Purpose of the transaction as it relates to the campus functions (instruction, operations)
* [`ErpProgram`](3.2.1%20Data%20Objects/ErpProgram.md)
  * The Program segment records revenue and expense transactions associated with a formal, ongoing system-wide or cross-campus/location academic or administrative activity that demonstrates UC Davis' mission of teaching, research, public service and patient care.
* [`ErpProject`](3.2.1%20Data%20Objects/ErpProject.md)
  * The Project segment tracks financial activity for a "body of work" that often has a start and an end date that spans across fiscal years.
* [`ErpActivity`](3.2.1%20Data%20Objects/ErpActivity.md)
  * Systemwide activity to which a transaction is assigned.
* [`ErpFlex1`](3.2.1%20Data%20Objects/ErpFlex1.md) (**FUTURE**)
* [`ErpFlex2`](3.2.1%20Data%20Objects/ErpFlex2.md) (**FUTURE**)

<!-- * [`ErpInterEntity`](3.2.1%20Data%20Objects/ErpInterEntity.md) (**FUTURE**) -->
  <!-- * Internal accounting use only when transactions cross between entities, to represent the nature of the funds transfer. -->

#### GL Reference Data

* [`GlJournalSource`](3.2.1%20Data%20Objects/GlJournalSource.md)
  * Boundary system source for a journal sent in via integrations.
* [`GlJournalCategory`](3.2.1%20Data%20Objects/GlJournalCategory.md)
  * Type of activity recorded on a journal.  Cooresponds to the KFS document type code.
* [`GlAccountingPeriod`](3.2.1%20Data%20Objects/GlAccountingPeriod.md)
  * Accounting period to which a transaction is assigned.
* [`GlChartstringAlias`](3.2.1%20Data%20Objects/GlChartstringAlias.md)
  * Shortcut string for a full set of key accounting segments.  Usable on integration journals instead of specifying all chartfields.  Will be resolved by the integration layer.

#### PPM Costing Segments

* [`PpmProject`](3.2.1%20Data%20Objects/PpmProject.md)
* [`PpmTask`](3.2.1%20Data%20Objects/PpmTask.md)
* [`PpmExpenseOrganization`](3.2.1%20Data%20Objects/PpmExpenseOrganization.md)
* [`PpmExpenseType`](3.2.1%20Data%20Objects/PpmExpenseType.md)
* [`PpmAward`](3.2.1%20Data%20Objects/PpmAward.md)
* [`PpmFundingSource`](3.2.1%20Data%20Objects/PpmFundingSource.md)

#### PPM Reference Data

* [`PpmDocumentEntry`](3.2.1%20Data%20Objects/PpmDocumentEntry.md) (**IN PROGRESS**)
  * This will serve the function of the Journal Source in the GL module.

<!-- * [`PpmCostingType`](3.2.1%20Data%20Objects/PpmCostingType.md) (**TBD**) -->
<!-- * [`PpmCustomer`](3.2.1%20Data%20Objects/PpmCustomer.md) (**TBD**) -->
<!-- * [`PpmDocument`](3.2.1%20Data%20Objects/PpmDocument.md) (**TODO**) -->
  <!-- * This will serve the function of the Journal Source / Payment Source in other modules. -->
<!-- * [`PpmExpenseCategory`](3.2.1%20Data%20Objects/PpmExpenseCategory.md) (**TODO**) -->
<!-- * [`PpmExpenseTypeClass`](3.2.1%20Data%20Objects/PpmExpenseTypeClass.md) (**TODO**) -->
  <!-- * Classification of the PpmExpenseType.  Used to control business rules around usable PPM expense types. -->
<!-- * [`PpmProjectStatus`](3.2.1%20Data%20Objects/PpmProjectStatus.md) (**TBD**) -->
<!-- * [`PpmProjectType`](3.2.1%20Data%20Objects/PpmProjectType.md) (**TBD**) -->
<!-- * [`PpmSource`](3.2.1%20Data%20Objects/PpmSource.md) (**TBD**) -->
<!-- * [`PpmTransactionSource`](3.2.1%20Data%20Objects/PpmTransactionSource.md) (**TBD**) -->

#### SCM Reference Data

* [`ScmSupplier`](3.2.1%20Data%20Objects/ScmSupplier.md)
  * [`ScmSupplierSite`](3.2.1%20Data%20Objects/ScmSupplierSite.md)
* [`ScmPaymentTerms`](3.2.1%20Data%20Objects/ScmPaymentTerms.md) (**TODO**)
* [`ScmPaymentType`](3.2.1%20Data%20Objects/ScmPaymentType.md) (**TODO**)
* [`ScmSupplierType`](3.2.1%20Data%20Objects/ScmSupplierType.md) (**TODO**)

#### AR Reference Data

* [`ArAccountingPeriod`](3.2.1%20Data%20Objects/ArAccountingPeriod.md)
* [`ArCustomer`](3.2.1%20Data%20Objects/ArCustomer.md) (**TODO**)
  * [`ArCustomerSite`](3.2.1%20Data%20Objects/ArCustomerSite.md) (**TODO**)
* [`ArInvoiceSummary`](3.2.1%20Data%20Objects/ArInvoiceSummary.md) (**TODO**)
* [`ArPaymentTerm`](3.2.1%20Data%20Objects/ArPaymentTerm.md)
* [`ArTransactionSource`](3.2.1%20Data%20Objects/ArTransactionSource.md) (**TBD**)

#### Common Reference Data

* [`ErpCountry`](3.2.1%20Data%20Objects/ErpCountry.md) (**TODO**)
* [`ErpLocation`](3.2.1%20Data%20Objects/ErpLocation.md) (**TBD**)
* [`ErpPerson`](3.2.1%20Data%20Objects/ErpPerson.md) (**TBD**)
* [`ErpUnitOfMeasure`](3.2.1%20Data%20Objects/ErpUnitOfMeasure.md) (**TODO**)
  * Might need per-module types (e.g., AR and SCM might have different lists.)

<!-- * [`ErpCurrency`](3.2.1%20Data%20Objects/ErpCurrency.md) (**TBD**) -->


<!--BREAK-->
### Data Requests Supported

> Data Requests are actions which request data that is not directly linked to an underlying data object or require an additional level of processing to satisfy the request.

#### Data Conversion Support

* [`kfsConvertAccount`](3.2.2%20Data%20Requests/kfsDataRequests.md) (**TBD**)
  * Given a chart and account, returns the best matching Oracle accounting segments.
  * This will be based on the data conversion rules created for cutover.
  * These could be either glSegments or ppmSegments depending on the KFS account.
  * For `glSegments` the response will contain the Entity, Fund, Department, and Purpose.
  * For `ppmSegments` the response will contain the Project, Task, and Expenditure Organization.
  * **TBD: The business need for this service is presently unknown.**

* [`kfsConvertOrgCode`](3.2.2%20Data%20Requests/kfsDataRequests.md) (**TBD**)
  * Given a KFS Organization code, returns the best matching Oracle Financial Department.
  * This will be based on the data conversion rules created for cutover.
  * **TBD: The business need for this service is presently unknown.**

#### General Ledger

* [`glValidateChartSegments`](3.2.2%20Data%20Requests/glDataRequests.md) (**IN PROGRESS**)
  * Given a set of segment values, validate if they will be accepted by Oracle.
  * This does not include situational correctness.  E.g., use of a labor account on a recharge journal or payable.
* [`glValidateChartstring`](3.2.2%20Data%20Requests/glDataRequests.md) (**IN PROGRESS**)
  * Given a complete GL Chartstring, validate if it will be accepted by Oracle.
  * This does not include situational correctness.  E.g., use of a labor account on a recharge journal or payable.

<!-- * [`erpFiscalApprover`](3.2.2%20Data%20Requests/glDataRequests.md) (**TODO**)
  * For a given set of segment values, return the person(s) who would need to approve any transactions against that chartstring.
  * **TBD: We do not yet know how or where approvers will be attached.** -->

#### Project and Portfolio Management

* [`ppmSegmentsValidate`](3.2.2%20Data%20Requests/ppmDataRequests.md) (**TODO**)
  * Validate that the given POET segments will be accepted by Oracle.

<!--
* [`ppmCostApprover`](3.2.2%20Data%20Requests/ppmCostApprover.md) (**TODO**)
  * For a given set of POET segment values, return the person(s) who would need to approve any transactions against that project.
-->

#### Accounts Receivable

* [`arInvoiceSummary`](3.2.2%20Data%20Requests/arDataRequests.md) (**TODO**)
  * (This may end up as a data object - but falls more into the area of a special data request since it involves transactional data.)


<!--BREAK-->
### Action Requests Supported

#### Common Operations

* [Common Types](3.2.3%20Action%20Requests/1_CommonTypes.md)
  * Input and output types common across ERP Action Requests.
* [Common Operations](3.2.3%20Action%20Requests/2_CommonOperations.md)
  * Action Request-related operations not specific to a particular type.

#### General Ledger

* [`GlJournal`](3.2.3%20Action%20Requests/GlJournal-1-summary.md) (**IN PROGRESS**)
  * Combined GL/PPM Journal import

#### Supply Chain Management / PTP

* [`ScmRequisition`](3.2.3%20Action%20Requests/ScmRequisition-1-summary.md) (**IN PROGRESS**)
  * Creation of new purchasing requisitions
* [`ScmInvoicePayment`](3.2.3%20Action%20Requests/ScmInvoicePayment-1-summary.md) (**IN PROGRESS**)
  * Creation of PO Invoice and Non PO Payment Requests

#### Accounts Receivable

* [`ArInvoice`](3.2.3%20Action%20Requests/ArInvoice-1-summary.md) (**IN PROGRESS**)
  * AR Invoices


![diagram](action-request-flow-summary.svg)