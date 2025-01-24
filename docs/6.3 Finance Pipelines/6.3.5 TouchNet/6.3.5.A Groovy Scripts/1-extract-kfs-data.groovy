/** ExecuteGroovyScript processor to retrieve TouchNet transactions
 *  Name: Extract TouchNet Data from KFS
 *  Attributes:
 *  - SQL.kfs: Controller Service (DB - Oracle - KFS)
 *  - SQL.int: Controller Service (DB - Postgres - Integrations)
 *  - sqlQueryKfs: SQL query to retrieve TouchNet transactions
 *  - sqlQueryInt: SQL query to get the last timestamp of staging data
 *  - stagingSchema: #{int_db_staging_schema}
 *  - defaultLookBackYears: 1
 *  Input flow file: None
 *  Relationships:
 *  - Success: JDBC resultset in JSON format
 *  - Failure: SQL or other errors in JSON format
 */

import groovy.json.JsonBuilder
import org.apache.nifi.flowfile.attributes.CoreAttributes
import java.sql.SQLException
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

def processorName = context.name
def flowFile = session.create()
if (!flowFile) return
def flowFileId = flowFile.getAttribute(CoreAttributes.UUID.key())
flowFile['mime.type'] = 'application/json'

def timestampFormatter = DateTimeFormatter.ofPattern('yyyy-MM-dd HH:mm:ss')
def failure = false
def defaultLookBack = defaultLookBackYears.value as long
JsonBuilder json
try {
    def timestamp = SQL.int.rows(String.format(sqlQueryInt.value, stagingSchema.value))[0]
    def lastTransTimestamp = timestamp['last_transaction']
    flowFile['timestamp'] = new JsonBuilder(timestamp).toString()
    def startTransDate = lastTransTimestamp ?
            LocalDateTime.parse(lastTransTimestamp, timestampFormatter).minusHours(24).format(timestampFormatter) :
            LocalDateTime.now().minusYears(defaultLookBack).format(timestampFormatter)
    flowFile['startTransDate'] = startTransDate
    def results = SQL.kfs.rows(String.format(sqlQueryKfs.value, startTransDate))
    flowFile['kfsQuery'] = String.format(sqlQueryKfs.value, startTransDate)
    flowFile['kfsRecordCount'] = results.size()
    results.each { row ->
        row['RECORD_DIGEST'] = row.values().collect{it.toString()}.join("|").digest("SHA-1")
        row['PROCESSING_STATUS'] = 'PENDING'
        row['TOUCHNET_MERCHANT_ID'] = row['TOUCHNET_MERCHANT_ID'].toString()
        row['SETTLEMENT_DATE'] = row['SETTLEMENT_DATE'].toLocalDateTime().format(timestampFormatter)
        row['TRANS_DATE'] = row['TRANS_DATE'].toLocalDateTime().format(timestampFormatter)
    }
    if (results.size() > 0) flowFile['columns'] = results[0].keySet().join(',')
    json = new JsonBuilder(results)
} catch (SQLException sqlException) {
    def details = sqlException.iterator().collect{ [processorName: processorName, flowFileId: flowFileId, message: it.message] }
    def error = [type: 'SQL', timestamp: LocalDateTime.now().toString(), details: details]
    json = new JsonBuilder(error)
    failure = true
} catch (Exception exception) {
    def error = [type: 'Other', details: [processorName: processorName, flowFileId: flowFileId, message: exception.message], timestamp: LocalDateTime.now().toString()]
    json = new JsonBuilder(error)
    failure = true
} finally {
    flowFile.write("UTF-8", json.toString())
    session.transfer(flowFile, failure ? REL_FAILURE : REL_SUCCESS)
}
