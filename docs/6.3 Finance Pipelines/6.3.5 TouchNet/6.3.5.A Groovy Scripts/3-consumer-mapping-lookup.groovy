/** ExecuteGroovyScript processor to lookup consumer mapping with a give consumer ID
 *  Name: Lookup Consumer Mapping
 *  Attributes:
 *  - apiSchema: #{db_int_api_schema}
 *  - consumerId: #{consumer_id}
 *  - SQL.db: Controller Service (DB - Postgres - Integrations)
 *  Input: Partitioned TouchNet transactions (JSON array)
 *  Relationships:
 *  - Success: original flow file with additional attributes (see below)
 *  - Failure: original flow file with error attributes
 */

import org.apache.nifi.flowfile.attributes.CoreAttributes
import java.sql.SQLException
import java.time.LocalDateTime
import groovy.json.JsonBuilder

def processorName = context.name
def flowFile = session.get()
if (!flowFile) return
def flowFileId = flowFile.getAttribute(CoreAttributes.UUID.key())

def sql = "SELECT * FROM ${apiSchema.value}.consumer_mapping WHERE consumer_id = '${consumerId.value}' AND enabled_flag = 'Y'".toString()
def failure = false
try {
    def consumerMapping = SQL.db.firstRow(sql)
    if (!consumerMapping) throw new Exception("Invalid consumerId: ${consumerId.value}")
    flowFile['consumerId'] = consumerId.value
    flowFile['boundaryApplicationName'] = consumerId.value
    flowFile['consumerReferenceId'] = String.format("%s %s", consumerId.value, LocalDateTime.now())
    flowFile['requestSourceType'] = 'api'
    flowFile['requestSourceId'] = flowFileId
    flowFile['journalName'] = String.format("%s %s", consumerId.value, flowFileId)
    flowFile['journalReference'] = flowFileId
    flowFile['journalSourceName'] = consumerMapping.journal_source
    flowFile['journalCategoryName'] = consumerMapping.journal_category
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
