# 6.3.13 FleetFocus M5


#### Summary

UC Davis Fleet Services uses FleetFocus M5 to track usage and expenses of vehicles that are leased to campus departments, owned by campus departments and those rented from the motor pool. This pipeline extracts billing transactions from FleetFocus M5 and processes them into journals to post to Aggie Enterprise.

### Pre-processing Flow

1. At the beginning of each month, a billing analyst initiates a billing cycle in M5, which pre-stages billing transactions.
2. The billing analyst validates the billing transactions and makes corrections as necessary.
3. Upon validation, the analyst will close the billing period in M5, which commits the billing transactions.
4. The transactions are now ready for processing by the pipeline.

#### General Process Flow

1. Get the fiscal period in M5 that is flagged as ready for processing.
2. Extract billing transactions under that fiscal period from the M5 database.
3. Transform the file contents into individual JSON records representing expenses.
4. Generate revenue records for each expense.
5. Transform each record to conform to the `in.#{instance_id}.internal.json.gl_journal_validated-value` schema.
5. Merge all records into a single journal.
6. Publish the journal to the `in.#{instance_id}.internal.json.gl_journal_flattened` Kafka topic.
7. The journal is processed by the **6.2.1.2 GL-PPM Journal Line Validation** pipeline.

#### Pipeline Dependencies

* 6.2.1.2 GL-PPM Journal Line Validation
* 6.4.14 GLIDe Stage
* 6.4.14 GLIDe Status Updates
  
