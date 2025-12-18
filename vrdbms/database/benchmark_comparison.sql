-- ============================================================================
-- BEFORE/AFTER INDEX PERFORMANCE BENCHMARK
-- This script demonstrates the performance difference with and without indexes
-- ============================================================================
-- WARNING: This script temporarily drops indexes for comparison!
-- Run this on a test database, not production!
-- Usage: psql -U ceejayy -d vrdbms -f benchmark_comparison.sql
-- ============================================================================

\timing on

\echo '============================================================================'
\echo 'INDEX OPTIMIZATION BENCHMARK - BEFORE vs AFTER'
\echo '============================================================================'
\echo ''
\echo 'This test will:'
\echo '  1. Run queries WITH indexes (current state)'
\echo '  2. Temporarily DROP specific indexes'
\echo '  3. Run same queries WITHOUT indexes'
\echo '  4. RESTORE indexes'
\echo '  5. Show performance comparison'
\echo ''
\echo 'Press Ctrl+C now if you want to cancel...'
\echo 'Continuing in 3 seconds...'
SELECT pg_sleep(3);
\echo ''

-- ============================================================================
-- BENCHMARK 1: Vehicle Status Filter
-- ============================================================================

\echo '============================================================================'
\echo 'BENCHMARK 1: Count Available Vehicles'
\echo '============================================================================'
\echo ''

\echo 'WITH INDEX (idx_vehicle_status):'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT COUNT(*) FROM vehicle WHERE status = 'available';

\echo ''
\echo 'Recording performance WITH index...'
\echo 'Run 1:' SELECT COUNT(*) FROM vehicle WHERE status = 'available';
\echo 'Run 2:' SELECT COUNT(*) FROM vehicle WHERE status = 'available';
\echo 'Run 3:' SELECT COUNT(*) FROM vehicle WHERE status = 'available';
\echo ''

-- Drop the index temporarily
DROP INDEX IF EXISTS idx_vehicle_status;

\echo 'WITHOUT INDEX (after dropping idx_vehicle_status):'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT COUNT(*) FROM vehicle WHERE status = 'available';

\echo ''
\echo 'Recording performance WITHOUT index...'
\echo 'Run 1:' SELECT COUNT(*) FROM vehicle WHERE status = 'available';
\echo 'Run 2:' SELECT COUNT(*) FROM vehicle WHERE status = 'available';
\echo 'Run 3:' SELECT COUNT(*) FROM vehicle WHERE status = 'available';
\echo ''

-- Restore the index
CREATE INDEX idx_vehicle_status ON vehicle(status);
\echo '✓ Index restored: idx_vehicle_status'
\echo ''

-- ============================================================================
-- BENCHMARK 2: Customer Name Search
-- ============================================================================

\echo '============================================================================'
\echo 'BENCHMARK 2: Customer Search by Last Name'
\echo '============================================================================'
\echo ''

\echo 'WITH INDEX (idx_customer_name):'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT customer_id, first_name, last_name, email 
FROM customer 
WHERE last_name LIKE 'J%' 
ORDER BY last_name, first_name;

\echo ''
\echo 'Recording performance WITH index...'
SELECT COUNT(*) FROM customer WHERE last_name LIKE 'J%';

-- Drop the index temporarily
DROP INDEX IF EXISTS idx_customer_name;

\echo ''
\echo 'WITHOUT INDEX (after dropping idx_customer_name):'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT customer_id, first_name, last_name, email 
FROM customer 
WHERE last_name LIKE 'J%' 
ORDER BY last_name, first_name;

\echo ''
\echo 'Recording performance WITHOUT index...'
SELECT COUNT(*) FROM customer WHERE last_name LIKE 'J%';

-- Restore the index
CREATE INDEX idx_customer_name ON customer(last_name, first_name);
\echo '✓ Index restored: idx_customer_name'
\echo ''

-- ============================================================================
-- BENCHMARK 3: Rental History (Foreign Key Join)
-- ============================================================================

\echo '============================================================================'
\echo 'BENCHMARK 3: Customer Rental History (JOIN performance)'
\echo '============================================================================'
\echo ''

\echo 'WITH INDEX (idx_rental_customer):'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT 
    r.rental_id,
    r.rental_date,
    v.make || ' ' || v.model AS vehicle,
    r.total_amount
FROM rental r
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
WHERE r.customer_id = 1;

\echo ''
\echo 'Recording performance WITH index...'
SELECT COUNT(*) FROM rental WHERE customer_id = 1;

-- Drop the index temporarily
DROP INDEX IF EXISTS idx_rental_customer;

\echo ''
\echo 'WITHOUT INDEX (after dropping idx_rental_customer):'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT 
    r.rental_id,
    r.rental_date,
    v.make || ' ' || v.model AS vehicle,
    r.total_amount
FROM rental r
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
WHERE r.customer_id = 1;

\echo ''
\echo 'Recording performance WITHOUT index...'
SELECT COUNT(*) FROM rental WHERE customer_id = 1;

-- Restore the index
CREATE INDEX idx_rental_customer ON rental(customer_id);
\echo '✓ Index restored: idx_rental_customer'
\echo ''

-- ============================================================================
-- BENCHMARK 4: Composite Index (Status + Branch)
-- ============================================================================

\echo '============================================================================'
\echo 'BENCHMARK 4: Available Vehicles by Branch (Composite Index)'
\echo '============================================================================'
\echo ''

\echo 'WITH COMPOSITE INDEX (idx_vehicle_status_branch):'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT COUNT(*) 
FROM vehicle 
WHERE status = 'available' AND branch_id = 1;

\echo ''
\echo 'Recording performance WITH composite index...'
SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;

-- Drop the composite index temporarily
DROP INDEX IF EXISTS idx_vehicle_status_branch;

\echo ''
\echo 'WITHOUT COMPOSITE INDEX (still has individual indexes):'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT COUNT(*) 
FROM vehicle 
WHERE status = 'available' AND branch_id = 1;

\echo ''
\echo 'Recording performance WITHOUT composite index...'
SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;

-- Restore the composite index
CREATE INDEX idx_vehicle_status_branch ON vehicle(status, branch_id);
\echo '✓ Index restored: idx_vehicle_status_branch'
\echo ''

-- ============================================================================
-- BENCHMARK 5: Date Range Query
-- ============================================================================

\echo '============================================================================'
\echo 'BENCHMARK 5: Rentals in Date Range'
\echo '============================================================================'
\echo ''

\echo 'WITH INDEX (idx_rental_dates):'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT COUNT(*) 
FROM rental 
WHERE start_date >= CURRENT_DATE - INTERVAL '30 days'
  AND end_date <= CURRENT_DATE + INTERVAL '30 days';

\echo ''
\echo 'Recording performance WITH index...'
SELECT COUNT(*) FROM rental 
WHERE start_date >= CURRENT_DATE - INTERVAL '30 days'
  AND end_date <= CURRENT_DATE + INTERVAL '30 days';

-- Drop the index temporarily
DROP INDEX IF EXISTS idx_rental_dates;

\echo ''
\echo 'WITHOUT INDEX (after dropping idx_rental_dates):'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT COUNT(*) 
FROM rental 
WHERE start_date >= CURRENT_DATE - INTERVAL '30 days'
  AND end_date <= CURRENT_DATE + INTERVAL '30 days';

\echo ''
\echo 'Recording performance WITHOUT index...'
SELECT COUNT(*) FROM rental 
WHERE start_date >= CURRENT_DATE - INTERVAL '30 days'
  AND end_date <= CURRENT_DATE + INTERVAL '30 days';

-- Restore the index
CREATE INDEX idx_rental_dates ON rental(start_date, end_date);
\echo '✓ Index restored: idx_rental_dates'
\echo ''

-- ============================================================================
-- BENCHMARK 6: Complex JOIN with Multiple Indexes
-- ============================================================================

\echo '============================================================================'
\echo 'BENCHMARK 6: Dashboard Query (Complex JOIN with multiple indexes)'
\echo '============================================================================'
\echo ''

\echo 'WITH ALL INDEXES:'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT 
    r.rental_id,
    c.first_name || ' ' || c.last_name AS customer,
    v.make || ' ' || v.model AS vehicle,
    r.rental_date,
    r.status
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
ORDER BY r.rental_date DESC
LIMIT 10;

\echo ''
\echo 'Execution time noted above ↑'
\echo ''

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================

\echo '============================================================================'
\echo 'BENCHMARK COMPLETE - ALL INDEXES RESTORED'
\echo '============================================================================'
\echo ''
\echo 'HOW TO READ THE RESULTS:'
\echo ''
\echo '1. EXPLAIN ANALYZE Output:'
\echo '   • "Index Scan" or "Bitmap Index Scan" = Index is being used ✓'
\echo '   • "Seq Scan" = Full table scan (slower) ✗'
\echo '   • Look at "actual time" - lower is better'
\echo '   • Look at "cost" - lower is better'
\echo ''
\echo '2. Execution Times (shown by \\timing):'
\echo '   • Compare milliseconds WITH vs WITHOUT indexes'
\echo '   • Speedup is more noticeable with larger datasets'
\echo ''
\echo '3. Buffers Statistics:'
\echo '   • "shared hit" = data found in cache (fast)'
\echo '   • "shared read" = data read from disk (slower)'
\echo '   • Indexes reduce both cache and disk usage'
\echo ''
\echo 'KEY TAKEAWAYS:'
\echo '✓ Indexes convert "Seq Scan" to "Index Scan"'
\echo '✓ Composite indexes optimize multi-column WHERE clauses'
\echo '✓ Foreign key indexes speed up JOIN operations'
\echo '✓ Performance gains scale with data volume'
\echo ''
\echo 'All indexes have been restored to original state.'
\echo '============================================================================'

\timing off





