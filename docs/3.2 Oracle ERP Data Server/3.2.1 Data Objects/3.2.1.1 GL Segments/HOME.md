# 3.2.1.1 GL Segments

<!--BREAK-->
### Data Object: ErpEntity

The Entity segment identifies the major UC system organizational units. These units generally require their own complete, separately audited financial statements to comply with external, regulatory reporting requirements (e.g., external audits, tax reporting), which cannot achieve compliance by using the audited financial statements issued by the Office of the President. Entity, however, will also provide high level management and operational reports.

The balancing segment designation in Oracle Financials Cloud allows for net position (e.g., fund balance) to be calculated at the Entity level.

Entities at all levels have unique reporting and/or external auditing needs that can only be met with an Entity level designation (e.g., UC Davis Health).

**FAU Value Comparison:**
The Entity segment most closely aligns with the KFS Chart (e.g. 3, H, L, P).

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `ERP_ENTITY` (view)
  * Support Tables:
    * `VALUE_SET_TYPED_VALUES_PVO`
    * `VALUE_SET_TYPED_VALUES_TL_PVO`
    * `VALUE_SET_VALUES_PVO`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetTypedValuesPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetTypedValuesTLPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetValuesPVO
    * View Object: FscmTopModelAM.FinExtractAM.GlBiccExtractAM.SegmentValueHierarchyExtractPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.FndTreeAndVersionVO
  * Underlying Database Objects:
    * FND_VS_VALUES_B
    * GL_SEG_VAL_HIER_CF
    * FND_VS_VALUE_SETS
    * FND_VS_VALUES_TL
    * FND_TREE_AND_VERSION_VO

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | ErpEntityCode!            |       Y        |        Y        |               | Unique identifier of an ErpEntity |
| id                 | Long!                     |                |                 |               | Internal numeric identifier of an ErpEntity |
| name               | NonEmptyTrimmedString240! |                |        Y        |               | Descriptive name of an ErpEntity |
| enabled            | Boolean!                  |                |        Y        |               | Whether this ErpEntity is presently enabled for use. |
| startDate          | LocalDate                 |                |                 |               | The date from when the value is available for use. |
| endDate            | LocalDate                 |                |                 |               | The date till which the value is available for use. |
| summaryOnly        | Boolean!                  |                |        Y        |               | Indicates that the ErpEntity is only used for summarization and may not be used on GL Entries |
| securityEnabled    | Boolean!                  |                |                 |               | Indicates that data linked to this ErpEntity is protected by row-level security. |
| sortOrder          | PositiveInt               |                |                 |               | The number that indicates the order in which the values appear in the list of values. |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               | Timestamp this record was last updated in the financial system. |
| lastUpdateUserId   | ErpUserId                 |                |                 |               | User ID of the person who last updated this record. |
| parentCode         | ErpEntityCode             |                |        Y        |               | Code of the ErpEntity which is the immediate parent of this one.<br/>Will be undefined if the ErpEntity has no parent. |
| parent             | ErpEntity                 |                |                 |               | The ErpEntity which is the immediate parent of this one.<br/>Will be undefined if the ErpEntity has no parent. |
| children           | [ErpEntity!]              |                |                 |               | The ErpEntitys which are the immediate children of this one.<br/>Will be an empty list if the ErpEntity has no children. |
| hierarchyDepth     | Int                       |                |        Y        |               | Level below the top for a ErpEntity that is part of a reporting hierarchy. |
| hierarchyLevel     | String                    |                |        Y        |               | Reporting Level designation based on the hierachy depth. |
| eligibleForUse     | Boolean!                  |                |                 |               | Returns whether this ErpEntity is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the ErpEntity must:<br/>- Be enabled<br/>- Not be summaryOnly<br/>- Have a startDate and endDate range which includes the given accountingDate |

* `parent` : `ErpEntity`
  * The ErpEntity which is the immediate parent of this one.<br/>Will be undefined if the ErpEntity has no parent.
* `eligibleForUse` : `Boolean!`
  * Returns whether this ErpEntity is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the ErpEntity must:<br/>- Be enabled<br/>- Not be summaryOnly<br/>- Have a startDate and endDate range which includes the given accountingDate
  * Arguments:
    * `accountingDate` : `LocalDate`

##### Linked Data Objects

(None)

#### Query Operations

##### `erpEntity`

> Get a single ErpEntity by code.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `ErpEntity`

##### `erpEntityAll`

> Get all currently valid ErpEntity objects.

* **Parameters**
  * `sort : [String!]`
* **Returns**
  * `[ErpEntity!]!`

##### `erpEntityChildren`

> Get items under the given ErpEntity in the hierarchy.
> Returns undefined if the parent does not exist.
> Returns an empty list if the given record has no children.

* **Parameters**
  * `code : String!`
* **Returns**
  * `[ErpEntity!]`

##### `erpEntitySearch`

> Search for ErpEntity objects by multiple properties.
> See
> See the ErpEntityFilterInput type for options.

* **Parameters**
  * `filter : ErpEntityFilterInput!`
* **Returns**
  * `ErpEntitySearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpFund

Funds provide a method of tracking funding resources whose use is limited by donors, granting agencies, regulations and other external individuals or entities, or by governing boards. A Fund is maintained for each specific funding type (e.g., Unrestricted, Restricted-Expendable, Capital) which supports the compilation of GASB audited financial statements.

The balancing segment designation in Oracle Financials Cloud allows for net position (e.g., fund balance) to be calculated at the Fund level.

In most cases, Fund activity will be presented in the general ledger in summary and the Fund values will be shared amongst Financial Departments. For example, all Financial Departments will share one Restricted Expendable Federal Contracts fund. The detailed transactional information related to each federally sponsored project within this fund will be tracked using the PPM module.

**FAU Value Comparison:**
The Fund segment most closely aligns with the fund attribute of the KFS Account.

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `ERP_FUND` (view)
  * Support Tables:
    * `VALUE_SET_TYPED_VALUES_PVO`
    * `VALUE_SET_TYPED_VALUES_TL_PVO`
    * `VALUE_SET_VALUES_PVO`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetTypedValuesPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetTypedValuesTLPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetValuesPVO
    * View Object: FscmTopModelAM.FinExtractAM.GlBiccExtractAM.SegmentValueHierarchyExtractPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.FndTreeAndVersionVO
  * Underlying Database Objects:
    * FND_VS_VALUES_B
    * GL_SEG_VAL_HIER_CF
    * FND_VS_VALUE_SETS
    * FND_VS_VALUES_TL
    * FND_TREE_AND_VERSION_VO

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes                                                                                                                                                                                                                                                                                                                                                  |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| code               | ErpFundCode!              |       Y        |        Y        |               | Unique identifier of an ErpFund                                                                                                                                                                                                                                                                                                                        |
| id                 | Long!                     |                |                 |               | Internal numeric identifier of an ErpFund                                                                                                                                                                                                                                                                                                              |
| name               | NonEmptyTrimmedString240! |                |        Y        |               | Descriptive name of an ErpFund                                                                                                                                                                                                                                                                                                                         |
| enabled            | Boolean!                  |                |        Y        |               | Whether this ErpFund is presently enabled for use.                                                                                                                                                                                                                                                                                                     |
| startDate          | LocalDate                 |                |                 |               | The date from when the value is available for use.                                                                                                                                                                                                                                                                                                     |
| endDate            | LocalDate                 |                |                 |               | The date till which the value is available for use.                                                                                                                                                                                                                                                                                                    |
| summaryOnly        | Boolean!                  |                |        Y        |               | Indicates that the ErpFund is only used for summarization and may not be used on GL Entries                                                                                                                                                                                                                                                            |
| securityEnabled    | Boolean!                  |                |                 |               | Indicates that data linked to this ErpFund is protected by row-level security.                                                                                                                                                                                                                                                                         |
| sortOrder          | PositiveInt               |                |                 |               | The number that indicates the order in which the values appear in the list of values.                                                                                                                                                                                                                                                                  |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               | Timestamp this record was last updated in the financial system.                                                                                                                                                                                                                                                                                        |
| lastUpdateUserId   | ErpUserId                 |                |                 |               | User ID of the person who last updated this record.                                                                                                                                                                                                                                                                                                    |
| parentCode         | ErpFundCode               |                |                 |               | Code of the ErpFund which is the immediate parent of this one.<br/>Will be undefined if the ErpFund has no parent.                                                                                                                                                                                                                                     |
| parent             | ErpFund                   |                |                 |               | The ErpFund which is the immediate parent of this one.<br/>Will be undefined if the ErpFund has no parent.                                                                                                                                                                                                                                             |
| children           | [ErpFund!]!               |                |                 |               | The ErpFunds which are the immediate children of this one.<br/>Will be an empty list if the ErpFund has no children.                                                                                                                                                                                                                                   |
| hierarchyDepth     | Int                       |                |        Y        |               | Level below the top for a ErpFund that is part of a reporting hierarchy.                                                                                                                                                                                                                                                                               |
| hierarchyLevel     | String                    |                |        Y        |               | Reporting Level designation based on the hierachy depth.                                                                                                                                                                                                                                                                                               |
| budgeted           | Boolean                   |                |        Y        |               | Whether this fund is used for budgeting purposes.                                                                                                                                                                                                                                                                                                      |
| eligibleForUse     | Boolean!                  |                |                 |               | Returns whether this ErpFund is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the ErpFund must:<br/>- Be enabled<br/>- Not be summaryOnly<br/>- Have a startDate and endDate range which includes the given accountingDate |

* `parent` : `ErpFund`
  * The ErpFund which is the immediate parent of this one.<br/>Will be undefined if the ErpFund has no parent.
* `eligibleForUse` : `Boolean!`
  * Returns whether this ErpFund is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the ErpFund must:<br/>- Be enabled<br/>- Not be summaryOnly<br/>- Have a startDate and endDate range which includes the given accountingDate
  * Arguments:
    * `accountingDate` : `LocalDate`

##### Linked Data Objects

(None)

#### Query Operations

##### `erpFund`

> Get a single ErpFund by code.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `ErpFund`

##### `erpFundChildren`

> Get items under the given ErpFund in the hierarchy.
> Returns undefined if the parent does not exist.
> Returns an empty list if the given record has no children.

* **Parameters**
  * `code : String!`
* **Returns**
  * `[ErpFund!]`

##### `erpFundSearch`

> Search for ErpFund objects by multiple properties.
> See
> See the ErpFundFilterInput type for options.

* **Parameters**
  * `filter : ErpFundFilterInput!`
* **Returns**
  * `ErpFundSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpFinancialDepartment

Financial Department is often known as the "cost center" or "department". This field records, tracks and retains the Financial Department's financial transactions. There are several levels of Financial Departments within the CoA hierarchy. The mid-level hierarchy aligns with the UCPath HR Departments.

**Financial Departments have:**
- An ongoing business objective and operational function with no planned end date (enabling historical trend analysis + long-range planning)

- Identifiable, permanently funded employees and generally an allocation of physical space

**FAU Value Comparison:**
Due to significant variations in departments' financial structure in KFS, it is not possible to align the Financial Department segment with  specific KFS values.

**Access Roles: erp:reader-refdata**

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `ERP_FIN_DEPT` (view)
  * Support Tables:
    * `VALUE_SET_TYPED_VALUES_PVO`
    * `VALUE_SET_TYPED_VALUES_TL_PVO`
    * `VALUE_SET_VALUES_PVO`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetTypedValuesPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetTypedValuesTLPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetValuesPVO
    * View Object: FscmTopModelAM.FinExtractAM.GlBiccExtractAM.SegmentValueHierarchyExtractPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.FndTreeAndVersionVO
  * Underlying Database Objects:
    * FND_VS_VALUES_B
    * GL_SEG_VAL_HIER_CF
    * FND_VS_VALUE_SETS
    * FND_VS_VALUES_TL
    * FND_TREE_AND_VERSION_VO

##### Properties

| Property Name      | Data Type                   | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | --------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | ErpDepartmentCode!          |       Y        |        Y        |               | Unique identifier of an ErpFinancialDepartment |
| id                 | Long!                       |                |                 |               | Internal numeric identifier of an ErpFinancialDepartment |
| name               | NonEmptyTrimmedString240!   |                |        Y        |               | Descriptive name of an ErpFinancialDepartment |
| enabled            | Boolean!                    |                |        Y        |               | Whether this ErpFinancialDepartment is presently enabled for use. |
| startDate          | LocalDate                   |                |                 |               | The date from when the value is available for use. |
| endDate            | LocalDate                   |                |                 |               | The date till which the value is available for use. |
| summaryOnly        | Boolean!                    |                |        Y        |               | Indicates that the ErpFinancialDepartment is only used for summarization and may not be used on GL Entries |
| securityEnabled    | Boolean!                    |                |                 |               | Indicates that data linked to this ErpFinancialDepartment is protected by row-level security. |
| sortOrder          | PositiveInt                 |                |                 |               | The number that indicates the order in which the values appear in the list of values. |
| lastUpdateDateTime | DateTime!                   |                |        Y        |               | Timestamp this record was last updated in the financial system. |
| lastUpdateUserId   | ErpUserId                   |                |                 |               | User ID of the person who last updated this record. |
| allowedEntityCodes | [ErpEntityCode!]!           |                |                 |               | List of all entity codes with which this department may be used. |
| approvers          | [ErpDepartmentalApprover!]! |                |                 |               | List of all approvers linked to this department.  To return only a specific approver type, use the approverTypeName argument for this field. |
| parentCode         | ErpDepartmentCode           |                |                 |               | Code of the ErpFinancialDepartment which is the immediate parent of this one.<br/>Will be undefined if the ErpFinancialDepartment has no parent. |
| parent             | ErpFinancialDepartment      |                |                 |               | The ErpFinancialDepartment which is the immediate parent of this one.<br/>Will be undefined if the ErpFinancialDepartment has no parent. |
| children           | [ErpFinancialDepartment!]!  |                |                 |               | The ErpFinancialDepartments which are the immediate children of this one.<br/>Will be an empty list if the ErpFinancialDepartment has no children. |
| hierarchyDepth     | Int                         |                |        Y        |               | Level below the top for a ErpFinancialDepartment that is part of a reporting hierarchy. |
| hierarchyLevel     | String                      |                |        Y        |               | Reporting Level designation based on the hierarchy depth. |
| departmentType     | ErpDepartmentTypeCode       |                |                 |               | Reporting Level designation based on the hierarchy depth. |
| eligibleForUse     | Boolean!                    |                |                 |               | Returns whether this ErpFinancialDepartment is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the ErpFinancialDepartment must:<br/>- Be enabled<br/>- Not be summaryOnly<br/>- Have a startDate and endDate range which includes the given accountingDate |

* `approvers` : `[ErpDepartmentalApprover!]!`
  * List of all approvers linked to this department.  To return only a specific approver type, use the approverTypeName argument for this field.
  * Arguments:
    * `approverTypeName` : `NonEmptyTrimmedString50`
  * Description of `ErpDepartmentalApprover`:
    * Represents an approver from the Oracle Role-Based Security module.  Values here have been extracted<br/>from advanced security table and formatted for API use.
* `parent` : `ErpFinancialDepartment`
  * The ErpFinancialDepartment which is the immediate parent of this one.<br/>Will be undefined if the ErpFinancialDepartment has no parent.
* `eligibleForUse` : `Boolean!`
  * Returns whether this ErpFinancialDepartment is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the ErpFinancialDepartment must:<br/>- Be enabled<br/>- Not be summaryOnly<br/>- Have a startDate and endDate range which includes the given accountingDate
  * Arguments:
    * `accountingDate` : `LocalDate`

##### Linked Data Objects

(None)

#### Query Operations

##### `erpFinancialDepartment`

> Get a single ErpFinancialDepartment by code.  Returns undefined if does not exist.

* **Parameters**
  * `code : String!`
* **Returns**
  * `ErpFinancialDepartment`

##### `erpFinancialDepartmentAll`

> Get all currently enabled ErpFinancialDepartment objects.

* **Parameters**
  * `sort : [String!]`
* **Returns**
  * `[ErpFinancialDepartment!]!`

##### `erpFinancialDepartmentByEntity`

> Get ErpFinancialDepartment records which may be used with the given entity code.

* **Parameters**
  * `entity : ErpEntityCode!`
* **Returns**
  * `[ErpFinancialDepartment!]!`

##### `erpFinancialDepartmentChildren`

> Get items under the given ErpFinancialDepartment in the segment hierarchy.
> Returns undefined if the parent does not exist.
> Returns an empty list if the given record has no children.

* **Parameters**
  * `code : String! - The code of the parent.`
* **Returns**
  * `[ErpFinancialDepartment!]`

##### `erpFinancialDepartmentSearch`

> Search for ErpFinancialDepartment objects by multiple properties.
> See
> See the ErpFinancialDepartmentFilterInput type for options.

* **Parameters**
  * `filter : ErpFinancialDepartmentFilterInput!`
* **Returns**
  * `ErpFinancialDepartmentSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpAccount

For clarity between the CoA Account segment and the current KFS Account, we will refer to the CoA segment as "Natural Account", a commonly used accounting term.

The (Natural) Account segment categorizes the nature of the transaction being recorded. The transaction is either revenue-producing, an expenditure, an asset that is owned, or a liability that is owed. Additionally, Account maintains Net Position for Entities and Funds.

(Natural) Account values will generally be shared across Financial Departments to provide consistency in operational and management reporting for UC Davis.

**FAU Value Comparison:**

The (Natural) Account segment most closely aligns with the KFS Object Code.

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `ERP_ACCOUNT` (view)
  * Support Tables:
    * `VALUE_SET_TYPED_VALUES_PVO`
    * `VALUE_SET_TYPED_VALUES_TL_PVO`
    * `VALUE_SET_VALUES_PVO`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetTypedValuesPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetTypedValuesTLPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetValuesPVO
    * View Object: FscmTopModelAM.FinExtractAM.GlBiccExtractAM.SegmentValueHierarchyExtractPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.FndTreeAndVersionVO
  * Underlying Database Objects:
    * FND_VS_VALUES_B
    * GL_SEG_VAL_HIER_CF
    * FND_VS_VALUE_SETS
    * FND_VS_VALUES_TL
    * FND_TREE_AND_VERSION_VO

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | ErpAccountCode!           |       Y        |        Y        |               | Unique identifier of an ErpAccount |
| id                 | Long!                     |                |                 |               | Internal numeric identifier of an ErpAccount |
| name               | NonEmptyTrimmedString240! |                |        Y        |               | Descriptive name of an ErpAccount |
| enabled            | Boolean!                  |                |        Y        |               | Whether this ErpAccount is presently enabled for use. |
| startDate          | LocalDate                 |                |                 |               | The date from when the value is available for use. |
| endDate            | LocalDate                 |                |                 |               | The date till which the value is available for use. |
| summaryOnly        | Boolean!                  |                |        Y        |               | Indicates that the ErpAccount is only used for summarization and may not be used on GL Entries |
| securityEnabled    | Boolean!                  |                |                 |               | Indicates that data linked to this ErpAccount is protected by row-level security. |
| sortOrder          | PositiveInt               |                |                 |               | The number that indicates the order in which the values appear in the list of values. |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               | Timestamp this record was last updated in the financial system. |
| lastUpdateUserId   | ErpUserId                 |                |                 |               | User ID of the person who last updated this record. |
| parentCode         | ErpAccountCode            |                |                 |               | Code of the ErpAccount which is the immediate parent of this one.<br/>Will be undefined if the ErpAccount has no parent. |
| parent             | ErpAccount                |                |                 |               | The ErpAccount which is the immediate parent of this one.<br/>Will be undefined if the ErpAccount has no parent. |
| children           | [ErpAccount!]             |                |                 |               | The ErpAccounts which are the immediate children of this one.<br/>Will be an empty list if the ErpAccount has no children. |
| hierarchyDepth     | Int                       |                |        Y        |               | Level below the top for a ErpAccount that is part of a reporting hierarchy. |
| hierarchyLevel     | String                    |                |        Y        |               | Reporting Level designation based on the hierarchy depth. |
| ppmAllowed         | Boolean!                  |                |                 |               | If true, this natural account is also a PPM Expenditure Type and may be used when creating expenses against PPM-managed projects. |
| eligibleForUse     | Boolean!                  |                |                 |               | Returns whether this ErpAccount is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the ErpAccount must:<br/>- Be enabled<br/>- Not be summaryOnly<br/>- Have a startDate and endDate range which includes the given accountingDate |
| purposeRequired    | Boolean!                  |                |                 |               | DEPRECATED - NOT IMPLEMENTED |

* `parent` : `ErpAccount`
  * The ErpAccount which is the immediate parent of this one.<br/>Will be undefined if the ErpAccount has no parent.
* `eligibleForUse` : `Boolean!`
  * Returns whether this ErpAccount is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the ErpAccount must:<br/>- Be enabled<br/>- Not be summaryOnly<br/>- Have a startDate and endDate range which includes the given accountingDate
  * Arguments:
    * `accountingDate` : `LocalDate`

##### Linked Data Objects

(None)

#### Query Operations

##### `erpAccount`

> Get a single ErpAccount by code.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `ErpAccount`

##### `erpAccountAll`

> Get all currently valid ErpAccount objects.

* **Parameters**
  * `sort : [String!]`
* **Returns**
  * `[ErpAccount!]!`

##### `erpAccountChildren`

> Get items under the given ErpAccount in the hierarchy.
> Returns undefined if the parent does not exist.
> Returns an empty list if the given record has no children.

* **Parameters**
  * `code : String!`
* **Returns**
  * `[ErpAccount!]`

##### `erpAccountSearch`

> Search for ErpAccount objects by multiple properties.
> See the ErpAccountFilterInput type for options.

* **Parameters**
  * `filter : ErpAccountFilterInput!`
* **Returns**
  * `ErpAccountSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpPurpose

The Purpose segment tracks the purpose of the transaction, such as NACUBO-defined functional expense classification and mission.

NACUBO classification data is utilized for far-reaching external reporting (e.g., institution ranking). This field is also essential for compliance with federal cost principles and financial statement reporting requiring expenditures be displayed by functional class.

**FAU Value Comparison:**

The Purpose segment most closely aligns with the HEFC (Higher Ed. Function Code) attribute of the KFS Account.

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `ERP_PURPOSE` (view)
  * Support Tables:
    * `VALUE_SET_TYPED_VALUES_PVO`
    * `VALUE_SET_TYPED_VALUES_TL_PVO`
    * `VALUE_SET_VALUES_PVO`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetTypedValuesPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetTypedValuesTLPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetValuesPVO
    * View Object: FscmTopModelAM.FinExtractAM.GlBiccExtractAM.SegmentValueHierarchyExtractPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.FndTreeAndVersionVO
  * Underlying Database Objects:
    * FND_VS_VALUES_B
    * GL_SEG_VAL_HIER_CF
    * FND_VS_VALUE_SETS
    * FND_VS_VALUES_TL
    * FND_TREE_AND_VERSION_VO

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | ErpPurposeCode!           |       Y        |        Y        |               | Unique identifier of an ErpPurpose |
| id                 | Long!                     |                |                 |               | Internal numeric identifier of an ErpPurpose |
| name               | NonEmptyTrimmedString240! |                |        Y        |               | Descriptive name of an ErpPurpose |
| enabled            | Boolean!                  |                |        Y        |               | Whether this ErpPurpose is presently enabled for use. |
| startDate          | LocalDate                 |                |                 |               | The date from when the value is available for use. |
| endDate            | LocalDate                 |                |                 |               | The date till which the value is available for use. |
| summaryOnly        | Boolean!                  |                |        Y        |               | Indicates that the ErpPurpose is only used for summarization and may not be used on GL Entries |
| securityEnabled    | Boolean!                  |                |                 |               | Indicates that data linked to this ErpPurpose is protected by row-level security. |
| sortOrder          | PositiveInt               |                |                 |               | The number that indicates the order in which the values appear in the list of values. |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               | Timestamp this record was last updated in the financial system. |
| lastUpdateUserId   | ErpUserId                 |                |                 |               | User ID of the person who last updated this record. |
| parentCode         | ErpPurposeCode            |                |                 |               | Code of the ErpPurpose which is the immediate parent of this one.<br/>Will be undefined if the ErpPurpose has no parent. |
| parent             | ErpPurpose                |                |                 |               | The ErpPurpose which is the immediate parent of this one.<br/>Will be undefined if the ErpPurpose has no parent. |
| children           | [ErpPurpose!]             |                |                 |               | The ErpPurposes which are the immediate children of this one.<br/>Will be an empty list if the ErpPurpose has no children. |
| hierarchyDepth     | Int                       |                |        Y        |               | Level below the top for a ErpPurpose that is part of a reporting hierarchy. |
| hierarchyLevel     | String                    |                |        Y        |               | Reporting Level designation based on the hierachy depth. |
| eligibleForUse     | Boolean!                  |                |                 |               | Returns whether this ErpPurpose is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the ErpPurpose must:<br/>- Be enabled<br/>- Not be summaryOnly<br/>- Have a startDate and endDate range which includes the given accountingDate |

* `parent` : `ErpPurpose`
  * The ErpPurpose which is the immediate parent of this one.<br/>Will be undefined if the ErpPurpose has no parent.
* `eligibleForUse` : `Boolean!`
  * Returns whether this ErpPurpose is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the ErpPurpose must:<br/>- Be enabled<br/>- Not be summaryOnly<br/>- Have a startDate and endDate range which includes the given accountingDate
  * Arguments:
    * `accountingDate` : `LocalDate`

##### Linked Data Objects

(None)

#### Query Operations

##### `erpPurpose`

> Get a single ErpPurpose by code.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `ErpPurpose`

##### `erpPurposeAll`

> Get all currently valid ErpPurpose objects.

* **Parameters**
  * `sort : [String!]`
* **Returns**
  * `[ErpPurpose!]!`

##### `erpPurposeChildren`

> Get items under the given ErpPurpose in the hierarchy.
> Returns undefined if the parent does not exist.
> Returns an empty list if the given record has no children.

* **Parameters**
  * `code : String!`
* **Returns**
  * `[ErpPurpose!]`

##### `erpPurposeSearch`

> Search for ErpPurpose objects by multiple properties.
> See
> See the ErpPurposeFilterInput type for options.

* **Parameters**
  * `filter : ErpPurposeFilterInput!`
* **Returns**
  * `ErpPurposeSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpProgram

The Program segment records revenue and expense transactions associated with a formal, ongoing system-wide or cross-campus/location academic or administrative activity that demonstrates UC Davis' mission of teaching, research, public service and patient care.

**Expanded Definition and Criteria:**
There are two categories of Programs:
1. Those pre-defined and sanctioned by UCOP, of which values are predesignated
2. Those endorsed and acknowledged by UC Davis Leadership

Programs have permanence, are a going-concern, and are considered significant due to their prominence and impact.

In general, Programs have allocated, not dedicated, FTEs and cannot be identified through a single Financial Department, Project Code or Activity Code.

Program values are determined by both UCOP and UC Davis.

**Examples:**

* UCOP System-wide examples:
  * Ag Experiment Station (AES)
  * California State Summer School for Mathematics & Science (COSMOS)
  * UC Sacramento
* UC Davis examples (possible programs):
  * Self-Supporting Degree Programs
  * Student Success Programs
  * Graduate Groups
  * Campus-wide Programs
  * Campus Ready
  * Healthy Davis Together
  * International/ Study Abroad Programs
  * Housing Services Programs

**FAU Value Comparison:**
Due to significant variations in how departments track programs in KFS, it is not possible to align the Program segment with a KFS value.

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `ERP_PROGRAM` (view)
  * Support Tables:
    * `VALUE_SET_TYPED_VALUES_PVO`
    * `VALUE_SET_TYPED_VALUES_TL_PVO`
    * `VALUE_SET_VALUES_PVO`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetTypedValuesPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetTypedValuesTLPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetValuesPVO
    * View Object: FscmTopModelAM.FinExtractAM.GlBiccExtractAM.SegmentValueHierarchyExtractPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.FndTreeAndVersionVO
  * Underlying Database Objects:
    * FND_VS_VALUES_B
    * GL_SEG_VAL_HIER_CF
    * FND_VS_VALUE_SETS
    * FND_VS_VALUES_TL
    * FND_TREE_AND_VERSION_VO

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | ErpProgramCode!           |       Y        |        Y        |               | Unique identifier of an ErpProgram |
| id                 | Long!                     |                |                 |               | Internal numeric identifier of an ErpProgram |
| name               | NonEmptyTrimmedString240! |                |        Y        |               | Descriptive name of an ErpProgram |
| enabled            | Boolean!                  |                |        Y        |               | Whether this ErpProgram is presently enabled for use. |
| startDate          | LocalDate                 |                |                 |               | The date from when the value is available for use. |
| endDate            | LocalDate                 |                |                 |               | The date till which the value is available for use. |
| summaryOnly        | Boolean!                  |                |        Y        |               | Indicates that the ErpProgram is only used for summarization and may not be used on GL Entries |
| securityEnabled    | Boolean!                  |                |                 |               | Indicates that data linked to this ErpProgram is protected by row-level security. |
| sortOrder          | PositiveInt               |                |                 |               | The number that indicates the order in which the values appear in the list of values. |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               | Timestamp this record was last updated in the financial system. |
| lastUpdateUserId   | ErpUserId                 |                |                 |               | User ID of the person who last updated this record. |
| parentCode         | ErpProgramCode            |                |                 |               | Code of the ErpProgram which is the immediate parent of this one.<br/>Will be undefined if the ErpProgram has no parent. |
| parent             | ErpProgram                |                |                 |               | The ErpProgram which is the immediate parent of this one.<br/>Will be undefined if the ErpProgram has no parent. |
| children           | [ErpProgram!]             |                |                 |               | The ErpPrograms which are the immediate children of this one.<br/>Will be an empty list if the ErpProgram has no children. |
| hierarchyDepth     | Int                       |                |        Y        |               | Level below the top for a ErpProgram that is part of a reporting hierarchy. |
| hierarchyLevel     | String                    |                |        Y        |               | Reporting Level designation based on the hierachy depth. |
| eligibleForUse     | Boolean!                  |                |                 |               | Returns whether this ErpProgram is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the ErpProgram must:<br/>- Be enabled<br/>- Not be summaryOnly<br/>- Have a startDate and endDate range which includes the given accountingDate |

* `parent` : `ErpProgram`
  * The ErpProgram which is the immediate parent of this one.<br/>Will be undefined if the ErpProgram has no parent.
* `eligibleForUse` : `Boolean!`
  * Returns whether this ErpProgram is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the ErpProgram must:<br/>- Be enabled<br/>- Not be summaryOnly<br/>- Have a startDate and endDate range which includes the given accountingDate
  * Arguments:
    * `accountingDate` : `LocalDate`

##### Linked Data Objects

(None)

#### Query Operations

##### `erpProgram`

> Get a single ErpProgram by code.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `ErpProgram`

##### `erpProgramChildren`

> Get items under the given ErpProgram in the hierarchy.
> Returns undefined if the parent does not exist.
> Returns an empty list if the given record has no children.

* **Parameters**
  * `code : String!`
* **Returns**
  * `[ErpProgram!]`

##### `erpProgramSearch`

> Search for ErpProgram objects by multiple properties.
> See
> See the ErpProgramFilterInput type for options.

* **Parameters**
  * `filter : ErpProgramFilterInput!`
* **Returns**
  * `ErpProgramSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpProject

The Project segment tracks financial activity for a "body of work" that often has a start and an end date that spans across fiscal years.

**Expanded Definition and Criteria:**

There are two categories of Projects:

1. GL-Only Projects
2. Projects supported with the PPM (Projects Portfolio Management).

GL-Only Projects - Activities, initiatives, or bodies of work with explicit funding, low complexity of budget management and/or reporting needs, &         which are not explicitly defined as a PPM Project.

- Are associated with a Financial Department, and are formally recognized and of financial significance.
- Billing/invoicing to a third party is not required.

PPM Projects - Generally, a body of work, often supported by a contract, with complex budget and third-party invoicing needs, or designated to a         specific faculty member by agreement.

- Generally, have a designated start and end date.
- Managed under the terms and conditions of a contract.
- Supported by multi-funding sources.
- Supports reporting across fiscal years.

**FAU Value Comparison:**

Due to significant variations in how departments track projects in KFS, it is not possible to align the Project segment with a KFS value.

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `ERP_PROJECT` (view)
  * Support Tables:
    * `VALUE_SET_TYPED_VALUES_PVO`
    * `VALUE_SET_TYPED_VALUES_TL_PVO`
    * `VALUE_SET_VALUES_PVO`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetTypedValuesPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetTypedValuesTLPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetValuesPVO
    * View Object: FscmTopModelAM.FinExtractAM.GlBiccExtractAM.SegmentValueHierarchyExtractPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.FndTreeAndVersionVO
  * Underlying Database Objects:
    * FND_VS_VALUES_B
    * GL_SEG_VAL_HIER_CF
    * FND_VS_VALUE_SETS
    * FND_VS_VALUES_TL
    * FND_TREE_AND_VERSION_VO

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | ErpProjectCode!           |       Y        |        Y        |               | Unique identifier of an ErpProject |
| id                 | Long!                     |                |                 |               | Internal numeric identifier of an ErpProject |
| name               | NonEmptyTrimmedString240! |                |        Y        |               | Descriptive name of an ErpProject |
| enabled            | Boolean!                  |                |        Y        |               | Whether this ErpProject is presently enabled for use. |
| startDate          | Date                      |                |                 |               | The date from when the value is available for use. |
| endDate            | Date                      |                |                 |               | The date till which the value is available for use. |
| summaryOnly        | Boolean!                  |                |        Y        |               | Indicates that the ErpProject is only used for summarization and may not be used on GL Entries |
| securityEnabled    | Boolean!                  |                |                 |               | Indicates that data linked to this ErpProject is protected by row-level security. |
| sortOrder          | PositiveInt               |                |                 |               | The number that indicates the order in which the values appear in the list of values. |
| lastUpdateDateTime | DateTime                  |                |        Y        |               | Timestamp this record was last updated in the financial system. |
| lastUpdateUserId   | ErpUserId                 |                |                 |               | User ID of the person who last updated this record. |
| parentCode         | ErpProjectCode            |                |                 |               | Code of the ErpProject which is the immediate parent of this one.<br/>Will be undefined if the ErpProject has no parent. |
| parent             | ErpProject                |                |                 |               | The ErpProject which is the immediate parent of this one.<br/>Will be undefined if the ErpProject has no parent. |
| children           | [ErpProject!]             |                |                 |               | The ErpProjects which are the immediate children of this one.<br/>Will be an empty list if the ErpProject has no children. |
| hierarchyDepth     | Int                       |                |        Y        |               | Level below the top for a ErpProject that is part of a reporting hierarchy. |
| hierarchyLevel     | String                    |                |        Y        |               | Reporting Level designation based on the hierachy depth. |
| isPpmProject       | Boolean                   |                |                 |               | Whether this is a PPM project or a GL Only project.  Only GL-only projects may be expensed directly on a journal feed.  PPM Projects must be expensed via the POET strings via the ppmSegments inputs on the journal or distribution lines. |
| ppmProject         | PpmProject                |                |                 |               | If a project code represents a PPM Project, this property will be a reference to that project. |
| eligibleForUse     | Boolean!                  |                |                 |               | Returns whether this ErpProject is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the ErpProject must:<br/>- Be enabled<br/>- Not be summaryOnly<br/>- Have a parentCode of GLG000000A (parent of all GL-only projects)<br/>- Have a startDate and endDate range which includes the given accountingDate |

* `parent` : `ErpProject`
  * The ErpProject which is the immediate parent of this one.<br/>Will be undefined if the ErpProject has no parent.
* `ppmProject` : `PpmProject`
  * If a project code represents a PPM Project, this property will be a reference to that project.
  * Description of `PpmProject`:
    * The Project identifies the planned work or activity to be completed over a period of time and intended to achieve a particular goal.<br/><br/>--Roll-up relationship to the new Chart of Accounts (CoA) in the General Ledger:--<br/><br/>- The POET(AF) Project value will roll up to the Project segment of the Chart of Accounts.<br/>- PPM Project values and CoA Project segment values will be the same<br/><br/>--Examples:--<br/><br/>- Capital Projects<br/>- Sponsored Projects<br/>- Faculty Projects
* `eligibleForUse` : `Boolean!`
  * Returns whether this ErpProject is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the ErpProject must:<br/>- Be enabled<br/>- Not be summaryOnly<br/>- Have a parentCode of GLG000000A (parent of all GL-only projects)<br/>- Have a startDate and endDate range which includes the given accountingDate
  * Arguments:
    * `accountingDate` : `LocalDate`

##### Linked Data Objects

(None)

#### Query Operations

##### `erpProject`

> Get a single ErpProject by code.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `ErpProject`

##### `erpProjectSearch`

> Search for ErpProject objects by multiple properties.
> See the ErpProjectFilterInput type for options.

* **Parameters**
  * `filter : ErpProjectFilterInput!`
* **Returns**
  * `ErpProjectSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpActivity

The Activity segment will track significant transactions which are recurring and take place at a point in time.

**Expanded Definition and Criteria:**

The Activity segment will track activities or events which support:

- Financial Departments
- and/or Programs
- and/or GL-Only Projects.

Activities need to be tracked and reported on because of their financial significance.
Activity values will generally be shared across Financial Departments to provide consistency in operational and management reporting for UC Davis.
Activity values are assigned by UC Davis.

**Examples:**

- Commencement
- Student Orientation & Welcome Events
- Fund Raising Campaigns
- Symposiums/ Colloquiums
- Student Advising
- Professional Development/Awards
- Student Competitions
- Marketing & Media Campaigns
- Recruitment & Relocation
- Student Organizations & Sports Clubs
- Campus-wide Activities (e.g. Picnic Day)

**FAU Value Comparison:**

Due to significant variations in how departments track activities in KFS, it is not possible to align the Activity segment with a KFS value.

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `ERP_ACTIVITY` (view)
  * Support Tables:
    * `VALUE_SET_TYPED_VALUES_PVO`
    * `VALUE_SET_TYPED_VALUES_TL_PVO`
    * `VALUE_SET_VALUES_PVO`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetTypedValuesPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetTypedValuesTLPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.ValueSetValuesPVO
    * View Object: FscmTopModelAM.FinExtractAM.GlBiccExtractAM.SegmentValueHierarchyExtractPVO
    * View Object: FscmTopModelAM.AnalyticsServiceAM.FndTreeAndVersionVO
  * Underlying Database Objects:
    * FND_VS_VALUES_B
    * GL_SEG_VAL_HIER_CF
    * FND_VS_VALUE_SETS
    * FND_VS_VALUES_TL
    * FND_TREE_AND_VERSION_VO

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | ErpActivityCode!          |       Y        |        Y        |               | Unique identifier of an ErpActivity |
| id                 | Long!                     |                |                 |               | Internal numeric identifier of an ErpActivity |
| name               | NonEmptyTrimmedString240! |                |        Y        |               | Descriptive name of an ErpActivity |
| enabled            | Boolean!                  |                |        Y        |               | Whether this ErpActivity is presently enabled for use. |
| startDate          | LocalDate                 |                |                 |               | The date from when the value is available for use. |
| endDate            | LocalDate                 |                |                 |               | The date till which the value is available for use. |
| summaryOnly        | Boolean!                  |                |        Y        |               | Indicates that the ErpActivity is only used for summarization and may not be used on GL Entries |
| securityEnabled    | Boolean!                  |                |                 |               | Indicates that data linked to this ErpActivity is protected by row-level security. |
| sortOrder          | PositiveInt               |                |                 |               | The number that indicates the order in which the values appear in the list of values. |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               | Timestamp this record was last updated in the financial system. |
| lastUpdateUserId   | ErpUserId                 |                |                 |               | User ID of the person who last updated this record. |
| parentCode         | ErpActivityCode           |                |                 |               | Code of the ErpActivity which is the immediate parent of this one.<br/>Will be undefined if the ErpActivity has no parent. |
| parent             | ErpActivity               |                |                 |               | The ErpActivity which is the immediate parent of this one.<br/>Will be undefined if the ErpActivity has no parent. |
| children           | [ErpActivity!]            |                |                 |               | The ErpActivitys which are the immediate children of this one.<br/>Will be an empty list if the ErpActivity has no children. |
| hierarchyDepth     | Int                       |                |        Y        |               | Level below the top for a ErpActivity that is part of a reporting hierarchy. |
| hierarchyLevel     | String                    |                |        Y        |               | Reporting Level designation based on the hierarchy depth. |
| eligibleForUse     | Boolean!                  |                |                 |               | Returns whether this ErpActivity is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the ErpActivity must:<br/>- Be enabled<br/>- Not be summaryOnly<br/>- Have a startDate and endDate range which includes the given accountingDate |

* `parent` : `ErpActivity`
  * The ErpActivity which is the immediate parent of this one.<br/>Will be undefined if the ErpActivity has no parent.
* `eligibleForUse` : `Boolean!`
  * Returns whether this ErpActivity is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the ErpActivity must:<br/>- Be enabled<br/>- Not be summaryOnly<br/>- Have a startDate and endDate range which includes the given accountingDate
  * Arguments:
    * `accountingDate` : `LocalDate`

##### Linked Data Objects

(None)

#### Query Operations

##### `erpActivity`

> Get a single ErpActivity by code.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `ErpActivity`

##### `erpActivityChildren`

> Get items under the given ErpActivity in the hierarchy.
> Returns undefined if the parent does not exist.
> Returns an empty list if the given record has no children.

* **Parameters**
  * `code : String!`
* **Returns**
  * `[ErpActivity!]`

##### `erpActivitySearch`

> Search for ErpActivity objects by multiple properties.
> See the ErpActivityFilterInput type for options.

* **Parameters**
  * `filter : ErpActivityFilterInput!`
* **Returns**
  * `ErpActivitySearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.
