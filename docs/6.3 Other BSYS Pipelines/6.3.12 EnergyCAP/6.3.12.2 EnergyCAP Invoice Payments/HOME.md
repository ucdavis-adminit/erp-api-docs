# 6.3.12.2 EnergyCAP Invoice Payments


#### Summary

This pipeline extracts utility vendor invoices from EnergyCAP and posts them as invoice payments to the SCM Invoice Payment Service.

### Pre-processing Flow

1. A billing analyst exports a CSV file from EnergyCAP and drops it in the SecureShare directory  **ou\foa\Secure\batch\EnergyCAP\invoicepayments**
2. GoAnywhere picks up the file and delivers it to an S3 bucket.
3. A process picks up the file from S3 publishes it to the to the `in.#{instance_id}.sftp.csv.energycapInvoicePayment` Kafka topic.

#### General Process Flow

1. Consume the file from the `in.#{instance_id}.sftp.csv.energycapInvoicePayment` Kafka topic.
2. Transform the file contents into individual JSON records.
3. Transform each record to conform to the `in.#{instance_id}.api.json.scmInvoicePaymentCreate-value` schema.
4. Publish each invoice payment to the `in.#{instance_id}.sftp.json.scmInvoicePaymentCreate` Kafka topic.
5. The invoice payment is processed by the **6.2.2 Invoice Payment Inbound** pipeline.

#### Pipeline Dependencies

* 6.2.2 Invoice Payment Inbound

#### Maintenance History

1. [AMS-1340](https://afs-dev.ucdavis.edu/jira/browse/AMS-1340) EnergyCAP invoice payment integration with AggieEnterprise
2. [INT-760](https://afs-dev.ucdavis.edu/jira/browse/INT-760) NiFi: 6.3.12.2 EnergyCap Invoice Payments - ReplaceText + Pipeline Request
3. [INT-941](https://afs-dev.ucdavis.edu/jira/browse/INT-941) NIFI: EnergyCAP Invoice Payments (6.3.12.2) - Handle invoices with multiple lines under same Bill ID