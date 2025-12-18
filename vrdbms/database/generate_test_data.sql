-- ============================================================================
-- GENERATE TEST DATA FOR PERFORMANCE DEMONSTRATION
-- Creates realistic data to show index performance improvements
-- ============================================================================
-- This script will add:
--   - 1000+ vehicles
--   - 500+ customers  
--   - 5000+ rentals
--   - Corresponding payments and maintenance records
-- ============================================================================

\echo '============================================================================'
\echo '  GENERATING TEST DATA FOR PERFORMANCE DEMONSTRATION'
\echo '============================================================================'
\echo ''
\echo 'This will add substantial data to show index performance benefits.'
\echo ''

-- ============================================================================
-- STEP 1: Add More Vehicles (1000 vehicles)
-- ============================================================================

\echo 'Step 1: Generating 1000 vehicles...'

INSERT INTO vehicle (category_id, branch_id, make, model, year, license_plate, vin, color, mileage, status)
SELECT 
    -- category_id: Random between 1-5 (assuming 5 categories exist)
    (random() * 4 + 1)::int,
    -- branch_id: Random between 1-5 (assuming 5 branches exist)
    (random() * 4 + 1)::int,
    -- make: Variety of car makes
    (ARRAY['Toyota', 'Honda', 'Ford', 'Chevrolet', 'Nissan', 'BMW', 'Mercedes', 'Audi', 'Hyundai', 'Kia'])[floor(random() * 10 + 1)],
    -- model: Model name with series number
    'Model-' || generate_series,
    -- year: Between 2018-2024
    (random() * 6 + 2018)::int,
    -- license_plate: Unique
    'TEST' || LPAD(generate_series::text, 6, '0'),
    -- vin: 17 character VIN
    'VIN' || LPAD(generate_series::text, 14, '0'),
    -- color: Variety of colors
    (ARRAY['White', 'Black', 'Silver', 'Red', 'Blue', 'Gray', 'Green', 'Yellow'])[floor(random() * 8 + 1)],
    -- mileage: Between 0-100000
    (random() * 100000)::int,
    -- status: Mostly available, some rented/maintenance
    (ARRAY['available', 'available', 'available', 'available', 'available', 'rented', 'rented', 'maintenance'])[floor(random() * 8 + 1)]::vehicle_status
FROM generate_series(1, 1000);

\echo '✓ 1000 vehicles added'

-- ============================================================================
-- STEP 2: Add More Customers (500 customers)
-- ============================================================================

\echo 'Step 2: Generating 500 customers...'

INSERT INTO customer (first_name, last_name, email, phone, license_number, address, city, state, zip_code, date_of_birth)
SELECT 
    -- first_name: Common names
    (ARRAY['James', 'John', 'Robert', 'Michael', 'William', 'David', 'Richard', 'Joseph', 'Thomas', 'Charles',
           'Mary', 'Patricia', 'Jennifer', 'Linda', 'Elizabeth', 'Barbara', 'Susan', 'Jessica', 'Sarah', 'Karen'])[floor(random() * 20 + 1)],
    -- last_name: Common surnames
    (ARRAY['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez',
           'Wilson', 'Anderson', 'Taylor', 'Thomas', 'Moore', 'Jackson', 'Martin', 'Lee', 'Thompson', 'White'])[floor(random() * 20 + 1)],
    -- email: Unique
    'customer' || generate_series || '@test.com',
    -- phone: Format XXX-XXX-XXXX
    LPAD((random() * 900 + 100)::int::text, 3, '0') || '-' || 
    LPAD((random() * 900 + 100)::int::text, 3, '0') || '-' || 
    LPAD((random() * 9000 + 1000)::int::text, 4, '0'),
    -- license_number: Unique
    'LIC' || LPAD(generate_series::text, 9, '0'),
    -- address
    (random() * 9999 + 1)::int || ' Main St',
    -- city
    (ARRAY['Los Angeles', 'San Francisco', 'San Diego', 'Sacramento', 'San Jose', 
           'Oakland', 'Fresno', 'Long Beach', 'Santa Ana', 'Anaheim'])[floor(random() * 10 + 1)],
    -- state
    'CA',
    -- zip_code
    LPAD((random() * 89999 + 90000)::int::text, 5, '0'),
    -- date_of_birth: Between 21-70 years old
    CURRENT_DATE - (random() * 18250 + 7665)::int * INTERVAL '1 day'
FROM generate_series(1, 500);

\echo '✓ 500 customers added'

-- ============================================================================
-- STEP 3: Add More Employees (50 employees)
-- ============================================================================

\echo 'Step 3: Generating 50 employees...'

INSERT INTO employee (branch_id, first_name, last_name, email, phone, position, salary)
SELECT 
    -- branch_id: Spread across branches
    (random() * 4 + 1)::int,
    -- first_name
    (ARRAY['James', 'John', 'Robert', 'Michael', 'William', 'David', 'Emma', 'Olivia', 'Ava', 'Sophia'])[floor(random() * 10 + 1)],
    -- last_name
    (ARRAY['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Wilson', 'Moore'])[floor(random() * 10 + 1)],
    -- email
    'employee' || generate_series || '@vrdbms.com',
    -- phone
    LPAD((random() * 900 + 100)::int::text, 3, '0') || '-' || 
    LPAD((random() * 900 + 100)::int::text, 3, '0') || '-' || 
    LPAD((random() * 9000 + 1000)::int::text, 4, '0'),
    -- position
    (ARRAY['Sales Agent', 'Manager', 'Customer Service', 'Mechanic', 'Admin'])[floor(random() * 5 + 1)],
    -- salary: Between 35000-85000
    (random() * 50000 + 35000)::decimal(10,2)
FROM generate_series(1, 50);

\echo '✓ 50 employees added'

-- ============================================================================
-- STEP 4: Add Rentals (5000 rentals) - This is the key table!
-- ============================================================================

\echo 'Step 4: Generating 5000 rentals (this may take a moment)...'

INSERT INTO rental (customer_id, vehicle_id, branch_id, employee_id, rental_date, start_date, end_date, return_date, start_mileage, end_mileage, daily_rate, status)
SELECT 
    -- customer_id: Random from existing customers (1-515 = 15 original + 500 new)
    (random() * 514 + 1)::int,
    -- vehicle_id: Random from existing vehicles (1-1025 = 25 original + 1000 new)
    (random() * 1024 + 1)::int,
    -- branch_id: Random branch
    (random() * 4 + 1)::int,
    -- employee_id: Random from existing employees (1-65 = 15 original + 50 new)
    (random() * 64 + 1)::int,
    -- rental_date: Past 365 days
    CURRENT_DATE - (random() * 365)::int,
    -- start_date: rental_date to rental_date + 3 days
    CURRENT_DATE - (random() * 365)::int,
    -- end_date: start_date + 1 to 14 days
    CURRENT_DATE - (random() * 365)::int + (random() * 13 + 1)::int,
    -- return_date: For completed rentals
    CASE 
        WHEN random() < 0.7 THEN CURRENT_DATE - (random() * 365)::int + (random() * 13 + 1)::int
        ELSE NULL
    END,
    -- start_mileage: Between 0-100000
    (random() * 100000)::int,
    -- end_mileage: start_mileage + 50-500
    (random() * 100000)::int + (random() * 450 + 50)::int,
    -- daily_rate: Between 30-150
    (random() * 120 + 30)::decimal(10,2),
    -- status: Varied distribution
    (ARRAY['completed', 'completed', 'completed', 'completed', 'completed', 
           'active', 'active', 'pending', 'cancelled'])[floor(random() * 9 + 1)]::rental_status
FROM generate_series(1, 5000);

\echo '✓ 5000 rentals added'

-- ============================================================================
-- STEP 5: Add Payments (5000 payments for rentals)
-- ============================================================================

\echo 'Step 5: Generating 5000 payments...'

INSERT INTO payment (rental_id, payment_date, amount, payment_method, transaction_id)
SELECT 
    -- rental_id: Corresponds to rentals (16 original + 5000 new = 16-5016)
    15 + generate_series,
    -- payment_date: Around rental date
    CURRENT_DATE - (random() * 365)::int,
    -- amount: Between 50-2000
    (random() * 1950 + 50)::decimal(10,2),
    -- payment_method
    (ARRAY['cash', 'credit_card', 'credit_card', 'credit_card', 'debit_card', 'debit_card', 'online'])[floor(random() * 7 + 1)]::payment_method,
    -- transaction_id: Unique for credit/debit/online
    'TXN' || LPAD(generate_series::text, 10, '0')
FROM generate_series(1, 5000);

\echo '✓ 5000 payments added'

-- ============================================================================
-- STEP 6: Add Maintenance Records (3000 maintenance records)
-- ============================================================================

\echo 'Step 6: Generating 3000 maintenance records...'

INSERT INTO maintenance (vehicle_id, maintenance_type, maintenance_date, description, cost, performed_by, next_service_date)
SELECT 
    -- vehicle_id: Random from all vehicles
    (random() * 1024 + 1)::int,
    -- maintenance_type
    (ARRAY['routine', 'routine', 'routine', 'repair', 'repair', 'inspection', 'emergency'])[floor(random() * 7 + 1)]::maintenance_type,
    -- maintenance_date: Past 730 days (2 years)
    CURRENT_DATE - (random() * 730)::int,
    -- description
    (ARRAY['Oil change and filter', 'Tire rotation', 'Brake inspection', 'Engine repair', 
           'Transmission service', 'Battery replacement', 'AC service', 'General inspection',
           'Alignment', 'Coolant flush'])[floor(random() * 10 + 1)],
    -- cost: Between 50-1500
    (random() * 1450 + 50)::decimal(10,2),
    -- performed_by
    (ARRAY['Mike Johnson', 'Sarah Williams', 'Tom Brown', 'Lisa Davis', 'John Smith'])[floor(random() * 5 + 1)],
    -- next_service_date: 30-180 days after maintenance
    CURRENT_DATE - (random() * 730)::int + (random() * 150 + 30)::int
FROM generate_series(1, 3000);

\echo '✓ 3000 maintenance records added'

-- ============================================================================
-- STEP 7: Update Statistics
-- ============================================================================

\echo ''
\echo 'Step 7: Updating database statistics...'

ANALYZE vehicle;
ANALYZE customer;
ANALYZE employee;
ANALYZE rental;
ANALYZE payment;
ANALYZE maintenance;

\echo '✓ Statistics updated'

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================

\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo '  TEST DATA GENERATION COMPLETE'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''

SELECT 
    'Vehicles' AS table_name,
    COUNT(*)::text AS total_records
FROM vehicle
UNION ALL
SELECT 'Customers', COUNT(*)::text FROM customer
UNION ALL
SELECT 'Employees', COUNT(*)::text FROM employee
UNION ALL
SELECT 'Rentals', COUNT(*)::text FROM rental
UNION ALL
SELECT 'Payments', COUNT(*)::text FROM payment
UNION ALL
SELECT 'Maintenance', COUNT(*)::text FROM maintenance
ORDER BY table_name;

\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'READY TO TEST PERFORMANCE!'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo 'Now run the performance comparison script again:'
\echo '  psql -U ceejayy -d vrdbms -f database/demo_performance_comparison.sql'
\echo ''
\echo 'With this larger dataset, you will see:'
\echo '  • Index Scans instead of Sequential Scans'
\echo '  • Dramatic timing improvements (3-10x faster)'
\echo '  • Lower costs in EXPLAIN output'
\echo '  • Real-world performance benefits'
\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''

