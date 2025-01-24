
CREATE OR REPLACE VIEW CC_TOUCHNET_DATA_V ( TOUCHNET_MERCHANT_ID, MERCHANT_ID, RAW_SECONDARY_ID, SECONDARY_ID, SETTLEMENT_DATE, REFERENCE_ID, TRANS_TYPE, ANCILLARY_DATA, RAW_ANCILLARY_DATA, CARD_TYPE_CODE, TRANS_AMT, TRANS_DATE, AUTHORIZED_AMT, CHART_NUM, ACCT_NUM, SUB_ACCT_NUM, PROJECT_NUM )
BEQUEATH DEFINER AS
SELECT
          m.sub_trans_cd AS touchnet_merchant_id
        , merch.merchant_id
        , CASE
            WHEN INSTR( s.ancil_data, 'FID=' ) > 0 THEN
              SUBSTR( s.ancil_data, INSTR( s.ancil_data, 'FID=' ) + 4, 3 )
            ELSE
              '---'
          END AS raw_secondary_id
        , NVL( cm.secondary_id, '---' ) AS secondary_id
        , TO_DATE( TO_CHAR( s.trans_date, 'MMDDYYYY' )||s.trans_time, 'MMDDYYYYHH24:MI:SS' ) AS settlement_date
        , SUBSTR( s.trans_id, 1, 8 )||TO_CHAR( NVL( SUBSTR( s.trans_id, 9 ), '0' ), 'FM000000' ) AS reference_id
        , s.trans_type
        , CASE   --SR14536 simplified per LS and corrected syntax on substr() that lost data
            WHEN INSTR( s.ancil_data, 'EXT_TRANS_ID=' ) > 0   THEN
               SUBSTR( s.ancil_data, INSTR( s.ancil_data, 'EXT_TRANS_ID=' ) + 13 )
            ELSE
               s.ancil_data
          END AS ancillary_data
        , s.ancil_data AS raw_ancillary_data
        , s.card_type AS card_type_code
        , s.amount   AS trans_amt
        , TO_DATE( TO_CHAR( a.trans_date, 'MMDDYYYY' )||a.trans_time, 'MMDDYYYYHH24:MI:SS' ) AS trans_date
        , a.amount AS authorized_amt
        , CASE
            WHEN INSTR( s.ancil_data, 'FAU=' ) > 0 THEN
              SUBSTR( s.ancil_data, INSTR( s.ancil_data, 'FAU=' ) + 4, 1 )
            ELSE
              NULL
          END AS chart_num
        , CASE
            WHEN INSTR( s.ancil_data, 'FAU=' ) > 0 THEN
              SUBSTR( s.ancil_data, INSTR( s.ancil_data, 'FAU=' ) + 5, 7 )
            ELSE
              NULL
          END AS acct_num
        , CASE
            WHEN INSTR( s.ancil_data, 'FAU=' ) > 0 THEN
              NVL( SUBSTR( s.ancil_data, INSTR( s.ancil_data, 'FAU=' ) + 12, 5 ), '-----' )
            ELSE
              NULL
          END AS sub_acct_num
        , CASE
            WHEN INSTR( s.ancil_data, 'FAU=' ) > 0 THEN
              NVL( SUBSTR( s.ancil_data, INSTR( s.ancil_data, 'FAU=' ) + 17, 10 ), '----------' )
            ELSE
              NULL
          END AS project_num
    FROM  fp.tpg_set_det_log       s
         , fp.tpg_merchant      m
         , fp.tpg_auth_log          a
         , cc_merchant_t merch
         , (SELECT cm.touchnet_merchant_id, cct.secondary_id
            FROM cc_merchant_t cm
               , cc_charge_translation_t cct
               WHERE cm.merchant_id = cct.merchant_id
                 AND cm.active_flag = 'Y'
                 AND cct.active_flag = 'Y'
            ) cm
    WHERE s.rec_type = 'CD'
      AND s.trans_type IN ( 'PUR', 'CR' ) -- purchases, credits only
      AND s.mrch_id = m.sub_trans_cd
      AND m.merchant_type_id = 0 -- (credit card merchants only)
      AND a.mrch_id (+)= s.mrch_id
      AND merch.touchnet_merchant_id = s.mrch_id
      AND cm.touchnet_merchant_id (+)= s.mrch_id
      AND cm.secondary_id (+)=
         CASE
            WHEN INSTR( s.ancil_data, 'FID=' ) > 0 THEN
              SUBSTR( s.ancil_data, INSTR( s.ancil_data, 'FID=' ) + 4, 3 )
            ELSE
              '---'
          END
      AND a.rec_type (+)= 'CA'
      AND a.trans_type (+)= s.trans_type
      AND a.trans_id (+)= s.trans_id
      AND ( s.trans_type = 'PUR'
        OR (s.trans_type = 'CR'
          AND a.trans_date >= s.trans_date - 1
          AND a.trans_date <= s.trans_date + 1
           )
          )
      AND a.return_code (+)= 0
 
/
