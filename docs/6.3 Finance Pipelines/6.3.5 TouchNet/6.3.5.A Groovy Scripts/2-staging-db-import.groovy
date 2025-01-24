/** ExecuteGroovyScript processor to import TouchNet transactions
 *  Name: Import Data into Staging DB
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
import java.sql.Timestamp
import java.time.LocalDateTime
import groovy.json.JsonSlurper
import groovy.json.JsonBuilder

def processorName = context.name
def flowFile = session.get()
if (!flowFile) return
def flowFileId = flowFile.getAttribute(CoreAttributes.UUID.key())

def input = new JsonSlurper().parse(flowFile.read())
def failure = false
def cols = flowFile['columns'].split(/,/)
def params = cols.collect{":${it}"}.join(',')
def sql = """
INSERT INTO ${stagingSchema.value}.${stagingTable.value} (${cols.join(',')})
VALUES (${params})
ON CONFLICT (record_digest) DO NOTHING
""".replaceAll(/[\n\r]/, ' ')

try {
    SQL.db.withBatch(batchSize.value as int, sql) { ps ->
        input.each { row ->
            row['SETTLEMENT_DATE'] = Timestamp.valueOf(row['SETTLEMENT_DATE'])
            row['TRANS_DATE'] = Timestamp.valueOf(row['TRANS_DATE'])
            ps.addBatch(row)
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
