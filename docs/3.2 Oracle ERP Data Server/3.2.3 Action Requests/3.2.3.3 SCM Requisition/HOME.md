# 3.2.3.3 SCM Requisition

<!--BREAK-->
### Action Request: `ScmPurchaseRequisition`

#### Overview

This request allows the submitting boundary application to create purchase requisition request in the Oracle Financials system.  It accepts the provided data for a single requisition and runs validation prior to storing it for processing by the integration platform.


#### Access Controls

* Required Role: `erp:writer-requisition`
* Required Role: `erp:reader-supplier`

#### Basic Use

1. Consumer calls the operation providing a data payload with the proper structure.
2. API Server will perform validation against locally extracted Oracle ERP data.
3. A failure in these initial validations will result in an error response being returned and no request being generated.
4. Passing initial validation will save and submit the request to the integration platform for processing.
5. A request tracking ID will be generated and returned to allow for the consumer to check on the status of the request and obtain results when completed.

#### Operations

##### `scmPurchaseRequisitionRequest`

* **Parameters**
  * `data : ScmPurchaseRequisitionInput!`
* **Returns**
  * `ScmPurchaseRequisitionRequestStatusOutput!`


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

* Validate requisitionSourceName : ?
* Validate requisitionCategoryName: ?
* Validate requesterName: ?
* Check that Supplier is valid. Validate supplierNumber: `ScmSupplier.supplierNumber`
  * scm_supplier table
* Ensure that the Site is valid. Validate supplierSiteCode: `ScmSupplier.supplierNumber.suppliers.supplierSiteCode`
  * scm_supplier_site table
* Validate unitOfMeasureCode: this will probably be enum?  `ErpUnitOfMeasure`
* Validate deliverToTypeCode - probably just enum. What should be in it?
* Validate deliveryToLocationCode: ? Against `ErpLocation` table assuming that all uc locations are loaded there as well?
* Validate glSegment
* Validate glSegment String
* Validate ppmSegment:
  * Validate POET (Project, Organization, Expenditure, Task).
* Check that `ScmPurchaseRequisitionLineInput.amount` represents sum of  `ScmPurchaseRequisitionDistributionInput.amount`


#### Data Object to Oracle Mapping

> Base Object:                                      `ScmPurchaseRequisitionRequestInput`
> `payload`:                                        `ScmPurchaseRequisitionInput`
> `payload.lines`:                                  `[ScmPurchaseRequisitionLineInput]`
> `payload.lines.distributions`:                    `[ScmPurchaseRequisitionDistributionInput]`
> `payload.lines.distributions.glSegments`:  `GlSegmentInput`
> `payload.lines.distributions.ppmSegments`: `PpmSegmentInput`


* [Oracle Requisition Documentation](https://docs.oracle.com/en/cloud/saas/procurement/21c/fapra/api-purchase-requisitions.html)
* [Table: POR_REQ_HEADERS_INTERFACE_ALL](https://docs.oracle.com/en/cloud/saas/procurement/21c/oedmp/self-service-procurement.html#porreqheadersinterfaceall-5884)
* [Table: POR_REQ_LINES_INTERFACE_ALL](https://docs.oracle.com/en/cloud/saas/procurement/21c/oedmp/self-service-procurement.html#porreqheadersinterfaceall-5884)
* [Table: POR_REQ_DISTS_INTERFACE_ALL](https://docs.oracle.com/en/cloud/saas/procurement/21c/oedmp/self-service-procurement.html#porreqdistsinterfaceall-25349)


| GraphQL Property                                            | Req? | Oracle FBDI Destination                                                                                                               | Column                          |
| ----------------------------------------------------------- | ---- | ------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| **Purchase Requisition Header Fields**                      |      | ------------------------------------                                                                                                  | `POR_REQ_HEADERS_INTERFACE_ALL` |
| payload.requisitionSourceName                               | Yes  | Centrally assigned source name for your boundary applicationName                                                                      | INTERFACE_SOURCE_CODE????       |
| payload.requisitionCategoryName                             | Yes  | Centrally assigned category name for your boundary application's feed                                                                 |                                 |
| payload.supplierNumber                                      | Yes  | Supplier Number                                                                                                                       |                                 |
| payload.requesterName                                       | Yes  | Requester Number                                                                                                                      | REQUESTER_NAME                  |
| payload.supplierSiteCode                                    | Yes  | Value that uniquely identifies the supplier site                                                                                      |                                 |
| payload.description                                         | Yes  | Description of the requisition                                                                                                        | DESCRIPTION                     |
| payload.justification                                       | Yes  | Reason for creating the requisition                                                                                                   | JUSTIFICATION                   |
| payload.transactionDate                                     | Yes  | Transaction Date                                                                                                                      | CREATION_DATE                   |
| **Purchase Requisition Line Fields**                        |      | ------------------------------------                                                                                                  | `POR_REQ_LINES_INTERFACE_ALL`   |
| payload.lines.itemDescription                               | Yes  | Description of the goods or services being purchased                                                                                  | ITEM_DESCRIPTION                |
| payload.lines.amount                                        | Yes  | Amount                                                                                                                                | AMOUNT                          |
| payload.lines.quantity                                      |      | Quantity ordered  Quantity                                                                                                            | QUANTITY                        |
| payload.lines.unitOfMeasureCode                             |      | Unit of Measure Code                                                                                                                  | UOM_CODE                        |
| payload.lines.purchasingCategoryName                        |      | Name of the purchasing category that is used for classifying the purchase being made by using this order line                         | CATEGORY_NAME                   |
| payload.lines.deliveryToTypeCode                            |      |                                                                                                                                       |                                 |
| payload.lines.requestedDeliveryDate                         |      | Date by which the requested item is needed                                                                                            | REQUESTED_DELIVERY_DATE         |
| payload.lines.deliveryToLocationCode                        |      | Abbreviation that identifies the final location where the buying company should deliver the goods previously received from a supplier | DELIVER_TO_LOCATION_CODE        |
| Constant: `USD`                                             |      | Currency Code                                                                                                                         | CURRENCY_CODE                   |
| **Purchase RequisitionLine Distribution Fields**            |      | ------------------------------------                                                                                                  | `POR_REQ_DISTS_INTERFACE_ALL`   |
| payload.lines.distributions.amount                          | ***  | Amount                                                                                                                                | AMOUNT                          |
| payload.lines.distributions.percent                         | ***  | Percent                                                                                                                               | PERCENT                         |
| payload.lines.distributions.quantity                        | ***  | Quantity of the distribution.                                                                                                         | DISTRIBUTION_QUANTITY           |
| payload.lines.distributions.glSegments.entity               | Yes  | Accounting Flexfield Segment 1                                                                                                        | SEGMENT1                        |
| payload.lines.distributions.glSegments.fund                 | Yes  | Accounting Flexfield Segment 2                                                                                                        | SEGMENT2                        |
| payload.lines.distributions.glSegments.department           | Yes  | Accounting Flexfield Segment 3                                                                                                        | SEGMENT3                        |
| payload.lines.distributions.glSegments.account              | Yes  | Accounting Flexfield Segment 4                                                                                                        | SEGMENT4                        |
| payload.lines.distributions.glSegments.purpose              |      | Accounting Flexfield Segment 5                                                                                                        | SEGMENT5                        |
| payload.lines.distributions.glSegments.program              |      | Accounting Flexfield Segment 6                                                                                                        | SEGMENT6                        |
| payload.lines.distributions.glSegments.project              |      | Accounting Flexfield Segment 7                                                                                                        | SEGMENT7                        |
| payload.lines.distributions.glSegments.activity             |      | Accounting Flexfield Segment 8                                                                                                        | SEGMENT8                        |
| Constant: `0000`                                            |      | Accounting Flexfield Segment 9                                                                                                        | SEGMENT9                        |
| Constant: `000000`                                          |      | Accounting Flexfield Segment 10                                                                                                       | SEGMENT10                       |
| Constant: `000000`                                          |      | Accounting Flexfield Segment 11                                                                                                       | SEGMENT11                       |
| payload.lines.distributions.ppmSegmentInput.project         | Yes  | Managed Project Number                                                                                                                | PJC_PROJECT_NAME                |
| payload.lines.distributions.ppmSegmentInput.PpmTaskNumber   | Yes  | Task ID.  Must belong to Project and be a chargeable task                                                                             |                                 |
| payload.lines.distributions.ppmSegmentInput.organization    | Yes  | Organization for which the expense is being incurred                                                                                  | PJC_ORGANIZATION_NAME           |
| payload.lines.distributions.ppmSegmentInput.expenditureType | Yes  | Type of expense being charged to the project                                                                                          |                                 |
| PJC_EXPENDITURE_TYPE_NAME                                   |      |                                                                                                                                       |                                 |

* Either Amount or Percent are required, but not both.
* Derived value from project: `payload.lines.distributions.ppmSegmentInput.organization`
* Derived value from project: `payload.lines.distributions.ppmSegmentInput.fundingSource`


###### Questions

##### Property Lookup Validations

| GraphQL Property                                        | Local Data Object      | Local Data Object Property |
| ------------------------------------------------------- | ---------------------- | -------------------------- |
| payload.supplier                                        | scmSupplier            |                            |
| payload.supplierNumber                                  | scmSupplier            |                            |
| payload.supplierSite                                    | scmSupplier            |                            |
| payload.paymentTermsName                                | ArPaymentTerm          | name                       |
| payload.lines.unitOfMeasureCode                         | ErpUnitOfMeasure       | code                       |
| payload.lines.distributions.glSegments.entity           | ErpEntity              | code                       |
| payload.lines.distributions.glSegments.fund             | ErpFund                | code                       |
| payload.lines.distributions.glSegments.department       | ErpFinancialDepartment | code                       |
| payload.lines.distributions.glSegments.account          | ErpAccount             | code                       |
| payload.lines.distributions.glSegments.purpose          | ErpPurpose             | code                       |
| payload.lines.distributions.glSegments.program          | ErpProgram             | code                       |
| payload.lines.distributions.glSegments.project          | ErpProject             | code                       |
| payload.lines.distributions.glSegments.activity         | ErpActivity            | code                       |
| payload.lines.distributions.ppmSegments.project         | ppmProject             | code                       |
| payload.lines.distributions.ppmSegments.task            | ppmTask                | code                       |
| payload.lines.distributions.ppmSegments.organization    | ppmOrganization        | code                       |
| payload.lines.distributions.ppmSegments.expenditureType | ppmExpenditureType     | code                       |
| payload.lines.distributions.ppmSegments.award           | ppmAward               | code                       |
| payload.lines.distributions.ppmSegments.fundingSource   | ppmFundingSource       | code                       |
