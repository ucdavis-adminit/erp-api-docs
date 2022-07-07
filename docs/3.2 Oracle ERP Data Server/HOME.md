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



#### Scalars

> Scalar types defined to provide standard max-length, character type and pattern restrictions.  Result in immediate enforcement during graphQL parsing.

| Scalar Name                  | Description |
| ---------------------------- | ----------- |
| `Boolean`                    | The `Boolean` scalar type represents `true` or `false`. |
| `CityName`                   | Oracle City Name, 60-character limit |
| `CountryCode`                | A country code as defined by ISO 3166-1 alpha-2 |
| `Currency`                   | A field whose value is a Currency: https://en.wikipedia.org/wiki/ISO_4217. |
| `Date`                       | A date string, such as 2007-12-03, compliant with the `full-date` format outlined in section 5.6 of the RFC 3339 profile of the ISO 8601 standard for representation of dates and times using the Gregorian calendar. |
| `DateTime`                   | A date-time string at UTC, such as 2007-12-03T10:15:30Z, compliant with the `date-time` format outlined in section 5.6 of the RFC 3339 profile of the ISO 8601 standard for representation of dates and times using the Gregorian calendar. |
| `EmailAddress`               | A field whose value conforms to the standard internet email address format as specified in RFC822: https://www.w3.org/Protocols/rfc822/. |
| `ErpAccountCode`             | Oracle GL Account Segment Code<br/><br/>- All values are exactly 6 characters matching the regex pattern: `[0-9]{5}[0-9A-EX]`<br/>- Validated against the [`ErpAccount`]({{Types.ErpAccount}}) object. |
| `ErpAccountingPeriodName`    | Oracle Accounting Period Name<br/><br/>- Validated against the `periodName` of the [`GlAccountingPeriod`]({{Types.GlAccountingPeriod}}).<br/>   |
| `ErpActivityCode`            | Oracle GL Activity Segment Code<br/><br/>- All values are exactly 6 characters matching the regex pattern: `[0-9X]{5}[0-9AB]`<br/>- Validated against the [`ErpActivity`]({{Types.ErpActivity}}) object. |
| `ErpCountryCode`             | Oracle Country Code.  ISO-3601-1 alpha-2 |
| `ErpDepartmentCode`          | Oracle GL Financial Department Segment Code<br/><br/>- All values are exactly 7 characters matching the regex pattern: `[0-9P][0-9]{5}[0-9A-F]`<br/>- Validated against the [`ErpFinancialDepartment`]({{Types.ErpFinancialDepartment}}) object. |
| `ErpDepartmentTypeCode`      | ERP Financial Department Type Code |
| `ErpDescriptionField240`     | Up to 240-character description field limited to letters, numbers, hyphen, underscore, spaces, and periods. |
| `ErpEmailAddress`            | Oracle Email Address, 320 Character Limit |
| `ErpEntityCode`              | Oracle GL Entity Segment Code<br/><br/>Represents the 4-character entity code that identifies the major operational unit within the University of California responsible for each transaction.<br/><br/>- All values are exactly 4 characters matching the regex pattern: `[0-9]{3}[0-9AB]`<br/>- Validated against the [`ErpEntity`]({{Types.ErpEntity}}) object. |
| `ErpFlex1Code`               | Oracle GL Flex1 Segment Code - **UNUSED** |
| `ErpFlex2Code`               | Oracle GL Flex2 Segment Code - **UNUSED** |
| `ErpFundCode`                | Oracle GL Fund Segment Code<br/><br/>- All values are exactly 5 characters matching the regex pattern: `[0-9A-Z][0-9]{3}[0-9A-Z]`<br/>- Validated against the [`ErpFund`]({{Types.ErpFund}}) object. |
| `ErpNameField100`            | 100-character naming field limited to letters, numbers, hyphen, underscore, and spaces |
| `ErpPostalCode`              | Oracle Postal Code |
| `ErpProgramCode`             | Oracle GL Program Segment Code<br/><br/>- All values are exactly 3 characters matching the regex pattern: `[0-9A-Z]{3}`<br/>- Validated against the [`ErpProgram`]({{Types.ErpProgram}}) object. |
| `ErpProjectCode`             | Oracle GL Project Segment Code<br/><br/>- All values are exactly 10 characters matching the regex pattern: `[0-9A-Z]{10}`<br/>- Validated against the [`ErpProject`]({{Types.ErpProject}}) object. |
| `ErpPurposeCode`             | Oracle GL Purpose Segment Code<br/><br/>- All values are exactly 2 characters matching the regex pattern: `[0-9][0-9A-Z]`<br/>- Validated against the [`ErpPurpose`]({{Types.ErpPurpose}}) object. |
| `ErpUnitOfMeasureCode`       | Oracle ERP Unit Of Measure Code |
| `ErpUserId`                  | Oracle User ID: 32 character limit |
| `Float`                      | The `Float` scalar type represents signed double-precision fractional values as specified by [IEEE 754](https://en.wikipedia.org/wiki/IEEE_floating_point). |
| `GlDescriptionField40`       | 40-character description field limited to letters, numbers, hyphen, underscore, and spaces |
| `GlJournalCategoryKey`       | General Ledger Journal Category Key<br/><br/>- Limit of 25 characters.<br/>- Validated against the `key` of the [`GlJournalCategory`]({{Types.GlJournalCategory}}).<br/> |
| `GlJournalSourceKey`         | General Ledger Journal Source Key or Name<br/><br/>- Limit of 25 characters.<br/>- Validated against the `key` of the [`GlJournalSource`]({{Types.GlJournalSource}}).<br/> |
| `GlReferenceField10`         | 10-character reference field limited to letters, numbers, hyphen, and underscore |
| `GlReferenceField25`         | 25-character reference field limited to letters, numbers, hyphen, and underscore |
| `GlSegmentString`            | Oracle GL Combined Segments Chartstring<br/><br/>Must be fully populated with all 11 segments, even if unused.  Fill unused segments with zeroes.<br/><br/>- Format Pattern: `0000-00000-0000000-000000-00-000-0000000000-000000-0000-000000-000000`<br/>- Format Regex:   `^[0-9]{3}[0-9AB]-[0-9A-Z][0-9]{3}[0-9A-Z]-[0-9P][0-9]{5}[0-9A-F]-[0-9]{5}[0-9A-EX]-[0-9][0-9A-Z]-[0-9A-Z]{3}-[0-9A-Z]{10}-[0-9X]{5}[0-9AB]-0000-000000-000000$`<br/> |
| `Int`                        | The `Int` scalar type represents non-fractional signed whole numeric values. Int can represent values between -(2^31) and 2^31 - 1. |
| `JWT`                        | A field whose value is a JSON Web Token (JWT): https://jwt.io/introduction. |
| `KfsAccountNumber`           | 7-character KFS Account Number, upper-case letters and digits only |
| `KfsChartCode`               | 1-character KFS Chart Code.  Must be one of 3, L, H, S, P, M, N |
| `KfsOrgCode`                 | 4-character KFS Org Code, upper-case letters and digits only |
| `KfsProjectCode`             | 10-character KFS Project Code, upper-case letters and digits only |
| `KfsSubAccountNumber`        | 5-character KFS Sub Account Number, upper-case letters and digits only |
| `LocalDate`                  | A local date string (i.e., with no associated timezone) in `YYYY-MM-DD` format, e.g. `2020-01-01`. |
| `Long`                       | The `BigInt` scalar type represents non-fractional signed whole numeric values. |
| `NonEmptyString`             | A string that cannot be passed as an empty value |
| `NonEmptyTrimmedString240`   | String limited to 240 characters.  Whitespace will be trimmed from both ends of the string when passing in both directions.  In the case that source data to be returned by the API exceeds this length, it will be truncated. |
| `NonEmptyTrimmedString40`    | String limited to 40 characters.  Whitespace will be trimmed from both ends of the string when passing in both directions.  In the case that source data to be returned by the API exceeds this length, it will be truncated. |
| `NonNegativeFloat`           | Floats that will have a value of 0 or more. |
| `NonNegativeInt`             | Integers that will have a value of 0 or more. |
| `PositiveFloat`              | Floats that will have a value greater than 0. |
| `PositiveInt`                | Integers that will have a value greater than 0. |
| `PpmAwardNumber`             | Oracle PPM Award Number<br/><br/>Only required for Sponsored Research projects (defined as a flag on the [PpmProject]({{Types.PpmProject}})), this identifies the award to which the expenses are applied.  This will be an system-generated 7-character string.  It is for project reporting only, and has no impact on the GL mappings.<br/><br/>Normally, you will not need to provide this, as most projects will have a single award and this will be derived by the API.  File-based submitters will need to look up the default project number from the PpmProject and supply it when the `sponsoredProject` property is true.<br/> |
| `PpmExpenseOrganizationCode` | Oracle PPM Expense Organization<br/><br/>The PPM Expense organization will have the same values as the [`ErpFinancialDepartment`]({{Types.ErpFinancialDepartment}}).  The expected value by oracle is the code + " - " + name.  This API will accept the code alone by using the first 7 characters of the string and perfoming the needed lookup to obtain the value required by Oracle.<br/><br/>-*Definition:** The Expenditure Organization identifies the organization that is incurring the expense and revenue. This may NOT be the same as the organization that owns the project.<br/><br/>-*Roll-up relationship to the new Chart of Accounts in the General Ledger:**<br/>- The Expenditure Organization value will roll up to the Financial Department segment of the Chart of Accounts.<br/> |
| `PpmExpenseTypeCode`         | Oracle PPM Expense Type<br/><br/>The PPM Expense Type will have the same values as the [`ErpAccount`]({{Types.ErpAccount}}).  The expected value by oracle is the code + " - " + name.  This API will accept the code alone by using the first 6 characters of the string and perfoming the needed lookup to obtain the value required by Oracle.<br/><br/>-*Definition:** The Expenditure Type identifies the natural classification of the expense transaction being recorded.<br/><br/>-*Roll-up relationship to the new Chart of Accounts in the General Ledger:**<br/>- The Expenditure Type value will roll up to the (Natural) Account segment in the Chart of Accounts.<br/>- The first 6 characters of the Expenditure Type value will correspond with the (Natural) Account value it rolls up to.<br/> |
| `PpmFundingSourceNumber`     | Oracle PPM Funding Source Number<br/><br/>Only required for Sponsored Research projects (defined as a flag on the [PpmProject]({{Types.PpmProject}})), this identifies the funding to which the expenses are applied.  It will be used to derive the GL Fund segment.<br/><br/>-*FORMAT AND LENGTH OF THIS SEGMENT IS UNKNOWN AT THIS TIME (4/4/22)**<br/><br/>Normally, you will not need to provide this, as most projects will have a single funding source and this will be derived by the API.  File-based submitters will need to look up the default project number from the PpmProject and supply it when the `sponsoredProject` property is true.<br/> |
| `PpmProjectNumber`           | Oracle Managed Project Number<br/><br/>A 10-character project code which identifies Sponsored Research, a Faculty Portfolio, or a Capital Project.  Values will generally start with a 2 character prefix which identifies their type followed by a system-assigned number.<br/><br/>-*Definition:** The Project identifies the planned work or activity to be completed over a period of time and intended to achieve a particular goal.<br/><br/>-*Roll-up relationship to the new Chart of Accounts (CoA) in the General Ledger:**<br/>- The POET(AF) Project value will roll up to the Project segment of the Chart of Accounts.<br/>- PPM Project values and GL Project segment values will be the same.<br/> |
| `PpmSegmentString`           | Oracle PPM Combined Segments Chartstring<br/><br/>Must be populated with either the 4 required segments, or all 6 segments.  (Project-Task Number-Expense Organization-Expense Type-Award Number-Funding Source)<br/><br/>- Format Pattern (Required Only): `SP00000001-000001-0000000-000000`<br/>- Format Pattern (Sponsored Projects): `CP00000001-000001-0000000-000000-0000000-00000`<br/>- Format Regex:   `^[A-Z0-9]{10}-[0-9A-Za-z]{6}-[0-9A-Z]{7}-[0-9A-Z]{6}(-[0-9A-Z]{7}-[0-9A-Z]{5})?$`<br/><br/>See documentation on the individual segments for more information:<br/><br/>- [PpmProjectNumber]({{Types.PpmProjectNumber}})<br/>- [PpmExpenseOrganizationCode]({{Types.PpmExpenseOrganizationCode}})<br/>- [PpmExpenseTypeCode]({{Types.PpmExpenseTypeCode}})<br/>- [PpmTaskNumber]({{Types.PpmTaskNumber}})<br/>- [PpmAwardNumber]({{Types.PpmAwardNumber}})<br/>- [PpmFundingSourceNumber]({{Types.PpmFundingSourceNumber}})<br/> |
| `PpmTaskNumber`              | Oracle PPM Project Task<br/><br/>The task number is a 4-character code which identifies an activity within a project.  PPM will internally map this to a combination of other segments during sub-ledger accounting processing to post to the GL.<br/><br/>-*Definition:** The Task identifies the activities used to further breakdown a PPM project. Every project MUST have at least one Task.  The number of tasks will vary by type of project.<br/><br/>-*Roll-up relationship to the new Chart of Accounts in the General Ledger:**<br/>- Task values are exclusively used in the PPM module.<br/>- For Internal Faculty Projects, the Task will identify the Program, Purpose, Fund and Activity segments in the GL, using various PPM mapping rules.<br/> |
| `ScmAddressLine`             | Oracle SCM Address Line, 240 Character Limit |
| `ScmName`                    | Oracle SCM Name |
| `String`                     | The `String` scalar type represents textual data, represented as UTF-8 character sequences. The String type is most often used by GraphQL to represent free-form human-readable text. |
| `TimeZone`                   | A field whose value exists in the standard IANA Time Zone Database: https://www.iana.org/time-zones |
| `URL`                        | A field whose value conforms to the standard URL format as specified in RFC3986: https://www.ietf.org/rfc/rfc3986.txt. |
| `UUID`                       | A field whose value is a generic Universally Unique Identifier: https://en.wikipedia.org/wiki/Universally_unique_identifier. |



#### Enums

  > Enumeration types defined to provide values and meaning were a standard set of codes is needed for or provided by a property on the API.  When used with inputs, they will result in immediate enforcement during GraphQL parsing.

##### `ArAccountClass`

Used on AR Invoices to indicate the type of accounting on a distribution line.

| Enum Value | Description |
| ---------- | ----------- |
| `REC`      | Receivable |
| `REV`      | Revenue |

##### `ArDistributionAccountClass`

Account class for this accounting distribution. Valid values are:

* REV - Revenue
* FREIGHT - Freight
* TAX - Tax
* REC - Receivables
* CHARGES -  Late Charges
* UNBILL - Unbilled Receivables
* UNEARN -  Unearned Revenue

When the line type is LINE, the value for this column should be REV, UNBILL, UNEARN, or REC."

| Enum Value | Description |
| ---------- | ----------- |
| `REC`      | Receivable |
| `REV`      | Revenue |

##### `ArLineType`



| Enum Value | Description |
| ---------- | ----------- |
| `LINE`     |  |

##### `ArTransactionType`



| Enum Value | Description |
| ---------- | ----------- |
| `CHARGES`  | Other Charges Line |
| `FREIGHT`  | Shipping and Handling Charges Line |
| `LINE`     | Normal Receivables Line.  Excludes tax, freight, or misc charges. |
| `TAX`      | Charged Tax Line |

##### `ErpCoaHierarchyLevel`

Hierarchy Level Codes used in the financial chartstring structures.

| Enum Value | Description |
| ---------- | ----------- |
| `A`        | Second Level, often defined by UCOP for segments with many values. |
| `B`        | Third Level, campus-specific, but may be UCOP defined. |
| `C`        | Fourth Level: Usually campus-defined values here and below. |
| `D`        | Fifth Level |
| `E`        | Sixth Level |
| `F`        | Seventh Level |
| `X`        | Top Level, Defined by UCOP |

##### `ErpCostCenterType`

The type of cost center needed by Oracle to record a transaction.

| Enum Value | Description |
| ---------- | ----------- |
| `GL`       | General Ledger Segments: Transaction may be posted directly to the general ledger |
| `POET`     | POET Segments: Transaction belongs to a managed project and must be posted through the PPM sub-ledger. |

##### `ErpPeriodStatus`

Valid values for an accounting period status.

| Enum Value | Description |
| ---------- | ----------- |
| `C`        | Closed |
| `F`        | Future Enterable |
| `N`        | Never Opened |
| `O`        | Open |
| `P`        | Permanently Closed |

##### `InvoiceType`

Invoice category used in Payable Payment

| Enum Value   | Description |
| ------------ | ----------- |
| `CREDIT`     |  |
| `PREPAYMENT` |  |
| `STANDARD`   |  |

##### `PayeeType`

Used on payment API to indicate payment type

| Enum Value | Description |
| ---------- | ----------- |
| `EMPLOYEE` |  |
| `STUDENT`  |  |
| `SUPPLIER` |  |

##### `ProcessingResultStatus`

Status of the pipeline request triggered from an API action request.

| Enum Value  | Description |
| ----------- | ----------- |
| `ERROR`     | one or more of the jobs resulted in an error and was not processed |
| `INPROCESS` | data is in pipeline for processing and all jobs have not completed |
| `PROCESSED` | processing is complete but notifications have not been sent |
| `SUCCESS`   | all jobs completed successfully |

##### `RequestStatus`

Status options within the [ActionRequestStatus]({{Types.ActionRequestStatus}}) that reflect the states a request can be in.

| Enum Value  | Description |
| ----------- | ----------- |
| `COMPLETE`  | If Callback URL Provided: Request has been processed, and the callback was successfully contacted.  Or, request has been processed, and no callback URL was provided. |
| `ERROR`     | There was an error processing the request after it was picked up. |
| `INPROCESS` | Request has been picked up for processing. |
| `PENDING`   | Request has been submitted to the server, but not validated or processed. |
| `PROCESSED` | Request has been processed, but the callback has not been completed. |
| `REJECTED`  | There was a validation error in the request payload data. |
| `STALE`     | If Callback URL Provided: Request has been processed, but repeated attempts to contact the callback have failed and no more will be tried. |

##### `ScmInvoiceType`

Nature of the invoice when paying one for a PO.  This would drive the natural account.  Use STANDARD unless directed otherwise.

| Enum Value   | Description |
| ------------ | ----------- |
| `CREDIT`     |  |
| `DEBIT`      |  |
| `PREPAYMENT` |  |
| `STANDARD`   |  |

##### `ScmLineType`

Nature of the payment for this one.  In general, all lines should be ITEM.

| Enum Value      | Description |
| --------------- | ----------- |
| `FREIGHT`       |  |
| `ITEM`          |  |
| `MISCELLANEOUS` |  |


![diagram](action-request-flow-summary.svg)