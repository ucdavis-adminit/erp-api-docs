/** Compress and Encode File Content
 *  Input: AR lockbox data file
 *  Output:
 *  - Success: compressed and Base64-encoded flow file
 *  - Failure: original flow file with ERROR attribute
 */

import java.util.zip.ZipOutputStream
import java.util.zip.ZipEntry

def flowFile = session.get()
def data = flowFile.read().getText('UTF-8').bytes
def baos = new ByteArrayOutputStream()
def zos = new ZipOutputStream(baos)
def entry = new ZipEntry(flowFile['filename'])
zos.putNextEntry(entry)
zos.write(data, 0, data.length)
zos.closeEntry()
zos.close()

def base64Encoded = Base64.encoder.encodeToString(baos.toByteArray())
flowFile.write('UTF-8', base64Encoded)

session.transfer(flowFile, REL_SUCCESS)
