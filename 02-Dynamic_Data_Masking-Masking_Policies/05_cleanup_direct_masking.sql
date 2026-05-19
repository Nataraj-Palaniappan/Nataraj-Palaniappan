-- ============================================================
-- Step 5: Remove Direct Masking (before applying Tag-Based)
-- ============================================================
-- Must remove direct masking before testing tag-based approach
-- Run with: LAB_ADMIN role
-- ============================================================

USE ROLE LAB_ADMIN;
USE DATABASE MASKING_LAB_DB;
USE SCHEMA LAB_SCHEMA;

ALTER TABLE HOTEL_REVENUE MODIFY COLUMN CREDIT_CARD_NUMBER
    UNSET MASKING POLICY;

ALTER TABLE HOTEL_REVENUE MODIFY COLUMN ACCOUNT_NUMBER
    UNSET MASKING POLICY;

SELECT * FROM TABLE(INFORMATION_SCHEMA.POLICY_REFERENCES(
    REF_ENTITY_DOMAIN => 'TABLE',
    REF_ENTITY_NAME => 'MASKING_LAB_DB.LAB_SCHEMA.HOTEL_REVENUE'
));
