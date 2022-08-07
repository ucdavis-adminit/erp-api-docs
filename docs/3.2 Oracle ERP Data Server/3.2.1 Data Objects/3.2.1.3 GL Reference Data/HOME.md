# 3.2.1.3 GL Reference Data

<!--BREAK-->
### Data Object: GlAccountAlias

A shorthand for identifying a set of GL chartstring segments.  May be used in various action request APIs in place of a GL chartstring.

The Alias will be interpreted by the API server and applied to the action request.  As such, very recent changes to aliases may not be taken into account, as data extracts from Oracle Financials are performed on a schedule.

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `GL_ACCOUNT_ALIAS`
* Data Origin:
  * System: Oracle BIPublisher
  * Extract Objects:
    * Report: GL Alias Export
  * Underlying Database Objects:
    * GL_ACCOUNT_ALIASES_B
    * GL_ACCOUNT_ALIASES_TL
    * GL_ACCOUNT_ALIASES_VL

##### Properties

| Property Name     | Data Type  | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ----------------- | ---------- | :------------: | :-------------: | ------------- | ----- |
| aliasCode         | String!    |                |        Y        |               | The unique code assigned to the contained set of glSegments. |
| name              | String!    |                |        Y        |               |  |
| description       | String!    |                |        Y        |               |  |
| combinationCodeId | Long!      |                |        Y        |               | Internal numeric identifier of the combination of GL Segment values. |
| enabled           | Boolean!   |                |        Y        |               |  |
| startDate         | Date       |                |                 |               |  |
| endDate           | Date       |                |                 |               |  |
| lastUpdateDate    | DateTime!  |                |        Y        |               |  |
| lastUpdateUser    | String     |                |                 |               |  |
| glSegments        | GlSegments |                |                 |               |  |

* `glSegments` : `GlSegments`
  * Description of `GlSegments`:
    * GL segment values as separate fields.

##### Linked Data Objects

(None)

#### Query Operations

##### `glAccountAlias`

> Get a single GlAccountAlias by aliasCode.  Returns undefined if does not exist

* **Parameters**
  * `aliasCode : String!`
* **Returns**
  * `GlAccountAlias`

##### `glAccountAliasSearch`

> Search for GlAccountAlias objects by multiple properties.
> See
> See the GlAccountAliasFilterInput type for options.

* **Parameters**
  * `filter : GlAccountAliasFilterInput!`
* **Returns**
  * `GlAccountAliasSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: GlAccountingCombination

Known accounting chartstring combinations.

#### Access Controls

* Required Role: ``

#### Data Source

* Local Table/View: `undefined`

##### Properties

| Property Name | Data Type              | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------- | ---------------------- | :------------: | :-------------: | ------------- | ----- |
| id            | Long!                  |                |                 |               |  |
| entity        | ErpEntityCode!         |                |        Y        |               | Required: Entity to which to charge a transaction. |
| fund          | ErpFundCode!           |                |        Y        |               | Required: Funding source to which to charge a transaction. |
| department    | ErpDepartmentCode!     |                |        Y        |               | Required: Financial department to which to charge a transaction. |
| purpose       | ErpPurposeCode         |                |        Y        |               | Required for Expenses: Functional purpose of the expense. |
| account       | ErpAccountCode!        |                |        Y        |               | Required: Nature of the transaction, expense, income, liability, etc... |
| project       | ErpProjectCode         |                |        Y        |               | Optional:  |
| program       | ErpProgramCode         |                |        Y        |               | Optional:  |
| activity      | ErpActivityCode        |                |        Y        |               | Optional:  |
| erpEntity     | ErpEntity              |                |                 |               |  |
| erpFund       | ErpFund                |                |                 |               |  |
| erpDepartment | ErpFinancialDepartment |                |                 |               |  |
| erpPurpose    | ErpPurpose             |                |                 |               |  |
| erpActivity   | ErpActivity            |                |                 |               |  |
| erpProgram    | ErpProgram             |                |                 |               |  |
| erpProject    | ErpProject             |                |                 |               |  |

* `erpEntity` : `ErpEntity`
  * Description of `ErpEntity`:
    * The Entity segment identifies the major UC system organizational units. These units generally require their own complete, separately audited financial statements to comply with external, regulatory reporting requirements (e.g., external audits, tax reporting), which cannot achieve compliance by using the audited financial statements issued by the Office of the President. Entity, however, will also provide high level management and operational reports.<br/><br/>The balancing segment designation in Oracle Financials Cloud allows for net position (e.g., fund balance) to be calculated at the Entity level.<br/><br/>Entities at all levels have unique reporting and/or external auditing needs that can only be met with an Entity level designation (e.g., UC Davis Health).<br/><br/>--FAU Value Comparison:--<br/>The Entity segment most closely aligns with the KFS Chart (e.g. 3, H, L, P).
* `erpFund` : `ErpFund`
  * Description of `ErpFund`:
    * Funds provide a method of tracking funding resources whose use is limited by donors, granting agencies, regulations and other external individuals or entities, or by governing boards. A Fund is maintained for each specific funding type (e.g., Unrestricted, Restricted-Expendable, Capital) which supports the compilation of GASB audited financial statements.<br/><br/>The balancing segment designation in Oracle Financials Cloud allows for net position (e.g., fund balance) to be calculated at the Fund level.<br/><br/>In most cases, Fund activity will be presented in the general ledger in summary and the Fund values will be shared amongst Financial Departments. For example, all Financial Departments will share one Restricted Expendable Federal Contracts fund. The detailed transactional information related to each federally sponsored project within this fund will be tracked using the PPM module.<br/><br/>--FAU Value Comparison:--<br/>The Fund segment most closely aligns with the fund attribute of the KFS Account.
* `erpDepartment` : `ErpFinancialDepartment`
  * Description of `ErpFinancialDepartment`:
    * Financial Department is often known as the "cost center" or "department". This field records, tracks and retains the Financial Department's financial transactions. There are several levels of Financial Departments within the CoA hierarchy. The mid-level hierarchy aligns with the UCPath HR Departments.<br/><br/>--Financial Departments have:--<br/>- An ongoing business objective and operational function with no planned end date (enabling historical trend analysis + long-range planning)<br/><br/>- Identifiable, permanently funded employees and generally an allocation of physical space<br/><br/>--FAU Value Comparison:--<br/>Due to significant variations in departments' financial structure in KFS, it is not possible to align the Financial Department segment with  specific KFS values.<br/><br/>--Access Roles: erp:reader-refdata--
* `erpPurpose` : `ErpPurpose`
  * Description of `ErpPurpose`:
    * The Purpose segment tracks the purpose of the transaction, such as NACUBO-defined functional expense classification and mission.<br/><br/>NACUBO classification data is utilized for far-reaching external reporting (e.g., institution ranking). This field is also essential for compliance with federal cost principles and financial statement reporting requiring expenditures be displayed by functional class.<br/><br/>--FAU Value Comparison:--<br/><br/>The Purpose segment most closely aligns with the HEFC (Higher Ed. Function Code) attribute of the KFS Account.
* `erpActivity` : `ErpActivity`
  * Description of `ErpActivity`:
    * The Activity segment will track significant transactions which are recurring and take place at a point in time.<br/><br/>--Expanded Definition and Criteria:--<br/><br/>The Activity segment will track activities or events which support:<br/><br/>- Financial Departments<br/>- and/or Programs<br/>- and/or GL-Only Projects.<br/><br/>Activities need to be tracked and reported on because of their financial significance.<br/>Activity values will generally be shared across Financial Departments to provide consistency in operational and management reporting for UC Davis.<br/>Activity values are assigned by UC Davis.<br/><br/>--Examples:--<br/><br/>- Commencement<br/>- Student Orientation & Welcome Events<br/>- Fund Raising Campaigns<br/>- Symposiums/ Colloquiums<br/>- Student Advising<br/>- Professional Development/Awards<br/>- Student Competitions<br/>- Marketing & Media Campaigns<br/>- Recruitment & Relocation<br/>- Student Organizations & Sports Clubs<br/>- Campus-wide Activities (e.g. Picnic Day)<br/><br/>--FAU Value Comparison:--<br/><br/>Due to significant variations in how departments track activities in KFS, it is not possible to align the Activity segment with a KFS value.
* `erpProgram` : `ErpProgram`
  * Description of `ErpProgram`:
    * The Program segment records revenue and expense transactions associated with a formal, ongoing system-wide or cross-campus/location academic or administrative activity that demonstrates UC Davis' mission of teaching, research, public service and patient care.<br/><br/>--Expanded Definition and Criteria:--<br/>There are two categories of Programs:<br/>1. Those pre-defined and sanctioned by UCOP, of which values are predesignated<br/>2. Those endorsed and acknowledged by UC Davis Leadership<br/><br/>Programs have permanence, are a going-concern, and are considered significant due to their prominence and impact.<br/><br/>In general, Programs have allocated, not dedicated, FTEs and cannot be identified through a single Financial Department, Project Code or Activity Code.<br/><br/>Program values are determined by both UCOP and UC Davis.<br/><br/>--Examples:--<br/><br/>- UCOP System-wide examples:<br/>  - Ag Experiment Station (AES)<br/>  - California State Summer School for Mathematics & Science (COSMOS)<br/>  - UC Sacramento<br/>- UC Davis examples (possible programs):<br/>  - Self-Supporting Degree Programs<br/>  - Student Success Programs<br/>  - Graduate Groups<br/>  - Campus-wide Programs<br/>  - Campus Ready<br/>  - Healthy Davis Together<br/>  - International/ Study Abroad Programs<br/>  - Housing Services Programs<br/><br/>--FAU Value Comparison:--<br/>Due to significant variations in how departments track programs in KFS, it is not possible to align the Program segment with a KFS value.
* `erpProject` : `ErpProject`
  * Description of `ErpProject`:
    * The Project segment tracks financial activity for a "body of work" that often has a start and an end date that spans across fiscal years.<br/><br/>--Expanded Definition and Criteria:--<br/><br/>There are two categories of Projects:<br/><br/>1. GL-Only Projects<br/>2. Projects supported with the PPM (Projects Portfolio Management).<br/><br/>GL-Only Projects - Activities, initiatives, or bodies of work with explicit funding, low complexity of budget management and/or reporting needs, &         which are not explicitly defined as a PPM Project.<br/><br/>- Are associated with a Financial Department, and are formally recognized and of financial significance.<br/>- Billing/invoicing to a third party is not required.<br/><br/>PPM Projects - Generally, a body of work, often supported by a contract, with complex budget and third-party invoicing needs, or designated to a         specific faculty member by agreement.<br/><br/>- Generally, have a designated start and end date.<br/>- Managed under the terms and conditions of a contract.<br/>- Supported by multi-funding sources.<br/>- Supports reporting across fiscal years.<br/><br/>--FAU Value Comparison:--<br/><br/>Due to significant variations in how departments track projects in KFS, it is not possible to align the Project segment with a KFS value.

##### Linked Data Objects

(None)

#### Query Operations

##### `glAccountingCombination`

> Get a single GlAccountingCombination by its id.  Returns undefined if does not exist

* **Parameters**
  * `id : Long!`
* **Returns**
  * `GlAccountingCombination`

##### `glAccountingCombinationSearch`

> Search for GlAccountingCombination objects by multiple properties.
> See
> See the GlAccountingCombinationFilterInput type for options.

* **Parameters**
  * `filter : GlAccountingCombinationFilterInput!`
* **Returns**
  * `GlAccountingCombinationSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: GlAccountingPeriod

Represents an accounting period in the GL module of Oracle Financials.  Used for validation of submitted journal entry data.

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `GL_PERIOD` (view)
  * Support Tables:
    * `ERP_PERIOD`
* Data Origin:
  * System: Oracle BIPublisher
  * Extract Objects:
    * Report: GL Period Export
  * Underlying Database Objects:
    * GL_LEDGERS_ALL_V (VIEW)
    * FND_APPLICATION (VIEW)
    * GL_PERIOD_STATUSES
    * FND_APPL_TAXONOMY
    * GL_LEDGERS
    * FND_LOOKUP_VALUES_B
    * FND_LOOKUP_VALUES_TL

##### Properties

| Property Name         | Data Type                | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| --------------------- | ------------------------ | :------------: | :-------------: | ------------- | ----- |
| periodName            | ErpAccountingPeriodName! |                |        Y        |               | The unique name of a GL Accounting Period |
| periodYear            | PositiveInt!             |                |        Y        |               |  |
| periodNumber          | PositiveInt!             |                |        Y        |               |  |
| periodStatus          | ErpPeriodStatus!         |                |        Y        |               |  |
| adjustmentPeriod      | Boolean!                 |                |        Y        |               |  |
| startDate             | Date!                    |                |        Y        |               |  |
| endDate               | Date!                    |                |        Y        |               |  |
| yearStartDate         | Date!                    |                |                 |               |  |
| quarterStartDate      | Date!                    |                |                 |               |  |
| quarterNumber         | PositiveInt!             |                |                 |               |  |
| effectivePeriodNumber | PositiveInt!             |                |                 |               |  |
| lastUpdateDate        | Timestamp!               |                |        Y        |               |  |
| lastUpdateUserId      | ErpUserId                |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `glAccountingPeriod`

> Get a single GlAccountingPeriod by its name.  Returns undefined if does not exist

* **Parameters**
  * `periodName : String!`
* **Returns**
  * `GlAccountingPeriod`

##### `glAccountingPeriodByDate`

> Get a single non-adjustment GlAccountingPeriod by the given date.  Returns undefined if no period is defined for the given date.

* **Parameters**
  * `accountingDate : Date!`
* **Returns**
  * `GlAccountingPeriod`

##### `glAccountingPeriodSearch`

> Search for GlAccountingPeriod objects by multiple properties.
> See
> See the GlAccountingPeriodFilterInput type for options.

* **Parameters**
  * `filter : GlAccountingPeriodFilterInput!`
* **Returns**
  * `GlAccountingPeriodSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: GlJournalCategory

Represents the types of transactions that are part of this journal.  For boundary systems, this is generally the same as the 

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `GL_JOURNAL_CATEGORY`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.FinExtractAM.GlBiccExtractAM.JournalCategoryExtractPVO
  * Underlying Database Objects:
    * GL_JE_CATEGORIES_B
    * GL_JE_CATEGORIES_TL

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| key                | GlJournalCategoryKey!     |                |        Y        |               | The name that uniquely identifies a journal category. |
| name               | GlJournalCategoryKey!     |                |        Y        |               | The journal category name provided by the user when the journal category is created. |
| description        | NonEmptyTrimmedString240! |                |                 |               | The description of the journal category associated with the row. |
| lastUpdateDateTime | Timestamp!                |                |        Y        |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `glJournalCategory`

> Get a single GlJournalCategory by code.  Returns undefined if does not exist

* **Parameters**
  * `key : String!`
* **Returns**
  * `GlJournalCategory`

##### `glJournalCategoryAll`

> Get all currently valid GlJournalCategory objects.

* **Parameters**
  * `sort : [String!]`
* **Returns**
  * `[GlJournalCategory!]!`

##### `glJournalCategorySearch`

> Search for GlJournalCategory objects by multiple properties.
> See
> See the GlJournalCategoryFilterInput type for options.

* **Parameters**
  * `filter : GlJournalCategoryFilterInput!`
* **Returns**
  * `GlJournalCategorySearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: GlJournalSource

Represents the types of transactions that are part of this journal.  For boundary systems, this is generally the same as the 

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `GL_JOURNAL_SOURCE`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.FinExtractAM.GlBiccExtractAM.JournalSourceExtractPVO
  * Underlying Database Objects:
    * GL_JE_SOURCES_B
    * GL_JE_SOURCES_TL

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| key                | GlJournalSourceKey!       |                |        Y        |               | The name that uniquely identifies a journal category. |
| name               | GlJournalSourceKey!       |                |        Y        |               | The journal category name provided by the user when the journal category is created. |
| description        | NonEmptyTrimmedString240! |                |                 |               | The description of the journal category associated with the row. |
| lastUpdateDateTime | Timestamp!                |                |        Y        |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `glJournalSource`

> Get a single GlJournalSource by code.  Returns undefined if does not exist

* **Parameters**
  * `key : String!`
* **Returns**
  * `GlJournalSource`

##### `glJournalSourceAll`

> Get all currently valid GlJournalSource objects.

* **Parameters**
  * `sort : [String!]`
* **Returns**
  * `[GlJournalSource!]!`

##### `glJournalSourceSearch`

> Search for GlJournalSource objects by multiple properties.
> See
> See the GlJournalSourceFilterInput type for options.

* **Parameters**
  * `filter : GlJournalSourceFilterInput!`
* **Returns**
  * `GlJournalSourceSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: GlSegmentNames



#### Access Controls

* Required Role: ``

#### Data Source

* Local Table/View: `undefined`

##### Properties

| Property Name  | Data Type | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| -------------- | --------- | :------------: | :-------------: | ------------- | ----- |
| entityName     | String    |                |                 |               |  |
| fundName       | String    |                |                 |               |  |
| departmentName | String    |                |                 |               |  |
| accountName    | String    |                |                 |               |  |
| purposeName    | String    |                |                 |               |  |
| projectName    | String    |                |                 |               |  |
| programName    | String    |                |                 |               |  |
| activityName   | String    |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.
