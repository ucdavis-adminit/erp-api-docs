# 3.2.5.1 GL Journal File Submission

### Differences from API

As noted in the file submission summary, not all features provided by the API are supported when uploading files.  Certain automatic functions and data cleansing are not available.  As such, it is more likely that, without local data cleanup and additional effort, a file could be submitted that will be rejected during the integration process.  Below is a list of the items which the pipeline will **NOT** perform that the GraphQL API would perform.

1. Setting of the `consumerId` in the header.  It must be in the file _and match the Consumer ID in the filename_.
2. Creation of `glSegments` from `glSegmentString` and `ppmSegments` from `ppmSegmentString`.
3. Verification that the `header.consumerTrackingId` is unique through your Consumer ID.
4. Oracle GL CVR rule checks.  (The API implements most CVR rules.  File validation omits validations unlikely to affect boundary systems.)

### Mitigations

For each of the above, the sender is responsible for performing the necessary validations or including the needed data before sending the file.  Notes on the above are given below as deemed necessary.

#### Segment String Parsing

On the API, you have the option of providing either the `glSegmentString` or the `glSegments` object.  The file transfer format only allows the use of the `glSegments` object.  You must populate that object will all segments that you are using.  (Any missing ones will be replaced by zeroes during submission to Oracle.)  The same is true for the `ppmSegments` object.

#### GL / PPM Segment and CVR Validation

The validations performed on the GL and PPM segments are more limited than those validations provided by the API.  You will have a greater likelihood of failing Oracle's validation unless you utilize the `glValidateChartSegments` and `ppmSegmentsValidate` operations on each combination before sending through the file.

### File Size Limitations

To maintain the effiency of the integration platform, some limits have been placed on the size of files that can be uploaded.  The limits are based on the design of the system which has been optimized for the smaller payloads common to API usage.

* glJournal Input file size limit: `20 MB`
* Approximate number of lines: `20,000` - `50,000`
  * The actual number of lines will vary by the fields in use on each line and the length of data present in each field on each one.
  * It also will vary greatly by the formatting of the JSON in the file.  It is highly recommended that you remove any whitespace added to the file for readability purposes before uploading.  (In general the removal of indentation of the file will allow you to fit at least `30,000` lines in the file size limit.)
