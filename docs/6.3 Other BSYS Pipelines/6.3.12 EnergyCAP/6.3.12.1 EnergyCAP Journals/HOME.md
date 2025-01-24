# 6.3.12.1 EnergyCAP Journals


#### Summary

This pipeline extracts billing transactions from EnergyCAP and processes them into journals to post to Aggie Enterprise.

### Pre-processing Flow

1. A billing analyst exports a CSV file from EnergyCAP and drops it in the SecureShare directory  **ou\foa\Secure\batch\EnergyCAP\journals**
2. GoAnywhere picks up the file and delivers it to an S3 bucket.
3. A process picks up the file from S3 publishes it to the to the `in.#{instance_id}.sftp.csv.energycapJournal` Kafka topic.

#### General Process Flow

1. Consume the file from the `in.#{instance_id}.sftp.csv.energycapJournal` Kafka topic.
2. Transform the file contents into individual JSON records representing expenses.
3. Generate revenue records for each expense.
4. Transform each record to conform to the `in.#{instance_id}.internal.json.gl_journal_validated-value` schema.
5. Merge all records into a single journal.
6. Publish the journal to the `in.#{instance_id}.internal.json.gl_journal_flattened` Kafka topic.
7. The journal is processed by the **6.2.1.2 GL-PPM Journal Line Validation** pipeline.

#### Pipeline Dependencies

* 6.2.1.2 GL-PPM Journal Line Validation
* 6.4.14 GLIDe Stage
* 6.4.14 GLIDe Status Updates

#### Maintenance History

1. [AMS-1328](https://afs-dev.ucdavis.edu/jira/browse/AMS-1328) EnergyCAP GL/PPM integration with AggieEnterprise
2. [INT-611](https://afs-dev.ucdavis.edu/jira/browse/INT-611) NIFI: 6.3.12.1 EnergyCAP Billing - Change properties on PublishKafka processors
3. [INT-759](https://afs-dev.ucdavis.edu/jira/browse/INT-759) NiFi: 6.3.12.1 EnergyCap Billing - ReplaceText + Pipeline Request
4. [INT-1212](https://afs-dev.ucdavis.edu/jira/browse/INT-1212) NiFi: EnergyCAP Billing (6.3.12.1) - Set Journal Transaction Date to BS-EndDate
