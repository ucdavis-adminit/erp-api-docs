# 3.2.5.1 GL Journal File Submission

### Gl Journal File Submissions

#### Differences from API

As noted in the file submission summary, not all features provided by the API are supported when uploading files.  Certain automatic functions and data cleansing are not available.  As such, it is more likely that, without local data cleanup and additional effort, a file could be submitted that will be rejected during the integration process.  Below is a list of the items which the API will perform automatically that must be included in or true of the submitted file.

1. Creation of `glSegments` from `glChartString`
2. Defaulting of the `payload.accountingDate` to today's date
3. Verification that the `header.consumerTrackingId` is unique  (Failure to use a unique ID here could result in a silent failure of transaction lines with `ppmSegments` within Oracle.)
4. Automatic derivation of the award and funding source on `ppmSegments`
5. Automatic inclusion of PPM offset transactions
6. GL / PPM Segment Validation
7. Oracle GL CVR rule checks

#### Mitigations

For each of the above, the sender is responsible for performing the necessary validations or including the needed data before sending the file.  Notes on the above are given below as deemed necessary.

##### GL Chart String Segment Parsing

On the API, you have the option of providing either the `glChartString` or the `glSegments` object.  The file transfer format only allows the use of the `glSegments` object.  You must populate that object will all segments that you are using.  (Any missing ones will be replaced by zeroes during submission to Oracle.)

##### Derivation of Award and Funding Source

On sponsored projects, these fields are required.  Within your application, you will need to check the project via the `ppmProject` family of operations.  If the `sponsoredProject` is true, then use the `defaultAwardNumber` and `defaultFundingSource` properties to fill in those values in the `ppmSegments` object before sending.

##### GL / PPM Segment Validation

The validations performed on the GL and PPM segments will be much more limited (and any errors less specific) than those validations provided by the API.  You will have a greater likelihood of failing Oracle's validation unless you utilize the `glChartSegmentsValidate` and `ppmSegmentsValidate` operations on each combination before sending through the file.

##### Generation of PPM Offset Transactions

**TODO - Still determining if we _could_ somehow do this during integration flow.**

* For each PPM entry, generate a GL entry with the opposite sign and a given `glSegments`.  This should net the entries in your file with `glSegments` to zero.
