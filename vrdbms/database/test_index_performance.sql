-- ============================================================================
-- SIMPLE TEST: Index Performance Comparison
-- Shows clear before/after performance difference
-- ============================================================================

\timing on

\echo ''
\echo '████████████████████████████████████████████████████████████████████████████'
\echo '           INDEX PERFORMANCE TEST - WITH vs WITHOUT'
\echo '████████████████████████████████████████████████████████████████████████████'
\echo ''

-- Show current data volume
\echo 'Current Database Size:'
SELECT 
    'Vehicles' AS table_name, COUNT(*) AS records FROM vehicle
UNION ALL
SELECT 'Customers', COUNT(*) FROM customer
UNION ALL
SELECT 'Rentals', COUNT(*) FROM rental
ORDER BY table_name;

\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'TEST 1: Find Rentals for a Customer'
\echo '════════════════════════════════════════════════════════════════════════════'

-- ============================================================================
-- WITHOUT INDEX
-- ============================================================================

\echo ''
\echo '─────────────────────────────────────'
\echo '❌ WITHOUT INDEX'
\echo '─────────────────────────────────────'

DROP INDEX IF EXISTS idx_rental_customer;

\echo ''
\echo 'EXPLAIN ANALYZE Output:'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT rental_id, customer_id, vehicle_id, rental_date, total_amount, status
FROM rental
WHERE customer_id = 100;

\echo ''
\echo 'Running query 5 times to measure timing:'
SELECT COUNT(*) as rental_count FROM rental WHERE customer_id = 100;
SELECT COUNT(*) as rental_count FROM rental WHERE customer_id = 100;
SELECT COUNT(*) as rental_count FROM rental WHERE customer_id = 100;
SELECT COUNT(*) as rental_count FROM rental WHERE customer_id = 100;
SELECT COUNT(*) as rental_count FROM rental WHERE customer_id = 100;

-- ============================================================================
-- WITH INDEX
-- ============================================================================

\echo ''
\echo '─────────────────────────────────────'
\echo '✅ WITH INDEX (idx_rental_customer)'
\echo '─────────────────────────────────────'

CREATE INDEX idx_rental_customer ON rental(customer_id);
ANALYZE rental;

\echo ''
\echo 'EXPLAIN ANALYZE Output:'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT rental_id, customer_id, vehicle_id, rental_date, total_amount, status
FROM rental
WHERE customer_id = 100;

\echo ''
\echo 'Running query 5 times to measure timing:'
SELECT COUNT(*) as rental_count FROM rental WHERE customer_id = 100;
SELECT COUNT(*) as rental_count FROM rental WHERE customer_id = 100;
SELECT COUNT(*) as rental_count FROM rental WHERE customer_id = 100;
SELECT COUNT(*) as rental_count FROM rental WHERE customer_id = 100;
SELECT COUNT(*) as rental_count FROM rental WHERE customer_id = 100;

\echo ''
\echo '✅ RESULT: Compare the timing above - WITH index should be 5-10x faster!'
\echo ''

-- ============================================================================
-- TEST 2: Find Available Vehicles
-- ============================================================================

\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'TEST 2: Find Available Vehicles'
\echo '════════════════════════════════════════════════════════════════════════════'

-- WITHOUT INDEX
\echo ''
\echo '─────────────────────────────────────'
\echo '❌ WITHOUT INDEX'
\echo '─────────────────────────────────────'

DROP INDEX IF EXISTS idx_vehicle_status;

\echo ''
\echo 'EXPLAIN ANALYZE Output:'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT vehicle_id, make, model, status
FROM vehicle
WHERE status = 'available';

\echo ''
\echo 'Running query 5 times:'
SELECT COUNT(*) as available_count FROM vehicle WHERE status = 'available';
SELECT COUNT(*) as available_count FROM vehicle WHERE status = 'available';
SELECT COUNT(*) as available_count FROM vehicle WHERE status = 'available';
SELECT COUNT(*) as available_count FROM vehicle WHERE status = 'available';
SELECT COUNT(*) as available_count FROM vehicle WHERE status = 'available';

-- WITH INDEX
\echo ''
\echo '─────────────────────────────────────'
\echo '✅ WITH INDEX (idx_vehicle_status)'
\echo '─────────────────────────────────────'

CREATE INDEX idx_vehicle_status ON vehicle(status);
ANALYZE vehicle;

\echo ''
\echo 'EXPLAIN ANALYZE Output:'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT vehicle_id, make, model, status
FROM vehicle
WHERE status = 'available';

\echo ''
\echo 'Running query 5 times:'
SELECT COUNT(*) as available_count FROM vehicle WHERE status = 'available';
SELECT COUNT(*) as available_count FROM vehicle WHERE status = 'available';
SELECT COUNT(*) as available_count FROM vehicle WHERE status = 'available';
SELECT COUNT(*) as available_count FROM vehicle WHERE status = 'available';
SELECT COUNT(*) as available_count FROM vehicle WHERE status = 'available';

\echo ''
\echo '✅ RESULT: Notice Index Scan vs Seq Scan in EXPLAIN output!'
\echo ''

-- ============================================================================
-- TEST 3: Complex JOIN Query
-- ============================================================================

\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'TEST 3: Customer Rental History (with JOIN)'
\echo '════════════════════════════════════════════════════════════════════════════'

-- WITHOUT INDEX
\echo ''
\echo '─────────────────────────────────────'
\echo '❌ WITHOUT INDEX'
\echo '─────────────────────────────────────'

DROP INDEX IF EXISTS idx_rental_customer;

\echo ''
\echo 'EXPLAIN ANALYZE Output:'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    c.first_name,
    c.last_name,
    r.rental_date,
    v.make,
    v.model,
    r.total_amount
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
WHERE r.customer_id = 50
ORDER BY r.rental_date DESC
LIMIT 10;

\echo ''
\echo 'Running query 3 times:'
SELECT COUNT(*) FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
WHERE r.customer_id = 50;

SELECT COUNT(*) FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
WHERE r.customer_id = 50;

SELECT COUNT(*) FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
WHERE r.customer_id = 50;

-- WITH INDEX
\echo ''
\echo '─────────────────────────────────────'
\echo '✅ WITH INDEX'
\echo '─────────────────────────────────────'

CREATE INDEX idx_rental_customer ON rental(customer_id);
ANALYZE rental;

\echo ''
\echo 'EXPLAIN ANALYZE Output:'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    c.first_name,
    c.last_name,
    r.rental_date,
    v.make,
    v.model,
    r.total_amount
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
WHERE r.customer_id = 50
ORDER BY r.rental_date DESC
LIMIT 10;

\echo ''
\echo 'Running query 3 times:'
SELECT COUNT(*) FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
WHERE r.customer_id = 50;

SELECT COUNT(*) FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
WHERE r.customer_id = 50;

SELECT COUNT(*) FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
WHERE r.customer_id = 50;

\echo ''
\echo '✅ RESULT: JOIN queries benefit significantly from indexes!'
\echo ''

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================

\echo ''
\echo '████████████████████████████████████████████████████████████████████████████'
\echo '                          TEST COMPLETE'
\echo '████████████████████████████████████████████████████████████████████████████'
\echo ''
\echo '╔════════════════════════════════════════════════════════════════════════╗'
\echo '║                     HOW TO READ THE RESULTS                            ║'
\echo '╠════════════════════════════════════════════════════════════════════════╣'
\echo '║                                                                        ║'
\echo '║  1. EXPLAIN ANALYZE shows:                                            ║'
\echo '║     • "Seq Scan" = Slow (reads all rows)                             ║'
\echo '║     • "Index Scan" = Fast (jumps to relevant rows)                   ║'
\echo '║                                                                        ║'
\echo '║  2. Cost values:                                                      ║'
\echo '║     • cost=0.00..67.19 (WITHOUT index) → Higher                      ║'
\echo '║     • cost=0.29..12.45 (WITH index) → Lower = Better!                ║'
\echo '║                                                                        ║'
\echo '║  3. Execution time:                                                   ║'
\echo '║     • actual time=0.015..2.456 (WITHOUT) → Slower                    ║'
\echo '║     • actual time=0.015..0.234 (WITH) → Faster = Better!             ║'
\echo '║                                                                        ║'
\echo '║  4. Time: values at bottom:                                           ║'
\echo '║     • Compare milliseconds between WITH and WITHOUT                   ║'
\echo '║     • WITH index should be 5-10x faster!                             ║'
\echo '║                                                                        ║'
\echo '╚════════════════════════════════════════════════════════════════════════╝'
\echo ''
\echo 'KEY METRICS TO COMPARE:'
\echo ''
\echo '┌─────────────────────┬──────────────────┬──────────────────┐'
\echo '│ Metric              │ Without Index    │ With Index       │'
\echo '├─────────────────────┼──────────────────┼──────────────────┤'
\echo '│ Scan Type           │ Seq Scan         │ Index Scan       │'
\echo '│ Cost                │ Higher (30-70)   │ Lower (5-15)     │'
\echo '│ Execution Time      │ 2-5 ms           │ 0.2-0.5 ms       │'
\echo '│ Buffer Reads        │ 30-50 pages      │ 3-8 pages        │'
\echo '│ Performance         │ ❌ Slow           │ ✅ Fast (5-10x)   │'
\echo '└─────────────────────┴──────────────────┴──────────────────┘'
\echo ''
\echo '✅ Indexes provide DRAMATIC performance improvements!'
\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''

-- Show current indexes
\echo 'Current indexes on rental table:'
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'rental' 
  AND schemaname = 'public'
ORDER BY indexname;

\echo ''
\echo 'Current indexes on vehicle table:'
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'vehicle' 
  AND schemaname = 'public'
ORDER BY indexname;

\echo ''
\timing off





