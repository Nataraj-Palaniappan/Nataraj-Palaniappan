-- ============================================================
-- FILE: 02_create_tags.sql
-- NOTE: In this exercise, the tags serve only as **metadata/documentation** 
-- The TAGs label the table/column as "region_controlled" for governance visibility. 
-- They do NOT enforce the row access policy.
-- ============================================================

USE ROLE SYSADMIN;
USE DATABASE HOSPITALITY_DB;
USE SCHEMA HOSPITALITY_DB.FINANCE;

-- ============================================================
-- Step 1: Create a TAG for Row Access Policy binding
-- Tags are used to associate a row access policy with
-- any table that carries this tag — no manual ALTER needed.
-- ============================================================

CREATE OR REPLACE TAG rap_region_tag
  COMMENT = 'Tag to bind region-based row access policy to tables';

-- ============================================================
-- Step 2: Grant TAG usage to roles
-- ============================================================
USE ROLE SECURITYADMIN;

GRANT APPLY ON TAG HOSPITALITY_DB.FINANCE.rap_region_tag
  TO ROLE ROLE_FINANCE_ADMIN;
