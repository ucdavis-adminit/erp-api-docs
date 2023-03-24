# 3.2.1.5 SCM Reference Data

<!--BREAK-->
### Data Object: ApAccountingPeriod

Represents an accounting period in the GL module of Oracle Financials.  Used for validation of submitted journal entry data.

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `AP_PERIOD` (view)
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
| lastUpdateDateTime    | DateTime!                |                |        Y        |               |  |
| lastUpdateUserId      | ErpUserId                |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `apAccountingPeriod`

> Get a single ApAccountingPeriod by its name.  Returns undefined if does not exist

* **Parameters**
  * `periodName : String!`
* **Returns**
  * `ApAccountingPeriod`

##### `apAccountingPeriodByDate`

> Get a single non-adjustment ApAccountingPeriod by the given date.  Returns undefined if no period is defined for the given date.

* **Parameters**
  * `accountingDate : Date!`
* **Returns**
  * `ApAccountingPeriod`

##### `apAccountingPeriodSearch`

> Search for ApAccountingPeriod objects by multiple properties.
> See
> See the ApAccountingPeriodFilterInput type for options.

* **Parameters**
  * `filter : ApAccountingPeriodFilterInput!`
* **Returns**
  * `ApAccountingPeriodSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ApInvoice



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `AP_INVOICE_V` (view)
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * 
  * Underlying Database Objects:
    * 
    * 
    * 

##### Properties

| Property Name         | Data Type                | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| --------------------- | ------------------------ | :------------: | :-------------: | ------------- | ----- |
| invoiceId             | Long!                    |                |                 |               |  |
| vendorId              | Long!                    |                |                 |               |  |
| vendorSiteId          | Long!                    |                |                 |               |  |
| orgId                 | Long!                    |                |                 |               |  |
| poHeaderId            | Long                     |                |                 |               |  |
| supplierNumber        | NonEmptyTrimmedString30  |                |                 |               |  |
| supplierSiteCode      | NonEmptyTrimmedString15  |                |                 |               |  |
| supplierName          | NonEmptyTrimmedString360 |                |                 |               |  |
| supplierInvoiceNumber | NonEmptyTrimmedString25  |                |                 |               |  |
| invoiceNumber         | NonEmptyTrimmedString50  |                |                 |               |  |
| poNumber              | NonEmptyTrimmedString30  |                |                 |               |  |
| checkNumber           | NonEmptyTrimmedString50  |                |                 |               |  |
| paymentAmount         | Long                     |                |                 |               |  |
| invoiceDate           | Date                     |                |                 |               |  |
| paymentDate           | Date                     |                |                 |               |  |
| paymentStatusCode     | NonEmptyTrimmedString1   |                |                 |               |  |
| paymentSourceName     | NonEmptyTrimmedString25  |                |                 |               |  |
| checkStatusCode       | NonEmptyTrimmedString50  |                |                 |               |  |
| paymentMethodCode     | NonEmptyTrimmedString25  |                |                 |               |  |
| batchName             | NonEmptyTrimmedString50  |                |                 |               |  |
| lastUpdateDateTime    | DateTime                 |                |                 |               |  |
| lastUpdateUserId      | ErpUserId                |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


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

The SCM purchasing category represent the type of item being paid for on an invoice payment.

The Oracle Purchasing category is the conceptual replacement for the KFS Commodity Code.

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
| id                  | Long!     |       Y        |                 |               | Unique identifier of the Category Code |
| code                | String!   |                |        Y        |               | A category is used to manage the catalog hierarchy. Items are assigned to categories in the catalog. |
| name                | String!   |                |        Y        |               | Name of the purchasing category.  This is used on the SCM Requisition interface. |
| description         | String    |                |        Y        |               | Description of the purchasing category. |
| categoryContentCode | String    |                |                 |               | Category Content Code. |
| startDateActive     | Date      |                |                 |               | The date from when the value is available for use. |
| endDateActive       | Date      |                |                 |               | The date till which the value is available for use. |
| enabled             | Boolean!  |                |        Y        |               | Indicates that the Category is enabled. |
| lastUpdateDateTime  | DateTime! |                |        Y        |               | Timestamp this record was last updated in the financial system. |
| lastUpdateUserId    | ErpUserId |                |                 |               | User ID of the person who last updated this record. |

##### Linked Data Objects

(None)

#### Query Operations

##### `scmPurchasingCategory`

> Get a single ScmPurchasingCategory by unitOfMeasureId.  Returns undefined if does not exist

* **Parameters**
  * `id : String!`
* **Returns**
  * `ScmPurchasingCategory`

##### `scmPurchasingCategoryByCode`

> Get a single ScmPurchasingCategory by category code.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `ScmPurchasingCategory`

##### `scmPurchasingCategoryByName`

> Get a single ScmPurchasingCategory by name.  Returns undefined if does not exist

* **Parameters**
  * `name : String!`
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

A defined supplier of goods or services in the ERP system.

Each supplier may have multiple sites at which they do business.  It is necessary to identify both the supplier and site when submitting a payment.

Supplier in Oracle replaces Vendor in KFS.

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

| Property Name            | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| supplierId               | Long!                     |                |                 |               | Value that uniquely identifies the supplier internally to Oracle. |
| supplierNumber           | NonEmptyTrimmedString30!  |                |        Y        |               | Unique ID for the supplier used to reference it within the UI and in interfaces.  This largely corresponds to the Vendor ID in KFS. |
| name                     | NonEmptyTrimmedString360! |                |        Y        |               | Supplier: Name of the supplier. |
| aliasName                | NonEmptyTrimmedString360  |                |        Y        |               | Alias: Alternate internal name for used for the supplier. |
| alternateName            | NonEmptyTrimmedString360  |                |        Y        |               | Alternate Name: Alternate name of the supplier. |
| businessRelationshipCode | NonEmptyTrimmedString30   |                |                 |               | Business Relationship: Business relationship between the enterprise and the supplier. |
| supplierType             | NonEmptyTrimmedString30   |                |                 |               | DEPRECATED: Use organizationTypeCode instead. |
| supplierTypeCode         | NonEmptyTrimmedString30   |                |                 |               | The general type of goods or services provided by this supplier. |
| organizationTypeCode     | NonEmptyTrimmedString30   |                |        Y        |               | The nature of the supplier's business structure.  (Corporation, Partnership, etc...) |
| startDateActive          | LocalDate                 |                |                 |               | The date from when the value is available for use. |
| endDateActive            | LocalDate                 |                |                 |               | The date till which the value is available for use. |
| lastUpdateDateTime       | DateTime!                 |                |        Y        |               | Timestamp this record was last updated in the financial system. |
| lastUpdateUserId         | ErpUserId                 |                |                 |               | User ID of the person who last updated this record. |
| sites                    | [ScmSupplierSite!]!       |                |                 |               | Supplier business locations referenced when making orders or payments to the supplier. |

##### Linked Data Objects

(None)

#### Query Operations

##### `scmSupplier`

> Get a single ScmSupplier by supplierId.  Returns undefined if does not exist

* **Parameters**
  * `supplierId : Long!`
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

Supplier Site represents a business location referenced when making orders or payments to the supplier.

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

| Property Name    | Data Type                | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ---------------- | ------------------------ | :------------: | :-------------: | ------------- | ----- |
| supplierSiteId   | Long!                    |                |                 |               | Value that uniquely identifies the supplier site internally within Oracle. |
| supplierSiteCode | NonEmptyTrimmedString15! |                |                 |               | Code used to identify the site on the UI and in interfaces. |
| locationId       | Long                     |                |                 |               | Internal location code containing address information. |
| location         | ErpLocation              |                |                 |               | Physical address of the site. |

* `location` : `ErpLocation`
  * Physical address of the site.
  * Description of `ErpLocation`:
    * Locations referenced by Supplier and AR Customer Sites

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.
