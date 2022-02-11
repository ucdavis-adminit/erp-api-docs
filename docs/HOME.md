# ERP API Overview


Oracle ERP integrations are being designed around delivering an API-first approach.  APIs will be available for all outbound and inbound data the project team has defined as a requirement for this project.  It is designed to support the needs for data integrations only.  Access to data to be used for reporting is not in the scope for these APIs.

The model for submitting data updates to Oracle is different from existing data update APIs.  The integration platform implements a model of asynchronous operations when interaction with the Oracle system is required.  This may require more work on the part of each consumer, and require a change in how data flows are managed within boundary systems.  This is being done in part due to Oracle Financials being a SaaS-based ERP system.  We have less control over the end-to-end connections (both in systems and networks) than we have with KFS.  We also must contend with potential downtimes of Oracle or integration components.  Moving to an asynchronous queue-based system eliminates these compound dependencies and potential performance bottlenecks.  And, it relieves boundary systems from having to be aware of, or schedule around, most components of integrations.  This also allows for requests to be retried (independent of the boundary system) until completion in the case of service downtimes.

Because the API is based on GraphQL, there will be a single API endpoint to serve all API data and action requests for systems managed by AdminIT.  Users of the API will be able to query data (in the same request) across all supported systems (presently Oracle Financials and UCPath), with defined internal links that will allow for data from one system to be enriched by data from the others.

Below are the primary components of the integration framework, each described in a section below:

1. GraphQL Data Request API
2. Asynchronous Action Request API
3. API Gateway Portal
4. Structured File Uploads

### 1. GraphQL Data Request API

A federated GraphQL data graph API which enables retrieval of data across multiple data sources managed or accessed by Admin IT.  This provides a standarized, stable manner in which to retrieve data both individually and in bulk utilizing a well known data transfer format.

GraphQL is a operation and data model specification using JSON as the underlying data structure format and runs on top of the standard HTTP POST operation used by many APIs today.  While the most benefit can be gained by using a GraphQL client library (which exist for for most programming languages), one is not necessary to use the API.  Any application capable of posting JSON-over-HTTP to an API endpoint would be able to adapt to query via GraphQL with little difficulty.

#### Cross-Domain Data Retrieval

One benefit of GraphQL requests is that each may contain multiple queries, with all results being returned in a single HTTP response.  And, due to the data federation tools used, a single request can contain data from multiple sources (e.g., Oracle Financials and UCPath) if the relationship has been established in the data graph.  (For Example, anywhere an employee ID appears in the Oracle data model, we could have a reference to the Employee object in UCPath to allow retrieval of more information about the person than Oracle can return.)

#### Object and Property Level Authorization

The structure of GraphQL requests allows for fine-grained access controls.  Through this, we are able to assign security roles to whole domains of data, specific operations, data objects, and individual properties of objects.  This allows the data model design to contain different versions of data objects with and without sensitive data properties.  All properties may exist on a single version of an object.  In GraphQL, each property of an object must be explicitly requested.  Security on sensitive properties is only applied _if_ those specific properties are requested by the consumer.  Such a authorization failure does not result in a failure of results to return.  The offending objects are blanked out, and the remainder of the data is returned, along with error information informing the consumer of the redaction.

### 2. Asynchronous Action Request API

Requests which require Oracle to take an action will be made asynchronously with request to the consumer's API call.  The call will be handled as a _request_ to perform the action.  The interaction with the ERP system to perform the action will be handled by the integration platform at a later time.  (Though most often within seconds.)  If preliminary validation by the API passes, the consumer will be returned a unique ID to allow for checks on the completion of the request at a later point in time.

#### Action Requests

Each _request_ will be pushed into a queue. (Depending on the API, there may be some validation performed which would result in an immediate response.)  The API will return tracking information about the request with a request identifier and an GraphQL payload (another API operation) which the consumer can then use to check on and retrieve the results of their request.

#### Result Polling

Clients have two options to get the results of their request.  The provided operation may be invoked to obtain the results or the present status (if incomplete).

#### Result Callbacks (future development)

Another option which may be available pending completion of other work would be to have the integration platform perform a callback to the consumer's server.  If this is an option for a boundary system, a callback URL may be provided in the request.  And, if present, when the request is complete the response will be placed in a queue for posting the data back to the client.  The URL must be an HTTPS URL with a trusted certificate to a white-listed domain.  The platform will attempt some retries of the callback if there is a problem connecting to the consumer system.  However, any consumer who chooses this option should have a fallback to use the results URL provided for any callbacks not received.

### 3. API Gateway Portal

We plan to offer a HTTP gateway server through which all requests will be proxied and authenticated.  It would also provide a portal for API consumers with documentation of all exposed APIs, whether for this API or others within Admin IT.  It also acts as a web application firewall, detecting and rejecting fradulent requests in order to protect the API servers.

#### Authentication

The API gateway supports multiple methods of authenticating consumers of API services and provides self-service setup of application-level authentication tokens.

We will be able to support multiple models of authentication depending on the needs and capabilities of the consumer as well as the sensitivity of the data the consumer will be able to access or modify.  (E.g., OAuth, static access tokens, etc...)

#### Developer Portal

We also want this to be a portal to allow for integration developers to be able to discover available endpoints, test calls against non-prod instances, and manage their own authentication keys for their boundary applications.  Our selected software provides for a self-signup approach, with workflows to request access to needed APIs.

### 4. Secure File Uploads

API integrations are the preferred method.  It provides more immediate feedback in the case of malformed files or data which is invalid in trivial ways.  However, we will still support a path for file-based data uploads in the following exception cases:

1. Units that can demonstrate they would be unable to update their systems to utilize a web service API for data updates.
2. The data is of such volume that providing it via API could be problematic for server resources.

The latter of the above should be rare, as size of uploads could be mitigated by sending batches of transactions more frequently.

It should also be noted that there is no database or reference data export for supporting the validation of data to be submitted to these files.  Boundary systems will still need to be able to call API endpoints to obtain valid values or run validations on segment values provided by customers.

Responses on uploaded files will be less timely than API calls, where more validation can be performed before accepting the data.  Results of file uploads (success or failure) will only be provided by email.  Though, as much as possible, we will indicate the reason for the failure so you can perform manual resolution of issues and resubmit the file.

That said, it is not required to batch data to be uploaded.  Processes will be regularly monitoring the upload locations and will process the files as soon as resources are available.

#### Upload Data Formats

As with the API, the data structure format will be JSON.  The schema will be the same as that used for the API payload for the same data type though there will likely be additional requirements for uploaded files.

The header data sent may be slightly different to account for the different timing semantics of API vs. file submission.  However, the business data content should be identical.

