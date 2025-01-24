# 3.2.3.1 GL Journal

### Overview

The journal voucher is the primary interface for loading transactions into Oracle from boundary systems.  It is used regardless of whether the expenses are costs which can be applied to the general ledger or must be expensed to the PPM sub-ledger.  The data model in the request allows for all fields which might be needed for GL or PPM transactions to be provided.  However, it is up to the caller to know and fill out the fields properly.  Where possible, the API will reject invalid data prior to it being sent to Oracle.

This API replaces the KFS GL Collector process.  While the valid values of the FAU components (now called chartstring segments) have changed, the basic concepts of feeding transactional data to the financial system have not.  As always, transactions submitted to the GL must be balanced between debits and credits.  Valid values must be used for certain fields, and fields have content and length limits.

The correct values to use for chartstring segments is out of scope for this documentation.  This API is the mechanism by which you submit values already determined to be functionally correct to the financial system.  Other operations on this server provide data retrieval and validation tools to support generation of correct data payloads for the API.

Please see below in this document for examples of payloads into this API.

### Access Controls

* Required Role: `erp:writer-journal`

### Supporting Operations

Other operations which should be used to pre-validate chartstring segments are below.  Please see <https://financeandbusiness.ucdavis.edu/aggie-enterprise/chart-of-accounts/redesign> for information about each of these segments.

* [`erpEntity`]({{Queries.erpEntity}})
* [`erpFund`]({{Queries.erpFund}})
* [`erpFinancialDepartment`]({{Queries.erpFinancialDepartment}})
* [`erpAccount`]({{Queries.erpAccount}})
* [`erpPurpose`]({{Queries.erpPurpose}})
* [`erpProject`]({{Queries.erpProject}})
* [`erpProgram`]({{Queries.erpProgram}})
* [`erpActivity`]({{Queries.erpActivity}})

For validating combinations, the following two operations are provided, differing only in their input format.

* [`glValidateChartSegments`]({{Queries.glValidateChartSegments}})
* [`glValidateChartstring`]({{Queries.glValidateChartstring}})

### Managed Project Cost Entries (PPM/POET)

In addition to the standard GL-type of transaction which aligns with the KFS general ledger, Oracle Financials also utilizes a sub-ledger for tracking costs against managed projects.  This loosely matches contracts and grants (award-based) accounts from KFS, but PPM (Project and Portfolio Management) encompasses more than that.

For expenses (or income) which are to be recorded against these managed projects, the expense must be recorded in the sub-ledger first, using a different set of chartstring values.  This interface allows you to provide both GL and PPM sub-ledger transactions in the same payload.  (Any attempt to record transactions against a managed project directly (using GL segments) will be rejected.)

For PPM, you must use a different set of input strings on the journal line, utilizing the 4 fields below (all required):

* `p`roject
* `o`rganization (same values as `ErpFinancialDepartment`)
* `e`xpenditureType (same values as `ErpAccount`)
* `t`ask

Tasks are child records to each project.  You can obtain the list of valid tasks for any project by referencing the `PpmProject.tasks` property.

There are also the two segments listed below.  For API-based use, the framework will pull the correct award and funding source for any sponsored projects.  For file-based submissions, the default values must be included by querying from the `ppmProject` operation.  You can check whether you need to include these by referencing the `sponsoredProject` property on the `PpmProject`.

* award (only for sponsored projects)
* fundingSource (only for sponsored projects)

As with the GL segments, the API provides the operations below for lookups and validation:

* [`ppmProject`]({{Queries.ppmProject}})
* [`ppmExpenditureType`]({{Queries.ppmExpenditureType}})
* [`ppmOrganization`]({{Queries.ppmOrganization}})
* [`ppmSegmentsValidate`]({{Queries.ppmSegmentsValidate}})

### Volume of Data

Unlike the use of the KFS ledger, the Oracle Financials general ledger will be a thin ledger.  This means that the level of detail that is allowed to be loaded into the ledger will be limited to summary level information.  It is required that you summarize data down as much as possible to the chartstring segments while being able to retain a link to the source of the transactions.  (E.g., an order number, batch number, or a transaction date)  Submitting lines for each source line item in an external billing system will not be allowed.  Failure to summarize data to an acceptable level will result in loss of API or journal upload access.

### Journal Balancing

As with the KFS ledger, journal payloads must balance.  (debit = credits)  Each API payload is a single journal (document number in KFS).

While lines with `glSegments` and `ppmSegments` are posted to different ledgers, we can balance across them when creating journals.  Offset entries are required by Oracle to keep the GL in balance until sub-ledger accounting processes execute.  These will be created by the integration framework for you and applied to a central clearing location outside of your department's cost center.

### Basic Use

1. Call the operation (`glJournalRequest`) providing a data payload with the proper structure.  (See [`GlJournalRequestInput`]({{Types.GlJournalRequestInput}}))
2. GraphQL Server will validate content format and reject if invalid.
3. API Server will perform request-specific validation against a local copy of Oracle ERP data.
4. A failure in either of these initial validations will result in an error response with no request being generated.
5. Passing validation will save the request to allow for pickup by the integration platform for processing.
6. A request tracking ID will be generated and returned to allow for the consumer to check on the status of the request and obtain results when completed.
7. At a later time, use the generated request tracking ID against the [`glJournalRequestStatus`]({{Queries.glJournalRequestStatus}}) operation to determine if the request was processed successfully

<!-- End copy to GraphQL API Docs -->

### Operations

#### `glJournalRequest`

> Submits a journal voucher data object for validation and submission to the Oracle ERP system.  Returns a handle with the results of the request submission.  This handle contains the operation to submit back to this server to get the results.

* **Parameters**
  * `data : GlJournalRequestInput!`
* **Returns**
  * `GlJournalRequestStatusOutput!`

#### `glJournalRequestStatus`

> Retrieves a GlJournal by the unique request ID assigned by the API upon submission of the request.

* **Parameters**
  * `requestId : String!`
* **Returns**
  * `GlJournalRequestStatusOutput`

#### `glJournalRequestStatusByConsumerTracking`

> Retrieves a GlJournal by the unique tracking ID provided by the consumer during submission of the request.

* **Parameters**
  * `consumerTrackingId : String!`
* **Returns**
  * `GlJournalRequestStatusOutput`

#### `glJournalRequestStatusByConsumerReference`

> Retrieves a list of GlJournals by the reference ID provided by the consumer during submission of the request.

* **Parameters**
  * `consumerReferenceId : String!`
* **Returns**
  * `[GlJournalRequestStatusOutput!]!`

### Related Lookup Objects

> These are the data types which will be needed to support this API as they provide valid values for fields either provided by the consumer or for internal validations.

* **GL ChartStrings**
  * [`ErpAccount`](../3.2.1%20Data%20Objects/ErpAccount.md)
  * [`ErpActivity`](../3.2.1%20Data%20Objects/ErpActivity.md)
  * [`ErpEntity`](../3.2.1%20Data%20Objects/ErpEntity.md)
  * [`ErpFinancialDepartment`](../3.2.1%20Data%20Objects/ErpFinancialDepartment.md)
  * [`ErpFund`](../3.2.1%20Data%20Objects/ErpFund.md)
  * [`ErpProgram`](../3.2.1%20Data%20Objects/ErpProgram.md)
  * [`ErpProject`](../3.2.1%20Data%20Objects/ErpProject.md)
  * [`ErpPurpose`](../3.2.1%20Data%20Objects/ErpPurpose.md)
* **Journal Entry Support**
  * [`GlAccountingPeriod`](../3.2.1%20Data%20Objects/GlAccountingPeriod.md)
* **PPM Costing**
  * [`PpmProject`](../3.2.1%20Data%20Objects/PpmProject.md)
  * [`PpmTask`](../3.2.1%20Data%20Objects/PpmTask.md)
  * [`PpmExpenditureType`](../3.2.1%20Data%20Objects/PpmExpenditureType.md)
  * [`PpmOrganization`](../3.2.1%20Data%20Objects/PpmOrganization.md)
  * [`PpmFundingSource`](../3.2.1%20Data%20Objects/PpmFundingSource.md)
  * [`PpmAward`](../3.2.1%20Data%20Objects/PpmAward.md)

  <!-- * [`GlAccountAlias`](../3.2.1%20Data%20Objects/GlAccountAlias.md) -->
  <!-- * [`GlAccountingCombination`](../3.2.1%20Data%20Objects/GlAccountingCombination.md) -->
  <!-- * [`GlJournalCategory`](../3.2.1%20Data%20Objects/GlJournalCategory.md) -->
  <!-- * [`GlJournalSource`](../3.2.1%20Data%20Objects/GlJournalSource.md) -->
<!-- * **PPM Costs Support** -->
  <!-- * [`PpmDocumentEntry`](../3.2.1%20Data%20Objects/PpmDocumentEntry.md) -->
  <!-- * [`PpmDocument`](../3.2.1%20Data%20Objects/PpmDocument.md) -->
  <!-- * [`PpmExpenseCategory`](../3.2.1%20Data%20Objects/PpmExpenseCategory.md) -->
  <!-- * [`PpmProjectStatus`](../3.2.1%20Data%20Objects/PpmProjectStatus.md) -->
  <!-- * [`PpmProjectType`](../3.2.1%20Data%20Objects/PpmProjectType.md) -->
  <!-- * [`PpmTransactionSource`](../3.2.1%20Data%20Objects/PpmTransactionSource.md) -->


## Request Object Data Types

> Objects passed when making calls to the operations above.

* Main Object: `GlJournalRequestInput`

| Property Name | GraphQL Type                                      | Notes                                                              |
| ------------- | ------------------------------------------------- | ------------------------------------------------------------------ |
| header        | [`ActionRequestHeaderInput`](./1_CommonTypes.md)! | Header information required on all action requests                 |
| payload       | `GlJournalInput`!                                 | The main payload used to create the journal in Oracle.  See below. |

<!-- | preValidate   | Boolean                                           | Whether to run more time consuming validations before sending to Oracle. | -->

* Child Request Objects:
  * [`ActionRequestHeaderInput`](./1_CommonTypes.md)
  * `GlJournalLineInput`
    * [`GlSegmentInput`](./1_CommonTypes.md)
    * [`PpmSegmentInput`](./1_CommonTypes.md)

### Response Objects

* `GlJournalRequestStatusOutput`
  * Child Request Objects:
    * [`ActionRequestStatus`](./1_CommonTypes.md)

### Object Properties

> Note: Object properties are for general documentation only.  The definitive data model is defined by the SDL retrieved from the graphql servers.

#### `GlJournalInput`

| Property Name        | GraphQL Type             | Notes                               |
| -------------------- | ------------------------ | ----------------------------------- |
|                      |                          | **Journal Header Fields**           |
| journalSourceName    | NonEmptyTrimmedString80! |                                     |
| journalCategoryName  | NonEmptyTrimmedString80! |                                     |
| journalName          | ErpNameField100!         |                                     |
| journalDescription   | ErpDescriptionField240   |                                     |
| journalReference     | GlReferenceField25!      |                                     |
| accountingDate       | LocalDate                | The accounting date of the journal. |
| accountingPeriodName | NonEmptyTrimmedString15  |                                     |
|                      |                          | **Journal Lines**                   |
| journalLines         | `[GlJournalLineInput!]!` |                                     |

#### `GlJournalLineInput`

> Represents a single journal line or PPM Cost.  Every line must have a set of GL _or_ POET segments and a credit or debit amount.  All other fields are optional.

| Property Name            | Type                                    | Notes                                                                                                                                                                                                                       |
| ------------------------ | --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|                          |                                         | **GL Distribution / PPM Costing Fields**                                                                                                                                                                                    |
| glSegments               | [`GlSegmentInput`](./1_CommonTypes.md)  | GL Segment fields.  Only those with non-default values need to be filled.                                                                                                                                                   |
| glSegmentString          | GlSegmentString                         | Delimited complete GL segment string.  All fields of the GL Accounting Key must be provided.                                                                                                                                |
|                          |                                         | PPM POET segment values.  If provided, this will override any provided GL segments.                                                                                                                                         |
| ppmSegments              | [`PpmSegmentInput`](./1_CommonTypes.md) | PPM POET segment values.  If provided, this will override any provided or default GL segments.  Any non-provided values which are present in the ppmSegmentDefaults property of the header will be filled in automatically. |
| ppmSegmentString         | PpmSegmentString                        | Delimited complete PPM segment string.  All required segments must be provided.  Award and funding source are optional on non-sponsored projects.                                                                           |
|                          |                                         | **Transaction Line Details**                                                                                                                                                                                                |
| creditAmount             | NonNegativeFloat                        | Debit amount of the GL transaction or PPM Cost.  Only one of debitAmount and creditAmount may be specified on a line.                                                                                                       |
| debitAmount              | NonNegativeFloat                        | Credit amount of the GL transaction or PPM Cost.  Only one of debitAmount and creditAmount may be specified on a line.                                                                                                      |
| externalSystemIdentifier | GlReferenceField10!                     | This 10-character field is intended to aid with linking boundary systems transactions to Oracle Cloud summarized journal entries for the purposes of reconciliation.                                                        |
| externalSystemReference  | GlReferenceField25                      | This 25-character field is intended to aid in additional linking of boundary systems transactions, as needed, to Oracle Cloud summarized journal entries for the purposes of reconciliation.                                |
| ppmComment               | GlDescriptionField40                    | Expenditure comment for PPM transactions.  Will be ignored for GL transactions.     
| glide                    | [`GlideInput`](./1_CommonTypes.md)      | GLIDe fields. These fields are optional.                                         |

#### `GlJournalRequestStatusOutput`

> Output type for GLJournal requests and follow-up status updates.
>
> Contains the overall request status.


| Property Name     | Type                                         | Notes                                                                                                          |
| ----------------- | -------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| requestStatus     | [`ActionRequestStatus`](./1_CommonTypes.md)! | General action request status and tracking information.                                                        |
| validationResults | [`ValidationResponse`](./1_CommonTypes.md)   | Errors found when validatating the payload data.  These must be corrected before the request will be accepted. |


## GLJournal API Validations

### Per GraphQL Data Model and Type Resolvers

> This set of validations will be enforced by the GraphQL parser and data type definitions.

* Valid JSON data structure
* Required fields (enforced by GraphQL data model)
* Ensure required fields are non-blank. (enforced by GraphQL data model)
* Ensure fields are formatted properly (enforced by GraphQL data model)
* Verify maximum lengths on fields.  (enforced by GraphQL data model)
  * (e.g., `TrimmedNonEmptyString240`)

### Request Header Checks

* Validate API user's Consumer ID is valid and active.
  * (The Consumer ID is extracted from API authentication.)
* Validate supplied Journal Source Name exists and is active
  * Verify Journal Source is allowed for the calling API consumer.
* Validate Journal Category is `UCD Recharge`
* Verify that the given `consumerTrackingId` has not been previously used on an accepted request.

### Data Validation

#### Overall

* Verify that the accounting date, if given, is not in the future.
* If no accounting date is given, set to the current date.
* Accounting Period Validation
  * If no accounting period given, derive the period from the accounting date
  * If an accounting period was given, verify that the accounting date falls within the period.  (Periods align with the calendar months.)
  * Verify the period is open to accept transactions and is not an adjustment period.  (E.g., period 13)
* Verify that at least two journal lines have been provided.
* Verify number of lines `<=` 10000 (Preliminary number - may be adjusted based on performance testing.)
* Verify that all lines have GL or PPM segment values.
* Verify no line was given both GL and PPM segments.
* Verify that every line has exactly one positive, non-zero amount in the debit or credit amount fields.
* Verify that the total of debits and credits are equal.

#### GL Transactions

* The presence of `glSegments` will override `glSegmentString`.
* If `glSegmentString` provided, it must parse properly, and contain all 11 segments in the correct order.
* Verify that the 4 required segments have been provided and are not all zeros. (`entity`, `fund`, `department`, `account`)
* If a non-blank and non-zeroes `project` has been provided, verify that the project is not a PPM Managed project.
  * (Managed projects must be submitted on lines using the `ppmSegments` or `ppmSegmentString` properties.)
* Verify values given in each GL segment
  * Value must be a valid value for the segment.
  * Value must be active on the accounting date between the segment's start and end date.
  * Segment must be a detail-level value.  (Segments are assigned a level in a hierarchy, only the lowest level values are valid for transactions.)

#### CVRs (Cross-Validation Rules)

| Rule ID              | Description                                                                                                                                                |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `EXP_PURPOSE_REQ`    | Expense transactions must have a purpose                                                                                                                   |
| `AUX_FUND_PURPOSE`   | Auxiliary Funds (1100C and below) should only be used for Auxiliary Enterprise (76) purposes                                                               |
| `CAPITAL_ACCT_FUND`  | Ensure Capital Asset (16000B and below) and Accumulated Depreciation (16500B and below) Accounts are only used with NICA Funds (4000A and below)           |
| `DEPR_ACCT_PURPOSE`  | Depreciation expenses (54000A and below) must use purpose code 65                                                                                          |
| `AGENCY_FUND_ACCT`   | Funds held for others (Account 22700B and below) should only be used with Agency Funds (5000A and below)                                                   |
| `INTEREST_FUND_ACCT` | Accounts under parent 23500C, 29500C should only be used with Split Interest Fund under parent 2210B                                                       |
| `SUBCONT_ACCT_FUND`  | Sub-contract services (53300B and below) should only be used with Federal Funds (2000B, 2085B and below)                                                   |
| `PDST_ACCT_FUND`     | Professional Degree Supplemental Tuition Revenue (40100C and below) may only be used with PDST Funds (1410C and below)                                     |
| `INTEXP_ACCT_FUND`   | Commercial Paper and Long-Term Debt Interest expenses (58000C and 58020C and below) must be recorded in an appropriate Debt Service Fund (2400B and below) |
| `UCDH_BS_DEPT`       | Balance sheet transactions in UCDH Entity 3210 may only be recorded in department 9500000                                                                  |
| `UCDH_FUND_ENTITY`   | UCD Operating Funds (12000) may only be used within the UCDH Entity 3210                                                                                   |
| `CAP_EXP_SALES_FUND` | Purchases to be Capitalized (52500B and below) may not be recorded on a Sales and Services fund (12100)                                                    |
| `COFI_NO_EXTREVENUE` | External Revenue accounts may not be used with Common University Funds (13U0D and below)                                                                   |
| `HATCHFUND_PURPOSE`  | ANR Expenses with Hatch Funds (2085C, 2086C, 2087C, 2088C and below) must use Organized Research purpose codes.                                            |
| `SMITHFUND_PURPOSE`  | ANR (Entity 3310) Smith Lever Federal Appropriations (2090C and below) must only be used for Public Service purposes (62)                                  |
| `SMITHFUND_PROGRAM`  | ANR (Entity 3310) Smith Lever Federal Appropriations (2090C and below) must only be used for ANR Local Programs (91B and below)                            |

<!-- | `ANRDEPT_ENTITY`     | UC ANR Departments (991000B and below) may only be used with ANR Entity Code 3310                                                                          | -->

#### Entity/Purpose Restrictions

Purpose code use is limited by entity.  Only combinations on the table below are allowed.   (Extracted from DEV2 / SUAT 6/15/23)

[](./entity-purpose-restrictions.txt ':include :type=markdown')

<!-- table above extracted via Query Below:

SELECT value_1 as entity, s1.name as entity_name, value_2 as purpose, s2.name as purpose_name
    FROM test_erp.value_set_related_values
    join test_erp.gl_segments s1 on s1.code = value_1
    join test_erp.gl_segments s2 on s2.code = value_2
    WHERE value_set_1_code = 'UCD Entity'
      AND value_set_2_code = 'UCD Purpose'
      AND enabled_flag = 'Y'
ORDER BY entity, purpose
-->

#### Entity/Department Restrictions

Department code use is limited by entity.  Only combinations defined within Oracle are allowed.  The error messages for these types of issues will contain the allowed entity codes.

#### Boundary Application Additional Rules

* _Net Position Accounts are not allowed_
  * Disallow all transactions if the account is a child of `3XXXXX`
* _Salary and Benefit Accounts are not allowed_
  * Disallow transactions where the account is a child of one of:
    * `50000A` : Salaries and Wages
    * `50500A` : Pension Benefits
    * `50600A` : Retiree Health Benefits
    * `50700A` : Other Employee Benefits
* _Purchases to be capitalized must be recorded in PPM._
  * Disallow accounts which are children of `52500B`

##### COFI Fund Restrictions

Common Operating Funds are distributed to by the budget office.  The funds below may not be used on expenditures, but will be expensed to by the central office.  Instead of using one of these funds, boundary systems should use fund `13U00` or `13U02` (depending on the college) in place of any of the funds below.

See: <https://financeandbusiness.ucdavis.edu/aggie-enterprise/about/cofi/resources> for more information.

| Fund Number | Name                                  |
| ----------- | ------------------------------------- |
| 07427       | UNIVERSITY OPPORTUNITY FUND           |
| 10010       | ANNUAL GIVING PROGRAM ALLOCATIONS     |
| 10500       | SUMMER SESSIONS INCOME                |
| 13U51       | UCOP SYSTEMWIDE ASSESSMENT            |
| 14000       | GRAD STUDIES TUITION INCOME           |
| 14001       | UNIVERSITY TUITION INCOME             |
| 19900       | GENERAL FUNDS                         |
| 19903       | GEN FUND - UTILITIES                  |
| 19904       | S/A UNDERGRADUATE TEACHING EXCELLENCE |
| 19905       | S/A INSTRUCTIONAL EQUIP REPLACEMENT   |
| 19933       | UC GENERAL FUND / FEDERAL OVERHEAD    |
| 19941       | UC GENERAL FUND                       |
| 19942       | NONRESIDENT TUITION                   |
| 66110       | ENDOWMENT ADMIN COST RECOVERY FEE     |
| 68800       | UNIVERSITY PATENT INCOME FUND         |
| 69006       | SSDP ASSESSMENT                       |
| 69240       | PRIVATE GIFT / GRANT STIP INCOME FUND |
| 69250       | CUF SHORT TERM INVESTMENT POOL INC    |
| 69763       | UC LAB FEE RESEARCH PROG / UCHRI      |
| 69820       | INCENTIVE PAYMENTS AND VENDOR REBATES |
| 69823       | CAMPUS COMMON GOODS ASSESSMENT        |
| 69825       | CAMPUS OVERHEAD FUNDS                 |
| 69826       | GEN & EMP PRAC LIAB RECHG             |
| 69831       | ENDOWMENT INFRASTRUCTURE FEE          |
| 69993       | CAMPUS ASSESSMENT FUND                |
| 75079       | GIFT FEE                              |

#### PPM Costs

* The presence of `ppmSegments` will override `ppmSegmentString`.
* If `ppmSegmentString` provided, it must parse properly, and contain either the first 4 or all 6 segments in the correct order.
* Verify that the 4 required segments have been provided. (`project`, `task`, `organization`, `expenditureType`)
* Verify values given in each PPM segment
  * Value must be a valid value for the segment.
  * Value must be active on the accounting date between the segment's start and end date.
  * See below for details on the checks performed on each segment.


##### Project Validations

* Project must be `ACTIVE` or `PENDING_CLOSE`
* Project must not be a departmental-default project (starting with `DKO`)
* Project must not be a template project
* Project must have an established budget (of any amount)
* Accounting date must be within the project's start and completion dates.

##### Task Validations

* Task must be valid for the project.
* Task must be marked as chargeable.
* Accounting date must be within the task's start and finish dates.

##### Organization Validations

* Organization must be enabled.
* Accounting date must be within the organization's effective start and end dates.

##### Expenditure Type Validations

* Expenditure type must be enabled.
* Accounting date must be within the expenditure type's start and end dates.
* **Special Case: Revenue Accounts**
  * PPM Does not allow revenue on transactions.  Special handling has been added to address this through the integration processes.  Specific GL Natural Accounts are allowed to be used on PPM transactions by boundary systems.  These are NOT set up as PPM Expenditure Types within Oracle, but an exception is made to the validation rules to allow them to be passed through so that responsive budgetary adjustments may be processed.
  * Allowed revenue accounts are children of the parents below:
    * `40090C` - Self Supporting Degree Fees
    * `40100C` - Professional Degree Supplemental Tuitions
    * `40200C` - University Extension Program Fees
    * `41000A` - Sales and Services of Educational Activities
    * `48000A` - Non-Capital Private Gifts
    * `77500C` - Internal Recharge Credit Interdepartmental within an Entity

##### Award Validation

* Award should only be included on sponsored projects and is **required** on sponsored projects.
* Award must be associated with the project.
* If left blank on a sponsored project, the operation will attempt to find a default.  If one can not be found, then the transaction will fail validation.  This will likely be due to an incomplete project setup which must be corrected in Oracle before transactions against that project may be submitted.
* Accounting date must be within the award's start and close dates.

##### Funding Source Validation

* Funding source should only be included on sponsored projects and is required on sponsored projects.
* Funding source must be associated with the project / award combination.
* If left blank on a sponsored project, the operation will attempt to find a default.  If one can not be found, then the transaction will fail validation.  This will likely be due to an incomplete project setup which must be corrected in Oracle before transactions against that project may be submitted.
* Accounting date must be within the funding source's from and to dates.


## Example `glJournalRequest` Requests

> Below are samples of the data object to be passed into the `glJournalRequest` mutation.
> Ignore the specific values.  No real attempt has been made to determine the actual values expected by Oracle.

### GL Recharges

> Normal recharge using individual GL Segment fields.

```jsonc
{
  // general request tracking information
  "header": {
    "consumerTrackingId": "5A314F00-C308-48FF-BF85-C8AF7FD43199", // unique ID assigned by boundary app
    "consumerReferenceId":  "ORDER_12345", // reference number used to pull multiple requests related to it
    "consumerNotes": "July Order from Xxxxxxx", // free-form description to include in later status checks
    "boundaryApplicationName": "My Boundary App" // name of the source boundary application
  },
  "payload": {
    "journalSourceName": "UCD Your Journal Source", // Assigned journal source ID from the Finance department
    "journalCategoryName": "UCD Recharge", // Allowed journal category name for the types of expenses
    "journalName": "MySystem Recharges for July 2023",
    "journalReference":  "ORDER_12345",
    "accountingDate": "2023-07-31",
    "accountingPeriodName": "Jul-23",
    // Array of accounting lines to post
    "journalLines": [
      {
        "glSegments": {
          "entity": "3110",
          "fund": "13U00",
          "department": "ADIT000",
          "purpose": "68",
          "account": "390000"
        },
        "debitAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      },
      {
        "glSegments": {
          "entity": "3110",
          "fund": "13U00",
          "department": "1203456",
          "account": "000060"
        },
        "creditAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      }
    ]
  }
}
```

### Use of Segment Strings

```jsonc
{
  // general request tracking information
  "header": {
    "consumerTrackingId": "5A314F00-C308-48FF-BF85-C8AF7FD43199", // unique ID assigned by boundary app
    "consumerReferenceId":  "ORDER_12345", // reference number used to pull multiple requests related to it
    "consumerNotes": "July Order from Xxxxxxx", // free-form description to include in later status checks
    "boundaryApplicationName": "My Boundary App" // name of the source boundary application
  },
  "payload": {
    "journalSourceName": "UCD Your Boundary App", // Assigned journal source ID from the Finance department
    "journalCategoryName": "UCD Recharge", // Allowed journal category name for the types of expenses
    "journalName": "MySystem Recharges for July 2023",
    "journalReference":  "ORDER_12345",
    "accountingDate": "2023-07-31",
    "accountingPeriodName": "Jul-23",
    // Array of accounting lines to post
    "journalLines": [
      {
        "glSegmentString": "3110-13U00-9300531-390000-68-000-0000000000-000000-0000-000000-000000",
        "debitAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      },
      {
        "glSegmentString": "3110-13U00-1203456-770000-00-000-0000000000-000000-0000-000000-000000",
        "creditAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      }
    ]
  }
}
```

### GL and PPM Expenses

```jsonc
{
  // general request tracking information
  "header": {
    "consumerId": "Boundary_System_Identifier", // assigned identifier of the boundary system
    "consumerTrackingId": "5A314F00-C308-48FF-BF85-C8AF7FD43199", // unique ID assigned by boundary app
    "consumerReferenceId":  "ORDER_12345", // reference number used to pull multiple requests related to it
    "consumerNotes": "July Order from Xxxxxxx", // free-form description to include in later status checks
    "boundaryApplicationName": "My Boundary App" // name of the source boundary application
  },
  "payload": {
    "journalSourceName": "UCD Your Boundary App", // Assigned journal source ID from the Finance department
    "journalCategoryName": "UCD Recharge", // Allowed journal category name for the types of expenses
    "journalName": "MySystem Recharges for July 2023",
    "journalReference":  "ORDER_12345",
    "accountingDate": "2023-07-31",
    "accountingPeriodName": "Jul-23",
    // Array of accounting lines to post
    "journalLines": [
      // recharge to department
      {
        "glSegmentString": "3110-13U00-9300479-390000-68-000-0000000000-000000-0000-000000-000000",
        "debitAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      },
      // income to provider
      {
        "glSegmentString": "3110-13U00-9300531-770000-00-000-0000000000-000000-0000-000000-000000",
        "creditAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      },
      // income to provider for PPM expense
      {
        "glSegments": {
          "entity": "3110",
          "fund": "13U00",
          "department": "ADIT000",
          "account": "770000"
        },
        "creditAmount": 500.00,
        "externalSystemIdentifier": "ITEMY"
      },
      // expense to managed project
      {
        "ppmSegments": {
          "project":          "GP12345678",
          "task":             "Task 1",
          "organization":     "9300479",
          "expenditureType":  "Lab Equipment"
        },
        "debitAmount": 500.00,
        "externalSystemIdentifier": "ITEMY",
        "ppmComment": "Something meaningful here"
      }
    ]
  }
}
```

### Example `glJournalRequest` Response

> Initial response after submitting request.  Oracle-provided data in the response will not be populated.

```jsonc
{
  "requestStatus": {
    "requestId": "BA77D46E-C610-406E-B426-38939E432968",
    "consumerId": "API_CONSUMER_ID",
    "consumerTrackingId": "5A314F00-C308-48FF-BF85-C8AF7FD43199", // unique ID assigned by boundary app
    "consumerReferenceId":  "ORDER_12345", // reference number used to pull multiple requests related to it
    "consumerNotes": "July Order from Xxxxxxx", // free-form description to include in later status checks
    "boundaryApplicationName": "My Boundary App", // name of the source boundary application
    "operationName": "glJournalRequest",
    "requestDateTime": "2021-07-23T17:00:00-0700",
    "requestStatus": "UNPROCESSED",
    "lastStatusDateTime": "2021-07-23T17:00:00-0700",
    "processedDateTime": null,
    "errorMessages": [],
    "statusRequestPayload": "{ \\"query\\": \\"query { glJournalRequestStatus(requestId:\\\\\\"BA77D46E-C610-406E-B426-38939E432968\\\\\\") { glJournalId requestStatus { requestId consumerId requestTime } }\\"}",
    "actionRequestPayload": "" // too large - would be entire request input
  }
}
```

### Example Raw JSON Payloads

If you don't have a GraphQL client, you can still post to the APIs by wrapping the above request objects in the GraphQL payload wrapper.  An example is below.  The payload goes in the `variables.data` object.  The `operationName` is as shown below and the `query` can be copied.  A sample result when that is used as the query is shown below.

```json
{
    "operationName": "glJournalRequest",
    "variables": {
        "data": {
            "header": {
                "boundaryApplicationName": "TESTING_APP",
                "consumerId": "CONSUMER_ID",
                "consumerReferenceId": "A_UNIQUE_ID",
                "consumerTrackingId": "CONSUMER_ORDER_NBR"
            },
            "payload": {
                "journalSourceName": "UCD Your Boundary App",
                "journalCategoryName": "UCD Recharge",
                "journalDescription": "Journal Description For Oracle",
                "journalName": "Journal Name For Oracle",
                "journalReference": "JournalReference",
                "accountingDate": "2021-09-10",
                "journalLines": [
                    {
                        "glSegments": {
                            "entity": "3110",
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
                            "entity": "3110",
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
    },
    "query": "mutation glJournalRequest($data: GlJournalRequestInput!) {  glJournalRequest(data: $data) {    requestStatus {      requestId      consumerId      requestDateTime      requestStatus      operationName    }   }}"
}
```

#### Sample Response for the Above

Responses are structured like the following.  Successful response data is wrapped by a `data.glJournalRequest` property.  If there are any errors, they are reported in a top-level `errors` property looking like the 2nd response below.

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


## Data Object to Oracle Mapping

> Base Object:                        `GlJournalRequestInput`
> `payload`:                          `GlJournalInput`
> `payload.journalLines`:             `[GlJournalLineInput]`
> `payload.journalLines.glSegments`:  `GlSegmentInput`
> `payload.journalLines.ppmSegments`: `PpmSegmentInput`

### For GL Entry Segment Lines

| GraphQL Property                              | Req? | Oracle FBDI Destination                      | GL_INTERFACE Column   |
| --------------------------------------------- | ---- | -------------------------------------------- | --------------------- |
| **Journal Header Fields**                     |      | ------------------------------------         | --------------------- |
| Constant: `NEW`                               |      | Status Code                                  | STATUS                |
| payload.accountingDate                        |      | Effective Date of Transaction                | ACCOUNTING_DATE       |
| payload.journalSource                         | Yes  | Journal Source                               | USER_JE_SOURCE_NAME   |
| payload.journalCategoryName                   | Yes  | Journal Category                             | USER_JE_CATEGORY_NAME |
| Constant: `USD`                               |      | Currency Code                                | CURRENCY_CODE         |
| Constant: `A`                                 |      | Actual Flag                                  | ACTUAL_FLAG           |
| Computed: `(request date)`                    |      | Journal Entry Creation Date                  | DATE_CREATED          |
| (blank - allow Oracle Default)                |      | REFERENCE1 (Batch Name)                      | REFERENCE1 (100)      |
| (blank - allow Oracle Default)                |      | REFERENCE2 (Batch Description)               | REFERENCE2 (240)      |
| payload.journalName                           | Yes  | REFERENCE4 (Journal Entry Name)              | REFERENCE4 (100)      |
| payload.journalDescription                    |      | REFERENCE5 (Journal Entry Description)       | REFERENCE5 (240)      |
| payload.journalReference                      | Yes  | REFERENCE6 (Journal Entry Reference)         | REFERENCE6 (100)      |
| payload.accountingPeriodName                  |      | Period Name                                  | PERIOD_NAME           |
| Constant: `UCD Primary Ledger`                |      | Ledger Name                                  | LEDGER_NAME           |
| **Journal Lines Fields**                      |      | ------------------------------------         | --------------------- |
| payload.journalLines.glSegments.entity        | Yes  | Segment1                                     | SEGMENT1              |
| payload.journalLines.glSegments.fund          | Yes  | Segment2                                     | SEGMENT2              |
| payload.journalLines.glSegments.department    | Yes  | Segment3                                     | SEGMENT3              |
| payload.journalLines.glSegments.account       | Yes  | Segment4                                     | SEGMENT4              |
| payload.journalLines.glSegments.purpose       |      | Segment5                                     | SEGMENT5              |
| payload.journalLines.glSegments.program       |      | Segment6                                     | SEGMENT6              |
| payload.journalLines.glSegments.project       |      | Segment7                                     | SEGMENT7              |
| payload.journalLines.glSegments.activity      |      | Segment8                                     | SEGMENT8              |
| Constant: `0000`                              |      | Segment9                                     | SEGMENT9              |
| Constant: `000000`                            |      | Segment10                                    | SEGMENT10             |
| Constant: `000000`                            |      | Segment11                                    | SEGMENT11             |
| payload.journalLines.debitAmount              | ***  | Entered Debit Amount                         | ENTERED_DR            |
| payload.journalLines.creditAmount             | ***  | Entered Credit Amount                        | ENTERED_CR            |
| Constant: `UCD RECHARGES`                     |      | Attribute Category                           | ATTRIBUTE_CATEGORY    |
| payload.journalLines.externalSystemIdentifier | Yes  | ATTRIBUTE1 Value for Journal Entry Line DFF  | ATTRIBUTE1 (10)       |
| payload.journalLines.externalSystemReference  |      | ATTRIBUTE2 Value for Journal Entry Line DFF  | ATTRIBUTE2 (25)       |
| Constant: **TBD**                             |      | REFERENCE10 (Journal Entry Line Description) | REFERENCE10 (240)     |

### Property Lookup Validations

| GraphQL Property                           | Local Data Object      | Local Data Object Property |
| ------------------------------------------ | ---------------------- | -------------------------- |
| payload.accountingPeriodName               | GlAccountingPeriod     | name                       |
| payload.journalSource                      | GlJournalSource        | name                       |
| payload.journalCategoryName                | GlJournalCategory      | name                       |
| payload.journalLines.glSegments.entity     | ErpEntity              | code                       |
| payload.journalLines.glSegments.fund       | ErpFund                | code                       |
| payload.journalLines.glSegments.department | ErpFinancialDepartment | code                       |
| payload.journalLines.glSegments.account    | ErpAccount             | code                       |
| payload.journalLines.glSegments.purpose    | ErpPurpose             | code                       |
| payload.journalLines.glSegments.program    | ErpProgram             | code                       |
| payload.journalLines.glSegments.project    | ErpProject             | code                       |
| payload.journalLines.glSegments.activity   | ErpActivity            | code                       |

### For PPM Costing Segment Lines

> where limits noted, values should be trimmed to the given length

| GraphQL Property                                        | Req? | Oracle FBDI Destination                    | PJC_TXN_XFACE_STAGE_ALL_MISC Column |
| ------------------------------------------------------- | ---- | ------------------------------------------ | ----------------------------------- |
| Constant: `MISCELLANEOUS`                               |      | Transaction Type                           | TRANSACTION_TYPE                    |
| Constant: `UCD Business Unit` / `UCD CGA Business Unit` |      | Business Unit Name                         | BUSINESS_UNIT                       |
| Constant: `UCD Miscellaneous Costs`                     |      | Third-Party Application Transaction Source | USER_TRANSACTION_SOURCE             |
| Constant: `Unaccounted External Transactions`           |      | Document Name                              | DOCUMENT_NAME                       |
| payload.journalSource                                   |      | Document Entry                             | DOC_ENTRY_NAME                      |
| _Calculated: see below_                                 | Yes  | Expenditure Batch                          | BATCH_NAME (200)                    |
| _Calculated: see below_                                 | Yes  | Batch Description                          | BATCH_DESCRIPTION (250)             |
| payload.accountingDate                                  |      | Expenditure Item Date                      | EXPENDITURE_ITEM_DATE               |
| payload.journalLines.ppmSegments.project                |      | Project Number                             | PROJECT_NUMBER (10)                 |
| payload.journalLines.ppmSegments.task                   |      | Task Number                                | TASK_NUMBER (100)                   |
| payload.journalLines.ppmSegments.expenditureType (name) |      | Expenditure Type                           | EXPENDITURE_TYPE (240)              |
| payload.journalLines.ppmSegments.organization (name)    |      | Expenditure Organization                   | ORGANIZATION_NAME (240)             |
| payload.journalLines.ppmSegments.award                  |      | Contract Number                            | CONTRACT_NUMBER                     |
| payload.journalLines.ppmSegments.fundingSource          |      | Funding Source Number                      | FUNDING_SOURCE_NUMBER               |
| payload.journalLines.debitAmount                        | ***  | Quantity                                   | QUANTITY                            |
| payload.journalLines.creditAmount                       | ***  | Quantity                                   | QUANTITY                            |
| Constant: `DOLLARS`                                     |      | Unit of Measure Code                       | UNIT_OF_MEASURE_NAME                |
| payload.journalLines.ppmComment                         | Yes  | Expenditure Item Comment                   | EXPENDITURE_COMMENT (240)           |
| _Calculated: see below_                                 | Yes  | Original Transaction Reference             | ORIG_TRANSACTION_REFERENCE (120)    |
| Constant: `USD`                                         |      | Transaction Currency Code                  | DENOM_CURRENCY_CODE                 |
| payload.journalLines.debitAmount                        | ***  | Raw Cost in Transaction Currency           | DENOM_RAW_COST                      |
| payload.journalLines.creditAmount                       | ***  | Raw Cost in Transaction Currency           | DENOM_RAW_COST                      |
| (empty)                                                 |      | Billable                                   | BILLABLE_FLAG                       |
| (empty)                                                 |      | Capitalizable                              | CAPITALIZABLE_FLAG                  |
| Constant: `PJC_All`                                     |      | Context Category                           | CONTEXT_CATEGORY                    |

* **Destination: Expenditure Batch (batch name)**
  * We want to ensure each batch is unique for tracking purposes.
  * Replace spaces in the journal name below with underscores.
  * The date should be the date of the request processing, not the accounting date from the payload.
  * `${payload.journalName}_yyyymmddhhmmss`
* **Destination: Batch Description**
  * `${payload.journalReference} ${payload.journalDescription}`
* **Destination: Original Transaction Reference**
  * This must be unique across all time within the transaction source (which is hard-coded, not per source).  To prevent conflicts between fed transactions (both within and between boundary systems), we will compute a unique value based on provided input.
  * In the journal source name below, replace spaces with underscores.
  * The date should be the date of the request processing, not the accounting date from the payload.
  * `header.consumerTrackingId` is supposed to be unique across all requests from a journal source.  The API server will enforce this.
  * `LineNumber` is the number of the line within the source request `journalLines` array.
  * `${payload.journalSource}-${header.consumerTrackingId}-${LineNumber}-${payload.journalLines.externalSystemIdentifier}-${payload.journalLines.externalSystemReference}`

### Property Lookup Validations

| GraphQL Property                                 | Local Data Object          | Local Data Object Property |
| ------------------------------------------------ | -------------------------- | -------------------------- |
| payload.journalLines.ppmSegments.project         | PpmProject                 | projectNumber              |
| payload.journalLines.ppmSegments.task            | PpmTask                    | taskNumber                 |
| payload.journalLines.ppmSegments.expenditureType | PpmExpenditureType         | name                       |
| payload.journalLines.ppmSegments.organization    | PpmExpenditureOrganization | name                       |
| payload.journalLines.ppmSegments.award           | PpmAward                   | awardNumber                |
| payload.journalLines.ppmSegments.fundingSource   | PpmFundingSource           | fundSourceNumber           |


## Testing Scenarios

> To Be Expanded: dump format at present

* **Assumption: API Call is correctly structured as a GraphQL call and properly referenced a named operation.**
* **Assumption: User has authenticated and their authorization roles have been retrieved from Grouper.**

1. Request Validations

   1. Improperly formatted input data is rejected with a GraphQL Error.
   2. Request is not processed if the user does not have authorization to use the operation and are rejected with an appropriate message to the consumer.
   3. Payloads with missing or blank input data are rejected with a GraphQL Error.

2. Request Header Validations

   1. Request is rejected if the consumer ID in the header does not match the authentication information.
   2. Request is rejected if the Journal Source/Category does not match the API Consumer.

3. Journal Header Validations
   1. Journal Lines are present and less than the maximum number allowed.
   2. Accounting date, if present, evaluates to an open GL Accounting Period
   3. Accounting Period, if present, is open
   4. GL Segment Defaults, if given, individually validate.
   5. PPM Segment Defaults, if present, and necessary parent values also provided, validate.

4. Journal Line Validations
   1. Line-Level Validations
      1. Lines with both GL and POET values will fail request validation.
      2. Lines with incomplete GL or POET values (after applying defaults) will fail request validation.
      3. Lines with invalid GL segment values will fail request validation.
      4. Lines with inactive GL segment values (as of the given accounting date) will fail request validation.
      5. Lines using non-leaf (lowest level) GL segment values will fail request validation.
      6. Lines with invalid PPM segment values (or relationships between PPM segments) will fail request validation.
      7. Lines using non-leaf (lowest level) PPM Task values will fail request validation.
      8. Lines violating the mapped CVRs will fail request validation.
      9. Lines using GL segment values not allowed for boundary system integrations will fail request validation.
      10. PPM Costs must fall within the project, task, and expenditure organization start and end dates.
   2. Line-Aggregate Validations
      1. Journal lines (GL/PPM combined) must balance to zero.
      2. Total debits on journal must not exceed...?

5. Upon any validation failure:
   1. GraphQL-level failures will report errors in an error property per the GraphQL specification.
   2. Application validations will return the appropriate response for the operation with the `requestStatus` property populated with `errorMessages`.
   3. No request will be saved to the action request tracking database.

6. Behaviors (once all validations passed)
   1. When GL and PPM lines are present.  And PPM Line debits do not equal credits, then offsetting GL entries are created for each PPM line using the defined GL-PPM clearing account.
   2. The request will be stored to a tracking table.  A separate process is responsible for picking it up and processing it for Oracle.
