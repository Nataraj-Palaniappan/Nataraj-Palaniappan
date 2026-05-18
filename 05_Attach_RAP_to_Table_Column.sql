-- ============================================================
-- FILE: 05_Attach_RAP_to_Table_Column.sql
-- PURPOSE: Attach the row access policy to the table using TAGS
--
-- WHY TAGS?
--   Instead of manually ALTERing every table, we:
--   1. Assign a TAG to the table
--   2. Bind the RAP to that TAG
--   → Any future table with the tag auto-inherits the policy!
-- ============================================================

USE ROLE SYSADMIN;
USE DATABASE HOSPITALITY_DB;
USE SCHEMA HOSPITALITY_DB.FINANCE;

-- ============================================================
-- Step 1: Assign the tag to the table
-- ============================================================
ALTER TABLE hotel_revenue
  SET TAG rap_region_tag = 'region_controlled';

-- Verify tag assignment
SELECT *
FROM TABLE(HOSPITALITY_DB.INFORMATION_SCHEMA.TAG_REFERENCES(
    'HOSPITALITY_DB.FINANCE.hotel_revenue', 'TABLE'
));

-- ============================================================
-- Step 2: Bind the Row Access Policy to the table. 
-- (Note: You cannot attach a row access policy directly to a tag in the same way as masking policies.
-- Snowflake only supports masking policies on tags via ALTER TAG ... SET MASKING POLICY)
--         Column mapped: "region" column in the table
-- ============================================================

USE ROLE SYSADMIN;

ALTER TABLE HOSPITALITY_DB.FINANCE.HOTEL_REVENUE
  ADD ROW ACCESS POLICY rap_region_filter ON (REGION);-- maps the policy param to the "region" column

-- ============================================================
-- Step 3: Verify policy is applied 
-- ============================================================

--Switch to any other role & run select statement. 

USE ROLE ROLE_REGION_APAC;
SELECT * FROM HOSPITALITY_DB.FINANCE.HOTEL_REVENUE; --This should return only the 5 rows corresponding to the APAC region.

USE ROLE ROLE_REGION_EMEA;
SELECT * FROM HOSPITALITY_DB.FINANCE.HOTEL_REVENUE; --This should return only the 5 rows corresponding to the EMEA region.
