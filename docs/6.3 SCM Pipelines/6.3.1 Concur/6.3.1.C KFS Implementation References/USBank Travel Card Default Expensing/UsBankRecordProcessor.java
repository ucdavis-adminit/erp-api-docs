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

import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.ParseException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.io.FilenameUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.time.FastDateFormat;
import org.springframework.batch.core.ExitStatus;
import org.springframework.batch.core.StepExecution;
import org.springframework.batch.core.StepExecutionListener;
import org.springframework.batch.item.ExecutionContext;
import org.springframework.batch.item.ItemProcessor;
import org.springframework.batch.item.file.mapping.FieldSetMapper;
import org.springframework.batch.item.file.transform.DefaultFieldSet;
import org.springframework.batch.item.file.transform.FieldSet;
import org.springframework.validation.BindException;

import edu.ucdavis.afs.integration.base.listener.UcdBatchJobListener;
import edu.ucdavis.afs.integration.concur.usbank.dto.UsBankCardAccountRecord;
import edu.ucdavis.afs.integration.concur.usbank.dto.UsBankCardHolderRecord;
import edu.ucdavis.afs.integration.concur.usbank.dto.UsBankCardTransactionRecord;
import edu.ucdavis.afs.integration.concur.usbank.dto.UsBankFileHeaderRow;
import edu.ucdavis.afs.integration.concur.usbank.dto.UsBankFileRecord;

/**
 * Handles conversion of US Bank file records into transaction records needed for importing into the 
 * Concur integration database for use in generating the GLJV file to transfer the expenses to the department default accounts.
 * 
 * @author kellerj
 */
public class UsBankRecordProcessor implements ItemProcessor<Object,UsBankFileRecord>, StepExecutionListener {
    private static final org.slf4j.Logger LOG = org.slf4j.LoggerFactory.getLogger(java.lang.invoke.MethodHandles.lookup().lookupClass());

    protected static final FastDateFormat usBankDateFormat                   = FastDateFormat.getInstance("MMddyyyy");
    protected static final String         INDIVIDUAL_CARDHOLDER_ACCOUNT_TYPE = "2";
    protected static final int            CARD_DIGITS_TO_SHOW                = 4;
    protected static final String         LINE_FORMAT                        = "\t%-40s : %12s";
    protected static final int            AMOUNT_COL_WIDTH                   = 12;
    protected static final int            SUMMARY_COL_WIDTH                  = 40;

    // lists of the fields in the different record types - matched to the data object
    protected List<String>                                cardAccountFields;
    protected List<String>                                cardHolderFields;
    protected List<String>                                cardTransactionFields;
    protected FieldSetMapper<UsBankCardAccountRecord>     cardAccountObjectMapper;
    protected FieldSetMapper<UsBankCardHolderRecord>      cardHolderObjectMapper;
    protected FieldSetMapper<UsBankCardTransactionRecord> cardTransactionObjectMapper;
    
    protected List<String> excludedTransactionTypeCodes = Arrays.asList(UsBankTransactionTypeCode.PAYMENT.getCode());
    
    protected UsBankRecordType                     currentDetailRecordType;
    protected Map<String, UsBankCardAccountRecord> cardAccountRecords;
    protected Map<String, UsBankCardHolderRecord>  cardHolderRecords;
    
    protected int          lineNumber;
    
    // Summary output information
    protected List<String> errorMessages;
    protected int          validCardHolders;
    protected int          cardAccounts;
    protected int          excludedTransactions;
    protected int          processedTransactions;
    protected int          skippedTransactions;
    protected int          transactionLines;
    protected int          headerLines;
    protected int          otherLines;
    protected BigDecimal   transactionTotal;

    @Override
    public void beforeStep(StepExecution stepExecution) {
        cardAccountRecords = new HashMap<>();
        cardHolderRecords = new HashMap<>();
        errorMessages = new ArrayList<>();
        currentDetailRecordType = null;
        lineNumber = 0;
        validCardHolders = 0;
        cardAccounts = 0;
        transactionLines = 0;
        headerLines = 0;
        otherLines = 0;
        excludedTransactions = 0;
        processedTransactions = 0;
        skippedTransactions = 0;
        transactionTotal = BigDecimal.ZERO;
    }

    @SuppressWarnings("unchecked")
    @Override
    public ExitStatus afterStep(StepExecution stepExecution) {
        ExecutionContext executionContext = stepExecution.getJobExecution().getExecutionContext();
        List<String> jobLog = (List<String>) executionContext.get(UcdBatchJobListener.EMAIL_LOG_PROP);
        String usBankFileName = stepExecution.getJobParameters().getString("input.file");
        usBankFileName = FilenameUtils.getName(usBankFileName);

        DecimalFormat amountFormat = new DecimalFormat("#,##0.00");       
        List<String> summary = new ArrayList<>();
        summary.add("<b>US Bank File Summary: " + usBankFileName + "</b>\n");
        summary.add(String.format(LINE_FORMAT, StringUtils.repeat("-", SUMMARY_COL_WIDTH), StringUtils.repeat("-", AMOUNT_COL_WIDTH)));
        summary.add(String.format(LINE_FORMAT, "Total Transactions in File", transactionLines));
        summary.add(String.format(LINE_FORMAT, "Card Accounts", cardAccounts));
        summary.add(String.format(LINE_FORMAT, "Card Holders", validCardHolders));
        summary.add(String.format(LINE_FORMAT, "Processed Transactions", processedTransactions));
        summary.add(String.format(LINE_FORMAT, "Excluded Transactions (not expense type)", excludedTransactions));
        summary.add(String.format(LINE_FORMAT, "Skipped Transactions (no emp ID)", skippedTransactions));
        summary.add(String.format(LINE_FORMAT, "Processed Transaction Total", amountFormat.format(transactionTotal.doubleValue())));
        summary.add(String.format(LINE_FORMAT, StringUtils.repeat("-", SUMMARY_COL_WIDTH), StringUtils.repeat("-", AMOUNT_COL_WIDTH)));
        summary.add(String.format(LINE_FORMAT, "Duplicate Transactions Ignored", stepExecution.getFilterCount() - headerLines - otherLines));
        summary.add("");
        jobLog.addAll(summary);
        
        LOG.info("\n{}", StringUtils.join(summary, "\n"));
        
        if ( !errorMessages.isEmpty() ) {
            executionContext.put(UcdBatchJobListener.HAS_WARNINGS_PROP, true);
            jobLog.add("\n<b>US Bank File Error Messages:</b>");
            jobLog.addAll(errorMessages);
        }
        
        // clear out the references to ensure the data is garbage collected as soon as possible
        cardAccountRecords = new HashMap<>();
        cardHolderRecords = new HashMap<>();
        errorMessages = new ArrayList<>();
        currentDetailRecordType = null;
        
        // Do not change exit status
        return null;
    }

    @Override
    public UsBankFileRecord process(Object item) throws Exception {
        lineNumber++;
        if ( item == null ) {
            return null;
        }
        if ( item instanceof UsBankFileHeaderRow ) {
            headerLines++;
            handleHeaderRow((UsBankFileHeaderRow)item);
            return null;
        }
        if ( item instanceof FieldSet ) {
            return handleDetailRow((FieldSet)item);
        }
        otherLines++;
        LOG.error("Unexpected item passed into processor: {} / {}", item.getClass().getName(), item);
        
        return null;
    }

    /**
     * Add the names to the index-only input fieldset limiting to 
     * the minimum number of fields between the values and names parameters.
     */
    protected FieldSet adaptFieldSet(FieldSet item, List<String> fieldNames) {
        if ( item == null || fieldNames == null ) {
            return new DefaultFieldSet(new String[0], new String[0]);
        }
        if ( item.getFieldCount() == fieldNames.size() ) {
            return new DefaultFieldSet(item.getValues(), fieldNames.toArray(new String[0]));
        }
        // if more fields than field names, eliminate fields past the end
        if ( item.getFieldCount() > fieldNames.size() ) {
            return new DefaultFieldSet(Arrays.copyOf(item.getValues(), fieldNames.size()), fieldNames.toArray(new String[0]));
        }
        // remove field names past the end since we don't have values for it
        return new DefaultFieldSet(item.getValues(), Arrays.copyOf(fieldNames.toArray(new String[0]), item.getFieldCount()));
    }
    
    /**
     * Given the tokenized card account record data.  Map it into a data object and then add the
     * object into the step's internal store of known card numbers.
     */
    protected UsBankCardAccountRecord handleCardAccountRecord(FieldSet item) throws BindException {
        FieldSet cardAccountFieldSet = adaptFieldSet(item, cardAccountFields);
        UsBankCardAccountRecord cardAccountRecord = cardAccountObjectMapper.mapFieldSet(cardAccountFieldSet);
        LOG.info("Card Account Record: {}", cardAccountRecord);
        // Only add the account if it's of the appropriate type
        if ( StringUtils.equals(cardAccountRecord.getAccountBillingTypeFlag(), INDIVIDUAL_CARDHOLDER_ACCOUNT_TYPE) ) {
            // Add card data to internal storage
            cardAccountRecords.put(cardAccountRecord.getAccountNumber(), cardAccountRecord);
            cardAccounts++;
            return cardAccountRecord;
        }
        return null;
    }
    
    /**
     * Given the tokenized card holder record data.  Map it into a data object and then add the
     * object into the step's internal store of known card holders.
     */
    protected UsBankCardHolderRecord handleCardHolderRecord(FieldSet item) throws BindException {
        FieldSet cardHolderFieldSet = adaptFieldSet(item, cardHolderFields);
        UsBankCardHolderRecord cardHolderRecord = cardHolderObjectMapper.mapFieldSet(cardHolderFieldSet);
        LOG.info("Card Holder Record: {}", cardHolderRecord);                
        // Add card to mapping setup if it was an eligible card per the card account rows
        // And if we have an employee ID
        if ( cardAccountRecords.containsKey(cardHolderRecord.getAccountNumber()) ) {
            if ( StringUtils.isNotBlank( cardHolderRecord.getEmployeeId() ) ) {
                cardHolderRecords.put(cardHolderRecord.getAccountNumber(), cardHolderRecord);
                validCardHolders++;
                return cardHolderRecord;
            } else {
                errorMessages.add("Line # " + lineNumber + ": Cardholder record for ************" + StringUtils.right(cardHolderRecord.getAccountNumber(),  CARD_DIGITS_TO_SHOW) + " did not have an employee ID.  Unable to process.");
            }
        }
        return null;
    }

    /**
     * Given the tokenized card transaction record data, map it into a data object.
     * If the card number on the transaction is one which was earlier deemed ok to process,
     * then convert the data into the format for storage into MongoDB.
     */
    protected UsBankFileRecord handleCardTransactionRecord(FieldSet item) throws BindException {
        FieldSet cardTransactionFieldSet = adaptFieldSet(item, cardTransactionFields);
        UsBankCardTransactionRecord trans = cardTransactionObjectMapper.mapFieldSet(cardTransactionFieldSet);
        LOG.info("Card Transaction Record: {}", trans);
        UsBankCardAccountRecord card = cardAccountRecords.get(trans.getAccountNumber());
        if ( card == null ) {
            LOG.debug("Transaction not eligible for export as card not of the correct type: {}", trans);
            return null;
        }
        UsBankCardHolderRecord cardholder = cardHolderRecords.get(trans.getAccountNumber());
        if ( cardholder == null ) {
            LOG.warn("Transaction not exportable for export as no cardholder record found: {}", trans);
            skippedTransactions++;
            return null;
        }
        if ( excludedTransactionTypeCodes.contains( trans.getTransactionTypeCode() ) ) {
            LOG.info("Excluding transaction {} as of an excluded transaction type: {}", trans.getReferenceNumber(), trans.getTransactionTypeCode() );
            excludedTransactions++;
            return null;
        }
        
        UsBankFileRecord usBankFileRecord = createUsBankFileRecord( trans, cardholder, card ); 
        processedTransactions++;
        transactionTotal = transactionTotal.add(BigDecimal.valueOf(usBankFileRecord.getTransactionAmount()));
        return usBankFileRecord;
    }
    
    /**
     * Convert the data on the given transaction, cardholder, and account into the MongoDB storage format.
     */
    protected UsBankFileRecord createUsBankFileRecord(UsBankCardTransactionRecord trans, UsBankCardHolderRecord cardholder, UsBankCardAccountRecord card) {
        UsBankFileRecord record = new UsBankFileRecord();
        record.setEmployeeId(StringUtils.trimToEmpty(cardholder.getEmployeeId()));
        record.setCardNumLast4(StringUtils.right(StringUtils.trimToEmpty(trans.getAccountNumber()), CARD_DIGITS_TO_SHOW));
        record.setTransactionId(StringUtils.trimToEmpty(trans.getReferenceNumber())+"-"+trans.getSequenceNumber());
        record.setCardholderName(StringUtils.normalizeSpace( cardholder.getFirstName() + " " + cardholder.getMiddleName() + " " + cardholder.getLastName() ));
        record.setTransactionAmount(new BigDecimal(trans.getBillingAmount()).movePointLeft(2).doubleValue());
        if ( UsBankTransactionTypeCode.getById(StringUtils.trimToEmpty(trans.getTransactionTypeCode())).isCredit() ) {
            record.setTransactionAmount(-record.getTransactionAmount());
        }
        try {
            record.setPostingDate(usBankDateFormat.parse(StringUtils.trimToEmpty(trans.getPostingDate())));
        } catch (ParseException ex) {
            LOG.warn("Invalid Posting Date on transaction {} - setting to today: {}", trans.getReferenceNumber(), trans.getPostingDate());
            record.setPostingDate(Date.from(LocalDate.now().atStartOfDay().atZone(ZoneId.systemDefault()).toInstant()));
        }
        try {
            record.setTransactionDate(usBankDateFormat.parse(StringUtils.trimToEmpty(trans.getTransactionDate())));
        } catch (ParseException ex) {
            LOG.warn("Invalid Transaction Date on transaction {} - setting to today: {}", trans.getReferenceNumber(), trans.getTransactionDate());
            record.setTransactionDate(Date.from(LocalDate.now().atStartOfDay().atZone(ZoneId.systemDefault()).toInstant()));
        }
        if ( StringUtils.isNotBlank(card.getAccountOpenDate()) ) {
            try {
                record.setCardIssueDate(usBankDateFormat.parse(StringUtils.trimToEmpty(card.getAccountOpenDate())));
            } catch (ParseException ex) {
                LOG.warn("Invalid card issue date on card linked to transaction {} - leaving blank: {}", trans.getReferenceNumber(), card.getAccountOpenDate());
            }
        }
        record.setMerchantName(StringUtils.trimToEmpty(trans.getSupplierName()));
        record.setTransactionTypeCode(StringUtils.trimToEmpty(trans.getTransactionTypeCode()));
        record.setTransactionDescription(StringUtils.trimToEmpty(trans.getPurchaseIdentificationDescription()));
        
        return record;
    }

    /**
     * Process the given detail row data depending on the current record type.
     */
    protected UsBankFileRecord handleDetailRow(FieldSet item) throws BindException {
        if ( currentDetailRecordType == null ) {
            otherLines++;
            LOG.warn("No Current Detail Record Type, File is Malformed.  Current Line: {}", item);
            return null;
        }
        switch ( currentDetailRecordType ) {
            case CARD_ACCOUNT :
                otherLines++;
                handleCardAccountRecord(item);
                return null;
            case CARDHOLDER :
                otherLines++;
                handleCardHolderRecord(item);
                return null;
            case CARD_TRANSACTION :
                transactionLines++;
                return handleCardTransactionRecord(item);
            default :
               otherLines++;
               LOG.debug("Unprocessed Record Type: {}", currentDetailRecordType);
               return null;
        }
    }

    /**
     * Process the given header row data depending on the parsed row type.
     */
    protected void handleHeaderRow(UsBankFileHeaderRow item) {
        switch ( UsBankRowType.getById(StringUtils.trimToEmpty(item.getRowType())) ) {
            case FILE_HEADER :
                LOG.info("File Header: {}", item);
                break;
            case FILE_TRAILER :
                LOG.info("File Trailer: {}", item);
                break;
            case RECORD_TYPE_HEADER :
                LOG.info("Record Type Header: {}", item);
                // set the current detail record type so following detail records are processed as needed
                currentDetailRecordType = UsBankRecordType.getById(StringUtils.trimToEmpty(item.getRecordTypeCode()));
                LOG.info("Set Detail Record Type to: {}", currentDetailRecordType);
                break;
            case RECORD_TYPE_TRAILER :
                LOG.info("Record Type Trailer: {}", item);
                currentDetailRecordType = null;
                break;
            default :
                LOG.info("Unknown Row Type: {}", item);
                break;
        }
    }

    public void setCardAccountFields(List<String> cardAccountFields) {
        this.cardAccountFields = cardAccountFields;
    }

    public void setCardAccountObjectMapper(FieldSetMapper<UsBankCardAccountRecord> cardAccountObjectMapper) {
        this.cardAccountObjectMapper = cardAccountObjectMapper;
    }

    public void setCardHolderObjectMapper(FieldSetMapper<UsBankCardHolderRecord> cardHolderObjectMapper) {
        this.cardHolderObjectMapper = cardHolderObjectMapper;
    }

    public void setCardTransactionObjectMapper(FieldSetMapper<UsBankCardTransactionRecord> cardTransactionObjectMapper) {
        this.cardTransactionObjectMapper = cardTransactionObjectMapper;
    }

    public void setCardHolderFields(List<String> cardHolderFields) {
        this.cardHolderFields = cardHolderFields;
    }

    public void setCardTransactionFields(List<String> cardTransactionFields) {
        this.cardTransactionFields = cardTransactionFields;
    }
}
