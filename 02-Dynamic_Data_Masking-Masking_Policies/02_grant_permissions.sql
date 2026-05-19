-- ============================================================
-- Step 2: Grant permissions to test roles
-- ============================================================
-- Run with: LAB_ADMIN role
-- ============================================================

USE ROLE LAB_ADMIN;

GRANT USAGE ON DATABASE MASKING_LAB_DB TO ROLE LAB_ANALYST;
GRANT USAGE ON SCHEMA MASKING_LAB_DB.LAB_SCHEMA TO ROLE LAB_ANALYST;
GRANT SELECT ON TABLE MASKING_LAB_DB.LAB_SCHEMA.HOTEL_REVENUE TO ROLE LAB_ANALYST;
