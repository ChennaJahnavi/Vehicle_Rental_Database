-- ============================================================================
-- SINGLE-SCRIPT PERFORMANCE DEMONSTRATION
-- Shows query performance WITHOUT indexes, then WITH indexes
-- ============================================================================
-- This script will:
--   1. Run queries WITHOUT indexes (baseline)
--   2. Create indexes
--   3. Run SAME queries WITH indexes (optimized)
--   4. Show side-by-side comparison
-- ============================================================================

-- Drop all performance indexes first

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

-- ============================================================================
-- QUERY 1: Count Available Vehicles
-- ============================================================================

EXPLAIN (ANALYZE, BUFFERS, COSTS, TIMING)
SELECT COUNT(*) FROM vehicle WHERE status = 'available';

SELECT COUNT(*) as available_vehicles FROM vehicle WHERE status = 'available';
SELECT COUNT(*) as available_vehicles FROM vehicle WHERE status = 'available';
SELECT COUNT(*) as available_vehicles FROM vehicle WHERE status = 'available';
SELECT COUNT(*) as available_vehicles FROM vehicle WHERE status = 'available';
SELECT COUNT(*) as available_vehicles FROM vehicle WHERE status = 'available';

-- Create the index
CREATE INDEX idx_vehicle_status ON vehicle(status);
ANALYZE vehicle;

EXPLAIN (ANALYZE, BUFFERS, COSTS, TIMING)
SELECT COUNT(*) FROM vehicle WHERE status = 'available';

SELECT COUNT(*) as available_vehicles FROM vehicle WHERE status = 'available';
SELECT COUNT(*) as available_vehicles FROM vehicle WHERE status = 'available';
SELECT COUNT(*) as available_vehicles FROM vehicle WHERE status = 'available';
SELECT COUNT(*) as available_vehicles FROM vehicle WHERE status = 'available';
SELECT COUNT(*) as available_vehicles FROM vehicle WHERE status = 'available';

-- ============================================================================
-- QUERY 2: Customer Search by Name
-- ============================================================================

EXPLAIN (ANALYZE, BUFFERS, COSTS, TIMING)
SELECT customer_id, first_name, last_name, email, phone
FROM customer 
WHERE last_name LIKE 'J%'
ORDER BY last_name, first_name;

SELECT COUNT(*) FROM customer WHERE last_name LIKE 'J%';
SELECT COUNT(*) FROM customer WHERE last_name LIKE 'J%';
SELECT COUNT(*) FROM customer WHERE last_name LIKE 'J%';

-- Create the index
CREATE INDEX idx_customer_name ON customer(last_name, first_name);
ANALYZE customer;

EXPLAIN (ANALYZE, BUFFERS, COSTS, TIMING)
SELECT customer_id, first_name, last_name, email, phone
FROM customer 
WHERE last_name LIKE 'J%'
ORDER BY last_name, first_name;

SELECT COUNT(*) FROM customer WHERE last_name LIKE 'J%';
SELECT COUNT(*) FROM customer WHERE last_name LIKE 'J%';
SELECT COUNT(*) FROM customer WHERE last_name LIKE 'J%';

-- ============================================================================
-- QUERY 3: Rental History for Customer
-- ============================================================================

EXPLAIN (ANALYZE, BUFFERS, COSTS, TIMING)
SELECT 
    r.rental_id,
    r.rental_date,
    v.make || ' ' || v.model AS vehicle,
    r.total_amount,
    r.status
FROM rental r
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
WHERE r.customer_id = 1
ORDER BY r.rental_date DESC;

SELECT COUNT(*) FROM rental WHERE customer_id = 1;
SELECT COUNT(*) FROM rental WHERE customer_id = 1;
SELECT COUNT(*) FROM rental WHERE customer_id = 1;

CREATE INDEX idx_rental_customer ON rental(customer_id);
ANALYZE rental;

EXPLAIN (ANALYZE, BUFFERS, COSTS, TIMING)
SELECT 
    r.rental_id,
    r.rental_date,
    v.make || ' ' || v.model AS vehicle,
    r.total_amount,
    r.status
FROM rental r
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
WHERE r.customer_id = 1
ORDER BY r.rental_date DESC;

SELECT COUNT(*) FROM rental WHERE customer_id = 1;
SELECT COUNT(*) FROM rental WHERE customer_id = 1;
SELECT COUNT(*) FROM rental WHERE customer_id = 1;

-- ============================================================================
-- QUERY 4: Multi-Column Search
-- ============================================================================

EXPLAIN (ANALYZE, BUFFERS, COSTS, TIMING)
SELECT vehicle_id, make, model, year
FROM vehicle
WHERE status = 'available' AND branch_id = 1;

SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;
SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;
SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;
SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;
SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;

CREATE INDEX idx_vehicle_status_branch ON vehicle(status, branch_id);
CREATE INDEX idx_vehicle_branch ON vehicle(branch_id);
ANALYZE vehicle;

EXPLAIN (ANALYZE, BUFFERS, COSTS, TIMING)
SELECT vehicle_id, make, model, year
FROM vehicle
WHERE status = 'available' AND branch_id = 1;

SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;
SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;
SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;
SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;
SELECT COUNT(*) FROM vehicle WHERE status = 'available' AND branch_id = 1;

-- ============================================================================
-- QUERY 5: Date Range Query
-- ============================================================================

EXPLAIN (ANALYZE, BUFFERS, COSTS, TIMING)
SELECT rental_id, customer_id, start_date, end_date, total_amount
FROM rental
WHERE start_date >= CURRENT_DATE - INTERVAL '30 days'
  AND end_date <= CURRENT_DATE + INTERVAL '30 days';

SELECT COUNT(*) FROM rental WHERE start_date >= CURRENT_DATE - INTERVAL '30 days';
SELECT COUNT(*) FROM rental WHERE start_date >= CURRENT_DATE - INTERVAL '30 days';
SELECT COUNT(*) FROM rental WHERE start_date >= CURRENT_DATE - INTERVAL '30 days';

CREATE INDEX idx_rental_dates ON rental(start_date, end_date);
ANALYZE rental;

EXPLAIN (ANALYZE, BUFFERS, COSTS, TIMING)
SELECT rental_id, customer_id, start_date, end_date, total_amount
FROM rental
WHERE start_date >= CURRENT_DATE - INTERVAL '30 days'
  AND end_date <= CURRENT_DATE + INTERVAL '30 days';

SELECT COUNT(*) FROM rental WHERE start_date >= CURRENT_DATE - INTERVAL '30 days';
SELECT COUNT(*) FROM rental WHERE start_date >= CURRENT_DATE - INTERVAL '30 days';
SELECT COUNT(*) FROM rental WHERE start_date >= CURRENT_DATE - INTERVAL '30 days';

-- ============================================================================
-- COMPLETE ALL REMAINING INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_branch_city ON branch(city);
CREATE INDEX IF NOT EXISTS idx_branch_state ON branch(state);
CREATE INDEX IF NOT EXISTS idx_branch_location ON branch(city, state);

CREATE INDEX IF NOT EXISTS idx_category_rate ON vehicle_category(daily_rate);
CREATE INDEX IF NOT EXISTS idx_category_capacity ON vehicle_category(seating_capacity);

CREATE INDEX IF NOT EXISTS idx_vehicle_category ON vehicle(category_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_license_plate ON vehicle(license_plate);
CREATE INDEX IF NOT EXISTS idx_vehicle_make_model ON vehicle(make, model);

CREATE INDEX IF NOT EXISTS idx_customer_email ON customer(email);
CREATE INDEX IF NOT EXISTS idx_customer_phone ON customer(phone);
CREATE INDEX IF NOT EXISTS idx_customer_city ON customer(city);

CREATE INDEX IF NOT EXISTS idx_employee_branch ON employee(branch_id);
CREATE INDEX IF NOT EXISTS idx_employee_position ON employee(position);

CREATE INDEX IF NOT EXISTS idx_rental_vehicle ON rental(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_rental_status ON rental(status);
CREATE INDEX IF NOT EXISTS idx_rental_branch ON rental(branch_id);
CREATE INDEX IF NOT EXISTS idx_rental_status_date ON rental(status, rental_date DESC);
CREATE INDEX IF NOT EXISTS idx_rental_employee ON rental(employee_id);
CREATE INDEX IF NOT EXISTS idx_rental_return_date ON rental(return_date);

CREATE INDEX IF NOT EXISTS idx_payment_rental ON payment(rental_id);
CREATE INDEX IF NOT EXISTS idx_payment_date ON payment(payment_date);
CREATE INDEX IF NOT EXISTS idx_payment_method ON payment(payment_method);
CREATE INDEX IF NOT EXISTS idx_payment_date_amount ON payment(payment_date DESC, amount);

CREATE INDEX IF NOT EXISTS idx_maintenance_vehicle ON maintenance(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_date ON maintenance(maintenance_date);
CREATE INDEX IF NOT EXISTS idx_maintenance_type ON maintenance(maintenance_type);
CREATE INDEX IF NOT EXISTS idx_maintenance_next_service ON maintenance(next_service_date);
CREATE INDEX IF NOT EXISTS idx_maintenance_vehicle_date ON maintenance(vehicle_id, maintenance_date DESC);

ANALYZE;

SELECT 
    'Total Indexes' AS metric,
    COUNT(*)::text AS value
FROM pg_indexes 
WHERE schemaname = 'public'
UNION ALL
SELECT 
    'Database Size' AS metric,
    pg_size_pretty(pg_database_size('vrdbms')) AS value
UNION ALL
SELECT 
    'Index Size' AS metric,
    pg_size_pretty(SUM(pg_relation_size(indexrelid))) AS value
FROM pg_stat_user_indexes
WHERE schemaname = 'public';
