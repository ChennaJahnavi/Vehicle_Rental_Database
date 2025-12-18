-- ============================================================================
-- DEMONSTRATION: Database Performance WITHOUT INDEXES
-- This script temporarily removes indexes to show performance degradation
-- ============================================================================
-- ⚠️  WARNING: This script drops indexes temporarily!
-- Run this FIRST, then run demo_with_indexes.sql to compare
-- ============================================================================

\timing on

\echo '============================================================================'
\echo '  DEMONSTRATION: WITHOUT INDEXES (Baseline Performance)'
\echo '============================================================================'
\echo ''
\echo '⚠️  This demo will:'
\echo '    1. Drop indexes temporarily'
\echo '    2. Run queries to measure performance'
\echo '    3. Show you the "before" state'
\echo ''
\echo 'Press Ctrl+C to cancel, or Enter to continue...'
\prompt 'Continue? ' dummy
\echo ''

-- Save current state
\echo 'Saving list of indexes to restore later...'
\o /tmp/vrdbms_indexes_backup.sql
SELECT 'CREATE INDEX ' || indexname || ' ON ' || tablename || 
       regexp_replace(indexdef, '.*\(', ' (', '') || ';'
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname NOT LIKE '%_pkey'
  AND indexname NOT LIKE '%_key'
  AND tablename NOT IN ('pg_stat_statements');
\o

\echo '✓ Index definitions saved'
\echo ''

-- Drop indexes (except primary keys and unique constraints)
\echo 'Dropping performance indexes...'
DROP INDEX IF EXISTS idx_branch_city;
DROP INDEX IF EXISTS idx_branch_state;
DROP INDEX IF EXISTS idx_branch_location;
DROP INDEX IF EXISTS idx_category_rate;
DROP INDEX IF EXISTS idx_category_capacity;
DROP INDEX IF EXISTS idx_vehicle_status;
DROP INDEX IF EXISTS idx_vehicle_branch;
DROP INDEX IF EXISTS idx_vehicle_category;
DROP INDEX IF EXISTS idx_vehicle_status_branch;
DROP INDEX IF EXISTS idx_vehicle_license_plate;
DROP INDEX IF EXISTS idx_vehicle_make_model;
DROP INDEX IF EXISTS idx_customer_email;
DROP INDEX IF EXISTS idx_customer_phone;
DROP INDEX IF EXISTS idx_customer_name;
DROP INDEX IF EXISTS idx_customer_city;
DROP INDEX IF EXISTS idx_employee_branch;
DROP INDEX IF EXISTS idx_employee_position;
DROP INDEX IF EXISTS idx_rental_customer;
DROP INDEX IF EXISTS idx_rental_vehicle;
DROP INDEX IF EXISTS idx_rental_status;
DROP INDEX IF EXISTS idx_rental_dates;
DROP INDEX IF EXISTS idx_rental_branch;
DROP INDEX IF EXISTS idx_rental_status_date;
DROP INDEX IF EXISTS idx_rental_employee;
DROP INDEX IF EXISTS idx_rental_return_date;
DROP INDEX IF EXISTS idx_payment_rental;
DROP INDEX IF EXISTS idx_payment_date;
DROP INDEX IF EXISTS idx_payment_method;
DROP INDEX IF EXISTS idx_payment_date_amount;
DROP INDEX IF EXISTS idx_maintenance_vehicle;
DROP INDEX IF EXISTS idx_maintenance_date;
DROP INDEX IF EXISTS idx_maintenance_type;
DROP INDEX IF EXISTS idx_maintenance_next_service;
DROP INDEX IF EXISTS idx_maintenance_vehicle_date;

\echo '✓ All performance indexes dropped'
\echo ''

\echo '============================================================================'
\echo 'TEST 1: Count Available Vehicles (WITHOUT INDEX)'
\echo '============================================================================'
EXPLAIN (ANALYZE, BUFFERS, COSTS) 
SELECT COUNT(*) FROM vehicle WHERE status = 'available';

\echo ''
\echo 'Running 5 times to get consistent timing:'
SELECT COUNT(*) FROM vehicle WHERE status = 'available';
SELECT COUNT(*) FROM vehicle WHERE status = 'available';
SELECT COUNT(*) FROM vehicle WHERE status = 'available';
SELECT COUNT(*) FROM vehicle WHERE status = 'available';
SELECT COUNT(*) FROM vehicle WHERE status = 'available';
\echo ''

\echo '============================================================================'
\echo 'TEST 2: Customer Search by Name (WITHOUT INDEX)'
\echo '============================================================================'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT customer_id, first_name, last_name, email 
FROM customer 
WHERE last_name LIKE 'J%' 
ORDER BY last_name, first_name;

\echo ''
\echo 'Running 3 times:'
SELECT COUNT(*) FROM customer WHERE last_name LIKE 'J%';
SELECT COUNT(*) FROM customer WHERE last_name LIKE 'J%';
SELECT COUNT(*) FROM customer WHERE last_name LIKE 'J%';
\echo ''

\echo '============================================================================'
\echo 'TEST 3: Customer Rental History (WITHOUT INDEX)'
\echo '============================================================================'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    r.rental_id,
    r.rental_date,
    v.make || ' ' || v.model AS vehicle,
    r.total_amount
FROM rental r
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
WHERE r.customer_id = 1;

\echo ''
\echo 'Running 3 times:'
SELECT COUNT(*) FROM rental WHERE customer_id = 1;
SELECT COUNT(*) FROM rental WHERE customer_id = 1;
SELECT COUNT(*) FROM rental WHERE customer_id = 1;
\echo ''

\echo '============================================================================'
\echo 'TEST 4: Available Vehicles by Branch (WITHOUT INDEX)'
\echo '============================================================================'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT COUNT(*) 
FROM vehicle 
WHERE status = 'available' AND branch_id = 1;

\echo ''
\echo 'Running 5 times:'
SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;
SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;
SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;
SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;
SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;
\echo ''

\echo '============================================================================'
\echo 'TEST 5: Recent Rentals (Dashboard Query) (WITHOUT INDEX)'
\echo '============================================================================'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    r.rental_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    v.make || ' ' || v.model AS vehicle,
    r.rental_date,
    r.status
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
ORDER BY r.rental_date DESC
LIMIT 10;

\echo ''
\echo 'Running 3 times:'
SELECT COUNT(*) FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id;

SELECT COUNT(*) FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id;

SELECT COUNT(*) FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id;
\echo ''

\echo '============================================================================'
\echo 'TEST 6: Branch Revenue Report (WITHOUT INDEX)'
\echo '============================================================================'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    b.branch_name,
    COUNT(r.rental_id) AS total_rentals,
    SUM(r.total_amount) AS total_revenue
FROM branch b
LEFT JOIN rental r ON b.branch_id = r.branch_id AND r.status = 'completed'
GROUP BY b.branch_id, b.branch_name
ORDER BY total_revenue DESC;

\echo ''
\echo 'Running 3 times:'
SELECT COUNT(*) FROM branch b
LEFT JOIN rental r ON b.branch_id = r.branch_id;

SELECT COUNT(*) FROM branch b
LEFT JOIN rental r ON b.branch_id = r.branch_id;

SELECT COUNT(*) FROM branch b
LEFT JOIN rental r ON b.branch_id = r.branch_id;
\echo ''

\echo '============================================================================'
\echo 'TEST 7: Rentals in Date Range (WITHOUT INDEX)'
\echo '============================================================================'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT COUNT(*) 
FROM rental 
WHERE start_date >= CURRENT_DATE - INTERVAL '30 days'
  AND end_date <= CURRENT_DATE + INTERVAL '30 days';

\echo ''
\echo 'Running 5 times:'
SELECT COUNT(*) FROM rental WHERE start_date >= CURRENT_DATE - INTERVAL '30 days';
SELECT COUNT(*) FROM rental WHERE start_date >= CURRENT_DATE - INTERVAL '30 days';
SELECT COUNT(*) FROM rental WHERE start_date >= CURRENT_DATE - INTERVAL '30 days';
SELECT COUNT(*) FROM rental WHERE start_date >= CURRENT_DATE - INTERVAL '30 days';
SELECT COUNT(*) FROM rental WHERE start_date >= CURRENT_DATE - INTERVAL '30 days';
\echo ''

\echo '============================================================================'
\echo 'SUMMARY: Performance WITHOUT INDEXES'
\echo '============================================================================'
\echo ''
\echo 'Key Observations:'
\echo '  - EXPLAIN shows "Seq Scan" (Sequential Scan = Full Table Scan)'
\echo '  - Higher execution times'
\echo '  - Higher cost values'
\echo '  - More buffer reads'
\echo ''
\echo '⚠️  Note the timing values above. Now run demo_with_indexes.sql to compare!'
\echo ''
\echo 'Current state: NO PERFORMANCE INDEXES'
\echo 'Index count:'
SELECT COUNT(*) AS remaining_indexes FROM pg_indexes WHERE schemaname = 'public';
\echo ''
\echo 'To restore indexes manually:'
\echo '  \\i /tmp/vrdbms_indexes_backup.sql'
\echo ''
\echo 'Or run: psql -U ceejayy -d vrdbms -f demo_with_indexes.sql'
\echo ''

\timing off





