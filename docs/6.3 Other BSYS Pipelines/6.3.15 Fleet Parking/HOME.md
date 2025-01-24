# 6.3.15 Fleet Parking

#### Summary

The Fleet Parking pipeline will handle billing interdepartmental recharge for parking fees incurred by Fleet Services managed vehicles.  The vehicles and periods of usage will be pulled from the Fleet Focus database, and that list will be further processed by removing exceptions using data from a TAPS database table.  The resulting data will be transformed into the flattened journal JSON format, run through GL/PPM validation, and then finally be submitted to the appropriate validated journal Kafka topic.

#### Flow Summary
TODO

#### Process Group Parameter Context
TODO

##### Parameters
TODO

#### Controller Services
TODO

#### Flow Walkthrough
TODO

#### Pipeline Dependencies

* Fleet Focus database hosted in AdminIT IM (MSSQL)
* TAPS database hosted in AdminIT IM (MSSQL)
* LookupService - SQL - Consumer Journal Features
* Validate GL Segments PG
* Validate PPM Segments PG
* Schema Registry
  * in.#{instance_id}.internal.json.gl_journal_flattened-value
  * in.#{instance_id}.internal.json.gl_journal_validated-value
* Kafka topics
  * in.#{instance_id}.internal.json.gl_journal_validated
  * feedback.#{instance_id}.request.sftp.error
  * feedback.#{instance_id}.internal.fleetparking.failure