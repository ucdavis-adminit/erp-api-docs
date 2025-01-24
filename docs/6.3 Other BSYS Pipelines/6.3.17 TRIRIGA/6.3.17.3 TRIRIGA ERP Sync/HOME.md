# 6.3.17.3 TRIRIGA ERP Sync


#### Summary

This pipeline extracts Aggie Enterprise maintenance and transactionn records from ERP (PG) and sends incremental changes to TRIRIGA. 
This pipeline replaces Dynamics SL ERP Sync (6.3.14.3).

1. GL Chart String segments: Entity, Fund, Financial Department, etc.
2. PPM Chart String segments: Project, Task, Program, etc.
3. SCM codes: Suppliers, Supplier Site Codes, Purchasing Categories, etc.
4. AP invoices.
5. (maybe) Purchase Orders.


#### General Process Flow

1. Extract recently-updated records from the ERP schema in the PG integration database.
2. Transform the Avro payload into a tab-delimited text files.
3. Drop the text files into S3. GoAnywhere will pick up the files and deliver them to TRIRIGA.

#### Pipeline Dependencies

* None

#### Maintenance History

1. [AMS-1509](https://afs-dev.ucdavis.edu/jira/browse/AMS-1509) Import Aggie Enterprise data into TRIRIGA.

