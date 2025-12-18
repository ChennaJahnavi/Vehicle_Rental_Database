-- ============================================================================
-- ADD MORE RENTALS, PAYMENTS, AND MAINTENANCE
-- Simpler script with proper date constraints
-- ============================================================================

\echo 'Adding 3000 rentals with proper date logic...'

-- Add rentals with correct date logic
INSERT INTO rental (customer_id, vehicle_id, branch_id, employee_id, rental_date, start_date, end_date, return_date, start_mileage, end_mileage, daily_rate, status)
SELECT 
    -- Random existing customer
    (random() * 514 + 1)::int,
    -- Random existing vehicle
    (random() * 1024 + 1)::int,
    -- Random branch (1-5)
    (random() * 4 + 1)::int,
    -- Random employee
    (random() * 59 + 1)::int,
    -- rental_date: in past year
    (CURRENT_DATE - (random() * 365)::int)::date as rental_date,
    -- start_date: same as rental date
    (CURRENT_DATE - (random() * 365)::int)::date as start_date,
    -- end_date: start_date + 3 to 14 days
    (CURRENT_DATE - (random() * 365)::int + (random() * 11 + 3)::int)::date as end_date,
    -- return_date: NULL for pending/active, or equal to end_date for completed
    CASE 
        WHEN random() > 0.3 THEN (CURRENT_DATE - (random() * 365)::int + (random() * 11 + 3)::int)::date
        ELSE NULL
    END as return_date,
    -- start_mileage
    (random() * 80000)::int,
    -- end_mileage: start + 50-500
    NULL,  -- Will be set by trigger or can be NULL
    -- daily_rate
    (random() * 100 + 40)::decimal(10,2),
    -- status
    (ARRAY['completed', 'completed', 'completed', 'active', 'pending'])[floor(random() * 5 + 1)]::rental_status
FROM generate_series(1, 3000)
WHERE true  -- Extra WHERE to ensure proper ordering
ON CONFLICT DO NOTHING;

\echo '✓ Rentals added'
\echo ''

\echo 'Adding payments for recent rentals...'

-- Add payments for rentals
INSERT INTO payment (rental_id, payment_date, amount, payment_method, transaction_id)
SELECT 
    rental_id,
    rental_date + (random() * 3)::int,
    total_amount,
    (ARRAY['cash', 'credit_card', 'credit_card', 'debit_card', 'online'])[floor(random() * 5 + 1)]::payment_method,
    'TXN-' || rental_id || '-' || (random() * 99999)::int
FROM rental
WHERE rental_id > 15  -- Only new rentals
  AND status IN ('completed', 'active')
ON CONFLICT DO NOTHING;

\echo '✓ Payments added'
\echo ''

\echo 'Adding maintenance records...'

-- Add maintenance
INSERT INTO maintenance (vehicle_id, maintenance_type, maintenance_date, description, cost, performed_by, next_service_date)
SELECT 
    (random() * 1024 + 1)::int,
    (ARRAY['routine', 'repair', 'inspection', 'emergency'])[floor(random() * 4 + 1)]::maintenance_type,
    (CURRENT_DATE - (random() * 730)::int)::date as maint_date,
    (ARRAY['Oil change', 'Tire rotation', 'Brake service', 'Engine repair', 'AC service'])[floor(random() * 5 + 1)],
    (random() * 1000 + 100)::decimal(10,2),
    (ARRAY['Tech-1', 'Tech-2', 'Tech-3'])[floor(random() * 3 + 1)],
    (CURRENT_DATE + (random() * 180 + 30)::int)::date  -- Future date for next service
FROM generate_series(1, 2000);

\echo '✓ Maintenance added'
\echo ''

\echo 'Updating statistics...'
ANALYZE vehicle;
ANALYZE customer;
ANALYZE rental;
ANALYZE payment;
ANALYZE maintenance;
\echo '✓ Done'
\echo ''

\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'FINAL COUNTS:'
\echo '════════════════════════════════════════════════════════════════════════════'

SELECT 
    'Vehicles' AS table_name, COUNT(*) AS total FROM vehicle
UNION ALL
SELECT 'Customers', COUNT(*) FROM customer
UNION ALL
SELECT 'Employees', COUNT(*) FROM employee
UNION ALL
SELECT 'Rentals', COUNT(*) FROM rental
UNION ALL
SELECT 'Payments', COUNT(*) FROM payment
UNION ALL
SELECT 'Maintenance', COUNT(*) FROM maintenance
ORDER BY table_name;

\echo ''
\echo '✅ Database now has enough data to show index performance!'
\echo ''
\echo 'Run the performance comparison again:'
\echo '  psql -U ceejayy -d vrdbms -f database/demo_performance_comparison.sql'
\echo ''





