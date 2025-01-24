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

public enum UsBankRecordType {
    ACCOUNT_BALANCE("01"),
    CARD_ACCOUNT("03"),
    CARDHOLDER("04"),
    CARD_TRANSACTION("05"),
    COMPANY("06"),
    LINE_ITEM_DETAIL("07"),
    LINE_ITEM_SUMMARY("08"),
    LODGING_SUMMARY("09"),
    ORGANIZATION("10"),
    PERIOD("11"),
    PASSENGER_ITINERARY("14"),
    LEG_ITINERARY("15"),
    SUPPLIER("16"),
    LODGING_DETAIL("26"),
    ALLOCATION("28"),
    ALLOCATION_DESC("29"),
    UNSPECIFIED("");    
    
    private String code;

    UsBankRecordType(String code) {
        this.code = code;
    }
    public String getCode() {
        return code;
    }

    public static UsBankRecordType getById(String code) {
        for( UsBankRecordType e : values() ) {
            if( e.code.equals(code) ) {
                return e;
            }
        }
        return UNSPECIFIED;
    }
}
