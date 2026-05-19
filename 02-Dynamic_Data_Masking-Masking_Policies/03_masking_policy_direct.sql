-- ============================================================
-- Step 3: Direct Column Masking Policy
-- ============================================================
-- This approach applies a masking policy DIRECTLY to a column.
-- Simpler, good for protecting individual columns.
-- Run with: LAB_ADMIN role
-- ============================================================

USE ROLE LAB_ADMIN;
USE DATABASE MASKING_LAB_DB;
USE SCHEMA LAB_SCHEMA;

CREATE OR REPLACE MASKING POLICY mask_credit_card
AS (val VARCHAR) RETURNS VARCHAR ->
    CASE
        WHEN CURRENT_ROLE() IN ('LAB_ADMIN') THEN val
        ELSE CONCAT('XXXX-XXXX-XXXX-', RIGHT(REPLACE(val, '-', ''), 4))
    END;

CREATE OR REPLACE MASKING POLICY mask_account_number
AS (val VARCHAR) RETURNS VARCHAR ->
    CASE
        WHEN CURRENT_ROLE() IN ('LAB_ADMIN') THEN val
        WHEN CURRENT_ROLE() IN ('LAB_ANALYST') THEN CONCAT('ACC-****-', RIGHT(val, 5))
        ELSE '**REDACTED**'
    END;

ALTER TABLE HOTEL_REVENUE MODIFY COLUMN CREDIT_CARD_NUMBER
    SET MASKING POLICY mask_credit_card;

ALTER TABLE HOTEL_REVENUE MODIFY COLUMN ACCOUNT_NUMBER
    SET MASKING POLICY mask_account_number;

SELECT * FROM TABLE(INFORMATION_SCHEMA.POLICY_REFERENCES(
    REF_ENTITY_DOMAIN => 'TABLE',
    REF_ENTITY_NAME => 'MASKING_LAB_DB.LAB_SCHEMA.HOTEL_REVENUE'
));
