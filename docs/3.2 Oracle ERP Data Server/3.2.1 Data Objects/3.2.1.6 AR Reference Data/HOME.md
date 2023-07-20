# 3.2.1.6 AR Reference Data

<!--BREAK-->
### Data Object: ArAccountingPeriod

Represents an accounting period in the GL module of Oracle Financials.  Used for validation of submitted journal entry data.

#### Access Controls

* Required Role: `erp:writer-receivable`

#### Data Source

* Local Table/View: `AR_PERIOD` (view)
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
| startDate             | LocalDate!               |                |        Y        |               |  |
| endDate               | LocalDate!               |                |        Y        |               |  |
| yearStartDate         | LocalDate!               |                |                 |               |  |
| quarterStartDate      | LocalDate!               |                |                 |               |  |
| quarterNumber         | PositiveInt!             |                |                 |               |  |
| effectivePeriodNumber | PositiveInt!             |                |                 |               |  |
| lastUpdateDateTime    | DateTime!                |                |        Y        |               |  |
| lastUpdateUserId      | ErpUserId                |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `arAccountingPeriod`

> Get a single ArAccountingPeriod by its name.  Returns undefined if does not exist

* **Parameters**
  * `periodName : String!`
* **Returns**
  * `ArAccountingPeriod`

##### `arAccountingPeriodByDate`

> Get a single non-adjustment ArAccountingPeriod by the given date.  Returns undefined if no period is defined for the given date.

* **Parameters**
  * `accountingDate : Date!`
* **Returns**
  * `ArAccountingPeriod`

##### `arAccountingPeriodSearch`

> Search for ArAccountingPeriod objects by multiple properties.
> See
> See the ArAccountingPeriodFilterInput type for options.

* **Parameters**
  * `filter : ArAccountingPeriodFilterInput!`
* **Returns**
  * `ArAccountingPeriodSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ArBatchSource

Represents a BatchSource within the AR module of Oracle Financials.

These are the allowed "sources" of batch/api entry of Invoices in the financial system.

This source name must be included in the request, and must match a value in the Financial System.

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `AR_BATCH_SOURCE`
  * Support Tables:
    * n/a
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View `FscmTopModelAM.FinExtractAM.ArBiccExtractAM.TransactionBatchSourceExtractPVO`
  * Underlying Database Objects:
    * `RA_BATCH_SOURCES_ALL`

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| id                 | NonEmptyTrimmedString20!  |       Y        |        Y        |               | Primary key of this object. |
| name               | NonEmptyTrimmedString50!  |                |        Y        |               | Short key name. |
| description        | NonEmptyTrimmedString240  |                |        Y        |               | Long description. |
| type               | NonEmptyTrimmedString30   |                |        Y        |               | Type of this MemoLine. |
| legalEntityId      | NonEmptyTrimmedString20   |                |        Y        |               | Type of this MemoLine. |
| status             | NonEmptyTrimmedString1    |                |        Y        |               | Type of this MemoLine. |
| startDate          | Date                      |                |        Y        |               | Timestamp this record was created. |
| endDAte            | Date                      |                |        Y        |               | Timestamp this record was last updated in the financial system. |
| creationDate       | DateTime                  |                |        Y        |               | Timestamp this record was created. |
| lastUpdateDateTime | DateTime                  |                |        Y        |               | Timestamp this record was last updated in the financial system. |

##### Linked Data Objects

(None)

#### Query Operations

This object is setup in the system, but is not queryable via GraphQL endpoint.

This is due to the potentially sensitive nature of this information.


<!--BREAK-->
### Data Object: ArCustomerAccount



#### Access Controls

* Required Role: `erp:reader-customer`

#### Data Source

* Local Table/View: `AR_CUSTOMER_ACCOUNT`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * CrmAnalyticsAM.CrmExtractAM.HzBiccExtractAM.CustomerAccountExtractPVO
  * Underlying Database Objects:
    * HZ_CUST_ACCOUNTS

##### Properties

| Property Name        | Data Type                | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| -------------------- | ------------------------ | :------------: | :-------------: | ------------- | ----- |
| custAccountId        | Long!                    |                |                 |               |  |
| accountNumber        | NonEmptyTrimmedString50  |                |        Y        |               | Value that uniquely identifies the CustomerAccount by number |
| accountName          | NonEmptyTrimmedString100 |                |        Y        |               | Value that uniquely identifies the CustomerAccount by name |
| status               | NonEmptyTrimmedString10  |                |                 |               | Status Code of the Customer Account |
| lastUpdateDateTime   | DateTime                 |                |                 |               | Date/Time last updated |
| customerAccountSites | [ArCustomerAccountSite]  |                |                 |               | Customer Accounts have one to many Sites associated |

##### Linked Data Objects

(None)

#### Query Operations

##### `arCustomerAccountSite`

> Get a single ArCustomerAccountSite by custAccountSiteId.  Returns undefined if does not exist

* **Parameters**
  * `custAccountSiteId : String!`
* **Returns**
  * `ArCustomerAccountSite`

##### `arCustomerAccountSiteSearch`

> Search for ArCustomerAccountSite objects by multiple properties.
> See the ArCustomerAccountSiteFilterInput type for options.

* **Parameters**
  * `filter : ArCustomerAccountSiteFilterInput!`
* **Returns**
  * `ArCustomerAccountSiteSearchResults!`

##### `arCustomerAccount`

> Get a single ArCustomerAccount by accountNumber.  Returns undefined if does not exist

* **Parameters**
  * `accountNumber : String!`
* **Returns**
  * `ArCustomerAccount`

##### `arCustomerAccountByAccountName`

> Get a single ArCustomerAccount by accountName.  Returns undefined if does not exist

* **Parameters**
  * `accountName : String!`
* **Returns**
  * `ArCustomerAccount`

##### `arCustomerAccountSearch`

> Search for ArCustomerAccount objects by multiple properties.
> See the ArCustomerAccountFilterInput type for options.

* **Parameters**
  * `filter : ArCustomerAccountFilterInput!`
* **Returns**
  * `ArCustomerAccountSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ArCustomerAccountSite



#### Access Controls

* Required Role: `erp:reader-customer`

#### Data Source

* Local Table/View: `AR_CUSTOMER_ACCOUNT_SITE`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * CrmAnalyticsAM.CrmExtractAM.HzBiccExtractAM.CustomerAccountSiteExtractPVO
  * Underlying Database Objects:
    * HZ_CUST_ACCT_SITES_ALL

##### Properties

| Property Name      | Data Type              | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ---------------------- | :------------: | :-------------: | ------------- | ----- |
| custAccountSiteId  | Long!                  |                |        Y        |               |  |
| custAccountId      | Long!                  |                |        Y        |               |  |
| partySiteId        | Long!                  |                |        Y        |               |  |
| startDate          | Date                   |                |        Y        |               |  |
| endDate            | Date                   |                |        Y        |               |  |
| shipToFlag         | NonEmptyTrimmedString1 |                |                 |               |  |
| billToFlag         | NonEmptyTrimmedString1 |                |                 |               |  |
| status             | NonEmptyTrimmedString1 |                |                 |               |  |
| lastUpdateDateTime | DateTime               |                |        Y        |               |  |
| partySite          | ArPartySite            |                |                 |               |  |

* `partySite` : `ArPartySite`

##### Linked Data Objects

(None)

#### Query Operations

##### `arCustomerAccountSite`

> Get a single ArCustomerAccountSite by custAccountSiteId.  Returns undefined if does not exist

* **Parameters**
  * `custAccountSiteId : String!`
* **Returns**
  * `ArCustomerAccountSite`

##### `arCustomerAccountSiteSearch`

> Search for ArCustomerAccountSite objects by multiple properties.
> See the ArCustomerAccountSiteFilterInput type for options.

* **Parameters**
  * `filter : ArCustomerAccountSiteFilterInput!`
* **Returns**
  * `ArCustomerAccountSiteSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ArInvoiceSummary

Invoice status information used to check remaining balances.

#### Access Controls

* Required Role: `UNIMPLEMENTED`

#### Data Source

* Local Table/View: `undefined`

##### Properties

| Property Name         | Data Type  | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| --------------------- | ---------- | :------------: | :-------------: | ------------- | ----- |
| transactionNumber     | String!    |                |                 |               |  |
| transactionDate       | LocalDate! |                |                 |               |  |
| complete              | Boolean!   |                |                 |               |  |
| remainingDueAmount    | Float      |                |                 |               |  |
| originalInvoiceAmount | Float!     |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `arInvoiceSummary`

> Using the provided transaction number, check on the status of the given invoice.  Returns null if the transaction number is unknown.

* **Parameters**
  * `transactionNumber : String!`
* **Returns**
  * `ArInvoiceSummary`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ArMemoLine



#### Access Controls

* Required Role: `erp:writer-receivable`

#### Data Source

* Local Table/View: `AR_MEMO_LINE`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * FscmTopModelAM.FinExtractAM.ArBiccExtractAM.MemoLineExtractPVO
  * Underlying Database Objects:
    * AR_MEMO_LINES_ALL_B

##### Properties

| Property Name      | Data Type               | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ----------------------- | :------------: | :-------------: | ------------- | ----- |
| id                 | Long!                   |                |        Y        |               | Value that uniquely identifies the MemoLine by ID |
| name               | NonEmptyTrimmedString50 |                |        Y        |               | Value that uniquely identifies the MemoLine by name |
| description        | NonEmptyTrimmedString80 |                |                 |               | Longer description |
| type               | NonEmptyTrimmedString10 |                |                 |               | Type of the MemoLine |
| creationDate       | DateTime                |                |                 |               | Date the MemoLine was created |
| lastUpdateDateTime | DateTime                |                |                 |               | Date/Time last updated |

##### Linked Data Objects

(None)

#### Query Operations

##### `arMemoLine`

> Get a single ArMemoLine by id.  Returns undefined if does not exist

* **Parameters**
  * `id : String!`
* **Returns**
  * `ArMemoLine`

##### `arMemoLineByName`

> Get a single ArMemoLine by name.  Returns undefined if does not exist

* **Parameters**
  * `name : String!`
* **Returns**
  * `ArMemoLine`

##### `arMemoLineSearch`

> Search for ArMemoLine objects by multiple properties.
> See the ArMemoLineFilterInput type for options.

* **Parameters**
  * `filter : ArMemoLineFilterInput!`
* **Returns**
  * `ArMemoLineSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ArPartySite



#### Access Controls

* Required Role: `erp:reader-customer`

#### Data Source

* Local Table/View: `AR_PARTY_SITE`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * CrmAnalyticsAM.CrmExtractAM.HzBiccExtractAM.PartySiteExtractPVO
  * Underlying Database Objects:
    * HZ_PARTY_SITES

##### Properties

| Property Name      | Data Type                | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------ | :------------: | :-------------: | ------------- | ----- |
| partySiteNumber    | NonEmptyTrimmedString50! |                |        Y        |               | Value that uniquely identifies the PartySite by number |
| partySiteName      | NonEmptyTrimmedString100 |                |        Y        |               | Value that uniquely identifies the PartySite by name |
| status             | NonEmptyTrimmedString10  |                |                 |               | Status Code of the PartySite |
| partySiteId        | Long                     |                |                 |               |  |
| partyId            | Long                     |                |                 |               |  |
| locationId         | Long                     |                |                 |               |  |
| lastUpdateDateTime | DateTime                 |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `arPartySite`

> Get a single ArPartySite by partySiteId.  Returns undefined if does not exist

* **Parameters**
  * `partySiteId : Long!`
* **Returns**
  * `ArPartySite`

##### `arPartySiteByPartySiteNumber`

> Get a single ArPartySite by partySiteNumber.  Returns undefined if does not exist

* **Parameters**
  * `partySiteNumber : String!`
* **Returns**
  * `ArPartySite`

##### `arPartySiteByPartySiteName`

> Get a single ArPartySite by partySiteName.  Returns undefined if does not exist

* **Parameters**
  * `partySiteName : String!`
* **Returns**
  * `ArPartySite`

##### `arPartySiteSearch`

> Search for ArPartySite objects by multiple properties.
> See the ArPartySiteFilterInput type for options.

* **Parameters**
  * `filter : ArPartySiteFilterInput!`
* **Returns**
  * `ArPartySiteSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ArPaymentTerm

TODO

#### Access Controls

* Required Role: `erp:writer-receivable`

#### Data Source

* Local Table/View: `AR_PAYMENT_TERM`

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| id                 | Long!                     |                |                 |               |  |
| name               | NonEmptyTrimmedString15!  |                |        Y        |               |  |
| description        | NonEmptyTrimmedString240! |                |                 |               |  |
| startDate          | LocalDate                 |                |                 |               | The date from when the value is available for use. |
| endDate            | LocalDate                 |                |                 |               | The date till which the value is available for use. |
| inUse              | Boolean!                  |                |        Y        |               | Indicates that the AR Payment Term is in active use. |
| lastUpdateDateTime | DateTime                  |                |        Y        |               | Timestamp this record was last updated in the financial system. |
| lastUpdateUserId   | ErpUserId                 |                |                 |               | User ID of the person who last updated this record. |

##### Linked Data Objects

(None)

#### Query Operations

##### `arPaymentTerm`

> Get a single ArPaymentTerm by code.  Returns undefined if does not exist

* **Parameters**
  * `id : Long!`
* **Returns**
  * `ArPaymentTerm`

##### `arPaymentTermByName`

> Get a single ArPaymentTerm by name.  Returns undefined if does not exist

* **Parameters**
  * `name : NonEmptyTrimmedString15!`
* **Returns**
  * `ArPaymentTerm`

##### `arPaymentTermSearch`

> Search for ArPaymentTerm objects by multiple properties.
> See
> See the ArPaymentTermFilterInput type for options.

* **Parameters**
  * `filter : ArPaymentTermFilterInput!`
* **Returns**
  * `ArPaymentTermSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.
