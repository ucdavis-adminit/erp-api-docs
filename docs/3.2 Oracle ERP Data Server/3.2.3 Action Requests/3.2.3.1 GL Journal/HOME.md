# 3.2.3.1 GL Journal

<!--BREAK-->
### Action Request: `GlJournal`

#### Overview

<!-- Start copy to GraphQL API Docs -->

The journal voucher is the primary interface for loading transactions into Oracle from boundary systems.  It is used regardless of whether the expenses are costs which can be applied to the general ledger or must be expensed to the PPM sub-ledger.  The data model in the request allows for all fields which might be needed for GL or PPM transactions to be provided.  However, it is up to the caller to know and fill out the fields properly.  Where possible, the API will reject invalid data prior to it being sent to Oracle.

This API replaces the KFS GL Collector process.  While the valid values of the FAU components (now called chartstring segments) have changed, the basic concepts of feeding transactional data to the financial system have not.  As always, transactions submitted to the GL must be balanced between debits and credits.  Valid values must be used for certain fields, and fields have content and length limits.

The correct values to use for chartstring segments is out of scope for this documentation.  This API is the mechanism by which you submit values already determined to be functionally correct to the financial system.  Other operations on this server provide data retrieval and validation tools to support generation of correct data payloads for the API.

Please see below in this document for examples of payloads into this API.

#### Supporting Operations

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

#### Managed Project Cost Entries (PPM/POET)

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

#### Volume of Data

Unlike the use of the KFS ledger, the Oracle Financials general ledger will be a thin ledger.  This means that the level of detail that is allowed to be loaded into the ledger will be limited to summary level information.  It is required that you summarize data down as much as possible to the chartstring segments while being able to retain a link to the source of the transactions.  (E.g., an order number, batch number, or a transaction date)  Submitting lines for each source line item in an external billing system will not be allowed.  Failure to summarize data to an acceptable level will result in loss of API or journal upload access.

#### Journal Balancing

As with the KFS ledger, journal payloads must balance.  (debit = credits)  Each API payload is a single journal (document number in KFS).

While lines with `glSegments` and `ppmSegments` are posted to different ledgers, we can balance across them when creating journals.  Offset entries are required by Oracle to keep the GL in balance until sub-ledger accounting processes execute.  These will be created by the integration framework for you and applied to a central clearing location outside of your department's cost center.

#### Basic Use

1. Call the operation (`glJournalRequest`) providing a data payload with the proper structure.  (See [`GlJournalRequestInput`]({{Types.GlJournalRequestInput}}))
2. GraphQL Server will validate content format and reject if invalid.
3. API Server will perform request-specific validation against a local copy of Oracle ERP data.
4. A failure in either of these initial validations will result in an error response with no request being generated.
5. Passing validation will save the request to allow for pickup by the integration platform for processing.
6. A request tracking ID will be generated and returned to allow for the consumer to check on the status of the request and obtain results when completed.
7. At a later time, use the generated request tracking ID against the [`glJournalRequestStatus`]({{Queries.glJournalRequestStatus}}) operation to determine if the request was processed successfully

<!-- End copy to GraphQL API Docs -->

#### Operations

##### `glJournalRequest`

> Submits a journal voucher data object for validation and submission to the Oracle ERP system.  Returns a handle with the results of the request submission.  This handle contains the operation to submit back to this server to get the results.

* **Parameters**
  * `data : GlJournalRequestInput!`
* **Returns**
  * `GlJournalRequestStatusOutput!`

##### `glJournalRequestStatus`

> Retrieves a GlJournal by the unique request ID assigned by the API upon submission of the request.

* **Parameters**
  * `requestId : String!`
* **Returns**
  * `GlJournalRequestStatusOutput`

##### `glJournalRequestStatusByConsumerTracking`

> Retrieves a GlJournal by the unique tracking ID provided by the consumer during submission of the request.

* **Parameters**
  * `consumerTrackingId : String!`
* **Returns**
  * `GlJournalRequestStatusOutput`

##### `glJournalRequestStatusByConsumerReference`

> Retrieves a list of GlJournals by the reference ID provided by the consumer during submission of the request.

* **Parameters**
  * `consumerReferenceId : String!`
* **Returns**
  * `[GlJournalRequestStatusOutput!]!`

#### Related Lookup Objects

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
  * [`GlAccountAlias`](../3.2.1%20Data%20Objects/GlAccountAlias.md)
  * [`GlAccountingCombination`](../3.2.1%20Data%20Objects/GlAccountingCombination.md)
  * [`GlAccountingPeriod`](../3.2.1%20Data%20Objects/GlAccountingPeriod.md)
  * [`GlJournalCategory`](../3.2.1%20Data%20Objects/GlJournalCategory.md)
  * [`GlJournalSource`](../3.2.1%20Data%20Objects/GlJournalSource.md)
* **PPM Costing**
  * [`PpmProject`](../3.2.1%20Data%20Objects/PpmProject.md)
  * [`PpmTask`](../3.2.1%20Data%20Objects/PpmTask.md)
  * [`PpmExpenditureType`](../3.2.1%20Data%20Objects/PpmExpenditureType.md)
  * [`PpmOrganization`](../3.2.1%20Data%20Objects/PpmOrganization.md)
  * [`PpmFundingSource`](../3.2.1%20Data%20Objects/PpmFundingSource.md)
  * [`PpmAward`](../3.2.1%20Data%20Objects/PpmAward.md)
* **PPM Costs Support**
  * [`PpmDocumentEntry`](../3.2.1%20Data%20Objects/PpmDocumentEntry.md)

  <!-- * [`PpmDocument`](../3.2.1%20Data%20Objects/PpmDocument.md) -->
  <!-- * [`PpmExpenseCategory`](../3.2.1%20Data%20Objects/PpmExpenseCategory.md) -->
  <!-- * [`PpmProjectStatus`](../3.2.1%20Data%20Objects/PpmProjectStatus.md) -->
  <!-- * [`PpmProjectType`](../3.2.1%20Data%20Objects/PpmProjectType.md) -->
  <!-- * [`PpmTransactionSource`](../3.2.1%20Data%20Objects/PpmTransactionSource.md) -->


#### Request Objects

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

#### Response Objects

* `GlJournalRequestStatusOutput`
  * Child Request Objects:
    * [`ActionRequestStatus`](./1_CommonTypes.md)

#### Object Properties

> Note: Object properties are for general documentation only.  The definitive data model is defined by the SDL retrieved from the graphql servers.

##### `GlJournalInput`

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

<!-- | glSegmentDefaults    | [`GlSegmentInput`](./1_CommonTypes.md)  |                                     | -->
<!-- | ppmSegmentDefaults   | [`PpmSegmentInput`](./1_CommonTypes.md) |                                     | -->
<!-- | TBD                  |                                         | (Other Journal-level Reference fields defined by functional team.) | -->
<!-- | summarizeEntries     | Boolean                               |                                                                    |
| postErrorsToSuspense | Boolean                               |                                                                    | -->
<!-- | balanceType          | NonEmptyTrimmedString15               |                                                                    | -->
<!--
| externalReference    | String!                     | The reference information for the journal entered by the user.                           |
| encumbranceType      | String                      | Type of encumbrance for records with an encumbrance balance type.                         |
| referenceDate        | String!                     |                                                                                          | -->

##### `GlJournalLineInput`

> Represents a single journal line or PPM Cost.  Every line must have a set of GL _or_ POET segments and a credit or debit amount.  All other fields are optional.

| Property Name            | Type                                    | Notes                                                                                                                                                                                                                       |
| ------------------------ | --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|                          |                                         | **GL Distribution / PPM Costing Fields**                                                                                                                                                                                    |
| glSegments               | [`GlSegmentInput`](./1_CommonTypes.md)  | GL Segment fields.  Only those with non-default values need to be filled.                                                                                                                                                   |
| glSegmentString          | GlSegmentString                         | Delimited complete GL segment string.  All fields of the GL Accounting Key must be provided.                                                                                                                                |
| glAliasCode              | NonEmptyTrimmedString15                 | GL Alias string which will be used to populate all GL Segments for this accounting line.                                                                                                                                    |
|                          |                                         | PPM POET segment values.  If provided, this will override any provided GL segments.                                                                                                                                         |
| ppmSegments              | [`PpmSegmentInput`](./1_CommonTypes.md) | PPM POET segment values.  If provided, this will override any provided or default GL segments.  Any non-provided values which are present in the ppmSegmentDefaults property of the header will be filled in automatically. |
|                          |                                         | **Transaction Line Details**                                                                                                                                                                                                |
| creditAmount             | NonNegativeFloat                        | Debit amount of the GL transaction or PPM Cost.  Only one of debitAmount and creditAmount may be specified on a line.                                                                                                       |
| debitAmount              | NonNegativeFloat                        | Credit amount of the GL transaction or PPM Cost.  Only one of debitAmount and creditAmount may be specified on a line.                                                                                                      |
| externalSystemIdentifier | GlReferenceField10!                     | This 10-character field is intended to aid with linking boundary systems transactions to Oracle Cloud summarized journal entries for the purposes of reconciliation.                                                        |
| externalSystemReference  | GlReferenceField25                      | This 25-character field is intended to aid in additional linking of boundary systems transactions, as needed, to Oracle Cloud summarized journal entries for the purposes of reconciliation.                                |
| ppmComment               | GlDescriptionField40                    | Expenditure comment for PPM transactions.  Will be ignored for GL transactions.                                                                                                                                             |

##### `GlJournalRequestStatusOutput`

> Output type for GLJournal requests and follow-up status updates.
>
> Contains the overall request status.  After a successful creation of the journal, will also contain the Oracle Financials assigned journal ID.


| Property Name     | Type                                         | Notes                                                                                                                                                            |
| ----------------- | -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| requestStatus     | [`ActionRequestStatus`](./1_CommonTypes.md)! | General action request status and tracking information.                                                                                                          |
| validationResults | [`ValidationResponse`](./1_CommonTypes.md)   | Errors found when validatating the payload data.  These must be corrected before the request will be accepted.                                                   |
|                   |                                              | **GlJournal-Specific Properties**                                                                                                                                |
| glJournalId       | Long                                         | ERP-assigned journal ID for transactions posted to the GL.  Only populated on subsequent status requests if the journal was successfully processed.              |
| ppmBatchName      | NonEmptyTrimmedString100                     | Integration-assigned batch name for costs posted to the PPM sub-ledger.  Only populated on subsequent status requests if the journal was successfully processed. |


#### GLJournal API Validations

##### Per GraphQL Data Model and Type Resolvers

> These validations will be enforced by the GraphQL parser and data type definitions.

* Valid JSON data structure.
* Required fields (enforced by GraphQL data model)
* Ensure required fields are non-blank. (enforced by GraphQL data model)
* Ensure fields are formatted properly (enforced by GraphQL data model - and custom code if needed)
* Verify maximum lengths on fields.  (Delegate using custom data types if possible.)
  * (e.g., `TrimmedNonEmptyString240`)

##### Request Header Checks

* Validate Journal Source
  * Verify Source is allowed for API consumer. (TBD - We will want to link the API Consumer authentication identifier to the journal sources.)
* Validate Journal Category
  * Verify Category is valid for API use. (TBD - only a small set of journal categories will be able to be used via integrations)
  * Verify Category is allowed for API consumer. (Each API Consumer may have a limited set of journal categories they are allowed to use.)
* Confirm if `consumerTrackingId` previously used and reject if found in the action request table.

##### Data Validation

* **Overall**

  * Verify that a non-zero number of journal lines have been provided.
  * Verify number of lines `<=` 1000 (Preliminary number - should be a constant we can adjust easily via config options)
  * Verify no line was given both GL and POET segments.
  * Verify that any field provided by the consumer that has a valid list of values in Oracle contains a valid and active value.

* **GL Transactions**

  * Verify values given in GL segments
    * values in each each line's segments.
    * If the program, project, or activity fields have an invalid value, replace with all zeroes.
    * If the purpose has an invalid value, and is not required per the CVR rules below, replace with zeroes.
    * The project in `glSegments` must be a GL-only project.  It must have `GL0000000A` as a parent.  (Use direct parent for now, there is no plan to make the hierarchy multi-level.)
    * Segment must not be a summary value and must allow detail posting. **(TODO)**
  * Verify Accounting Period if given.  It must exist and be open.  Assign current accounting period if missing.  Fail if an invalid period was given.
  * Verify that any field which has a valid list of values contains a valid value.
  * Verify that the GL journal lines balance to zero.  (I.e., debits == credits)
    * Calculation must be made after the generation of PPM offset GL entries.
  * **Boundary API Additional Restrictions**
    * _Net Position Accounts are not allowed_
      * If the account descends from 30000X, fail validation.
    * _PPM Offset Account is not allowed_
      * If the account == `TBD`, fail validation.
  * **Validate via Combination Code** **(TODO)**
    * Check if the combination of the 11 GL segments is a known, valid combination.
    * Using the GlAccountingCombination, check if the combination is valid is known and is active and valid for the given accounting date.  If so, CVR rules do not need to be run.  Oracle will allow any valid combination even if does not match the current CVR rules.  There is no validation failure for this rule.  This is only to short-circuit the CVR rules.
    * Must be open for detail posting, and not a summary combination code.
  * **CVR Matching Rules (message then technical rule)**
    * _Purpose is required for Expense Accounts (OPER_ACC_PURPOSE_1)_
      * If the account descends from 50000B, then the purpose must be a non 00 value.
    * _Financial Aid Expenses must have Student Financial Aid purpose code 78 (OPER_ACC_PURPOSE_4)_
      * If the account descends from 51000A, then the purpose code must be 78.
    * _Purpose code 78 (Student Financial Aid) must only be used with Financial Aid Expenses (OPER_ACC_PURPOSE_5)_
      * If the purpose code is 78, then the account must descend from 51000A.
    * _Auxiliary Funds should only be used for Auxiliary Enterprise (76) purposes (OPER_FUND_PURPOSE)_
      * If the fund is a descendent of 1100C, then purpose code must be 76.
    * _Purpose code 76 (Auxiliary Enterprises) must only be used with Financial Auxilary Funds (OPER_PURPOSE_FUND)_
      * If the purpose code is 76, then the fund must descend from 1100C.
    * _Recharge Accounts must have Transfer Activity (85) Purpose (NAT_ACC_PURPOSE)_
      * If the account starts with 7, then the purpose must be 85.
    * _Transfer Activities (purpose 85) must only be used with 7xxxxx Recharge Accounts (PUR_NAT_ACC)_
      * If the purpose code is 85, then the account must start with 7.
    * _Funds held for others (Account 22700D) should only be used with Agency Fund (Fund 5000C) (AGENCY_FUND_ACCT)_
      * If the account descends from 22700D, then the fund must descend from 5000C.
    * _Sub-contract services (53300B) should only be used on Grant and Contract Funds (2000B)_
      * If the account is a descendent of 53300B, then the fund must be descended from 2000B.

* **PPM Costs**

  * Verify values given in each PPM segment
    * values in each each line's segments.
  * Verify lines have complete PPM segments (project, task, organization, expenditure type)
    * Verify Award and Funding Source populated and valid if the Project has a Sponsored Project type. (per `sponsoredProject` flag on the project type)
      * This would be after derivation of the award and funding source from the project if not provided by the end user.
  * **Validate Project**
    * _Project is not Active_
      * `projectStatus` = `ACTIVE`
    * _Costs can not be assigned to template projects_
      * `templateProject` = false
    * _This project is for internal processing purposes only_
      * (An award project (a project used for internal processing in Oracle Grants Accounting))
      * **RULE TBD - UNKNOWN HOW TO DETECT THIS**
    * An intercompany provider project
      * **RULE TBD - UNKNOWN HOW TO DETECT THIS**
    * _Billing is not enabled for this project_
      * `billingEnabled`
    * _Given accounting date (yyyy-mm-dd) is not within the project start and completion dates._
      * Check accounting date against the `projectStartDate` and `projectCompletionDate`s.
  * **Validate Task**
    * _Summary tasks may not record costs_
      * is lowest level (`lowestLevelTask`)
    * _Task does not accept costs_
      * marked as `chargeable`
    * _Given accounting date (yyyy-mm-dd) is not within the task start and completion dates._
      * Check accounting date against the `taskStartDate` and `transactionCompletionDate`s.
  * **Validate Expenditure Type**
    * _Expenditure Type is not active_
      * is active
      * is not outside of start and end dates (`expenditureTypeStartDate` - `expenditureTypeEndDate`)
  * **Validate Expenditure Organization**
    * Accounting date falls within expense org dates (`effectiveStartDate` and `effectiveEndDate`)


#### Example `glJournalRequest` Requests

> Below are samples of the data object to be passed into the `glJournalRequest` mutation.
> Ignore the specific values.  No real attempt has been made to determine the actual values expected by Oracle.

##### GL Recharges

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
    "journalSourceName": "BOUNDARY_APP_1", // Assigned journal source ID from the Finance department
    "journalCategoryName": "INTERCOMPANY_REVENUE", // Allowed journal category name for the types of expenses
    "journalName": "MySystem Recharges for July 2023",
    "journalReference":  "ORDER_12345",
    "accountingDate": "2023-07-31",
    "accountingPeriodName": "Jul-23",
    // Array of accounting lines to post
    "journalLines": [
      {
        "glSegments": {
          "entity": "1311",
          "fund": "99100",
          "department": "9300051",
          "purpose": "68",
          "account": "390000"
        },
        "debitAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      },
      {
        "glSegments": {
          "entity": "1311",
          "fund": "99100",
          "department": "1203456",
          "account": "000060"
        },
        "creditAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      },
    ]
  },
}
```

##### Use of Aliases

> NOTE: Aliases are centrally managed within Oracle and not available to all campus boundary systems.

**TODO**

##### Use of Segment Strings

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
    "journalSourceName": "BOUNDARY_APP_1", // Assigned journal source ID from the Finance department
    "journalCategoryName": "INTERCOMPANY_REVENUE", // Allowed journal category name for the types of expenses
    "journalName": "MySystem Recharges for July 2023",
    "journalReference":  "ORDER_12345",
    "accountingDate": "2023-07-31",
    "accountingPeriodName": "Jul-23",
    // Array of accounting lines to post
    "journalLines": [
      {
        "glSegmentString": "1311-99100-9300051-390000-68-000-0000000000-000000-0000-000000-000000",
        "debitAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      },
      {
        "glSegmentString": "1311-99100-1203456-770000-00-000-0000000000-000000-0000-000000-000000",
        "creditAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      },
    ]
  },
}
```

##### PPM Expenses

**TODO**

##### GL and PPM Expenses

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
    "journalSourceName": "BOUNDARY_APP_1", // Assigned journal source ID from the Finance department
    "journalCategoryName": "INTERCOMPANY_REVENUE", // Allowed journal category name for the types of expenses
    "journalName": "MySystem Recharges for July 2023",
    "journalReference":  "ORDER_12345",
    "accountingDate": "2023-07-31",
    "accountingPeriodName": "Jul-23",
    // Array of accounting lines to post
    "journalLines": [
      // recharge to department
      {
        "glSegmentString": "1311-99100-9300479-390000-68-000-0000000000-000000-0000-000000-000000",
        "debitAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      },
      // income to provider
      {
        "glSegmentString": "1311-99100-9300051-770000-00-000-0000000000-000000-0000-000000-000000",
        "creditAmount": 100.00,
        "externalSystemIdentifier": "ITEMX"
      },
      // income to provider for PPM expense
      {
        "glSegments": {
          "entity": "1311",
          "fund": "99100",
          "department": "9300051",
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

#### Example `glJournalRequest` Response

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
  },
  "glJournalId": null,
}
```

#### Example Raw JSON Payloads

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
    },
    "query": "mutation glJournalRequest($data: GlJournalRequestInput!) {  glJournalRequest(data: $data) {    requestStatus {      requestId      consumerId      requestDateTime      requestStatus      operationName    }   }}"
}
```

##### Sample Response for the Above

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


#### Data Object to Oracle Mapping

> Base Object:                        `GlJournalRequestInput`
> `payload`:                          `GlJournalInput`
> `payload.journalLines`:             `[GlJournalLineInput]`
> `payload.journalLines.glSegments`:  `GlSegmentInput`
> `payload.journalLines.ppmSegments`: `PpmSegmentInput`

##### For GL Entry Segment Lines

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

###### Property Lookup Validations

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

##### For PPM Costing Segment Lines

> where limits noted, values should be trimmed to the given length

| GraphQL Property                                 | Req? | Oracle FBDI Destination                     | GL_INTERFACE Column                         |
| ------------------------------------------------ | ---- | ------------------------------------------- | ------------------------------------------- |
| Constant: `MISCELLANEOUS`                        |      | Transaction Type                            | TRANSACTION_TYPE                            |
| Constant: `UCD Business Unit`                    |      | Business Unit Name                          | BUSINESS_UNIT                               |
| Constant: `UCD Miscellaneous Costs`              |      | Third-Party Application Transaction Source  | USER_TRANSACTION_SOURCE                     |
| Constant: `Unaccounted External Transactions`    |      | Document Name                               | DOCUMENT_NAME                               |
| payload.journalSource                            |      | Document Entry                              | DOC_ENTRY_NAME                              |
| _Calculated: see below_                          | Yes  | Expenditure Batch                           | BATCH_NAME (200)                            |
| _Calculated: see below_                          | Yes  | Batch Description                           | BATCH_DESCRIPTION (250)                     |
| payload.accountingDate                           |      | Expenditure Item Date                       | EXPENDITURE_ITEM_DATE                       |
| payload.journalLines.ppmSegments.project         |      | Project Number                              | PROJECT_NUMBER (10)                         |
| payload.journalLines.ppmSegments.task            |      | Task Number                                 | TASK_NUMBER (100)                           |
| payload.journalLines.ppmSegments.expenditureType |      | Expenditure Type                            | EXPENDITURE_TYPE (240)                      |
| payload.journalLines.ppmSegments.organization    |      | Expenditure Organization                    | ORGANIZATION_NAME (240)                     |
| payload.journalLines.ppmSegments.award           |      | Contract Name / Contract Number             | CONTRACT_NAME / CONTRACT_NUMBER             |
| payload.journalLines.ppmSegments.fundingSource   |      | Funding Source Name / Funding Source Number | FUNDING_SOURCE_NAME / FUNDING_SOURCE_NUMBER |
| Constant: `1.00`                                 |      | Quantity                                    | QUANTITY                                    |
| Constant: `EA`                                   |      | Unit of Measure Code                        | UNIT_OF_MEASURE_NAME                        |
| payload.journalLines.ppmComment                  | Yes  | Expenditure Item Comment                    | EXPENDITURE_COMMENT (240)                   |
| _Calculated: see below_                          | Yes  | Original Transaction Reference              | ORIG_TRANSACTION_REFERENCE (120)            |
| Constant: `USD`                                  |      | Transaction Currency Code                   | DENOM_CURRENCY_CODE                         |
| payload.journalLines.debitAmount                 | ***  | Raw Cost in Transaction Currency            | DENOM_RAW_COST                              |
| payload.journalLines.creditAmount                | ***  | Raw Cost in Transaction Currency            | DENOM_RAW_COST                              |
| (empty)                                          |      | Billable                                    | BILLABLE_FLAG                               |
| (empty)                                          |      | Capitalizable                               | CAPITALIZABLE_FLAG                          |
| Constant: `PJC_All`                              |      | Context Category                            | CONTEXT_CATEGORY                            |

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

##### Property Lookup Validations

| GraphQL Property                                 | Local Data Object          | Local Data Object Property |
| ------------------------------------------------ | -------------------------- | -------------------------- |
| payload.journalSource                            | PpmDocumentEntry           | name                       |
| payload.journalLines.ppmSegments.project         | PpmProject                 | projectNumber              |
| payload.journalLines.ppmSegments.task            | PpmTask                    | name                       |
| payload.journalLines.ppmSegments.expenditureType | PpmExpenditureType         | name                       |
| payload.journalLines.ppmSegments.organization    | PpmExpenditureOrganization | name                       |
| payload.journalLines.ppmSegments.award           | PpmAward                   | awardNumber                |
| payload.journalLines.ppmSegments.fundingSource   | PpmFundingSource           | fundSourceNumber           |


#### Testing Scenarios

> To Be Expanded: dump format at present

* **Assumption: API Call is correctly structured as a GraphQL call and properly referenced a named operation.**
* **Assumption: User has authenticated and their authorization roles have been retrieved from Grouper.**

1. Request Validations

   1. Improperly formatted input data is rejected with a GraphQL Error.
   2. Request is not processed if the user does not have authorization to use the operation.
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
   1. When GL and PPM lines are present.  And GL Line debits do not equal credits, then offsetting GL entries are created for each PPM line using the defined GL-PPM clearing account.
   2. The request will be stored to a tracking table.  A separate process is responsible for picking it up and processing it for Oracle.
