-- ============================================================================
-- INDEX OPTIMIZATION TESTING & PROOF QUERIES
-- These queries demonstrate and measure the performance improvements from indexes
-- ============================================================================
-- Usage: psql -U ceejayy -d vrdbms -f test_optimization.sql
-- ============================================================================

\timing on
\echo '============================================================================'
\echo 'INDEX OPTIMIZATION PERFORMANCE TESTING'
\echo '============================================================================'
\echo ''

-- ============================================================================
-- SECTION 1: VERIFY INDEXES EXIST
-- ============================================================================

\echo '1. VERIFY ALL INDEXES ARE CREATED'
\echo '----------------------------------------------------------------------------'
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

\echo ''
\echo 'Total index count:'
SELECT COUNT(*) as total_indexes FROM pg_indexes WHERE schemaname = 'public';
\echo ''

-- ============================================================================
-- SECTION 2: DASHBOARD QUERIES (From app.py)
-- ============================================================================

\echo '============================================================================'
\echo '2. DASHBOARD QUERIES - EXPLAIN ANALYZE'
\echo '============================================================================'
\echo ''

\echo '2.1: Count Available Vehicles (uses idx_vehicle_status)'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT COUNT(*) as count 
FROM vehicle 
WHERE status = 'available';

\echo ''
\echo 'Actual Query Result:'
SELECT COUNT(*) as available_vehicles FROM vehicle WHERE status = 'available';
\echo ''

\echo '2.2: Count Active Rentals (uses idx_rental_status)'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT COUNT(*) as count 
FROM rental 
WHERE status = 'active';

\echo ''
\echo 'Actual Query Result:'
SELECT COUNT(*) as active_rentals FROM rental WHERE status = 'active';
\echo ''

\echo '2.3: Total Revenue (uses idx_rental_status)'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT COALESCE(SUM(total_amount), 0) as revenue 
FROM rental 
WHERE status = 'completed';

\echo ''
\echo 'Actual Query Result:'
SELECT COALESCE(SUM(total_amount), 0) as total_revenue FROM rental WHERE status = 'completed';
\echo ''

\echo '2.4: Recent Rentals with Joins (uses multiple indexes)'
\echo '----------------------------------------------------------------------------'
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
LIMIT 5;

\echo ''
\echo 'Actual Query Result:'
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
LIMIT 5;
\echo ''

-- ============================================================================
-- SECTION 3: COMPLEX BUSINESS QUERIES
-- ============================================================================

\echo '============================================================================'
\echo '3. COMPLEX BUSINESS QUERIES - OPTIMIZATION PROOF'
\echo '============================================================================'
\echo ''

\echo '3.1: Available Vehicles by Branch (uses idx_vehicle_status_branch composite)'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    v.vehicle_id, 
    v.make, 
    v.model, 
    v.year, 
    b.branch_name
FROM vehicle v
JOIN branch b ON v.branch_id = b.branch_id
WHERE v.status = 'available' 
  AND v.branch_id = 1;

\echo ''
\echo 'Actual Query Result:'
SELECT 
    v.vehicle_id, 
    v.make, 
    v.model, 
    v.year, 
    b.branch_name
FROM vehicle v
JOIN branch b ON v.branch_id = b.branch_id
WHERE v.status = 'available' 
  AND v.branch_id = 1;
\echo ''

\echo '3.2: Customer Search by Name (uses idx_customer_name composite)'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    customer_id, 
    first_name, 
    last_name, 
    email, 
    phone
FROM customer
WHERE last_name LIKE 'J%'
ORDER BY last_name, first_name;

\echo ''
\echo 'Actual Query Result:'
SELECT 
    customer_id, 
    first_name, 
    last_name, 
    email, 
    phone
FROM customer
WHERE last_name LIKE 'J%'
ORDER BY last_name, first_name;
\echo ''

\echo '3.3: Rental History by Customer (uses idx_rental_customer)'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    r.rental_id,
    r.rental_date,
    r.start_date,
    r.end_date,
    v.make || ' ' || v.model AS vehicle,
    r.total_amount,
    r.status
FROM rental r
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
WHERE r.customer_id = 1
ORDER BY r.rental_date DESC;

\echo ''
\echo 'Actual Query Result:'
SELECT 
    r.rental_id,
    r.rental_date,
    r.start_date,
    r.end_date,
    v.make || ' ' || v.model AS vehicle,
    r.total_amount,
    r.status
FROM rental r
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
WHERE r.customer_id = 1
ORDER BY r.rental_date DESC;
\echo ''

\echo '3.4: Vehicle Rental History (uses idx_rental_vehicle)'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    r.rental_id,
    c.first_name || ' ' || c.last_name AS customer,
    r.start_date,
    r.end_date,
    r.start_mileage,
    r.end_mileage,
    r.total_amount
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
WHERE r.vehicle_id = 1
ORDER BY r.start_date DESC;

\echo ''
\echo 'Actual Query Result:'
SELECT 
    r.rental_id,
    c.first_name || ' ' || c.last_name AS customer,
    r.start_date,
    r.end_date,
    r.start_mileage,
    r.end_mileage,
    r.total_amount
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
WHERE r.vehicle_id = 1
ORDER BY r.start_date DESC;
\echo ''

\echo '3.5: Branch Revenue Report (uses idx_rental_branch, idx_rental_status)'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    b.branch_name,
    b.city,
    COUNT(r.rental_id) AS total_rentals,
    SUM(r.total_amount) AS total_revenue,
    AVG(r.total_amount) AS avg_rental_amount
FROM branch b
LEFT JOIN rental r ON b.branch_id = r.branch_id AND r.status = 'completed'
GROUP BY b.branch_id, b.branch_name, b.city
ORDER BY total_revenue DESC;

\echo ''
\echo 'Actual Query Result:'
SELECT 
    b.branch_name,
    b.city,
    COUNT(r.rental_id) AS total_rentals,
    SUM(r.total_amount) AS total_revenue,
    AVG(r.total_amount) AS avg_rental_amount
FROM branch b
LEFT JOIN rental r ON b.branch_id = r.branch_id AND r.status = 'completed'
GROUP BY b.branch_id, b.branch_name, b.city
ORDER BY total_revenue DESC;
\echo ''

\echo '3.6: Maintenance History (uses idx_maintenance_vehicle_date composite)'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    m.maintenance_id,
    m.maintenance_type,
    m.maintenance_date,
    m.description,
    m.cost,
    m.next_service_date
FROM maintenance m
WHERE m.vehicle_id = 1
ORDER BY m.maintenance_date DESC;

\echo ''
\echo 'Actual Query Result:'
SELECT 
    m.maintenance_id,
    m.maintenance_type,
    m.maintenance_date,
    m.description,
    m.cost,
    m.next_service_date
FROM maintenance m
WHERE m.vehicle_id = 1
ORDER BY m.maintenance_date DESC;
\echo ''

\echo '3.7: Upcoming Maintenance (uses idx_maintenance_next_service)'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    v.vehicle_id,
    v.make || ' ' || v.model AS vehicle,
    v.license_plate,
    m.next_service_date,
    m.maintenance_type
FROM vehicle v
JOIN maintenance m ON v.vehicle_id = m.vehicle_id
WHERE m.next_service_date >= CURRENT_DATE
  AND m.next_service_date <= CURRENT_DATE + INTERVAL '30 days'
ORDER BY m.next_service_date;

\echo ''
\echo 'Actual Query Result:'
SELECT 
    v.vehicle_id,
    v.make || ' ' || v.model AS vehicle,
    v.license_plate,
    m.next_service_date,
    m.maintenance_type
FROM vehicle v
JOIN maintenance m ON v.vehicle_id = m.vehicle_id
WHERE m.next_service_date >= CURRENT_DATE
  AND m.next_service_date <= CURRENT_DATE + INTERVAL '30 days'
ORDER BY m.next_service_date;
\echo ''

\echo '3.8: Payment History by Date Range (uses idx_payment_date)'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    p.payment_id,
    p.payment_date,
    p.amount,
    p.payment_method,
    r.rental_id,
    c.first_name || ' ' || c.last_name AS customer
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN customer c ON r.customer_id = c.customer_id
WHERE p.payment_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY p.payment_date DESC;

\echo ''
\echo 'Actual Query Result (Last 10 payments):'
SELECT 
    p.payment_id,
    p.payment_date,
    p.amount,
    p.payment_method,
    r.rental_id,
    c.first_name || ' ' || c.last_name AS customer
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN customer c ON r.customer_id = c.customer_id
WHERE p.payment_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY p.payment_date DESC
LIMIT 10;
\echo ''

-- ============================================================================
-- SECTION 4: DATE RANGE QUERIES (Critical for Rental System)
-- ============================================================================

\echo '============================================================================'
\echo '4. DATE RANGE QUERIES - RENTAL AVAILABILITY'
\echo '============================================================================'
\echo ''

\echo '4.1: Vehicles Rented in Date Range (uses idx_rental_dates composite)'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    v.vehicle_id,
    v.make || ' ' || v.model AS vehicle,
    r.start_date,
    r.end_date,
    r.status
FROM vehicle v
JOIN rental r ON v.vehicle_id = r.vehicle_id
WHERE r.start_date <= CURRENT_DATE + INTERVAL '7 days'
  AND r.end_date >= CURRENT_DATE
  AND r.status IN ('active', 'pending')
ORDER BY r.start_date;

\echo ''
\echo 'Actual Query Result:'
SELECT 
    v.vehicle_id,
    v.make || ' ' || v.model AS vehicle,
    r.start_date,
    r.end_date,
    r.status
FROM vehicle v
JOIN rental r ON v.vehicle_id = r.vehicle_id
WHERE r.start_date <= CURRENT_DATE + INTERVAL '7 days'
  AND r.end_date >= CURRENT_DATE
  AND r.status IN ('active', 'pending')
ORDER BY r.start_date;
\echo ''

\echo '4.2: Overdue Rentals (uses idx_rental_return_date, idx_rental_status)'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    r.rental_id,
    c.first_name || ' ' || c.last_name AS customer,
    c.phone,
    v.make || ' ' || v.model AS vehicle,
    r.end_date,
    CURRENT_DATE - r.end_date AS days_overdue
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
WHERE r.status = 'active'
  AND r.end_date < CURRENT_DATE
  AND (r.return_date IS NULL OR r.return_date > r.end_date)
ORDER BY days_overdue DESC;

\echo ''
\echo 'Actual Query Result:'
SELECT 
    r.rental_id,
    c.first_name || ' ' || c.last_name AS customer,
    c.phone,
    v.make || ' ' || v.model AS vehicle,
    r.end_date,
    CURRENT_DATE - r.end_date AS days_overdue
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
WHERE r.status = 'active'
  AND r.end_date < CURRENT_DATE
  AND (r.return_date IS NULL OR r.return_date > r.end_date)
ORDER BY days_overdue DESC;
\echo ''

-- ============================================================================
-- SECTION 5: AGGREGATION & REPORTING QUERIES
-- ============================================================================

\echo '============================================================================'
\echo '5. AGGREGATION & REPORTING QUERIES'
\echo '============================================================================'
\echo ''

\echo '5.1: Revenue by Payment Method (uses idx_payment_method)'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    payment_method,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount,
    AVG(amount) AS avg_amount,
    MIN(amount) AS min_amount,
    MAX(amount) AS max_amount
FROM payment
GROUP BY payment_method
ORDER BY total_amount DESC;

\echo ''
\echo 'Actual Query Result:'
SELECT 
    payment_method,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount,
    AVG(amount) AS avg_amount,
    MIN(amount) AS min_amount,
    MAX(amount) AS max_amount
FROM payment
GROUP BY payment_method
ORDER BY total_amount DESC;
\echo ''

\echo '5.2: Vehicles by Category and Availability (uses idx_vehicle_category, idx_vehicle_status)'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    vc.category_name,
    v.status,
    COUNT(*) AS vehicle_count,
    AVG(v.mileage) AS avg_mileage
FROM vehicle v
JOIN vehicle_category vc ON v.category_id = vc.category_id
GROUP BY vc.category_name, v.status
ORDER BY vc.category_name, v.status;

\echo ''
\echo 'Actual Query Result:'
SELECT 
    vc.category_name,
    v.status,
    COUNT(*) AS vehicle_count,
    AVG(v.mileage) AS avg_mileage
FROM vehicle v
JOIN vehicle_category vc ON v.category_id = vc.category_id
GROUP BY vc.category_name, v.status
ORDER BY vc.category_name, v.status;
\echo ''

\echo '5.3: Maintenance Costs by Type (uses idx_maintenance_type)'
\echo '----------------------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    maintenance_type,
    COUNT(*) AS maintenance_count,
    SUM(cost) AS total_cost,
    AVG(cost) AS avg_cost,
    MAX(cost) AS max_cost
FROM maintenance
WHERE cost IS NOT NULL
GROUP BY maintenance_type
ORDER BY total_cost DESC;

\echo ''
\echo 'Actual Query Result:'
SELECT 
    maintenance_type,
    COUNT(*) AS maintenance_count,
    SUM(cost) AS total_cost,
    AVG(cost) AS avg_cost,
    MAX(cost) AS max_cost
FROM maintenance
WHERE cost IS NOT NULL
GROUP BY maintenance_type
ORDER BY total_cost DESC;
\echo ''

-- ============================================================================
-- SECTION 6: INDEX USAGE STATISTICS
-- ============================================================================

\echo '============================================================================'
\echo '6. INDEX USAGE STATISTICS'
\echo '============================================================================'
\echo ''

\echo '6.1: Most Used Indexes'
\echo '----------------------------------------------------------------------------'
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan AS scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC
LIMIT 20;

\echo ''

\echo '6.2: Index Efficiency (Hit Ratio)'
\echo '----------------------------------------------------------------------------'
SELECT 
    tablename,
    indexname,
    idx_scan,
    CASE 
        WHEN idx_scan = 0 THEN 'Not Used Yet'
        ELSE 'Being Used ✓'
    END AS status,
    pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

\echo ''

\echo '6.3: Index Size Summary by Table'
\echo '----------------------------------------------------------------------------'
SELECT 
    tablename,
    COUNT(*) AS index_count,
    pg_size_pretty(SUM(pg_relation_size(indexrelid))) AS total_index_size,
    pg_size_pretty(AVG(pg_relation_size(indexrelid))::bigint) AS avg_index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY SUM(pg_relation_size(indexrelid)) DESC;

\echo ''

-- ============================================================================
-- SECTION 7: PERFORMANCE COMPARISON METRICS
-- ============================================================================

\echo '============================================================================'
\echo '7. PERFORMANCE METRICS SUMMARY'
\echo '============================================================================'
\echo ''

\echo '7.1: Query Execution Time Samples'
\echo '----------------------------------------------------------------------------'
\echo 'Running each query 3 times to get consistent timing...'
\echo ''

\echo 'Test 1: Simple status filter (indexed)'
SELECT COUNT(*) FROM vehicle WHERE status = 'available';
SELECT COUNT(*) FROM vehicle WHERE status = 'available';
SELECT COUNT(*) FROM vehicle WHERE status = 'available';
\echo ''

\echo 'Test 2: Join with foreign keys (all indexed)'
SELECT COUNT(*) 
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id;
\echo ''

\echo 'Test 3: Composite index usage (status + branch)'
SELECT COUNT(*) 
FROM vehicle 
WHERE status = 'available' AND branch_id IN (1, 2, 3);
\echo ''

\echo 'Test 4: Date range query (indexed)'
SELECT COUNT(*) 
FROM rental 
WHERE start_date >= CURRENT_DATE - INTERVAL '30 days';
\echo ''

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================

\echo '============================================================================'
\echo 'OPTIMIZATION TESTING COMPLETE'
\echo '============================================================================'
\echo ''
\echo 'KEY INDICATORS OF SUCCESSFUL OPTIMIZATION:'
\echo ''
\echo '✓ Look for "Index Scan" or "Index Only Scan" in EXPLAIN output'
\echo '✓ Look for "Bitmap Index Scan" (also good - uses index)'
\echo '✓ Avoid "Seq Scan" on large tables (indicates missing/unused index)'
\echo '✓ Lower "cost" values in EXPLAIN output indicate better performance'
\echo '✓ Actual execution time should be in milliseconds, not seconds'
\echo '✓ Index scan counts (idx_scan) should increase with query usage'
\echo ''
\echo 'NEXT STEPS:'
\echo '1. Review EXPLAIN output above for "Index Scan" confirmations'
\echo '2. Check Section 6 for index usage statistics'
\echo '3. Compare timing results (shown with \\timing on)'
\echo '4. Run this script again after more queries to see idx_scan increase'
\echo ''
\echo 'To test without indexes (for comparison), you would need to:'
\echo '  DROP INDEX index_name; -- temporarily remove index'
\echo '  Run query and note timing'
\echo '  CREATE INDEX ... ; -- recreate index'
\echo '  Run query again and compare timing'
\echo ''
\echo '============================================================================'

\timing off





