# 3.2.1.4 PPM Reference Data

<!--BREAK-->
### Data Object: PpmDocumentEntry



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `PPM_DOCUMENT_ENTRY`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: file_fscmtopmodelam_prjextractam_pjfbiccextractam_transactiondocumententryextractpvo-batch1202213867-20220201_001135
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
