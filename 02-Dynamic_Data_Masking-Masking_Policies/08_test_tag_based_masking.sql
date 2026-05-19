-- ============================================================
-- Step 8: Test Tag-Based Masking
-- ============================================================

-- Test 1: Query as LAB_ADMIN (full access)
USE ROLE LAB_ADMIN;
SELECT TRANSACTION_ID, HOTEL_NAME, CREDIT_CARD_NUMBER, ACCOUNT_NUMBER
FROM MASKING_LAB_DB.LAB_SCHEMA.HOTEL_REVENUE
LIMIT 5;
-- Expected: Full unmasked values

-- Test 2: Query as LAB_ANALYST (tag-based masking applied)
USE ROLE LAB_ANALYST;
SELECT TRANSACTION_ID, HOTEL_NAME, CREDIT_CARD_NUMBER, ACCOUNT_NUMBER
FROM MASKING_LAB_DB.LAB_SCHEMA.HOTEL_REVENUE
LIMIT 5;
-- Expected:
--   CREDIT_CARD_NUMBER -> **REDACTED**       (HIGH sensitivity)
--   ACCOUNT_NUMBER     -> ACC****            (MEDIUM sensitivity)

SELECT *
FROM TABLE(INFORMATION_SCHEMA.POLICY_REFERENCES(
    REF_ENTITY_DOMAIN => 'TABLE',
    REF_ENTITY_NAME => 'MASKING_LAB_DB.LAB_SCHEMA.HOTEL_REVENUE'
));
