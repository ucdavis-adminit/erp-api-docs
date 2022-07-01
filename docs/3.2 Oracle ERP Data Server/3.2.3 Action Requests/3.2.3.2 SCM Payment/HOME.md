# 3.2.3.2 SCM Payment

<!--BREAK-->
### Action Request: `ScmInvoicePayment`

#### Overview

This request allows the submitting boundary application to create payment request in the Oracle Financials system.  It accepts the provided data for a single payment and runs validation prior to storing it for processing by the integration platform.


#### Access Controls

* Required Role: `erp:writer-payment`
* Required Role: `erp:reader-supplier`

#### Basic Use

1. Consumer calls the operation providing a data payload with the proper structure.
2. API Server will perform validation against locally extracted Oracle ERP data.
3. A failure in these initial validations will result in an error response being returned and no request being generated.
4. Passing initial validation will save and submit the request to the integration platform for processing.
5. A request tracking ID will be generated and returned to allow for the consumer to check on the status of the request and obtain results when completed.

#### Operations

##### `scmInvoicePaymentRequest`

* **Parameters**
  * `data : ScmInvoicePaymentRequestInput!`
* **Returns**
  * `ScmInvoicePaymentRequestStatusOutput!`


#### API Validations (TO COMPLETE)

##### Per GraphQL Data Model and Type Resolvers

> These validations will be enforced by the GraphQL parser and data type definitions.

* Valid JSON data structure.
* Required fields (enforced by GraphQL data model)
* Ensure required fields are non-blank. (enforced by GraphQL data model)
* Ensure fields are formatted properly (enforced by GraphQL data model - and custom code if needed)
* Verify maximum lengths on fields.  (Delegate using custom data types if possible.)
  * (e.g., `TrimmedNonEmptyString240`)

##### Request Header Checks

* Confirm if `consumerTrackingId` previously used and reject if found in the action request table.

##### Data Validation

* Validate LineType:  LINE_TYPE_LOOKUP_CODE
  * The code you enter must be ITEM, TAX, MISCELLANEOUS, or FREIGHT. Validate against lookup codes stored in the AP_LOOKUP_CODES table
* Validate InvoiceType: INVOICE_TYPE_LOOKUP_CODE
  * The value must be Credit or Standard. The invoice type must correspond to the invoice amount. For example, Credit invoices must have invoice Amounts less than zero.
* Validate unitOfMeasureCode: this will probably be enum? `ArUnitOfMeasure`
* Validate paymentTerms: `ScmPaymentTerm`
* Check that Supplier is valid. Validate supplierNumber: `ScmSupplier.supplierNumber`
  * scm_supplier table
* Ensure that the Site is valid. Validate supplierSiteCode: `ScmSupplier.supplierNumber.suppliers.supplierSiteCode`
  * scm_supplier_site table
* Check that there is not a previously submitted pending or successful request with the same transaction number for the API consumer.
* Verify transaction date within last month?
* Verify no line was given both GL and POET segments.
* Validate glSegment
* Validate glSegment String
* Validate ppmSegment:
  * Validate POET (Project, Organization, Expenditure, Task).
* If submitted, verify PO Number is valid
* If submitted, verify Project code is valid
  * Check if contact number is valid when submitted
  * Check if task number is valid when submitted
  * Check if expenditure organization is valid when submitted
  * Check if expenditure type is valid when submitted
  * Check if funding Source is valid when submitted
* Validate Invoice Number (Verify against `ap_invoices_all`).
  * If the Invoice Number already exists in the system for a given Vendor in a given Operating Unit, then another Invoice cannot be created with the same Invoice Number.Example: (<http://oraclelabs.phaniadivi.com/2017/08/oracle-payables-invoice-interface-validating-invoice-number/>)
* Validate Vendor Name.
  * The Validation logic should check to see if a vendor already exists for that vendor number. If Yes, then an Invoice can be created for that Supplier. Else, since that Supplier doesn’t exist, Invoices cannot be created against that supplier and the validation should result in error. Example: (<http://oraclelabs.phaniadivi.com/2017/08/oracle-payables-invoice-interface-validate-vendor-number/>)
* Validate PO number if one is provided.
* Validate Invoice Type (Enum: STANDARD, PREPAYMENT, CREDIT, DEBIT)
* Validate Invoice Amount
  * Validate Sum of Line Amount equals Invoice Amount
* Validate Payment Method Code.
* Validate Line Type (Enum: ITEM, FREIGHT, MISCELLANEOUS).




<!--BREAK-->
#### ScmInvoicePayment API Validations

##### Per GraphQL Data Model and Type Resolvers

> These validations will be enforced by the GraphQL parser and data type definitions.

* Valid JSON data structure.
* Required fields (enforced by GraphQL data model)
* Ensure required fields are non-blank. (enforced by GraphQL data model)
* Ensure fields are formatted properly (enforced by GraphQL data model - and custom code if needed)
* Verify maximum lengths on fields.  (Delegate using custom data types if possible.)
  * (e.g., `TrimmedNonEmptyString240`)
* `lineType`  The code you enter must be ITEM, TAX, MISCELLANEOUS, or FREIGHT which is enforced by enum.
* `invoiceType` The value must be CREDIT, STANDARD, PREPAYMENT or DEBIT which is enforced by enum.

##### Request Header Checks

* Validate Invoice Source
  * Verify invoiceSource is allowed for API consumer. (TBD - We will want to link the API Consumer authentication identifier to the invoice sources.)
* Confirm if `consumerTrackingId` previously used and reject if found in the action request table.

##### Data Validation

* **Overall**

  * Verify that a non-zero number of journal lines have been provided.
  * Verify number of lines `<=` 1000 (Preliminary number - should be a constant we can adjust easily via config options)
  * Verify no line was given both GL and POET segments.
  * Verify that any field provided by the consumer that has a valid list of values in Oracle contains a valid and active value.
  * Validate unitOfMeasureCode: validate against  `ArUnitOfMeasure`
  * Validate paymentTerms: verify that term is one of the following: `ArPaymentTerm`
  * Check that Supplier is valid. Validate supplierNumber: `ScmSupplier.supplierNumber`
    * scm_supplier table
  * Ensure that the Site is valid. Validate supplierSiteCode: `ScmSupplier.supplierNumber.suppliers.supplierSiteCode`
    * scm_supplier_site table
  * Check that there is not a previously submitted pending or successful request with the same transaction number for the API consumer.
  * Verify transaction date within last month?
  * Verify no line was given both GL and POET segments.
  * If submitted, verify purchaseOrderNumber is valid. Question: How to do this? We need table to query.
  * Validate Invoice Number does not exist for given Supplier. (Verify against `ap_invoices_all`).
    * If the Invoice Number already exists in the system for a given Vendor in a given Operating Unit, then another Invoice cannot be created with the same Invoice Number.Example: (<http://oraclelabs.phaniadivi.com/2017/08/oracle-payables-invoice-interface-validating-invoice-number/>)
* Validate Vendor Name.
  * The Validation logic should check to see if a vendor already exists for that vendor number. If Yes, then an Invoice can be created for that Supplier. Else, since that Supplier doesn’t exist, Invoices cannot be created against that supplier and the validation should result in error. Example: (<http://oraclelabs.phaniadivi.com/2017/08/oracle-payables-invoice-interface-validate-vendor-number/>)
* Validate Invoice Amount
  * Validate Sum of Line Amount equals Invoice Amount
* Validate Payment Method Code.



* **GL Transactions**
* GL is save in `DIST_CODE_CONCATENATED`
  * Verify values given in GL segments
    * values in each each line's segments.
    * If the program, project, or activity fields have an invalid value, replace with all zeroes.
    * If the purpose has an invalid value, and is not required per the CVR rules below, replace with zeroes.
    * The project in `glSegments` must be a GL-only project.  It must have `GL0000000A` as a parent.  (Use direct parent for now, there is no plan to make the hierarchy multi-level.)
    * Segment must not be a summary value and must allow detail posting. **(TODO)**
  * Verify Accounting Period if given.  It must exist and be open.  Assign current accounting period if missing.  Fail if an invalid period was given.
  * Verify that any field which has a valid list of values contains a valid value.

  * **Boundary API Additional Restrictions**
    * _Net Position Accounts are not allowed_
      * If the account descends from 30000X, fail validation.
    * _PPM Offset Account is not allowed_
      * If the account == `TBD`, fail validation.
  * **Validate via Combination Code** **(TODO)**
    * Check if the combination of the 11 GL segments is a known, valid combination.
    * Using the GlAccountingCombination, check if the combination is valid is known and is active and valid for the given accounting date.  If so, CVR rules do not need to be run.  Oracle will allow any valid combination even if does not match the current CVR rules.  There is no validation failure for this rule.  This is only to short-circuit the CVR rules.
    * Must be open for detail posting, and not a summary combination code.
  * **CVR Matching Rules (message then technical rule)**
    * _Purpose is required for Expense Accounts (OPER_ACC_PURPOSE_1)_
      * If the account descends from 50000B, then the purpose must be a non 00 value.
    * _Financial Aid Expenses must have Student Financial Aid purpose code 78 (OPER_ACC_PURPOSE_4)_
      * If the account descends from 51000A, then the purpose code must be 78.
    * _Purpose code 78 (Student Financial Aid) must only be used with Financial Aid Expenses (OPER_ACC_PURPOSE_5)_
      * If the purpose code is 78, then the account must descend from 51000A.
    * _Auxiliary Funds should only be used for Auxiliary Enterprise (76) purposes (OPER_FUND_PURPOSE)_
      * If the fund is a descendent of 1100C, then purpose code must be 76.
    * _Purpose code 76 (Auxiliary Enterprises) must only be used with Financial Auxilary Funds (OPER_PURPOSE_FUND)_
      * If the purpose code is 76, then the fund must descend from 1100C.
    * _Funds held for others (Account 22700D) should only be used with Agency Fund (Fund 5000C) (AGENCY_FUND_ACCT)_
      * If the account descends from 22700D, then the fund must descend from 5000C.
    * _Sub-contract services (53300B) should only be used on Grant and Contract Funds (2000B)_
      * If the account is a descendent of 53300B, then the fund must be descended from 2000B.

* **PPM Costs**

  * Verify values given in each PPM segment
    * values in each each line's segments.
  * Verify lines have complete PPM segments (project, task, organization, expenditure type)
    * Verify Award and Funding Source populated and valid if the Project has a Sponsored Project type. (per `sponsoredProject` flag on the project type)
      * This would be after derivation of the award and funding source from the project if not provided by the end user.
  * **Validate Project**
    * _Project is not Active_
      * `projectStatus` = `ACTIVE`
    * _Costs can not be assigned to template projects_
      * `templateProject` = false
    * _Given accounting date (yyyy-mm-dd) is not within the project start and completion dates._
      * Check accounting date against the `projectStartDate` and `projectCompletionDate`s.
  * **Validate Task**
    * _Summary tasks may not record costs_
      * is lowest level (`lowestLevelTask`)
    * _Task does not accept costs_
      * marked as `chargeable`
    * _Given accounting date (yyyy-mm-dd) is not within the task start and completion dates._
      * Check accounting date against the `taskStartDate` and `transactionCompletionDate`s.
* **Validate Expenditure Type**
  * Attempt a full match of the given value against the expense type table.  If that fails, and the string is longer than 6 characters, attempt a lookup against the first 6 characters of the expense type.
  * Populate the output with the full name of the expense type.  (This should be the GL account code plus its name.)
  * _Expenditure Type is not active_
    * is active
    * is not outside of start and end dates (`expenditureTypeStartDate` - `expenditureTypeEndDate`)
* **Validate Expenditure Organization**
  * Attempt a full match of the given value against the organization table.  If that fails, and the string is longer than 7 characters, attempt a lookup against the first 7 characters of the organization name.
  * Accounting date falls within expense org dates (`effectiveStartDate` and `effectiveEndDate`)
  * Populate the output with the full name of the organization.  (This should be the financial department code plus the name.)
* **Award and Funding Source**
  * If `sponsoredProject` is false, then no award or funding source may be provided.  _Do not provide an award or funding source except on sponsored projects._
  * Otherwise verify the values if present at that they are linked to the given project.
  * **Validate Award**
    * If provided, the award must be linked to the project.  If not, populate the output with the default award.
    * The accounting date must be between the start date and `closeDate` of the award.
  * **Validate Funding Source**
    * If provided, the award must be linked to the project.  If not, populate the output with the default award.
    * The accounting date must be between the `fundingSourceFromDate` and `fundingSourceToDate` of the funding source.


#### Data Object to Oracle Mapping

* [Oracle Create an Invoice Documentation](https://docs.oracle.com/en/cloud/saas/financials/22a/farfa/op-invoices-x-operations-0.html)
* [Table: AP_INVOICE_INTERFACE](https://docs.oracle.com/en/cloud/saas/financials/21d/oedmf/apinvoicesinterface-9830.html#apinvoicesinterface-9830)
* [Table: AP_INVOICE_LINES_INTERFACE](https://docs.oracle.com/en/cloud/saas/financials/21d/oedmf/apinvoicelinesinterface-24960.html#apinvoicelinesinterface-24960)


#### Request Objects

> Objects passed when making calls to the operations above.

* Main Object: `ScmInvoicePaymentRequestInput`

| Property Name | GraphQL Type                                      | Notes                                                              |
| ------------- | ------------------------------------------------- | ------------------------------------------------------------------ |
| header        | [`ActionRequestHeaderInput`](./1_CommonTypes.md)! | Header information required on all action requests                 |
| payload       | `ScmInvoicePaymentInput`!                         | The main payload used to create the payment in Oracle.  See below. |

<!-- | preValidate   | Boolean                                           | Whether to run more time consuming validations before sending to Oracle. | -->

* Child Request Objects:
  * [`ActionRequestHeaderInput`](./1_CommonTypes.md)
  * `DistributionInput`
    * [`GlSegmentInput`](./1_CommonTypes.md)
    * [`GlSegmentString`](./1_CommonTypes.md)
    * `glDistributionSetCode` : String
    * [`PpmSegmentInput`](./1_CommonTypes.md)


#### Response Objects

* `ScmInvoicePaymentStatusOutput`
  * Child Request Objects:
    * [`ActionRequestStatus`](./1_CommonTypes.md)

#### Object Properties

> Note: Object properties are for general documentation only.  The definitive data model is defined by the SDL retrieved from the graphql servers.

##### `ScmInvoicePaymentInput`

| Property Name       | Type                     | Notes                                                                                                                               |
| ------------------- | ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| accountingDate      | Date                     | The date when the payment is to be accounted.                                                                                       |
| businessUnit        | NonEmptyTrimmedString240 | Indicates the business unit name for the invoice                                                                                    |
| invoiceDescription  | NonEmptyTrimmedString240 | The user description for a payment.                                                                                                 |
| invoiceAmount       | Float                    | The payment amount in payment currency.                                                                                             |
| invoiceDate         | Date                     | The date on the supplier invoice.                                                                                                   |
| invoiceNumber       | NonEmptyTrimmedString50  | The unique number for supplier invoice.                                                                                             |
| invoiceSourceCode   | NonEmptyTrimmedString25  | Code that indicates the feeder system from which an invoice is created                                                              |
| invoiceType         | ScmInvoiceType           | The type of the invoice. The valid invoice types are Standard, Prepayment, Credit Memo, Debit Memo.                                 |
| paymentMethodCode   | NonEmptyTrimmedString30  | The user-entered payment method code that helps to uniquely identify a payment method.                                              |
| paymentTerms        | NonEmptyTrimmedString50  | The payment terms used to calculate installments and to calculate due dates, discount dates, and discount amounts for each invoice. |
| purchaseOrderNumber | NonEmptyTrimmedString30  | The purchase order document number that is matched to the invoice.                                                                  |
| supplierNumber      | NonEmptyTrimmedString30  | The unique number to identify the supplier.                                                                                         |
| supplierSiteCode    | NonEmptyTrimmedString15  | The name of the physical location of the supplier from where the goods and services are rendered.                                   |

##### `ScmInvoiceLineInput`

| Property Name           | Type                                    | Notes                                                                            |
| ----------------------- | --------------------------------------- | -------------------------------------------------------------------------------- |
| itemName                | NonEmptyTrimmedString255                | The inventory item name.                                                         |
| itemDescription         | NonEmptyTrimmedString240                | The description of the invoice line.                                             |
| lineAmount              | Float                                   | The line amount in invoice currency.                                             |
| lineType                | ScmLineType                             | The type of invoice line.  The valid values are Item, Freight and Miscellaneous. |
| purchaseOrderLineNumber | Int                                     | The purchase order line number that is matched to the invoice line.              |
| purchasingCategory      | NonEmptyTrimmedString250                | The unique identifier for the item category.                                     |
| quantity                | Int                                     | The quantity of items                                                            |
| unitOfMeasureCode       | NonEmptyTrimmedString25                 | The unit of measure for the quantity invoiced.                                   |
| unitPrice               | Float                                   | The price charged per unit of a good or service                                  |
|                         |                                         | **GL Distribution / PPM Costing Fields**                                         |
| glSegments              | [`GlSegmentInput`](./1_CommonTypes.md)  |                                                                                  |
| glSegmentString         | String                                  | Delimited complete GL segment string.                                            |
| ppmSegments             | [`PpmSegmentInput`](./1_CommonTypes.md) | PPM POET segment values                                                          |

##### `ScmPaymentStatusOutput`

> Response provided when the consumer submits a request.

| Property Name         | Type                                         | Notes                                                                                                     |
| --------------------- | -------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| requestStatus         | [`ActionRequestStatus`](./1_CommonTypes.md)! | General action request status and tracking information.                                                   |
|                       |                                              | **ScmPayment-Specific Properties**                                                                        |
| paymentProcessRequest | String                                       | The name of payment batch or quick payment identifier.  Only populated once the payment has been created. |
|                       |                                              |                                                                                                           |


#### Example `scmPaymentCreate` Requests

> Below are samples of the data object to be passed into the `scmPaymentCreate` mutation.
> Ignore the specific values.  No real attempt has been made to determine the actual values expected by Oracle.


```jsonc
{
  // general request tracking information
  "header": {
    "consumerTrackingId": "5A314F00-C308-48FF-BF85-C8AF7FD43199", // unique ID assigned by boundary app
    "consumerReferenceId":  "ORDER_12345", // reference number used to pull multiple requests related to it
    "consumerNotes": "July Order from Xxxxxxx", // free-form description to include in later status checks
    "boundaryApplicationName": "My Boundary App" // name of the source boundary application
  },
  "payload": {
    "InvoiceNumber": "AND_Unmatched_Invoice",
    "InvoiceCurrency": "USD",
    "InvoiceAmount": 2212.75,
    "InvoiceDate": "2019-02-01",
    "BusinessUnit": "Vision Operations",
    "Supplier": "Advanced Network Devices",
    "SupplierSite": "FRESNO",
    "Requester": "Johnson,Mary",
    "InvoiceGroup": "01Feb2019",
    "Description": "Office Supplies",

    // Array of accounting lines to post
   "invoiceLines": [{
        "LineNumber": 1,
        "LineAmount": 2112.75,

        "invoiceDistributions": [{
            "DistributionLineNumber": 1,
            "DistributionLineType": "Item",
            "DistributionAmount": 2112.75,
            "DistributionCombination": "01-420-7110-0000-000"

        }]
        },
        {
            "LineNumber": 2,
            "LineType": "Freight",
            "LineAmount": 100,
            "ProrateAcrossAllItemsFlag": true
        }]
  }
}
```

#### Questions



#### Example `scmInvoicePaymentRequest` Response

> Initial response after submitting request.  Oracle-provided data in the response will not be populated.

```jsonc
{
  "requestStatus": {
    "requestId": "BA77D46E-C610-406E-B426-38939E432968",
    "consumerId": "API_CONSUMER_ID",
    "consumerTrackingId": "5A314F00-C308-48FF-BF85-C8AF7FD43199", // unique ID assigned by boundary app
    "consumerReferenceId":  "ORDER_12345", // reference number used to pull multiple requests related to it
    "consumerNotes": "July Order from Xxxxxxx", // free-form description to include in later status checks
    "boundaryApplicationName": "My Boundary App", // name of the source boundary application
    "operationName": "scmInvoicePaymentRequest",
    "requestDateTime": "2021-07-23T17:00:00-0700",
    "requestStatus": "UNPROCESSED",
    "lastStatusDateTime": "2021-07-23T17:00:00-0700",
    "processedDateTime": null,
    "errorMessages": [],
    "statusRequestPayload": "{ \\"query\\": \\"query { scmInvoicePaymentRequestStatus(requestId:\\\\\\"BA77D46E-C610-406E-B426-38939E432968\\\\\\") { requestStatus { requestId consumerId requestTime } }\\"}",
    "actionRequestPayload": "" // too large - would be entire request input
  },
}
```




#### Data Object to Oracle Mapping

> Base Object:                                             `ScmInvoicePaymentRequestInput`
> `payload`:                                               `ScmInvoicePaymentInput`
> `payload.invoiceLines`:                                  `[ScmInvoiceLineInput]`
> `payload.invoiceLines.invoiceDistributions`:             `[ScmInvoiceDistributionInput]`
> `payload.invoiceLines.invoiceDistributions.glSegments`:  `GlSegmentInput`
> `payload.invoiceLines.invoiceDistributions.ppmSegments`: `PpmSegmentInput`

* [Oracle Create an Invoice Documentation](https://docs.oracle.com/en/cloud/saas/financials/22a/farfa/op-invoices-x-operations-0.html)
* [Table: AP_INVOICES_INTERFACE](https://docs.oracle.com/en/cloud/saas/financials/21d/oedmf/apinvoicesinterface-9830.html#apinvoicesinterface-9830)
* [Table: AP_INVOICE_LINES_INTERFACE](https://docs.oracle.com/en/cloud/saas/financials/21d/oedmf/apinvoicelinesinterface-24960.html#apinvoicelinesinterface-24960)

| GraphQL Property                                 | Req? | Oracle FBDI Destination                                                                           | Column                                              |
|--------------------------------------------------|------|---------------------------------------------------------------------------------------------------|-----------------------------------------------------|
| **Invoice Fields**                               |      | ------------------------------------                                                              | `AP_INVOICES_INTERFACE`                             |
| payload.accountingDate                           |      | The date when the payment is to be accounted.                                                     |                                                     |
| payload.businessUnit                             |      | Indicates the business unit name for the invoice.                                                 | OPERATING_UNIT                                      |
| payload.invoiceDescription                       |      | The statement that describes the invoice.                                                         | DESCRIPTION                                         |
| invoiceAmount                                    | Yes  | The invoice amount in transaction currency. The value must be provided while creating an invoice. | INVOICE_AMOUNT                                      |
| Constant: `USD`                                  |      | Currency of invoice. (USD)                                                                        | INVOICE_CURRENCY_CODE                               |
| payload.invoiceDate                              |      | The date on the supplier invoice.                                                                 | INVOICE_DATE                                        |
| payload.invoiceNumber                            |      | The unique number for supplier invoice.                                                           | INVOICE_NUM                                         |
| payload.invoiceSource                            |      | The source that indicates the feeder system from which an invoice is created.                     | SOURCE ***                                          |
| payload.invoiceSourceCode                        |      | Code that indicates the feeder system from which an invoice is created.                           |                                                     |
| payload.invoiceType                              |      | The type of the invoice. The valid invoice types are Standard, Prepayment, Creditand  Debit.      | INVOICE_TYPE_LOOKUP_CODE ****                       |
| payload.paymentMethodCode                        |      | The user-entered payment method code that helps to uniquely identify a payment method.            | PAYMENT_METHOD_LOOKUP_CODE ****                     |
| payload.paymentTerms                             |      | The payment terms                                                                                 | TERMS_NAME                                          |
| payload.purchaseOrderNumber                      |      | The purchase order document number that is matched to the invoice.                                | PO_NUMBER                                           |
| payload.supplierNumber                           |      | The unique number to identify the supplier.                                                       | VENDOR_NUM                                          |
| payload.supplierSiteCode                         |      | Supplier Site Code                                                                                | VENDOR_SITE_CODE                                    |
| **Invoice Line Fields**                          |      | ------------------------------------                                                              | `AP_INVOICE_LINES_INTERFACE`                        |
| payload.invoiceLines.itemName                    |      | The inventory item name                                                                           |                                                     |
| payload.invoiceLines.itemDescription             |      | The description of the item in the invoice line.                                                  | ITEM_DESCRIPTION                                    |
| payload.invoiceLines.lineAmount                  |      | The line amount in invoice currency.                                                              | AMOUNT                                              |
| payload.invoiceLines.lineType                    |      | The type of invoice line.                                                                         | LINE_TYPE_LOOKUP_CODE ***                           |
| payload.invoiceLines.purchaseOrderLineNumber     |      | The purchase order line number that is matched to the invoice line.                               | PO_LINE_NUMBER                                      |
| payload.invoiceLines.purchasingCategory          |      | The unique identifier for the item category                                                       | PURCHASING_CATEGORY_ID ***                          |
| payload.invoiceLines.quantity                    |      | The quantity of items invoiced                                                                    | QUANTITY_INVOICED                                   |
| payload.invoiceLines.unitOfMeasureCode           |      | The unit of measure for the quantity invoiced                                                     | UNIT_OF_MEAS_LOOKUP_CODE                            |
| payload.invoiceLines.unitPrice                   |      | The price charged per unit of a good or service.                                                  | UNIT_PRICE                                          |
| payload.invoiceLines.ppmSegments.project         |      | Project Number                                                                                    | PROJECT_ID                                          |
| payload.invoiceLines.ppmSegments.task            |      | Task Number                                                                                       | TASK_ID                                             |
| payload.invoiceLines.ppmSegments.expenditureType |      | Expenditure Type                                                                                  | EXPENDITURE_TYPE                                    |
| payload.invoiceLines.ppmSegments.organization    |      | Expenditure Organization                                                                          | EXPENDITURE_ORGANIZATION_ID                         |
| payload.invoiceLines.ppmSegments.award           |      | Contract Name / Contract Number                                                                   | PJC_CONTRACT_NAME / PJC_CONTRACT_NUMBER             |
| payload.invoiceLines.ppmSegments.fundingSource   |      | Funding Source Name / Funding Source Number                                                       | PJC_FUNDING_SOURCE_NAME / PJC_FUNDING_SOURCE_NUMBER |
|                                                  |      |                                                                                                   |                                                     |



#### Questions

> * Where can I map glSegments/ppmSegments on Rest API? 
> * Is GLSegmentString '0000-00000-0000000-000000-00-000-0000000000-000000-0000-000000-000000'  mapped to distributionCombination in REST API?
> * Where do we map ppmSegments in REST API? 
> 
> * Where do I find Manage Payable Lookup tables?!
> 
> * GROUP_ID where to obtain this info? VARCHAR2(80) vs input invoiceGroup VARCHAR(255)
> * DOC_CATEGORY_CODE VARCHAR(30) vs documentCategory VARCHAR2(255). Do we need it?
> * SOURCE VARCHAR2(80)  vs invoiceSource VARCHAR2(255).
> * INVOICE_TYPE_LOOKUP_CODE VARCHAR2(25) vs invoiceType
> * PAYMENT_METHOD_LOOKUP_CODE VARCHAR(25) vs paymentMethod VARCHAR2(30)
> * INVENTORY_ITEM_ID item VARCHAR(255)
> * LINE_TYPE_LOOKUP_CODE  vs lineType:ScmLineType
> * PURCHASING_CATEGORY_ID  vs purchasingCategory VARCHAR(250)

#### Validations

> * UNIT_OF_MEAS_LOOKUP_CODE: Validated against INV_UNITS_OF_MEASURE.UNIT_OF_MEASURE? Or perhaps ArUnitOfMeasure
> * Accounting Date: Date format: YYYY/MM/DD.
> 
##### Property Lookup Validations

| GraphQL Property                                        | Local Data Object/Table | Local Data Object Property |
|---------------------------------------------------------|-------------------------|----------------------------|
| payload.invoiceSource                                   |                         |                            |
| payload.customerAccountNumber                           |                         |                            |
| payload.paymentTerms                                    | ArPaymentTerm           | code                       |
| payload.supplier                                        | scmSupplier             | code                       |
| payload.supplierNumber                                  | scmSupplier             | code                       |
| payload.supplierSite                                    | scmSupplier             | code                       |
| payload.invoiceLines.unitOfMeasureCode                  | ArUnitOfMeasure         | code                       |
| payload.invoiceLines.glSegments.entity                  | ErpEntity               | code                       |
| payload.invoiceLines.glSegments.fund                    | ErpFund                 | code                       |
| payload.invoiceLines.glSegments.department              | ErpFinancialDepartment  | code                       |
| payload.invoiceLines.glSegments.account                 | ErpAccount              | code                       |
| payload.invoiceLines.glSegments.purpose                 | ErpPurpose              | code                       |
| payload.invoiceLines.glSegments.program                 | ErpProgram              | code                       |
| payload.invoiceLines.glSegments.project                 | ErpProject              | code                       |
| payload.invoiceLines.glSegments.activity                | ErpActivity             | code                       |
| payload.lines.distributions.ppmSegments.project         | ppmProject              | code                       |
| payload.lines.distributions.ppmSegments.task            | ppmTask                 | code                       |
| payload.lines.distributions.ppmSegments.organization    | ppmOrganization         | code                       |
| payload.lines.distributions.ppmSegments.expenditureType | ppmExpenditureType      | code                       |
| payload.lines.distributions.ppmSegments.award           | ppmAward                | code                       |
| payload.lines.distributions.ppmSegments.fundingSource   | ppmFundingSource        | code                       |
