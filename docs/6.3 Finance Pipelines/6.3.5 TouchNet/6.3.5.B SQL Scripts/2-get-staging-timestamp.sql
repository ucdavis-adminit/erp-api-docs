-- Query Parameters
-- 1. IntDB staging schema

SELECT TO_CHAR(MAX(trans_date), 'YYYY-MM-DD HH24:MI:SS') AS last_transaction FROM %s.tn_transactions
