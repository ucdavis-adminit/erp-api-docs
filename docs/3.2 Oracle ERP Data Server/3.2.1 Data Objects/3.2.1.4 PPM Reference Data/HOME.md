# 3.2.1.4 PPM Reference Data

<!--BREAK-->
### Data Object: ErpContracts

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
| name               | NonEmptyTrimmedString150! |                |        Y        |               | Contract Name: The name of the Contract. |
| description        | NonEmptyTrimmedString240  |                |        Y        |               | Contract Description: The description for the Contract. |
| startDate          | LocalDate!                |                |                 |               | Contract start date: Start Date of the Contract |
| endDate            | LocalDate                 |                |                 |               | Contract end date: End Date of the Contract |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               | The date when the keyword was last updated. |
| lastUpdatedBy      | ErpUserId                 |                |                 |               | The user that last updated the keyword. |

##### Linked Data Objects

(None)

#### Query Operations

##### `erpContracts`

> Get a single ErpContracts by id.  Returns undefined if does not exist

* **Parameters**
  * `id : String!`
* **Returns**
  * `ErpContracts`

##### `erpContractsByName`

> Gets ErpContractss by exact name.  Returns empty list if none are found

* **Parameters**
  * `name : String!`
* **Returns**
  * `[ErpContracts!]!`

##### `erpContractsSearch`

> Search for ErpContracts objects by multiple properties.
> See
> See the ErpContractsFilterInput type for options.

* **Parameters**
  * `filter : ErpContractsFilterInput!`
* **Returns**
  * `ErpContractsSearchResults!`

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
### Data Object: PpmKeywords

Cayuse support - non-segment data objects needed for submission of project and grant data
Needed for to manage keywords for lookup table

#### Access Controls

* Required Role: ``

#### Data Source

* Local Table/View: `undefined`

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| id                 | Long!                     |                |                 |               | ID: The unique identifier of the keyword. |
| name               | NonEmptyTrimmedString150! |                |        Y        |               | Keyword Name: The name of the keyword. |
| description        | NonEmptyTrimmedString240  |                |        Y        |               | Keyword Description: The description for the Keyword. |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               | The date when the keyword was last updated. |
| lastUpdatedBy      | ErpUserId                 |                |                 |               | The user that last updated the keyword. |

##### Linked Data Objects

(None)

#### Query Operations

##### `ppmKeywords`

> Get a single PpmKeywords by id.  Returns undefined if does not exist

* **Parameters**
  * `id : String!`
* **Returns**
  * `PpmKeywords`

##### `ppmKeywordsByName`

> Gets PpmKeywordss by exact name.  Returns empty list if none are found

* **Parameters**
  * `name : String!`
* **Returns**
  * `[PpmKeywords!]!`

##### `ppmKeywordsSearch`

> Search for PpmKeywords objects by multiple properties.
> See
> See the PpmKeywordsFilterInput type for options.

* **Parameters**
  * `filter : PpmKeywordsFilterInput!`
* **Returns**
  * `PpmKeywordsSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: PpmTerms

Cayuse support - non-segment data objects needed for submission of project and grant data
Needed for to manage Terms and Conditions for lookup table

#### Access Controls

* Required Role: ``

#### Data Source

* Local Table/View: `undefined`

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
  * `id : String!`
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
