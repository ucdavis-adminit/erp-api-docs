package edu.ucdavis.afs.integration.concur.usbank;

/*-
 * #%L
 * concur-batch-integration
 * %%
 * Copyright (C) 2015 - 2020 The Regents of the University of California, Davis campus
 * %%
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 
 * 3. Neither the name of the University of California nor the names of its contributors
 *    may be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * #L%
 */

import java.util.Arrays;
import java.util.List;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.time.FastDateFormat;
import org.springframework.batch.core.ExitStatus;
import org.springframework.batch.core.StepExecution;
import org.springframework.batch.core.StepExecutionListener;
import org.springframework.batch.item.ItemProcessor;

import edu.ucdavis.afs.integration.concur.usbank.dto.GLJVLine;
import edu.ucdavis.afs.integration.concur.usbank.dto.UsBankFileRecord;
import edu.ucdavis.afs.integration.kfs.KfsDao;
import edu.ucdavis.afs.integration.service.DateTimeService;

public class UsBankRecordToGljvProcessor implements ItemProcessor<UsBankFileRecord, List<GLJVLine>>, StepExecutionListener {
    protected static final String DOC_NUM_PREFIX = "TC";

    private static final org.slf4j.Logger LOG = org.slf4j.LoggerFactory.getLogger(java.lang.invoke.MethodHandles.lookup().lookupClass());
    
    protected static final FastDateFormat DATE_FORMAT          = FastDateFormat.getInstance("yyMMdd");
    protected static final int            DESCRIPTION_MAX_LEN  = 40;
    protected static final int            TRACKING_NUM_MAX_LEN = 10;

    protected DateTimeService dateTimeService;
    protected KfsDao          kfsDao;

    protected String          originCode;
    protected String          disbursementAccountChartCode;
    protected String          disbursementAccountNumber;
    protected String          cashObjectCode;
    protected String          departmentObjectCode;
    
    // State variables during step run
    protected int             fiscalYear;
    protected String          docNum;
    protected int             sequenceNum;

    @Override
    public void beforeStep(StepExecution stepExecution) {
        // get current FY and store
        fiscalYear = Integer.valueOf(kfsDao.getFiscalYear());
        // generate document number from date and store
        // Note that on the flat-file format for the GL, document numbers are limited to 9 characters
        docNum = DOC_NUM_PREFIX + DATE_FORMAT.format(dateTimeService.getCurrentDate());
        // reset sequence (just in case)
        sequenceNum = 0;
    }
    
    @Override
    public ExitStatus afterStep(StepExecution stepExecution) {
        return null;
    }

    @SuppressWarnings("squid:S1168") // returning null instead of empty list - null has meaning to spring batch processors
    @Override
    public List<GLJVLine> process(UsBankFileRecord item) throws Exception {
        if ( item == null ) {
            return null;
        }
        if ( StringUtils.isBlank( item.getDepartmentalChartAccount() ) ) {
            LOG.error("Record without account passed through, skipping: {}", item);
            return null;
        }
        String[] chartAccount = StringUtils.split(item.getDepartmentalChartAccount(), '-');
        if ( chartAccount.length != 2 ) {
            LOG.error("Incorrectly formatted account ({}) made it through earlier steps, skipping: {}", item.getDepartmentalChartAccount(), item);
            return null;
        }
        // create the JV line to debit the department
        GLJVLine deptDebit = createJvLine(item, chartAccount[0], chartAccount[1], departmentObjectCode, item.getTransactionAmount());
        GLJVLine disbursementAccountCredit = createJvLine(item, disbursementAccountChartCode, disbursementAccountNumber, cashObjectCode, -item.getTransactionAmount());

        // add the two items to a list and return it
        return Arrays.asList(deptDebit, disbursementAccountCredit);
    }
    
    protected GLJVLine createJvLine(UsBankFileRecord item, String chart, String account, String objectCode, double amount) {
        GLJVLine line = new GLJVLine();
        // FAU and amount fields
        line.setChart(chart);
        line.setAccount(account);
        line.setObject(objectCode);
        line.setAmount(Math.abs(amount));
        line.setDebitCreditCode(amount < 0 ? GLJVLine.CREDIT_CODE : GLJVLine.DEBIT_CODE );
        
        // Common Document ID fields
        line.setFiscalYear(fiscalYear);
        line.setOriginCode(originCode);
        line.setDocNum(docNum);
        line.setSequenceNum(sequenceNum);
        sequenceNum++;
        
        // Transaction Identification Fields
        line.setTrackingNumber(StringUtils.left(item.getEmployeeId(), TRACKING_NUM_MAX_LEN));
        line.setTransactionDate(item.getTransactionDate() != null ? item.getTransactionDate() : dateTimeService.getCurrentDateMidnight());
        line.setOrgReferenceId(item.getCardNumLast4());
        line.setDescription(
                StringUtils.left(
                        StringUtils.trimToEmpty(item.getTransactionId()) 
                        + "_" 
                        + StringUtils.trimToEmpty(item.getEmployeeName()), DESCRIPTION_MAX_LEN));

        return line;
    }
    
    public DateTimeService getDateTimeService() {
        return dateTimeService;
    }
    public void setDateTimeService(DateTimeService dateTimeService) {
        this.dateTimeService = dateTimeService;
    }
    public KfsDao getKfsDao() {
        return kfsDao;
    }
    public void setKfsDao(KfsDao kfsDao) {
        this.kfsDao = kfsDao;
    }
    public String getDisbursementAccountChartCode() {
        return disbursementAccountChartCode;
    }
    public void setDisbursementAccountChartCode(String disbursementAccountChartCode) {
        this.disbursementAccountChartCode = disbursementAccountChartCode;
    }
    public String getDisbursementAccountNumber() {
        return disbursementAccountNumber;
    }
    public void setDisbursementAccountNumber(String disbursementAccountNumber) {
        this.disbursementAccountNumber = disbursementAccountNumber;
    }
    public String getCashObjectCode() {
        return cashObjectCode;
    }
    public void setCashObjectCode(String cashObjectCode) {
        this.cashObjectCode = cashObjectCode;
    }
    public String getDepartmentObjectCode() {
        return departmentObjectCode;
    }
    public void setDepartmentObjectCode(String departmentObjectCode) {
        this.departmentObjectCode = departmentObjectCode;
    }
    public String getOriginCode() {
        return originCode;
    }
    public void setOriginCode(String originCode) {
        this.originCode = originCode;
    }

}
