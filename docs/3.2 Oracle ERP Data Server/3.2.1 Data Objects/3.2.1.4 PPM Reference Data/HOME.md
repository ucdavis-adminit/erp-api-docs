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
| creationFate       | DateTime                |                |                 |               |  |
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
| lastUpdatedBy       | ErpUserId                 |                |                 |               | The user that last updated the term. |

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
