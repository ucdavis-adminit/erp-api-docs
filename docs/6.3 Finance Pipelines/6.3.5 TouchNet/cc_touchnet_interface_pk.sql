
CREATE OR REPLACE PACKAGE BODY CC_TOUCHNET_INTERFACE_PK IS
  TYPE FiscalPeriod IS RECORD (
     fiscalYear NUMBER,
     fiscalPeriod CHAR(2)
    );
  MailHost CONSTANT VARCHAR2(30)  := 'smtp.ucdavis.edu';
  MailPort CONSTANT NUMBER       := 25;
  FilePath CONSTANT VARCHAR2(80) := 'GL_FEED_DIR';
  FileName CONSTANT VARCHAR2(30) := 'journal.TN';
  CRLF     CONSTANT CHAR(2)      := CHR(13)||CHR(10);

  -- set this to NULL to allow emails to go to the proper recipients
  -- when debugging, set it to your universal user ID
  EMailDebugID CONSTANT VARCHAR(10) := NULL;

  SequenceNum NUMBER := 1;

  -------------------------------------------------------------------------------------------
  -- send_mail
  -------------------------------------------------------------------------------------------
  --SR14536 Changed date formatting to DD/MM/YYYY from MM/DD/YYYY as it has been DD/MM/YYYY in
  --        the actual emails (in error) for 1st - 12th of month, when there is actually a month
  --        in this range, and ok the last part of the month when there is not...also changed to HH24
  --

  PROCEDURE send_mail ( sender IN VARCHAR2
                       , senderName IN VARCHAR2
                       , recipient IN VARCHAR2
                       , recipientName IN VARCHAR2
                       , subject IN VARCHAR2
                       , message IN VARCHAR2 )
  IS
    mail_conn   utl_smtp.connection;
  BEGIN
    mail_conn := utl_smtp.open_connection( MailHost, MailPort );
    utl_smtp.helo( mail_conn, MailHost );
    utl_smtp.mail( mail_conn, sender );
    utl_smtp.rcpt( mail_conn, recipient );
    utl_smtp.data( mail_conn,
                  'Date: '||TO_CHAR( SYSDATE, 'DD/MM/YYYY HH24:MI' )||CRLF
                ||'From: '||senderName||' <'||sender||'>'||CRLF
                ||'To: '||recipientName||' <'||recipient||'>'||CRLF
                ||'Subject: '||subject||CRLF||CRLF||message );
    utl_smtp.quit( mail_conn );
  EXCEPTION
    WHEN OTHERS THEN
      utl_smtp.quit(mail_conn);
      RAISE;
  END send_mail;

    -------------------------------------------------------------------------------------------
    -- send_parsed_email
    -------------------------------------------------------------------------------------------
    PROCEDURE send_parsed_email(
		  EmailFrom 	  IN VARCHAR2
        , SenderName      IN VARCHAR2
		, EmailSubject 	  IN VARCHAR2
		, EmailBody       IN VARCHAR2
		, EmailRecipient  IN VARCHAR2
		, EmailRecipientName IN VARCHAR2
		, GiftInitiatorID IN VARCHAR2 DEFAULT ''
		, MerchantID      IN VARCHAR2 DEFAULT ''
		, MerchantName    IN VARCHAR2 DEFAULT ''
		, TransDate       IN DATE     DEFAULT SYSDATE
		, TransAmt        IN VARCHAR2 DEFAULT ''
		, FID             IN VARCHAR2 DEFAULT ''
		, FIDName         IN VARCHAR2 DEFAULT ''
		, GiftProjectNum  IN VARCHAR2 DEFAULT ''
		, GiftDocNum      IN VARCHAR2 DEFAULT ''
		, DocNum          IN VARCHAR2 DEFAULT ''
		, UndistAcctStr   IN VARCHAR2 DEFAULT ''
		, AncillaryData   IN VARCHAR2 DEFAULT ''
		, AcctStr         IN VARCHAR2 DEFAULT ''
		, FundID          IN VARCHAR2 DEFAULT ''
		, FundName        IN VARCHAR2 DEFAULT ''
		, SettleDate      IN DATE     DEFAULT SYSDATE
		, GiftDocBaseURL  IN VARCHAR2 DEFAULT ''
		, TransTypeName   IN VARCHAR2 DEFAULT ''
		, ReferenceID     IN VARCHAR2 DEFAULT ''
	)
	IS
		OutputBody    VARCHAR2(32000);
		OutputSubject VARCHAR2(32000);
		FUNCTION perform_replacement( InputString IN VARCHAR2 ) RETURN VARCHAR2
		IS
			OutputString VARCHAR2(32000) := InputString;
		BEGIN
			OutputString := REPLACE( OutputString, '~TRANS-DATE~', TransDate );
			OutputString := REPLACE( OutputString, '~SETTLE-DATE~', SettleDate );
			OutputString := REPLACE( OutputString, '~ANCILLARY-DATA~', AncillaryData );
			OutputString := REPLACE( OutputString, '~GIFT-DOC-NUM~', GiftDocNum );
			OutputString := REPLACE( OutputString, '~GIFT-PROJECT-NUM~', GiftProjectNum );
			OutputString := REPLACE( OutputString, '~TRANSACTION-TYPE~', TransTypeName );
			OutputString := REPLACE( OutputString, '~FUND-ID~', FundID );
			OutputString := REPLACE( OutputString, '~TRANS-ID~', ReferenceID );
			OutputString := REPLACE( OutputString, '~FUND-NAME~', FundName );
			OutputString := REPLACE( OutputString, '~DOC-LINK-URL~', GiftDocBaseURL||GiftDocNum );
			OutputString := REPLACE( OutputString, '~TRANS-AMT~', TransAmt );
			OutputString := REPLACE( OutputString, '~FID~', FID );
			OutputString := REPLACE( OutputString, '~MERCHANT-NAME~', MerchantName );
			OutputString := REPLACE( OutputString, '~FID-NAME~', FIDName );
			OutputString := REPLACE( OutputString, '~MERCHANT-ID~', MerchantID );
			RETURN OutputString;
		END;
	BEGIN
		OutputSubject := perform_replacement( EmailSubject );
		OutputBody := perform_replacement( EmailBody );

		send_mail( EmailFrom, SenderName, EmailRecipient, EmailRecipientName, OutputSubject, OutputBody );
	END;

  -------------------------------------------------------------------------------------------
  -- get_fp_from_date
  -------------------------------------------------------------------------------------------

  FUNCTION get_fp_from_date( dt IN DATE ) RETURN FiscalPeriod
  IS
    temp FiscalPeriod;
    month NUMBER;
    year NUMBER;
  BEGIN
    month := TO_NUMBER( TO_CHAR( dt, 'FMMM' ) );
    year := TO_NUMBER( TO_CHAR( dt, 'FMYYYY' ) );
    IF month >= 7 THEN
      temp.fiscalYear := year + 1;
      temp.fiscalPeriod := month - 6;
    ELSE
      temp.fiscalYear := year;
      temp.fiscalPeriod := month + 6;
    END IF;
    temp.fiscalPeriod := TO_CHAR( TO_NUMBER( temp.fiscalPeriod ), 'FM00' );
    RETURN temp;
  END get_fp_from_date;

  -------------------------------------------------------------------------------------------
  -- to_base_36
  -------------------------------------------------------------------------------------------

    FUNCTION to_base_36( base10Num IN NUMBER ) RETURN VARCHAR2 IS
        returnStr VARCHAR2(10) := '';
        q NUMBER;
        r NUMBER;
        num NUMBER;
    BEGIN
        num := NVL( base10Num, 0 );
        LOOP
            q := TRUNC( num / 36 );
            r := MOD( num, 36 );
            IF r < 10 THEN
                returnStr := r||returnStr;
            ELSE
                returnStr := CHR( ASCII( 'A' ) + (r-10) )||returnStr;
            END IF;
            num := q;
            EXIT WHEN num = 0; --q <= 0 AND r <= 0;
        END LOOP;
        RETURN returnStr;
    END;

  -------------------------------------------------------------------------------------------
  -- get_gift_project_code
  -------------------------------------------------------------------------------------------

  FUNCTION get_gift_project_code( PrefixCharacter IN CHAR ) RETURN VARCHAR2 IS
    seq NUMBER;
  BEGIN
      SELECT gift_project_num_seq.NEXTVAL
        INTO seq
        FROM dual;
   	  RETURN SUBSTR(PrefixCharacter,1,1)
			||SUBSTR( to_base_36( TO_NUMBER( TO_CHAR( SYSDATE, 'FMYYYY' ) ) ), -1 )
			||TO_CHAR( SYSDATE, 'MMDD' )
			||SUBSTR( LPAD( to_base_36( seq ), 4, '0' ), -4 );
  END get_gift_project_code;

  -------------------------------------------------------------------------------------------
  -- open_feed_file
  -------------------------------------------------------------------------------------------

  FUNCTION open_feed_file RETURN utl_file.file_type
  IS
    temp utl_file.file_type;
  BEGIN
    -- check that the file does not exist, since the open operation will
    -- destroy the file if present
    BEGIN
      temp := utl_file.fopen( FilePath, FileName, 'r' );
      utl_file.fclose( temp );
      raise_application_error( -20000, 'File Exists, must be moved to prevent loss of data.' );
    EXCEPTION
      WHEN utl_file.invalid_operation THEN
        NULL; -- we don't want the file to exist
    END;
    temp := utl_file.fopen( FilePath, FileName, 'w', 180 );

    RETURN temp;
  END open_feed_file;

  -------------------------------------------------------------------------------------------
  -- close_feed_file
  -------------------------------------------------------------------------------------------

  PROCEDURE close_feed_file( fh IN OUT utl_file.file_type )
  IS
  BEGIN
    IF utl_file.is_open( fh ) THEN
      utl_file.fflush( fh );
      utl_file.fclose( fh );
    END IF;
  END close_feed_file;

  -------------------------------------------------------------------------------------------
  -- write_field
  -------------------------------------------------------------------------------------------

  PROCEDURE write_field( fh IN OUT utl_file.file_type
                        , data IN VARCHAR2
                    , fieldWidth IN NUMBER ) IS
    temp VARCHAR2(180);
  BEGIN
    temp := RPAD( SUBSTR( NVL( data, ' ' ), 1, fieldWidth ), fieldWidth );
    IF utl_file.is_open( fh ) THEN
      utl_file.put( fh, temp );
    ELSE
      dbms_output.put( temp );
    END IF;
  END write_field;

  -------------------------------------------------------------------------------------------
  -- end_line
  -------------------------------------------------------------------------------------------

  PROCEDURE end_line( fh IN OUT utl_file.file_type ) IS
  BEGIN
    IF utl_file.is_open( fh ) THEN
      utl_file.new_line( fh );
    ELSE
      DBMS_OUTPUT.new_line;
    END IF;
  END end_line;

  -------------------------------------------------------------------------------------------
  -- write_feed_line
  -------------------------------------------------------------------------------------------

  PROCEDURE write_feed_line( fh IN OUT utl_file.file_type
    , fp IN FiscalPeriod
    , DocOriginCode IN VARCHAR2 DEFAULT 'TN'
    , DocNum IN VARCHAR2
    , DocType IN VARCHAR2 DEFAULT 'GLJV'
    , TrackingNum IN VARCHAR2 DEFAULT ''
    , Chart IN VARCHAR2
    , Account IN VARCHAR2
    , SubAccount IN VARCHAR2 DEFAULT '-----'
    , ObjectCode IN VARCHAR2
    , SubObject IN VARCHAR2 DEFAULT '---'
    , ProjectCode IN VARCHAR2 DEFAULT '----------'
    , LineReference IN VARCHAR2
    , Description IN VARCHAR2
    , TransDate IN DATE DEFAULT SYSDATE
    , BalanceType IN VARCHAR2 DEFAULT 'AC'
    , TransAmt IN NUMBER
    , PriorDocOriginCode IN VARCHAR2 DEFAULT ' '
    , PriorDocNum IN VARCHAR2 DEFAULT ' '
    , PriorDocType IN VARCHAR2 DEFAULT ' '
  )
  IS
  BEGIN
    write_field( fh, TO_CHAR( fp.fiscalYear, 'FM0000' ), 4 );
    write_field( fh, Chart, 2 );
    write_field( fh, Account, 7 );
    write_field( fh, SubAccount, 5 );
    write_field( fh, ObjectCode, 4 );
    write_field( fh, SubObject, 3 );
    write_field( fh, BalanceType, 2 );
    write_field( fh, '  ', 2 );
    write_field( fh, fp.fiscalPeriod, 2 );
    write_field( fh, DocType, 4 );
    write_field( fh, DocOriginCode, 2 );
    write_field( fh, DocNum, 9 );
    -- sequence number
    write_field( fh, TO_CHAR( SequenceNum, 'FM00000' ), 5 );
    SequenceNum := SequenceNum + 1;
    IF SequenceNum > 99999 THEN
      SequenceNum := 1;
    END IF;
    write_field( fh, Description, 40 );
    IF BalanceType IN ( 'BB', 'BI', 'CB', 'FT', 'FI' ) THEN
      write_field( fh, LPAD( TO_CHAR( TransAmt, 'FM99999999990.00' ), 14 ), 14 );
      write_field( fh, ' ', 1 );
    ELSE
      write_field( fh, LPAD( TO_CHAR( ABS( TransAmt ), 'FM99999999990.00' ), 14 ), 14 );
      IF TransAmt < 0 THEN
        write_field( fh, 'C', 1 );
      ELSE
        write_field( fh, 'D', 1 );
      END IF;
    END IF;
    write_field( fh, TO_CHAR( TransDate, 'YYYYMMDD' ), 8 );
    write_field( fh, TrackingNum, 10 );
    write_field( fh, ProjectCode, 10 );
    write_field( fh, LineReference, 8 );
    write_field( fh, PriorDocType, 4 );
    write_field( fh, PriorDocOriginCode, 2 );
    write_field( fh, PriorDocNum, 9 );
    write_field( fh, ' ', 8 ); -- trans reversal date
    write_field( fh, ' ', 1 ); -- encumb update code

    end_line( fh );
  END write_feed_line;

  -------------------------------------------------------------------------------------------
  -- create_gift_document
  -------------------------------------------------------------------------------------------

  FUNCTION create_gift_document(   MerchantID      IN OUT NOCOPY VARCHAR2
                                 , FID             IN OUT NOCOPY VARCHAR2
                                 , SettleDate      IN OUT NOCOPY DATE
                                 , ReferenceID     IN OUT NOCOPY VARCHAR2
                                 , AncillaryData   IN OUT NOCOPY VARCHAR2
                                 , TransDate       IN OUT NOCOPY DATE
                                 , TransAmt        IN OUT NOCOPY NUMBER
                                 , CardType        IN OUT NOCOPY VARCHAR2
                                 , GiftProject     IN OUT NOCOPY VARCHAR2
                                 , Chart           IN OUT NOCOPY VARCHAR2
                                 , Account         IN OUT NOCOPY VARCHAR2
                                 , SubAccount      IN OUT NOCOPY VARCHAR2
                                 , SubObject       IN OUT NOCOPY VARCHAR2
                                 , LineReference   IN OUT NOCOPY VARCHAR2
                                 , GiftInitiatorID IN OUT NOCOPY VARCHAR2
                                 , fp              IN OUT NOCOPY FiscalPeriod
                                 , UndistChart     IN OUT NOCOPY VARCHAR2
                                 , UndistAccount   IN OUT NOCOPY VARCHAR2
                                 , UndistObject    IN OUT NOCOPY VARCHAR2
                                 , MerchantName    IN OUT NOCOPY VARCHAR2
                                 ) RETURN VARCHAR2
  IS
    GiftTransID             NUMBER;
    DocOriginCode CONSTANT VARCHAR2(2) := '01';
    DocNum                  VARCHAR2(9);
    ErrorMessage            VARCHAR2(4000);
  BEGIN
    -- create a new transaction ID
    SELECT gift_credit_trans_id_seq.NEXTVAL
      INTO GiftTransID
      FROM dual;
    -- get a document number for the GIFZ doc
    SELECT TO_CHAR( sqdocnum.NEXTVAL, 'FM000000000' )
      INTO DocNum
      FROM dual;
    -- save the information to the gift transaction table
    INSERT INTO gift_credit_transaction
    (
        cc_gift_trans_id
      , merchant_id
      , merchant_name
      , secondary_id
      , settlement_date
      , reference_id
      , ancillary_data
      , trans_amt
      , trans_date
      , card_type_code
      , gift_doc_origin_code
      , gift_doc_num
      , gift_undistrib_chart_num
      , gift_undistrib_acct_num
      , gift_undistrib_object_num
      , gift_undistrib_project_num
    ) VALUES (
        GiftTransID
      , MerchantID
      , MerchantName
      , FID
      , SettleDate
      , ReferenceID
      , AncillaryData
      , TransAmt
      , TransDate
      , CardType
      , DocOriginCode
      , DocNum
      , UndistChart
      , UndistAccount
      , UndistObject
      , GiftProject
    );
    -- create gift document
    -- main gift record
    INSERT INTO gift_ucd_gift
    (
        doc_origin_code
      , doc_num
      , expense_chart_num
      , expense_acct_num
      , expense_sub_acct_num
      , expense_sub_object_num
      , expense_reference
      , gift_status_cd
      , gift_status_dt
      , gift_type
      , gift_init_date
      , total_gift_amt
      , donor_name
      , cc_gift_trans_id
      , gift_init_universal_user_id
    ) VALUES (
        DocOriginCode
      , DocNum
      , Chart
      , Account
      , SubAccount
      , SubObject
      , LineReference
      , 'I'
      , SYSDATE
      , 'G'
      , SYSDATE
      , TransAmt
      , 'Credit Gift'
      , GiftTransID
      , GiftInitiatorID
    );
    -- TP document header
    INSERT INTO fp_doc_header_t
    (
        fs_origin_cd
      , fdoc_nbr
      , u_version
      , fdoc_create_dt
      , fdoc_typ_cd
      , fdoc_status_cd
      , fdoc_initiator_id
      , fdoc_desc
      , fdoc_total_amt
      , org_doc_nbr
      , fdoc_approved_dt
    ) VALUES (
        DocOriginCode
      , DocNum
      , '!'
      , SYSDATE
      , 'GIFZ'
      , 'I'
      , GiftInitiatorID
      , 'Credit Gift'
      , TransAmt
      , SUBSTR( MerchantID, -7 )
      , SYSDATE
    );
    -- SCC document tables
    INSERT INTO fp_cash_clctn_hdr_t
    (
        fs_origin_cd
      , fdoc_nbr
      , u_version
      , fdoc_explain_txt
    ) VALUES (
        DocOriginCode
      , DocNum
      , '!'
      , 'Gift imported via TouchNet credit card feed.  Ref ID: '||ReferenceID
    );
    INSERT INTO fp_cash_clctn_doc_t
    (
        fs_origin_cd
      , fdoc_nbr
      , u_version
      , fdoc_post_yr
      , fdoc_post_prd_cd
      , fdoc_crdt_card_amt
      , gift_status_cd
      , gift_status_dt
    ) VALUES (
        DocOriginCode
      , DocNum
      , '!'
      , fp.fiscalYear
      , fp.fiscalPeriod
      , TransAmt
      , 'P'
      , SYSDATE
    );
    INSERT INTO fp_cash_clctn_dtl_t
    (
        fs_origin_cd
      , fdoc_nbr
      , fdoc_line_nbr
      , u_version
    ) VALUES (
        DocOriginCode
      , DocNum
      , 1
      , '!'
    );
    -- no commit, handled by main loop
    RETURN DocNum;
  END create_gift_document;


  -------------------------------------------------------------------------------------------
  -- import_transactions
  -------------------------------------------------------------------------------------------

  FUNCTION import_transactions( priorDays IN NUMBER DEFAULT 7, DebugOutput IN BOOLEAN DEFAULT FALSE ) RETURN NUMBER
  IS
    -- cursor to select rows from touchnet
    CURSOR data_cur IS
      SELECT
              m.merchant_id
            , m.merchant_name
            , tn.touchnet_merchant_id
            , tn.raw_secondary_id as raw_fid
            , tn.secondary_id AS fid
            , tn.reference_id
            , tn.trans_amt
            , tn.trans_date
            , tn.card_type_code
            , tn.settlement_date
            , tn.ancillary_data
            , tn.raw_ancillary_data
            , ct.card_type_object_num
            , tn.chart_num
            , tn.acct_num
            , tn.sub_acct_num
            , tn.project_num
        FROM
              cc_charge_translation_t mt
            , cc_card_type_t          ct
            , cc_merchant_t           m
            , cc_touchnet_data_v      tn
        WHERE
              m.merchant_id = tn.merchant_id
          AND mt.merchant_id        = tn.merchant_id
          AND mt.secondary_id      = tn.secondary_id
          AND ct.card_type_code (+)= tn.card_type_code
          AND mt.active_flag       = 'Y'
          AND m.active_flag        = 'Y'
          AND tn.settlement_date   >= TRUNC( SYSDATE ) - priorDays
          AND NOT EXISTS
            ( SELECT 'x'
                FROM cc_trans_ref_t
                WHERE touchnet_merchant_id = tn.touchnet_merchant_id
                  AND settlement_date      = tn.settlement_date
                  AND reference_id         = tn.reference_id
                  AND deleted_flag         = 'N'
            )
          ORDER BY tn.touchnet_merchant_id, tn.reference_id;      --SR14536 added order by
        CURSOR acct_cur( MerchantID VARCHAR2, FIDx VARCHAR2, TransactionID VARCHAR2, ValidFID VARCHAR2 ) IS
    	SELECT
              CASE  --SR14536 - when ancil FID is invalid, don't allow split trans
                WHEN ValidFID = 'Y' AND
                     COALESCE( mts.split_fid_provided, 'N' ) = 'Y' AND COALESCE( mts.valid_fid, 'Y' ) = 'Y' THEN
                  COALESCE( mts.chart_num, mt.chart_num )
                ELSE
                  mt.chart_num
              END AS chart_num
            , CASE
                WHEN ValidFID = 'Y' AND
                     COALESCE( mts.split_fid_provided, 'N' ) = 'Y' AND COALESCE( mts.valid_fid, 'Y' ) = 'Y' THEN
                  COALESCE( mts.acct_num, mt.acct_num )
                ELSE
                  mt.acct_num
              END AS acct_num
            , CASE
                WHEN ValidFID = 'Y' AND
                     COALESCE( mts.split_fid_provided, 'N' ) = 'Y' AND COALESCE( mts.valid_fid, 'Y' ) = 'Y' THEN
                  COALESCE( mts.sub_acct_num, mt.sub_acct_num )
                ELSE
                  mt.sub_acct_num
              END AS sub_acct_num
            , CASE
                WHEN ValidFID = 'Y' AND
                     COALESCE( mts.split_fid_provided, 'N' ) = 'Y' AND COALESCE( mts.valid_fid, 'Y' ) = 'Y' THEN
                  COALESCE( mts.object_num, mt.object_num )
                ELSE
                  mt.object_num
              END AS object_num
            , CASE
                WHEN ValidFID = 'Y' AND
                     COALESCE( mts.split_fid_provided, 'N' ) = 'Y' AND COALESCE( mts.valid_fid, 'Y' ) = 'Y' THEN
                  COALESCE( mts.sub_object_num, mt.sub_object_num )
                ELSE
                  mt.sub_object_num
              END AS sub_object_num
            , CASE
                WHEN ValidFID = 'Y' AND
                     COALESCE( mts.split_fid_provided, 'N' ) = 'Y' AND COALESCE( mts.valid_fid, 'Y' ) = 'Y' THEN
                  COALESCE( mts.project_num, mt.project_num )
                ELSE
                  mt.project_num
              END AS project_num
            --SR14536 - when ancil FID is invalid, don't allow split trans, ALSO, reset type when invalid split FID provided
            , CASE
                WHEN ValidFID = 'Y' THEN
                  COALESCE( mts.def_merchant_type, COALESCE( mts.merchant_type_code, mt.merchant_type_code ) )
                ELSE
                  mt.merchant_type_code
              END AS merchant_type_code
            , COALESCE( mts.gift_notification_id, mt.gift_notification_dafis_id ) AS gift_notification_dafis_id
            , COALESCE( mts.fund_id, mt.fund_id ) AS fund_id
            , COALESCE( mts.fund_name, mt.fund_name ) AS fund_name
            , mts.split_percent AS split_percent
            , mts.split_amount AS split_amount
            , m.touchnet_merchant_id
            , mty.merchant_type_name
            , mty.gift_merchant_ind
            , mty.normal_email_subject
            , mty.normal_email_body
            , mty.credit_email_subject
            , mty.credit_email_body
            , mty.gift_threshold_amt
            , mty.over_threshold_email_subject
            , mty.over_threshold_email_body
            , mty.not_processed_email_recipient
            , mty.not_processed_email_subject
            , mty.not_processed_email_body
            , mty.source_email_address
            , mty.gift_document_base_url
            , c.credit_clearing_chart_num
            , c.credit_clearing_acct_num
            , COALESCE( mts.fid, mt.secondary_id ) AS fid
            , COALESCE( mts.split_fid_provided, 'N' ) AS split_fid_provided
            , COALESCE( mts.valid_fid, 'Y' ) AS split_fid_valid
            , COALESCE( mts.org_reference_num, mt.org_reference_num ) AS fid_short_name
            , COALESCE( mts.do_gift_processing, mt.do_gift_processing ) AS do_gift_processing
            , CASE
                WHEN mt.campus_id = 'UCDMC' THEN
                    mty.hosp_gift_undistrib_chart_num
                ELSE
                    mty.gift_undistrib_chart_num
              END AS gift_undistrib_chart_num
            , CASE
                WHEN mt.campus_id = 'UCDMC' THEN
                    mty.hosp_gift_undistrib_acct_num
                ELSE
                    mty.gift_undistrib_acct_num
              END AS gift_undistrib_acct_num
            , CASE
                WHEN mt.campus_id = 'UCDMC' THEN
                    mty.hosp_gift_undistrib_object_num
                ELSE
                    mty.gift_undistrib_object_num
              END AS gift_undistrib_object_num
        FROM cc_charge_translation_t  mt
           , cc_merchant_t            m
           , cc_campus_t              c
           , cc_merchant_type_t       mty
           , ( SELECT
               CASE --SR14536 - add validation on split FAU, if COA and ACCT is invalid, use split FID's FAU
                 WHEN NVL2( mts.fid, 'Y', 'N' ) = 'Y' AND NVL2( mt2.secondary_id, 'Y', 'N' ) = 'Y'
                      AND NVL2( ca.account_nbr, 'Y', 'N' ) = 'Y' THEN
                      COALESCE( mts.chart_num, mt2.chart_num )
                 ELSE
                    mt2.chart_num
               END AS chart_num
              ,CASE --SR14536
                  WHEN NVL2( mts.fid, 'Y', 'N' ) = 'Y' AND NVL2( mt2.secondary_id, 'Y', 'N' ) = 'Y'
                       AND NVL2( ca.account_nbr, 'Y', 'N' ) = 'Y' THEN
                       COALESCE( mts.acct_num, mt2.acct_num )
                  ELSE
                     mt2.acct_num
               END AS acct_num
              ,CASE --SR14536
                  WHEN NVL2( mts.fid, 'Y', 'N' ) = 'Y' AND NVL2( mt2.secondary_id, 'Y', 'N' ) = 'Y'
                       AND NVL2( ca.account_nbr, 'Y', 'N' ) = 'Y' THEN
                       COALESCE( mts.sub_acct_num, mt2.sub_acct_num )
                  ELSE
                     mt2.sub_acct_num
               END AS sub_acct_num
              ,CASE --SR14536
                  WHEN NVL2( mts.fid, 'Y', 'N' ) = 'Y' AND NVL2( mt2.secondary_id, 'Y', 'N' ) = 'Y'
                       AND NVL2( ca.account_nbr, 'Y', 'N' ) = 'Y' THEN
                       COALESCE( mts.project_num, mt2.project_num )
                  ELSE
                     mt2.project_num
               END AS project_num
                    , COALESCE( mts.fund_id, mt2.fund_id ) AS fund_id
                    , COALESCE( mts.fund_name, mt2.fund_name ) AS fund_name
                    , COALESCE( u.person_unvl_id, mt2.gift_notification_dafis_id ) AS gift_notification_id
                    , mt2.object_num
                    , mt2.sub_object_num
                    , mt2.merchant_type_code
                    , mts.amount AS split_amount
                    , mts.percent AS split_percent
                    , mts.alloc_id
                    , mt2.org_reference_num
                    , mts.fid
                    , m.merchant_id
                    , mt2.do_gift_processing
                    , CASE --SR14536 set to default type in order to override AncilFID when have Split but not valid FID
                          WHEN NVL2( mts.fid, 'Y', 'N' ) = 'Y' AND NVL2( mt2.secondary_id, 'Y', 'N' ) = 'N' THEN -- SR14536
                          'D'
                       ELSE
                           NULL
                      END AS def_merchant_type
                    , NVL2( mt2.secondary_id, 'Y', 'N' ) AS valid_fid
                    , NVL2( mts.fid, 'Y', 'N' ) AS split_fid_provided
                    FROM cc_trans_alloc_v         mts
                       , cc_merchant_t m
                       , cc_charge_translation_t  mt2
                       , fs_universal_usr_t       u
                       , ca_account_t             ca              --SR14536 add split FAU validation
                    WHERE m.merchant_id = MerchantID
                      AND mts.touchnet_merchant_id = m.touchnet_merchant_id  --SR15011 correct mismatch on data types
                      AND mts.transaction_id =  TransactionID
                      AND u.person_user_id (+)= mts.gift_notification_id
                      AND mt2.merchant_id (+)= mts.merchant_id               --SR15011 no mods view now has both merch fields
                      AND mt2.secondary_id (+)= mts.fid
                      AND ( ca.fin_coa_cd (+)= mts.chart_num      --SR14536 add split FAU validation
                           AND ca.account_nbr (+)= mts.acct_num )
        ) mts
       WHERE mt.merchant_id = MerchantID
          AND mt.secondary_id = FIDx
          AND m.merchant_id = mt.merchant_id
          AND c.campus_id = mt.campus_id
          AND mts.merchant_id (+)= mt.merchant_id
          AND mty.merchant_type_code = DECODE( ValidFID --change hard coded 'Y/N' value for different results
              ,'Y',
              COALESCE( mts.def_merchant_type, COALESCE( mts.merchant_type_code, mt.merchant_type_code ) )  -- force to D if SplitFID is invalid
                                               ,mt.merchant_type_code)    --SR14536 no split overrides if ancil FID invalid
       ORDER BY alloc_id;

    DocOriginCode    CONSTANT CHAR(2) := 'TN';
    DocType          CONSTANT CHAR(4) := 'GLJV';
    BalanceType      CONSTANT CHAR(2) := 'AC';
    CCardObject      cc_card_type_t.card_type_object_num%TYPE;
    GiftProject      VARCHAR2(10);
    fp               FiscalPeriod;
    DocNum           VARCHAR2(9);
    GiftDocNum       VARCHAR2(9);
    fh               utl_file.file_type;
    TotalAmount      NUMBER(15,2) := 0.00;
    JournalLineCount NUMBER      := 0;
    TransactionCount NUMBER      := 0;
    GiftDocCount     NUMBER      := 0;
    ReturnValue      NUMBER(1)   := 0;
    ErrorMessage     VARCHAR2(4000) := '';
    CreditRecords    NUMBER      := 0;
    ErrorCount       NUMBER      := 0;
    Temp             NUMBER;
    Chart            VARCHAR2(2);
    Account          VARCHAR2(7);
    SubAccount       VARCHAR2(5);
    ProjectCode      VARCHAR2(10);
    OrgReferenceNum  VARCHAR2(8);
    NumSplits        NUMBER;
    SplitNumber      NUMBER;
    LineRemainder    NUMBER(15,2);
    SplitAmount      NUMBER(15,2);
	EmailSubject     VARCHAR2(4000);
	EmailBody        VARCHAR2(4000);
	EmailRecipient      VARCHAR2(100);
	EmailRecipientName  VARCHAR2(200);
	GiftInitiatorID  VARCHAR2(10);
	ValidFID         VARCHAR2(1);
  BEGIN
    INSERT INTO cc_process_log_t ( action_code, message_text )
      VALUES ( 'S', 'Starting Extract' );
    COMMIT;

    -- TODO: get the amount of the gift threshold

    --   Determine a document number from the date (YYYYMMDD)
    DocNum := TO_CHAR( SYSDATE, 'YYYYMMDD' );

    -- open the feed file
    IF NOT DebugOutput THEN
      fh := open_feed_file;
    END IF;
    -- Run query which joins the data from the Payment Gateway to the translation,
    --     merchant, and campus tables.
    --   Only include active items from the tables.
    FOR rec IN data_cur LOOP
      IF DebugOutput THEN dbms_output.put_line('Processing: '||rec.merchant_id||'/'||rec.raw_fid||'/'||rec.reference_id||'/'||rec.trans_amt);
      dbms_output.put_line('"'||rec.raw_ancillary_data||'"'); END IF;
      BEGIN

        --SR14536 implement rule to treat dash FID as invalid, default, no overrides by split or ancil FAU
        IF rec.fid = '---' THEN
            ValidFID := 'N';
        ELSE
            ValidFID := 'Y';
        END IF;

        IF DebugOutput AND ValidFID = 'N' THEN dbms_output.put_line('Invalid FID'); END IF;
        --   Get the posting fiscal year period from the settlement date.  Convert directly,
        --     not from the date conversion table.  (E.g., 1/1/05 is FY 2005, FP 07 - NOT
        --     part of December.)
        fp := get_fp_from_date( rec.settlement_date );
        --   Determine the object code for the card type from CC_CARD_TYPE_T.
        IF rec.card_type_object_num IS NULL THEN
          -- pull the default record
          SELECT card_type_object_num
            INTO CCardObject
            FROM cc_card_type_t
            WHERE card_type_code = '----';
        ELSE
          CCardObject := rec.card_type_object_num;
        END IF;
        --   Add a line to the CC_TRANS_REF_T table.
        -- do all database operations first, since they can be rolled back
        -- the file update operations can not be undone, so,
        -- we don't any problems after they are executed
        IF NOT DebugOutput THEN -- don't mark the trans as used if in debug mode
	        INSERT INTO cc_trans_ref_t
	          (   merchant_id
	            , touchnet_merchant_id
	            , settlement_date
	            , reference_id
	            , card_type_code
	            , trans_amt
	            , trans_date
	            , ancillary_data
	            , processed_timestamp
	          ) VALUES (
	              rec.merchant_id
	            , rec.touchnet_merchant_id
	            , rec.settlement_date
	            , rec.reference_id
	            , rec.card_type_code
	            , rec.trans_amt
	            , rec.trans_date
	            , rec.ancillary_data
	            , SYSDATE
	          );
        END IF;
        TransactionCount := TransactionCount + 1;

        TotalAmount := TotalAmount + rec.trans_amt;
        IF rec.trans_amt < 0 THEN
          CreditRecords := CreditRecords + 1;
        END IF;
        LineRemainder := rec.trans_amt;
        SplitNumber := 0;
        SELECT COUNT(*)
        	INTO NumSplits
	        FROM cc_charge_translation_t mt
                   , cc_merchant_t m
                   , cc_trans_alloc_v mts
                   , cc_charge_translation_t mt2
	        WHERE mt.merchant_id = rec.merchant_id
	          AND mt.secondary_id = rec.fid
	          AND m.merchant_id = mt.merchant_id
    		  AND mts.touchnet_merchant_id (+)= m.touchnet_merchant_id --SR15011 correct mts mismatch on data types
	          AND mts.transaction_id (+)= rec.reference_id
	          AND mt2.merchant_id (+)= mts.merchant_id
	          AND mt2.secondary_id (+)= mts.fid;

        -- Now, loop over any potential lines in the split table
        --dbms_output.put_line('Getting accts for: "'||rec.merchant_id||'/'||rec.fid||'/'||rec.reference_id||'"');
        --dbms_output.put_line('NumSplits: '||NumSplits);

	FOR acct_rec IN acct_cur( rec.merchant_id, rec.fid, rec.reference_id, ValidFID ) LOOP
            IF DebugOutput THEN dbms_output.put_line('AcctRec: '||acct_rec.fid||'/'||acct_rec.split_fid_provided||'/'||acct_rec.split_fid_valid); END IF;

		SplitNumber := SplitNumber + 1;
		OrgReferenceNum := acct_rec.fid_short_name;

                --SR14536 add initialization of local vars so don't get last row's value when current record should be null
              	EmailSubject := NULL;
              	EmailBody := NULL;
              	EmailRecipient := NULL;
              	EmailRecipientName := NULL;
              	GiftInitiatorID := NULL;
                GiftProject := NULL;
                GiftDocNum := NULL;
                EmailRecipient := NULL;

--SR14536 removed test and reset of ValidFID, leave it to pertain only to validity of ancil FID
--                IF acct_rec.split_fid_provided = 'Y' AND acct_rec.split_fid_valid = 'N' THEN
--		   ValidFID := 'N';
--                END IF;
--            IF DebugOutput AND ValidFID = 'N' THEN dbms_output.put_line('Invalid FID (split_percent level)'); END IF;

                IF ROUND( LineRemainder, 2 ) != 0.00 THEN
                   --SR14536 - note: this is either the Split FAU, Split FIDs FAU, or the Ancil FIDs FAU
		   Chart := acct_rec.chart_num;
		   Account := acct_rec.acct_num;
		   SubAccount := acct_rec.sub_acct_num;
		   ProjectCode := acct_rec.project_num;

                   --SR14536 - redesign to set the amount and FAU separately for Split vs NON Split records
                   --          when NO SPLIT/ALLOCATION records, process against only the ancil data
		   IF acct_rec.split_fid_provided = 'N' THEN  --SR14536 new

                      -- SR14536 only use ancil FAU when not null, when no splits and when ancil FID is valid
		      -- if the department specified a FAU, charge the entire amount to that FAU and continue
		      -- However, if the FID is invalid, don't allow FAU changes
		      IF  ValidFID = 'Y'
                          AND rec.chart_num||rec.acct_num IS NOT NULL     --SR14536 ensure have values to test
                          AND rec.raw_ancillary_data LIKE '%FAU=%' THEN
    				Chart := rec.chart_num;
    				Account := rec.acct_num;
    				SubAccount := rec.sub_acct_num;
    				ProjectCode := rec.project_num;
					-- check if the FAU was specified and validate account if necessary
				IF Chart||Account <> acct_rec.chart_num||acct_rec.acct_num THEN
						-- check ca_account_t
						SELECT COUNT(*) INTO Temp
						 FROM ca_account_t
						 WHERE fin_coa_cd = Chart
							AND account_nbr = Account;
					 IF Temp = 0 THEN
						  Chart := acct_rec.chart_num;
						  Account := acct_rec.acct_num;
						  SubAccount := acct_rec.sub_acct_num;
						  ProjectCode := acct_rec.project_num;
					 END IF;
				END IF;
		      END IF;  ----SR14536

		      SplitAmount := LineRemainder;  --SR14536, existing, sets to full trans amount from data cursor
		      LineRemainder := 0;    --SR14536, new, to ensure stops processing and goes to next trans row..

		   ELSE
                       -- SR14536 HAVE SPLIT/ALLOCATIONS
                       IF ValidFID = 'N' THEN    --SR14536 ignore splits if AncilFID is not valid

 		          SplitAmount := LineRemainder;  --SR14536 sets to full trans amount from data cursor
 		          LineRemainder := 0;    --SR14536 to ensure stops processing and goes to next trans row..

   		       ELSE   --Ancil FID is valid so ok to process each split

                         -- SR14536 Split FAU validations added to acct_cur cursor
                         --         Existing amount settings below but now this block is no longer the logical else to when
                         --         there is an AncilFAU and ValidFID.
                         -----------------------------------------------
					-- in any situation where the remainder should simply be used,
					-- just use it rather than relying on the math to work out
				IF acct_rec.split_percent = 100 -- entire amount should be used
				   OR (acct_rec.split_percent IS NULL AND acct_rec.split_amount IS NULL) -- (ditto)
				   OR (acct_rec.split_amount IS NOT NULL AND acct_rec.split_amount > LineRemainder) -- if split amount > remaining
				   OR SplitNumber = NumSplits THEN -- OR last split, force use of remainder
					 SplitAmount := LineRemainder;
					 LineRemainder := 0;
				ELSE
					IF acct_rec.split_percent IS NOT NULL THEN
					   SplitAmount := ROUND( rec.trans_amt * (acct_rec.split_percent/100.00), 2 );
					ELSE
					   SplitAmount := ROUND( acct_rec.split_amount, 2 );
					END IF;

				LineRemainder := ROUND( LineRemainder - SplitAmount, 2 );
				END IF;

                       END IF;

		   END IF; -- SR14536 end on IF acct_rec.split_fid_provided = 'N'

		   --     Debit to the credit clearing account associated with the Campus.
		   write_feed_line(
		                          fh            => fh
		                        , fp            => fp
		                        , DocOriginCode => DocOriginCode
		                        , DocNum        => DocNum
		                        , DocType       => DocType
		                        , Chart         => acct_rec.credit_clearing_chart_num
		                        , Account       => acct_rec.credit_clearing_acct_num
		                        , ObjectCode    => CCardObject
		                        , BalanceType   => BalanceType
		                        , Description   => rec.reference_id||'-'||rec.ancillary_data
		                        , TrackingNum   => SUBSTR( rec.merchant_id, -7 )
		                        , LineReference => OrgReferenceNum
		                        , TransDate     => rec.settlement_date
		                        , TransAmt      => SplitAmount
		                       );
		   JournalLineCount := JournalLineCount + 1;

		   IF acct_rec.gift_merchant_ind = 'Y' THEN
                                      --SR14536 - no code mods here, is dependant on data in merch type table
                                      --        - Changing data for D merchant to gift_merchant_ind = 'N'
                                      --        - Expectation is that all merchant types except P, D will be gifts.

			        GiftProject := get_gift_project_code( acct_rec.merchant_type_code );

				-- If a foundation merchant, then use the fund ID in the GL transaction
	  			IF acct_rec.merchant_type_code IN ( 'F', 'N' ) THEN
	  				     OrgReferenceNum := SUBSTR( acct_rec.fund_id, 1, 8 );
  				END IF;

                                --SR14536 No Mods. Note: the FAU and email info for the merch type is set in the acct cursor
	  			--     Gift: Credit to the gift undistributed FAU appropriate for the type of gift transaction
				write_feed_line(
				                    fh            => fh
				                  , fp            => fp
				                  , DocOriginCode => DocOriginCode
				                  , DocNum        => DocNum
				                  , DocType       => DocType
				                  , Chart         => acct_rec.gift_undistrib_chart_num
				                  , Account       => acct_rec.gift_undistrib_acct_num
				                  , ObjectCode    => acct_rec.gift_undistrib_object_num
				                  , ProjectCode   => GiftProject
				                  , BalanceType   => BalanceType
				                  , Description   => rec.ancillary_data||'-'||rec.reference_id
				                  , TrackingNum   => SUBSTR( rec.merchant_id, -7 )
				                  , LineReference => OrgReferenceNum
				                  , TransDate     => rec.settlement_date
				                  , TransAmt      => -SplitAmount
					);
				JournalLineCount := JournalLineCount + 1;
		   END IF;


		   IF acct_rec.merchant_type_code = 'G' THEN -- gifts
					----------------------------------------------------------------------
					-- Regents Gift Handling
					----------------------------------------------------------------------
					-- call Gift Handling Procedure
                                --SR14536 No Mods except FID. Note: the do_gift_processing test is to allow for future possibility
                                --                       of no longer creating gift docs, without a code mod needed.
				IF acct_rec.do_gift_processing = 'Y'
                       	   	   AND SplitAmount > 0                            -- only create gift documents for debits
                           	   AND SplitAmount < acct_rec.gift_threshold_amt  -- under the given threshhold
                        	   THEN
					GiftDocNum := create_gift_document(
				                    MerchantID       => rec.merchant_id
				                  , FID              => acct_rec.fid    --SR14536 change to split FID, defaults to ancil FID if no split
				                  , SettleDate       => rec.settlement_date
				                  , ReferenceID      => rec.reference_id
				                  , AncillaryData    => rec.ancillary_data
				                  , TransDate        => rec.trans_date
				                  , TransAmt         => SplitAmount
				                  , CardType         => rec.card_type_code
				                  , GiftProject      => GiftProject
				                  , Chart            => Chart
				                  , Account          => Account
				                  , SubAccount       => SubAccount
				                  , SubObject        => acct_rec.sub_object_num
				                  , LineReference    => OrgReferenceNum
				                  , GiftInitiatorID  => acct_rec.gift_notification_dafis_id
				                  , fp               => fp
				                  , UndistChart      => acct_rec.gift_undistrib_chart_num
				                  , UndistAccount    => acct_rec.gift_undistrib_acct_num
				                  , UndistObject     => acct_rec.gift_undistrib_object_num
				                  , MerchantName     => rec.merchant_name
				                  );
				        GiftDocCount := GiftDocCount + 1;

                    		ELSE
					NULL;
				END IF;

		   ELSIF acct_rec.merchant_type_code = 'P' THEN
					----------------------------------------------------------------------
					-- Commerce Transaction Handling
					----------------------------------------------------------------------
					--     Non-Gift: Credit to the FAU specified in the translation table.
					write_feed_line(
				                    fh            => fh
				                  , fp            => fp
				                  , DocOriginCode => DocOriginCode
				                  , DocNum        => DocNum
				                  , DocType       => DocType
				                  , Chart         => Chart
				                  , Account       => Account
				                  , SubAccount    => SubAccount
				                  , ObjectCode    => acct_rec.object_num
				                  , SubObject     => acct_rec.sub_object_num
				                  , ProjectCode   => ProjectCode
				                  , BalanceType   => BalanceType
				                  , Description   => rec.ancillary_data||'-'||rec.reference_id
				                  , TrackingNum   => SUBSTR( rec.merchant_id, -7 )
				                  , LineReference => OrgReferenceNum
				                  , TransDate     => rec.settlement_date
				                  , TransAmt      => -SplitAmount
					);
					JournalLineCount := JournalLineCount + 1;

		   --SR14536 - add block to give credit in GLVJ when default handling due to invalid FID
		   --        - Dependent on the assumption that the data has been changed in merchant type
		   --        - table such that acct_rec.gift_merchant_ind = 'N' for merchant_type_code = 'D'
		   ELSIF acct_rec.merchant_type_code = 'D' THEN
					----------------------------------------------------------------------
					-- DEFAULT Transaction Handling - no gift processing,
                                        --                                Assumption is dash FID is type D and setup
                                        --                                to go to Internal Control FAU listed in the
                                        --                                merchant type table. Ignores FIDs FAU.
					----------------------------------------------------------------------
					--     DEFAULTS: Credit to the FAU specified in the merchant type for D table.
				write_feed_line(
				                    fh            => fh
				                  , fp            => fp
				                  , DocOriginCode => DocOriginCode
				                  , DocNum        => DocNum
				                  , DocType       => DocType
				                  , Chart         => acct_rec.gift_undistrib_chart_num
				                  , Account       => acct_rec.gift_undistrib_acct_num
				                  , ObjectCode    => acct_rec.gift_undistrib_object_num
						  , ProjectCode   => ProjectCode
						  , BalanceType   => BalanceType
						  , Description   => rec.ancillary_data||'-'||rec.reference_id
						  , TrackingNum   => SUBSTR( rec.merchant_id, -7 )
						  , LineReference => OrgReferenceNum
						  , TransDate     => rec.settlement_date
						  , TransAmt      => -SplitAmount
					);
				JournalLineCount := JournalLineCount + 1;

                                --SR14536 set GiftProject var for reference in email
                                GiftProject := ProjectCode;

		   ELSIF acct_rec.merchant_type_code = 'E' THEN
					----------------------------------------------------------------------
					-- Regents Endowment Gift Handling
					----------------------------------------------------------------------
					-- place in gift undist account
					-- no gift document
                                        -- SR14536 - note: CR to GLJV is done above based on acct_rec.gift_merchant_ind = 'Y'
					NULL;
		   ELSIF acct_rec.merchant_type_code = 'F' THEN
					----------------------------------------------------------------------
					-- Foundation Gift Handling
					----------------------------------------------------------------------
					-- just place in clearing account
					-- Phase 2: create ack document
                                        -- SR14536 - note: CR to GLJV is done above based on acct_rec.gift_merchant_ind = 'Y'
					NULL;
		   ELSIF acct_rec.merchant_type_code = 'N' THEN
					----------------------------------------------------------------------
					-- Foundation Endowment Gift Handling
					----------------------------------------------------------------------
					-- just place in clearing account
					-- Phase 2: create ack document
                                        -- SR14536 - note: CR to GLJV is done above based on acct_rec.gift_merchant_ind = 'Y'
					NULL;
		   END IF;

	BEGIN
		 GiftInitiatorID := acct_rec.gift_notification_dafis_id;

                  -- lookup the gift initiator
                  IF EMailDebugID IS NOT NULL THEN
                    GiftInitiatorID := EMailDebugID;
                  END IF;

                  BEGIN
                    --SR14989: include domain in email
                    SELECT u.emp_email_id||'@ucdavis.edu', u.person_first_nm||' '||u.person_last_nm
                      INTO EmailRecipient, EmailRecipientName
                      FROM fs_universal_usr_t u
                      WHERE person_unvl_id = GiftInitiatorID;
                  EXCEPTION
		     WHEN others THEN
                        EmailRecipient := NULL;
                  END;

                  --SR14536 Removed test and not_processed_email for when acct_rec.gift_merchant_ind = 'Y' AND acct_rec.do_gift_processing = 'N'
                  --        Gift GLEs are done so prefer merchant to get regular email even if no gift doc created.
                  --        Also added test against gift_threshold from v1.30 in cvs, not migrated to prod previously.
                  --        Note: if any merch type has a recipient on FID and normal_email_subject in type table they will get an email
		  IF SplitAmount > 0 AND SplitAmount < acct_rec.gift_threshold_amt AND acct_rec.normal_email_subject IS NOT NULL THEN
					EmailSubject := acct_rec.normal_email_subject;
					EmailBody    := acct_rec.normal_email_body;
		  ELSIF SplitAmount > 0 AND SplitAmount >= acct_rec.gift_threshold_amt AND acct_rec.over_threshold_email_subject IS NOT NULL THEN
					EmailSubject := acct_rec.over_threshold_email_subject;
					EmailBody    := acct_rec.over_threshold_email_body;
		  ELSIF SplitAmount < 0 AND acct_rec.credit_email_subject IS NOT NULL THEN
					EmailSubject := acct_rec.credit_email_subject;
					EmailBody    := acct_rec.credit_email_body;
		  END IF;

                  --SR14536 No Mods except amt. Note: this send email block is dependent on data in,
                  --        or not in, the merchant type table to control sending..
                  IF EMailRecipient IS NOT NULL AND EmailSubject IS NOT NULL THEN
		     send_parsed_email(
				 EmailFrom       => acct_rec.source_email_address
			       , SenderName      => 'Credit Card Processing'
			       , EmailRecipient     => EmailRecipient
			       , EmailRecipientName => EmailRecipientName
			       , EmailSubject    => EmailSubject
			       , EmailBody       => EmailBody
			       , GiftInitiatorID => GiftInitiatorID
			       , MerchantID      => rec.touchnet_merchant_id
			       , MerchantName    => rec.merchant_name
			       , TransDate       => rec.trans_date
			       , TransAmt        => SplitAmount        --rec.trans_amt - SR14536 should match gift doc and GLEs
			       , FID             => acct_rec.fid
			       , FIDName         => acct_rec.fid_short_name
			       , GiftProjectNum  => GiftProject
			       , GiftDocNum      => GiftDocNum
			       , DocNum          => DocNum
			       , ReferenceID     => rec.reference_id
			       , UndistAcctStr   => acct_rec.gift_undistrib_chart_num||'-'||acct_rec.gift_undistrib_acct_num
			       , AncillaryData   => rec.ancillary_data
			       , AcctStr         => acct_rec.chart_num||'-'||acct_rec.acct_num
                    	       , FundID          => acct_rec.fund_id
                    	       , FundName        => acct_rec.fund_name
                    	       , SettleDate      => rec.settlement_date
                    	       , GiftDocBaseURL  => acct_rec.gift_document_base_url
                    	       , TransTypeName   => acct_rec.merchant_type_name
                    	      );
		  END IF;

		  EXCEPTION
			WHEN OTHERS THEN
			        ErrorMessage := 'Error Sending Email' || CHR(10);
			        ErrorMessage := ErrorMessage ||'ORA'||SQLCODE||' - '||SQLERRM||CHR(10);
			        ErrorMessage := ErrorMessage ||'Merchant ID   : '||rec.touchnet_merchant_id||CHR(10);
			        ErrorMessage := ErrorMessage ||'Settle Date   : '||rec.settlement_date||CHR(10);
			        ErrorMessage := ErrorMessage ||'Reference ID  : '||rec.reference_id||CHR(10);
			        ErrorMessage := ErrorMessage ||'AcctRec FID   : '||acct_rec.fid||CHR(10); --SR14536 add FID
			        ErrorMessage := ErrorMessage ||'Amount        : '||SplitAmount||CHR(10);  --rec.trans_amt - SR14536
			        ErrorMessage := ErrorMessage ||'Ancillary Data: '||rec.ancillary_data||CHR(10);
			        ErrorMessage := ErrorMessage ||'GiftInitiatorID: '||GiftInitiatorID||CHR(10);
			        ErrorMessage := ErrorMessage ||'Gift Doc #    : '||GiftDocNum||CHR(10);
			        ErrorMessage := ErrorMessage ||'GiftProject   : '||GiftProject||CHR(10);  --SR14536 add project
			        ErrorMessage := ErrorMessage ||'Document #    : '||DocNum||CHR(10);
			        INSERT INTO cc_process_log_t ( action_code, message_text )
			          VALUES ( 'E', ErrorMessage );
		  END;

	   END IF;

  	END LOOP;  --end on ACCT CURSOR LOOP

        -- flush the lines to the file and commit to the database
        IF NOT DebugOutput THEN
          utl_file.fflush( fh );
        END IF;
        COMMIT;
      EXCEPTION
        WHEN others THEN
          ROLLBACK;
          ErrorCount := ErrorCount + 1;
          ErrorMessage := 'Error Processing Transaction' || CHR(10);
          ErrorMessage := ErrorMessage ||'ORA'||SQLCODE||' - '||SQLERRM||CHR(10);
          ErrorMessage := ErrorMessage ||'TN Merchant ID: '||rec.touchnet_merchant_id||CHR(10);
          ErrorMessage := ErrorMessage ||'Merchant ID   : '||rec.merchant_id||CHR(10);
          ErrorMessage := ErrorMessage ||'Settle Date   : '||rec.settlement_date||CHR(10);
          ErrorMessage := ErrorMessage ||'Reference ID  : '||rec.reference_id||CHR(10);
          ErrorMessage := ErrorMessage ||'Amount        : '||rec.trans_amt||CHR(10);
          ErrorMessage := ErrorMessage ||'Ancillary Data: '||rec.ancillary_data||CHR(10);
          INSERT INTO cc_process_log_t ( action_code, message_text, touchnet_records, journal_records, gift_docs_created, journal_total_amt, error_records )
            VALUES ( 'E', ErrorMessage, TransactionCount, JournalLineCount, GiftDocCount, TotalAmount, ErrorCount );
          COMMIT;
          ReturnValue := 4;
          IF DebugOutput THEN
            dbms_output.put_line(SUBSTR(ErrorMessage,1,255));
          END IF;
      END;
    END LOOP;

    close_feed_file( fh );

    INSERT INTO cc_process_log_t ( action_code, message_text, touchnet_records, journal_records, gift_docs_created, journal_total_amt, credit_records, error_records )
      VALUES ( 'D', 'Completed Extract', TransactionCount, JournalLineCount, GiftDocCount, TotalAmount, CreditRecords, ErrorCount );
    COMMIT;

    RETURN ReturnValue;
  EXCEPTION
    WHEN others THEN
      ROLLBACK;
      ErrorMessage := 'Error In Setup/Teardown' || CHR(10);
      ErrorMessage := ErrorMessage ||'ORA'||SQLCODE||' - '||SQLERRM||CHR(10);
      INSERT INTO cc_process_log_t ( action_code, message_text, touchnet_records, journal_records, gift_docs_created, journal_total_amt )
        VALUES ( 'E', ErrorMessage, TransactionCount, JournalLineCount, GiftDocCount, TotalAmount );
      COMMIT;
      RETURN 8;
  END import_transactions;

END cc_touchnet_interface_pk;
/
