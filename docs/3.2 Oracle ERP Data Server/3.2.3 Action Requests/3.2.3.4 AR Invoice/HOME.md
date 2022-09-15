# 3.2.3.4 AR Invoice

<!--BREAK-->
### Action Request: `ArInvoice`

#### Overview

This request allows the submitting boundary application to create a receivables invoice in the Oracle Financials system.  It accepts the provided data for a single invoice and runs validation prior to storing it for processing by the integration platform.

Some key AR values will need to be known ahead of time, but will be provided to you or available from the API:

* `consumerId`: API consumer ID, provided to you
* `boundaryApplicationName`: Name of your boundary application, provided to you
* `batchSourceName`: Name of your boundary application, provided to you
* `transactionTypeName`: TransactionType, provided to you
* `customerAccountNumber`: Unique customer number from the ERP system, provided to you, or searchable via API
* `customerSiteNumber`: Unique customer site/location number from the ERP system, provided to you, or searchable via API
* `memoLineName`: MemoLineName provided to you controls the accounting generated for your invoice
* `paymentTerm`: Name of the paymentTerms for your invoice, provided to you
* `lines.unitOfMeasureCode`: Unit of Measure codes can be searched via API

#### Access Controls

* Required Role: `erp:writer-receivable`
* Required Role: `erp:reader-customer`

#### Supporting Operations

##### Header Values

* `consumerTrackingId`
* `consumerReferenceId`
* `consumerNotes`
* `boundaryApplicationName`
* `consumerId`

##### AR Values

* `batchSourceName`
* `transactionTypeName`
* `transactionNumber`
* `customerAccountNumber`
* `customerSiteNumber`
* `transactionDate`
* `accountingDate`
* `memoLineName`
* `lines`
  * `lineType`
  * `description`
  * `amount`
  * `quantity`
  * `unitOfMeasureCode`
  * `customerOrderedQuantity`
  * `unitSellingPrice`
  * `unitStandardPrice`
  * `memoLineName`
  * `paymentTerm`

#### Basic Use

1. Consumer calls the operation providing a data payload with the proper structure.
2. API Server will perform validation against locally extracted Oracle ERP data.
3. A failure in these initial validations will result in an error response being returned and no request being generated.
4. Passing initial validation will save and submit the request to the integration platform for processing.
5. A request tracking ID will be generated and returned to allow for the consumer to check on the status of the request and obtain results when completed.

#### Operations

##### `arInvoiceCreate`

> Submits an AR Invoice for validation and submission to the Oracle ERP system. Returns a handle with the results of the request submission. This handle contains the operation to submit back to this server to get the results.

* **Parameters**
  * `data : ArInvoiceRequestInput!`
* **Returns**
  * `ArInvoiceRequestStatusOutput!`


#### API Validations

##### Per GraphQL Data Model and Type Resolvers

> These validations will be enforced by the GraphQL parser and data type definitions.

* Valid JSON data structure.
* Required fields (enforced by GraphQL data model)
* Ensure required fields are non-blank. (enforced by GraphQL data model)
* Ensure fields are formatted properly (enforced by GraphQL data model - and custom code if needed)
* Verify maximum lengths on fields.  (Delegate using custom data types if possible.)
  * (e.g., `TrimmedNonEmptyString240`)

##### Request Header Checks

* Validate `batchSourceName`
  * `RA_BATCH_SOURCES_ALL.NAME and RA_BATCH_SOURCES_ALL.BATCH_SOURCE_TYPE = 'FOREIGN'`
  * Verify Source is allowed for API consumer. (TBD - We will want to link the API Consumer authentication identifier to the journal sources.)
* Validate `transactionTypeName`
  * Verify Type is valid for API use. (TBD)
  * Verify Type is allowed for API consumer. (Each API Consumer may have a limited set of types they are allowed to use.)
* Confirm if `consumerTrackingId` previously used and reject if found in the action request table.
* The header `header.consumerTrackingId` and `payload.transactionNumber` must be the same.

##### Data Validation

* **Verify Header**
  * Verify items with lookup tables
    * Payment Terms
    * Customer Account
      * `RA_INTERFACE_LINES_ALL.ORIG_SYSTEM_BILL_CUSTOMER_ID = HZ_CUST_ACCT_ROLES.CUST_ACCOUNT_ID and RA_INTERFACE_LINES_ALL.ORIG_SYSTEM_BILL_CONTACT_REF = RA_CONTACTS.ORIG_SYSTEM_REFERENCE`
    * Customer Site
      * `RA_INTERFACE_LINES_ALL.ORIG_SYSTEM_BILL_ADDRESS_REF = HZ_PARTY_SITES.ORIG_SYSTEM_REFERENCE and CUSTOMER_REF = HZ_CUST_ACCOUNTS.ORIG_SYSTEM_REFERENCE and HZ_CUST_ACCOUNTS.CUST_ACCOUNT_ID = HZ_CUST_ACCT_SITE.CUST_ACCOUNT_ID and HZ_CUST_ACCT_SITE.CUSTOMER_SITE_ID = HZ_CUST_SITE_USES.CUST_ACCT_SITE_ID and RA_SITE_USES.SITE_USE_CODE = 'BILL_TO'`
  * Ensure that the Site is valid for the customer account
  * Check that there is not a previously submitted pending or successful request with the same transaction number for the API consumer.
  * Verify transaction date within last month?
  * Verify accounting date belongs to an open AR Accounting Period.  (AR_PERIODS - though - there is no status on this table.  May need to join in to the GL period if the name matches)
  * Memo Line Name
  * Payment Term
* **Verify Lines**
  * Verify items with lookup tables
    * Unit of Measure Code (if provided)



#### Data Object to Oracle Mapping

> Base Object:                               `ArInvoiceRequestInput`
> `payload`:                                 `ArInvoiceInput`
> `payload.lines`:                           `[ArInvoiceLineInput!]!`
> `payload.lines.distributions`:             `[ArInvoiceDistributionInput!]!`
> `payload.lines.distributions.glSegments`:  `GlSegmentInput`

* [Oracle AutoInvoice Documentation](https://docs.oracle.com/cd/E18727_01/doc.121/e13512/T447348T383863.htm)
* [Table: RA_INTERFACE_LINES_ALL](https://docs.oracle.com/en/cloud/saas/financials/21d/oedmf/rainterfacelinesall-8520.html)
* [Table: RA_INTERFACE_DISTRIBUTIONS_ALL](https://docs.oracle.com/en/cloud/saas/financials/21d/oedmf/rainterfacelinesall-8520.html)

| GraphQL Property                                     | Req? | Oracle FBDI Destination                            | Column                           |
| ---------------------------------------------------- | ---- | -------------------------------------------------- | -------------------------------- |
| **Invoice Header Fields**                            |      | ------------------------------------               | `RA_INTERFACE_LINES_ALL`         |
| Constant: `UCD Business Unit`                        | Yes  | Business Unit Name                                 | BU_NAME                          |
| payload.batchSourceName                              | Yes  | Transaction Batch Source Name                      | BATCH_SOURCE_NAME                |
| payload.transactionTypeName                          | Yes  | Transaction Type Name                              | CUST_TRX_TYPE_NAME               |
| payload.paymentTermsName                             |      | Payment Terms                                      | TERM_NAME                        |
| payload.transactionNumber                            | Yes  | Transaction Number                                 | TRX_NUMBER                       |
| payload.customerAccountNumber                        | Yes  | Original System Bill-to Customer Reference         | ORIG_SYSTEM_BILL_CUSTOMER_REF    |
| payload.customerSiteNumber                           | Yes  | Original System Bill-to Customer Address Reference | ORIG_SYSTEM_BILL_ADDRESS_REF     |
| payload.transactionDate                              | Yes  | Transaction Date                                   | TRX_DATE                         |
| payload.accountingDate                               |      | Accounting Date                                    | GL_DATE                          |
| **Invoice Line Fields**                              |      | ------------------------------------               | `RA_INTERFACE_LINES_ALL`         |
| payload.lines.lineType                               | Yes  | Transaction Line Type                              | LINE_TYPE                        |
| payload.lines.memoLineName                           |      | Memo Line Name                                     | MEMO_LINE_NAME                   |
| payload.lines.description                            | Yes  | Transaction Line Description                       | DESCRIPTION                      |
| payload.lines.amount                                 | Yes  | Transaction Line Amount                            | AMOUNT                           |
| payload.lines.quantity                               |      | Transaction Line Quantity                          | QUANTITY                         |
| payload.lines.unitOfMeasureCode                      |      | Unit of Measure Code                               | UOM_CODE                         |
| payload.lines.customerOrderedQuantity                |      | Customer Ordered Quantity                          | QUANTITY_ORDERED                 |
| payload.lines.unitSellingPrice                       |      | Unit Selling Price                                 | UNIT_SELLING_PRICE               |
| payload.lines.unitStandardPrice                      |      | Unit Standard Price                                | UNIT_STANDARD_PRICE              |
| Constant: `USD`                                      |      | Currency Code                                      | CURRENCY_CODE                    |
| Constant: `User`                                     |      | Currency Conversion Type                           | CONVERSION_TYPE                  |
| Constant: `1`                                        |      | Currency Conversion Rate                           | CONVERSION_RATE                  |
| Constant: `UCD Context`                              |      | Line Transactions Flexfield Context                | INTERFACE_LINE_CONTEXT           |
| payload.transactionNumber                            |      | Line Transactions Flexfield Segment 1              | INTERFACE_LINE_ATTRIBUTE1        |
| Computed: (Line Number)                              |      | Line Transactions Flexfield Segment 2              | INTERFACE_LINE_ATTRIBUTE2        |
| **Invoice Line Distribution Fields**                 |      | ------------------------------------               | `RA_INTERFACE_DISTRIBUTIONS_ALL` |
| Constant: `UCD Context`                              |      | Line Transactions Flexfield Context                | INTERFACE_LINE_CONTEXT           |
| payload.transactionNumber                            |      | Line Transactions Flexfield Segment 1              | INTERFACE_LINE_ATTRIBUTE1        |
| Computed: (Line Number)                              |      | Line Transactions Flexfield Segment 2              | INTERFACE_LINE_ATTRIBUTE2        |
| Constant: `UCD Business Unit`                        | Yes  | Business Unit Name                                 | BU_NAME                          |
| payload.lines.distributions.distributionAccountClass | Yes  | Account Class                                      | ACCOUNT_CLASS                    |
| payload.lines.distributions.amount                   | ***  | Amount                                             | AMOUNT                           |
| payload.lines.distributions.percent                  | ***  | Percent                                            | PERCENT                          |
| payload.lines.distributions.glSegments.entity        | Yes  | Accounting Flexfield Segment 1                     | SEGMENT1                         |
| payload.lines.distributions.glSegments.fund          | Yes  | Accounting Flexfield Segment 2                     | SEGMENT2                         |
| payload.lines.distributions.glSegments.department    | Yes  | Accounting Flexfield Segment 3                     | SEGMENT3                         |
| payload.lines.distributions.glSegments.account       | Yes  | Accounting Flexfield Segment 4                     | SEGMENT4                         |
| payload.lines.distributions.glSegments.purpose       |      | Accounting Flexfield Segment 5                     | SEGMENT5                         |
| payload.lines.distributions.glSegments.program       |      | Accounting Flexfield Segment 6                     | SEGMENT6                         |
| payload.lines.distributions.glSegments.project       |      | Accounting Flexfield Segment 7                     | SEGMENT7                         |
| payload.lines.distributions.glSegments.activity      |      | Accounting Flexfield Segment 8                     | SEGMENT8                         |
| Constant: `0000`                                     |      | Accounting Flexfield Segment 9                     | SEGMENT9                         |
| Constant: `000000`                                   |      | Accounting Flexfield Segment 10                    | SEGMENT10                        |
| Constant: `000000`                                   |      | Accounting Flexfield Segment 11                    | SEGMENT11                        |

* Either Amount or Percent are required, but not both.

###### Questions

##### Property Lookup Validations

| GraphQL Property                                  | Local Data Object      | Local Data Object Property |
| ------------------------------------------------- | ---------------------- | -------------------------- |
| payload.batchSourceName                           | ArBatchSource          | name                       |
| payload.transactionTypeName                       | ArTransactionSource    | name                       |
| payload.customerAccountNumber                     | ArCustomer             |                            |
| payload.paymentTermsName                          | ArPaymentTerm          | name                       |
| payload.customerSiteNumber                        | ArCustomerSite         |                            |
| payload.memoLineName                              | ArMemoLine             | name                       |
| payload.lines.unitOfMeasureCode                   | ErpUnitOfMeasure       | code                       |
| payload.lines.distributions.glSegments.entity     | ErpEntity              | code                       |
| payload.lines.distributions.glSegments.fund       | ErpFund                | code                       |
| payload.lines.distributions.glSegments.department | ErpFinancialDepartment | code                       |
| payload.lines.distributions.glSegments.account    | ErpAccount             | code                       |
| payload.lines.distributions.glSegments.purpose    | ErpPurpose             | code                       |
| payload.lines.distributions.glSegments.program    | ErpProgram             | code                       |
| payload.lines.distributions.glSegments.project    | ErpProject             | code                       |
| payload.lines.distributions.glSegments.activity   | ErpActivity            | code                       |
