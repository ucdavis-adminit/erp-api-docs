/** ExecuteGroovyScript processor to convert CashNet transaction records to GL/PPM flattened format
 *  Name: GL/PPM Flattened Format Conversion
 *  Attributes (added by upstream processors):
 *  - consumerId: UCD CashNet
 *  - offsetGlChartString
 *  Input: CashNet transactions as JSON array of objects
 *  Output:
 *  - Success: GL/PPM flattened JSON format
 *  - Failure: SQL or other errors in JSON format
 */

import groovy.json.JsonBuilder
import groovy.json.JsonSlurper
import java.time.LocalDateTime
import org.apache.nifi.flowfile.attributes.CoreAttributes

class CashnetGlEntry {
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
    CashnetGlEntry(String glAccount) {
        (entity, fund, department, account, purpose, program, glProject, activity) = glAccount.split("-")
    }
}

def processorName = context.name
def flowFile = session.get()
if (!flowFile) return
def flowFileId = flowFile.getAttribute(CoreAttributes.UUID.key())
def headers = [
        'consumerId': consumerId.value,
        'boundaryApplicationName': consumerId.value,
        'consumerReferenceId': String.format("%s %s", consumerId.value, LocalDateTime.now()),
        'consumerTrackingId': flowFileId,
        'requestSourceType': null,
        'requestSourceId': flowFileId,
        'journalName': String.format("%s %s", consumerId.value, flowFileId),
        'journalReference': flowFileId,
        'journalSourceName': consumerId.value,
        'journalCategoryName': 'UCD Recharge',
        'externalSystemIdentifier': consumerId.value,
]

JsonBuilder json
def failure = false
def input = new JsonSlurper().parse(flowFile.read())
def output = []
try {
    input.each {
        def glEntry = new CashnetGlEntry(it['GLString'])
        def offsetGlEntry = new CashnetGlEntry(offsetGlChartString.value)
        headers.each { k, v ->
            glEntry."${k}" = v
            offsetGlEntry."${k}" = v
        }
        def amount = new BigDecimal(it['Amount'])
        if (amount > 0) {
            glEntry.creditAmount = amount
            offsetGlEntry.debitAmount = amount
        } else {
            glEntry.debitAmount = amount
            offsetGlEntry.creditAmount = amount
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
    json = new JsonBuilder(error)
    failure = true
} finally {
    flowFile.write("UTF_8", json.toString())
    session.transfer(flowFile, failure ? REL_FAILURE : REL_SUCCESS)
}
