# 3.2.5.1 GL Journal File Submission

### Gl Journal File Submissions

#### Differences from API

As noted in the file submission summary, not all features provided by the API are supported when uploading files.  Certain automatic functions and data cleansing are not available.  As such, it is more likely that, without local data cleanup and additional effort, a file could be submitted that will be rejected during the integration process.  Below is a list of the items which the pipeline will **NOT** perform that the GraphQL API would perform.

1. Setting of the `consumerId` in the header.  It must be in the file and match the Consumer ID in the filename.
2. Creation of `glSegments` from `glSegmentString` and `ppmSegments` from `ppmSegmentString`.
3. Verification that the `header.consumerTrackingId` is unique through your Consumer ID.
4. Comprehensive GL / PPM Segment Validation.  (Most validation is still performed, but not all.)
5. Comprehensive Oracle GL CVR rule checks.  (The API implements most CVR rules.  File validation only includes the most common violations.)

#### Mitigations

For each of the above, the sender is responsible for performing the necessary validations or including the needed data before sending the file.  Notes on the above are given below as deemed necessary.

##### Segment String Parsing

On the API, you have the option of providing either the `glSegmentString` or the `glSegments` object.  The file transfer format only allows the use of the `glSegments` object.  You must populate that object will all segments that you are using.  (Any missing ones will be replaced by zeroes during submission to Oracle.)

##### GL / PPM Segment and CVR Validation

The validations performed on the GL and PPM segments will be much more limited (and any errors less specific) than those validations provided by the API.  You will have a greater likelihood of failing Oracle's validation unless you utilize the `glValidateChartSegments` and `ppmSegmentsValidate` operations on each combination before sending through the file.
