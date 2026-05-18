-- ============================================================
-- FILE: 02_create_tags.sql
-- PURPOSE: Create tags used to attach row access policies
--          to tables/columns via tag-based policies
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

GRANT USAGE ON TAG HOSPITALITY_DB.FINANCE.rap_region_tag
  TO ROLE ROLE_FINANCE_ADMIN;
