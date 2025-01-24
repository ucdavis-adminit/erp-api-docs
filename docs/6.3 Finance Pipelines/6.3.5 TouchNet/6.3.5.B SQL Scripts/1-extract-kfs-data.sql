-- Query Parameters
-- 1. Startinng transaction date

SELECT
	m.sub_trans_cd AS touchnet_merchant_id,
	merch.merchant_id,
	CASE
		WHEN INSTR( s.ancil_data, 'FID=' ) > 0 THEN
      SUBSTR( s.ancil_data, INSTR( s.ancil_data, 'FID=' ) + 4, 3 )
		ELSE
      '---'
	END AS fid,
	TO_DATE( TO_CHAR( s.trans_date, 'MMDDYYYY' )|| s.trans_time, 'MMDDYYYYHH24:MI:SS' ) AS settlement_date,
	SUBSTR( s.trans_id, 1, 8 )|| TO_CHAR( NVL( SUBSTR( s.trans_id, 9 ), '0' ), 'FM000000' ) AS reference_id,
	s.trans_type,
	s.ancil_data AS ancillary_data,
	s.card_type AS card_type_code,
	s.amount AS trans_amt,
	TO_DATE( TO_CHAR( a.trans_date, 'MMDDYYYY' )|| a.trans_time, 'MMDDYYYYHH24:MI:SS' ) AS trans_date,
	a.amount AS authorized_amt
FROM
	fp.tpg_set_det_log s
JOIN fp.cc_merchant_t merch ON
  merch.touchnet_merchant_id = s.mrch_id AND merch.active_flag = 'Y'
JOIN fp.tpg_merchant m ON
	m.sub_trans_cd = s.mrch_id
	AND m.merchant_type_id = 0
LEFT OUTER JOIN fp.tpg_auth_log a ON
	a.mrch_id = s.mrch_id
	AND a.rec_type = 'CA'
	AND a.trans_type = s.trans_type
	AND a.trans_id = s.trans_id
	AND a.return_code = 0
WHERE
	s.rec_type = 'CD'
	AND s.trans_type IN ( 'PUR', 'CR' )
	AND (s.trans_type = 'PUR'
	  OR (s.trans_type = 'CR'
			AND a.trans_date >= s.trans_date - 1
			AND a.trans_date <= s.trans_date + 1
    )
  )
	AND TO_DATE( TO_CHAR( s.trans_date, 'MMDDYYYY' )|| s.trans_time, 'MMDDYYYYHH24:MI:SS' ) >= TIMESTAMP '%s'
	AND NOT EXISTS (
    SELECT
      'x'
    FROM
      touchnet_import_user.cc_trans_ref_t tr
    WHERE
      tr.touchnet_merchant_id = m.sub_trans_cd
      AND tr.settlement_date = TO_DATE( TO_CHAR( s.trans_date, 'MMDDYYYY' )|| s.trans_time, 'MMDDYYYYHH24:MI:SS' )
      AND tr.reference_id = SUBSTR( s.trans_id, 1, 8 )|| TO_CHAR( NVL( SUBSTR( s.trans_id, 9 ), '0' ), 'FM000000' )
      AND tr.deleted_flag = 'N'
  )
ORDER BY
	m.SUB_TRANS_CD,
	s.TRANS_ID
