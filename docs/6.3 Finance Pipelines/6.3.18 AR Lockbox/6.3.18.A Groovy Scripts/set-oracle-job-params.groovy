/** Set Oracle Job Parameters
 *  Input: AR lockbox data file
 *  Output:
 *  - Success: original flow file
 *  - Failure: original flow file with ERROR_* attribute
 */

def flowFile = session.get()
def lockboxId = null, basename = null
if ((match = flowFile['kafka.key'] =~ /arlockboximportextbai2_(\d+)_(\d+)/)) {
    basename = match[0][0]
    lockboxId = match[0][1]
} else {
    flowFile['error'] = "Invalid file name: ${flowFile['kafka.key']}"
    session.transfer(flowFile, REL_FAILURE)
    return
}
//include #{lockbox_mappings}
def bu = oracleBusinessUnit[lockboxId]
def lb = oracleLockboxId[lockboxId]
def dt = flowFile['accounting.date']
def id = flowFile['assigned.job.id']
def jobName = "ARLOCKBOX_${lockboxId}_${id}"
def params = "Y,#NULL,$jobName,N,#NULL,#NULL,108,Y,$lb,$dt,A,N,N,N,Y,$bu,1"
flowFile['lockboxId'] = lockboxId
flowFile['filename'] = "${basename}_${id}.dat"
flowFile['job.parameter.list'] = params
session.transfer(flowFile, REL_SUCCESS)
