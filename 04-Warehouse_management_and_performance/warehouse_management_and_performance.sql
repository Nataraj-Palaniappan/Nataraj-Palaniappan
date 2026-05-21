-- ============================================================
-- LAB: WAREHOUSE MANAGEMENT & PERFORMANCE
-- ============================================================
-- Role: ACCOUNTADMIN
-- Database: LAB_DB
-- Schema: PUBLIC
-- Warehouse: LAB_WH_XSMALL
-- **Author:** NATARAJ_PALANIAPPAN
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE LAB_DB;
USE SCHEMA PUBLIC;
USE WAREHOUSE LAB_WH_XSMALL;

-- ============================================================
-- SECTION 1: UNDERSTANDING WAREHOUSE BASICS
-- ============================================================
-- A virtual warehouse provides compute resources for:
--   - Executing SQL queries
--   - Performing DML operations (INSERT, UPDATE, DELETE)
--   - Loading/unloading data
--
-- Key characteristics:
--   - Decoupled from storage (pay only when running)
--   - Can be started/stopped/resized independently
--   - Billed per-second (minimum 60 seconds)
-- ============================================================

-- 1.1 View all warehouses you have access to
SHOW WAREHOUSES;

-- 1.2 View specific warehouse details
DESCRIBE WAREHOUSE LAB_WH_XSMALL;

-- 1.3 Check current warehouse context
SELECT CURRENT_WAREHOUSE();


-- ============================================================
-- SECTION 2: WAREHOUSE SIZING
-- ============================================================
-- Sizes: XS, S, M, L, XL, 2XL, 3XL, 4XL, 5XL, 6XL
-- Each size doubles compute power AND credits/hour:
--   XS = 1 credit/hr
--   S  = 2 credits/hr
--   M  = 4 credits/hr
--   L  = 8 credits/hr
--   XL = 16 credits/hr
--   ...and so on (doubling each time)
--
-- IMPORTANT: Bigger != always better
--   - Larger warehouses help with COMPLEX queries (more nodes)
--   - They do NOT help with MORE concurrent simple queries
--   - For concurrency, use multi-cluster warehouses
-- ============================================================

-- 2.1 Create a warehouse with specific size
CREATE OR REPLACE WAREHOUSE LAB_WH_XSMALL
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Lab warehouse - XSmall for testing';

-- 2.2 Resize a warehouse (can be done while running)
ALTER WAREHOUSE LAB_WH_XSMALL SET WAREHOUSE_SIZE = 'SMALL';

-- 2.3 Verify the resize
SHOW WAREHOUSES LIKE 'LAB_WH_XSMALL';

-- 2.4 Resize back down
ALTER WAREHOUSE LAB_WH_XSMALL SET WAREHOUSE_SIZE = 'XSMALL';


-- ============================================================
-- SECTION 3: AUTO-SUSPEND & AUTO-RESUME
-- ============================================================
-- AUTO_SUSPEND: Seconds of inactivity before warehouse suspends
--   - Minimum: 60 seconds (or 0 to disable auto-suspend)
--   - Recommendation: 60s for ETL, 300-600s for BI/interactive
--
-- AUTO_RESUME: Automatically resume when a query is submitted
--   - Almost always set to TRUE
--   - FALSE means manual RESUME needed (rare use case)
--
-- INITIALLY_SUSPENDED: Start in suspended state at creation
-- ============================================================

-- 3.1 Set aggressive auto-suspend (good for ETL warehouses)
ALTER WAREHOUSE LAB_WH_XSMALL SET
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- 3.2 Check warehouse state
SELECT SYSTEM$WAREHOUSE_STATUS('LAB_WH_XSMALL');

-- 3.3 Manually suspend a warehouse
ALTER WAREHOUSE LAB_WH_XSMALL SUSPEND;

-- 3.4 Manually resume a warehouse
ALTER WAREHOUSE LAB_WH_XSMALL RESUME;

-- 3.5 Suspend again to save credits
ALTER WAREHOUSE LAB_WH_XSMALL SUSPEND;


-- ============================================================
-- SECTION 4: MULTI-CLUSTER WAREHOUSES
-- ============================================================
-- Purpose: Handle CONCURRENCY (many users/queries at once)
-- NOT for making individual queries faster (use sizing for that)
--
-- Modes:
--   MAXIMIZED: All clusters always running (predictable cost)
--   AUTO-SCALE: Clusters start/stop based on load (cost-efficient)
--
-- Scaling Policies (Auto-scale mode):
--   STANDARD: Favors performance (starts clusters quickly)
--   ECONOMY: Favors cost savings (waits for ~6min of queued work)
--
-- Requires: Enterprise Edition or higher
-- ============================================================

-- 4.1 Create a multi-cluster warehouse (Auto-scale mode)
CREATE OR REPLACE WAREHOUSE LAB_WH_MULTICLUSTER
    WAREHOUSE_SIZE = 'XSMALL'
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 3
    SCALING_POLICY = 'STANDARD'
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Lab multi-cluster warehouse - auto-scale';

-- 4.2 View multi-cluster configuration
SHOW WAREHOUSES LIKE 'LAB_WH_MULTICLUSTER';

-- 4.3 Change to ECONOMY scaling policy
ALTER WAREHOUSE LAB_WH_MULTICLUSTER SET SCALING_POLICY = 'ECONOMY';

-- 4.4 Change to MAXIMIZED mode (min = max)
ALTER WAREHOUSE LAB_WH_MULTICLUSTER SET
    MIN_CLUSTER_COUNT = 2
    MAX_CLUSTER_COUNT = 2;

-- 4.5 Revert to Auto-scale
ALTER WAREHOUSE LAB_WH_MULTICLUSTER SET
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 3
    SCALING_POLICY = 'STANDARD';


-- ============================================================
-- SECTION 5: RESOURCE MONITORS
-- ============================================================
-- Resource monitors track credit usage and can:
--   - Send notifications (NOTIFY)
--   - Suspend warehouse (SUSPEND)
--   - Suspend warehouse & kill running queries (SUSPEND_IMMEDIATE)
--
-- Can be set at:
--   - Account level (applies to all warehouses)
--   - Warehouse level (specific warehouse only)
--
-- NOTE: Creating resource monitors requires ACCOUNTADMIN role
-- ============================================================

-- 5.1 Create a resource monitor
CREATE OR REPLACE RESOURCE MONITOR LAB_MONITOR
    WITH CREDIT_QUOTA = 100
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 75 PERCENT DO NOTIFY
        ON 90 PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND
        ON 110 PERCENT DO SUSPEND_IMMEDIATE;

-- 5.2 Assign resource monitor to a warehouse
ALTER WAREHOUSE LAB_WH_XSMALL SET RESOURCE_MONITOR = 'LAB_MONITOR';

-- 5.3 View resource monitors
SHOW RESOURCE MONITORS;

-- 5.4 Check current credit usage
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE WAREHOUSE_NAME = 'LAB_WH_XSMALL'
AND START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
ORDER BY START_TIME DESC;


-- ============================================================
-- SECTION 6: QUERY ACCELERATION SERVICE (QAS)
-- ============================================================
-- Offloads portions of eligible queries to shared compute
-- Best for:
--   - Large scans with selective filters
--   - Large INSERT/COPY operations
--   - Outlier queries that use more resources than typical
--
-- Scale Factor: Controls max additional resources (cost limiter)
--   - Default: 8 (explicit enable) or 2 (auto-enabled for Gen2/MCW)
--   - 0 = unlimited (no cap)
--
-- Requires: Enterprise Edition or higher
-- ============================================================

-- 6.1 Enable QAS on a warehouse
ALTER WAREHOUSE LAB_WH_XSMALL SET
    ENABLE_QUERY_ACCELERATION = TRUE
    QUERY_ACCELERATION_MAX_SCALE_FACTOR = 8;

-- 6.2 Verify QAS is enabled
SHOW WAREHOUSES LIKE 'LAB_WH_XSMALL';

-- 6.3 Find queries that would benefit from QAS (last 7 days)
SELECT query_id, eligible_query_acceleration_time
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_ACCELERATION_ELIGIBLE
WHERE start_time > DATEADD('day', -7, CURRENT_TIMESTAMP())
ORDER BY eligible_query_acceleration_time DESC
LIMIT 10;

-- 6.4 Find warehouses that would benefit most from QAS
SELECT warehouse_name, COUNT(query_id) AS num_eligible_queries,
       SUM(eligible_query_acceleration_time) AS total_eligible_time
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_ACCELERATION_ELIGIBLE
WHERE start_time > DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY warehouse_name
ORDER BY total_eligible_time DESC;

-- 6.5 Check QAS credit usage
SELECT warehouse_name, SUM(credits_used) AS total_credits_used
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_ACCELERATION_HISTORY
WHERE start_time >= DATE_TRUNC('month', CURRENT_DATE())
GROUP BY warehouse_name
ORDER BY total_credits_used DESC;

-- 6.6 Disable QAS (if cost is a concern)
ALTER WAREHOUSE LAB_WH_XSMALL SET ENABLE_QUERY_ACCELERATION = FALSE;


-- ============================================================
-- SECTION 7: WAREHOUSE UTILIZATION MONITORING
-- ============================================================
-- Two sources for monitoring data:
--
-- ┌──────────────────────────┬──────────────────────────────────────────┐
-- │ INFORMATION_SCHEMA       │ ACCOUNT_USAGE (SNOWFLAKE database)       │
-- ├──────────────────────────┼──────────────────────────────────────────┤
-- │ NO latency (real-time)   │ 45 min to 3 hour latency                │
-- │ Last 7-14 days only      │ Up to 365 days of history               │
-- │ Per-database scope       │ Account-wide scope                      │
-- │ No ACCOUNTADMIN needed   │ Requires ACCOUNTADMIN (or granted role) │
-- │ Table functions (need WH)│ Views (standard SQL)                    │
-- │ Best for: live debugging │ Best for: trend analysis & reporting    │
-- └──────────────────────────┴──────────────────────────────────────────┘
--
-- RULE OF THUMB:
--   - Need data RIGHT NOW (live troubleshooting)? → INFORMATION_SCHEMA
--   - Need historical trends / cross-account view? → ACCOUNT_USAGE
-- ============================================================

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 7A: INFORMATION_SCHEMA (Real-time, no latency)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- 7A.1 Real-time query history (no latency, last 7 days)
SELECT query_id, query_text, warehouse_name, warehouse_size,
       execution_status, error_message,
       execution_time / 1000 AS exec_seconds,
       total_elapsed_time / 1000 AS total_seconds,
       bytes_scanned, rows_produced
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(
    DATEADD('hour', -1, CURRENT_TIMESTAMP()),
    CURRENT_TIMESTAMP()
))
ORDER BY start_time DESC
LIMIT 20;

-- 7A.2 Real-time: Currently running/queued queries
SELECT query_id, query_text, warehouse_name,
       execution_status, start_time,
       DATEDIFF('second', start_time, CURRENT_TIMESTAMP()) AS running_seconds
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
WHERE execution_status IN ('RUNNING', 'QUEUED')
ORDER BY start_time;

-- 7A.3 Real-time: Warehouse load in the last hour (no latency)
SELECT *
FROM TABLE(INFORMATION_SCHEMA.WAREHOUSE_LOAD_HISTORY(
    DATE_TRUNC('hour', CURRENT_TIMESTAMP()),
    CURRENT_TIMESTAMP(),
    'LAB_WH_XSMALL'
));

-- 7A.4 Real-time: Warehouse metering in the last 24 hours
SELECT *
FROM TABLE(INFORMATION_SCHEMA.WAREHOUSE_METERING_HISTORY(
    DATEADD('day', -1, CURRENT_TIMESTAMP()),
    CURRENT_TIMESTAMP(),
    'LAB_WH_XSMALL'
));

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 7B: ACCOUNT_USAGE (Historical, 45min-3hr latency)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- 7B.1 Credit consumption by warehouse (last 30 days)
SELECT warehouse_name,
       SUM(credits_used) AS total_credits,
       SUM(credits_used_compute) AS compute_credits,
       SUM(credits_used_cloud_services) AS cloud_services_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY warehouse_name
ORDER BY total_credits DESC;

-- 7B.2 Warehouse load history (queuing indicates undersizing)
SELECT warehouse_name,
       TO_DATE(start_time) AS usage_date,
       AVG(avg_running) AS avg_queries_running,
       AVG(avg_queued_load) AS avg_queries_queued,
       AVG(avg_blocked) AS avg_queries_blocked
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY warehouse_name, usage_date
ORDER BY warehouse_name, usage_date;

-- 7B.3 Identify long-running queries (potential candidates for larger WH)
SELECT query_id, query_text, warehouse_name, warehouse_size,
       execution_time / 1000 AS exec_seconds,
       total_elapsed_time / 1000 AS total_seconds,
       queued_overload_time / 1000 AS queued_seconds,
       bytes_scanned,
       rows_produced
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
AND execution_time > 60000
ORDER BY execution_time DESC
LIMIT 20;

-- 7B.4 Identify queries that spill to disk (need larger warehouse)
SELECT query_id, query_text, warehouse_name, warehouse_size,
       bytes_spilled_to_local_storage,
       bytes_spilled_to_remote_storage,
       execution_time / 1000 AS exec_seconds
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
AND (bytes_spilled_to_local_storage > 0 OR bytes_spilled_to_remote_storage > 0)
ORDER BY bytes_spilled_to_remote_storage DESC
LIMIT 20;

-- 7B.5 Warehouse idle time analysis (over-provisioned?)
SELECT warehouse_name,
       TO_DATE(start_time) AS usage_date,
       SUM(credits_used) AS credits_consumed,
       COUNT(*) AS metering_intervals
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY warehouse_name, usage_date
ORDER BY warehouse_name, usage_date;


-- ============================================================
-- SECTION 8: WORKLOAD ISOLATION STRATEGIES
-- ============================================================
-- Best practice: Separate warehouses by workload type
--
-- Pattern:
--   WH_ETL_*       → Data loading & transformation (large, auto-suspend 60s)
--   WH_BI_*        → Dashboard & reporting (medium, multi-cluster, auto-suspend 300s)
--   WH_ADHOC_*     → Analyst exploration (small, auto-suspend 300s)
--   WH_DS_*        → Data science / ML (large, auto-suspend 60s)
--
-- Benefits:
--   - ETL doesn't block BI users
--   - Cost attribution per team/workload
--   - Different sizing per use case
--   - Independent scaling & tuning
-- ============================================================

-- 8.1 Example: Create isolated warehouses for different workloads
CREATE OR REPLACE WAREHOUSE LAB_WH_ETL
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'ETL workload - aggressive suspend';

CREATE OR REPLACE WAREHOUSE LAB_WH_BI
    WAREHOUSE_SIZE = 'SMALL'
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 3
    SCALING_POLICY = 'STANDARD'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'BI workload - multi-cluster for concurrency';

CREATE OR REPLACE WAREHOUSE LAB_WH_ADHOC
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    STATEMENT_TIMEOUT_IN_SECONDS = 900
    COMMENT = 'Ad-hoc queries - timeout after 15 min';

-- 8.2 Set statement timeout to prevent runaway queries
ALTER WAREHOUSE LAB_WH_ADHOC SET STATEMENT_TIMEOUT_IN_SECONDS = 600;

-- 8.3 Set queued statement timeout
ALTER WAREHOUSE LAB_WH_ADHOC SET STATEMENT_QUEUED_TIMEOUT_IN_SECONDS = 300;


-- ============================================================
-- SECTION 9: ADAPTIVE WAREHOUSES (Preview)
-- ============================================================
-- New warehouse type that automatically manages:
--   - Warehouse size
--   - Multi-cluster settings
--   - Query Acceleration
--   - Suspend/resume
--
-- Key properties:
--   MAX_QUERY_PERFORMANCE_LEVEL: Upper bound (XS to X4LARGE)
--   QUERY_THROUGHPUT_MULTIPLIER: Controls concurrency burst
--
-- Available in Enterprise Edition (certain AWS regions)
-- ============================================================

-- 9.1 Create an adaptive warehouse (if available in your region)
-- CREATE ADAPTIVE WAREHOUSE LAB_WH_ADAPTIVE
--     WITH MAX_QUERY_PERFORMANCE_LEVEL = XLARGE
--          QUERY_THROUGHPUT_MULTIPLIER = 2;

-- 9.2 Convert existing warehouse to adaptive
-- ALTER WAREHOUSE LAB_WH_XSMALL SET WAREHOUSE_TYPE = 'ADAPTIVE';

-- 9.3 Convert back to standard
-- ALTER WAREHOUSE LAB_WH_XSMALL SET WAREHOUSE_TYPE = 'STANDARD';


-- ============================================================
-- SECTION 10: PRACTICAL EXERCISES
-- ============================================================

-- EXERCISE 1: Right-Sizing Analysis
-- Find warehouses that are oversized (low utilization)
SELECT warehouse_name,
       warehouse_size,
       AVG(avg_running) AS avg_queries_running,
       AVG(avg_queued_load) AS avg_queries_queued
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY warehouse_name, warehouse_size
HAVING AVG(avg_queued_load) < 0.1
ORDER BY warehouse_name;

-- EXERCISE 2: Find warehouses with excessive queuing (undersized)
SELECT warehouse_name,
       warehouse_size,
       AVG(avg_running) AS avg_queries_running,
       AVG(avg_queued_load) AS avg_queries_queued
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY warehouse_name, warehouse_size
HAVING AVG(avg_queued_load) > 1
ORDER BY avg_queries_queued DESC;

-- EXERCISE 3: Cost per query analysis
SELECT warehouse_name,
       COUNT(*) AS query_count,
       SUM(credits_used_cloud_services) AS total_cloud_credits,
       SUM(credits_used_cloud_services) / COUNT(*) AS avg_credit_per_query
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY q
JOIN SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY w
    ON q.warehouse_name = w.warehouse_name
    AND DATE_TRUNC('hour', q.start_time) = DATE_TRUNC('hour', w.start_time)
WHERE q.start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY q.warehouse_name
ORDER BY avg_credit_per_query DESC;

-- EXERCISE 4: Identify queries that could benefit from a larger warehouse
-- (Look for high execution time with spilling)
SELECT warehouse_name, warehouse_size,
       COUNT(*) AS spilling_query_count,
       SUM(bytes_spilled_to_remote_storage) / POWER(1024, 3) AS gb_spilled_remote
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
AND bytes_spilled_to_remote_storage > 0
GROUP BY warehouse_name, warehouse_size
ORDER BY gb_spilled_remote DESC;


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- HOW TO INTERPRET EXERCISE RESULTS
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- EXERCISE 1: avg_queued_load < 0.1
--   → Queries barely queue at all. The warehouse handles everything
--     instantly — it's likely OVERSIZED for its workload.
--   → ACTION: Try downsizing (e.g., MEDIUM → SMALL) and monitor.
--     If queries still don't queue, downsize again. Save credits.
--
-- EXERCISE 2: avg_queued_load > 1
--   → On average, more than 1 query is waiting in the queue at any time.
--     Users are experiencing delays.
--   → ACTION (single-cluster): Resize UP (e.g., SMALL → MEDIUM)
--   → ACTION (already large): Enable multi-cluster (MAX_CLUSTER_COUNT > 1)
--     Queuing = concurrency problem → scale OUT, not UP.
--
-- EXERCISE 3: avg_credit_per_query interpretation
--   → High cost per query means either:
--     (a) Warehouse is too large for simple queries (wasteful)
--     (b) Queries are inefficient (full table scans, no pruning)
--   → ACTION: Compare across warehouses. If WH_ADHOC has higher
--     cost-per-query than WH_ETL, analysts may be running unoptimized
--     queries on an oversized warehouse.
--   → BENCHMARK: For XS warehouse, expect ~0.0003 credits/query for
--     simple queries. If you see 0.01+, investigate those queries.
--
-- EXERCISE 4: bytes_spilled_to_remote_storage > 0
--   → Query ran out of LOCAL memory/SSD and spilled to remote storage.
--     This is VERY SLOW (network I/O) and indicates the warehouse
--     is TOO SMALL for that query's data volume.
--   → Spill to LOCAL storage: Acceptable (SSD, still fast)
--   → Spill to REMOTE storage: BAD (S3/blob, 10-100x slower)
--   → ACTION: Size UP the warehouse for workloads with remote spilling.
--     Doubling warehouse size = doubling memory & SSD cache.
--   → EXAMPLE: If a SMALL WH spills 50GB remote, try MEDIUM or LARGE.
--     After resize, re-run the same query and verify no spilling.
--
-- GENERAL DECISION MATRIX:
-- ┌─────────────────────────┬────────────────────────────────────────┐
-- │ Symptom                 │ Fix                                    │
-- ├─────────────────────────┼────────────────────────────────────────┤
-- │ No queuing, low usage   │ Downsize warehouse (save cost)         │
-- │ High queuing            │ Multi-cluster OR resize up             │
-- │ Remote spilling         │ Resize up (more memory/SSD)            │
-- │ High cost per query     │ Downsize OR optimize SQL               │
-- │ Long exec + no spill    │ Check query plan (bad joins/scans)     │
-- │ Queuing + no spilling   │ Concurrency issue → multi-cluster      │
-- │ Queuing + spilling      │ Both: resize up AND multi-cluster      │
-- └─────────────────────────┴────────────────────────────────────────┘
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ============================================================
-- SECTION 11: CLEANUP
-- ============================================================

DROP WAREHOUSE IF EXISTS LAB_WH_XSMALL;
DROP WAREHOUSE IF EXISTS LAB_WH_MULTICLUSTER;
DROP WAREHOUSE IF EXISTS LAB_WH_ETL;
DROP WAREHOUSE IF EXISTS LAB_WH_BI;
DROP WAREHOUSE IF EXISTS LAB_WH_ADHOC;


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. SIZE UP for complex queries (joins, aggregations, sorts)
-- 2. SCALE OUT (multi-cluster) for concurrent users/queries
-- 3. AUTO-SUSPEND aggressively (60s for ETL, 300s for BI)
-- 4. ISOLATE workloads (ETL, BI, ad-hoc, data science)
-- 5. MONITOR queuing (indicates need for multi-cluster or resize)
-- 6. MONITOR spilling (indicates need for larger warehouse)
-- 7. USE RESOURCE MONITORS to prevent runaway costs
-- 8. QAS helps with outlier queries without resizing
-- 9. ADAPTIVE WAREHOUSES automate all of the above (preview)
-- ============================================================