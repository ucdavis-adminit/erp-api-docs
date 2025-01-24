# 6.3.23.2 UCPath Exports to RAM


#### Summary

This pipeline extracts department records from the UCPath schema in the PG integration database and updates the Department table in the Role Access Management database.

#### General Process Flow

1. Extract recently-updated department records from the UCPath schemas in the PG integration database.
2. Partition the result set into individual records.
3. Check if each record already exists in the RAM database.
4. If it doesn't exist, perform an INSERT. If it exists, perform an UPDATE.

#### Pipeline Dependencies

* None

#### Maintenance History

1. [INT-1757](https://afs-dev.ucdavis.edu/jira/browse/INT-1757) NIFI: Creates a new pipeline to load departments from IAM into Role Access Management