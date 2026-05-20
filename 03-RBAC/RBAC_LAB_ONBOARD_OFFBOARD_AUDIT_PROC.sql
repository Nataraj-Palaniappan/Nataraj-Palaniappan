-- ============================================================================
-- RBAC LAB: USER ONBOARDING STORED PROCEDURE
-- ============================================================================
-- Purpose: Automate granting of functional roles to new users
-- Author: NATARAJ_PALANIAPPAN
-- Usage:  CALL RBAC_LAB_DB.RBAC_LAB_SCHEMA.ONBOARD_USER('USERNAME', 'ROLE_TYPE');
--         Role types: 'ANALYST', 'ENGINEER', 'DBA'
-- ============================================================================

USE ROLE RBAC_LAB_OWNER;
USE SECONDARY ROLES NONE;
USE WAREHOUSE RBAC_LAB_WH;
USE RBAC_LAB_DB.RBAC_LAB_SCHEMA;

CREATE OR REPLACE PROCEDURE RBAC_LAB_DB.RBAC_LAB_SCHEMA.ONBOARD_USER(
    P_USERNAME VARCHAR,
    P_ROLE_TYPE VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    V_FUNCTIONAL_ROLE VARCHAR;
    V_RESULT VARCHAR;
BEGIN
    CASE UPPER(P_ROLE_TYPE)
        WHEN 'ANALYST' THEN
            V_FUNCTIONAL_ROLE := 'RBAC_LAB_ANALYST';
        WHEN 'ENGINEER' THEN
            V_FUNCTIONAL_ROLE := 'RBAC_LAB_ENGINEER';
        WHEN 'DBA' THEN
            V_FUNCTIONAL_ROLE := 'RBAC_LAB_DBA';
        ELSE
            RETURN 'ERROR: Invalid role type "' || P_ROLE_TYPE || '". Valid values: ANALYST, ENGINEER, DBA';
    END CASE;

    EXECUTE IMMEDIATE 'GRANT ROLE ' || V_FUNCTIONAL_ROLE || ' TO USER ' || P_USERNAME;

    EXECUTE IMMEDIATE 'GRANT USAGE ON WAREHOUSE RBAC_LAB_WH TO ROLE ' || V_FUNCTIONAL_ROLE;

    V_RESULT := 'SUCCESS: User ' || P_USERNAME || ' onboarded as ' || P_ROLE_TYPE
                || ' (granted role ' || V_FUNCTIONAL_ROLE || ').'
                || ' Inherited access: ';

    CASE UPPER(P_ROLE_TYPE)
        WHEN 'ANALYST' THEN
            V_RESULT := V_RESULT || 'READ (SELECT on all tables/views)';
        WHEN 'ENGINEER' THEN
            V_RESULT := V_RESULT || 'READ + WRITE (SELECT, INSERT, UPDATE, DELETE)';
        WHEN 'DBA' THEN
            V_RESULT := V_RESULT || 'READ + WRITE + ADMIN (full DDL + DML)';
    END CASE;

    RETURN V_RESULT;
END;
$$;


-- ============================================================================
-- USAGE EXAMPLES
-- ============================================================================

-- Onboard a new analyst
-- CALL RBAC_LAB_DB.RBAC_LAB_SCHEMA.ONBOARD_USER('JOHN_SMITH', 'ANALYST');

-- Onboard a new data engineer
-- CALL RBAC_LAB_DB.RBAC_LAB_SCHEMA.ONBOARD_USER('JANE_DOE', 'ENGINEER');

-- Onboard a new DBA
-- CALL RBAC_LAB_DB.RBAC_LAB_SCHEMA.ONBOARD_USER('BOB_ADMIN', 'DBA');

-- Invalid role type (returns error message)
-- CALL RBAC_LAB_DB.RBAC_LAB_SCHEMA.ONBOARD_USER('SOMEONE', 'MANAGER');


-- ============================================================================
-- OFFBOARD USER (Remove role when someone leaves or changes team)
-- ============================================================================

CREATE OR REPLACE PROCEDURE RBAC_LAB_DB.RBAC_LAB_SCHEMA.OFFBOARD_USER(
    P_USERNAME VARCHAR,
    P_ROLE_TYPE VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    V_FUNCTIONAL_ROLE VARCHAR;
BEGIN
    CASE UPPER(P_ROLE_TYPE)
        WHEN 'ANALYST' THEN
            V_FUNCTIONAL_ROLE := 'RBAC_LAB_ANALYST';
        WHEN 'ENGINEER' THEN
            V_FUNCTIONAL_ROLE := 'RBAC_LAB_ENGINEER';
        WHEN 'DBA' THEN
            V_FUNCTIONAL_ROLE := 'RBAC_LAB_DBA';
        ELSE
            RETURN 'ERROR: Invalid role type "' || P_ROLE_TYPE || '". Valid values: ANALYST, ENGINEER, DBA';
    END CASE;

    EXECUTE IMMEDIATE 'REVOKE ROLE ' || V_FUNCTIONAL_ROLE || ' FROM USER ' || P_USERNAME;

    RETURN 'SUCCESS: User ' || P_USERNAME || ' offboarded from ' || P_ROLE_TYPE
           || ' (revoked role ' || V_FUNCTIONAL_ROLE || ').';
END;
$$;


-- ============================================================================
-- USAGE EXAMPLES - OFFBOARD
-- ============================================================================

-- Remove engineer access when someone moves to a different team
-- CALL RBAC_LAB_DB.RBAC_LAB_SCHEMA.OFFBOARD_USER('NATARAJ_PALANIAPPAN', 'ENGINEER');


-- ============================================================================
-- LIST USERS BY ROLE (Audit who has what)
/* You pass a role name (e.g. 'ENGINEER')
It runs SHOW GRANTS OF ROLE <that_role> internally — this lists who/what has been granted that role
It captures the output using RESULT_SCAN(LAST_QUERY_ID()) — this converts the SHOW command output into a queryable table
It filters to only rows where granted_to = 'USER' — so you only see users, not other roles
Returns a clean table with: user name, role name, and who granted it */
-- ============================================================================

CREATE OR REPLACE PROCEDURE RBAC_LAB_DB.RBAC_LAB_SCHEMA.LIST_ROLE_MEMBERS(
    P_ROLE_TYPE VARCHAR
)
RETURNS TABLE(GRANTEE_NAME VARCHAR, GRANTED_ROLE VARCHAR, GRANTED_BY VARCHAR)
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    V_FUNCTIONAL_ROLE VARCHAR;
    RES RESULTSET;
BEGIN
    CASE UPPER(P_ROLE_TYPE)
        WHEN 'ANALYST' THEN
            V_FUNCTIONAL_ROLE := 'RBAC_LAB_ANALYST';
        WHEN 'ENGINEER' THEN
            V_FUNCTIONAL_ROLE := 'RBAC_LAB_ENGINEER';
        WHEN 'DBA' THEN
            V_FUNCTIONAL_ROLE := 'RBAC_LAB_DBA';
        WHEN 'ALL' THEN
            V_FUNCTIONAL_ROLE := NULL;
        ELSE
            V_FUNCTIONAL_ROLE := UPPER(P_ROLE_TYPE);
    END CASE;

    IF (V_FUNCTIONAL_ROLE IS NULL) THEN
        RES := (
            SELECT GRANTEE_NAME, ROLE AS GRANTED_ROLE, GRANTED_BY
            FROM TABLE(RESULT_SCAN(LAST_QUERY_ID(-1)))
            WHERE 1=0
        );
        RETURN TABLE(RES);
    END IF;

    EXECUTE IMMEDIATE 'SHOW GRANTS OF ROLE ' || V_FUNCTIONAL_ROLE;
    RES := (
        SELECT "grantee_name" AS GRANTEE_NAME,
               "role" AS GRANTED_ROLE,
               "granted_by" AS GRANTED_BY
        FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
        WHERE "granted_to" = 'USER'
    );
    RETURN TABLE(RES);
END;
$$;


-- ============================================================================
-- USAGE EXAMPLES - LIST MEMBERS
-- ============================================================================

-- List all engineers
-- CALL RBAC_LAB_DB.RBAC_LAB_SCHEMA.LIST_ROLE_MEMBERS('ENGINEER');

-- List all DBAs
-- CALL RBAC_LAB_DB.RBAC_LAB_SCHEMA.LIST_ROLE_MEMBERS('DBA');

-- NOTE

