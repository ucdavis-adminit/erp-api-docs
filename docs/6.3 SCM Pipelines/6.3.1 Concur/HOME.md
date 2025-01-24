# 6.3.1 Concur

### Summary

Concur Expense (AggieTravel) has a large number of integrations which will require data pipelines.  It both receives GL and POET segment data as well as generates GL/PPM entries and payments.  It also has a number of other ancillary integrations which do not interact with Oracle.  Those will be moved into here at some point, but are not the initial development focus.

* **Functional Specification: <https://ucdavis.app.box.com/file/947317608126>**

There is one outbound feed from Oracle to Concur and one inbound feed from Concur.  The outbound feed contains GL and POET segment data.  The inbound feed contains completed expense reports since the previous feed.  This feed is then split into multiple components and feed into Oracle as required.

There are also three other feeds which will be coming in from outside systems to be posted to Oracle (and one to Concur.)  These are the US Bank transaction files for the travel card and purchasing card and the CTS travel agency file.  All of these files are used to record the expenses incurred in default chartstrings for the relevant traveller.  (The CTS file also needs to feed into Concur as "quick expenses" that can be reconciled by the traveller.)

### Pipelines

* [6.3.1.1 Travel and Purchasing Card Allocations](#/6%20Data%20Pipelines/6.3%20Custom%20Pipelines/6.3.1%20Concur/6.3.1.1%20Card%20Allocations/HOME ':ignore')
* [6.3.1.2 Traveller Reimbursements](#/6%20Data%20Pipelines/6.3%20Custom%20Pipelines/6.3.1%20Concur/6.3.1.2%20Traveller%20Reimbursements/HOME ':ignore')
* [6.3.1.3 Bank Card Default Expensing](#/6%20Data%20Pipelines/6.3%20Custom%20Pipelines/6.3.1%20Concur/6.3.1.3%20Bank%20Card%20Default%20Expensing/HOME ':ignore')
* [6.3.1.4 GL-PPM Segment Upload](#/6%20Data%20Pipelines/6.3%20Custom%20Pipelines/6.3.1%20Concur/6.3.1.4%20GL-PPM%20Segment%20Upload/HOME ':ignore')
  * This upload includes the approver information for the cost center segment as well as a separate upload file to push the cost center approvers into concur.
* [6.3.1.5 SAE Ingestion](#/6%20Data%20Pipelines/6.3%20Custom%20Pipelines/6.3.1%20Concur/6.3.1.5%20SAE%20Ingestion/HOME ':ignore')
* [6.3.1.6 Travel Agency Allocation](#/6%20Data%20Pipelines/6.3%20Custom%20Pipelines/6.3.1%20Concur/6.3.1.6%20Travel%20Agency%20Allocation/HOME ':ignore')
* [6.3.1.7 CTS Default Expensing](#/6%20Data%20Pipelines/6.3%20Custom%20Pipelines/6.3.1%20Concur/6.3.1.7%20CTS%20Default%20Expensing/HOME ':ignore')

### Pending Pipelines

1. CTS Agency Feed Journal
2. CTS Allocation Journal
3. Cash Advance Payments

### Retired (after KFS)

1. Payment Confirmation
2. Financial Approver (merged with list)
3. Validation Lists

#### Sub-Pipeline Dependencies

* GL/PPM Validated Input
* Error Reporting
* Oracle Job Submission
