-- ============================================================================
-- QUICK INDEX VERIFICATION
-- Fast proof that indexes are working
-- ============================================================================
-- Usage: psql -U ceejayy -d vrdbms -f quick_verify.sql
-- ============================================================================

\echo '============================================================================'
\echo '          QUICK INDEX OPTIMIZATION VERIFICATION'
\echo '============================================================================'
\echo ''

-- Count all indexes
\echo '1. INDEX COUNT'
\echo '-----------------------------------'
SELECT 
    'Total Indexes Created' AS metric,
    COUNT(*)::text AS value
FROM pg_indexes 
WHERE schemaname = 'public'
UNION ALL
SELECT 
    'Expected Indexes' AS metric,
    '34' AS value;
\echo ''

-- Show indexes per table
\echo '2. INDEXES BY TABLE'
\echo '-----------------------------------'
SELECT 
    tablename,
    COUNT(*) AS index_count
FROM pg_indexes
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY index_count DESC;
\echo ''

-- Test key queries with EXPLAIN (simple format)
\echo '3. PROOF: Available Vehicles Query Uses Index'
\echo '-----------------------------------'
EXPLAIN 
SELECT COUNT(*) FROM vehicle WHERE status = 'available';
\echo ''
\echo '→ Look for "Index" in the output above ✓'
\echo ''

\echo '4. PROOF: Customer Search Uses Index'
\echo '-----------------------------------'
EXPLAIN
SELECT * FROM customer WHERE last_name LIKE 'J%' ORDER BY last_name;
\echo ''
\echo '→ Look for "Index" in the output above ✓'
\echo ''

\echo '5. PROOF: Rental Status Query Uses Index'
\echo '-----------------------------------'
EXPLAIN
SELECT COUNT(*) FROM rental WHERE status = 'active';
\echo ''
\echo '→ Look for "Index" in the output above ✓'
\echo ''

\echo '6. PROOF: Composite Index for Status + Branch'
\echo '-----------------------------------'
EXPLAIN
SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;
\echo ''
\echo '→ Look for "idx_vehicle_status_branch" above ✓'
\echo ''

\echo '7. PROOF: Date Range Uses Index'
\echo '-----------------------------------'
EXPLAIN
SELECT * FROM rental 
WHERE start_date >= '2024-01-01' AND end_date <= '2024-12-31';
\echo ''
\echo '→ Look for "idx_rental_dates" above ✓'
\echo ''

-- Show most used indexes
\echo '8. MOST USED INDEXES (Top 15)'
\echo '-----------------------------------'
SELECT 
    tablename,
    indexname,
    idx_scan AS times_used,
    CASE 
        WHEN idx_scan = 0 THEN '⚠ Not used yet'
        WHEN idx_scan < 10 THEN '✓ Used (low)'
        WHEN idx_scan < 100 THEN '✓ Used (medium)'
        ELSE '✓✓ Used (high)'
    END AS status
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC
LIMIT 15;
\echo ''

-- Database size impact
\echo '9. DATABASE SIZE IMPACT'
\echo '-----------------------------------'
SELECT 
    'Total Database Size' AS metric,
    pg_size_pretty(pg_database_size('vrdbms')) AS size
UNION ALL
SELECT 
    'Total Index Size' AS metric,
    pg_size_pretty(SUM(pg_relation_size(indexrelid))) AS size
FROM pg_stat_user_indexes
WHERE schemaname = 'public';
\echo ''

-- Sample query performance with timing
\echo '10. SAMPLE QUERY PERFORMANCE TEST'
\echo '-----------------------------------'
\timing on

\echo 'Test 1: Count available vehicles (3 runs)'
SELECT COUNT(*) FROM vehicle WHERE status = 'available';
SELECT COUNT(*) FROM vehicle WHERE status = 'available';
SELECT COUNT(*) FROM vehicle WHERE status = 'available';

\echo ''
\echo 'Test 2: Count active rentals (3 runs)'
SELECT COUNT(*) FROM rental WHERE status = 'active';
SELECT COUNT(*) FROM rental WHERE status = 'active';
SELECT COUNT(*) FROM rental WHERE status = 'active';

\echo ''
\echo 'Test 3: Dashboard query with JOINs (3 runs)'
SELECT COUNT(*) FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id;
SELECT COUNT(*) FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id;
SELECT COUNT(*) FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id;

\timing off
\echo ''

-- Final summary
\echo '============================================================================'
\echo '                    VERIFICATION SUMMARY'
\echo '============================================================================'
\echo ''
\echo 'WHAT TO LOOK FOR:'
\echo ''
\echo '✓ Section 1: Should show 34 total indexes'
\echo '✓ Section 2: Rental table should have 8 indexes (most)'
\echo '✓ Sections 3-7: Should show "Index Scan" or "Bitmap Index Scan"'
\echo '✓ Section 8: Shows which indexes are actively being used'
\echo '✓ Section 10: Query times should be in milliseconds (< 5ms typically)'
\echo ''
\echo 'SUCCESS INDICATORS:'
\echo '  • All 34 indexes exist ✓'
\echo '  • EXPLAIN shows "Index Scan" instead of "Seq Scan" ✓'
\echo '  • Query execution times are fast (< 10ms) ✓'
\echo '  • Join operations use index lookups ✓'
\echo ''
\echo 'For detailed analysis, run:'
\echo '  psql -U ceejayy -d vrdbms -f test_optimization.sql'
\echo ''
\echo 'For before/after comparison, run:'
\echo '  psql -U ceejayy -d vrdbms -f benchmark_comparison.sql'
\echo ''
\echo '============================================================================'





