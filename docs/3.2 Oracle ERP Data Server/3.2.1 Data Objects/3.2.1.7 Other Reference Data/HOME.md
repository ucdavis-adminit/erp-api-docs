# 3.2.1.7 Other Reference Data

<!--BREAK-->
### Data Object: ErpApiInfo

Contains information about the ERP API server's version.

#### Access Controls

* Required Role: `PUBLIC`

#### Data Source

* Local Table/View: `undefined`

##### Properties

| Property Name | Data Type | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------- | --------- | :------------: | :-------------: | ------------- | ----- |
| versionNumber | String!   |                |                 |               |  |
| shortHash     | String    |                |                 |               |  |
| branch        | String    |                |                 |               |  |
| committedOn   | Date      |                |                 |               |  |
| erpSchema     | String!   |                |                 |               |  |
| apiSchema     | String!   |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `erpApiInfo`

> Return the current API Information Object

* **Parameters**
* **Returns**
  * `ErpApiInfo!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpInstitutionLocation



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `ERP_INSTITUTION_LOCATION`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * FscmTopModelAM.LocationAM.LocationRefPVO
  * Underlying Database Objects:
    * PER_ADDRESSES_F
    * PER_LOCATION_DETAILS_F_VL
    * PER_LOCATIONS

##### Properties

| Property Name | Data Type               | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------- | ----------------------- | :------------: | :-------------: | ------------- | ----- |
| locationId    | Long!                   |                |                 |               | Value that uniquely identifies the supplier site. |
| addressLine1  | ScmAddressLine          |                |                 |               | Address Line 1 |
| addressLine2  | ScmAddressLine          |                |                 |               | Address Line 2 |
| addressLine3  | ScmAddressLine          |                |                 |               | Address Line 3 |
| addressLine4  | ScmAddressLine          |                |                 |               | Address Line 4 |
| city          | CityName                |                |                 |               | City of the supplier address |
| postalCode    | ErpPostalCode           |                |                 |               | Postal code of the supplier address |
| countryName   | NonEmptyTrimmedString80 |                |                 |               | Country of the supplier address |
| countryCode   | ErpCountryCode          |                |                 |               | Abbreviation that identifies the country where the supplier address is located |
| county        | NonEmptyTrimmedString60 |                |                 |               | County of the supplier address |
| state         | NonEmptyTrimmedString60 |                |                 |               | State of the supplier address |

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpLocation

Locations referenced by Supplier and AR Customer Sites

#### Access Controls

* Required Role: `erp:reader-supplier`

#### Data Source

* Local Table/View: `ERP_LOCATION`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * CrmAnalyticsAM.CrmExtractAM.HzBiccExtractAM.LocationExtractPVO
  * Underlying Database Objects:
    * HZ_LOCATIONS

##### Properties

| Property Name      | Data Type               | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ----------------------- | :------------: | :-------------: | ------------- | ----- |
| locationId         | Long!                   |                |                 |               | Value that uniquely identifies the supplier site. |
| addressLine1       | ScmAddressLine          |                |                 |               | Address Line 1 |
| addressLine2       | ScmAddressLine          |                |                 |               | Address Line 2 |
| addressLine3       | ScmAddressLine          |                |                 |               | Address Line 3 |
| addressLine4       | ScmAddressLine          |                |                 |               | Address Line 4 |
| city               | CityName                |                |                 |               | City of the supplier address |
| postalCode         | ErpPostalCode           |                |                 |               | Postal code of the supplier address |
| countryName        | NonEmptyTrimmedString80 |                |                 |               | Country of the supplier address |
| countryCode        | ErpCountryCode          |                |                 |               | Abbreviation that identifies the country where the supplier address is located |
| county             | NonEmptyTrimmedString60 |                |                 |               | County of the supplier address |
| state              | NonEmptyTrimmedString60 |                |                 |               | State of the supplier address |
| statusCode         | String!                 |                |                 |               |  |
| startDate          | LocalDate               |                |                 |               | The date from when the value is available for use. |
| endDate            | LocalDate               |                |                 |               | The date till which the value is available for use. |
| lastUpdateDateTime | DateTime!               |                |                 |               | Timestamp this record was last updated in the financial system. |
| lastUpdateUserId   | ErpUserId               |                |                 |               | User ID of the person who last updated this record. |

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpUnitOfMeasure



#### Access Controls

* Required Role: `erp:reader-supplier`

#### Data Source

* Local Table/View: `ERP_UNIT_OF_MEASURE` (view)
  * Support Tables:
    * `ERP_UNIT_OF_MEASURE_TL`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * View: FscmTopModelAM.InvUomPublicViewAM.InvUomPVO
  * Underlying Database Objects:
    * INV_UNITS_OF_MEASURE_B
    * INV_UNITS_OF_MEASURE_TL

##### Properties

| Property Name   | Data Type               | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| --------------- | ----------------------- | :------------: | :-------------: | ------------- | ----- |
| unitOfMeasureId | Long                    |       Y        |        Y        |               | Unique identifier of the Unit of Measure (UOM) |
| uomCode         | ErpUnitOfMeasureCode    |                |        Y        |               | Unique short code assigned to a Unit of Measure (UOM) |
| name            | NonEmptyTrimmedString25 |                |        Y        |               | Translatable Unit of Measure (UOM) name |
| description     | NonEmptyTrimmedString50 |                |                 |               | Translatable Unit of Measure (UOM) description. |
| baseUOM         | Boolean!                |                |                 |               | Base Unit of Measure (UOM) flag. |

##### Linked Data Objects

(None)

#### Query Operations

##### `erpUnitOfMeasure`

> Get a single ErpUnitOfMeasure by unitOfMeasureId.  Returns undefined if does not exist

* **Parameters**
  * `unitOfMeasureId : String!`
* **Returns**
  * `ErpUnitOfMeasure`

##### `erpUnitOfMeasureByCode`

> Get a single ErpUnitOfMeasure by uom code.  Returns undefined if does not exist

* **Parameters**
  * `uomCode : String!`
* **Returns**
  * `ErpUnitOfMeasure`

##### `erpUnitOfMeasureSearch`

> Search for ErpUnitOfMeasure objects by multiple properties.
> See the ErpUnitOfMeasureFilterInput type for options.

* **Parameters**
  * `filter : ErpUnitOfMeasureFilterInput!`
* **Returns**
  * `ErpUnitOfMeasureSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpUser

Represents one record per fusion system user

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `ERP_USER` (view)
  * Support Tables:
    * `PER_USER`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
    * CrmAnalyticsAM.UserAM.UserPVO
    * FscmTopModelAM.PersonAM.GlobalPersonPVOViewAll
  * Underlying Database Objects:
    * PER_USERS
    * PER_USER_HISTORY
    * PER_ALL_USERS_F

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| id                 | Long!                     |                |        Y        |               | Mandatory Primary Key. |
| userId             | NonEmptyTrimmedString100! |                |        Y        |               | The latest principal username of the user |
| personId           | Long!                     |                |        Y        |               | The description of the journal category associated with the row. |
| firstName          | NonEmptyTrimmedString150! |                |                 |               | Person's First name. |
| lastName           | NonEmptyTrimmedString150! |                |        Y        |               | Person's Last name. |
| displayName        | NonEmptyTrimmedString360  |                |        Y        |               | Peron's Display name. |
| fullName           | NonEmptyTrimmedString360  |                |                 |               | Person's Full name. |
| email              | ErpEmailAddress           |                |                 |               | E-mail address. |
| assignmentStatus   | NonEmptyTrimmedString30   |                |                 |               | Unique code representing the status. |
| assignmentType     | NonEmptyTrimmedString30   |                |                 |               | Identifies the type of record: employee, CWK, applicant or non-workers |
| active             | Boolean                   |                |                 |               | Flag to mark when a user record that has been deleted in LDAP. |
| startDate          | Date                      |                |                 |               | The date that the user is active from. |
| endDate            | Date                      |                |                 |               | The date that the user ceases to be active in fusion. |
| lastUpdateDateTime | Timestamp!                |                |        Y        |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `erpUser`

> Get a single ErpUser by id.  Returns undefined if does not exist

* **Parameters**
  * `id : String!`
* **Returns**
  * `ErpUser`

##### `erpUserByUserId`

> Get a single ErpUser by user id.  Returns undefined if does not exist

* **Parameters**
  * `userId : String!`
* **Returns**
  * `ErpUser`

##### `erpUserAll`

> Get all currently valid ErpUser objects.

* **Parameters**
  * `sort : [String!]`
* **Returns**
  * `[ErpUser!]!`

##### `erpUserSearch`

> Search for ErpUser objects by multiple properties.
> See
> See the ErpUserFilterInput type for options.

* **Parameters**
  * `filter : ErpUserFilterInput!`
* **Returns**
  * `ErpUserSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.
