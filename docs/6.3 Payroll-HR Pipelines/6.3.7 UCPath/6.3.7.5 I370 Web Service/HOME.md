# 6.3.7.5 I370 Web Service

### Overview

The I-370 web service provides a second level of COA segment validation that UCPath can not handle.  This service accepts the full set of UCPath chartfields and validates that the combination of provided fields is valid.  (The validity of the individual fields and mandatory fields are handled within UCPath.)

### Change Summary for Oracle Chartstring Support

As there may still be old chartstrings in UCPath after the cutover, and we do not want to force a hard cutover date, we will alter the behavior of the existing web service to support both styles of chartstrings.  Due to differences in the data sizes, we will be able to detect whether a chartstring sent to us by UCPath is of the old (KFS) style or the new (Oracle) style.  Old chartstrings will continue to validate using the existing code.

1. Accept the incoming list of chartfields as is currently handled.
2. Check the Operating Unit input's length.  If it is exactly 4 characters, process using the new validation rules.  Otherwise, respond with the existing validation rules.
3. Steps below are for the new validation rules.
4. Check if the Project field is a PPM project.  There are more extensive validation rules for PPM chartstrings.
5. Run the rules appropriate for the chartstring type. (GL or PPM)

### Validation Overview

The below assumes that existence and Active status were handled by validation against the lookup tables for each segment value.

1. If the PROJECT_ID is a PPM project
   1. Verify the project has not completed
   2. Verify the task (PRODUCT) belongs to the project, is chargeable, and has not ended
   3. May also need to check budgetary status for projects.
   4. Verify the OPERATING_UNIT  matches the legal entity of the project
   5. Verify the DEPTID_CF against the ppm organization table
   6. Verify the ACCOUNT against the expense type table
   7. If the project is a sponsored project
      1. Verify the award (CHARTFIELD2) and FUND_CODE are linked to the project (not sure about award type mapping)
      2. Verify that the PROGRAM_CODE and Activity (CHARTFIELD1) are blank
   8. If not a sponsored project
      1. If there are values in the custom attributes for purpose, program, activity, and/or fund
         1. Verify that the UCPath chartfields fields match  those values if populated (CLASS_FLD, PROGRAM_CODE, CHARTFIELD1, FUND_CODE)
2. If no project code or the project code is a GL-only project
   1. Verify that the task and award fields are blank (PRODUCT, CHARTFIELD2)

### Implementation Notes

* **TBD:** Whether this service should use a local database for validation or should call the GraphQL services.  There are stability and connectivity considerations with the approaches.
  * As such, the required data access components should be isolated in the above code to allow the implementation to be switched out without altering the overall logic.
* Include the required field check so we can abort if we don't have all the required fields for the detected chartstring type.
