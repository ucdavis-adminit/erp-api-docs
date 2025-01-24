# 6.3.6.2 GL Transactions from Lawson

### Lawson GL Ledger Data Inbound to Oracle

Should be a simple transformation of the Lawson GL Ledger data into the GL-PPM flattened format (or FBDI).

* Functional Specification: <https://ucdavis.app.box.com/file/916961478408>

### Functional Specification Problems (2022-08-12)

* Use of the UCDH Lawson journal category.  We are using `UCD Recharges` for all use of the GL-PPM Common service.
* The spec maps to the FBDI format, which is not the target here.  So, we don't know the format that Lawson plans to send.
  * If they intend to build out a correct FBDI file, we can just pass it along, but I didn't think that was the plan.
* Summarization logic needs to be translated into Oracle field concepts unless we will be fed a source file with those names.
  * Also: still references summarization, when we were going to move to sending detail records.
* There is functionally no mapping of Lawson fields to the Oracle fields in the above document.  So there is nothing to plan from.


### Pending Requirements

1. Should any data validation be done on this file prior to sending it to Oracle?
   1. If so, what should be done with failed records?
   2. If so, what should be validated?

### High Level Flow (Assumed)

1. Lawson will SFTP the data file to GoA.
2. GoA will accept the file and upload to S3.
3. Standard S3 Monitors will pick up the file and publish it to an intake topic.
4. Consume file from Kafka topic.
5. Record the request in the pipeline_request table to enable notifications.
6. Reformat the data into the GL-PPM flattened format.
   1. This will require some level of mapping. (**TBD**)
7. Summarize the information as needed.
8. Validate the segment information, replace invalid segments with the kickout chartstring.
9. Push to GL-PPM Validated topic for further processing and submission to Oracle.


