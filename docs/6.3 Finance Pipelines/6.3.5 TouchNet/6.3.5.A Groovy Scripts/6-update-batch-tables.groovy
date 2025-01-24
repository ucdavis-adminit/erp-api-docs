/** ExecuteGroovyScript processor to update tn_batches and tn_batch_items table
 *  Name: Update Batch Tables
 *  Attributes:
 *  - SQL.db: Controller Service (DB - Postgres - Integrations)
 *  - stagingSchema: #{int_db_staging_schama}
 *  Input:
 *  Relationships:
 *  - Success: JDBC resultset in JSON format
 *  - Failure: SQL or other errors in JSON format
 */

import groovy.json.JsonBuilder
import groovy.json.JsonSlurper
import org.apache.nifi.flowfile.attributes.CoreAttributes
import java.sql.SQLException
import java.sql.Timestamp
import java.time.LocalDateTime

def processorName = context.name
def flowFile = session.get()
if (!flowFile) return
def flowFileId = flowFile.getAttribute(CoreAttributes.UUID.key())
flowFile['mime.type'] = 'application/json'

def batchData = new JsonSlurper().parse(flowFile.read())
if (batchData?.size() == 0) return

def sqlCreateBatch = "INSERT INTO ${stagingSchema.value}.tn_batches (batch_id, batch_timestamp, data_records) VALUES (:batchId, :batchTimestamp, :dataRecords)".toString()
def sqlCreateBatchItems = "INSERT INTO ${stagingSchema.value}.tn_batch_items (batch_id, record_digest) VALUES (:batchId, :recordDigest)".toString()
def batchId = flowFile.requestSourceId
def dataRecords = batchData.size()
def batchTimestamp = new Timestamp(System.currentTimeMillis())
def failure = false
try {
    SQL.db.withTransaction {
        SQL.db.execute(sqlCreateBatch, [batchId: batchId, batchTimestamp: batchTimestamp, dataRecords: dataRecords])
        batchData.each {
            SQL.db.execute(sqlCreateBatchItems, [batchId: batchId, recordDigest: it['record_digest']])
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
