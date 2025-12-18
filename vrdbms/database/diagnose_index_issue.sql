-- ============================================================================
-- DIAGNOSE INDEX PERFORMANCE ISSUE
-- Why indexes might not show improvement
-- ============================================================================

\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'DIAGNOSING INDEX PERFORMANCE'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''

-- Check 1: Table sizes
\echo '1. TABLE SIZES (Small tables may not benefit from indexes)'
\echo '───────────────────────────────────────────────────────────────────────'
SELECT 
    tablename,
    n_live_tup AS row_count,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_live_tup DESC;

\echo ''
\echo '⚠️  If row_count < 1000, PostgreSQL may prefer Seq Scan (it''s actually faster!)'
\echo ''

-- Check 2: Are indexes being used?
\echo '2. INDEX USAGE STATISTICS'
\echo '───────────────────────────────────────────────────────────────────────'
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan AS times_used,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
  AND indexname LIKE 'idx_%'
ORDER BY idx_scan DESC;

\echo ''
\echo '⚠️  If idx_scan = 0, the index hasn''t been used yet'
\echo ''

-- Check 3: Query selectivity
\echo '3. QUERY SELECTIVITY (How many rows match?)'
\echo '───────────────────────────────────────────────────────────────────────'
SELECT 
    'Total rentals' AS metric,
    COUNT(*)::text AS value
FROM rental
UNION ALL
SELECT 
    'Rentals for customer_id=50',
    COUNT(*)::text
FROM rental WHERE customer_id = 50
UNION ALL
SELECT 
    'Selectivity %',
    ROUND((COUNT(*)::numeric / (SELECT COUNT(*) FROM rental) * 100), 2)::text || '%'
FROM rental WHERE customer_id = 50;

\echo ''
\echo '⚠️  If selectivity > 10%, Seq Scan might be faster than Index Scan'
\echo ''

-- Check 4: PostgreSQL configuration
\echo '4. POSTGRESQL OPTIMIZER SETTINGS'
\echo '───────────────────────────────────────────────────────────────────────'
SELECT name, setting, unit 
FROM pg_settings 
WHERE name IN ('random_page_cost', 'seq_page_cost', 'effective_cache_size', 'shared_buffers');

\echo ''
\echo ''

-- Check 5: Force index usage vs let optimizer choose
\echo '5. FORCING INDEX VS OPTIMIZER CHOICE'
\echo '───────────────────────────────────────────────────────────────────────'

\echo ''
\echo 'a) Let PostgreSQL choose (default):'
EXPLAIN ANALYZE
SELECT * FROM rental WHERE customer_id = 50;

\echo ''
\echo 'b) Disable sequential scans temporarily (forces index if possible):'
SET enable_seqscan = OFF;
EXPLAIN ANALYZE
SELECT * FROM rental WHERE customer_id = 50;
SET enable_seqscan = ON;

\echo ''
\echo '⚠️  Compare execution times above'
\echo ''

-- Check 6: Statistics up to date?
\echo '6. TABLE STATISTICS FRESHNESS'
\echo '───────────────────────────────────────────────────────────────────────'
SELECT 
    schemaname,
    tablename,
    last_analyze,
    last_autoanalyze,
    n_live_tup AS estimated_rows,
    n_tup_ins AS inserts_since_analyze,
    n_tup_upd AS updates_since_analyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY tablename;

\echo ''
\echo '⚠️  If last_analyze is old, run ANALYZE table_name;'
\echo ''

\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'COMMON REASONS FOR SLOW INDEX PERFORMANCE:'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo '1. ❌ Table too small (< 1000 rows)'
\echo '      → PostgreSQL correctly chooses Seq Scan for tiny tables'
\echo '      → This is CORRECT behavior!'
\echo ''
\echo '2. ❌ Query returns many rows (> 10% of table)'
\echo '      → Index scan would read more pages than Seq Scan'
\echo '      → PostgreSQL correctly chooses Seq Scan'
\echo ''
\echo '3. ❌ Statistics out of date'
\echo '      → Run: ANALYZE table_name;'
\echo ''
\echo '4. ❌ Data in cache already (first query slower)'
\echo '      → Run query multiple times, ignore first result'
\echo ''
\echo '5. ❌ Index exists but not used'
\echo '      → Check EXPLAIN output for "Index Scan"'
\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''





