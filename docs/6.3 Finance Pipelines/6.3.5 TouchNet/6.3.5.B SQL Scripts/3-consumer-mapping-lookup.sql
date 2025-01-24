-- Query parameters
-- 1. intdb api schema
-- 2. consumer id

SELECT * FROM %s.consumer_mapping WHERE consumer_id = '%s' AND enabled_flag = 'Y'
