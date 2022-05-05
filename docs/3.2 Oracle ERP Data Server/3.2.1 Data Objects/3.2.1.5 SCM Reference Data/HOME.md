# 3.2.1.5 SCM Reference Data

<!--BREAK-->
### Data Object: ScmPaymentTerm



#### Access Controls

* Required Role: `erp:reader-supplier`

#### Data Source

* Local Table/View: `SCM_PAYMENT_TERM` (view)
  * Support Tables:
    * `SCM_TERMS_TL`
    * `SCM_TERMS_B`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View: FscmTopModelAM.FinExtractAM.ApBiccExtractAM.PaymentTermHeaderTranslationExtractPVO
    * View: FscmTopModelAM.FinExtractAM.ApBiccExtractAM.PaymentTermHeaderExtractPVO
  * Underlying Database Objects:
    * AP_TERMS_B
    * AP_TERMS_TL

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| termId             | Long!                     |                |                 |               |  |
| name               | NonEmptyTrimmedString50!  |                |        Y        |               |  |
| description        | NonEmptyTrimmedString240! |                |                 |               |  |
| startDateActive    | Date                      |                |                 |               | The date from when the value is available for use. |
| endDateActive      | Date                      |                |                 |               | The date till which the value is available for use. |
| enabled            | Boolean!                  |                |        Y        |               | Indicates that the Payment Term is enabled. |
| termType           | NonEmptyTrimmedString15   |                |                 |               | Specifies the type of payment terms. |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               | Timestamp this record was last updated in the financial system. |
| lastUpdateUserId   | ErpUserId                 |                |                 |               | User ID of the person who last updated this record. |

##### Linked Data Objects

(None)

#### Query Operations

##### `scmPaymentTerm`

> Get a single ScmPaymentTerm by unitOfMeasureId.  Returns undefined if does not exist

* **Parameters**
  * `termId : String!`
* **Returns**
  * `ScmPaymentTerm`

##### `scmPaymentTermByName`

> Get a single ScmPaymentTerm by category code.  Returns undefined if does not exist

* **Parameters**
  * `name : String!`
* **Returns**
  * `ScmPaymentTerm`

##### `scmPaymentTermSearch`

> Search for ScmPaymentTerm objects by multiple properties.
> See the ScmPaymentTermFilterInput type for options.

* **Parameters**
  * `filter : ScmPaymentTermFilterInput!`
* **Returns**
  * `ScmPaymentTermSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ScmPurchasingCategory



#### Access Controls

* Required Role: `erp:reader-supplier`

#### Data Source

* Local Table/View: `SCM_PURCHASING_CATEGORY`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View: FscmTopModelAM.ScmExtractAM.EgpBiccExtractAM.CategoryExtractPVO
  * Underlying Database Objects:
    * HZ_CLASS_CATEGORIES

##### Properties

| Property Name       | Data Type | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------- | --------- | :------------: | :-------------: | ------------- | ----- |
| categoryId          | Long!     |       Y        |        Y        |               | Unique identifier of the Category Code |
| categoryCode        | String!   |                |        Y        |               | A category is used to manage the catalog hierarchy. Items are assigned to categories in the catalog. |
| categoryContentCode | String    |                |                 |               | Category Content Code. |
| startDateActive     | Date      |                |                 |               | The date from when the value is available for use. |
| endDateActive       | Date      |                |                 |               | The date till which the value is available for use. |
| enabled             | Boolean!  |                |                 |               | Indicates that the Category is enabled. |
| lastUpdateDateTime  | DateTime! |                |                 |               | Timestamp this record was last updated in the financial system. |
| lastUpdateUserId    | ErpUserId |                |                 |               | User ID of the person who last updated this record. |

##### Linked Data Objects

(None)

#### Query Operations

##### `scmPurchasingCategory`

> Get a single ScmPurchasingCategory by unitOfMeasureId.  Returns undefined if does not exist

* **Parameters**
  * `categoryId : String!`
* **Returns**
  * `ScmPurchasingCategory`

##### `scmPurchasingCategoryByPurchasingCategoryCode`

> Get a single ScmPurchasingCategory by category code.  Returns undefined if does not exist

* **Parameters**
  * `categoryCode : String!`
* **Returns**
  * `ScmPurchasingCategory`

##### `scmPurchasingCategorySearch`

> Search for ScmPurchasingCategory objects by multiple properties.
> See the ScmPurchasingCategoryFilterInput type for options.

* **Parameters**
  * `filter : ScmPurchasingCategoryFilterInput!`
* **Returns**
  * `ScmPurchasingCategorySearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ScmSupplier



#### Access Controls

* Required Role: `erp:reader-supplier`

#### Data Source

* Local Table/View: `SCM_SUPPLIER`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.PrcPozPublicViewAM.SupplierPVO
  * Underlying Database Objects:
    * POZ_SUPPLIERS

##### Properties

| Property Name            | Data Type                | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------------ | ------------------------ | :------------: | :-------------: | ------------- | ----- |
| supplierId               | Long                     |                |        Y        |               | Value that uniquely identifies the supplier. |
| supplierNumber           | Long                     |                |        Y        |               |  |
| partyId                  | Long                     |                |                 |               |  |
| name                     | NonEmptyTrimmedString360 |                |        Y        |               | Supplier: Name of the supplier. |
| aliasName                | NonEmptyTrimmedString360 |                |                 |               | Alias: Alternate internal name for the organization. |
| alternateName            | NonEmptyTrimmedString360 |                |                 |               | Alternate Name: Alternate name of the supplier. |
| businessRelationshipCode | NonEmptyTrimmedString30  |                |                 |               | Business Relationship: Business relationship between the enterprise and the supplier. |
| supplierType             | NonEmptyTrimmedString80  |                |                 |               | Supplier Type: Type of supplier. |
| startDateActive          | Date                     |                |                 |               | The date from when the value is available for use. |
| endDateActive            | Date                     |                |                 |               | The date till which the value is available for use. |
| lastUpdateDateTime       | DateTime!                |                |                 |               | Timestamp this record was last updated in the financial system. |
| lastUpdateUserId         | ErpUserId                |                |                 |               | User ID of the person who last updated this record. |
| sites                    | [ScmSupplierSite!]       |                |                 |               | Sites: The Supplier Sites resource manages supplier sites. |

##### Linked Data Objects

(None)

#### Query Operations

##### `scmSupplier`

> Get a single ScmSupplier by supplierId.  Returns undefined if does not exist

* **Parameters**
  * `supplierId : String!`
* **Returns**
  * `ScmSupplier`

##### `scmSupplierByNumber`

> Get a single ScmSupplier by supplier number.  Returns undefined if does not exist

* **Parameters**
  * `supplierNumber : String!`
* **Returns**
  * `ScmSupplier`

##### `scmSupplierSearch`

> Search for ScmSupplier objects by multiple properties.
> See the ScmSupplierFilterInput type for options.

* **Parameters**
  * `filter : ScmSupplierFilterInput!`
* **Returns**
  * `ScmSupplierSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ScmSupplierSite



#### Access Controls

* Required Role: `erp:reader-supplier`

#### Data Source

* Local Table/View: `SCM_SUPPLIER_SITE`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View Object: FscmTopModelAM.PrcExtractAM.PozBiccExtractAM.SupplierSiteExtractPVO
  * Underlying Database Objects:
    * POZ_SUPPLIER_SITES_ALL_M

##### Properties

| Property Name    | Data Type               | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ---------------- | ----------------------- | :------------: | :-------------: | ------------- | ----- |
| supplierSiteId   | Long                    |                |                 |               | Value that uniquely identifies the supplier site. |
| supplierSiteCode | NonEmptyTrimmedString15 |                |                 |               |  |
| supplierId       | Long                    |                |                 |               |  |
| locationId       | Long                    |                |                 |               |  |
| location         | ErpLocation             |                |                 |               |  |

* `location` : `ErpLocation`

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ScmUnitOfMeasure



#### Access Controls

* Required Role: `erp:reader-supplier`

#### Data Source

* Local Table/View: `SCM_UNIT_OF_MEASURE` (view)
  * Support Tables:
    * `SCM_UNIT_OF_MEASURE_TL`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View: FscmTopModelAM.InvUomPublicViewAM.InvUomPVO
  * Underlying Database Objects:
    * INV_UNITS_OF_MEASURE_B
    * INV_UNITS_OF_MEASURE_TL

##### Properties

| Property Name   | Data Type               | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| --------------- | ----------------------- | :------------: | :-------------: | ------------- | ----- |
| unitOfMeasureId | Long                    |       Y        |        Y        |               | Unique identifier of the Unit of Measure (UOM) |
| uomCode         | ScmUnitOfMeasureCode    |                |        Y        |               | Unique short code assigned to a Unit of Measure (UOM) |
| name            | NonEmptyTrimmedString25 |                |        Y        |               | Translatable Unit of Measure (UOM) name |
| description     | NonEmptyTrimmedString50 |                |                 |               | Translatable Unit of Measure (UOM) description. |
| baseUOM         | Boolean!                |                |                 |               | Base Unit of Measure (UOM) flag. |

##### Linked Data Objects

(None)

#### Query Operations

##### `scmUnitOfMeasure`

> Get a single ScmUnitOfMeasure by unitOfMeasureId.  Returns undefined if does not exist

* **Parameters**
  * `unitOfMeasureId : String!`
* **Returns**
  * `ScmUnitOfMeasure`

##### `scmUnitOfMeasureByCode`

> Get a single ScmUnitOfMeasure by uom code.  Returns undefined if does not exist

* **Parameters**
  * `uomCode : String!`
* **Returns**
  * `ScmUnitOfMeasure`

##### `scmUnitOfMeasureSearch`

> Search for ScmUnitOfMeasure objects by multiple properties.
> See the ScmUnitOfMeasureFilterInput type for options.

* **Parameters**
  * `filter : ScmUnitOfMeasureFilterInput!`
* **Returns**
  * `ScmUnitOfMeasureSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.
