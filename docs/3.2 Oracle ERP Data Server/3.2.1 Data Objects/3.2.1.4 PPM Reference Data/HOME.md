# 3.2.1.4 PPM Reference Data

<!--BREAK-->
### Data Object: ErpContract

Cayuse support - non-segment data objects needed for submission of project and grant data
Needed for to manage grants and contracts for lookup table

#### Access Controls

* Required Role: ``

#### Data Source

* Local Table/View: `undefined`

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| id                 | Long!                     |                |                 |               | ID: The unique identifier of the contract. |
| contractNumber     | NonEmptyTrimmedString60!  |                |        Y        |               |  |
| name               | NonEmptyTrimmedString150! |                |        Y        |               | Contract Name: The name of the Contract. |
| contractTypeName   | NonEmptyTrimmedString240! |                |        Y        |               | Contract Description: The description for the Contract. |
| startDate          | LocalDate!                |                |                 |               | Contract start date: Start Date of the Contract |
| endDate            | LocalDate                 |                |                 |               | Contract end date: End Date of the Contract |
| lastUpdatedBy      | ErpUserId                 |                |                 |               | The user that last updated the keyword. |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               | The date when the keyword was last updated. |

##### Linked Data Objects

(None)

#### Query Operations

##### `erpContract`

> Get a single ErpContract by id.  Returns undefined if does not exist

* **Parameters**
  * `id : String!`
* **Returns**
  * `ErpContract`

##### `erpContractByName`

> Gets ErpContracts by exact name.  Returns empty list if none are found

* **Parameters**
  * `name : String!`
* **Returns**
  * `[ErpContract!]!`

##### `erpContractSearch`

> Search for ErpContract objects by multiple properties.
> See
> See the ErpContractFilterInput type for options.

* **Parameters**
  * `filter : ErpContractFilterInput!`
* **Returns**
  * `ErpContractSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: PpmAccountingPeriod

Represents an accounting period in Oracle Financials.  Used for validation of submitted journal entry data.

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `PPM_PERIOD` (view)
  * Support Tables:
    * `ERP_PERIOD`
    * `ERP_PERIOD_CUTOFF_DATES`
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
| periodName            | ErpAccountingPeriodName! |                |        Y        |               | The unique name of a ERP Accounting Period |
| periodYear            | PositiveInt!             |                |        Y        |               | Fiscal year this period belongs to. |
| periodNumber          | PositiveInt!             |                |        Y        |               | Integer number of the period within the year. |
| periodStatus          | ErpPeriodStatus!         |                |        Y        |               | Current Status of the Period.  Only Open (O) and Future Enterable (F) are valid on submission of documents. |
| adjustmentPeriod      | Boolean!                 |                |        Y        |               | Whether this is an period used for adjusting the balances prior to fiscal closing. |
| startDate             | LocalDate!               |                |        Y        |               | Start date of the period. |
| endDate               | LocalDate!               |                |        Y        |               | End date of the period. |
| yearStartDate         | LocalDate!               |                |                 |               | Start date of the fiscal year this period belongs to. |
| quarterStartDate      | LocalDate!               |                |                 |               | Start date of the fiscal quarter this period belongs to. |
| quarterNumber         | PositiveInt!             |                |                 |               | Integer number of the period within the fiscal year. |
| effectivePeriodNumber | PositiveInt!             |                |                 |               | Unique numeric representation of the period used for sorting periods in order. |
| journalCutoffDate     | LocalDate                |                |                 |               | Last day that journals may be submitted for this accounting period. |
| lastUpdateDateTime    | DateTime!                |                |        Y        |               |  |
| lastUpdateUserId      | ErpUserId                |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `ppmAccountingPeriod`

> Get a single PpmAccountingPeriod by its name.  Returns undefined if does not exist

* **Parameters**
  * `periodName : String!`
* **Returns**
  * `PpmAccountingPeriod`

##### `ppmAccountingPeriodByDate`

> Get a single non-adjustment PpmAccountingPeriod by the given date.  Returns undefined if no period is defined for the given date.

* **Parameters**
  * `accountingDate : Date!`
* **Returns**
  * `PpmAccountingPeriod`

##### `ppmAccountingPeriodSearch`

> Search for PpmAccountingPeriod objects by multiple properties.
> See
> See the PpmAccountingPeriodFilterInput type for options.

* **Parameters**
  * `filter : PpmAccountingPeriodFilterInput!`
* **Returns**
  * `PpmAccountingPeriodSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: PpmAwardPersonnel



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `PPM_AWARD_PERSONNEL`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.GmsAwardAM.AwardPersonnelPVO
  * Underlying Database Objects:
    * GMS_AWARD_PERSONNEL
    * GMS_AWARD_EXTERNAL_CONTACTS_V (VIEW)
    * GMS_INTERNAL_CONTACTS_V (VIEW)
    * GMS_ROLES_V (VIEW)
    * GMS_PERSONS
    * GMS_AWARD_PROJECTS

##### Properties

| Property Name | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------- | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| personId      | Long!                     |       Y        |                 |               | Unique identifier of the person.  Internal to Oracle. |
| employeeId    | UcEmployeeId!             |                |                 |               | UCPath Employee ID of the person associated with the award. |
| name          | NonEmptyTrimmedString360! |                |                 |               | Display Name of the person associated with the award. |
| roleName      | NonEmptyTrimmedString240! |                |                 |               | Person's Role on the award.  E.g., Principal Investigator, Grants Administrator, Project Administrator, etc. |
| email         | EmailAddress!             |                |                 |               | Person's Email Address. |
| jobTitle      | NonEmptyTrimmedString240! |                |                 |               | Person's Job Title as extracted from UCPath. |
| creditPercent | NonNegativeFloat          |                |                 |               |  |
| person        | ErpUser                   |                |                 |               | Person record associated with this team member.  May contain additional information about the person. |

* `person` : `ErpUser`
  * Person record associated with this team member.  May contain additional information about the person.
  * Description of `ErpUser`:
    * A user as known to the ERP application.

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: PpmCfda

CFDA

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `PPM_CFDA`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.GmsSetupAM.CFDAViewPVO
  * Underlying Database Objects:
    * 

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| cfda               | NonEmptyTrimmedString30!  |                |        Y        |               |  |
| assistanceType     | NonEmptyTrimmedString2000 |                |                 |               |  |
| programTitle       | NonEmptyTrimmedString255  |                |        Y        |               |  |
| creationDate       | DateTime                  |                |                 |               |  |
| lastUpdateDateTime | DateTime                  |                |        Y        |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `ppmCfda`

> undefined

* **Parameters**
  * `cfda : String!`
* **Returns**
  * `PpmCfda`

##### `ppmCfdaSearch`

> undefined

* **Parameters**
  * `filter : PpmCfdaFilterInput!`
* **Returns**
  * `PpmCfdaSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: PpmCfdaAward

CFDAAward

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `PPM_AWARD_CFDA`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.GmsAwardAM.AwardCFDAPVO
  * Underlying Database Objects:
    * 

##### Properties

| Property Name      | Data Type               | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ----------------------- | :------------: | :-------------: | ------------- | ----- |
| id                 | Long!                   |                |                 |               |  |
| cfda               | NonEmptyTrimmedString30 |                |                 |               |  |
| awardId            | Long                    |                |                 |               |  |
| creationDate       | DateTime                |                |                 |               |  |
| lastUpdateDateTime | DateTime                |                |                 |               |  |
| lastUpdateUserId   | ErpUserId               |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: PpmDocumentEntry

PpmDocumentEntry is used to store the document entries.

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `PPM_DOCUMENT_ENTRY`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object:  FscmTopModelAM.PrjExtractAM.PjfBiccExtractAM.TransactionDocumentEntryExtractPVO
  * Underlying Database Objects:
    * PJF_TXN_DOC_ENTRY_B_PK
    * PJF_TXN_DOC_ENTRY_TL

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| id                 | Long!                     |                |                 |               | Document Entry ID: The unique identifier of the funding source. |
| documentId         | Long!                     |                |                 |               | Document Id: The document identifier. |
| name               | NonEmptyTrimmedString150! |                |        Y        |               | Document Name: The name of the Document Entry. |
| code               | NonEmptyTrimmedString150! |                |        Y        |               | Document Code: The document code of the Document Entry. |
| description        | NonEmptyTrimmedString240  |                |        Y        |               | Document Description: The description for the Document Entry. |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               | The date when the funding source was last updated. |
| lastUpdatedBy      | ErpUserId                 |                |                 |               | The user that last updated the funding source. |

##### Linked Data Objects

(None)

#### Query Operations

##### `ppmDocumentEntry`

> Get a single PpmDocumentEntry by id.  Returns undefined if does not exist

* **Parameters**
  * `id : String!`
* **Returns**
  * `PpmDocumentEntry`

##### `ppmDocumentEntryByName`

> Gets PpmDocumentEntrys by exact name.  Returns empty list if none are found

* **Parameters**
  * `name : String!`
* **Returns**
  * `[PpmDocumentEntry!]!`

##### `ppmDocumentEntrySearch`

> Search for PpmDocumentEntry objects by multiple properties.
> See
> See the PpmDocumentEntryFilterInput type for options.

* **Parameters**
  * `filter : PpmDocumentEntryFilterInput!`
* **Returns**
  * `PpmDocumentEntrySearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: PpmProjectTeamMember

Person Associated with a PPM Project.  Identifies the person and their role on the project.

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `PPM_PROJECT_TEAM_MEMBER`
  * Support Tables:
    * `PPM_PROJECT`
* Data Origin:
  * System: Oracle BIPublisher
  * Extract Objects:
    * Report: PPM_Team_Member_Extract_RPT
  * Underlying Database Objects:
    * PJF_PROJ_ALL_MEMBERS_V (VIEW)
    * PJF_PROJ_ROLE_TYPES_V (VIEW)
    * PER_ALL_PEOPLE_F

##### Properties

| Property Name | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------- | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| personId      | Long!                     |       Y        |                 |               | Unique identifier of the person.  Internal to Oracle. |
| employeeId    | UcEmployeeId!             |                |                 |               | UCPath Employee ID of the person associated with the project. |
| name          | NonEmptyTrimmedString360! |                |                 |               | Display Name of the person associated with the project. |
| roleName      | NonEmptyTrimmedString240! |                |                 |               | Person's Role on the project.  E.g., Principal Investigator, Project Administrator, Project Manager, Co-Principal Investigator, etc. |
| email         | EmailAddress!             |                |                 |               | Person's Email Address. |
| jobTitle      | NonEmptyTrimmedString240! |                |                 |               | Person's Job Title as extracted from UCPath. |
| startDate     | LocalDate!                |                |                 |               | Start Date of the person's association with the project. |
| endDate       | LocalDate                 |                |                 |               | End Date of the person's association with the project.  Usually null for current team members. |
| person        | ErpUser                   |                |                 |               | Person record associated with this team member.  May contain additional information about the person. |

* `person` : `ErpUser`
  * Person record associated with this team member.  May contain additional information about the person.
  * Description of `ErpUser`:
    * A user as known to the ERP application.

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

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: PpmSponsor

PPM Sponsor reference for use with sponsored project awards.

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `PPM_SPONSOR`
* Data Origin:
  * System: Oracle BIPublisher
  * Extract Objects:
    * /Custom/Interfaces/Data Extracts/PPM_Sponsor_RPT.xdo
  * Underlying Database Objects:
    * GMS_SPONSORS_VL
    * GMS_SPONSOR_ACCT_DETAILS_B
    * HZ_PARTIES
    * HZ_CUST_ACCOUNTS

##### Properties

| Property Name        | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| -------------------- | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| sponsorId            | Long!                     |                |        Y        |               |  |
| name                 | NonEmptyTrimmedString240! |                |        Y        |               |  |
| sponsorNumber        | NonEmptyTrimmedString30!  |                |        Y        |               |  |
| accountNumber        | NonEmptyTrimmedString240  |                |        Y        |               |  |
| accountName          | NonEmptyTrimmedString30   |                |        Y        |               |  |
| letterOfCreditNumber | NonEmptyTrimmedString240  |                |        Y        |               |  |
| isLetterOfCredit     | Boolean!                  |                |                 |               |  |
| isFederal            | Boolean!                  |                |        Y        |               |  |
| address1             | NonEmptyTrimmedString240  |                |                 |               |  |
| address2             | NonEmptyTrimmedString240  |                |                 |               |  |
| address3             | NonEmptyTrimmedString240  |                |                 |               |  |
| address4             | NonEmptyTrimmedString240  |                |                 |               |  |
| city                 | NonEmptyTrimmedString60   |                |                 |               |  |
| state                | NonEmptyTrimmedString60   |                |                 |               |  |
| postalCode           | NonEmptyTrimmedString60   |                |                 |               |  |
| country              | ErpCountryCode            |                |                 |               |  |
| references           | [PpmSponsorReference!]!   |                |                 |               |  |
| creationDate         | DateTime!                 |                |                 |               |  |
| lastUpdateDateTime   | DateTime!                 |                |        Y        |               |  |
| lastUpdateUserId     | ErpUserId                 |                |                 |               |  |
| partyId              | Long!                     |                |                 |               |  |
| burdenScheduleId     | Long                      |                |                 |               |  |
| billToSponsorId      | Long                      |                |                 |               |  |
| statusCode           | NonEmptyTrimmedString30   |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `ppmSponsor`

> undefined

* **Parameters**
  * `sponsorId : String!`
* **Returns**
  * `PpmSponsor`

##### `ppmSponsorByNumber`

> undefined

* **Parameters**
  * `sponsorNumber : NonEmptyTrimmedString30!`
* **Returns**
  * `PpmSponsor`

##### `ppmSponsorSearch`

> undefined

* **Parameters**
  * `filter : PpmSponsorFilterInput!`
* **Returns**
  * `PpmSponsorSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: PpmSponsorReference

SPONSOR REFERENCE

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `PPM_SPONSOR_REFERENCE`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object:FscmTopModelAM.GmsSetupAM.SponsorReferencePVO
  * Underlying Database Objects:
    * GMS_SPONSORS_REFERENCES_B
    * GMS_SPONSORS_REFERENCES_TL
    * GMS_REFERENCES_B
    * GMS_REFERENCES_TL
    * GMS_SPONSORS_REFERENCES_VL
    * GMS_REFERENCES_VL

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| id                 | Long!                     |                |                 |               |  |
| sponsorId          | Long!                     |                |                 |               |  |
| referenceTypeName  | NonEmptyTrimmedString80!  |                |                 |               |  |
| referenceValue     | NonEmptyTrimmedString80   |                |                 |               |  |
| comments           | NonEmptyTrimmedString2000 |                |                 |               |  |
| lastUpdateDateTime | DateTime!                 |                |                 |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: PpmTerms

Cayuse support - non-segment data objects needed for submission of project and grant data
Needed for to manage Terms and Conditions for lookup table

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `PPM_TERMS`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.GmsSetupAM.TermsViewPVO
  * Underlying Database Objects:
    * GMS_TERMS_TL

##### Properties

| Property Name       | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------- | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| id                  | Long!                     |                |                 |               | ID: The unique identifier of the term. |
| name                | NonEmptyTrimmedString150! |                |        Y        |               | Term Name: The name of the Term. |
| description         | NonEmptyTrimmedString240  |                |        Y        |               | Term Description: The description for the Term. |
| startDate           | LocalDate!                |                |                 |               | Term start date: Start Date of the term |
| endDate             | LocalDate                 |                |                 |               | Term end date: End Date of the term |
| categoryName        | NonEmptyTrimmedString150! |                |        Y        |               | Category Name: The category name of the Term |
| categoryDescription | NonEmptyTrimmedString240  |                |                 |               | Category Description: The category description of the Term |
| lastUpdateDateTime  | DateTime                  |                |        Y        |               | The date when the keyword was last updated. |
| lastUpdateUserId    | ErpUserId                 |                |                 |               | The user that last updated the term. |

##### Linked Data Objects

(None)

#### Query Operations

##### `ppmTerms`

> Get a single PpmTerms by id.  Returns undefined if does not exist

* **Parameters**
  * `id : NumericString!`
* **Returns**
  * `PpmTerms`

##### `ppmTermsByName`

> Gets PpmTermss by category name and name.  Returns undefined if none are found

* **Parameters**
  * `categoryName : String!`
  * `name : String!`
* **Returns**
  * `PpmTerms`

##### `ppmTermsCategories`

> Gets PpmTermss by distinct category code.  Returns empty list if none are found

* **Parameters**
* **Returns**
  * `[PpmTerms!]!`

##### `ppmTermsSearch`

> Search for PpmTerms objects by multiple properties.
> See
> See the PpmTermsFilterInput type for options.

* **Parameters**
  * `filter : PpmTermsFilterInput!`
* **Returns**
  * `PpmTermsSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.
