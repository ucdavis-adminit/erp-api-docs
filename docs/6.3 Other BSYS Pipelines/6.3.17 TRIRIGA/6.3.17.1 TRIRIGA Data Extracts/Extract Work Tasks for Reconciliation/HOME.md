# Extract Work Tasks for Reconciliation


#### Summary

This pipeline extracts work tasks from TRIRIGA and stores them in the PostgreSQL integration and Oracle reporting databases.

#### General Process Flow

1. Call the TRIRIGA Business Connect API to retrieve work tasks.
2. Transform the XML payload into individual JSON records for each work task.
3. Transform each record to conform to the [`out.#{instance_id}.internal.json.tririga.worktask`](https://afs-dev.ucdavis.edu/stash/projects/INT/repos/ae-avro-schema/browse/out/facilities/tririga_work_task.avsc) schema.
4. Load the `#{instance_id}_fac.tririga_work_task` table in the PostgeSQL integration database.
5. Transform each record to conform to the [`out.#{instance_id}.internal.json.boundary_app_recon_source`](https://afs-dev.ucdavis.edu/stash/projects/INT/repos/ae-avro-schema/browse/out/glide/boundary-application-reconciliation-source.avsc) schema.
6. Publish the journal to the `out.#{instance_id}.internal.json.boundary_app_recon_source` Kafka topic.
7. The records will be loaded into the Oracle reporting database by the **6.1 Oracle Data Extracts** pipeline.

#### Pipeline Dependencies

* 6.1 Oracle Data Extracts

#### Maintenance History

1. [INT-1396](https://afs-dev.ucdavis.edu/jira/browse/INT-1396) NiFi: TRIRIGA Data Extracts (6.3.17.1) - Create new pipeline