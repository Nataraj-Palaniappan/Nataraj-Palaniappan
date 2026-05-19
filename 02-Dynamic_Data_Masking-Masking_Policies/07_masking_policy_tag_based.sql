-- ============================================================
-- Step 7: Tag-Based Masking Policy
-- ============================================================
-- This approach attaches masking policies to a TAG.
-- Any column tagged automatically inherits the masking.
-- Scalable: add the tag to any new column/table and masking
-- is applied automatically without extra ALTER TABLE statements.
-- Run with: LAB_ADMIN role
-- ============================================================

USE ROLE LAB_ADMIN;
USE DATABASE MASKING_LAB_DB;
USE SCHEMA LAB_SCHEMA;

CREATE OR REPLACE MASKING POLICY tag_mask_string
AS (val VARCHAR) RETURNS VARCHAR ->
    CASE
        WHEN CURRENT_ROLE() IN ('LAB_ADMIN') THEN val
        WHEN SYSTEM$GET_TAG_ON_CURRENT_COLUMN('MASKING_LAB_DB.LAB_SCHEMA.pii_sensitivity') = 'HIGH'
            THEN '**REDACTED**'
        WHEN SYSTEM$GET_TAG_ON_CURRENT_COLUMN('MASKING_LAB_DB.LAB_SCHEMA.pii_sensitivity') = 'MEDIUM'
            THEN CONCAT(LEFT(val, 3), '****')
        ELSE val
    END;

ALTER TAG pii_sensitivity SET MASKING POLICY tag_mask_string;

ALTER TABLE HOTEL_REVENUE MODIFY COLUMN CREDIT_CARD_NUMBER
    SET TAG pii_sensitivity = 'HIGH';

ALTER TABLE HOTEL_REVENUE MODIFY COLUMN ACCOUNT_NUMBER
    SET TAG pii_sensitivity = 'MEDIUM';
