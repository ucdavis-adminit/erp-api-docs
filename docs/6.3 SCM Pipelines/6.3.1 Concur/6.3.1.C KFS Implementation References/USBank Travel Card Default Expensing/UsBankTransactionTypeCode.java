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

public enum UsBankTransactionTypeCode {
    CHARGE("10"),
    CREDIT("11", true),
    PAYMENT("31"),
    FINANCE_CHARGE("40"),
    FEE_0("50"),
    FEE_1("51"),
    FEE_2("52"),
    FEE_3("53"),
    FEE_4("54"),
    FEE_5("55"),
    FEE_6("56"),
    FEE_7("57"),
    FEE_8("58"),
    FEE_9("59"),
    CREDIT_ADJUSTMENT_1("61", true),
    CREDIT_ADJUSTMENT_2("63", true),
    CREDIT_ADJUSTMENT_3("65", true),
    DEBIT_ADJUSTMENT_1("62"),
    DEBIT_ADJUSTMENT_2("64"),
    DEBIT_ADJUSTMENT_3("66"),
    UNKNOWN("");    
    
    private String code;
    private boolean credit = false;

    UsBankTransactionTypeCode(String code) {
        this.code = code;
    }
    UsBankTransactionTypeCode(String code, boolean credit) {
        this.code = code;
        this.credit = credit;
    }
    public String getCode() {
        return code;
    }
    public boolean isCredit() {
        return credit;
    }

    public static UsBankTransactionTypeCode getById(String code) {
        for( UsBankTransactionTypeCode e : values() ) {
            if( e.code.equals(code) ) {
                return e;
            }
        }
        return UNKNOWN;
    }
}
