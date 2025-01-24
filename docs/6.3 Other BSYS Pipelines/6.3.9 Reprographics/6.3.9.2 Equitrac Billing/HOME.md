# 6.3.9.2 Equitrac Billing


#### Summary

Equitrac application stores all transactional data in an MSSQL database.  These transactions are datetime stamped, however they are not always loaded in immediately after the transaction is completed.  There are cases where a transaction may be uploaded days or weeks after it originally took place, with the datetime stamp referencing that previous date.  Because of this, it's not possible to merely query out records from a particular date range without the possibility of losing some of these future backdated transactions.

Planned solution would be for the pipeline to query out all transactions over the preceding X days (90 for instance), and after processing a transaction into a journal, the foreign primary key would be stored in a local data source (PgSQL?) so that the pipeline knows not to process that transaction again.  This should limit the number of records that NiFi is having to pull down from the MSSQL server to a reasonable level, without losing any backdated transactions that are posted to the server within a set amount of time.

#### Pipeline Dependencies

* TBD