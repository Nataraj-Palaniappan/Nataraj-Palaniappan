-- ============================================================
-- Step 4: Test Direct Column Masking
-- ============================================================

-- Test 1: Query as LAB_ADMIN (full access)
USE ROLE LAB_ADMIN;
SELECT TRANSACTION_ID, HOTEL_NAME, CREDIT_CARD_NUMBER, ACCOUNT_NUMBER
FROM MASKING_LAB_DB.LAB_SCHEMA.HOTEL_REVENUE
LIMIT 5;
-- Expected: Full unmasked values visible

-- Test 2: Query as LAB_ANALYST (partial mask)
USE ROLE LAB_ANALYST;
SELECT TRANSACTION_ID, HOTEL_NAME, CREDIT_CARD_NUMBER, ACCOUNT_NUMBER
FROM MASKING_LAB_DB.LAB_SCHEMA.HOTEL_REVENUE
LIMIT 5;
-- Expected:
--   CREDIT_CARD_NUMBER -> XXXX-XXXX-XXXX-1111
--   ACCOUNT_NUMBER     -> ACC-****-00101
