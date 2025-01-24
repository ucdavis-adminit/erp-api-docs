/** ExecuteGroovyScript processor to convert TouchNet transaction records to GL/PPM flattened format
 *  Name: GL/PPM Flattened Format Conversion
 *  Attibutes:
 *  - offsetGlChartString: #{offset_gl_chart_string}
 *  Input: Partitioned TouchNet transactions as JSON array of objects
 *  Input Attributes:
 *  - glChartString
 *  - consumerId
 *  - boundaryApplicationName
 *  - consumerReferenceId
 *  - requestSourceType
 *  - requestSourceId
 *  - journalName
 *  - journalReference
 *  - journalSourceName
 *  - journalCategoryName
 *  - externalSystemIdentifier
 *  Relationships:
 *  - Success: GL/PPM flattened JSON format
 *  - Failure: original flowfile with error attributes
 */

import groovy.json.JsonBuilder
import groovy.json.JsonSlurper
import org.apache.nifi.flowfile.attributes.CoreAttributes
import java.time.LocalDateTime

class TouchnetGlEntry {
    // Request Headers
    String consumerId, boundaryApplicationName, consumerReferenceId, consumerTrackingId, requestSourceType, requestSourceId
    // Journal Headers
    String journalSourceName, journalCategoryName, journalName, journalReference
    // Line Fields
    BigDecimal debitAmount, creditAmount
    String externalSystemIdentifier
    // GL Segments
    String lineType = "glSegments"
    String entity = "0000"
    String fund = "00000"
    String department = "0000000"
    String account = "000000"
    String purpose = "00"
    String program = "000"
    String glProject = "0000000000"
    String activity = "000000"
    String interEntity = "0000"
    String flex1 = "000000"
    String flex2 = "000000"
    TouchnetGlEntry(String glChartString) {
        (entity, fund, department, account, purpose, program, glProject, activity, interEntity, flex1, flex2) = glChartString.split("-")
    }
}
def headers = [
        'consumerId', 'boundaryApplicationName', 'consumerReferenceId',
        'requestSourceType', 'requestSourceId', 'journalName', 'journalReference',
        'journalSourceName', 'journalCategoryName', 'externalSystemIdentifier',
]
def processorName = context.name
def flowFile = session.get()
if (!flowFile) return
def flowFileId = flowFile.getAttribute(CoreAttributes.UUID.key())

JsonBuilder json
def failure = false
def input = new JsonSlurper().parse(flowFile.read())
if (input?.size() == 0) return
def output = []
try {
    input.each {
        def glEntry = new TouchnetGlEntry(flowFile['glChartString'])
        def offsetGlEntry = new TouchnetGlEntry(offsetGlChartString.value)
        headers.each {
            glEntry[it] = flowFile[it]
            offsetGlEntry[it] = flowFile[it]
        }
        glEntry.consumerTrackingId = "original:${it['record_digest']}"
        offsetGlEntry.consumerTrackingId = "offset:${it['record_digest']}"
        if (it['trans_type'] == 'CR') {
            glEntry.creditAmount = new BigDecimal(it['authorized_amt'])
            offsetGlEntry.debitAmount = new BigDecimal(it['authorized_amt'])
        } else if (it['trans_type'] == 'PUR') {
            glEntry.debitAmount = new BigDecimal(it['authorized_amt'])
            offsetGlEntry.creditAmount = new BigDecimal(it['authorized_amt'])
        } else {
            throw new Exception("Invalid transaction type: ${it['trans_type']}; original data: ${it.toString()}")
        }
        output << glEntry << offsetGlEntry
    }
    json = new JsonBuilder(output)
} catch(Exception exception) {
    def error = [
        type: 'Other',
        timestamp: LocalDateTime.now().toString(),
        details: [processorName: processorName, flowFileId: flowFileId, message: exception.message],
    ]
    flowFile['otherException'] = new JsonBuilder(error).toString()
    failure = true
} finally {
    if (!failure) flowFile.write("UTF-8", json.toString())
    session.transfer(flowFile, failure ? REL_FAILURE : REL_SUCCESS)
}
