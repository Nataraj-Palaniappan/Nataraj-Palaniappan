-- ============================================================
-- Step 9: Full Cleanup
-- ============================================================
-- Run with: LAB_ADMIN role
-- ============================================================

USE ROLE LAB_ADMIN;
USE DATABASE MASKING_LAB_DB;
USE SCHEMA LAB_SCHEMA;

ALTER TABLE HOTEL_REVENUE MODIFY COLUMN CREDIT_CARD_NUMBER UNSET TAG pii_sensitivity;
ALTER TABLE HOTEL_REVENUE MODIFY COLUMN ACCOUNT_NUMBER UNSET TAG pii_sensitivity;

ALTER TAG pii_sensitivity UNSET MASKING POLICY tag_mask_string;

DROP MASKING POLICY IF EXISTS tag_mask_string;
DROP MASKING POLICY IF EXISTS mask_credit_card;
DROP MASKING POLICY IF EXISTS mask_account_number;

DROP TAG IF EXISTS pii_sensitivity;

DROP TABLE IF EXISTS HOTEL_REVENUE;
DROP SCHEMA IF EXISTS LAB_SCHEMA;
DROP DATABASE IF EXISTS MASKING_LAB_DB;

-- Optional: Drop roles (run as ACCOUNTADMIN)
-- USE ROLE ACCOUNTADMIN;
-- DROP ROLE IF EXISTS LAB_ADMIN;
-- DROP ROLE IF EXISTS LAB_ANALYST;
-- DROP WAREHOUSE IF EXISTS LAB_WAREHOUSE;
