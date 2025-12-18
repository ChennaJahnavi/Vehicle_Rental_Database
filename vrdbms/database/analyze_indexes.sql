-- ============================================================================
-- INDEX ANALYSIS AND MONITORING QUERIES
-- Use these queries to verify indexes are being used and performing well
-- ============================================================================
-- Usage: psql -U ceejayy -d vrdbms -f analyze_indexes.sql
-- ============================================================================

\echo '============================================================================'
\echo 'VRDBMS Index Analysis Report'
\echo '============================================================================'
\echo ''

-- 1. List all indexes and their sizes
\echo '1. ALL INDEXES AND SIZES'
\echo '----------------------------------------------------------------------------'
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY tablename, indexname;

\echo ''
\echo '============================================================================'

-- 2. Index usage statistics (most used indexes)
\echo '2. INDEX USAGE STATISTICS (Most Used)'
\echo '----------------------------------------------------------------------------'
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan AS scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched,
    CASE 
        WHEN idx_scan = 0 THEN 'UNUSED'
        WHEN idx_scan < 100 THEN 'Low Usage'
        WHEN idx_scan < 1000 THEN 'Medium Usage'
        ELSE 'High Usage'
    END AS usage_level
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

\echo ''
\echo '============================================================================'

-- 3. Potentially unused indexes
\echo '3. POTENTIALLY UNUSED INDEXES'
\echo '----------------------------------------------------------------------------'
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0 
  AND schemaname = 'public'
  AND indexrelname NOT LIKE 'pg_toast%'
ORDER BY pg_relation_size(indexrelid) DESC;

\echo ''
\echo '============================================================================'

-- 4. Table sizes with index overhead
\echo '4. TABLE SIZES WITH INDEX OVERHEAD'
\echo '----------------------------------------------------------------------------'
SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - 
                   pg_relation_size(schemaname||'.'||tablename)) AS indexes_size,
    (SELECT COUNT(*) 
     FROM pg_stat_user_indexes 
     WHERE pg_stat_user_indexes.tablename = pg_stat_user_tables.tablename) AS index_count
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

\echo ''
\echo '============================================================================'

-- 5. Index count by table
\echo '5. INDEX COUNT BY TABLE'
\echo '----------------------------------------------------------------------------'
SELECT 
    tablename,
    COUNT(*) AS index_count,
    pg_size_pretty(SUM(pg_relation_size(indexrelid))) AS total_index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY index_count DESC;

\echo ''
\echo '============================================================================'

-- 6. Check for duplicate/redundant indexes
\echo '6. CHECKING FOR DUPLICATE INDEXES'
\echo '----------------------------------------------------------------------------'
\echo 'Note: Manual review required for composite indexes'
SELECT 
    t.tablename,
    array_agg(i.indexname) AS indexes,
    array_agg(pg_get_indexdef(i.indexrelid)) AS definitions
FROM pg_stat_user_indexes t
JOIN pg_index i ON t.indexrelid = i.indexrelid
WHERE t.schemaname = 'public'
GROUP BY t.tablename, i.indkey
HAVING COUNT(*) > 1;

\echo ''
\echo '============================================================================'

-- 7. Missing indexes suggestion (tables with no indexes on foreign keys)
\echo '7. FOREIGN KEY COLUMNS AND THEIR INDEXES'
\echo '----------------------------------------------------------------------------'
SELECT 
    tc.table_name,
    kcu.column_name,
    EXISTS (
        SELECT 1 
        FROM pg_indexes 
        WHERE tablename = tc.table_name 
        AND indexdef LIKE '%' || kcu.column_name || '%'
    ) AS has_index
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

\echo ''
\echo '============================================================================'

-- 8. Sample EXPLAIN ANALYZE for key queries
\echo '8. QUERY PLAN FOR KEY DASHBOARD QUERIES'
\echo '----------------------------------------------------------------------------'
\echo 'Query 1: Available vehicles count'
EXPLAIN ANALYZE
SELECT COUNT(*) FROM vehicle WHERE status = 'available';

\echo ''
\echo 'Query 2: Active rentals count'
EXPLAIN ANALYZE
SELECT COUNT(*) FROM rental WHERE status = 'active';

\echo ''
\echo 'Query 3: Recent rentals (main dashboard query)'
EXPLAIN ANALYZE
SELECT r.rental_id, c.first_name || ' ' || c.last_name AS customer_name,
       v.make || ' ' || v.model AS vehicle, r.rental_date, r.status
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
ORDER BY r.rental_date DESC LIMIT 5;

\echo ''
\echo 'Query 4: Available vehicles by date range (from stored procedure)'
EXPLAIN ANALYZE
SELECT v.vehicle_id, v.make, v.model, v.year, vc.category_name, vc.daily_rate, b.branch_name
FROM vehicle v
JOIN vehicle_category vc ON v.category_id = vc.category_id
JOIN branch b ON v.branch_id = b.branch_id
WHERE v.status = 'available'
AND NOT EXISTS (
    SELECT 1 FROM rental r WHERE r.vehicle_id = v.vehicle_id 
    AND r.status IN ('pending', 'active')
    AND ((CURRENT_DATE BETWEEN r.start_date AND r.end_date) OR
         (CURRENT_DATE + 7 BETWEEN r.start_date AND r.end_date) OR
         (r.start_date BETWEEN CURRENT_DATE AND CURRENT_DATE + 7))
);

\echo ''
\echo '============================================================================'
\echo 'Index Analysis Complete!'
\echo '============================================================================'
\echo ''
\echo 'Tips:'
\echo '  - Indexes with idx_scan = 0 may not be needed (but check query patterns first)'
\echo '  - Look for "Index Scan" or "Index Only Scan" in EXPLAIN output for confirmation'
\echo '  - Bitmap Index Scan is also good, indicates index is being used'
\echo '  - "Seq Scan" means full table scan (may need index)'
\echo ''
\echo 'To reset statistics (after major data changes):'
\echo '  SELECT pg_stat_reset();'
\echo ''





