# ERP API Overview

### Principles

For campus boundary systems, we have taken an API-first approach.  Except as needed due to volume or 3rd party vendor limitations, we require all systems on campus to retrieve and send data to Oracle Financials via API calls.

The model for submitting data updates to Oracle is somewhat different from existing data update APIs.  Data updates into Oracle and any other destination system we support will be handled asynchronously.  With a SaaS-based ERP system, we have less control over the availability of the system, and there are more network dependencies.  An asynchronous queue-based system eliminates the coordination of uptime between sending system and receiving system and provides natural support for preventing overload of any portion of the process.

There is a single API endpoint that serves all API data and action requests for systems managed by AdminIT.  The API can query data (in the same request) across all supported systems.  The data types containing internal links that allow for related data from one system to be enriched by the others.

The data and action request model will be reviewed and governed to ensure standard naming of elements to maintain usability and support detailed data and access management of the data model, with technical and functional governance over each.

Below are the primary components of the integration framework, each described in a section below:

1. GraphQL Data Request API
2. Asynchronous Action Request API
3. Roles/Permission UI and API
4. API Gateway Portal
5. Structured File Uploads

### 1. GraphQL Data Request API

The federated GraphQL data graph API enables retrieval of data crossing multiple data sources managed by or heavily utilized by Admin IT.  This provides a standarized, stable manner in which to retrieve data both individually, and in bulk, using a well known data transfer format.

GraphQL is a operation and data model schema specification that uses JSON as the underlying data structure and runs on top of standard HTTP POST operations used by modern APIs.  While the most benefit to consumers can be gained when using a GraphQL client library (these exist for for most programming languages), one is not necessary to use the API.  Any application capable of posting JSON-over-HTTP (as are most REST APIs) would be able to adapt to submit requests via GraphQL with little difficulty.

#### Cross-Domain Data Retrieval

One benefit of GraphQL requests is that each submission to the server may contain multiple queries, with all results then returned in a single response.  Due to the data federation tools setup, a single API call can request data from multiple sources (e.g., UCPath and Oracle Financials) if a relationship between data types has been established by the schema developers.

#### Object and Property Level Authorization

Apollo Server allows for fine-grained access controls within GraphQL data types and operations.  Through that configuration, we can assign roles to data types, specific operations, and individual fields of types.  This last part eliminates the need to create different operations or versions of data types with and without sensitive data fields.  All fields, regardless of security level, may exist on the single version of an object.  In GraphQL, each field of a response must be explicitly identified.  And each field goes through a security check to see if the user's role is able to see that field.  Even so, an authorization failure does not result in a failure of the API result to be returned to the consumer.  The disallowed fields are nulled out, and the remainder of the data is returned, along with error information informing the consumer of the redaction.

The security roles applied by the API implementation are managed within Grouper.  Each consumer's roles is requested from there at the time of the request.

![](Integration%20C4%20Model-Data%20Request%20API%20Flow.drawio.png)

### 2. Asynchronous Action Request API

Requests which require data to be processed by a destination system are processed asynchronously from the consumer's API call.  The call is assigned a unique ID immediately that they can use to track the results later.  The interaction with the destination system (usually Oracle Financials) to process the request is queued up and performed by the integration platform as it has capacity.

![](Integration%20Platform-GraphQL%20API%20Call%20Flow.drawio.png)

![](Update%20Request.svg)

Each request is stored to a main control table. Every action request operation performs validation on the provided payload, so that we can provide immediate feedback if it can identify that the payload will fail later processing.  The response contains tracking information which the consumer can then use to check on and retrieve the results of their request.

### 3. Roles/Permission UI and API

Access controls for operations and data elements are stored and managed within the Grouper roles management system.  Groups in grouper are linked to role IDs within the API servers.  Those roles are then granted access to operations or data types within the GraphQL server code base.  Within grouper, API consumer IDs are assigned as members of the groups.

Management of those groups is handled by authorized staff in Operations.

Grouper provides a REST API to obtain group information.  The API servers call this API to obtain the roles granted at the moment of the request.  Some caching is performed to maintain system performance.

### 4. API Gateway Portal

This is an HTTP gateway server through which all requests from boundary systems are passed, authenticated, and authorized.  It provides a portal for API consumers with documentation of all operations and data types we APIs we expose through the GraphQL Gateway.  It provides some functions of a web application firewall, detecting and rejecting fradulent requests in order to protect the API servers.

#### Authentication

The API gateway authenticates consumers via a client secret and key pair.  Both are opaque strings known only to the API Gateway.  The consumer's validated identity is encoded into a JWT authentication token that is passed on to the GraphQL Gateway server.

#### Authorization

The API Gateway could perform API-group or individual operation authorization as needed.  This is coarse-grained authorization, intended to keep clients who have no access to an upstream API or operation from communicating with the server.  We are not presently using this potential feature, allowing the GraphQL Gateway and the upstream GraphQL Data Servers to handle the authorization.

#### Developer Portal

The gateway is GraphQL-award and provides a portal for integration developers to discover and test available operations.

### 5. Structured File Uploads

API Integration is the preferred method for all integrations.  It provides immediate feedback in the case of malformed files or incorrect data.  However, we still support a path for file-based data uploads in the following exception cases:

1. Units that can demonstrate they would be unable to update their systems (usually a contracted vendor's system) to utilize a GraphQL API for data updates.
2. The data volume is such that providing it via API could be problematic for server resources.

The latter of the above should be rare, as size of uploads could be mitigated by sending units of work to Oracle more frequently.

For files, validation feedback is sent by email to the address provided on their configuration records.

Data sent via file uploads is not batched for processing.  That is, intake processes regularly monitor the upload locations and process the files as soon as resources are available.

#### Upload Data Formats

As with the API, the data structure format is JSON.  The schema is the same as that used for the API payload for the same data type.

The header data sent may be slightly different to account for the different timing semantics of API vs. file submission.  However, the business data content should be identical.

#### File Upload Implementation

The campus GoAnywhere (GoA) server is used as the interface point for boundary systems uploading files for processing into Oracle.  It is a staging area only.  Projects on GoA upload the files to Amazon S3, within the bucket used by the integration platform, for secure storage and later processing.
