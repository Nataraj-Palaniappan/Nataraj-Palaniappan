-- ============================================================
-- Step 6: Create Tag for Tag-Based Masking
-- ============================================================
-- Tags allow you to attach a masking policy to a tag, then
-- any column with that tag gets automatically masked.
-- Run with: LAB_ADMIN role
-- ============================================================

USE ROLE LAB_ADMIN;
USE DATABASE MASKING_LAB_DB;
USE SCHEMA LAB_SCHEMA;

CREATE OR REPLACE TAG pii_sensitivity
    COMMENT = 'Classifies PII sensitivity level for automatic masking';
