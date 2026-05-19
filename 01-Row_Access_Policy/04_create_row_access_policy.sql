-- ============================================================
-- FILE: 04_create_row_access_policy.sql
-- PURPOSE: Create the Row Access Policy with region-based logic
-- ============================================================

USE ROLE SYSADMIN;
USE DATABASE HOSPITALITY_DB;
USE SCHEMA HOSPITALITY_DB.FINANCE;

-- ============================================================
-- Row Access Policy Logic:
--   - ROLE_FINANCE_ADMIN  → sees ALL rows
--   - ROLE_REGION_APAC    → sees only APAC rows
--   - ROLE_REGION_EMEA    → sees only EMEA rows
--   - ROLE_REGION_AMER    → sees only AMER rows
--   - Any other role      → sees NO rows
-- ============================================================

CREATE OR REPLACE ROW ACCESS POLICY rap_region_filter
AS (row_region VARCHAR) RETURNS BOOLEAN ->
    CASE
        -- Admin sees everything
        WHEN CURRENT_ROLE() = 'ROLE_FINANCE_ADMIN' THEN TRUE

        -- Region-specific access
        WHEN CURRENT_ROLE() = 'ROLE_REGION_APAC' AND row_region = 'APAC' THEN TRUE
        WHEN CURRENT_ROLE() = 'ROLE_REGION_EMEA' AND row_region = 'EMEA' THEN TRUE
        WHEN CURRENT_ROLE() = 'ROLE_REGION_AMER' AND row_region = 'AMER' THEN TRUE

        -- Default: deny
        ELSE FALSE
    END;

-- Verify policy created
SHOW ROW ACCESS POLICIES;

-- ============================================================
-- Grant usage on the policy for tag binding
-- ============================================================
USE ROLE SECURITYADMIN;

GRANT APPLY ON ROW ACCESS POLICY HOSPITALITY_DB.FINANCE.rap_region_filter
  TO ROLE SYSADMIN;
