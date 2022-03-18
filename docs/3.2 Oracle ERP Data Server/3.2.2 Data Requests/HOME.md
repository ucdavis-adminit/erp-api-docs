# 3.2.2 Data Requests

### Data Requests: GL Chart Segment Validations

This data request is used to validate a set of GL chart segments a boundary system wants to ensure are correct before allowing them to be saved within their application or used on an action request.  The assumption is that this is a chartstring to which the boundary application will want to post.  Within the accounting segment definitions, certain values are flagged as summary-only values to be used for reporting only.  This API will return those strings as invalid.

It accepts the same data structure as is used on a number of action requests to submit distribution information.

#### Basic Use

1. Consumer prepares a payload containing the `GlSegmentInput` structure and submits to this endpoint.
2. Structural or format errors will be rejected immediately.  All input data elements must match the required patterns and lengths.  A failure here will result in a GraphQL error result.
3. API Server verifies each provided segment value against locally extracted Oracle ERP data.
4. The combination as a whole will be verified against a set of rules for validity.  This will not be all rules which could render the chartstring as invalid, but a subset of common validations.
5. If there are any validation failures, they will be returned in the `errors` structure of the returned payload.
6. A successful response will include a fully populated `GlSegmentInput` object and `glSegmentString` property with the string representation.

#### Operations

##### `glValidateChartSegments`

> Validates that the given set of GL chartstring segments are most likely valid for posting
> to the financial system general ledger.  Individual non-blank elements will be checked
> for current validity.  Certain combinations of attributes will be sanity checked.
>
> If validateCVRs is true, certain combinations of attributes will be sanity checked if the string format is accepted.
>
>
> This operation will return a fully populated set of segments, including defaults in
> both individual segment and full chartstring form.
>
> If the combination was previously known/used in the financial system, its unique ID will be included.


|                | Name           | Type                             | Notes                                   |
| -------------- | -------------- | -------------------------------- | --------------------------------------- |
| **Parameters** |                |                                  |                                         |
|                | `segments`     | `GlSegmentInput!`                |                                         |
|                | `validateCVRs` | `Boolean`                        | Whether to run the full CVR Validation. |
| **Returns**    |                |                                  |                                         |
|                |                | `GlValidateChartSegmentsOutput!` |                                         |

##### `glValidateChartstring`

> Validates that the given GL chartstring is most likely valid for posting
> to the financial system general ledger.  The input string format is strongly typed
> and will reject the call if not structured properly.  Please see the definition of the
> GlSegmentString for format information.
>
> If validateCVRs is true, certain combinations of attributes will be sanity checked if the string format is accepted.
>
> This operation will return the validation result and the segments as parsed out into their component fields.
>
> If the combination was previously known/used in the financial system, its unique ID will be included.

|                | Name            | Type                             | Notes                                   |
| -------------- | --------------- | -------------------------------- | --------------------------------------- |
| **Parameters** |                 |                                  |                                         |
|                | `segmentString` | `GlSegmentString!`               | Custom scalar to enforce pattern        |
|                | `validateCVRs`  | `Boolean`                        | Whether to run the full CVR Validation. |
| **Returns**    |                 |                                  |                                         |
|                |                 | `GlValidateChartSegmentsOutput!` |                                         |

```graphql
"""
Input structure for specifying GL segment values as separate fields.
"""
input GlSegmentInput {
  "Required: Entity to which to charge a transaction."
  entity:      ErpEntityCode!
  "Required: Funding source to which to charge a transaction."
  fund:        ErpFundCode!
  "Required: Financial department to which to charge a transaction."
  department:  ErpDepartmentCode!
  "Required: Nature of the transaction, expense, income, liability, etc..."
  account:     ErpAccountCode!
  "Required for Expenses: Functional purpose of the expense."
  purpose:     ErpPurposeCode
  "Optional: "
  project:     ErpProjectCode
  "Optional: "
  program:     ErpProgramCode
  "Optional: "
  activity:    ErpActivityCode
  # "Optional: Only used for transfers between business entities."
  # interEntity: ErpInterEntityCode
  "Unused: For future UCOP Reporting Requirements.  Always 000000."
  flex1:       ErpFlex1Code
  "Unused: For future UCOP Reporting Requirements.  Always 000000."
  flex2:       ErpFlex2Code
}
```

#### Returns

The operation returns an object per the definition below.  The `result` property will contain the overall validation result and any error messages encountered during validation.  If any errors occur during data parsing (formats/required values), that will be returned as a GraphQL error per the specification in a top-level `errors` property.

The operation will complete any missing segments with their defaults and return them populated in the `segments` property as well as the `completeChartstring` property.  Both of these values are structured such that (if all properties requested) they could be included as accounting line or distribution data in other operations.

The `codeCombinationId` is an informational property only.  If populated, it indicates that the validated combination of segment values was previously known to the financial system.  Validity still needs to be checked, as chartstrings can be disabled or expire.  However, segments which match an existing valid combination can not fail validation when posted to the financial system.

```graphql
type GlValidateChartSegmentsOutput {
  "Validation result and error messages, if any."
  result: ValidationResponse!
  "Fully populated object with the GL segments combination that was validated."
  segments: GlSegments!
  "Full chartstring with the GL segments combination that was validated."
  completeChartstring: GlSegmentString
  """
  The `codeCombinationId` is an informational property only.  If populated, it
  indicates that the validated combination of segment values was previously
  known to the financial system.  Validity still needs to be checked, as
  chartstrings can be disabled or expire.  However, segments which match an
  existing valid combination can not fail validation when posted to the
  financial system.
  """
  codeCombinationId: Int
}

"""
GL segment values as separate fields
"""
type GlSegments {
  "Required: Entity to which to charge a transaction."
  entity:      ErpEntityCode
  "Required: Funding source to which to charge a transaction."
  fund:        ErpFundCode
  "Required: Financial department to which to charge a transaction."
  department:  ErpDepartmentCode
  "Required for Expenses: Functional purpose of the expense."
  purpose:     ErpPurposeCode
  "Required: Nature of the transaction, expense, income, liability, etc..."
  account:     ErpAccountCode
  "Optional: "
  project:     ErpProjectCode
  "Optional: "
  program:     ErpProgramCode
  "Optional: "
  activity:    ErpActivityCode
}

"Contains the validation overall status and any error messages and the properties they belong to."
type ValidationResponse {
  "Whether the overall validation succeeded or failed."
  valid: Boolean!
  "Array of all errors found during validation.  The failed property is in the matching index in the `messageProperties` list."
  errorMessages: [String!]
  "Property names which failed validation.  May be blank if the validation applies to the entire payload or no particular property."
  messageProperties: [String!]
}

```

#### Validations

* **Non-Blank Segment Validation**
  * Entity exists and is active
  * Financial Department exists and is active
  * Fund exists and is active
  * Account exists and is active
  * Purpose exists and is active
  * Program exists and is active
  * Project exists and is active
  * Activity exists and is active
* **Segment Usability Checks**
  * Entity allows detail posting
  * Financial Department allows detail posting
  * Fund allows detail posting
  * Account allows detail posting
  * Purpose allows detail posting
  * Program allows detail posting
  * Project allows detail posting
  * Activity allows detail posting
  * Project must not be a PPM Project
    * Project must be a child of `GL0000000A`
* **Multi-Segment Checks**
  * That at least Entity, Fund, Financial Department, and Account have been provided.
  * If the given segment string already exists as an active record in the combination code table in Oracle.
    * (If a combination was previously marked as valid, the cross-validation rules are skipped in Oracle.)
* **CVR Rule Checks (if requested)**
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

#### Implementation Notes

* Format checks are unnecessary as the GraphQL scalar types will reject badly formatted data before resolver executes.
* Populate all missing segments in the return object with their default "zeroes" value.
* Combination code validity trumps almost all other checks.  The first check should be against the `gl_code_combination` table to see if it was previously known.  Use a datasource to take advantage of caching.  If present, use the validity information there and return the results.  There is no need to check other rules.
  * Exception: We must still check that the project attribute (if given) is not a PPM project.  Those GL strings might be "valid" but must not be used directly by feeding systems.
* If an unknown pre-existing combination, run the validations in roughly the order shown above.  But be sure to utilize as few round trips to the database as possible and use the SQLDataSource classes to utilize cached data.
* Do not stop if there are errors.  Continue to run all rules which can be run.  Try to avoid returning errors which are the result of prior errors.
* For each error, record the segment property which has the error in the `messageProperties` array in the same index as the error message.  If a multi-segment rule, use the one which caused the rule to fail.


<!--BREAK-->
### Data Requests: KFS Data Conversions

These operations are to support the transitional period when clients may be providing their old KFS strings (or utilizing stored KFS strings after the Oracle Financials go-live date.)  They will use the information built during the data conversion process to provide a probable mapping of the given information to the matching Oracle values.

_Data pulled from these services should be manually reviewed_, as it will be based on the automated conversion datasets which will not reflect manual corrections performed after go-live.


#### Basic Use

1. Consumer prepares a payload containing the required attributes and submits to this endpoint.
2. Structural or format errors will be rejected immediately.  All input data elements must match the required patterns and lengths.  A failure here will result in a GraphQL error result.
3. The server will return a GraphQL structured response containing an object of the `KfsConvertAccountOutput` type.  It will contain whether the account was found in the mapping table and the likely set of Oracle GL or POET Segments that represent the former KFS Account.


#### Operations

##### `kfsConvertAccount`

> Accepts a chart and account (and optionally a sub account and/or project code) which was converted as part of cutover and returns the cost center portion with matching GL or POET segments needed to record a transaction.  If no match is found when a sub account or project code is provided, the conversion will revert to only using the chart and account.  The attributes used for the returned converted values will be included in the response.

> In the case of a POET segment response, an array of tasks will be returned.  The data conversion mapping does not contain that information.  At cutover, there will be only one task per project.  However, additional tasks will be added as part of use after go-live.


|                | Name         | Type                       | Notes |
| -------------- | ------------ | -------------------------- | ----- |
| **Parameters** |              |                            |       |
|                | `chart`      | `KfsChartCode!`            |       |
|                | `account`    | `KfsAccountNumber!`        |       |
|                | `subAccount` | `KfsSubAccountNumber!`     |       |
|                | `kfsProject` | `KfsProjectCode!`          |       |
| **Returns**    |              |                            |       |
|                |              | `KfsConvertAccountOutput!` |       |

###### Returns

The operation returns an object per the definition below.  The `result` property will contain the overall validation result and any error messages encountered during validation.  If any errors occur during data parsing (formats/required values), that will be returned as a GraphQL error per the specification in a top-level `errors` property.

```graphql
type KfsConvertAccountOutput {
  "Whether the account was found in the mapping table"
  mappingFound:   Boolean!
  "The chart code used when mapping."
  chart:          KfsChartCode!
  "The account number used when mapping."
  account:        KfsAccountNumber!
  "The sub account number used when mapping.  Will be undefined if no mapping using the sub account was found."
  subAccount:     KfsSubAccountNumber
  "The KFS project code used when mapping.  Will be undefined if no mapping using the project code was found."
  kfsProject:     KfsProjectCode

  "The type of cost center this maps to in Oracle.  Determines which of glSegments and ppmSegments are populated."
  costCenterType: ErpCostCenterType
  "If a GL cost center, the segments which could be derived from the given chart-account."
  glSegments:     GlCostCenterSegments
  "If a POET cost center, the segments which could be derived from the given chart-account."
  ppmSegments:    PpmCostCenterSegments
}

"The type of cost center needed by Oracle to record a transaction."
enum ErpCostCenterType {
  "General Ledger Segments: Transaction may be posted directly to the general ledger"
  GL
  "POET Segments: Transaction belongs to a managed project and must be posted through the PPM sub-ledger."
  POET
}

"Cost-center components of Oracle GL Segments which can be derived from the KFS Chart-Account-Sub Account-Project."
type GlCostCenterSegments {
  entity:      ErpEntityCode!
  fund:        ErpFundCode!
  department:  ErpDepartmentCode!
  purpose:     ErpPurposeCode

  project:     ErpProjectCode
  program:     ErpProgramCode
  activity:    ErpActivityCode
}

"Cost-center components of the POET Segments which can be derived from the KFS Chart-Account-Sub Account-Project."
type PpmCostCenterSegments {
  project:       PpmProjectNumber!
  organization:  PpmExpenseOrganizationCode!
  task:          [PpmTaskName!]!
  award:         PpmAwardNumber
  fundingSource: PpmFundingSourceNumber
}
```

###### Example GraphQL Request

```graphql
query {
  kfsConvertAccount(chart:"3", account:"6620011") {
    mappingFound
    chart
    account
    costCenterType
    glSegments {
      entity
      fund
      department
      purpose
      project
      activity
      program
    }
    ppmSegments {
      project
      organization
      task
      award
      fundingSource
    }
  }
}
```

###### Example JSON GraphQL Payload

> Note: newlines are optional.  GraphQL allows any whitespace as a delimiter.

```json
{
    "operationName": null,
    "variables": {},
    "query": "{\n  kfsConvertAccount(chart: \"3\", account: \"6620011\") {\n    mappingFound\n    chart\n    account\n    costCenterType\n    glSegments {\n      entity\n      fund\n      department\n      purpose\n    }\n    ppmSegments {\n      project\n      organization\n      task\n    }\n  }\n}\n"
}
```

###### Example Response

**TODO**

###### Implementation Notes

* Format checks are unnecessary as the GraphQL scalar types will reject badly formatted data before resolver executes.
* Look up the account in the mapping table.
* Always put the requested chart/account into the response.
* If no record is found, set mappingFound to false and leave response properties undefined.
* Otherwise, set mappingFound to true and continue.
* **VERIFY:** If the erp_project is populated in the mapping table, it will be a POET cost center.  Populate the `costCenterType` as appropriate.
* Leave the segments object for the "other" type undefined.
* If GL:
  * Populate any fields for which we have non-blank, non-all-zero values in the mapping table.
* If POET:
  * Populate the project from the erp_project.
  * Populate the organization from the erp_fin_dept
  * Run a lookup on the project number in the local integration database to return an array of all the chargeable task names.
  * If a sponsored project, pull in the default award and funding source as per the logic in the PpmProject resolvers.

##### `kfsConvertOrgCode`

> Accepts a chart and org code which was converted as part of cutover and returns the financial department(s) to which it was mapped.

|                | Name    | Type                   | Notes |
| -------------- | ------- | ---------------------- | ----- |
| **Parameters** |         |                        |       |
|                | `chart` | `KfsChartCode!`        |       |
|                | `org`   | `KfsOrgCode!`          |       |
| **Returns**    |         |                        |       |
|                |         | `KfsConvertOrgOutput!` |       |

###### Returns

The operation returns an object per the definition below.  The `result` property will contain the overall validation result and any error messages encountered during validation.  If any errors occur during data parsing (formats/required values), that will be returned as a GraphQL error per the specification in a top-level `errors` property.

```graphql
"Return type when requesting conversion of a KFS Organization to the Oracle financial department."
type KfsConvertOrgOutput {
  "Whether the account was found in the mapping table"
  orgFound:       Boolean!
  chart:          KfsChartCode!
  org:            KfsOrgCode!
  "The mapped department code."
  departmentCode: ErpDepartmentCode
  "The mapped department object if more information about the department is needed."
  department:     ErpFinancialDepartment
}
```

###### Example GraphQL Request

```graphql
query {
  kfsConvertOrgCode(chart:"3", org: "ADIT") {
    orgFound
    chart
    org
    departmentCode
    department {
      name
      enabled
      summaryOnly
    }
  }
}
```

###### Example JSON GraphQL Payload

> Note: newlines are optional.  GraphQL allows any whitespace as a delimiter.

```json
{
    "operationName": null,
    "variables": {},
    "query": "{\n  kfsConvertOrgCode(chart: \"3\", org: \"ADIT\") {\n    orgFound\n    chart\n    org\n    departmentCode\n    department {\n      name\n      enabled\n      summaryOnly\n    }\n  }\n}\n"
}
```

###### Example Response

**TODO**

###### Implementation Notes

* Format checks are unnecessary as the GraphQL scalar types will reject badly formatted data before resolver executes.
* Look up the org in the mapping table and join to the erp_fin_dept table.  (No results will be returned if the destination department does not exist in oracle.)
* Always put the requested chart/org into the response.
* If no record is found, set orgFound to false and leave response properties undefined.
* Otherwise, set orgFound to true and continue.
* Populate the department code and department properties.


### Data Requests: PPM Costing Segment Validations

This data request is used to validate a set of POET(AF) segments a boundary system needs to ensure are correct before allowing them to be saved within their application or used on an action request.  The assumption is that this is a set of segments to which the boundary application will want to post.  Within the segment definitions, certain values are not eligible to receive costs.  This API will return those strings as invalid.

It accepts the same data structure as is used on a number of action requests to submit distribution information.

#### Basic Use

1. Consumer prepares a payload containing the `PpmSegmentInput` structure and submits to this endpoint.
2. Structural or format errors will be rejected immediately.  All input data elements must match the required patterns and lengths.  A failure here will result in a GraphQL error result.
3. API Server verifies each provided segment value against locally extracted Oracle ERP data.
4. The combination as a whole will be verified against a set of rules for validity.  This will not be all rules which could render the chartstring as invalid, but a subset of common validations.
5. If there are any validation failures, they will be returned in the `errors` structure of the returned payload.
6. A successful response will include a fully populated `PpmSegmentInput` object.

#### Operations

##### `ppmSegmentsValidate`

> Validates that the given set of PPM segments are most likely valid for posting
> to the Oracle ERP PPM Module sub-ledger.  Individual non-blank elements will be checked
> for current validity.

> This operation will return a fully populated set of segments.

|                | Name             | Type                         | Notes |
| -------------- | ---------------- | ---------------------------- | ----- |
| **Parameters** |                  |                              |       |
|                | `segments`       | `PpmSegmentInput!`           |       |
|                | `accountingDate` | `LocalDate`                  |       |
| **Returns**    |                  |                              |       |
|                |                  | `PpmSegmentsValidateOutput!` |       |

```graphql
"""
Input structure for specifying POET/PPM segment values.
"""
input PpmSegmentInput {
  "Required: Managed Project Number"
  project:          PpmProjectNumber!
  "Required: Task ID.  Must belong to Project and be a chargeable task"
  task:             PpmTaskName!
  "Required: Organization for which the expense is being incurred.  Aligns with the GL Financial Department segment."
  organization:     PpmExpenseOrganizationCode!
  "Required: Type of expense being charged to the project.  Aligns with the GL Account segment."
  expenditureType:  PpmExpenseTypeCode!
  """
  Award for Sponsored projects only

  **API Users, do not provide.  The valid value will be derived from the project if necessary.**
  """
  award:            PpmAwardNumber
  """
  Award funding source for Sponsored projects only

  **API Users, do not provide.  The valid value will be derived from the project if necessary.**
  """
  fundingSource:    PpmFundingSourceNumber
}
```

#### Returns

The operation returns an object per the definition below.

The `result` property will contain the overall validation result and any error messages encountered during validation.  If any errors occur during data parsing (formats/required values), that will be returned as a GraphQL error per the specification in a top-level `errors` property.

The operation will complete any missing segments with their defaults and return them populated in the `segments` property.  This property is structured such that they could be included as accounting line or distribution data in other operations.

```graphql
type PpmSegmentsValidateOutput {
  "Validation result and error messages, if any."
  result: ValidationResponse!
  "Fully populated object with the PPM segments combination that was validated."
  segments: PpmSegments!
}

"""
POET/PPM segment values.
"""
type PpmSegments {
  "Required: Managed Project Number"
  project:          PpmProjectNumber!
  "Required: Task ID.  Must belong to Project and be a chargeable task"
  task:             PpmTaskName!
  "Required: Organization for which the expense is being incurred.  Aligns with the GL Financial Department segment."
  organization:     PpmExpenseOrganizationCode!
  "Required: Type of expense being charged to the project.  Aligns with the GL Account segment."
  expenditureType:  PpmExpenseTypeCode!
  """
  Award for Sponsored projects only
  """
  award:            PpmAwardNumber
  """
  Award funding source for Sponsored projects only
  """
  fundingSource:    PpmFundingSourceNumber
}

"Contains the validation overall status and any error messages and the properties they belong to."
type ValidationResponse {
  "Whether the overall validation succeeded or failed."
  valid: Boolean!
  "Array of all errors found during validation.  The failed property is in the matching index in the `messageProperties` list."
  errorMessages: [String!]
  "Property names which failed validation.  May be blank if the validation applies to the entire payload or no particular property."
  messageProperties: [String!]
}

```

#### Validations

* For each validation below, the given value must exist.  In the case where an item only exists within the context of another (E.g., Project -> Task), then the value must exist within the scope of its parent.
* Unlike GL segments, there is no default (all zeroes) value for any PPM segment.
* Verify that there is a complete set of required PPM segments (project, task, organization, expenditure type)
* **Validate Project**
  * _Project is not Active_
    * `projectStatus` = `ACTIVE`
  * _Costs can not be assigned to template projects_
    * `templateProject` = false
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
  * Attempt a full match of the given value against the expense type table.  If that fails, and the string is longer than 6 characters, attempt a lookup against the first 6 characters of the expense type.
  * Populate the output with the full name of the expense type.  (This should be the GL account code plus its name.)
  * _Expenditure Type is not active_
    * is active
    * is not outside of start and end dates (`expenditureTypeStartDate` - `expenditureTypeEndDate`)
* **Validate Expenditure Organization**
  * Attempt a full match of the given value against the organization table.  If that fails, and the string is longer than 7 characters, attempt a lookup against the first 7 characters of the organization name.
  * Accounting date falls within expense org dates (`effectiveStartDate` and `effectiveEndDate`)
  * Populate the output with the full name of the organization.  (This should be the financial department code plus the name.)
* **Award and Funding Source**
  * If `sponsoredProject` is false, then no award or funding source may be provided.  _Do not provide an award or funding source except on sponsored projects._
  * Otherwise verify the values if present at that they are linked to the given project.
  * **Validate Award**
    * If provided, the award must be linked to the project.  If not, populate the output with the default award.
    * The accounting date must be between the start date and `closeDate` of the award.
  * **Validate Funding Source**
    * If provided, the award must be linked to the project.  If not, populate the output with the default award.
    * The accounting date must be between the `fundingSourceFromDate` and `fundingSourceToDate` of the funding source.

#### Implementation Notes

* Format checks are unnecessary as the GraphQL scalar types will reject badly formatted data before our resolver executes.
* Do not stop if there are errors.  Continue to run all rules which can be run.  Try to avoid returning errors which are the result of prior errors.
* For each error, record the segment property which has the error in the `messageProperties` array in the same index as the error message.  If a multi-segment rule, use the one which caused the rule to fail.
