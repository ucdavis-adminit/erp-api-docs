# 6.3.3 SC Logic

### Summary

SC Logic requires inbound and outbound data.  However, SCLogic has chosen to integrate with our APIs for both outbound data as well as submission of journal data via the action requests.

There are some additional data extracts and APIs which are necessary to support SC Logic functions.

SC Logic will require the following additional data items extracted from Oracle:

* Assets
* Campus Codes
* Buildings
* Rooms
* Asset Custodial Divisions
* Asset Custodial Departments
* Acquisition Codes
* Condition Codes
* Equipment Fund Source Codes
* Equipment Loan Codes
* Equipment Program Codes
* Equipment Fund Source Codes
* Equipment Category Codes
* Equipment Minor Category Codes

Functional Spec: https://ucdavis.app.box.com/file/948468980344

All of the above objects will also need to be exposed as API endpoints in GraphQL.

### Components of Project

1. Create Views to expose the additional value set values in the ERP Server migration scripts.
2. Create Tables to hold the extracted asset data in the ERP Server migration scripts.
3. Create views on top of the above tables to simplify use of the tables.
4. Add the seed scripts to load data from the extracted asset data in CSV files for the BICC view objects in question.
5. Create GraphQL data types for each of needed data items.
6. Create Table to type mappings and datasources in the GraphQL server.
7. Create GraphQL operations and resolver implementations for the data types.
8. Create Postman tests to exercise the GraphQL endpoints.
9. Create the CSV to Table mapping QueryRecord processors in the data extract process group in NiFi for the two new tables.
10. Add the new view objects to the BICC Configuration.
11. Customize the Asset Additions extract to include the custom fields.

### Required Objects and Values

In the following, the "Required Attributes" are those required for SC Logic integration.  Additional attributes may be extracted during integrations if deemed potentially useful or necessary for integration/API functionality.  (E.g. last update date)

#### Buildings

* **Type of Extract:** Value Set
  * Value Set Name: `UCD BUILDING CODE`
* **Required Attributes:**
  * Code/Value
  * Name/Description
* **Searchable Attributes:**
  * Code
  * Description
  * Last Update Date
  * Enabled

#### Rooms

* **Type of Extract:** Value Set
  * Value Set Name: `UCD ROOM`
* **Required Attributes:**
  * Code/Value
  * Name/Description
* **Searchable Attributes:**
  * Code
  * Description
  * Last Update Date
  * Enabled

#### Asset Custodian Division

* **Type of Extract:** Value Set
  * Value Set Name: `CUSTODIAL DIVISION CODE`
* **Required Attributes:**
  * Code/Value
  * Name/Description
* **Searchable Attributes:**
  * Code
  * Description
  * Last Update Date
  * Enabled

These values seem to match Level C GL department codes.

#### Asset Custodian Department

* **Type of Extract:** Value Set
  * Value Set Name: `CUSTODIAL DEPARTMENT CODE`
* **Required Attributes:**
  * Code/Value
  * Name/Description
* **Searchable Attributes:**
  * Code
  * Description
  * Last Update Date
  * Enabled

#### Others

Names and value set codes for the remaining tables.  Structure and searchable attributes are the same as the above

* Campus Codes
  * UCD CAMPUS CODE
* Acquisition Codes
  * ACQUISITION CODE
* Condition Codes
  * CONDITION CODE
* Equipment Fund Source Codes
  * EQ FUND SOURCE CODE DEP
* Equipment Loan Codes
  * EQ LOAN CODE
* Equipment Program Codes
  * EQ PROGRAM CODE
* Fund Source Codes
  * FUNDING SOURCE
* Equipment Category Codes
  * UCD MAJOR
* Equipment Minor Category Codes
  * UCD MINOR


#### Assets

* **Type of Extract:** BICC
  * BICC View Object: `FscmTopModelAM.FinExtractAM.FaBiccExtractAM.AdditionExtractPVO`
    * Required View Customizations:
      * Addition of custom attribute DFFs
    * Underlying Tables:
      * `FA_ADDITIONS_B` / <https://docs.oracle.com/en/cloud/saas/financials/22c/oedmf/faadditionsb-23506.html#faadditionsb-23506>
      * `FA_ADDITIONS_TL`
  * BICC View Object: `FscmTopModelAM.FinExtractAM.FaBiccExtractAM.BookExtractPVO`
    * Underlying Tables:
      * `FA_BOOKS` / <https://docs.oracle.com/en/cloud/saas/financials/22c/oedmf/fabooks-13244.html#fabooks-13244>
* **Required Attributes:**
  * Asset Tag Number
  * Asset Description
  * Manufacturer
  * Serial Number
  * Model
  * Cost
  * Date Placed in Service
  * Asset Category Segment2 - Minor Category (value and value description)
  * Asset Location Segment 1 - Campus Code (value and value description)
  * Asset Location Segment 2 - Building Code (value and value description)
  * Asset Location Segment 3 - Room (value and value description)
  * Asset Location Segment 4 - Alt Address (value and value description)
  * DFF Attribute 18 - Custodial Division Code (value and value description)
  * DFF Attribute 6 - Custodial Department Code (value and value description)
  * Attribute 19 - Asset Rep
  * DFF Attribute 2 - Title Flag
  * DFF Attribute 1 - Acquisition Code (value and value description)
  * DFF Attribute 3 - Primary Fund Number (value and value description)
  * DFF Attribute 4 - EQ Fund Source Code (value and value description)
  * DFF Attribute 8 - Condition Code (value and value description)
  * DFF Attribute 9 - EQ Loan Code (value and value description)
  * DFF ATTRIBUTE_DATE1 - Last Inventory Cert Date
  * DFF Attribute 12 - PI Name
  * DFF Attribute 13 - Sponsor Info
  * DFF Attribute 14 - Loan Detail
  * DFF Attribute 16 - Warranty Agreement Info
  * DFF Attribute 20 - Lawson Asset No
* **Searchable Attributes:**
  * Asset Tag Number
  * Asset Description
  * Last Update Date
  * Enabled
  * Lawson Asset No
  * Primary Fund Number
  * Minor Category
  * Custodial Department Code
  * Custodial Division Code
* **Notes**
  * Description will not be in the table extract - most are in support tables or value sets.  For the base table, we will only hold the code from the DFF field.



### SC Logic Data Extract Tables

#### Building (View)

* **View Name:** `erp_building`

| Column Name       | Column Type | Comments |
| ----------------- | ----------- | -------- |
| code              | varchar     |          |
| description       | varchar     |          |
| value_id          | bigint      |          |
| enabled_flag      | char        |          |
| start_date_active | date        |          |
| end_date_active   | date        |          |
| last_update_login | varchar     |          |
| last_update_date  | timestamp   |          |

##### View SQL

```sql
SELECT v.value AS code
    , v.value_id
    , vn.description
    , v.enabled_flag
    , v.start_date_active
    , v.end_date_active
    , v.last_update_login
    , v.last_update_date
FROM dev4_erp.value_set_typed_values_pvo    v
JOIN dev4_erp.value_set_typed_values_tl_pvo vn
  ON vn.value_id = v.value_id
 AND vn.language = 'US'
WHERE v.value_set_code = 'UCD BUILDING CODE'
```

#### Room (View)

* **View Name:** `erp_building_room`

| Column Name       | Column Type | Comments |
| ----------------- | ----------- | -------- |
| code              | varchar     |          |
| description       | varchar     |          |
| value_id          | bigint      |          |
| enabled_flag      | char        |          |
| start_date_active | date        |          |
| end_date_active   | date        |          |
| last_update_login | varchar     |          |
| last_update_date  | timestamp   |          |

##### View SQL

```sql
SELECT v.value AS code
    , v.value_id
    , vn.description
    , v.enabled_flag
    , v.start_date_active
    , v.end_date_active
    , v.last_update_login
    , v.last_update_date
FROM dev4_erp.value_set_typed_values_pvo    v
JOIN dev4_erp.value_set_typed_values_tl_pvo vn
  ON vn.value_id = v.value_id
 AND vn.language = 'US'
 -- value set code may change, needs to be verified after outside of DEV4
WHERE v.value_set_code = 'UCD ROOM IND'
```

#### Asset Custodial Division (View)

* **View Name:** `fa_custodial_division`

| Column Name       | Column Type | Comments |
| ----------------- | ----------- | -------- |
| code              | varchar     |          |
| description       | varchar     |          |
| value_id          | bigint      |          |
| enabled_flag      | char        |          |
| start_date_active | date        |          |
| end_date_active   | date        |          |
| last_update_login | varchar     |          |
| last_update_date  | timestamp   |          |

##### View SQL

```sql
SELECT v.value AS code
    , v.value_id
    , vn.description
    , v.enabled_flag
    , v.start_date_active
    , v.end_date_active
    , v.last_update_login
    , v.last_update_date
FROM dev4_erp.value_set_typed_values_pvo    v
JOIN dev4_erp.value_set_typed_values_tl_pvo vn
  ON vn.value_id = v.value_id
 AND vn.language = 'US'
WHERE v.value_set_code = 'CUSTODIAL DIVISION CODE'
```

#### Asset Custodial Department (View)

* **View Name:** `fa_custodial_department`

| Column Name       | Column Type | Comments |
| ----------------- | ----------- | -------- |
| code              | varchar     |          |
| description       | varchar     |          |
| value_id          | bigint      |          |
| enabled_flag      | char        |          |
| start_date_active | date        |          |
| end_date_active   | date        |          |
| last_update_login | varchar     |          |
| last_update_date  | timestamp   |          |

##### View SQL

```sql
SELECT v.value AS code
    , v.value_id
    , vn.description
    , v.enabled_flag
    , v.start_date_active
    , v.end_date_active
    , v.last_update_login
    , v.last_update_date
FROM dev4_erp.value_set_typed_values_pvo    v
JOIN dev4_erp.value_set_typed_values_tl_pvo vn
  ON vn.value_id = v.value_id
 AND vn.language = 'US'
WHERE v.value_set_code = 'CUSTODIAL DEPARTMENT CODE'
```

#### Others

All the others are the same as the above, except for the value set code.

* Table Name: `fa_acquisition_code`
  * ACQUISITION CODE
* Table Name: `fa_condition`
  * CONDITION CODE
* Table Name: `fa_fund_source`
  * EQ FUND SOURCE CODE DEP
* Table Name: `fa_loan_code`
  * EQ LOAN CODE
* Table Name: `fa_program`
  * EQ PROGRAM CODE
* Table Name: `erp_fund_source`
  * FUNDING SOURCE
* Table Name: `erp_campus`
  * UCD CAMPUS CODE
* Table Name: `fa_major_category`
  * UCD MAJOR
* Table Name: `fa_minor_category`
  * UCD MINOR

#### Asset (Table)

* **Table Name:** `fa_asset`

| Column Name             | Column Type   | Functional Spec Name      | Comments |
| ----------------------- | ------------- | ------------------------- | -------- |
| asset_id                | decimal(18,0) |                           |          |
| asset_number            | varchar(30)   |                           |          |
| asset_tag_nbr           | varchar(15)   | Asset Tag Number          |          |
| asset_type              | varchar(11)   |                           |          |
| asset_category_id       | decimal(18,0) |                           |          |
| description             | varchar(80)   | Asset Description         |          |
| manufacturer_name       | varchar(360)  | Manufacturer              |          |
| serial_number           | varchar(35)   | Serial Number             |          |
| model_number            | varchar(40)   | Model                     |          |
| minor_category          | varchar(150)  | Minor Category            |          |
| campus_code             | varchar(150)  | Campus Code               |          |
| building_code           | varchar(150)  | Building Code             |          |
| room_code               | varchar(150)  | Room                      |          |
| alternate_address       | varchar(150)  | Alt Address               |          |
| cust_div_code           | varchar(150)  | Custodial Division Code   |          |
| cust_dept_code          | varchar(150)  | Custodial Department Code |          |
| asset_rep_employee_id   | varchar(150)  | Asset Rep                 |          |
| title_flag              | char(1)       | Title Flag                |          |
| acquisition_code        | varchar(150)  | Acquisition Code          |          |
| primary_fund_code       | varchar(150)  | Primary Fund Number       |          |
| equip_fund_source_code  | varchar(150)  | EQ Fund Source Code       |          |
| condition_code          | varchar(150)  | Condition Code            |          |
| equip_loan_code         | varchar(150)  | EQ Loan Code              |          |
| last_certification_date | date          | Last Inventory Cert Date  |          |
| pi_employee_id          | varchar(150)  | PI                        |          |
| sponsor_name            | varchar(150)  | Sponsor Info              |          |
| loan_detail             | varchar(150)  | Loan Detail               |          |
| warranty_info           | varchar(150)  | Warranty Agreement Info   |          |
| lawson_asset_nbr        | varchar(150)  | Lawson Asset No           |          |
| creation_date           | date          |                           |          |
| last_update_login       | varchar(32)   |                           |          |
| last_update_date        | timestamp     |                           |          |

* **Indexes**
  * asset_id (Primary Key)
  * asset_number (Unique)
  * asset_tag_nbr (Unique)
  * last_update_date

#### Asset Cost History (Table)

* **Table Name:** `fa_asset_cost_history`

| Column Name               | Column Type   | Functional Spec Name   | Comments |
| ------------------------- | ------------- | ---------------------- | -------- |
| asset_id                  | decimal(18,0) |                        |          |
| book_type_code            | varchar(30)   |                        |          |
| transaction_header_id_in  | decimal(18,0) |                        |          |
| transaction_header_id_out | decimal(18,0) |                        |          |
| in_service_date           | date          | Date Placed in Service |          |
| total_cost                | decimal       | Cost                   |          |
| effective_date            | date          |                        |          |
| ineffective_date          | date          |                        |          |
| creation_date             | date          |                        |          |
| last_update_login         | varchar(32)   |                        |          |
| last_update_date          | timestamp     |                        |          |

* **Indexes**
  * transaction_header_id_in (Primary Key)
  * asset_id, book_type_code, transaction_header_id_out (Unique Key)
  * last_update_date

#### Asset Cost (View)

Gets the current row from the `fa_asset_cost_history` table.  There will be only one row effective for the current time.

* **View Name:** `fa_asset_cost_current_v`

```sql
SELECT
  asset_id
, book_type_code
, in_service_date
, total_cost
, effective_date
, last_update_login
, last_update_date
FROM fa_asset_cost_history
WHERE CURRENT_DATE >= COALESCE(effective_date, CURRENT_DATE)
  and CURRENT_DATE < COALESCE(ineffective_date, 'infinity')
```

#### Asset Category (Table)

> General category information for fixed assets.

* **Table Name:** `fa_asset_category`

| Column Name          | Column Type   | Functional Spec Name | Comments    |
| -------------------- | ------------- | -------------------- | ----------- |
| asset_category_id    | decimal(18,0) |                      |             |
| name                 | varchar(40)   |                      |             |
| enabled_flag         | char(1)       |                      | Trim to Y/N |
| inventorial_flag     | char(1)       |                      | Trim to Y/N |
| capitalize_flag      | char(1)       |                      |             |
| property_type_code   | varchar(30)   |                      |             |
| category_type_code   | varchar(30)   |                      |             |
| major_category_code  | varchar(30)   |                      | SEGMENT1    |
| minor_category_code  | varchar(30)   |                      | SEGMENT2    |
| owned_or_leased_code | varchar(6)    |                      |             |
| last_update_login    | varchar(32)   |                      |             |
| last_update_date     | timestamp     |                      |             |

* **Indexes**
  * asset_category_id (Primary Key)
  * last_update_date

#### Fixed Asset Module Locations (Table)

> Fixed asset module location reference data.  These location IDs are private to the FA module.  Oracle has a method of cross-referencing these to other location tables in Oracle.

* **Table Name:** `fa_location`

| Column Name       | Column Type   | Functional Spec Name | Comments |
| ----------------- | ------------- | -------------------- | -------- |
| location_id       | decimal(18,0) |                      |          |
| campus_code       | varchar(150)  | Campus Code          |          |
| building_code     | varchar(150)  | Building Code        |          |
| room_code         | varchar(150)  | Room                 |          |
| address           | varchar(150)  | Alt Address          |          |
| last_update_login | varchar(32)   |                      |          |
| last_update_date  | timestamp     |                      |          |

* **Indexes**
  * location_id (Primary Key)
  * building_code
  * last_update_date

#### Asset Distribution (Table)

> Distribution history for an asset for location and depreciation accounting information.  Rows are effective dated.  Unless there is some sort of split accounting on the distributions, this should result in a single row per asset at a given time.

* **Table Name:** `fa_asset_distribution_history`

| Column Name              | Column Type   | Functional Spec Name | Comments                               |
| ------------------------ | ------------- | -------------------- | -------------------------------------- |
| asset_id                 | decimal(18,0) |                      |                                        |
| distribution_id          | decimal(18,0) |                      |                                        |
| book_type_code           | varchar(30)   |                      |                                        |
| depr_code_combination_id | decimal(18,0) |                      |                                        |
| location_id              | decimal(18,0) |                      |                                        |
| effective_date           | date          |                      |                                        |
| ineffective_date         | date          |                      |                                        |
| units_assigned           | decimal(12,6) |                      | Unsure of use - may need for filtering |
| last_update_login        | varchar(32)   |                      |                                        |
| last_update_date         | timestamp     |                      |                                        |

* **Indexes**
  * distribution_id, book_type_code (Primary Key)
  * asset_id, effective_date
  * location_id
  * last_update_date

#### Asset Distribution (View)

> Get the current distribution information for an asset.  This includes the location code.

* **View Name:** `fa_asset_distribution_v`

```sql
SELECT
  asset_id
, distribution_id
, book_type_code
, depr_code_combination_id
, location_id
, effective_date
, last_update_login
, last_update_date
WHERE CURRENT_DATE >= COALESCE(effective_date, CURRENT_DATE)
  and CURRENT_DATE < COALESCE(ineffective_date, 'infinity')
```

#### Asset Location (View)

> Get the current location of an asset.

* **View Name:** `fa_asset_location_v`

```sql
SELECT
  d.asset_id
, l.location_id
, l.campus_code
, l.building_code
, l.room_code
, l.address
, l.last_update_login
, GREATER(d.last_update_date, l.last_update_date) AS last_update_date
FROM fa_asset_distribution_v d
JOIN fa_location             l ON l.location_id = d.location_id
```

#### Asset (View)

* **View Name:** `fa_asset_v`

```sql
SELECT
  fa.asset_id,
  fa.asset_number,
  fa.asset_tag_nbr,
  fa.asset_type,
  fa.asset_category_id,
  fa.description,
  fa.manufacturer_name,
  fa.serial_number,
  fa.model_number,
  fa.last_certification_date,
  fa.pi_employee_id,
  pi.full_name                       AS pi_name,
  fa.sponsor_name,
  fa.loan_detail,
  fa.warranty_info,
  fa.lawson_asset_nbr,
  fa.asset_rep_employee_id,
  asset_rep.full_name                AS asset_rep_name,
  fa.title_flag,
  ch.in_service_date,
  ch.total_cost,
  cat.major_category_code,
  cat.minor_category_code,
  mc.description                     AS minor_category_name,
  loc.campus_code,
  campus_name.description            AS campus_name,
  loc.building_code,
  building_name.description          AS building_name,
  loc.room_code,
  room_name.description              AS room_name,
  loc.alternate_address,
  fa.cust_div_code,
  cust_div_name.description          AS cust_div_name,
  fa.cust_dept_code,
  cust_dept_name.description         AS cust_dept_name,
  fa.acquisition_code,
  acquisition_code_name.description  AS acquisition_code_name,
  fa.primary_fund_code,
  primary_fund_name.description      AS primary_fund_name,
  fa.equip_fund_source_code,
  equip_fund_source_name.description AS equip_fund_source_name,
  fa.condition_code,
  condition_code_name.description    AS condition_code_name,
  fa.equip_loan_code,
  equip_loan_code_name.description   AS equip_loan_code_name,
  fa.creation_date,
  fa.last_update_login,
  GREATEST(fa.last_update_date, ch.last_update_date) AS last_update_date
FROM      ${SCHEMA_NAME}.fa_asset                fa
     JOIN ${SCHEMA_NAME}.fa_asset_cost_current_v ch                     ON ch.asset_id                        = fa.asset_id
     JOIN ${SCHEMA_NAME}.fa_asset_location_v     loc                    ON loc.asset_id                       = fa.asset_id
     JOIN ${SCHEMA_NAME}.fa_asset_category       cat                    ON cat.asset_category_id              = fa.asset_category_id
     JOIN ${SCHEMA_NAME}.fa_minor_category       mc                     ON mc.code                            = cat.minor_category_code
                                                                       AND mc.parent_code                     = cat.major_category_code
LEFT JOIN ${SCHEMA_NAME}.erp_campus              campus_name            ON campus_name.code                   = loc.campus_code
LEFT JOIN ${SCHEMA_NAME}.erp_building            building_name          ON building_name.code                 = loc.building_code
LEFT JOIN ${SCHEMA_NAME}.erp_building_room       room_name              ON room_name.code                     = loc.room_code
LEFT JOIN ${SCHEMA_NAME}.fa_custodial_division   cust_div_name          ON cust_div_name.code                 = fa.cust_div_code
LEFT JOIN ${SCHEMA_NAME}.fa_custodial_department cust_dept_name         ON cust_dept_name.code                = fa.cust_dept_code
                                                                       AND cust_dept_name.parent_code         = fa.cust_div_code
LEFT JOIN ${SCHEMA_NAME}.fa_acquisition_code     acquisition_code_name  ON acquisition_code_name.code         = fa.acquisition_code
LEFT JOIN ${SCHEMA_NAME}.erp_fund_source         primary_fund_name      ON primary_fund_name.code             = fa.primary_fund_code
LEFT JOIN ${SCHEMA_NAME}.fa_fund_source          equip_fund_source_name ON equip_fund_source_name.code        = fa.equip_fund_source_code
                                                                       AND equip_fund_source_name.parent_code = fa.primary_fund_code
LEFT JOIN ${SCHEMA_NAME}.fa_condition            condition_code_name    ON condition_code_name.code           = fa.condition_code
LEFT JOIN ${SCHEMA_NAME}.fa_loan_code            equip_loan_code_name   ON equip_loan_code_name.code          = fa.equip_loan_code
LEFT JOIN ${SCHEMA_NAME}.per_all_people_f        pi                     ON pi.person_number                   = fa.pi_employee_id
LEFT JOIN ${SCHEMA_NAME}.per_all_people_f        asset_rep              ON asset_rep.person_number            = fa.asset_rep_employee_id
```
