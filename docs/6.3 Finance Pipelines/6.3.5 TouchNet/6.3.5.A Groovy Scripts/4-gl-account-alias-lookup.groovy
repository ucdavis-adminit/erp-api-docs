/** ExecuteGroovyScript processor to lookup GL account alias with a give alias ID
 *  Name: GL Account Alias Lookup
 *  Attributes:
 *  - erpSchema: #{int_db_erp_schema}
 *  - defaultGlChartString: #{default_gl_chart_string}
 *  - offsetGlChartString: #{offset_gl_chart_string}
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

def aliasId = flowFile['fid'] == '---' ?
        String.format("TN_%s", flowFile['touchnetMerchantId']) :
        String.format("TN_%s_%s", flowFile['touchnetMerchantId'], flowFile['fid'])
def sql = "SELECT * FROM ${erpSchema.value}.gl_account_alias WHERE name = '${aliasId}'".toString()
def failure = false
try {
    def glAccountAlias = SQL.db.firstRow(sql)
    def glChartString = glAccountAlias ?
            (1..11).collect {glAccountAlias."segment${it}" }.join('-') :
            defaultGlChartString.value
    flowFile['glChartString'] = glChartString
    flowFile['externalSystemIdentifier'] = aliasId
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
