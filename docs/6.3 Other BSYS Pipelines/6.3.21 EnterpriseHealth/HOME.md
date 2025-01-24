# 6.3.21 EnterpriseHealth


#### Summary

Enterprise Health is used by Safety Services - Occupational Health to maintain health care records for UCD employees.

Enterprise Health requires a pipeline to support the maintenance of its patient records based on records in UC Path. The UC Path data includes typical data such as Employee ID, Name and Supervisor, along with sensitive data such as Legal Name and Birth Date.

#### General Process Flow

1. Query the OHS_HCMODS data mart to retrieve UC Path employee records.
2. Augment each record with data from IAM.
3. Transform each record to conform to Enterprise Health's HR interface record requirements.
4. Package the records into a pipe-delimited CSV file using the naming convention ucd_ucpath_<instance_id>_<yyyyMMddHHmmss>.csv
5. Load the CSV file into S3 with the naming convention <instance_id>/out/enterprisehealth/<filename>.
6. GoAnywhere picks up the CSV, PGP-encrypts it and sends it to the Enterprise Health SFTP end point.

#### Maintenance History

1. [INT-1395](https://afs-dev.ucdavis.edu/jira/browse/INT-1395) NiFi: Create new pipeline to feed UC Path data OHS_HCMODS into Enterprise Health