# Original Application Docs

## Non-Employee Traveler Maintenance

!> The below was extracted from the existing application.  It will roughly align with the current state of the application.  However, due to it's last update being in 2016, it may not be 100% representative of the current state of the application.  It is provided for historical and reference purposes.

Due to serious deficiencies in the usability of the Sponsored Guest feature of AggieTravel, we need to build a UI which will allow campus employees to sponsor non-employees as travelers and act within the travel system on their behalf to submit reports to reimbursement them or reconcile expenses UCD made on their behalf.

### Purpose

We want to provide the campus end users with a method of supplying information about non-employees for whom the University will reimburse travel expenses.  Since these payments will be going directly to these non-employees, the payment system must have their information provided to it by the AggieTravel extract process.

So, we must provide a user interface for campus-authenticated users who are eligible for receiving travel reimbursements themselves.  Within this interface they should be able to:

1. Sponsor a new non-employee
2. Review their list of previously sponsored non-employees
3. Update the information of a previously sponsored non-employee
4. Cancel their sponsorship of a non-employee

The data on the non-employees must be saved into local storage by the application.  On a nightly basis, this information will be used to create records in the employee import file formats.

In addition to gathering the needed information for payment (name, address), the UI must also provide the ability to enter a list of additional "delegates" (the sponsor is automatically considered one) who will be granted the ability to enter and submit reports on the non-employee's behalf.

Since departmental approval is a key control in the travel workflow, non-employees must have a department assigned.  This department will be the sponsor's department *at the time they are added or edited*.  This information will be stored in the non-employee's record.

The list of currently sponsored employees should provide the key information a sponsor needs to know about the non-employee.  This will include their sponsor date, last updated date, and sponsorship end date.  The end date will be set to one year from the original sponsorship date, but can be moved to a sooner date if desired.  It can not be made to extend for more than a year from the current date when adding or editing a non-employee's record.  Upon expiration of a non-employee's sponsorship, their record will be marked as inactive in AggieTravel.

Users may see and edit only their own sponsored non-employees.  Non-employee sponsorship may not be transferred.

### Technical Components

1. User Interface for end users
2. Data store for holding the non-employee traveler data
3. Additional Batch Job to extract changed data and upload to AggieTravel.

### Technologies

* Node.JS (server and API implementation)
* React / React Router / Redux (UI Logic)
* Semantic UI (UI Interface Components)
* MongoDB (Data Persistence)
    * Mongoose (object to database mapping)
* Passport (Authentication)

### Dependencies

* MongoDB Database (same as batch integration server)
    * To reduce Dependencies, this application will use the data previously loaded by the batch server into the Mongo database as it's source for employee information.

### UI Function Summary

1. Entry of new non-employee travelers
2. List previous non-employee travelers for the current user
3. Edit the information of a previously entered traveler
4. Inactivate a previously entered traveler

### Non-Employee Traveler Data Elements

| Field Name         | Data Type       | Concur Import Location       | Notes                      |
| :----------------- | :-------------- | :--------------------------- | :------------------------- |
| firstName          | String(32)      | First Name                   | Required                   |
| middleName         | String(32)      | Middle Name                  |                            |
| lastName           | String(32)      | Last Name                    | Required                   |
| employeeId         | String(48)      | Employee ID                  | N + sequence               |
| loginId            | String          | Login ID                     | <emp ID>.guest@ucdavis.edu |
| emailAddress       | String          | Email Address                |                            |
| divisionCode       | String          | Organizational Unit 1        | defaulted from sponsor     |
| departmentCode     | String          | Organizational Unit 2        | defaulted from sponsor     |
| subDepartmentCode  | String          | Organizational Unit 3        | defaulted from sponsor     |
| departmentName     | String          | N/A                          |                            |
| group              | String          | CUSTOM21                     | CAMPUS or UCDHS            |
| addressLine1       | String(40)      | CUSTOM5                      | Required                   |
| addressLine2       | String(40)      | CUSTOM6                      |                            |
| addressLine3       | String(40)      | CUSTOM7                      |                            |
| cityName           | String(40)      | CUSTOM8                      | Required                   |
| stateCode          | String(2)       | CUSTOM9                      | Required                   |
| postalCode         | String(11)      | CUSTOM10                     | Required                   |
| countryCode        | String(2)       | CUSTOM11                     | Required, Default US       |
| usCitizen          | boolean         | CUSTOM12                     | Default True               |
| sponsorEmployeeId  | String          | Expense Report Approver (59) |                            |
| createDate         | Date            | N/A                          | Calculated                 |
| lastUpdatedDate    | Date            | N/A                          | Calculated                 |
| sponsorshipEndDate | Date            | N/A                          | Calculated/Editable        |
| delegates          | Array[Delegate] | (550 record)                 |                            |
| lastExportDate     | Date            | N/A                          | Set by batch process       |

#### Delegate Info

Of the fields below, only employee ID is really required.  Having the other elements in the child document is for ease of display.

* employeeId
* name
* principalName
* principalId
* departmentName
* lastUpdatedDate
* active

### General Application information

#### Page Structure

Page should have a title: `AggieTravel Non-Employee Traveler Sponsorship`.

In the upper left below the title, the page should reflect the name of the currently logged-in user.  (Something like:)

    Hello, Jonathan
    ACCOUNTING & FINANCIAL SERVICES (062005)

Remaining content would be below this point.

#### Access and Authentication

This application will be linked to from within the AggieTravel system or the A&FS Web Site.  As such, there is no need for this application to be available to anyone who is not already authenticated as a campus user.  The authentication filter can and should be in place for all endpoints of the application.

However, the first check the application should make (and then store in the session), is whether the person is eligible for upload into AggieTravel.  That can be done by checking the `concurEmployee` collection used by the integration server on MongoDB.  If not eligible, then redirect the user to a page explaining the issue.  (text below)

All API endpoints within the application should be confirming that the user has the right to do what they have asked.

### List Screen

This is the main screen listing all the active non-employees the user has sponsored.  This list should never be too large, so there is no need for paging logic and controls.  When the user has no sponsored employees, replace the table section with an informational block noting the use of the application.

This screen also will contain a banner at the top informing the user of actions just taken.  (E.g., user added/edited/inactivated).

Clicking on the edit or an update link will take the user to a new screen with the form.

#### Proposed Layout

```text
|:-------------------------------------------------|
| pop-in Banner informing users of actions taken |
| ---------------------------------------------- |
<Create New Non-Employee Traveller button>
|:-------------------------------------------------|
| List of active non-employees in table            |
| ------------------------------------------------ |
| name would be link to edit                       |
| ------------------------------------------------ |
| inactivate link at end of row                    |
| ------------------------------------------------ |
|                                                  |
| ------------------------------------------------ |
```

#### Columns

* name (link to edit)
* employeeId
* departmentName
* sponsorDate
* lastUpdatedDate
* sponsorshipEndDate (bold red if within 30 days of expiring)
* (inactivate button - include confirmation)

(How easy would it be to display more detailed information (such as address and delegate info) upon overing over a record?  http://semantic-ui.com/modules/popup.html ?)

#### Create/Edit Page

#### Proposed Layout

Surprise Me!

#### Field Specs / Rules

**Note:** Semantic UI contains some default form behavior capabilities.  See: http://semantic-ui.com/behaviors/form.html

### Block Texts

#### User Is not an Travel User

**TODO**

#### User Has No Sponsored Non-Employees

**TODO**


## More Technical Requirements

### Backing Database Notes

This application will use MongoDB as the back-end database for storing the non-employee information.  Field names don't explicitly matter except that they should logically map to the UI names for ease of tracing by future developers.  It will use the same database as the integration server with its information in a new `nonEmployee` collection.

### New Batch Job

A new batch job which creates the same types of data as the other employe ejobs will need to be created.  It will pull from this new collection.  Records should be pulled if the `lastUpdateDate` or `sponsorshipEndDate` on the record is greater than the `lastExtractDate`.  (Or if the `lastExtractDate` is not set and the `sponsorshipEndDate` is still in the future.)

Even then, we only want to upload if changes were actually made to fields we include in the file.  Review the table earlier in this document for more information.  Likewise, we only want to send up delegate records for those changed.

* 305 record
* 550 record for delegates

**TODO: Spec out constant fields on record types.**

* Profile as reimbursement method
* In the case of a delegate being inactivated, we issue a 550 record with all the delegation flags set to "N".  There is no way to explicitly delete a delegation record.


## Deployment Issues


### Concur-Side

* A user who can edit the links on the main page will need to add a link to this application from within Concur.
* A link should probably also be made on the main AggieTravel web site on the A&FS web site somewhere near the link to get into AggieTravel.

### Application Server

**TODO**

### Database Connections

**TODO**

## Notes

How to deploy.
  Main port 3000
  needs fronting HTTPS web server
  REST API to perform updates
  Can we put the passport filter on the api calls? - YES - confirmed using ensureLoggedIn() module.
  API calls need to confirm identity.
    API calls need to use the person's ID from their session.

Passport and passport-cas

Initial screen with a list of non employees the user sponsors and the "sponsor a guest traveler" button.  No filters needed, but table can be sortable.  Default to sorting by last name.  No paging on table.  Only show active records.

Inform user that updates take overnight in confirmation messages.

Use the integration server employee and department data.

How to generate a sequence in Mongo?
    https://docs.mongodb.org/manual/tutorial/create-an-auto-incrementing-field/

Document needed settings for roles and delegate abilities.

Include help text to show as completing each field.
```
<div class="inline field">
    <input type="text" placeholder="Username">
    <div class="ui left pointing label">
      That name is taken!
    </div>
  </div>
```

