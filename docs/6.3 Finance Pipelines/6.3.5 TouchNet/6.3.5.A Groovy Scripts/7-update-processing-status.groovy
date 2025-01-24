/** ExecuteGroovyScript processor to update processing status in tn_transactions
 *  Name: Update Processing Status
 *  Attributes:
 *  - SQL.db: Controller Service (DB - Postgres - Integrations)
 *  - stagingSchema: #{int_db_staging_schema}
 *  - stagingTable: tn_transactions
 *  - batchSize: 100
 *  Input flow file: None
 *  Relationships:
 *  - Success: original flowfile
 *  - Failure: original flowfile with error attributes
 */

import org.apache.nifi.flowfile.attributes.CoreAttributes
import java.sql.SQLException
import java.time.LocalDateTime
import groovy.json.JsonBuilder
import groovy.json.JsonSlurper

def processorName = context.name
def flowFile = session.get()
if (!flowFile) return
def flowFileId = flowFile.getAttribute(CoreAttributes.UUID.key())

def input = new JsonSlurper().parse(flowFile.read())
def failure = false
def sql = """
UPDATE ${stagingSchema.value}.${stagingTable.value}
SET processing_status = 'POSTED'
WHERE record_digest = :recordDigest
""".replaceAll(/[\n\r]/, ' ')

try {
    SQL.db.withBatch(batchSize.value as int, sql) { ps ->
        input.each { glEntry ->
            def (entryType, recordDigest) = glEntry.consumerTrackingId.split(/:/)
            if (entryType == 'original') ps.addBatch([recordDigest: recordDigest])
        }
    }
} catch (SQLException sqlException) {
    def details = sqlException.iterator().collect{ [processorName: processorName, flowFileId: flowFileId, message: it.message] }
    def error = [type: 'SQL', timestamp: LocalDateTime.now().toString(), details: details]
    flowFile['sqlException'] = new JsonBuilder(error).toString()
    failure = true
} catch (Exception exception) {
    def error = [type: 'Other', details: [processorName: processorName, flowFileId: flowFileId, message: exception.message], timestamp: LocalDateTime.now().toString()]
    flowFile['otherException'] = new JsonBuilder(error).toString()
    failure = true
} finally {
    session.transfer(flowFile, failure ? REL_FAILURE : REL_SUCCESS)
}
