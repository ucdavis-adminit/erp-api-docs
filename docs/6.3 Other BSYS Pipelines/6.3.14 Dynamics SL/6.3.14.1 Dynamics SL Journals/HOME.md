# 6.3.14.1 Dynamics SL Journals


#### Summary

This pipeline extracts project transactions from Dynamics SL and posts them as journals to the GL/PPM Common Service.

#### General Process Flow

1. A billing analyst executes a billing cycle in Dynamics SL, which generates project transactions.
2. This pipeline extracts those transactions from the Dynamics SL database to create a GL Journal.
   a. Transform the file contents into the flattened GL Journal format as individual records representing expenses.
   b. Generate revenue records for each expense.
   c. Validate the GL and PPM segments on each line. If a segment is invalid send it to error processing.
5. Publish the resulting GL Journal to GL-PPM Inbound pipeline.

#### Pipeline Dependencies

* 6.4.14 GLIDe
  
