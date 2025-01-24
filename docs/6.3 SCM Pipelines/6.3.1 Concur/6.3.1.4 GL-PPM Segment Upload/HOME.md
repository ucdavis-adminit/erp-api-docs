# 6.3.1.4 GL-PPM Segment Upload

### Overview

Concur requires that the list of valid GL/PPM values be uploaded for selection on the UI and for approval purposes.  This utilizes the common list upload format provided by Concur as well as the Cost object Importers.

For the purposes of the UI, the following GL and PPM segments are required.

* Entity
* Fund
* Purpose
* Activity
* GL Project
* Program
* Financial Department
* PPM Project-Task

Further, AggieExpense requires that reports be approved by a financial approver linked to either the GL financial department or the PPM project.  This requires the use of the Cost Object Approvers Import and special construction of one of the segment lists.

### Concur List Imports

For the above attributes, we will need to import the following lists:

* *AE UCD Entity
* *AE UCD Fund
* *AE UCD Purpose
* *AE UCD Activity
* *AE UCD Program
* *AE UCD Project
* *AE UCD Ledger-Dept-Approver
* *AE UCD Expense Organization

With the exception of UCD Cost Center, these are all single-level lists that are independent of each other.  The UCD Cost Center is a combination field of GL Financial Department, PPM Project-Task, and the approvers linked to each.  This is a "connected list" in Concur-speak where each level is dependent on the previously selected value.

This list will have 3 levels:

1. Allocation Type: The string GL or PPM
2. Cost Center Type: The string Financial Department or PPM Project
3. Department / Project-Task: Either a department code or a project_task combination, depending on the cost center type.
4. Approver: An approver for the cost center.

This one connected list will contain all eligible financial departments and project-tasks.  The approvers will be pulled from the security roles for the departments and the project manager on the ppm_project table.

An example of the list is below:

* GL
  * Financial Department
    * ADIT0001
      * fiscal approver1
      * fiscal approver2
    * ADIT0002
      * fiscal approver1
      * fiscal approver2
* PPM
  * PPM Project
    * K30RA24STP_TASK01
      * Project Manager
    * K30RA25STP_TASK01
      * Project Manager

### Cost Center Approvers

Due to the way that approvers need to work in Concur, we must also load the approver for each entry in the cost center list above.  The approver given will be the SAME as the approver listed at the bottom level of the list.  When complete, there will be a 1:1 relationship between cost center list items and the cost center approvers entries.


## GL/PPM Segment Import to Concur

### Stats

|                  |                                       |
| ---------------- | ------------------------------------- |
| **Direction:**   | **Outbound**                          |
| **Source:**      | Integration Database, changed records |
| **Destination:** | Concur, via flat file, vendor format  |

### Summary

Extracts changed GL segment data from Oracle and imports into concur using their List Item upload format.

### Flow Summary

1. Consume updated records `gl_segments` and `ppm_segments` MViews.
   1. Use QueryDatabaseTable with a custom query to pull updated records.
   2. Set: `initial.maxvalue.last_update_date` to the current date minus 30 days to allow for recovery if the processor state is lost.
   3. (There will be a separate version of the processor for the initial load which will have no initial date`.)
2. Restructure records into Concur list item format. (See Concur List Import Spec in section 6.3.1.A.)
3. Save file to output S3 bucket.
4. (GoAnywhere) Pick up file and send to Concur.

### Custom Query for Pulling Records

[](./segment_to_concur_list.sql ':include')

### Segment to Concur List Mapping

| Segment Type                       | Concur List Name                 |
| ---------------------------------- | -------------------------------- |
| erp_entity                         | *AE UCD Entity                   |
| erp_fund                           | *AE UCD Fund                     |
| erp_purpose                        | *AE UCD Purpose                  |
| erp_activity                       | *AE UCD Activity                 |
| erp_program                        | *AE UCD Program                  |
| gl_project                         | *AE UCD GL Project               |
| erp_fin_dept / ppm_project_task    | *AE UCD Ledger-Dept-Approver     |
| erp_fin_dept JOIN ppm_organization | *AE UCD Expenditure Organization |

### Mapping Notes

* List Category and List Name are the same.
* We are only using the level 1 code on everything except Financial Department / Project-Task hierarchy.
* We do not use the start and end dates in these files.
* The last field should be N or Y, mapped to valid and INVALID in the status column of the input.
* Financial department will be a connected list.



## Cost Object Approver Imports

This will create the lines which are processed by the employee import job by Concur.  This associates the entries in the UCD Cost Center connected list with the matching approver for each record.

There are two record types needed for this, and they are described in the extract from the Concur File Specifications at [Cost_Object_Approver_Specs.pdf](../6.3.1.A%20Vendor%20File%20Specifications/Cost_Object_Approver_Specs.pdf ':ignore').  The 710 record is used for adding approvers for new entries in the cost center list.  The 760 record inactivates records which have been removed.  Since the list items contain the approver as well, and are a 1:1 with these records, there is no need for updates.

The complication with this feed are the deletions.  If we see all the inactive record updates, we are likely ok, and can use the inactive flag to create the inactivate records in the file.

### Data Retrieval

This job will take the same input data as that for the UCD Cost Center list, as they are maintained in tandem.  (Because of this, it is critical that the Concur lists be loaded first, as the records here are (probably) dependent on the list items being present...we don't actually know if Concur links them up at time of import, or just upon use.)

### Flow Design

1. Accept input from the Cost center changed data extract flow.
2. Split and reformat the contents for the cost object approver updates and deletions. (`QueryRecord`)
   1. Filter out non-leaf level records as we only assign approvers at the bottom.
3. Attach the schemas for each of the results. (`UpdateAttribute`)
4. Reformat into headerless CSV files. (`ConvertRecord`)
5. Set attributes on the files to allow for them to be merged. (`UpdateAttribute`)
6. Merge the record content and add a header. (`MergeContent`)
7. Set the file name (`UpdateAttribute`)
8. Upload the file to S3. (`PutS3Object`)

### Reformatting Query for Approver Updates

```sql
-- Expense Approver Updates
SELECT
  '710' AS "Transaction_Type"
, 'EXP' AS "Approval_Type"
, "Level_03_Code" AS "Employee_ID"
, "Level_01_Code" AS "Segment_1"
, "Level_02_Code" AS "Segment_2"
, "Level_03_Code" AS "Segment_3"
FROM FLOWFILE
WHERE "Level_03_Code" IS NOT NULL
  AND "Delete_List_Item" = 'N'
  AND "List_Name" = '*AE UCD Ledger-Dept-Approver'
UNION ALL
-- Request Approver Updates
SELECT
  '710' AS "Transaction_Type"
, 'REQ' AS "Approval_Type"
, "Level_03_Code" AS "Employee_ID"
, "Level_01_Code" AS "Segment_1"
, "Level_02_Code" AS "Segment_2"
, "Level_03_Code" AS "Segment_3"
FROM FLOWFILE
WHERE "Level_03_Code" IS NOT NULL
  AND "Delete_List_Item" = 'N'
  AND "List_Name" = '*AE UCD Ledger-Dept-Approver'
ORDER BY "Transaction_Type", "Approval_Type", "Employee_ID", "Segment_1", "Segment_2", "Segment_3"
```

### Reformatting Query for Approver Deletions

```sql
-- Expense Approver Deletions
SELECT
  '760' AS "Transaction_Type"
, 'EXP' AS "Approval_Type"
, "Level_03_Code" AS "Employee_ID"
, "Level_01_Code" AS "Segment_1"
, "Level_02_Code" AS "Segment_2"
, "Level_03_Code" AS "Segment_3"
FROM FLOWFILE
WHERE "Level_03_Code" IS NOT NULL
  AND "Delete_List_Item" = 'Y'
  AND "List_Name" = '*AE UCD Ledger-Dept-Approver'
UNION ALL
-- Request Approver Deletions
SELECT
  '760' AS "Transaction_Type"
, 'REQ' AS "Approval_Type"
, "Level_03_Code" AS "Employee_ID"
, "Level_01_Code" AS "Segment_1"
, "Level_02_Code" AS "Segment_2"
, "Level_03_Code" AS "Segment_3"
FROM FLOWFILE
WHERE "Level_03_Code" IS NOT NULL
  AND "Delete_List_Item" = 'Y'
  AND "List_Name" = '*AE UCD Ledger-Dept-Approver'
ORDER BY "Transaction_Type", "Approval_Type", "Employee_ID", "Segment_1", "Segment_2", "Segment_3"
```

### File Format and Naming Convention

#### File Format

The file format for concur is a CSV with variable row formats.  Each row contains a record type as the first field, and Concur uses that to parse the line.  As such, there is no CSV header line in the file.

Since this is technically an employee import file, every file must start with a Type 100 header record.  The format is given in the above document, but we just hard-code it as:

```csv
100,0,SSO,IGNORE,EN,Y,N
```

#### File Naming

Concur requires that the file name be of the format: `employee_<concur entity id>_<local identifier>.txt`.

The `concur entity id` is an identifier which controls the instance into which the file is loaded.  UCD has two entity IDs, one for test, one for production.  The test ID is `t00082678yhu`.

The `local identifer` is just a string to be able to uniquely identify the file.  It should both include a timestamp as well as an idenifier for the contents of the file, as there are at least 3 processes sending employee import files to concur.  (Actual Employee Records, HR Department Approvers, and this.)

For the local identifier, we will use the following format: `cost_object_<timestamp>`.  The timestamp will be in the format `YYYYMMDDHHMMSS`, and will be the time at which the file is created.

### Cost Object Approver Import Records (Type 710)

These records should have a record for every new entry in the cost center list unless it is inactive.  The mapping would be as below.  Note that there will be TWO records for every cost center, as we need to load the approvers for both the expense report and the travel request.

|    # | Concur Field                 | Value                              | Notes                                                           |
| ---: | ---------------------------- | ---------------------------------- | --------------------------------------------------------------- |
|    1 | Transaction Type             | 710                                | Constant                                                        |
|    2 | Approval Type                | EXP or REQ                         | Two records for each cost center each with one of these values. |
|    3 | Employee ID                  |                                    | The employee ID of the approver                                 |
|    4 | Segment 1                    | GL/PPM                             | The allocation type                                             |
|    5 | Segment 2                    | Financial Department / PPM Project | The type of cost center value used for GL or PPM                |
|    6 | Segment 3                    | Fin Dept or Project_Task           | The department or project-task                                  |
|    7 | Segment 4                    | Employee ID                        | The approver's employee ID                                      |
|    8 | Segment 5                    |                                    | Blank                                                           |
|    9 | Segment 6                    |                                    | Blank                                                           |
|   10 | Segment 7                    |                                    | Blank                                                           |
|   11 | Segment 8                    |                                    | Blank                                                           |
|   12 | Segment 9                    |                                    | Blank                                                           |
|   13 | Segment 10                   |                                    | Blank                                                           |
|   14 | Exception Approval Authority | N                                  | Constant                                                        |
|   15 | Approval Limit               |                                    | Blank                                                           |
|   16 | Approval Limit Currency Code |                                    | Blank                                                           |
|   17 | Level                        | 1                                  | Constant                                                        |

### Delete Cost Object Approver Import (Type 760)

These records should be generated for every updated cost center which is now inactive or invalid.  The mapping would be as below.  Note that there will be TWO records for every cost center, as we need to remove the approvers for both the expense report and the travel request.

|    # | Concur Field     | Value                              | Notes                                                           |
| ---: | ---------------- | ---------------------------------- | --------------------------------------------------------------- |
|    1 | Transaction Type | 760                                | Constant                                                        |
|    2 | Approval Type    | EXP or REQ                         | Two records for each cost center each with one of these values. |
|    3 | Employee ID      |                                    | The employee ID of the approver                                 |
|    4 | Segment 1        | GL/PPM                             | The allocation type                                             |
|    5 | Segment 2        | Financial Department / PPM Project | The type of cost center value used for GL or PPM                |
|    6 | Segment 3        | Fin Dept or Project_Task           | The department or project-task                                  |
|    7 | Segment 4        | Employee ID                        | The approver's employee ID                                      |
|    8 | Segment 5        |                                    | Blank                                                           |
|    9 | Segment 6        |                                    | Blank                                                           |
|   10 | Segment 7        |                                    | Blank                                                           |
|   11 | Segment 8        |                                    | Blank                                                           |
|   12 | Segment 9        |                                    | Blank                                                           |
|   13 | Segment 10       |                                    | Blank                                                           |
