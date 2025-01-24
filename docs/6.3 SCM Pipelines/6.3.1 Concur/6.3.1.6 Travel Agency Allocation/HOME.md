# 6.3.1.6 Travel Agency Allocation

### Data Flow Design

#### 1. Traveler Agency allocation Data Extract

1. We will be getting flow from Traveller Agency Allocations funnel after Split SAE processing.
2. Find departmental segment values by querying database using last department and subdepartment. (`LookupRecord`)
3. Attach the kickout chartstring to the flow file. (`UpdateAttribute`)  This may then be used to replace segments on bad lines with the kickout segments.
4. Convert the overall format of the data into the format required by the GL-PPM Line validation pipeline. (`QueryRecord`)
   1. See [Section 6.2.5](#/6%20Data%20Pipelines/6.2%20Common%20Inbound%20Pipelines/6.2.5%20GL-PPM%20Flattened/HOME ':ignore') for details on the format.
5. Add the journal header attributes to the flowfile.  (`PartitionRecord`)
6. Validate the segment values by using the `Validate GL Segments` and `Validate PPM Segments` process groups.
    1. Disable the `Validation Error Records` and `Passed Validation` output ports and set their relationships to expire flowfiles after one second.
    2. Enable the `All Records` output port and remove any expiration time on the relationship.
    3. Between each process group, update any records where line_valid = 'false' to the kickout chartstring. (`QueryRecord` or `UpdateRecord`)
    4. After each update, use ConverRecord to get rid of GL/PPM validation fields
7. Post the flowfile to the validated topic:
    1. Topic: `in.#{instance_id}.internal.json.gl_ppm_validated`
    2. Headers: `.*`
    3. Kafka Key: `${source.id}`


### Chartstring Parsing Groovy Script

Used ScriptedTransformRecord to check if  either a PPM or GL set of segments is not valid.  If gl/ppm is valid we don't do anything. In case when invalid record, i.e when `line_valid` is false, we set lineType to glSegments and set gl values to departmental default (kick out) account.

```groovy
def default_chartstring = attributes["concur.departmental.default.chartstring"];
def paymentMethodCode = record.getValue("paymentMethodCode");

//check if line_valid is valid 
//when invalid set up departmental account
if (record.getValue("line_valid") == false) {
   record.setValue("entity", default_chartstring.split('-')[0]);
   record.setValue("fund", default_chartstring.split('-')[1]);
   record.setValue("department", default_chartstring.split('-')[2]);
   record.setValue("account", default_chartstring.split('-')[3]);
   record.setValue("purpose", default_chartstring.split('-')[4]);
   
   record.setValue("line_valid", true);
   record.setValue("lineType", 'glSegments');
 
   //reset PPM values
   record.setValue("ppmProject", null);
   record.setValue("task", null);
   record.setValue("organization", null);
   record.setValue("award", null);
   record.setValue("fundingSource", null);
}

record;
```

### MCM Query to GL-PPM Flattened Mapping

| GL-PPM Field                | Concur Query Field                                   | Notes                |
| --------------------------- | ---------------------------------------------------- | -------------------- |
| **Request Header Fields**   |                                                      |                      |
| `consumerId`                | UCD Concur                                           |                      |
| `boundaryApplicationName`   | Concur                                               |                      |
| `consumerReferenceId`       | Concur_yyyyMMddHHmmss                                |                      |
| `consumerTrackingId`        | Concur_yyyyMMddHHmmss                                |                      |
| `consumerNotes`             | (unset)                                              |                      |
| `requestSourceType`         | sftp                                                 |                      |
| `requestSourceId`           | journal.Concur_yyyyMMddHHmmss.json                   |                      |
| **Journal Header Fields**   |                                                      |                      |
| `journalSourceName`         | UCD Concur                                           |                      |
| `journalCategoryName`       | UCD Recharges                                        |                      |
| `journalName`               | Batch_ID2 _BatchDate_3_Journal                       |                      |
| `journalDescription`        | (unset)                                              |                      |
| `journalReference`          | BatchID_2                                            |                      | '_'  |  | BatchDate_3                       |                       | '_Journal' |  |
| `accountingDate`            | BatchDate_3                                          |                      |
| `accountingPeriodName`      | (unset)                                              |                      |
| **Line Fields**             |                                                      |                      |
| `debitAmount`               | JournalAmount_169                                    | If positive          |
| `creditAmount`              | JournalAmount_169                                    | If negative          |
| `externalSystemIdentifier`  | ReportID_19                                          |                      |
| `externalSystemReference`   | PC_ReportKey_20   (when PCard) or TC-ReportKey_20    |                      |
| `ppmComment`                | EmployeeLastName_6                                   |                      | ', ' |  | EmployeeFirstName_7               |                       | ' '        |  | EmployeeID_5 |  |
| **GL Segment Fields**       | it is GL segment when AllocationCustom17_207 is NULL |                      |
| `entity`                    | AllocationCustom10_200 AllocationCustom14_204                               |                      |
| `fund`                      | AllocationCustom11_201 AllocationCustom7_197                              |                      |
| `department`                | AllocationCustom12_202  AllocationCustom8_198                             |                      |
| `account`                   | JournalAccountCode_167                               |                      |
| `purpose`                   | AllocationCustom13_203  AllocationCustom13_203                             |                      |
| `glProject`                 | COALESCE(AllocationCustom14_204,'0000000000') AllocationCustom9_199        |                      |
| `program`                   | COALESCE(AllocationCustom15_205, '000' ) AllocationCustom15_205           |                      |
| `activity`                  | COALESCE(AllocationCustom16_206, '000000' )  AllocationCustom16_206        |                      |
| `interEntity`               | 0000                                                 |                      |
| `flex1`                     | 000000                                               |                      |
| `flex2`                     | 000000                                               |                      |
| **PPM Segment Fields**      | PPM segment when AllocationCustom17_207 is NOT NULL  |                      |
| `ppmProject`                | COALESCE(AllocationCustom14_204,'0000000000')   AllocationCustom10_200 (first part before /)     |                      |
| `task`                      | AllocationCustom17_207  AllocationCustom10_200 (second part after /)                             |                      |
| `organization`              | AllocationCustom18_208 AllocationCustom11_201                              |                      |
| `expenditureType`           | JournalAccountCode_167                               |                      |
| `award`                     | AllocationCustom20_210 (or blank)  (blank)                  |                      |
| `fundingSource`             | (blank)                              |                      |
| **Internal Control Fields** |                                                      |                      |
| `lineType`                  | based on segment_string                              |                      |
| **GLIDe Fields**            |                                                      |                      |
| `lineDescription`           | ReportName_27                                        |                      | '_'  |  | BilledCreditCardAccountNumber_130 |                       |
| `journalLineNumber`         | row number in journal                                | ROW_NUMBER() OVER () |
| `transactionDate`           | ReportUserDefinedDate_25                             |                      |
| `udfNumeric1`               |                                                      |                      |
| `udfNumeric2`               |                                                      |                      |
| `udfNumeric3`               |                                                      |                      |
| `udfDate1`                  | ReportUserDefinedDate_25                             |                      |
| `udfDate2`                  |                                                      |                      |
| `udfString1`                | EmployeeLastName_6                                   |                      | ', ' |  | EmployeeFirstName_7               | Trim to 50 characters |
| `udfString2`                | EmployeeID_5                                         |                      |
| `udfString3`                | ReportKey_20                                         |                      |

### Outbound Flowfile Attributes

| Attribute Name                | Attribute Value                |
| ----------------------------- | ------------------------------ |
| `record.count`                |                                |
| `consumer.id`                 | Concur Card Recharges          |
| `data.source`                 | sftp                           |
| `source.id`                   | same as `requestSourceId`      |
| `boundary.system`             | Concur                         |
| `consumer.ref.id`             | same as `consumerReferenceId`  |
| `consumer.tracking.id`        | same as `consumerTrackingId`   |
| `glide.extract.enabled`       | Y                              |
| `glide.summarization.enabled` | Y                              |
| `journal.name`                | same as `journalName`          |
| `journal.source`              | same as `journalSourceName`    |
| `journal.category`            | same as `journalCategoryName`  |
| `accounting.date`             | same as `accountingDate`       |
| `accounting.period`           | same as `accountingPeriodName` |
| `journal.debits`              | (calculated)                   |
| `journal.credits`             | (calculated)                   |
| `gl.total`                    | (calculated)                   |
| `ppm.total`                   | (calculated)                   |

### Sample Data

