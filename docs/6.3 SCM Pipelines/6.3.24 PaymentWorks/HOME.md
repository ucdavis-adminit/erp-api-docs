# 6.3.24 PaymentWorks

## Overview

PaymentWorks is a supplier portal which allows businesses to request to be added as suppliers for UCD.  It also serves as a payment portal, by which ACH payments are passed through PaymentWorks on their way to the bank and suppliers can (if we send the information) view open invoices and payment status/history.

The integration component of this comes in three parts:

1. Setup and maintenance of suppliers in Oracle via approved changes made in PaymentWorks.
2. Sending of invoice information to PaymentWorks for suppliers to view.
3. Sending information on payments for the above invoices to PaymentWorks.

## High-Level Flows

### New Supplier Registration

PaymentWorks provides an API which allows us to pull the list of approved new suppliers for us to add to Oracle.  Their APIs retain a status of "approved" until we tell them it has been processed.  As such, PaymentWorks will be the source of necessary work for this pipeline, and no custom tables will be needed to track.

* Hourly - call API to get new approved supplier records - max 20
* Iterate over returned results
  * MIGHT have to call the details getter API for each one
* Call Oracle Supplier API(s) to create supplier and site
  * This should generate the needed IDs immediately
* Make API call back to PW to provide the supplier number and site code
* Make API call back to PW to mark as processed (if the above does not imply that)
  * This last part makes the process restart-safe - can just run the process again if there is a failure at any time


## PaymentWorks Documentation References

* Main Integration Page: <https://community.paymentworks.com/payers/s/article/Integrating-PaymentWorks-with-Your-ERP>
* API Documentation: <https://www.paymentworks.com/integration-docs/>
* Integration Overview: <https://community.paymentworks.com/payers/s/article/ERP-to-PaymentWorks-Data-Flows>
* PaymentWorks field Definitions: <https://www.dropbox.com/scl/fi/c6w3p2xmow7jb86etyqi4/PaymentWorks-Field-Index-for-Mapping.xlsx?rlkey=5iwk27196um061zh6rb7uyomt&e=1&dl=0>

## Implementation Work Components

1. Secure providing of initial supplier data to PaymentWorks.  (presently being handled by SCM - production data which will contain all vendor TINs may need to be handled by Ops.)
2. Configuration of a DFF field within Oracle to store the PaymentWorks vendor ID/request number.
3. One-time process to update the DFF fields above after suppliers imported into PaymentWorks.
4. Analysis and experimentation with the Oracle APIs to determine how they behave when attempting to create suppliers.  (both successful and unsuccessful operations)
5. Analysis and experimentation with the PaymentWorks APIs to determine their behavior and responses.
6. Establishment and configuration of PW API Credentials.
7. NiFi Process Group to
   1. poll PW API for new and updated suppliers
   2. import new suppliers into Oracle via API
   3. send the Oracle vendor number back to PW via API
   4. Update oracle information on updated suppliers
   5. Update the vendor request as processed in PW via API
8. Creation of new ACH BIPublisher file to send payment data to PaymentWorks.
    1. Per discussions - this would be a copy of the existing ACH file format with the potential splitting of data by invoice along with invoice numbers (in the addenda records?) so that PW can match them up with invoices we have exported to them.
    2. Changes to GoAnywhere or Oracle configuration to SFTP the payment file to PaymentWorks
9. NiFi Process group to extract invoices for PaymentWorks suppliers, format, and send to PaymentWorks via API calls.
10. Error handling and feedback components…possible daily reports?  (Depends on what is needed and what PaymentWorks provides…or perhaps could be an OTBI report…)


## References

* Payment Method - <https://community.oracle.com/customerconnect/discussion/516134/how-to-use-rest-apis-for-supplier-payment-attributes>
* Banking info - <https://community.oracle.com/customerconnect/discussion/519047/how-to-use-rest-apis-for-supplier-bank-accounts?utm_source=community-search&utm_medium=organic-search&utm_term=rest+api+add+bank+account>
* <https://docs.oracle.com/en/cloud/saas/financials/24b/oedmf/ibyexternalpayeesall-17348.html>
* IBY_EXT_BANK_ACCOUNTS_V
  * PRIMARY_ACCT_OWNER_PARTY_ID is the PARTY_ID from POZ_SUPPLIERS_V
* IBY_EXT_PARTY_PMT_MTHDS
* IBY_EXTERNAL_PAYEES_ALL
* POZ_SUPPLIERS_V
