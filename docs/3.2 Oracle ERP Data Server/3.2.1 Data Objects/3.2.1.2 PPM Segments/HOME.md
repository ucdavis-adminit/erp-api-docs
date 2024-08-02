# 3.2.1.2 PPM Segments

<!--BREAK-->
### Data Object: PpmProject

The Project identifies the planned work or activity to be completed over a period of time and intended to achieve a particular goal.

**Roll-up relationship to the new Chart of Accounts (CoA) in the General Ledger:**

* The POET(AF) Project value will roll up to the Project segment of the Chart of Accounts.
* PPM Project values and CoA Project segment values will be the same

**Examples:**

* Capital Projects
* Sponsored Projects
* Faculty Projects

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `PPM_PROJECT_V` (view)
  * Support Tables:
    * `PPM_PROJECT`
    * `ERP_ORGANIZATION`
    * `ERP_LEGAL_ENTITY`
    * `ERP_ENTITY`
    * `PPM_PROJECT_AWARD`
    * `PPM_AWARD`
    * `ERP_CONTRACT`
    * `ERP_LOOKUP_VALUES`
    * `XLA_MAPPING_SET_VALUES`
    * `PPM_FUNDING_SOURCE`
    * `PPM_PROJECT_PLAN_VERSION`
    * `PPM_PROJECT`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.PjfProjectAM.ProjectView
  * Underlying Database Objects:
    * FND_CURRENCIES_VL
    * FND_SETID_SETS_VL
    * GL_DAILY_CONVERSION_TYPES
    * HR_ORGANIZATION_INFORMATION_F
    * HR_ORGANIZATION_UNITS_F_TL
    * HR_ORGANIZATION_V
    * PER_PERSON_NAMES_F_V
    * PJC_CINT_RATE_SCH_VL
    * PJF_IND_RATE_SCH_VL
    * PJF_LATESTPROJECTMANAGER_V
    * PJF_PROJECTS_ALL_B
    * PJF_PROJECTS_ALL_VL
    * PJF_PROJECT_STATUSES_VL
    * PJF_PROJECT_TYPES_VL
    * PJF_PROJ_ELEMENTS_VL
    * PJF_TP_SCHEDULES
    * PJF_WORK_TYPES_VL
    * PJO_PROJECT_PROGRESS
    * PJT_PRIMARYPROJMANAGER_V
    * PJT_SCHEDULES_VL
    * XLE_ENTITY_PROFILES

##### Properties

| Property Name                  | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| id                             | Long!                     |       Y        |                 |               | Project ID: Unique identifier of the project.  Internal to Oracle. |
| projectNumber                  | PpmProjectNumber!         |                |        Y        |               | Project Number: Number of the project that is being created.  This will match the GL Project used to record costs to the ledger. |
| name                           | NonEmptyTrimmedString240! |                |        Y        |               | Project Name: Name of the project that is being created. |
| description                    | String                    |                |                 |               | Project Description: A description about the project. This might include high-level information about the work being performed. |
| projectStartDate               | LocalDate!                |                |        Y        |               | Project Start Date: The date that work or information tracking begins on a project. |
| projectEndDate                 | LocalDate!                |                |                 |               | Project End Date:  The last accounting date for which costs may be charged to the project. |
| projectCompletionDate          | LocalDate                 |                |        Y        |               | Project Completion Date: The date that work or information tracking completes for a project. |
| projectStatus                  | NonEmptyTrimmedString80!  |                |                 |               | Project Status: An implementation-defined classification of the status of a project. Typical project statuses are Active and Closed. |
| projectStatusCode              | NonEmptyTrimmedString30!  |                |        Y        |               | Project Status Code: The current status set on a project. A project status is an implementation-defined classification of the status of a project. Typical project status codes are ACTIVE and CLOSED. |
| projectOrganizationName        | NonEmptyTrimmedString240  |                |        Y        |               | Organization: An organizing unit in the internal or external structure of the enterprise. Organization structures provide the framework for performing legal reporting, financial control, and management reporting for the project. |
| businessUnitName               | NonEmptyTrimmedString240! |                |                 |               | Name of the component of the system that this project belongs to.  There is a separation between sponsored projects managed by CGA, and other managed projects.  The value in this field should align with the sponsoredProject flag. |
| legalEntityName                | NonEmptyTrimmedString240! |                |                 |               | Legal Entity: Name of the legal entity associated with the project. A legal entity is a recognized party with given rights and responsibilities by legislation. Legal entities generally have the right to own property, the right to trade, the responsibility to repay debt, and the responsibility to account for themselves to company regulators, taxation authorities, and owners according to rules specified in the relevant legislation. |
| legalEntityCode                | ErpEntityCode             |                |                 |               |  |
| projectType                    | NonEmptyTrimmedString30!  |                |        Y        |               | Project Type - Values:<br/><br/>- Sponsored Capital<br/>- Capital<br/>- Fabrication<br/>- Sponsored<br/>- Sponsored Fabrication<br/>- Internal |
| projectTypeName                | NonEmptyTrimmedString240! |                |                 |               | Project Type Name: String |
| sourceApplicationCode          | NonEmptyTrimmedString30   |                |                 |               | Source Application: The third-party application from which the project originates. |
| sourceProjectReference         | NonEmptyTrimmedString30   |                |                 |               | Source Reference: The identifier of the project in the external system where it was originally entered. |
| projectCategory                | NonEmptyTrimmedString30!  |                |                 |               |  |
| sponsoredProject               | Boolean!                  |                |        Y        |               | Sponsored Project Flag: Whether this project is a sponsored project and requires Award and Funding Source segments when assigning costs. |
| billingEnabled                 | Boolean!                  |                |        Y        |               | Billing Enabled Flag: If billing is allowed for this project. |
| capitalizationEnabled          | Boolean!                  |                |        Y        |               | Capitalization Enabled Flag: If this is a capital project whose costs may need to be capitalized. |
| templateProject                | Boolean!                  |                |        Y        |               | Template Project Only Flag: If this project is a template for other projects.  Template projects may not have costs submitted against them. |
| lastUpdateDateTime             | DateTime!                 |                |        Y        |               | Timestamp this record was last updated in the financial system. |
| lastUpdateUserId               | ErpUserId                 |                |                 |               | User ID of the person who last updated this record. |
| projectBudgeted                | Boolean!                  |                |                 |               | Does this project have an established budget.  With a budget, transactions against a project will be rejected. |
| hasBudgetaryControl            | Boolean!                  |                |                 |               | Whether this project is subject to budgetary control rules. |
| defaultAwardNumber             | PpmAwardNumber            |                |        Y        |               | For sponsored projects, the default award number that will be expensed if left off of the journal line or distribution. |
| defaultAwardSponsorAwardNumber | NonEmptyTrimmedString60   |                |        Y        |               | For sponsored projects, the sponsor award number for the default award that will be expensed if left off of the journal line or distribution. |
| defaultFundingSourceNumber     | PpmFundingSourceNumber    |                |        Y        |               | For sponsored projects, the default funding source that will be expensed if left off of the journal line or distribution. |
| glInfoAtTaskLevel              | Boolean!                  |                |                 |               | Indicates that the the Fund, Purpose, Program, and Activity GL segments are based on the expensed task.  Those fields will be unset at this level if this flag is true. |
| glPostingEntityCode            | ErpEntityCode!            |                |                 |               | Entity code used when expenses to this project are applied to the general ledger. |
| glPostingFundCode              | ErpFundCode               |                |                 |               | Fund code used when expenses to this project are applied to the general ledger. |
| glPostingDepartmentCode        | ErpDepartmentCode!        |                |                 |               | Financial Department code used when expenses to this project are applied to the general ledger. |
| glPostingPurposeCode           | ErpPurposeCode            |                |                 |               | Purpose code used when expenses to this project are applied to the general ledger. |
| glPostingProgramCode           | ErpProgramCode            |                |                 |               | Program code used when expenses to this project are applied to the general ledger. |
| glPostingProjectCode           | ErpProjectCode!           |                |                 |               | Project code used when expenses to this project are applied to the general ledger. |
| glPostingActivityCode          | ErpActivityCode           |                |                 |               | Activity code used when expenses to this project are applied to the general ledger. |
| tasks                          | [PpmTask!]!               |                |                 |               | Tasks: The Task resource includes the attributes that are used to store values while creating or updating project tasks. Tasks are units of project work assigned or performed as part of the duties of a resource. Tasks can be a portion of project work to be performed within a defined period by a specific resource or multiple resources.<br/><br/>By default, this will only list tasks which are allowed to be assigned costs.  If you need to see all tasks, set the property argument to false. |
| awards                         | [PpmAward!]!              |                |                 |               |  |
| teamMembers                    | [PpmProjectTeamMember!]!  |                |                 |               | List of the project team members.  If roleName is provided, only team members with that role will be returned. |
| awardPersonnel                 | [PpmAwardPersonnel!]!     |                |                 |               | List of the award personnel if this is a sponsored project associated with an award.  If roleName is provided, only people with that role will be returned.  Will return an empty list if this is not a sponsored project. |
| primaryProjectManager          | ErpUser                   |                |                 |               | Person who leads the project team and who has the authority and responsibility for meeting the project objectives |
| primaryProjectManagerEmail     | NonEmptyTrimmedString240  |                |                 |               | Project Manager Email: Email of the person who leads the project team and who has the authority and responsibility for meeting the project objectives. |
| primaryProjectManagerName      | NonEmptyTrimmedString240  |                |                 |               | Project Manager: Name of the person who leads the project team and who has the authority and responsibility for meeting project objectives. |
| eligibleForUse                 | Boolean!                  |                |                 |               | Returns whether this PpmProject is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the PpmProject must:<br/>- Have a projectStatusCode of ACTIVE<br/>- Not be a templateProject<br/>- Have a projectStartDate and projectCompletionDate range which includes the given accountingDate |

* `tasks` : `[PpmTask!]!`
  * Tasks: The Task resource includes the attributes that are used to store values while creating or updating project tasks. Tasks are units of project work assigned or performed as part of the duties of a resource. Tasks can be a portion of project work to be performed within a defined period by a specific resource or multiple resources.<br/><br/>By default, this will only list tasks which are allowed to be assigned costs.  If you need to see all tasks, set the property argument to false.
  * Arguments:
    * `chargeableOnly` : `Boolean` = true
  * Description of `PpmTask`:
    * The Task identifies the activities used to further breakdown a PPM project. Every project MUST have at least one Task.  The number of tasks will vary by type of project.<br/><br/>--Roll-up relationship to the new Chart of Accounts in the General Ledger:--<br/><br/>- The Task value will NOT roll up to the Chart of Accounts. Task values will only be used in the PPM module.<br/>- Internal rules within the Oracle PPM module will be used to map the task to components of the GL Chart of Accounts which are not directly mapped to other components of the POET(AF) segments.<br/><br/>--Examples:--<br/><br/>- Design<br/>- Construction<br/>- Data Gathering & Analysis
* `teamMembers` : `[PpmProjectTeamMember!]!`
  * List of the project team members.  If roleName is provided, only team members with that role will be returned.
  * Arguments:
    * `roleName` : `NonEmptyTrimmedString60`
  * Description of `PpmProjectTeamMember`:
    * Person Associated with a PPM Project.  Identifies the person and their role on the project.
* `awardPersonnel` : `[PpmAwardPersonnel!]!`
  * List of the award personnel if this is a sponsored project associated with an award.  If roleName is provided, only people with that role will be returned.  Will return an empty list if this is not a sponsored project.
  * Arguments:
    * `roleName` : `NonEmptyTrimmedString60`
* `primaryProjectManager` : `ErpUser`
  * Person who leads the project team and who has the authority and responsibility for meeting the project objectives
  * Description of `ErpUser`:
    * A user as known to the ERP application.
* `eligibleForUse` : `Boolean!`
  * Returns whether this PpmProject is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the PpmProject must:<br/>- Have a projectStatusCode of ACTIVE<br/>- Not be a templateProject<br/>- Have a projectStartDate and projectCompletionDate range which includes the given accountingDate
  * Arguments:
    * `accountingDate` : `LocalDate`

##### Linked Data Objects

(None)

#### Query Operations

##### `ppmProjectTeamMemberByProjectNumber`

> Pull all active project team members by project number.

* **Parameters**
  * `projectNumber : PpmProjectNumber!`
* **Returns**
  * `[PpmProjectTeamMember!]!`

##### `ppmProjectTeamMemberByProjectAndRole`

> Pull all active project team members by project number and role.

* **Parameters**
  * `projectNumber : PpmProjectNumber!`
  * `roleName : NonEmptyTrimmedString240!`
* **Returns**
  * `[PpmProjectTeamMember!]!`

##### `ppmProject`

> Get a single PpmProject by code.  Returns undefined if does not exist

* **Parameters**
  * `projectId : NumericString!`
* **Returns**
  * `PpmProject`

##### `ppmProjectByNumber`

> Get a single PpmProject by the project number.  Returns undefined if no project with that number is found.

* **Parameters**
  * `projectNumber : String!`
* **Returns**
  * `PpmProject`

##### `ppmProjectByName`

> Gets a list of PpmProjects by exact name.  Returns empty list if none are found.  Project Name should be unique in oracle.

* **Parameters**
  * `projectName : String!`
* **Returns**
  * `[PpmProject!]!`

##### `ppmProjectByProjectTeamMemberEmployeeId`

> Find PpmProject objects by active team members or award personnel.  Role name is optional.  If not passed then the project is returned if they have any role on the project.

* **Parameters**
  * `employeeId : UcEmployeeId!`
  * `roleName : NonEmptyTrimmedString60`
* **Returns**
  * `[PpmProject!]!`

##### `ppmProjectByProjectTeamMemberEmail`

> Find PpmProject objects by active team members.  Role name is optional.  If not passed then the project is returned if they have any role on the project.

* **Parameters**
  * `email : EmailAddress!`
  * `roleName : NonEmptyTrimmedString60`
* **Returns**
  * `[PpmProject!]!`

##### `ppmProjectSearch`

> Search for PpmProject objects by multiple properties.
> See
> See the PpmProjectFilterInput type for options.

* **Parameters**
  * `filter : PpmProjectFilterInput!`
* **Returns**
  * `PpmProjectSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: PpmTask

The Task identifies the activities used to further breakdown a PPM project. Every project MUST have at least one Task.  The number of tasks will vary by type of project.

**Roll-up relationship to the new Chart of Accounts in the General Ledger:**

* The Task value will NOT roll up to the Chart of Accounts. Task values will only be used in the PPM module.
* Internal rules within the Oracle PPM module will be used to map the task to components of the GL Chart of Accounts which are not directly mapped to other components of the POET(AF) segments.

**Examples:**

* Design
* Construction
* Data Gathering & Analysis

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `PPM_TASK`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object:   FscmTopModelAM.PrjExtractAM.PjfBiccExtractAM.TaskStructureExtractPVO
  * Underlying Database Objects:
    * PJF_TASK_XFACE

##### Properties

| Property Name            | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| id                       | Long!                     |       Y        |        Y        |               | Task ID: Unique identifier of the project task. |
| taskNumber               | NonEmptyTrimmedString100! |                |        Y        |               | Task Number: The number of a task. |
| name                     | NonEmptyTrimmedString240! |                |        Y        |               | Task Name: The name of the task. A task is a subdivision of the project work. Each project can have a set of top tasks and a hierarchy of subtasks below each top task. |
| description              | String                    |                |                 |               | Task Description: Text description of the project task that is being created. |
| taskStartDate            | LocalDate                 |                |                 |               | Task Start Date: Scheduled start date of the project task. |
| taskFinishDate           | LocalDate                 |                |                 |               | Task Finish Date: Scheduled end date of the project task. |
| billable                 | Boolean!                  |                |        Y        |               | Billable: Indicates that transactions charged to that task can be billed to customers. |
| chargeable               | Boolean!                  |                |        Y        |               | Chargeable: Indicates that something is eligible to be charged to a task. |
| taskLevel                | NonNegativeInt!           |                |                 |               | Task Level: Indicates level of the task in the WBS. |
| executionDisplaySequence | NonNegativeInt            |                |                 |               | Display Sequence: The order in which the task is displayed in the project. |
| lowestLevelTask          | Boolean                   |                |                 |               | Lowest Level Task: Indicates the task is at the lowest level. |
| parentTaskId             | Long                      |                |                 |               | Parent Task ID: Identifier of the parent task of the task. |
| topTaskId                | Long                      |                |                 |               | Top Task ID: Identifier of the top task to which the task rolls up. If the task is a top task, the identifier of the top task is same as the identifier of the task. |
| lastUpdateDateTime       | DateTime!                 |                |        Y        |               | The date when the task was last updated. |
| lastUpdateUserId         | ErpUserId                 |                |                 |               | The user that last updated the task. |
| projectId                | Long!                     |                |        Y        |               | The project that the task is linked to |
| eligibleForUse           | Boolean!                  |                |                 |               | Returns whether this PpmTask is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the PpmTask must:<br/>- Be chargeable<br/>- Be a lowestLevelTask<br/>- Have a taskStartDate and taskFinishDate range which includes the given accountingDate |
| glPostingProgramCode     | ErpProgramCode            |                |                 |               | GL Program used during subledger accounting jobs to post GL entries when costs are recorded against this task. |
| glPostingPurposeCode     | ErpPurposeCode            |                |                 |               | GL Purpose  used during subledger accounting jobs to post GL entries when costs are recorded against this task. |
| glPostingFundCode        | ErpFundCode               |                |                 |               | GL Fund used during subledger accounting jobs to post GL entries when costs are recorded against this task. |
| glPostingActivityCode    | ErpActivityCode           |                |                 |               | GL Activity used during subledger accounting jobs to post GL entries when costs are recorded against this task. |

* `eligibleForUse` : `Boolean!`
  * Returns whether this PpmTask is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the PpmTask must:<br/>- Be chargeable<br/>- Be a lowestLevelTask<br/>- Have a taskStartDate and taskFinishDate range which includes the given accountingDate
  * Arguments:
    * `accountingDate` : `LocalDate`

##### Linked Data Objects

(None)

#### Query Operations

##### `ppmTask`

> Get a single PpmTask by id.  Returns undefined if it does not exist

* **Parameters**
  * `id : NumericString!`
* **Returns**
  * `PpmTask`

##### `ppmTaskByProjectNumber`

> Gets PpmTasks by project.  Returns empty list if none are found

* **Parameters**
  * `projectNumber : PpmProjectNumber!`
* **Returns**
  * `[PpmTask!]!`

##### `ppmTaskByProjectNumberAndTaskNumber`

> Gets PpmTasks by projectNumber and taskNumber.  Returns undefined if not found

* **Parameters**
  * `projectNumber : PpmProjectNumber!`
  * `taskNumber : PpmTaskNumber!`
* **Returns**
  * `PpmTask`

##### `ppmTaskSearch`

> Search for PpmTask objects by multiple properties.
> See
> See the PpmTaskFilterInput type for options.

* **Parameters**
  * `filter : PpmTaskFilterInput!`
* **Returns**
  * `PpmTaskSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: PpmOrganization

The Expenditure Organization identifies the organization that is incurring the expense and revenue. This may NOT be the same as the organization that owns the project.

**Roll-up relationship to the new Chart of Accounts in the General Ledger:**

* The Expenditure Organization value will roll up to the Financial Department segment of the Chart of Accounts.

**Examples:**

* Computer Science
* Plant Sciences

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `PPM_ORGANIZATION`
* Data Origin:
  * System: Oracle BIPublisher
  * Extract Objects:
    * /Custom/Interfaces/Data Extracts/PPMExpenseOrganization.xdo
  * Underlying Database Objects:
    * PJF_ORGANIZATIONS_EXPEND_V

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | String!                   |                |        Y        |               | Organization Code: The code of the Organization. |
| name               | NonEmptyTrimmedString100! |                |        Y        |               | Organization Name: Name of the Organization |
| effectiveStartDate | LocalDate!                |                |                 |               | Effective Start Date: Start date of Organization |
| effectiveEndDate   | LocalDate                 |                |                 |               | Effective End Date: End date of Organization |
| enabled            | Boolean!                  |                |        Y        |               | Whether the expense organization allows costing transactions against it. |
| id                 | Long!                     |       Y        |                 |               | Organization ID: Unique identifier of the Organization.  Internal to Oracle. |
| eligibleForUse     | Boolean!                  |                |                 |               | Returns whether this PpmOrganization is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the PpmOrganization must:<br/>- Have a effectiveStartDate and effectiveEndDate range which includes the given accountingDate<br/>- Be enabled |

* `eligibleForUse` : `Boolean!`
  * Returns whether this PpmOrganization is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the PpmOrganization must:<br/>- Have a effectiveStartDate and effectiveEndDate range which includes the given accountingDate<br/>- Be enabled
  * Arguments:
    * `accountingDate` : `LocalDate`

##### Linked Data Objects

(None)

#### Query Operations

##### `ppmOrganization`

> Get a single PpmOrganization by code.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `PpmOrganization`

##### `ppmOrganizationByName`

> Gets PpmOrganizations by exact name.  Returns undefined if does not exist

* **Parameters**
  * `name : String!`
* **Returns**
  * `PpmOrganization`

##### `ppmOrganizationSearch`

> Search for PpmOrganization objects by multiple properties.
> See
> See the PpmOrganizationFilterInput type for options.

* **Parameters**
  * `filter : PpmOrganizationFilterInput!`
* **Returns**
  * `PpmOrganizationSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: PpmExpenditureType

The Expenditure Type identifies the natural classification of the expense transaction being recorded.

**Roll-up relationship to the Chart of Accounts in the General Ledger:**

* The Expenditure Type value will roll up to the (Natural) Account segment in the Chart of Accounts.
* The first 6 characters of the Expenditure Type value will correspond with the (Natural) Account value it rolls up to.

**Examples:**

* Salary
* Fringe Benefits
* Consulting Services
* Travel

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `PPM_EXPENDITURE_TYPE_V` (view)
  * Support Tables:
    * `PPM_EXPENDITURE_TYPE`
    * `ERP_ACCOUNT`
    * `PPM_EXP_TYPE_TO_PROJ_TYPE_LOOKUP`
    * `PPM_EXP_TYPE_TO_PROJ_TYPE_LOOKUP`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.PjfSetupTransactionsAM.ExpenditureTypeView
  * Underlying Database Objects:
    * PJF_EXP_TYPES_B
    * PJF_EXP_TYPES_TL

##### Properties

| Property Name             | Data Type                   | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------------- | --------------------------- | :------------: | :-------------: | ------------- | ----- |
| code                      | String!                     |                |        Y        |               | Expenditure Type Code: The code of the Expenditure Type. |
| name                      | NonEmptyTrimmedString240!   |                |        Y        |               | Expenditure Type: Name of the expenditure type. |
| description               | String                      |                |                 |               | Expenditure Type Description: Description of the expenditure type. |
| startDate                 | LocalDate                   |                |                 |               | Expenditure Type Start Date: Start date of an expenditure type. |
| endDate                   | LocalDate                   |                |                 |               | Expenditure Type End Date: End date of an expenditure type. |
| expenditureCategory       | NonEmptyTrimmedString240    |                |        Y        |               | Expenditure Category: Name of the expenditure category. |
| revenueCategoryCode       | NonEmptyTrimmedString30     |                |                 |               | Revenue Category Code: Code of a category grouping of expenditure types by type of revenue. |
| revenue                   | Boolean!                    |                |        Y        |               | Indicates that this expense type is really a revenue natural account allowed on PPM journals for the purpose of increasing the project budget. |
| lastUpdateDateTime        | DateTime!                   |                |        Y        |               | The date when the expenditure type was last updated. |
| lastUpdateUserId          | ErpUserId                   |                |                 |               | The user that last updated the expenditure type. |
| allowedOnProjectTypeCodes | [NonEmptyTrimmedString30!]! |                |                 |               | Project Type Codes which will accept use of this expenditure type.  If empty, the project type will not be validated against the expense type upon data submission. |
| eligibleForUse            | Boolean!                    |                |                 |               | Returns whether this PpmExpenditureType is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the PpmExpenditureType must:<br/>- Have a startDate and endDate range which includes the given accountingDate |

* `eligibleForUse` : `Boolean!`
  * Returns whether this PpmExpenditureType is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the PpmExpenditureType must:<br/>- Have a startDate and endDate range which includes the given accountingDate
  * Arguments:
    * `accountingDate` : `LocalDate`

##### Linked Data Objects

(None)

#### Query Operations

##### `ppmExpenditureType`

> Get a single PpmExpenditureType by code.  Returns undefined if does not exist.

* **Parameters**
  * `id : String!`
* **Returns**
  * `PpmExpenditureType`

##### `ppmExpenditureTypeByCode`

> Get a single PpmExpenditureType by code.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `PpmExpenditureType`

##### `ppmExpenditureTypeByName`

> Gets PpmExpenditureTypes by exact name.  Returns empty list if none are found

* **Parameters**
  * `name : NonEmptyTrimmedString100!`
* **Returns**
  * `PpmExpenditureType!`

##### `ppmExpenditureTypeAll`

> Get all currently valid PpmExpenditureType objects.

* **Parameters**
  * `sort : [String!]`
* **Returns**
  * `[PpmExpenditureType!]!`

##### `ppmExpenditureTypeSearch`

> Search for PpmExpenditureType objects by multiple properties.
> See
> See the PpmExpenditureTypeFilterInput type for options.

* **Parameters**
  * `filter : PpmExpenditureTypeFilterInput!`
* **Returns**
  * `PpmExpenditureTypeSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: PpmAward



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `PPM_AWARD_V` (view)
  * Support Tables:
    * `PPM_AWARD`
    * `ERP_CONTRACT`
    * `PPM_PROJECT_AWARD`
    * `PPM_PROJECT`
    * `ERP_LOOKUP_VALUES`
    * ` XLA_MAPPING_SET_VALUES`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.GmsAwardAM.AwardHeaderViewPVO
  * Underlying Database Objects:
    * GMS_AWARD_HEADERS_B
    * GMS_AWARD_HEADERS_TL
    * GMS_AWARD_HEADERS_VL

##### Properties

| Property Name               | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| --------------------------- | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| id                          | Long!                     |       Y        |                 |               | Award ID: Internal Unique identifier of the award. |
| awardNumber                 | NonEmptyTrimmedString60!  |                |        Y        |               | Award number tracked by the sponsor. |
| ppmAwardNumber              | NonEmptyTrimmedString30!  |                |        Y        |               | Award number used internally to PPM.  Generally of the form K1234567. |
| name                        | NonEmptyTrimmedString240! |                |        Y        |               | Award Name: Name of the award. |
| description                 | NonEmptyTrimmedString240  |                |                 |               | Description: Brief description of the award. |
| awardStatus                 | PpmAwardStatus            |                |        Y        |               |  |
| awardType                   | NonEmptyTrimmedString30   |                |        Y        |               | Classification of an award, for example, Federal grants or Private grants.  Used to determine the GL Fund Code. |
| awardTypeName               | NonEmptyTrimmedString30!  |                |        Y        |               | The award type name associated with the award |
| awardPurpose                | NonEmptyTrimmedString80   |                |                 |               | Purpose: Code of the award purpose.  Used to determine the GL Purpose Code. |
| startDate                   | LocalDate                 |                |                 |               | Start Date: Start date of the award. |
| endDate                     | LocalDate                 |                |                 |               | End Date: End date of the award. |
| closeDate                   | LocalDate                 |                |        Y        |               | Close Date: Date past the end date of the award. Transactions for the award can be entered up to this date. |
| awardOwningOrganizationName | NonEmptyTrimmedString240! |                |        Y        |               | Award Owning Organization: An organization that owns awards within an enterprise. An organizing unit in the internal or external structure of your enterprise. Organization structures provide the framework for performing legal reporting, financial control, and management reporting for the award. |
| businessUnitName            | NonEmptyTrimmedString100! |                |                 |               | Business Unit: Unit of an enterprise that performs one or many business functions that can be rolled up in a management hierarchy. An award business unit is one within which the award is created. |
| legalEntityName             | NonEmptyTrimmedString240  |                |                 |               | Business entity associated with the award. |
| lastUpdateDateTime          | DateTime!                 |                |        Y        |               | The date when the award was last updated. |
| lastUpdateUserId            | ErpUserId                 |                |                 |               | The user that last updated the award. |
| awardFundingSource          | [PpmFundingSource!]!      |                |                 |               | Award Funding Sources: The Award Funding Sources resource is used to view the attributes used to create or update a funding source for the award. |
| defaultFundingSourceNumber  | PpmFundingSourceNumber    |                |                 |               | The default (usually first) funding source attached to the award.  If the funding source is left blank on a transaction, this is the one which will be auto-inserted during processing. |
| awardCfda                   | [PpmCfdaAward!]!          |                |                 |               | List of CFDA catalog numbers associated with the award.  CFDA numbers are used to identify federal assistance programs. |
| glFundCode                  | ErpFundCode               |                |                 |               | The GL Fund code which will be used when the Oracle Projects module posts to the General Ledger. |
| glPurposeCode               | ErpPurposeCode            |                |                 |               | The GL Purpose code which will be used when the Oracle Projects module posts to the General Ledger. |
| flowThruAmount              | NonNegativeFloat          |                |                 |               |  |
| flowThruFromDate            | LocalDate                 |                |                 |               |  |
| flowThruToDate              | LocalDate                 |                |                 |               |  |
| flowThruPrimarySponsorId    | Long                      |                |                 |               | Internal ID of the party associated with the flow-thru activity.  Will be linked to that data if determined necessary and available. |
| flowThruRefAwardName        | NonEmptyTrimmedString100  |                |                 |               |  |
| flowThruIsFederal           | Boolean!                  |                |                 |               |  |
| personnel                   | [PpmAwardPersonnel!]!     |                |                 |               | List of personnel associated with the award. |
| eligibleForUse              | Boolean!                  |                |                 |               | Returns whether this PpmAward is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the PpmAward must:<br/>- Have closeDate after the given accountingDate<br/>- Be active or under amendment |

* `personnel` : `[PpmAwardPersonnel!]!`
  * List of personnel associated with the award.
  * Arguments:
    * `roleName` : `NonEmptyTrimmedString60`
* `eligibleForUse` : `Boolean!`
  * Returns whether this PpmAward is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the PpmAward must:<br/>- Have closeDate after the given accountingDate<br/>- Be active or under amendment
  * Arguments:
    * `accountingDate` : `LocalDate`

##### Linked Data Objects

(None)

#### Query Operations

##### `ppmAward`

> Get a single PpmAward by id.  Returns undefined if does not exist

* **Parameters**
  * `id : NumericString!`
* **Returns**
  * `PpmAward`

##### `ppmAwardSearch`

> Search for PpmAward objects by multiple properties.
> See
> See the PpmAwardFilterInput type for options.

* **Parameters**
  * `filter : PpmAwardFilterInput!`
* **Returns**
  * `PpmAwardSearchResults!`

##### `ppmAwardByPpmAwardNumber`

> Find PpmAwards by the Oracle PPM-assigned award number.

* **Parameters**
  * `ppmAwardNumber : NonEmptyTrimmedString30!`
* **Returns**
  * `[PpmAward!]!`

##### `ppmAwardBySponsorAwardNumber`

> Find PpmAwards by the sponsor-assigned award number.

* **Parameters**
  * `awardNumber : NonEmptyTrimmedString60!`
* **Returns**
  * `[PpmAward!]!`

##### `ppmAwardByProjectNumber`

> Find PpmAwards by the project they are associated with.

* **Parameters**
  * `projectNumber : PpmProjectNumber!`
* **Returns**
  * `[PpmAward!]!`

##### `ppmAwardByPersonnelEmployeeId`

> Find PpmAward objects by active personnel.  Role name is optional.  If not passed then the award is returned if the person has any role on the project.

* **Parameters**
  * `employeeId : UcEmployeeId!`
  * `roleName : NonEmptyTrimmedString60`
* **Returns**
  * `[PpmAward!]!`

##### `ppmAwardByPersonnelEmail`

> Find PpmAward objects by active personnel.  Role name is optional.  If not passed then the award is returned if the person has any role on the project.

* **Parameters**
  * `email : EmailAddress!`
  * `roleName : NonEmptyTrimmedString60`
* **Returns**
  * `[PpmAward!]!`

##### `ppmAwardByName`

> DEPRECATED - use ppmAwardSearch instead.  Gets PpmAwards by exact name.  Returns empty list if none are found

* **Parameters**
  * `name : String!`
* **Returns**
  * `[PpmAward!]!`

##### `ppmAwardByNumber`

> DEPRECATED - use ppmAwardByPpmAwardNumber instead.  Gets PpmAwards by number.  Returns empty if not found

* **Parameters**
  * `number : String!`
* **Returns**
  * `PpmAward`

##### `ppmAwardByProjectAndAwardNumber`

> DEPRECATED - use ppmAwardSearch instead.  Gets PpmAwards by projectNumber and awardNumber.  Returns null if not found

* **Parameters**
  * `projectNumber : String!`
  * `awardNumber : String!`
* **Returns**
  * `PpmAward`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: PpmFundingSource

The Funding Source identifies the name of the sponsor for the external funding source.

**Roll-up relationship to the new Chart of Accounts in the General Ledger:**

* Funding Source values will only be used in the PPM module.
* The Funding Source will map to the correct value for the Fund segment in the CoA
  * (i.e In the examples below, NIH and USAID would map to the Federal Fund value in the Chart of Accounts)

**Examples:**

* National Institute of Health (NIH)
* U.S. Agency for International Development (USAID)

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `PPM_FUNDING_SOURCE`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object:FscmTopModelAM.GmsAwardAM.AwardFundingSourcePVO
  * Underlying Database Objects:
    * GMS_FUNDING_SOURCES_B
    * GMS_FUNDING_SOURCES_TL

##### Properties

| Property Name         | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| --------------------- | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| id                    | Long!                     |                |                 |               | Funding Source ID: The unique identifier of the funding source. |
| name                  | NonEmptyTrimmedString360! |                |        Y        |               | Funding Source Name: The source name of the funding source. |
| fundingSourceNumber   | NonEmptyTrimmedString50!  |                |        Y        |               | Funding Source Number: The number of the funding source. |
| description           | NonEmptyTrimmedString240  |                |                 |               | Funding Source Description: The description of the funding source. |
| fundingSourceFromDate | LocalDate                 |                |        Y        |               | Funding Source From Date: The date from which the funding source is active. |
| fundingSourceToDate   | LocalDate                 |                |        Y        |               | Funding Source To Date: The date till which the funding source is active. |
| fundingSourceType     | NonEmptyTrimmedString50   |                |                 |               | The funding source type name. |
| lastUpdateDateTime    | DateTime!                 |                |        Y        |               | The date when the funding source was last updated. |
| lastUpdateUserId      | ErpUserId                 |                |                 |               | The user that last updated the funding source. |
| awardId               | Long!                     |                |        Y        |               | The award id linked to the funding Source |
| eligibleForUse        | Boolean!                  |                |                 |               | Returns whether this PpmFundingSource is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the PpmFundingSource must:<br/>- Have a fundingSourceFromDate and fundingSourceToDate range which includes the given accountingDate |

* `eligibleForUse` : `Boolean!`
  * Returns whether this PpmFundingSource is valid to use on transactional documents for the given accounting date.  If not provided, the date will be defaulted to the current date.<br/><br/>To be eligible for use, the PpmFundingSource must:<br/>- Have a fundingSourceFromDate and fundingSourceToDate range which includes the given accountingDate
  * Arguments:
    * `accountingDate` : `LocalDate`

##### Linked Data Objects

(None)

#### Query Operations

##### `ppmFundingSource`

> Get a single PpmFundingSource by id.  Returns undefined if does not exist

* **Parameters**
  * `id : NumericString!`
* **Returns**
  * `PpmFundingSource`

##### `ppmFundingSourceByNumber`

> Get a single PpmFundingSource by number.  Returns undefined if does not exist

* **Parameters**
  * `fundingSourceNumber : String!`
* **Returns**
  * `PpmFundingSource`

##### `ppmFundingSourceByProjectAndFundingSourceNumber`

> Get a single PpmFundingSource by project number and funding source number.  Returns null if does not exist

* **Parameters**
  * `projectNumber : String!`
  * `fundingSourceNumber : String!`
* **Returns**
  * `PpmFundingSource`

##### `ppmFundingSourceByName`

> Gets PpmFundingSources by exact name.  Returns empty list if none are found

* **Parameters**
  * `name : String!`
* **Returns**
  * `[PpmFundingSource!]!`

##### `ppmFundingSourceSearch`

> Search for PpmFundingSource objects by multiple properties.
> See
> See the PpmFundingSourceFilterInput type for options.

* **Parameters**
  * `filter : PpmFundingSourceFilterInput!`
* **Returns**
  * `PpmFundingSourceSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.
