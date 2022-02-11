# 3.2.1 Data Objects


All data objects must have at least 2 operations:

* `get` : get a single data object by a unique identifier
* `search` : general purpose, multi-property search
<!-- * `searchCount` : as above, but only returns the number of matching results -->

The first always takes the complete set of primary key fields for the data object and returns 0 or 1 objects.

The second takes a filter input type specific to the data object and returns an array of 0 or more of that objects data types.

They may also include standardized optional operations:

* `xxxxxxAll` : get all currently valid instances of this data object
* `xxxxxxChildren` : for data with hierarchies, get all currently valid child instances

### `get` Query

The get query should be the name of the data object starting with a lower case letter.  E.g., for the `Department` data object, this query definition would look like:

```gql
  "Returns a single record based on its primary key"
  department(setId: String!, departmentCode: String!): Department
```

* All primary key fields must be required.
* The return value must not be, as this method could return a null result if the record does not exist.

### `search` Query

The search query is the general purpose lookup for this data object.  Its name is the name of the data object (again starting with lower case), and followed by the term `Search`.  The only parameter is a filter object.

#### Common Search Data Types

These are two common data types to be used on the input and output of all search queries.  They provide standard properties which clients can provide to control the results of the search.  If any function on the common inputs can not be supported by a given search operation, it must be clearly documented in the operation's description.

* `sort` (optional): Array of property name strings by which to sort the results.  If not provided, a default sort will be applied.
* `limit` (optional): The maximum number of records to return.  Defaults to a server-configured value.
* `startIndex` (optional): Zero-based record to start with.  Allows for paging results.
* `includeTotalResultCount` : If present and true will trigger the server to perform a count of all matching records.  As this may increase the return time of the search, it is disabled by default.  It is present to be turned on in cases where the calling application (perhaps for UI display) needs to know the total number of records which could be returned at time of downloading the first page of results.

```gql
  """
  Special properties common to all common search operations.
  """
  input SearchCommonInputs {
    "Array of property names to sort on"
    sort: [String!],
    "maximum number of records to retrieve"
    limit: PositiveInt,
    "Record number to start with"
    startIndex: NonNegativeInt
    "Whether to include a count of all records to be returned by this search.  Will increase search time."
    includeTotalResultCount: Boolean
  }

  """
  Metadata about the search results returned in a given response.
  Used to provide metrics of the results and the information necessary
  to pull in the next set of records.
  """
  type SearchResultMetadata {
    "Array of property names used to sort the results"
    sort: [String!],
    "requested limit to the number of records to retrieve"
    limit: PositiveInt,
    "Results returned in the data property."
    returnedResultCount: NonNegativeInt!
    "Starting index for the current result set."
    startIndex: NonNegativeInt!
    "Start index for getting the next page of results.  Unset if there are no more results."
    nextStartIndex: NonNegativeInt
    "Total number of results.  Will only be populated if `includeTotalResultCount` is true in the search request."
    totalResultCount: NonNegativeInt
  }
```

#### Search Filter and Results Patterns

Every `FilterInput` and `SearchResults` object on a common search function must implement with the following patterns.  Use of these for custom searches is optional, but highly encouraged for overall API consistency.

The `FilterInput` object must look like the following, with an optional `searchCommon` property of the `SearchCommonInputs` seen above.  Other properties in this object should match the property names on the data object.  Properties which do not match the base object may be added for special purposes, but must have documentation as to how they are applied to the search.

```gql
  type XxxxxxxxxFilterInput {
    searchCommon:   SearchCommonInputs

    propertyName:   StringFilterInput
    propertyName2:  StringFilterInput
    boolProp:       BooleanFilterInput
  }
```

The `SearchResults` object is a wrapper object for the results which contains `metadata` about the results and a `data` array containing the list of matching records.  Every `SearchResults` object must have the following properties.

```gql
type XxxxxxxxxSearchResults {
  "Information about the search results returned."
  metadata: SearchResultMetadata!
  "Results of the search"
  data: [Xxxxxxxxx!]!
}
```

#### Example: ErpFinancialDepartment Search

Below is how the search input, output, and operation could look for the ErpFinancialDepartment object.

```gql
  type ErpFinancialDepartmentFilterInput {
    searchCommon:   SearchCommonInputs

    code:           StringFilterInput
    name:           StringFilterInput
    enabled:        BooleanFilterInput
  }

  type ErpFinancialDepartmentSearchResults {
    metadata: SearchResultMetadata!
    "Results of the search"
    data:     [ErpFinancialDepartment!]!
  }

  type Query {
  "Search for records based on a set of filters."
  erpFinancialDepartmentSearch(
    "Criteria to apply to the search"
    filter: ErpFinancialDepartmentFilterInput!) : ErpFinancialDepartmentSearchResults!
  }
```

### `xxxxxxAll` Query

The optional getAll query should be the name of the data object starting with a lower case letter followed by `All`.  E.g., for the `Department` data object, this query definition would look like:

```gql
  "Get all currently valid departments"
  departmentAll(sort: [String!]): [Department!]!
```

* The `sort` input is optional.  Array of property name strings by which to sort the results.  If not provided, a default sort will be applied.
* The return value must always return an array.
* It should return all currently valid (i.e., Active, Not Expired) records for the object type.  If a consumer wants to get inactive values, they can use the search method above.
* This should not be added to any data object whose number of active records over the lifetime of the system could exceed `1,000`.  There is no facility to limit or page results as part of this API to keep processing the response simple for consumers.

### `xxxxxxChildren` Query

The optional getChildren query should be the name of the data object starting with a lower case letter followed by `Children`.  E.g., for the `Department` data object, this query definition would look like:

```gql
  """
  Get items under the given ${this.mainDataObjectName} in the hierarchy.
  Returns undefined if the parent does not exist.
  Returns an empty list if the given record has no children.
  """
  departmentChildren(code: String!): [Department!]
```

* The `sort` input is optional.  Array of property name strings by which to sort the results.  If not provided, a default sort will be applied.
* The `immediateOnly` input is optional.  It should default to a true value.  When true, the results should only include records which have the given code as their direct parent.  Otherwise, it should recurse to include all records under the given code in the hierarchy.
  * Inclusion of this as a parameter is optional in cases where execution of a hierarchical query can not be performed efficiently.
* It should return all currently valid (i.e., Active, Not Expired) child records for the object type.  If a consumer wants to get inactive values, they can use the search method above.
* If no valid record exists for the given code, the method should return undefined.
* If no valid children exist for a given code, the method should return an empty list.
* This should not be added to any data object whose number of active records over the lifetime of the system could exceed `1,000`.  There is no facility to limit or page results as part of this API to keep processing the response simple for consumers.

### Other Queries

Other queries may be added as relevant for special use cases not covered by the generic filter or for convenience for common use cases.  (E.g., we could have a `departmentByDivision(divisionCode:String!) : [Department!]` operation.)

All queries for a data object **_MUST_** start with the data object name to ensure that there is no confusion or potential name collision between operations hosted on different data servers.


### Common Input Structures

#### Search Inputs

Per the above, for each data object's generic search, a GraphQL `input` type will need to be created.  This object will contain many of the same properties as the data object (with the same name).  Not all properties on the data object must to be present if it does not make sense to (or would cause problems to) include them as search criteria.  (for complexity or performance reasons)

However, the type of these properties should be of one of the `FilterInput` types below, with common attributes for performing the standard types of comparisons needed during lookups.  (In v1, there is no support for "or"-type filtering.)

It is the responsibility of any backing datasource to be able to implement these filters.  This can be done as needed by a combination of use of the back-end datasource's (e.g., Oracle) capabilities and additional filtering logic in the server's datasource class.

At the time of writing, the common filter input data types were defined as:

* `StringInputFilter`
* `IntInputFilter`
* `FloatInputFilter`
* `BooleanInputFilter`
* `DateInputFilter`

```gql
"Generic string filter criteria object, only one of these properties should be set"
input StringFilterInput {
  "Test if property is equal to the given value"
  eq: String
  "Test if property is NOT equal to the given value"
  ne: String
  "Test if property is less than or equal to the given value"
  le: String
  "Test if property is less than the given value"
  lt: String
  "Test if property is greater than or equal to the given value"
  ge: String
  "Test if property is greater than the given value"
  gt: String
  "Test if property begins with the given value"
  beginsWith: String
  "Test if property ends with the given value"
  endsWith: String
  "Test if property contains the given value"
  contains: String
  "Test if property does not contain the given value"
  notContains: String
  "Test if property is between the first 2 elements in the array"
  between: [String!]
  "Test if property is equal to one of the given values"
  in: [String]
}

"Generic integer filter criteria object, only one of these properties should be set"
input IntFilterInput {
  "Test if property is equal to the given value"
  eq: Int
  "Test if property is NOT equal to the given value"
  ne: Int
  "Test if property is less than or equal to the given value"
  le: Int
  "Test if property is less than the given value"
  lt: Int
  "Test if property is greater than or equal to the given value"
  ge: Int
  "Test if property is greater than the given value"
  gt: Int
  "Test if property is between the first 2 elements in the array"
  between: [Int!]
  "Test if property is equal to one of the given values"
  in: [Int]
}

"Generic decimal number filter criteria object, only one of these properties should be set"
input FloatFilterInput {
  "Test if property is equal to the given value"
  eq: Float
  "Test if property is NOT equal to the given value"
  ne: Float
  "Test if property is less than or equal to the given value"
  le: Float
  "Test if property is less than the given value"
  lt: Float
  "Test if property is greater than or equal to the given value"
  ge: Float
  "Test if property is greater than the given value"
  gt: Float
  "Test if property is between the first 2 elements in the array"
  between: [Float!]
  "Test if property is equal to one of the given values"
  in: [Float]
}

"Generic date filter criteria object, only one of these properties should be set"
input DateFilterInput {
  "Test if property is equal to the given value"
  eq: LocalDate
  "Test if property is NOT equal to the given value"
  ne: LocalDate
  "Test if property is less than or equal to the given value"
  le: LocalDate
  "Test if property is less than the given value"
  lt: LocalDate
  "Test if property is greater than or equal to the given value"
  ge: LocalDate
  "Test if property is greater than the given value"
  gt: LocalDate
  "Test if property is between the first 2 elements in the array"
  between: [LocalDate!]
}

input BooleanFilterInput {
  "Test if property is equal to the given value"
  eq: Boolean
  "Test if property is NOT equal to the given value"
  ne: Boolean
}
```
