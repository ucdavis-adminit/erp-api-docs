# 6.3.4 CashNet


#### Summary

Cashnet provides a daily feed of transactions to the financial system.  This file should already have all of the chartstring segments and it would be a simple transformation to convert into the needed format.

The file will be received via SFTP and placed into an S3 bucket by GoAnywhere.  This pipeline will read the file from there.

CashNET will provide a file which contains the GL Segment information along with descriptive information for each line.  CashNET will not expense to PPM segment strings.  Each line can be converted to a single GL line.  The file from CashNET will be unbalanced, and an offsetting GL line will be added to balance the file.  The segment values for this line will be the same in every generated file and will be provided by the functional team.


#### Implementation Notes

This process should perform the parsing of the file and convert to the gl-ppm-flattened JSON format.  The resulting file should then be posted to the appropriate input topic for that portion of the GL-PPM pipeline.

1. Pull file from input topic.  (File will be placed there by a common SFTP->S3->Kafka pipeline.)
2. Validate file format
3. Restructure input lines to match the GL-PPM format.
4. (Maybe) verify GL segments on each line
5. Route errors in file to failure feedback topic.
6. Generate offset line.
7. Write to `in.<env>.internal.json.gl_journal_flattened` topic.


### CashNet Data Processing Pipeline

#### Nifi Process Group URL (dev environment)

[http://dev-nifi-zkp-01.it-streaming-dev.aws.ait.ucdavis.edu:8080/nifi/?processGroupId=4af44d77-c910-1df4-0000-000023a570b1&componentIds=765a3b3f-f01d-1ce0-863c-3e614e3854bc]


#### Cashnet Specific Parameter Context

- consumer_id: UCD CashNet
- offset_gl_chart_string: 3110-13U00-1000002-100000-00-000-0000000000-000000
- default_gl_chart_string: 3110-99U99-1000006-590000-80-000-0000000000-000000

_Note: The parameter `default_gl_chart_string` is for 'kickout account'._

#### Nifi Pipelines Overview

`Get Cashnet Data` -> `Convert CSV to Avro` -> `Convert Avro to JSON` -> `Convert to GL/PPM Format` -> `GL Segments Validation` -> `Publish to Kafka`

#### Type Definition of CashNet Input Data

Avro Schema:

```json
{
  "type": "record",
  "namespace": "edu.ucdavis.ait",
  "name": "Cashnet",
  "fields": [
    { "name": "GlString",         "type": "string" },
    { "name": "LineRef",         "type": "string" },
    { "name": "DepositNo",        "type": "string" },
    { "name": "LineDescription",  "type": "string" },
    { "name": "Amount",           "type": "string" }
  ]
}
```

#### Convert CSV to Avro

- Purpoose: Convert CSV records to Avro format
- Processor Type: ConvertCSVToAvro
- Processor Name: ConvertCSVToAvro
- Processor Attributes:
  - Record Schema: (see above)

_Note: This processor is need because the origianl input file has no header line and we need to attach schema based on column position._

#### Convert Avro to JSON

- Purpose: Convert Avro to JSON format
- Processor Type: ConvertAvroToJSON
- Processor Name: ConvertAvroToJSON

#### Convert to GL/PPM Flattened Format

- Purpose: Convert JSON format to GL/PPM flattened format
- Processor Type: ExecuteGroovyScript
- Processor Name:  Convert to GL/PPM Flattened Format
- Processor Attributes:
  - consumerId: `#{consumer_id}`
  - offsetGlChartString: `#{offset_gl_chart_string}`
  - Script Body: [Link](./gl-ppm-flattened-format-conversion.groovy)

#### GL Segments Validation

- Purpose: Validate GL segments
- Process Group: [Validate GL Segment](../6.4/../../6.4%20Support%20Pipelines/6.4.16%20GL%20Segment%20Validation/2b-gl-segment-validation.md)

#### Publish to Kafka

- Purpose: Produce Kafka messages for GL entries to be posted to Oracle
- Procssor Type: PublishKafka_2_6
- Procssor Name: Publish Journal Records to Kafka
- Processor Attributes
  - Kafka Brokers: `#{kafka_broker_list}`
  - Topic Name: `in.#{instance_id}.internal.json.gl_journal_flattened`
  - Use Transactions: true
  - Delivery Guarantee: Guarantee Replicated Delivery
  - Attributes to Send as Headers: `.*`
  - Kafka Key: `${kafka.key}`

### CashNet Data to GL-PPM Flattened Mapping

| GL-PPM Field                | MCM Query Field                                      | Notes          |
| --------------------------- | ---------------------------------------------------- | -------------- |
| **Request Header Fields**   |                                                      |                |
| `consumerId`                | UCD CashNet                                          |                |
| `boundaryApplicationName`   | UCD CashNet                                          |                |
| `consumerReferenceId`       | Cashnet_yyyyMMdd                                     |                |
| `consumerTrackingId`        | `UUID`                                               |                |
| `requestSourceType`         | sftp                                                 |                |
| `requestSourceId`           | `kafka.key`                                          |                |
| **Journal Header Fields**   |                                                      |                |
| `journalSourceName`         | UCD CashNet                                          |                |
| `journalCategoryName`       | UCD Recharges                                        |                |
| `journalName`               | Cashnet UUID                                         |                |
| `journalDescription`        | (unset)                                              |                |
| `journalReference`          | `UUID `                                              |                |
| `accountingDate`            | (today)                                              |                |
| `accountingPeriodName`      | (unset)                                              |                |
| **Line Fields**             |                                                      |                |
| `debitAmount`               | Line amount negated                                  | If negative    |
| `creditAmount`              | Line amount                                          | If positive    |
| `externalSystemIdentifier`  | UCD CashNet + `LineRef`                              |                |
| `externalSystemReference`   | UCD CashNet                                          |                |
| **GL Segment Fields**       | it is GL segment when AllocationCustom17_207 is NULL |                |
| `entity`                    | (Parsed from Chart String)                           |                |
| `fund`                      | (Parsed from Chart String)                           |                |
| `department`                | (Parsed from Chart String)                           |                |
| `account`                   | (Parsed from Chart String)                           |                |
| `purpose`                   | (Parsed from Chart String)                           |                |
| `glProject`                 | (Parsed from Chart String)                           |                |
| `program`                   | (Parsed from Chart String)                           |                |
| `activity`                  | (Parsed from Chart String)                           |                |
| `interEntity`               | 0000                                                 |                |
| `flex1`                     | 000000                                               |                |
| `flex2`                     | 000000                                               |                |
| **PPM Segment Fields**      |                                                      |                |
| `ppmProject`                | `glProject`                                          | If PPM project |
| `task`                      | `activity`                                           | If PPM project |
| `organization`              | `department`                                         | If PPM project |
| `expenditureType`           | `account`                                            | If PPM project |
| **Internal Control Fields** |                                                      |                |
| `lineType`                  | glSegments or ppmSegments                            |                |
| `lineDescription`           | CSV fields: `LineRef DepositNo RefIdLineDescription` |                |

### Outbound Flowfile Attributes

| Attribute Name                | Attribute Value                |
| ----------------------------- | ------------------------------ |
| `record.count`                | (Calculated)                   |
| `consumer.id`                 | UCD CashNet                    |
| `data.source`                 | sftp                           |
| `source.id`                   | same as `requestSourceId`      |
| `boundary.system`             | UCD CashNet                    |
| `consumer.ref.id`             | same as `consumerReferenceId`  |
| `consumer.tracking.id`        | same as `consumerTrackingId`   |
| `glide.extract.enabled`       | N                              |
| `glide.summarization.enabled` | N                              |
| `journal.name`                | same as `journalName`          |
| `journal.source`              | same as `journalSourceName`    |
| `journal.category`            | same as `journalCategoryName`  |
| `accounting.date`             | same as `accountingDate`       |
| `accounting.period`           | same as `accountingPeriodName` |
