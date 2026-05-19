# Snowflake Dynamic Data Masking - Learning Lab

## Overview

Dynamic Data Masking (DDM) allows you to mask sensitive data at query time based on the role of the querying user. The actual data remains unchanged in storage — masking happens transparently on read.

This lab demonstrates **two approaches** using the `HOTEL_REVENUE` table with `CREDIT_CARD_NUMBER` and `ACCOUNT_NUMBER` columns.

---

## Lab Structure

| File | Description |
|------|-------------|
| `00_prerequisites.sql` | **Run first (as ACCOUNTADMIN)**: Creates database, schema, warehouse, and roles |
| `01_setup_table.sql` | Create HOTEL_REVENUE table with CREDIT_CARD_NUMBER and ACCOUNT_NUMBER |
| `02_grant_permissions.sql` | Grant SELECT to LAB_ANALYST role |
| `03_masking_policy_direct.sql` | **Approach 1**: Create and apply masking policies directly on columns |
| `04_test_direct_masking.sql` | Test direct masking with different roles |
| `05_cleanup_direct_masking.sql` | Remove direct masking before testing tag-based |
| `06_create_tag.sql` | Create the `pii_sensitivity` tag |
| `07_masking_policy_tag_based.sql` | **Approach 2**: Create tag-based masking policy |
| `08_test_tag_based_masking.sql` | Test tag-based masking with different roles |
| `09_cleanup_all.sql` | Full cleanup of all policies, tags, tables, and database |

---

## Roles Used

| Role | Purpose |
|------|---------|
| `ACCOUNTADMIN` | One-time setup only (file `00`) |
| `LAB_ADMIN` | Policy owner, full data access, creates masking policies and tags |
| `LAB_ANALYST` | Consumer role, sees masked data |

---

## Approach 1: Direct Column Masking

### How It Works

A masking policy is created and applied **directly** to a specific column using `ALTER TABLE ... MODIFY COLUMN ... SET MASKING POLICY`.

```sql
CREATE OR REPLACE MASKING POLICY mask_credit_card
AS (val VARCHAR) RETURNS VARCHAR ->
    CASE
        WHEN CURRENT_ROLE() IN ('LAB_ADMIN') THEN val
        ELSE CONCAT('XXXX-XXXX-XXXX-', RIGHT(REPLACE(val, '-', ''), 4))
    END;

ALTER TABLE HOTEL_REVENUE MODIFY COLUMN CREDIT_CARD_NUMBER
    SET MASKING POLICY mask_credit_card;
```

### Pros
- Simple and explicit
- Easy to understand which column has which policy
- Good for small number of sensitive columns

### Cons
- Must apply to each column individually
- Doesn't scale well (100 tables × 5 columns = 500 ALTER statements)
- Adding a new table requires manual policy attachment

---

## Approach 2: Tag-Based Masking

### How It Works

A masking policy is attached to a **tag**. Any column tagged with that tag automatically inherits the masking policy. Different tag values (e.g., `HIGH`, `MEDIUM`) can produce different masking behavior.

```sql
CREATE OR REPLACE TAG pii_sensitivity;

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
```

### Pros
- Scales across many tables/columns (just add the tag)
- Single policy handles multiple masking levels via tag values
- Governance-friendly: integrates with Snowflake's data classification
- Centralized: change the policy once, all tagged columns update

### Cons
- Slightly more complex to set up
- Only one masking policy per data type per tag
- Requires `APPLY MASKING POLICY ON ACCOUNT` privilege
- Debugging requires checking both tag assignment and policy logic

---

## Comparison Table

| Feature | Direct Column | Tag-Based |
|---------|--------------|-----------|
| Setup complexity | Low | Medium |
| Scalability | Poor | Excellent |
| Policy per column | One per column | One per tag (per data type) |
| Governance integration | Manual | Automatic via classification |
| Centralized updates | No (per column) | Yes (change policy once) |
| Privileges needed | OWNERSHIP on table | APPLY MASKING POLICY ON ACCOUNT |
| Best for | Few columns, simple needs | Enterprise-wide PII protection |

---

## Key Concepts

### Masking Policy Syntax
```sql
CREATE MASKING POLICY <name>
AS (val <DATA_TYPE>) RETURNS <DATA_TYPE> ->
    <expression>;
```
- Input and output types **must match**
- Uses `CURRENT_ROLE()`, `IS_ROLE_IN_SESSION()`, or mapping tables for access control

### Important Functions
| Function | Use |
|----------|-----|
| `CURRENT_ROLE()` | Check active primary role |
| `IS_ROLE_IN_SESSION('ROLE_NAME')` | Check if role is active (includes secondary roles) |
| `SYSTEM$GET_TAG_ON_CURRENT_COLUMN('tag_fqn')` | Get tag value on the column being queried (tag-based only) |

### Constraints
- A column can have only **one** masking policy (either direct OR tag-based, not both)
- Tag-based: only **one** masking policy per data type per tag
- You cannot apply both a direct policy and a tag-based policy to the same column

---

## Execution Order

1. Run `00_prerequisites.sql` as **ACCOUNTADMIN** (one-time setup)
2. Run files `01` through `08` sequentially as **LAB_ADMIN** / **LAB_ANALYST**
3. Run `09` to clean up everything

**Important**: Run `05_cleanup_direct_masking.sql` before `07_masking_policy_tag_based.sql` — a column cannot have two masking policies simultaneously.

---

## Useful Commands

```sql
-- View policies applied to a table
SELECT * FROM TABLE(INFORMATION_SCHEMA.POLICY_REFERENCES(
    REF_ENTITY_DOMAIN => 'TABLE',
    REF_ENTITY_NAME => 'MASKING_LAB_DB.LAB_SCHEMA.HOTEL_REVENUE'
));

-- Check tag value on a column
SELECT SYSTEM$GET_TAG('MASKING_LAB_DB.LAB_SCHEMA.pii_sensitivity',
    'MASKING_LAB_DB.LAB_SCHEMA.HOTEL_REVENUE.CREDIT_CARD_NUMBER', 'COLUMN');

-- Describe a masking policy
DESCRIBE MASKING POLICY MASKING_LAB_DB.LAB_SCHEMA.mask_credit_card;
```
