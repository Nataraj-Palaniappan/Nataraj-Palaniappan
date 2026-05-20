-- ============================================================================
-- RBAC & PRIVILEGE MANAGEMENT LAB
-- ============================================================================
-- This lab uses a dedicated database, schema, and role for isolation.
-- Run SECTION 0 (Setup) first with SYSADMIN or equivalent.
-- ============================================================================


-- ============================================================================
-- SECTION 0: SETUP (Run as SYSADMIN or role with CREATE DATABASE/ROLE)
-- ============================================================================

USE ROLE SYSADMIN;
USE SECONDARY ROLES NONE;

CREATE DATABASE IF NOT EXISTS RBAC_LAB_DB;
CREATE SCHEMA IF NOT EXISTS RBAC_LAB_DB.RBAC_LAB_SCHEMA;

USE ROLE SECURITYADMIN;
USE SECONDARY ROLES NONE;

CREATE ROLE IF NOT EXISTS RBAC_LAB_OWNER;
GRANT ROLE RBAC_LAB_OWNER TO ROLE SYSADMIN;
GRANT ROLE RBAC_LAB_OWNER TO USER NATARAJ_PALANIAPPAN;

USE ROLE SYSADMIN;
USE SECONDARY ROLES NONE;
GRANT OWNERSHIP ON DATABASE RBAC_LAB_DB TO ROLE RBAC_LAB_OWNER COPY CURRENT GRANTS;
GRANT OWNERSHIP ON SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA TO ROLE RBAC_LAB_OWNER COPY CURRENT GRANTS;

USE ROLE SECURITYADMIN;
USE SECONDARY ROLES NONE;
GRANT CREATE ROLE ON ACCOUNT TO ROLE RBAC_LAB_OWNER;
GRANT MANAGE GRANTS ON ACCOUNT TO ROLE RBAC_LAB_OWNER;

CREATE WAREHOUSE IF NOT EXISTS RBAC_LAB_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;
GRANT USAGE ON WAREHOUSE RBAC_LAB_WH TO ROLE RBAC_LAB_OWNER;


-- ============================================================================
-- SECTION 1: UNDERSTANDING YOUR CURRENT ROLE & PRIVILEGES
-- ============================================================================

USE ROLE RBAC_LAB_OWNER;
USE SECONDARY ROLES NONE;
USE WAREHOUSE RBAC_LAB_WH;
USE RBAC_LAB_DB.RBAC_LAB_SCHEMA;

-- 1.1 Check your current session context
SELECT CURRENT_ROLE(), CURRENT_USER(), CURRENT_DATABASE(), CURRENT_SCHEMA(), CURRENT_WAREHOUSE();

-- 1.2 List all roles granted to your user
SHOW GRANTS TO USER NATARAJ_PALANIAPPAN;

-- 1.3 View privileges granted to your current role
SHOW GRANTS TO ROLE RBAC_LAB_OWNER;

-- 1.4 View the role hierarchy (what roles are granted to your role)
SHOW GRANTS OF ROLE RBAC_LAB_OWNER;

-- 1.5 Check what roles exist in the account
SHOW ROLES;


-- ============================================================================
-- SECTION 2: INSPECTING OBJECT-LEVEL PRIVILEGES
-- ============================================================================

-- 2.1 View privileges on the database
SHOW GRANTS ON DATABASE RBAC_LAB_DB;

-- 2.2 View privileges on the schema
SHOW GRANTS ON SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA;

-- 2.3 View grants on a specific table
-- (After creating tables later, run: SHOW GRANTS ON TABLE RBAC_LAB_DB.RBAC_LAB_SCHEMA.<TABLE_NAME>;)
SHOW TABLES IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA;

-- 2.4 View future grants defined on the schema
SHOW FUTURE GRANTS IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA;

-- 2.5 View future grants defined at the database level
SHOW FUTURE GRANTS IN DATABASE RBAC_LAB_DB;


-- ============================================================================
-- SECTION 3: CREATING ROLES & BUILDING A ROLE HIERARCHY
-- ============================================================================

-- 3.1 Create access roles (object-level permissions)
CREATE ROLE IF NOT EXISTS RBAC_LAB_READ;
CREATE ROLE IF NOT EXISTS RBAC_LAB_WRITE;
CREATE ROLE IF NOT EXISTS RBAC_LAB_ADMIN;

-- 3.2 Create functional roles (business-level groupings)
CREATE ROLE IF NOT EXISTS RBAC_LAB_ANALYST;
CREATE ROLE IF NOT EXISTS RBAC_LAB_ENGINEER;
CREATE ROLE IF NOT EXISTS RBAC_LAB_DBA;

-- 3.3 Build the access role hierarchy: READ -> WRITE -> ADMIN
GRANT ROLE RBAC_LAB_READ TO ROLE RBAC_LAB_WRITE;
GRANT ROLE RBAC_LAB_WRITE TO ROLE RBAC_LAB_ADMIN;

-- 3.4 Build the functional role hierarchy: access roles -> functional roles
GRANT ROLE RBAC_LAB_READ TO ROLE RBAC_LAB_ANALYST;
GRANT ROLE RBAC_LAB_WRITE TO ROLE RBAC_LAB_ENGINEER;
GRANT ROLE RBAC_LAB_ADMIN TO ROLE RBAC_LAB_DBA;

-- 3.5 Connect functional roles to SYSADMIN (best practice)
GRANT ROLE RBAC_LAB_ANALYST TO ROLE SYSADMIN;
GRANT ROLE RBAC_LAB_ENGINEER TO ROLE SYSADMIN;
GRANT ROLE RBAC_LAB_DBA TO ROLE SYSADMIN;

-- 3.6 Grant warehouse usage to all access roles (so functional roles inherit it)
GRANT USAGE ON WAREHOUSE RBAC_LAB_WH TO ROLE RBAC_LAB_READ;

-- 3.7 Verify the hierarchy
SHOW GRANTS OF ROLE RBAC_LAB_READ;
SHOW GRANTS OF ROLE RBAC_LAB_DBA;


-- ============================================================================
-- SECTION 4: GRANTING PRIVILEGES TO ACCESS ROLES
-- ============================================================================

-- 4.1 Grant database & schema USAGE to the read role (WRITE and ADMIN inherit this)
GRANT USAGE ON DATABASE RBAC_LAB_DB TO ROLE RBAC_LAB_READ;
GRANT USAGE ON SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA TO ROLE RBAC_LAB_READ;

-- 4.2 Grant SELECT on all existing tables to the read role
GRANT SELECT ON ALL TABLES IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA TO ROLE RBAC_LAB_READ;

-- 4.3 Grant DML privileges to the write role (inherits USAGE + SELECT from READ)
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA TO ROLE RBAC_LAB_WRITE;

-- 4.4 Grant DDL privileges to the admin role (inherits everything from WRITE & READ)
GRANT CREATE TABLE ON SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA TO ROLE RBAC_LAB_ADMIN;
GRANT CREATE VIEW ON SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA TO ROLE RBAC_LAB_ADMIN;

-- 4.5 Verify grants on the access roles
SHOW GRANTS TO ROLE RBAC_LAB_READ;
SHOW GRANTS TO ROLE RBAC_LAB_WRITE;
SHOW GRANTS TO ROLE RBAC_LAB_ADMIN;


-- ============================================================================
-- SECTION 5: FUTURE GRANTS (AUTO-APPLY TO NEW OBJECTS)
-- ============================================================================

-- 5.1 Grant SELECT on all future tables to the read role
GRANT SELECT ON FUTURE TABLES IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA TO ROLE RBAC_LAB_READ;

-- 5.2 Grant SELECT on all future views to the read role
GRANT SELECT ON FUTURE VIEWS IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA TO ROLE RBAC_LAB_READ;

-- 5.3 Grant DML on future tables to the write role
GRANT INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA TO ROLE RBAC_LAB_WRITE;

-- 5.4 Verify future grants
SHOW FUTURE GRANTS IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA;

-- 5.5 Test: create a table and verify future grants took effect
USE ROLE RBAC_LAB_DBA;
USE SECONDARY ROLES NONE;
USE WAREHOUSE RBAC_LAB_WH;
CREATE OR REPLACE TABLE RBAC_LAB_DB.RBAC_LAB_SCHEMA.RBAC_LAB_TEST_TABLE (
    ID INT,
    NAME VARCHAR(100),
    CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Check: the read role should automatically have SELECT
SHOW GRANTS ON TABLE RBAC_LAB_DB.RBAC_LAB_SCHEMA.RBAC_LAB_TEST_TABLE;


-- ============================================================================
-- SECTION 6: ASSIGNING ROLES TO USERS
-- ============================================================================

-- 6.1 Grant functional role to a user
USE ROLE RBAC_LAB_OWNER;
USE SECONDARY ROLES NONE;
GRANT ROLE RBAC_LAB_ANALYST TO USER NATARAJ_PALANIAPPAN;
GRANT ROLE RBAC_LAB_ENGINEER TO USER NATARAJ_PALANIAPPAN;
GRANT ROLE RBAC_LAB_DBA TO USER NATARAJ_PALANIAPPAN;

-- 6.2 Verify roles assigned to the user
SHOW GRANTS TO USER NATARAJ_PALANIAPPAN;

-- 6.3 Test: switch to the analyst role and verify access
USE ROLE RBAC_LAB_ANALYST;
USE SECONDARY ROLES NONE;
USE WAREHOUSE RBAC_LAB_WH;
SELECT CURRENT_ROLE();

-- Should succeed (analyst has read access via RBAC_LAB_READ)
SELECT * FROM RBAC_LAB_DB.RBAC_LAB_SCHEMA.RBAC_LAB_TEST_TABLE LIMIT 5;

-- Should FAIL (analyst does NOT have write access)
-- INSERT INTO RBAC_LAB_DB.RBAC_LAB_SCHEMA.RBAC_LAB_TEST_TABLE (ID, NAME) VALUES (1, 'test');

-- 6.4 Test: switch to engineer role and verify write access
USE ROLE RBAC_LAB_ENGINEER;
USE SECONDARY ROLES NONE;
USE WAREHOUSE RBAC_LAB_WH;
INSERT INTO RBAC_LAB_DB.RBAC_LAB_SCHEMA.RBAC_LAB_TEST_TABLE (ID, NAME) VALUES (1, 'Engineer Test');
SELECT * FROM RBAC_LAB_DB.RBAC_LAB_SCHEMA.RBAC_LAB_TEST_TABLE;


-- ============================================================================
-- SECTION 7: REVOKING PRIVILEGES
-- ============================================================================

USE ROLE RBAC_LAB_OWNER;
USE SECONDARY ROLES NONE;

-- 7.1 Revoke a specific privilege
REVOKE DELETE ON ALL TABLES IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA FROM ROLE RBAC_LAB_WRITE;

-- 7.2 Verify the revocation
SHOW GRANTS TO ROLE RBAC_LAB_WRITE;

-- 7.3 Revoke future grants
REVOKE INSERT ON FUTURE TABLES IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA FROM ROLE RBAC_LAB_WRITE;

-- 7.4 Verify future grants after revocation
SHOW FUTURE GRANTS IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA;


-- ============================================================================
-- SECTION 8: WITH GRANT OPTION (DELEGATED ADMINISTRATION)
-- ============================================================================

USE ROLE RBAC_LAB_OWNER;
USE SECONDARY ROLES NONE;

-- 8.1 Grant a privilege WITH GRANT OPTION (allows re-granting)
GRANT SELECT ON ALL TABLES IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA TO ROLE RBAC_LAB_DBA WITH GRANT OPTION;

-- 8.2 Now the DBA role can grant that privilege to other roles
USE ROLE RBAC_LAB_DBA;
USE SECONDARY ROLES NONE;
USE WAREHOUSE RBAC_LAB_WH;
GRANT SELECT ON TABLE RBAC_LAB_DB.RBAC_LAB_SCHEMA.RBAC_LAB_TEST_TABLE TO ROLE RBAC_LAB_ANALYST;


-- ============================================================================
-- SECTION 9: MANAGED ACCESS SCHEMAS
-- ============================================================================

-- 9.1 Create a managed access schema (centralizes grant control)
USE ROLE RBAC_LAB_OWNER;
USE SECONDARY ROLES NONE;
USE WAREHOUSE RBAC_LAB_WH;
CREATE SCHEMA IF NOT EXISTS RBAC_LAB_DB.RBAC_LAB_MANAGED WITH MANAGED ACCESS;

-- 9.2 In a managed access schema, ONLY the schema owner or MANAGE GRANTS can grant
-- Object owners CANNOT grant access to their own objects (more secure)
GRANT USAGE ON SCHEMA RBAC_LAB_DB.RBAC_LAB_MANAGED TO ROLE RBAC_LAB_READ;

-- 9.3 Create a table in the managed schema
CREATE TABLE RBAC_LAB_DB.RBAC_LAB_MANAGED.SECURE_DATA (
    ID INT,
    SENSITIVE_INFO VARCHAR(200)
);

-- 9.4 Grant SELECT (only schema owner can do this in managed access)
GRANT SELECT ON TABLE RBAC_LAB_DB.RBAC_LAB_MANAGED.SECURE_DATA TO ROLE RBAC_LAB_READ;

-- 9.5 Test: switch to a non-owner role and try to grant (should FAIL)
USE ROLE RBAC_LAB_DBA;
USE SECONDARY ROLES NONE;
USE WAREHOUSE RBAC_LAB_WH;
-- This will FAIL because RBAC_LAB_DBA is not the schema owner in managed access
-- GRANT SELECT ON TABLE RBAC_LAB_DB.RBAC_LAB_MANAGED.SECURE_DATA TO ROLE RBAC_LAB_ENGINEER;

-- 9.6 Verify
USE ROLE RBAC_LAB_OWNER;
USE SECONDARY ROLES NONE;
SHOW GRANTS ON SCHEMA RBAC_LAB_DB.RBAC_LAB_MANAGED;


-- ============================================================================
-- SECTION 10: MONITORING & AUDITING PRIVILEGES
-- ============================================================================

-- 10.1 Query GRANTS_TO_ROLES view for audit (requires ACCOUNTADMIN or SNOWFLAKE DB access)
-- SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_ROLES
-- WHERE GRANTEE_NAME = 'RBAC_LAB_DBA'
-- ORDER BY CREATED_ON DESC
-- LIMIT 20;

-- 10.2 Check login history for a user
-- SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
-- WHERE USER_NAME = 'NATARAJ_PALANIAPPAN'
-- ORDER BY EVENT_TIMESTAMP DESC
-- LIMIT 10;

-- 10.3 Use SHOW commands as an alternative (works with current role)
SHOW GRANTS TO ROLE RBAC_LAB_DBA;
SHOW GRANTS TO ROLE RBAC_LAB_ANALYST;
SHOW GRANTS TO ROLE RBAC_LAB_ENGINEER;

-- 10.4 Check all grants on a specific object
SHOW GRANTS ON TABLE RBAC_LAB_DB.RBAC_LAB_SCHEMA.RBAC_LAB_TEST_TABLE;


-- ============================================================================
-- SECTION 11: DATABASE ROLES (SCOPED ALTERNATIVE TO ACCOUNT ROLES)
-- ============================================================================
-- Database roles are scoped to a single database. They are commonly used for:
-- * Sharing (database roles can be granted to shares, account roles cannot)
-- * Simplifying privilege management within a database
-- * They are NOT a universal standard, but increasingly adopted for data sharing
--   and for teams that want tighter scoping per database.

-- 11.1 Create database roles (scoped to RBAC_LAB_DB)
USE ROLE RBAC_LAB_OWNER;
USE SECONDARY ROLES NONE;
USE WAREHOUSE RBAC_LAB_WH;
CREATE DATABASE ROLE IF NOT EXISTS RBAC_LAB_DB.RBAC_LAB_DB_READER;
CREATE DATABASE ROLE IF NOT EXISTS RBAC_LAB_DB.RBAC_LAB_DB_WRITER;

-- 11.2 Grant privileges to the database roles
GRANT USAGE ON SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA TO DATABASE ROLE RBAC_LAB_DB.RBAC_LAB_DB_READER;
GRANT SELECT ON ALL TABLES IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA TO DATABASE ROLE RBAC_LAB_DB.RBAC_LAB_DB_READER;
GRANT SELECT ON FUTURE TABLES IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA TO DATABASE ROLE RBAC_LAB_DB.RBAC_LAB_DB_READER;

GRANT USAGE ON SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA TO DATABASE ROLE RBAC_LAB_DB.RBAC_LAB_DB_WRITER;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA TO DATABASE ROLE RBAC_LAB_DB.RBAC_LAB_DB_WRITER;
GRANT INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA TO DATABASE ROLE RBAC_LAB_DB.RBAC_LAB_DB_WRITER;

-- 11.3 Build hierarchy: DB_READER -> DB_WRITER (writer inherits read)
GRANT DATABASE ROLE RBAC_LAB_DB.RBAC_LAB_DB_READER TO DATABASE ROLE RBAC_LAB_DB.RBAC_LAB_DB_WRITER;

-- 11.4 Grant database role to an account role (bridges DB role -> account role)
GRANT DATABASE ROLE RBAC_LAB_DB.RBAC_LAB_DB_READER TO ROLE RBAC_LAB_ANALYST;
GRANT DATABASE ROLE RBAC_LAB_DB.RBAC_LAB_DB_WRITER TO ROLE RBAC_LAB_ENGINEER;

-- 11.5 Verify database roles
SHOW DATABASE ROLES IN DATABASE RBAC_LAB_DB;
SHOW GRANTS TO DATABASE ROLE RBAC_LAB_DB.RBAC_LAB_DB_READER;
SHOW GRANTS TO DATABASE ROLE RBAC_LAB_DB.RBAC_LAB_DB_WRITER;

-- 11.6 Key differences: Database Roles vs Account Roles
-- +-------------------------+----------------------------------------------+
-- | Account Roles           | Database Roles                               |
-- +-------------------------+----------------------------------------------+
-- | Global scope            | Scoped to one database                       |
-- | Cannot be shared        | CAN be granted to shares (data sharing)      |
-- | Visible across account  | Only visible within their database           |
-- | Granted to users        | Cannot be granted directly to users          |
-- |                         | (must go through an account role)             |
-- +-------------------------+----------------------------------------------+


-- ============================================================================
-- SECTION 12: CLEANUP
-- ============================================================================

USE ROLE RBAC_LAB_OWNER;
USE SECONDARY ROLES NONE;

-- 12.1 Revoke future grants first
REVOKE SELECT ON FUTURE TABLES IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA FROM ROLE RBAC_LAB_READ;
REVOKE SELECT ON FUTURE VIEWS IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA FROM ROLE RBAC_LAB_READ;
REVOKE UPDATE, DELETE ON FUTURE TABLES IN SCHEMA RBAC_LAB_DB.RBAC_LAB_SCHEMA FROM ROLE RBAC_LAB_WRITE;

-- 12.2 Drop database roles
DROP DATABASE ROLE IF EXISTS RBAC_LAB_DB.RBAC_LAB_DB_WRITER;
DROP DATABASE ROLE IF EXISTS RBAC_LAB_DB.RBAC_LAB_DB_READER;

-- 12.3 Drop test objects
DROP TABLE IF EXISTS RBAC_LAB_DB.RBAC_LAB_SCHEMA.RBAC_LAB_TEST_TABLE;
DROP SCHEMA IF EXISTS RBAC_LAB_DB.RBAC_LAB_MANAGED;

-- 12.4 Revoke role assignments from user
REVOKE ROLE RBAC_LAB_ANALYST FROM USER NATARAJ_PALANIAPPAN;
REVOKE ROLE RBAC_LAB_ENGINEER FROM USER NATARAJ_PALANIAPPAN;
REVOKE ROLE RBAC_LAB_DBA FROM USER NATARAJ_PALANIAPPAN;

-- 12.5 Drop functional roles
DROP ROLE IF EXISTS RBAC_LAB_DBA;
DROP ROLE IF EXISTS RBAC_LAB_ENGINEER;
DROP ROLE IF EXISTS RBAC_LAB_ANALYST;

-- 12.6 Drop access roles
DROP ROLE IF EXISTS RBAC_LAB_ADMIN;
DROP ROLE IF EXISTS RBAC_LAB_WRITE;
DROP ROLE IF EXISTS RBAC_LAB_READ;

-- 12.7 Drop lab infrastructure
USE ROLE SYSADMIN;
USE SECONDARY ROLES NONE;
DROP DATABASE IF EXISTS RBAC_LAB_DB;
DROP WAREHOUSE IF EXISTS RBAC_LAB_WH;

USE ROLE SECURITYADMIN;
USE SECONDARY ROLES NONE;
REVOKE CREATE ROLE ON ACCOUNT FROM ROLE RBAC_LAB_OWNER;
REVOKE MANAGE GRANTS ON ACCOUNT FROM ROLE RBAC_LAB_OWNER;
DROP ROLE IF EXISTS RBAC_LAB_OWNER;

-- Cleanup complete!
