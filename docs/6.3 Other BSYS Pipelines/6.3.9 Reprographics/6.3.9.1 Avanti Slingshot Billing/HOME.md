# 6.3.9.1 Avanti Slingshot Billing


#### Summary

Avanti Slingshot application will export CSV file which contains all data required for creating GL/PPM journals to handle recharge income and expense.  AdminIT Operations will move file into ingestion directory using GoA MFT as they currently do for FIN-INT Spring Batch job.  NiFi pipeline will be scheduled to run at a time after this MFT job is run.  CSV will be imported as records, and needs to be partitioned by Sales Order so that all credits and debits remain together for processing into the journal.  If any lines in a partition fail validation, the entire Sales Order must be dropped to keep the journal balanced (alternatively see about trying to resolve via a "kickout" account that could be configured).

#### Pipeline Dependencies

* TBD