# 7.1.2 Needed Integration Components

## Supporting Integration Components

> This page is here for planning purposes.  Integrations will be documented in their appropriate pipeline or GraphQL server sections.

### Data Required by Application Loaded from UCPath

* Employee Data (INT-1447)
  * Used to search and validate approvers
  * Used to validate IDs on travel agency transactions
  * Used to validate non-employee traveller sponsor delegates
  * Used to obtain default department for employees
* Department Data (INT-1413, INT-1414)
  * Used to display department names
  * Used to identify which departments are UCDH departments

### Data Required by Application Loaded from Oracle Financials

* Expense Segment Data (existing)
  * Used to validate expense segment strings
* Geography Data (existing)
  * Used to validate non-employee traveller address fields (optional)

### GraphQL Data Operations Required by Application

> (Might be able to use Postgres for the UCPath-data operations.  GL Segment validation must be done via GraphQL to use the existing validation rule logic.)

* search for employees by ID and name
* list of departments
* GL segment string validation
* Geography validation (optional)

### Integrations to be Developed

> These are integrations w  hich are presently running on the Spring Batch system that need to be replaced by NiFi pipelines.

* Employees to Concur (INT-1357)
  * Postgres Data Extract to Concur File
  * Tracking table (optional - if we can not just compare to `concur_employee` extract table)
    * destination_code
    * key_fields
    * last_sent_date
    * last sent batch job ID
    * data hash (SHA-1 hash of interesting fields so we know whether to check if we need to send the record again.)
    * (Might need others depending on behaviors needed.  I.e., if we need to know about specific types of changes to send certain types of records or field values.)
* Employees to Trondent/Connexxus (INT-1358)
  * Postgres Data Extract to Trondent File
  * Same tracking table as above: different destination code
* Department Hierarchy to Concur (INT-1450)
  * Postgres Data Extract to Concur File
* Departmental Approvers to Concur (INT-1360)
  * Postgres Data Extract to Concur File
* Non-Employee Travellers to Concur (INT-1359)
  * Postgres Data Extract to Concur File
* Travel Agency Transactions to Concur (INT-1363)
  * Postgres Data Extract to Concur API
* UCPath Department Data to Application Table (INT-1451)
  * Postgres UCPath Department Export to Department / Approvers Table
* UCPath Employee Data to Application Table (INT-1452)
  * Postgres UCPath Employee Export to Employee Department Assignment Table


### Database Objects Needed

#### Concur-Specific

* Travel Agency Transaction Table (existing - needs new columns)  (INT-1448)
  * quick_expense_sent_flag
  * message column?
  * import job ID (user ID_timestamp)
  * import file name (if we can know this)
  * insert date
  * updated by/date
* New Tables (INT-1449)
  * Department-Sub-Department Table
    * Division / Department / Sub-Dept / T&E Approvers / last updated fields / dept name
    * last uploaded to Concur date
  * Non-Employee Table
  * Employee Load Status Table? (not used by application)
    * employee ID
    * user ID?
    * record hash? (see supporting tables)
    * Or - could we just compare to the CT_EMPLOYEE data?/ (concur_employee)
* Travel Agency default segments table (existing)

#### UCPath Extracts

* emp_primary_info
* emp_primary_job ?
* ucpath_department (INT-1413, INT-1414)
* ucpath_jobcode (not for this app)
