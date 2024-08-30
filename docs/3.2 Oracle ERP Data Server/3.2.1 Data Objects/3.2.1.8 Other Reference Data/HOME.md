# 3.2.1.8 Other Reference Data

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
### Data Object: ErpBuilding



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `ERP_BUILDING` (view)
  * Support Tables:
    * `VALUE_SET_TYPED_VALUES_PVO`
    * `VALUE_SET_TYPED_VALUES_TL_PVO`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
  * Underlying Database Objects:
    * 

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | NonEmptyTrimmedString150! |                |        Y        |               |  |
| id                 | Long!                     |                |                 |               |  |
| name               | NonEmptyTrimmedString240! |                |        Y        |               |  |
| enabled            | Boolean!                  |                |        Y        |               |  |
| startDate          | LocalDate                 |                |                 |               |  |
| endDate            | LocalDate                 |                |                 |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `erpBuildingRoom`

> Get a single ErpBuildingRoom by id.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `ErpBuildingRoom`

##### `erpBuildingRoomSearch`

> Search for ErpBuildingRoom objects by multiple properties.
> 
> See the ErpBuildingRoomFilterInput type for options.

* **Parameters**
  * `filter : ErpBuildingRoomFilterInput!`
* **Returns**
  * `ErpBuildingRoomSearchResults!`

##### `erpBuilding`

> Get a single ErpBuilding by id.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `ErpBuilding`

##### `erpBuildingSearch`

> Search for ErpBuilding objects by multiple properties.
> 
> See the ErpBuildingFilterInput type for options.

* **Parameters**
  * `filter : ErpBuildingFilterInput!`
* **Returns**
  * `ErpBuildingSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpBuildingRoom



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `ERP_BUILDING_ROOM` (view)
  * Support Tables:
    * `VALUE_SET_TYPED_VALUES_PVO`
    * `VALUE_SET_TYPED_VALUES_TL_PVO`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
  * Underlying Database Objects:
    * 

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | NonEmptyTrimmedString150! |                |        Y        |               |  |
| id                 | Long!                     |                |                 |               |  |
| name               | NonEmptyTrimmedString240! |                |        Y        |               |  |
| enabled            | Boolean!                  |                |        Y        |               |  |
| startDate          | LocalDate                 |                |                 |               |  |
| endDate            | LocalDate                 |                |                 |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `erpBuildingRoom`

> Get a single ErpBuildingRoom by id.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `ErpBuildingRoom`

##### `erpBuildingRoomSearch`

> Search for ErpBuildingRoom objects by multiple properties.
> 
> See the ErpBuildingRoomFilterInput type for options.

* **Parameters**
  * `filter : ErpBuildingRoomFilterInput!`
* **Returns**
  * `ErpBuildingRoomSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpCampus



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `ERP_CAMPUS` (view)
  * Support Tables:
    * `VALUE_SET_TYPED_VALUES_PVO`
    * `VALUE_SET_TYPED_VALUES_TL_PVO`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
  * Underlying Database Objects:
    * 

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | NonEmptyTrimmedString150! |                |        Y        |               |  |
| id                 | Long!                     |                |                 |               |  |
| name               | NonEmptyTrimmedString240! |                |        Y        |               |  |
| enabled            | Boolean!                  |                |        Y        |               |  |
| startDate          | LocalDate                 |                |                 |               |  |
| endDate            | LocalDate                 |                |                 |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `erpCampus`

> Get a single ErpCampus by id.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `ErpCampus`

##### `erpCampusSearch`

> Search for ErpCampus objects by multiple properties.
> 
> See the ErpCampusFilterInput type for options.

* **Parameters**
  * `filter : ErpCampusFilterInput!`
* **Returns**
  * `ErpCampusSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpDepartmentalApprover

Represents an approver from the Oracle Role-Based Security module.  Values here have been extracted
from advanced security table and formatted for API use.

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `ERP_FIN_DEPT_APPROVER` (view)
  * Support Tables:
    * `ERP_DEPT_APPROVER_SETUP`
    * `ERP_FIN_DEPT`
    * `ASE_USER_ROLE_MEMBER`
    * `PER_USER`
    * `PER_ALL_PEOPLE_F`
* Data Origin:
  * System: Oracle BIPublisher
  * Extract Objects:
    * /Custom/Interfaces/Data Extracts/OracleRoles.xdo
  * Underlying Database Objects:
    * ASE_USER_ROLE_MBR
    * ASE_USER_VL
    * ASE_ROLE_VL

##### Properties

| Property Name | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------- | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| approverType  | NonEmptyTrimmedString50!  |                |                 |               | Type of the approver as defined by the functional users.  This name defines its usage in Oracle. |
| userId        | ErpUserId!                |                |                 |               | Oracle User ID of the person.  This should be the same as the UCD Computing account ID for campus employees. |
| name          | NonEmptyTrimmedString360! |                |                 |               |  |
| firstName     | NonEmptyTrimmedString150  |                |                 |               |  |
| lastName      | NonEmptyTrimmedString150  |                |                 |               |  |
| employeeId    | UcEmployeeId              |                |                 |               |  |
| emailAddress  | NonEmptyTrimmedString240  |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpFavoritesCostCenter



#### Access Controls

* Required Role: ``

#### Data Source

* Local Table/View: `undefined`

##### Properties

| Property Name  | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| -------------- | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| id             | Long!                     |                |                 |               | Value that uniquely identifies the ErpFavoritesCostCenter. |
| userId         | NonEmptyTrimmedString20!  |                |                 |               | UCD NetworkId of the user that owns the Favorite |
| key            | NonEmptyTrimmedString100! |                |                 |               | Key as a unique name for the Favorite value |
| value          | JSON                      |                |                 |               | Value of the favorite (JSON) |
| creationDate   | DateTime!                 |                |                 |               |  |
| lastUpdateDate | DateTime!                 |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `erpFavoritesCostCenter`

> Get a single ErpFavoritesCostCenter by internal ID.  Returns undefined if does not exist

* **Parameters**
  * `id : NumericString!`
* **Returns**
  * `ErpFavoritesCostCenter`

##### `erpFavoritesCostCenterById`

> Get a single ErpFavoritesCostCenter by internal ID.  Returns undefined if does not exist

* **Parameters**
  * `id : NumericString!`
* **Returns**
  * `ErpFavoritesCostCenter`

##### `erpFavoritesCostCenterByUserIdAndKey`

> Get a single ErpFavoritesCostCenter by userId and key.  Returns undefined if does not exist

* **Parameters**
  * `userId : NonEmptyTrimmedString20!`
  * `key : NonEmptyTrimmedString100!`
* **Returns**
  * `ErpFavoritesCostCenter`

##### `erpFavoritesCostCenterByUserId`

> Get all of ErpFavoritesCostCenter by userId.  Returns undefined if does not exist

* **Parameters**
  * `userId : NonEmptyTrimmedString20!`
* **Returns**
  * `[ErpFavoritesCostCenter]!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpFundSource



#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `ERP_FUND_SOURCE` (view)
  * Support Tables:
    * `VALUE_SET_TYPED_VALUES_PVO`
    * `VALUE_SET_TYPED_VALUES_TL_PVO`
* Data Origin:
  * System: Oracle BICC
  * Extract Objects:
  * Underlying Database Objects:
    * 

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| code               | NonEmptyTrimmedString150! |                |        Y        |               |  |
| id                 | Long!                     |                |                 |               |  |
| name               | NonEmptyTrimmedString240! |                |        Y        |               |  |
| enabled            | Boolean!                  |                |        Y        |               |  |
| startDate          | LocalDate                 |                |                 |               |  |
| endDate            | LocalDate                 |                |                 |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `erpFundSource`

> Get a single ErpFundSource by id.  Returns undefined if does not exist

* **Parameters**
  * `code : String!`
* **Returns**
  * `ErpFundSource`

##### `erpFundSourceSearch`

> Search for ErpFundSource objects by multiple properties.
> 
> See the ErpFundSourceFilterInput type for options.

* **Parameters**
  * `filter : ErpFundSourceFilterInput!`
* **Returns**
  * `ErpFundSourceSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpInstitutionLocation

UC Davis locations that can be used for delivery or receiving locations.

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
| locationId    | Long!                   |                |                 |               | Value that uniquely identifies the supplier site internally to Oracle. |
| locationCode  | String!                 |                |        Y        |               | Value that uniquely identifies the supplier site for use on interfaces and in the Oracle UI. |
| addressLine1  | ScmAddressLine!         |                |        Y        |               | Address Line 1 |
| addressLine2  | ScmAddressLine          |                |                 |               | Address Line 2 |
| addressLine3  | ScmAddressLine          |                |                 |               | Address Line 3 |
| addressLine4  | ScmAddressLine          |                |                 |               | Address Line 4 |
| city          | CityName!               |                |        Y        |               | City Name |
| state         | NonEmptyTrimmedString60 |                |        Y        |               | State Code |
| postalCode    | ErpPostalCode           |                |        Y        |               | Postal code |
| countryCode   | ErpCountryCode!         |                |        Y        |               | Country Code |
| receivingSite | Boolean!                |                |        Y        |               | Whether the location can be used as the receiving address for a purchase order. |
| deliverySite  | Boolean!                |                |        Y        |               | Whether the location can be used as the delivery address for a requisition. |
| enabled       | Boolean!                |                |        Y        |               | Whether this address is enabled for current use. |

##### Linked Data Objects

(None)

#### Query Operations

##### `erpInstitutionLocation`

> Get a single ErpInstitutionLocation by internal ID.  Returns undefined if does not exist

* **Parameters**
  * `id : String!`
* **Returns**
  * `ErpInstitutionLocation`

##### `erpInstitutionLocationByCode`

> Get a single ErpInstitutionLocation by code.  Returns undefined if does not exist

* **Parameters**
  * `locationCode : String!`
* **Returns**
  * `ErpInstitutionLocation`

##### `erpInstitutionLocationSearch`

> Search for ErpInstitutionLocation objects by multiple properties.
> See the ErpInstitutionLocationFilterInput type for options.

* **Parameters**
  * `filter : ErpInstitutionLocationFilterInput!`
* **Returns**
  * `ErpInstitutionLocationSearchResults!`

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
### Data Object: ErpRole

Definition of a role in the ERP system.

#### Access Controls

* Required Role: ``

#### Data Source

* Local Table/View: `undefined`

##### Properties

| Property Name   | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| --------------- | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| roleCode        | NonEmptyTrimmedString100! |                |        Y        |               | Internal identifier for the role membership. |
| roleName        | NonEmptyTrimmedString240! |                |        Y        |               |  |
| roleDescription | String                    |                |                 |               |  |

##### Linked Data Objects

(None)

#### Query Operations

##### `erpRoles`

> Get the list of roles assigned to your consumer.

* **Parameters**
* **Returns**
  * `[String!]!`

##### `erpRole`

> Get a single ErpRole by ID.  Returns undefined if does not exist

* **Parameters**
  * `roleCode : NonEmptyTrimmedString100!`
* **Returns**
  * `ErpRole`

##### `erpRoleByName`

> Get a single ErpRole by its name.  Returns undefined if does not exist

* **Parameters**
  * `roleName : NonEmptyTrimmedString240!`
* **Returns**
  * `ErpRole`

##### `erpRoleAll`

> Gets all ERP System Roles

* **Parameters**
* **Returns**
  * `[ErpRole!]!`

##### `erpRoleSearch`

> Search for ErpRole objects by multiple properties.
> See
> See the ErpRoleFilterInput type for options.

* **Parameters**
  * `filter : ErpRoleFilterInput!`
* **Returns**
  * `ErpRoleSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpUnitOfMeasure



#### Access Controls

* Required Role: `erp:reader-refdata`

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

##### `erpUnitOfMeasureByName`

> Get a single ErpUnitOfMeasure by unit of measure.  Returns undefined if does not exist

* **Parameters**
  * `name : String!`
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

A user as known to the ERP application.

#### Access Controls

* Required Role: `erp:reader-refdata`

#### Data Source

* Local Table/View: `ERP_USER` (view)
  * Support Tables:
    * `PER_USER`
    * `PER_ALL_PEOPLE_F`
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
| id                 | Long!                     |                |                 |               | Internal identifier for the user account. |
| userId             | ErpUserId!                |                |        Y        |               | User ID used to identify the person in the ERP application.  Matches their UCD computing account. |
| personId           | Long!                     |                |                 |               | Internal person identifier linked to the user account. |
| employeeId         | UcEmployeeId              |                |        Y        |               | UCPath employee ID of the user. |
| firstName          | NonEmptyTrimmedString150  |                |        Y        |               | Person's First name. |
| lastName           | NonEmptyTrimmedString150! |                |        Y        |               | Person's Last name. |
| displayName        | NonEmptyTrimmedString360! |                |        Y        |               | Peron's Display name. |
| email              | ErpEmailAddress           |                |        Y        |               | E-mail address. |
| assignmentStatus   | NonEmptyTrimmedString30   |                |                 |               | Whether their employee assignment is ACTIVE or INACTIVE. |
| assignmentType     | NonEmptyTrimmedString30   |                |                 |               | Identifies the type of record: employee (E) or Contingent-Worker (C) |
| active             | Boolean!                  |                |        Y        |               |  |
| startDate          | LocalDate!                |                |                 |               | The date that the user is active from. |
| endDate            | LocalDate                 |                |                 |               | The date that the user ceases to be active in fusion. |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |
| userRoles          | [ErpUserRole!]!           |                |                 |               | List of roles assigned to the user.  By default includes only the current and active roles.  Use includeInactive to include all role memberships ever assigned to the person. |

* `userRoles` : `[ErpUserRole!]!`
  * List of roles assigned to the user.  By default includes only the current and active roles.  Use includeInactive to include all role memberships ever assigned to the person.
  * Arguments:
    * `includeInactive` : `Boolean` = false
  * Description of `ErpUserRole`:
    * Association between a user account and role in the Oracle application.

##### Linked Data Objects

(None)

#### Query Operations

##### `erpUserRoleDataAccess`

> Get a single ErpUserRoleDataAccess by ID.  Returns undefined if does not exist

* **Parameters**
  * `id : Long!`
* **Returns**
  * `ErpUserRoleDataAccess`

##### `erpUserRoleDataAccessByUserId`

> Get ErpUserRoleDataAccess records by user ID.  Only returns current and active user data security records.

* **Parameters**
  * `userId : ErpUserId!`
* **Returns**
  * `[ErpUserRoleDataAccess!]!`

##### `erpUserRoleDataAccessByUserIdAndRole`

> Get ErpUserRoleDataAccess records by user ID and role code or name.  Only returns current and active user data security records.

* **Parameters**
  * `userId : ErpUserId!`
  * `roleCodeOrName : NonEmptyTrimmedString100!`
* **Returns**
  * `[ErpUserRoleDataAccess!]!`

##### `erpUserRoleDataAccessSearch`

> Search for ErpUserRoleDataAccess objects by multiple properties.
> See
> See the ErpUserRoleDataAccessFilterInput type for options.

* **Parameters**
  * `filter : ErpUserRoleDataAccessFilterInput!`
* **Returns**
  * `ErpUserRoleDataAccessSearchResults!`

##### `erpUserRole`

> Get a single ErpUserRole by ID.  Returns undefined if does not exist

* **Parameters**
  * `id : Long!`
* **Returns**
  * `ErpUserRole`

##### `erpUserRoleByUserIdAndRole`

> Get ErpUserRoles by user ID and role code or name.  Only returns current and active user roles.  Returns undefined if one does not exist.

* **Parameters**
  * `userId : ErpUserId!`
  * `roleCodeOrName : NonEmptyTrimmedString100!`
* **Returns**
  * `ErpUserRole`

##### `erpUserRoleByUserId`

> Get ErpUserRoles by user ID.  Only returns current and active user roles.

* **Parameters**
  * `userId : ErpUserId!`
* **Returns**
  * `[ErpUserRole!]!`

##### `erpUserRoleSearch`

> Search for ErpUserRole objects by multiple properties.
> See
> See the ErpUserRoleFilterInput type for options.

* **Parameters**
  * `filter : ErpUserRoleFilterInput!`
* **Returns**
  * `ErpUserRoleSearchResults!`

##### `erpUserRoleRequestStatus`

> Get the status of a previously submitted ERP User Role request by the API-assigned request ID.

* **Parameters**
  * `requestId : UUID!`
* **Returns**
  * `ErpUserRoleRequestStatusOutput`

##### `erpUserRoleRequestStatusByConsumerTracking`

> Get the status of a previously submitted ERP User Role request by the consumer's unique tracking ID.

* **Parameters**
  * `consumerTrackingId : String!`
* **Returns**
  * `ErpUserRoleRequestStatusOutput`

##### `erpUserRoleRequestStatusByConsumerReference`

> Get the statuses of previously submitted ERP User Role requests by the consumer's reference ID.

* **Parameters**
  * `consumerReferenceId : String!`
* **Returns**
  * `[ErpUserRoleRequestStatusOutput!]!`

##### `erpUserRoleRequestStatusByBatchId`

> Get the list of ERP User Role requests which were processed via the given batch ID.

* **Parameters**
  * `batchId : UUID!`
* **Returns**
  * `[ErpUserRoleRequestStatusOutput!]!`

##### `erpUserApprovalGroupByUserId`

> Get ErpUserApprovalGroups by user ID.  Only returns current and active records.

* **Parameters**
  * `userId : ErpUserId!`
* **Returns**
  * `[ErpUserApprovalGroup!]!`

##### `erpUserApprovalGroupByGroupName`

> Get ErpUserApprovalGroups by a group name.  Only returns current and active records.

* **Parameters**
  * `approvalGroupName : NonEmptyTrimmedString80!`
* **Returns**
  * `[ErpUserApprovalGroup!]!`

##### `erpUserApprovalGroupAll`

> Get all ErpUserApprovalGroups.  Only returns current and active records.

* **Parameters**
* **Returns**
  * `[ErpUserApprovalGroup!]!`

##### `erpUserApprovalGroupSearch`

> Search for ErpUserApprovalGroup objects by multiple properties.
> See
> See the ErpUserApprovalGroupFilterInput type for options.

* **Parameters**
  * `filter : ErpUserApprovalGroupFilterInput!`
* **Returns**
  * `ErpUserApprovalGroupSearchResults!`

##### `erpUser`

> Get a single ErpUser by ID.  Returns undefined if does not exist

* **Parameters**
  * `id : Long!`
* **Returns**
  * `ErpUser`

##### `erpUserByPersonId`

> Get a single ErpUser by Oracle Person ID.  Returns undefined if does not exist

* **Parameters**
  * `personId : Long!`
* **Returns**
  * `ErpUser`

##### `erpUserByUserId`

> Get a single ErpUser by user ID.  Returns undefined if does not exist

* **Parameters**
  * `userId : ErpUserId!`
* **Returns**
  * `ErpUser`

##### `erpUserByEmployeeId`

> Get a single ErpUser by employee ID.  Returns undefined if does not exist

* **Parameters**
  * `employeeId : UcEmployeeId!`
* **Returns**
  * `ErpUser`

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


<!--BREAK-->
### Data Object: ErpUserApprovalGroup

Association between a user account and an approval group in the Oracle application.

#### Access Controls

* Required Role: ``

#### Data Source

* Local Table/View: `undefined`

##### Properties

| Property Name      | Data Type                | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------ | :------------: | :-------------: | ------------- | ----- |
| approvalGroupName  | NonEmptyTrimmedString80! |                |        Y        |               | Name of the approval group in Oracle. |
| userId             | ErpUserId!               |                |        Y        |               | User ID used to identify the person in the ERP application.  Matches their UCD computing account. |
| user               | ErpUser!                 |                |                 |               | User object for the person in the ERP application. |
| active             | Boolean!                 |                |        Y        |               | Whether this user/role association is active. |
| lastUpdateDateTime | DateTime!                |                |        Y        |               |  |

* `user` : `ErpUser!`
  * User object for the person in the ERP application.
  * Description of `ErpUser`:
    * A user as known to the ERP application.

##### Linked Data Objects

(None)

#### Query Operations

##### `erpUserApprovalGroupByUserId`

> Get ErpUserApprovalGroups by user ID.  Only returns current and active records.

* **Parameters**
  * `userId : ErpUserId!`
* **Returns**
  * `[ErpUserApprovalGroup!]!`

##### `erpUserApprovalGroupByGroupName`

> Get ErpUserApprovalGroups by a group name.  Only returns current and active records.

* **Parameters**
  * `approvalGroupName : NonEmptyTrimmedString80!`
* **Returns**
  * `[ErpUserApprovalGroup!]!`

##### `erpUserApprovalGroupAll`

> Get all ErpUserApprovalGroups.  Only returns current and active records.

* **Parameters**
* **Returns**
  * `[ErpUserApprovalGroup!]!`

##### `erpUserApprovalGroupSearch`

> Search for ErpUserApprovalGroup objects by multiple properties.
> See
> See the ErpUserApprovalGroupFilterInput type for options.

* **Parameters**
  * `filter : ErpUserApprovalGroupFilterInput!`
* **Returns**
  * `ErpUserApprovalGroupSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpUserRole

Association between a user account and role in the Oracle application.

#### Access Controls

* Required Role: ``

#### Data Source

* Local Table/View: `undefined`

##### Properties

| Property Name      | Data Type                 | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | ------------------------- | :------------: | :-------------: | ------------- | ----- |
| id                 | Long!                     |                |                 |               | Internal identifier for the role membership. |
| userId             | ErpUserId!                |                |        Y        |               | User ID used to identify the person in the ERP application.  Matches their UCD computing account. |
| user               | ErpUser                   |                |                 |               | User object for the person in the ERP application. |
| roleCode           | NonEmptyTrimmedString100! |                |        Y        |               |  |
| roleName           | NonEmptyTrimmedString240! |                |        Y        |               |  |
| roleDescription    | String                    |                |                 |               |  |
| active             | Boolean!                  |                |        Y        |               | Whether this user/role association is active. |
| startDate          | LocalDate!                |                |                 |               | The date that the role membership is active from. |
| endDate            | LocalDate                 |                |                 |               | The date that the role membership ends. |
| userGuid           | String!                   |                |                 |               | Internal GUID used for linking user accounts to roles within the ERP system. |
| lastUpdateDateTime | DateTime!                 |                |        Y        |               |  |
| lastUpdateUserId   | ErpUserId                 |                |                 |               |  |

* `user` : `ErpUser`
  * User object for the person in the ERP application.
  * Description of `ErpUser`:
    * A user as known to the ERP application.

##### Linked Data Objects

(None)

#### Query Operations

##### `erpUserRoleDataAccess`

> Get a single ErpUserRoleDataAccess by ID.  Returns undefined if does not exist

* **Parameters**
  * `id : Long!`
* **Returns**
  * `ErpUserRoleDataAccess`

##### `erpUserRoleDataAccessByUserId`

> Get ErpUserRoleDataAccess records by user ID.  Only returns current and active user data security records.

* **Parameters**
  * `userId : ErpUserId!`
* **Returns**
  * `[ErpUserRoleDataAccess!]!`

##### `erpUserRoleDataAccessByUserIdAndRole`

> Get ErpUserRoleDataAccess records by user ID and role code or name.  Only returns current and active user data security records.

* **Parameters**
  * `userId : ErpUserId!`
  * `roleCodeOrName : NonEmptyTrimmedString100!`
* **Returns**
  * `[ErpUserRoleDataAccess!]!`

##### `erpUserRoleDataAccessSearch`

> Search for ErpUserRoleDataAccess objects by multiple properties.
> See
> See the ErpUserRoleDataAccessFilterInput type for options.

* **Parameters**
  * `filter : ErpUserRoleDataAccessFilterInput!`
* **Returns**
  * `ErpUserRoleDataAccessSearchResults!`

##### `erpUserRole`

> Get a single ErpUserRole by ID.  Returns undefined if does not exist

* **Parameters**
  * `id : Long!`
* **Returns**
  * `ErpUserRole`

##### `erpUserRoleByUserIdAndRole`

> Get ErpUserRoles by user ID and role code or name.  Only returns current and active user roles.  Returns undefined if one does not exist.

* **Parameters**
  * `userId : ErpUserId!`
  * `roleCodeOrName : NonEmptyTrimmedString100!`
* **Returns**
  * `ErpUserRole`

##### `erpUserRoleByUserId`

> Get ErpUserRoles by user ID.  Only returns current and active user roles.

* **Parameters**
  * `userId : ErpUserId!`
* **Returns**
  * `[ErpUserRole!]!`

##### `erpUserRoleSearch`

> Search for ErpUserRole objects by multiple properties.
> See
> See the ErpUserRoleFilterInput type for options.

* **Parameters**
  * `filter : ErpUserRoleFilterInput!`
* **Returns**
  * `ErpUserRoleSearchResults!`

##### `erpUserRoleRequestStatus`

> Get the status of a previously submitted ERP User Role request by the API-assigned request ID.

* **Parameters**
  * `requestId : UUID!`
* **Returns**
  * `ErpUserRoleRequestStatusOutput`

##### `erpUserRoleRequestStatusByConsumerTracking`

> Get the status of a previously submitted ERP User Role request by the consumer's unique tracking ID.

* **Parameters**
  * `consumerTrackingId : String!`
* **Returns**
  * `ErpUserRoleRequestStatusOutput`

##### `erpUserRoleRequestStatusByConsumerReference`

> Get the statuses of previously submitted ERP User Role requests by the consumer's reference ID.

* **Parameters**
  * `consumerReferenceId : String!`
* **Returns**
  * `[ErpUserRoleRequestStatusOutput!]!`

##### `erpUserRoleRequestStatusByBatchId`

> Get the list of ERP User Role requests which were processed via the given batch ID.

* **Parameters**
  * `batchId : UUID!`
* **Returns**
  * `[ErpUserRoleRequestStatusOutput!]!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.


<!--BREAK-->
### Data Object: ErpUserRoleDataAccess

A record which indicates the scope of access a role grants a specific user within the Oracle application.

#### Access Controls

* Required Role: ``

#### Data Source

* Local Table/View: `undefined`

##### Properties

| Property Name      | Data Type                  | Key Field [^2] | Searchable [^1] | Required Role | Notes |
| ------------------ | -------------------------- | :------------: | :-------------: | ------------- | ----- |
| id                 | Long!                      |                |                 |               | Internal identifier for the role membership. |
| userId             | ErpUserId!                 |                |        Y        |               | User ID used to identify the person in the ERP application.  Matches their UCD computing account. |
| user               | ErpUser                    |                |                 |               | User object for the person in the ERP application. |
| userRole           | ErpUserRole                |                |                 |               |  |
| roleCode           | NonEmptyTrimmedString100!  |                |        Y        |               | Role this data security value is associated with. |
| roleName           | NonEmptyTrimmedString240!  |                |        Y        |               | Role this data security value is associated with. |
| dataAccessType     | ErpUserRoleDataAccessType! |                |                 |               | The part of the application of this data security value applies to within Oracle. |
| dataAccessValue    | NonEmptyTrimmedString255!  |                |                 |               | The scope this record gives to the user within the context of the linked role. |
| userGuid           | String!                    |                |                 |               | Internal GUID used for linking user accounts to roles within the ERP system. |
| active             | Boolean!                   |                |        Y        |               | Whether this user/role association is active. |
| startDate          | LocalDate!                 |                |                 |               | The date that the role membership is active from. |
| endDate            | LocalDate                  |                |                 |               | The date that the role membership ends. |
| lastUpdateDateTime | DateTime!                  |                |        Y        |               |  |
| lastUpdateUserId   | ErpUserId                  |                |                 |               |  |

* `user` : `ErpUser`
  * User object for the person in the ERP application.
  * Description of `ErpUser`:
    * A user as known to the ERP application.
* `userRole` : `ErpUserRole`
  * Description of `ErpUserRole`:
    * Association between a user account and role in the Oracle application.

##### Linked Data Objects

(None)

#### Query Operations

##### `erpUserRoleDataAccess`

> Get a single ErpUserRoleDataAccess by ID.  Returns undefined if does not exist

* **Parameters**
  * `id : Long!`
* **Returns**
  * `ErpUserRoleDataAccess`

##### `erpUserRoleDataAccessByUserId`

> Get ErpUserRoleDataAccess records by user ID.  Only returns current and active user data security records.

* **Parameters**
  * `userId : ErpUserId!`
* **Returns**
  * `[ErpUserRoleDataAccess!]!`

##### `erpUserRoleDataAccessByUserIdAndRole`

> Get ErpUserRoleDataAccess records by user ID and role code or name.  Only returns current and active user data security records.

* **Parameters**
  * `userId : ErpUserId!`
  * `roleCodeOrName : NonEmptyTrimmedString100!`
* **Returns**
  * `[ErpUserRoleDataAccess!]!`

##### `erpUserRoleDataAccessSearch`

> Search for ErpUserRoleDataAccess objects by multiple properties.
> See
> See the ErpUserRoleDataAccessFilterInput type for options.

* **Parameters**
  * `filter : ErpUserRoleDataAccessFilterInput!`
* **Returns**
  * `ErpUserRoleDataAccessSearchResults!`

[^1]: Searchable attributes are available as part of the general search filter input.
[^2]: Key fields are considered unique identifiers for a data type and can be used to retrieve single records via dedicated operations.
