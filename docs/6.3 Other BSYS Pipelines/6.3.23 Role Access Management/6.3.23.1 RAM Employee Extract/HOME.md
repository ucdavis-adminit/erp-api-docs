# 6.3.23.1 RAM Employee Extract


#### Summary

This pipeline extracts employee records from IAM & UCPath and updates the User table in the Role Access Management database.

#### General Process Flow

1. Extract recently-updated employee records from the IAM and UCPath schemas in the PG integration database.
2. Partition the result set into individual records.
3. Check if each record already exists in the RAM database.
4. If it doesn't exist, perform an INSERT. If it exists, perform an UPDATE.

#### Pipeline Dependencies

* None

#### Maintenance History

1. [INT-1654](https://afs-dev.ucdavis.edu/jira/browse/INT-1654) NiFi: Creates a new pipeline to send incremental employee record changes to Role Access Management