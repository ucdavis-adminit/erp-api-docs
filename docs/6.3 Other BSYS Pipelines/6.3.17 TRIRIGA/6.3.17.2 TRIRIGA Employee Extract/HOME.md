# 6.3.17.2 TRIRIGA Employee Extract


#### Summary

This pipeline extracts employee records from IAM and sends incremental changes to TRIRIGA.

#### General Process Flow

1. Extract recently-updated employee records from the IAM schema in the PG integration database.
2. Package the records up into a tab-delimited text file.
3. Drop the file into S3. GoAnywhere will pick up the file and deliver it to TRIRIGA's SFTP endpoint.

#### Pipeline Dependencies

* None

#### Maintenance History

1. [INT-1605](https://afs-dev.ucdavis.edu/jira/browse/INT-1605) NiFi: Creates a new pipeline to send incremental employee record changes to TRIRIGA.