# 6.3.2 AggieShip


#### Summary

AggieShip requires inbound and outbound pipelines.  Outbound pipelines will transmit GL and PPM segments and user data.  (User data is not a day-1 conversion as it is not sourced from KFS.)  Inbound pipelines will support translation of the provided FBAP (`F`reight `B`illing `A`udit and `P`ay) file into the required GL Journal, PPM Costing, and Invoice Payment formats and upload them into Oracle.

1. GL Segment Uploads
   1. **Segments TBD**
2. PPM Segment Uploads
   1. **Segments TBD**
3. FBAP Ingestion and Processing
   1. File Parsing and Data Extraction
   2. Routing of data to GL / PPM
   3. Routing of data to Invoice Payment


#### Pipeline Dependencies

* **Outbound**
  * 6.4.2 GL-POET Segment Change Extracts
  * 6.4.1 Error Handling
* **Inbound**
  * 6.2.1 GL-PPM Combined
    * 6.4.5 GL FBDI Formatting
    * 6.4.6 PPM Costing FBDI Formatting
    * 6.4.9 Oracle FBDI File and Job Submission
      * 6.4.10 Oracle Job Feedback
  * 6.2.2 Payments
    * 6.4.11 AP Payment FBDI Formatting
    * 6.4.9 Oracle FBDI File and Job Submission
      * 6.4.10 Oracle Job Feedback
  * 6.4.1 Error Handling
