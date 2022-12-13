# 3.2.1.7 FA Reference Data

<!--BREAK-->
### Data Object: FaAcquisitionCode



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `FA_ACQUISITION_CODE` (view)
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
  * Underlying Database Objects:
    * 

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | NonEmptyTrimmedString150! |                |        Y        |               |  |
| id                 | Long!                     |                |                 |               |  |
| name               | NonEmptyTrimmedString240! |                |                 |               |  |
| enabled            | Boolean!                  |                |        Y        |               |  |
| startDate          | LocalDate                 |                |                 |               |  |
| endDate            | LocalDate                 |                |                 |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `faAcquisitionCode`

> Get a single FaAcquisitionCode by id.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `FaAcquisitionCode`

##### `faAcquisitionCodeSearch`

> Search for FaAcquisitionCode objects by multiple properties.
> 
> See the FaAcquisitionCodeFilterInput type for options.

* **Parameters**
  * `filter : FaAcquisitionCodeFilterInput!`
* **Returns**
  * `FaAcquisitionCodeSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: FaAsset



#### Access Controls

* Required Role: `erp:reader-fixedasset`

#### Data Source

* Local Table/View: `FA_ASSET_V`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * FscmTopModelAM.FinExtractAM.FaBiccExtractAM.AdditionExtractPVO
  * Underlying Database Objects:
    * FA_ADDITIONS_VL
    * FA_ADDITIONS_B
    * FA_ADDITIONS_TL

##### Properties

| Property Name           | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ----------------------- | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| assetId                 | Long!                     |                |                 |               | Internal Oracle Identifier for this asset |
| assetNumber             | NonEmptyTrimmedString30!  |                |        Y        |               | Sequential ID number assigned to the asset and visible within Oracle. |
| assetTagNumber          | NonEmptyTrimmedString15!  |                |        Y        |               | UC-Assigned Tag Number for the asset |
| assetType               | NonEmptyTrimmedString15!  |                |        Y        |               |  |
| assetCategoryId         | Long!                     |                |                 |               |  |
| description             | NonEmptyTrimmedString80   |                |        Y        |               |  |
| manufacturerName        | NonEmptyTrimmedString360  |                |                 |               |  |
| serialNumber            | NonEmptyTrimmedString40   |                |                 |               |  |
| modelNumber             | NonEmptyTrimmedString40   |                |                 |               |  |
| minorCategory           | NonEmptyTrimmedString150! |                |                 |               |  |
| campusCode              | NonEmptyTrimmedString150! |                |                 |               |  |
| buildingCode            | NonEmptyTrimmedString150! |                |        Y        |               |  |
| roomCode                | NonEmptyTrimmedString150  |                |                 |               |  |
| alternateAddress        | NonEmptyTrimmedString150  |                |                 |               |  |
| custodialDivisionCode   | NonEmptyTrimmedString150! |                |        Y        |               |  |
| custodialDepartmentCode | NonEmptyTrimmedString150! |                |        Y        |               |  |
| assetRepresentativeName | NonEmptyTrimmedString150  |                |                 |               |  |
| titleFlag               | Boolean!                  |                |                 |               |  |
| totalCost               | Float                     |                |                 |               | The current recorded cost of the asset.  See costHistory for a history of cost changes. |
| acquisitionCode         | NonEmptyTrimmedString150! |                |                 |               |  |
| primaryFundCode         | NonEmptyTrimmedString150! |                |                 |               |  |
| equipFundSourceCode     | NonEmptyTrimmedString150! |                |                 |               |  |
| conditionCode           | NonEmptyTrimmedString150! |                |        Y        |               |  |
| equipLoanCode           | NonEmptyTrimmedString150  |                |                 |               |  |
| lastCertificationDate   | LocalDate                 |                |                 |               |  |
| piName                  | String                    |                |                 |               |  |
| sponsorName             | NonEmptyTrimmedString150  |                |                 |               |  |
| loanDetail              | NonEmptyTrimmedString150  |                |                 |               |  |
| warrantyInfo            | NonEmptyTrimmedString150  |                |                 |               |  |
| hospitalAssetNumber     | NonEmptyTrimmedString150  |                |                 |               |  |
| creationDate            | DateTime!                 |                |                 |               |  |
| lastUpdateUserId        | ErpUserId                 |                |                 |               |  |
| lastUpdateDateTime      | DateTime!                 |                |        Y        |               |  |
| acquisitionCodeInfo     | FaAcquisitionCode         |                |                 |               |  |
| custodialDivisionInfo   | FaCustodialDivision       |                |                 |               |  |
| custodialDepartmentInfo | FaCustodialDepartment     |                |                 |               |  |
| campusInfo              | ErpCampus                 |                |                 |               |  |
| buildingInfo            | ErpBuilding               |                |                 |               |  |
| roomInfo                | ErpBuildingRoom           |                |                 |               |  |
| conditionCodeInfo       | FaCondition               |                |                 |               |  |
| equipFundSourceInfo     | FaFundSource              |                |                 |               |  |
| equipLoanInfo           | FaLoanCode                |                |                 |               |  |
| minorCategoryInfo       | FaMinorCategory           |                |                 |               |  |
| primaryFundInfo         | ErpFundSource             |                |                 |               |  |
| costHistory             | [FaAssetCostHistory!]!    |                |                 |               |  |

* `acquisitionCodeInfo` : `FaAcquisitionCode`
* `custodialDivisionInfo` : `FaCustodialDivision`
* `custodialDepartmentInfo` : `FaCustodialDepartment`
* `campusInfo` : `ErpCampus`
* `buildingInfo` : `ErpBuilding`
* `roomInfo` : `ErpBuildingRoom`
* `conditionCodeInfo` : `FaCondition`
* `equipFundSourceInfo` : `FaFundSource`
* `equipLoanInfo` : `FaLoanCode`
* `minorCategoryInfo` : `FaMinorCategory`
* `primaryFundInfo` : `ErpFundSource`

##### Linked Data Objects

(None)

#### Query Operations

##### `faAsset`

> Get a single FaAsset by id.  Returns undefined if does not exist

* **Parameters**
  * `id : String!`
* **Returns**
  * `FaAsset`

##### `faAssetSearch`

> Search for FaAsset objects by multiple properties.
> 
> See the FaAssetFilterInput type for options.

* **Parameters**
  * `filter : FaAssetFilterInput!`
* **Returns**
  * `FaAssetSearchResults!`

##### `faAssetByAssetTagNumber`

> undefined

* **Parameters**
  * `assetTagNumber : String!`
* **Returns**
  * `FaAsset`

##### `faAssetByAssetNumber`

> undefined

* **Parameters**
  * `assetNumber : String!`
* **Returns**
  * `FaAsset`

##### `faAssetCategory`

> Get a single FaAssetCategory by id.  Returns undefined if does not exist

* **Parameters**
  * `id : String!`
* **Returns**
  * `FaAssetCategory`

##### `faAssetCategorySearch`

> Search for FaAssetCategory objects by multiple properties.
> 
> See the FaAssetCategoryFilterInput type for options.

* **Parameters**
  * `filter : FaAssetCategoryFilterInput!`
* **Returns**
  * `FaAssetCategorySearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: FaAssetCategory



#### Access Controls

* Required Role: ``

#### Data Source

* Local Table/View: `FA_ASSET_CATEGORY`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * file_fscmtopmodelam_finextractam_fabiccextractam_categoryextractpvo
  * Underlying Database Objects:

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| assetCategoryId    | Long!                     |                |        Y        |               |  |
| name               | NonEmptyTrimmedString240! |                |        Y        |               |  |
| enabled            | Boolean!                  |                |        Y        |               |  |
| inventorialFlag    | Boolean!                  |                |                 |               |  |
| capitalizeFlag     | Boolean!                  |                |                 |               |  |
| propertyTypeCode   | NonEmptyTrimmedString150! |                |                 |               |  |
| categoryType       | NonEmptyTrimmedString150! |                |                 |               |  |
| majorCategoryCode  | NonEmptyTrimmedString150! |                |                 |               |  |
| minorCategoryCode  | NonEmptyTrimmedString150! |                |                 |               |  |
| ownedOrLeasedCode  | NonEmptyTrimmedString150! |                |                 |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `faAssetCategory`

> Get a single FaAssetCategory by id.  Returns undefined if does not exist

* **Parameters**
  * `id : String!`
* **Returns**
  * `FaAssetCategory`

##### `faAssetCategorySearch`

> Search for FaAssetCategory objects by multiple properties.
> 
> See the FaAssetCategoryFilterInput type for options.

* **Parameters**
  * `filter : FaAssetCategoryFilterInput!`
* **Returns**
  * `FaAssetCategorySearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: FaAssetCostHistory



#### Access Controls

* Required Role: `erp:reader-fixedasset`

#### Data Source

* Local Table/View: `FA_ASSET_COST_HISTORY`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * FscmTopModelAM.FinExtractAM.FaBiccExtractAM.BookExtractPVO
  * Underlying Database Objects:
    * FA_BOOKS

##### Properties

| Property Name      | Data Type               | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ----------------------- | :------------: | :-------------: | ------------- | ----- |
| assetId            | Long                    |                |                 |               |  |
| typeCode           | NonEmptyTrimmedString30 |                |                 |               |  |
| headerId           | Long                    |                |                 |               |  |
| serviceDate        | LocalDate               |                |                 |               |  |
| totalCost          | Float                   |                |                 |               |  |
| effectiveDate      | LocalDate               |                |                 |               |  |
| ineffectiveDate    | LocalDate               |                |                 |               |  |
| creationDate       | DateTime                |                |                 |               |  |
| lastUpdateUserId   | ErpUserId               |                |                 |               |  |
| lastUpdateDateTime | DateTime                |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: FaAssetDistributionHistory



#### Access Controls

* Required Role: `erp:reader-fixedasset`

#### Data Source

* Local Table/View: `FA_ASSET_DISTRIBUTION_HISTORY`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * file_fscmtopmodelam_finextractam_fabiccextractam_distributionhistoryextractpvo
  * Underlying Database Objects:

##### Properties

| Property Name         | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| --------------------- | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| assetId               | Long!                     |                |                 |               |  |
| distributionId        | Long!                     |                |                 |               |  |
| bookTypeCode          | NonEmptyTrimmedString240! |                |                 |               |  |
| deprCodeCombinationId | Long!                     |                |                 |               |  |
| effectiveDate         | DateTime!                 |                |                 |               |  |
| ineffectiveDate       | DateTime!                 |                |                 |               |  |
| unitsAssigned         | Long!                     |                |                 |               |  |
| lastUpdateUserId      | ErpUserId                 |                |                 |               |  |
| lastUpdateDateTime    | DateTime!                 |                |        Y        |               |  |

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: FaCondition



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `FA_CONDITION` (view)
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
  * Underlying Database Objects:
    * 

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | NonEmptyTrimmedString150! |                |        Y        |               |  |
| id                 | Long!                     |                |                 |               |  |
| name               | NonEmptyTrimmedString240! |                |                 |               |  |
| enabled            | Boolean!                  |                |        Y        |               |  |
| startDate          | LocalDate                 |                |                 |               |  |
| endDate            | LocalDate                 |                |                 |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `faCondition`

> Get a single FaCondition by id.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `FaCondition`

##### `faConditionSearch`

> Search for FaCondition objects by multiple properties.
> 
> See the FaConditionFilterInput type for options.

* **Parameters**
  * `filter : FaConditionFilterInput!`
* **Returns**
  * `FaConditionSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: FaCustodialDepartment



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `FA_CUSTODIAL_DEPARTMENT` (view)
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
  * Underlying Database Objects:
    * 

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | NonEmptyTrimmedString150! |                |        Y        |               |  |
| id                 | Long!                     |                |                 |               |  |
| name               | NonEmptyTrimmedString240! |                |                 |               |  |
| enabled            | Boolean!                  |                |        Y        |               |  |
| startDate          | LocalDate                 |                |                 |               |  |
| endDate            | LocalDate                 |                |                 |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `faCustodialDepartment`

> Get a single FaCustodialDepartment by id.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `FaCustodialDepartment`

##### `faCustodialDepartmentSearch`

> Search for FaCustodialDepartment objects by multiple properties.
> 
> See the FaCustodialDepartmentFilterInput type for options.

* **Parameters**
  * `filter : FaCustodialDepartmentFilterInput!`
* **Returns**
  * `FaCustodialDepartmentSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: FaCustodialDivision



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `FA_CUSTODIAL_DIVISION` (view)
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
  * Underlying Database Objects:
    * 

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | NonEmptyTrimmedString150! |                |        Y        |               |  |
| id                 | Long!                     |                |                 |               |  |
| name               | NonEmptyTrimmedString240! |                |                 |               |  |
| enabled            | Boolean!                  |                |        Y        |               |  |
| startDate          | LocalDate                 |                |                 |               |  |
| endDate            | LocalDate                 |                |                 |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `faCustodialDivision`

> Get a single FaCustodialDivision by id.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `FaCustodialDivision`

##### `faCustodialDivisionSearch`

> Search for FaCustodialDivision objects by multiple properties.
> 
> See the FaCustodialDivisionFilterInput type for options.

* **Parameters**
  * `filter : FaCustodialDivisionFilterInput!`
* **Returns**
  * `FaCustodialDivisionSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: FaFundSource



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `FA_FUND_SOURCE` (view)
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
  * Underlying Database Objects:
    * 

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | NonEmptyTrimmedString150! |                |        Y        |               |  |
| id                 | Long!                     |                |                 |               |  |
| name               | NonEmptyTrimmedString240! |                |                 |               |  |
| enabled            | Boolean!                  |                |        Y        |               |  |
| startDate          | LocalDate                 |                |                 |               |  |
| endDate            | LocalDate                 |                |                 |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `faFundSource`

> Get a single FaFundSource by id.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `FaFundSource`

##### `faFundSourceSearch`

> Search for FaFundSource objects by multiple properties.
> 
> See the FaFundSourceFilterInput type for options.

* **Parameters**
  * `filter : FaFundSourceFilterInput!`
* **Returns**
  * `FaFundSourceSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: FaLoanCode



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `FA_LOAN_CODE` (view)
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
  * Underlying Database Objects:
    * 

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | NonEmptyTrimmedString150! |                |        Y        |               |  |
| id                 | Long!                     |                |                 |               |  |
| name               | NonEmptyTrimmedString240! |                |                 |               |  |
| enabled            | Boolean!                  |                |        Y        |               |  |
| startDate          | LocalDate                 |                |                 |               |  |
| endDate            | LocalDate                 |                |                 |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `faLoanCode`

> Get a single FaLoanCode by id.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `FaLoanCode`

##### `faLoanCodeSearch`

> Search for FaLoanCode objects by multiple properties.
> 
> See the FaLoanCodeFilterInput type for options.

* **Parameters**
  * `filter : FaLoanCodeFilterInput!`
* **Returns**
  * `FaLoanCodeSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: FaLocation



#### Access Controls

* Required Role: `erp:reader-fixedasset`

#### Data Source

* Local Table/View: `FA_LOCATION`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * file_fscmtopmodelam_finextractam_fabiccextractam_locationextractpvo
  * Underlying Database Objects:

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| locationId         | Long!                     |                |                 |               |  |
| propertyTypeCode   | NonEmptyTrimmedString150! |                |                 |               |  |
| campusCode         | NonEmptyTrimmedString150! |                |                 |               |  |
| buildingCode       | NonEmptyTrimmedString150! |                |                 |               |  |
| roomCode           | NonEmptyTrimmedString150! |                |                 |               |  |
| address            | NonEmptyTrimmedString240! |                |                 |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |
| lastUpdateDateTime | DateTime!                 |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: FaMajorCategory



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `FA_MAJOR_CATEGORY` (view)
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
  * Underlying Database Objects:
    * 

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | NonEmptyTrimmedString150! |                |        Y        |               |  |
| id                 | Long!                     |                |                 |               |  |
| name               | NonEmptyTrimmedString240! |                |                 |               |  |
| enabled            | Boolean!                  |                |        Y        |               |  |
| startDate          | LocalDate                 |                |                 |               |  |
| endDate            | LocalDate                 |                |                 |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `faMajorCategory`

> Get a single FaMajorCategory by id.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `FaMajorCategory`

##### `faMajorCategorySearch`

> Search for FaMajorCategory objects by multiple properties.
> 
> See the FaMajorCategoryFilterInput type for options.

* **Parameters**
  * `filter : FaMajorCategoryFilterInput!`
* **Returns**
  * `FaMajorCategorySearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: FaMinorCategory



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `FA_MINOR_CATEGORY` (view)
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
  * Underlying Database Objects:
    * 

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | NonEmptyTrimmedString150! |                |        Y        |               |  |
| id                 | Long!                     |                |                 |               |  |
| name               | NonEmptyTrimmedString240! |                |                 |               |  |
| enabled            | Boolean!                  |                |        Y        |               |  |
| startDate          | LocalDate                 |                |                 |               |  |
| endDate            | LocalDate                 |                |                 |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `faMinorCategory`

> Get a single FaMinorCategory by id.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `FaMinorCategory`

##### `faMinorCategorySearch`

> Search for FaMinorCategory objects by multiple properties.
> 
> See the FaMinorCategoryFilterInput type for options.

* **Parameters**
  * `filter : FaMinorCategoryFilterInput!`
* **Returns**
  * `FaMinorCategorySearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: FaProgram



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `FA_PROGRAM` (view)
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
  * Underlying Database Objects:
    * 

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | NonEmptyTrimmedString150! |                |        Y        |               |  |
| id                 | Long!                     |                |                 |               |  |
| name               | NonEmptyTrimmedString240! |                |                 |               |  |
| enabled            | Boolean!                  |                |        Y        |               |  |
| startDate          | LocalDate                 |                |                 |               |  |
| endDate            | LocalDate                 |                |                 |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `faProgram`

> Get a single FaProgram by id.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `FaProgram`

##### `faProgramSearch`

> Search for FaProgram objects by multiple properties.
> 
> See the FaProgramFilterInput type for options.

* **Parameters**
  * `filter : FaProgramFilterInput!`
* **Returns**
  * `FaProgramSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.
