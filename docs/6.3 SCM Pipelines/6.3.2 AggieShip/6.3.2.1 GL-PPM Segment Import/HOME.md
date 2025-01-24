# 6.3.2.1 GL-PPM Segment Import

## AggieShip GL/PPM Segment Import

This pipeline is used to import GL/PPM Segment data into AggieShip.  Data is extracted from the erp_segments and ppm_segments materialized views and formatted into a CSV file and uploaded into S3 for transmission to AggieShip.

### Flow Summary

1. Extract changed segment records from the integration database.
2. Reformat into a CSV file.
3. Upload to S3

### Flow Walkthough

1. **Extract Data**: Once a day process extract changed records from the integration database.
   1. Execute using Cron Expression: `0 0 23 ? * MON-FRI`
2. **Attach AVRO Schema** (see below)
3. **Convert Avro Flowfile Contents to CSV**
   1. Record reader is Avro
   2. Record with `Writer - CSV-Unix - Use Embedded Schema`
4. Set the name of the file:
   1. `erp_segments_YYYYMMDDHHMMSS.csv`
5. Check if the flowfile is empty, and skip transmission if so.
6. **Upload file to S3**
   1. `#{instance_id}/out/aggieship/${filename}`

#### Data Extract SQL

[](segment_to_aggieship_csv.sql ':include')

#### CSV Avro Schema

[](../6.3.2.A%20Schemas%20and%20Formats/aggieship_gl_ppm_segments_csv.avsc ':include')


### Outbound File Formats: GL and POET Segments

SC Logic requires segment strings to perform their internal validation.  For this, we will extract incremental changes of these values from Oracle and write to CSV files for SFTP transport to SC Logic.

#### Files Needed

SC Logic wants to receive one file containing all segment values.  This will be performed by sending a column in the output CSV file which identifies the type of segment.

The types of segments we will be sending are:

* **GL Segments**
  * Entity
  * Financial Department
  * Fund
  * Purpose
  * Activity
  * GL Project
  * Program
* **POET Segments**
  * PPM Project / Task

#### Output Format

The file will be a standard CSV file with the following output structure.

* File Name: `sclogic_erp_segments_yyyyMMddHHmmss.csv`

| Column Name      | Type        | Notes                    |
| ---------------- | ----------- | ------------------------ |
| SEGMENT_TYPE     | String(40)  |                          |
| CODE             | String(20)  |                          |
| NAME             | String(100) |                          |
| ENABLED          | Character   | Y/N                      |
| APPROVER_ID      | String(32)  |                          |
| APPROVER_EMAIL   | String(200) |                          |
| APPROVER_NAME    | String(200) |                          |
| LAST_UPDATE_DATE | Timestamp   | ISO8601 Timestamp Format |

#### Flow Summary

1. Extract changed data from the changed segment topics. (GL and PPM)
2. Perform additional filtering on inactive records.
3. Format as CSV.
4. Merge records into single flow file.
5. Upload file to S3 bucket for pickup by GoAnywhere.

##### Segment Type Values

* erp_entity
* erp_fin_dept
* erp_fund
* erp_purpose
* erp_activity
* erp_program
* gl_project
* ppm_project_task

#### Extract Contents

This integration will source from Kafka Topics containing all changed items since the last run.  The contents of the Kafka topic will be JSON-formatted records, one per segment update.  The structure of this object is described by the AVRO schema below.  (See Section 6.4.2 for more information.)

The Kafka Topic Names are:

* `out.<env>.internal.json.gl_segments`
* `out.<env>.internal.json.ppm_segments`

The Kafka Consumer Group (used to track last read position):

* `out.sclogic.coappm_segments`

##### `gl_segment` AVRO Schema

[](../../6.4%20Support%20Pipelines/6.4.2%20GL-POET%20Segment%20Change%20Extracts/gl_segment.avsc ':include')

##### `ppm_segment` AVRO Schema

[](../../6.4%20Support%20Pipelines/6.4.2%20GL-POET%20Segment%20Change%20Extracts/ppm_segment.avsc ':include')

#### GL Segments

All GL Segment values are in the same tables.  For all but GL Project, the export will be the name, changing only the value set code for each query.  On all GL segments, the rules are:

* Current date must be between the start and end dates.
* Must not be a summary level record.
* Enabled flag is forced to `N` when the end date is reached.
* `US` Language code for the name/description.
* Last update date used to select new records is from `VALUE_SET_TYPED_VALUES_PVO`
* Must have been active within the last 14 days.

For GL Project, all of the above plus:

* Top-level project code must be one of the allowed parents.  `GLG000000A` at time of writing.  However, the `gl_journal` mview will implement that and this integration does not need to include any rule to this effect.

All of the above are effectively enforced by the `gl_segments` view.  The only one which will need additional processing is "Must have been active within the last 14 days."  For that one, filter out any status = INACTIVE records whose `last_update_date` is more than 14 days ago.

##### Mapping To Output (`gl_segments`)

| Column Name      | Source                                |
| ---------------- | ------------------------------------- |
| SEGMENT_TYPE     | segment_type                          |
| CODE             | code                                  |
| NAME             | name                                  |
| ENABLED          | status (valid = Y, INVALID = N)       |
| APPROVER_ID      | financial_approver_id                 |
| APPROVER_EMAIL   | financial_approver_email              |
| APPROVER_NAME    | financial_approver_name               |
| LAST_UPDATE_DATE | last_update_date (format: yyyy-MM-dd) |

#### POET Segments

For PPM, we only need one - a combined query of the Project and Task Number.  This is identified as the `ppm_project_task` segment type in the `ppm_segments` mview.

* Code is Project Number `_` Task Number
* Name is Project Name ` - ` Task Name
* Enabled is based on the project status code and the project start and completion dates.  Project must be ACTIVE and current date within the given dates.  Task must also be valid on the current date.
* Template projects are excluded.
* Only chargeable tasks are included.  Projects with no chargeable tasks will be filtered out.
* Only projects

All of the above are effectively enforced by the `ppm_segments` view.  The only one which will need additional processing is "Must have been active within the last 14 days."  For that one, filter out any status = INACTIVE records whose `last_update_date` is more than 14 days ago.

##### Mapping To Output (`ppm_segments`)

| Column Name      | Source                                |
| ---------------- | ------------------------------------- |
| SEGMENT_TYPE     | segment_type                          |
| CODE             | code                                  |
| NAME             | name                                  |
| ENABLED          | status (valid = Y, INVALID = N)       |
| APPROVER_ID      | project_manager_id                    |
| APPROVER_EMAIL   | project_manager_email                 |
| APPROVER_NAME    | project_manager_name                  |
| LAST_UPDATE_DATE | last_update_date (format: yyyy-MM-dd) |
