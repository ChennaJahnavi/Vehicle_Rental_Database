-- ============================================================================
-- ADD INDEXES TO EXISTING VRDBMS DATABASE
-- Run this script to add performance optimization indexes without recreating tables
-- ============================================================================
-- Usage: psql -U ceejayy -d vrdbms -f add_indexes.sql
-- ============================================================================

\echo '============================================================================'
\echo 'Adding Performance Optimization Indexes to VRDBMS'
\echo '============================================================================'

-- Branch table indexes
\echo 'Creating indexes for BRANCH table...'
CREATE INDEX IF NOT EXISTS idx_branch_city ON branch(city);
CREATE INDEX IF NOT EXISTS idx_branch_state ON branch(state);
CREATE INDEX IF NOT EXISTS idx_branch_location ON branch(city, state);

-- Vehicle Category table indexes
\echo 'Creating indexes for VEHICLE_CATEGORY table...'
CREATE INDEX IF NOT EXISTS idx_category_rate ON vehicle_category(daily_rate);
CREATE INDEX IF NOT EXISTS idx_category_capacity ON vehicle_category(seating_capacity);

-- Vehicle table indexes
\echo 'Creating indexes for VEHICLE table...'
CREATE INDEX IF NOT EXISTS idx_vehicle_status ON vehicle(status);
CREATE INDEX IF NOT EXISTS idx_vehicle_branch ON vehicle(branch_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_category ON vehicle(category_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_status_branch ON vehicle(status, branch_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_license_plate ON vehicle(license_plate);
CREATE INDEX IF NOT EXISTS idx_vehicle_make_model ON vehicle(make, model);

-- Customer table indexes
\echo 'Creating indexes for CUSTOMER table...'
CREATE INDEX IF NOT EXISTS idx_customer_email ON customer(email);
CREATE INDEX IF NOT EXISTS idx_customer_phone ON customer(phone);
CREATE INDEX IF NOT EXISTS idx_customer_name ON customer(last_name, first_name);
CREATE INDEX IF NOT EXISTS idx_customer_city ON customer(city);

-- Employee table indexes
\echo 'Creating indexes for EMPLOYEE table...'
CREATE INDEX IF NOT EXISTS idx_employee_branch ON employee(branch_id);
CREATE INDEX IF NOT EXISTS idx_employee_position ON employee(position);

-- Rental table indexes
\echo 'Creating indexes for RENTAL table...'
CREATE INDEX IF NOT EXISTS idx_rental_customer ON rental(customer_id);
CREATE INDEX IF NOT EXISTS idx_rental_vehicle ON rental(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_rental_status ON rental(status);
CREATE INDEX IF NOT EXISTS idx_rental_dates ON rental(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_rental_branch ON rental(branch_id);
CREATE INDEX IF NOT EXISTS idx_rental_status_date ON rental(status, rental_date DESC);
CREATE INDEX IF NOT EXISTS idx_rental_employee ON rental(employee_id);
CREATE INDEX IF NOT EXISTS idx_rental_return_date ON rental(return_date);

-- Payment table indexes
\echo 'Creating indexes for PAYMENT table...'
CREATE INDEX IF NOT EXISTS idx_payment_rental ON payment(rental_id);
CREATE INDEX IF NOT EXISTS idx_payment_date ON payment(payment_date);
CREATE INDEX IF NOT EXISTS idx_payment_method ON payment(payment_method);
CREATE INDEX IF NOT EXISTS idx_payment_date_amount ON payment(payment_date DESC, amount);

-- Maintenance table indexes
\echo 'Creating indexes for MAINTENANCE table...'
CREATE INDEX IF NOT EXISTS idx_maintenance_vehicle ON maintenance(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_date ON maintenance(maintenance_date);
CREATE INDEX IF NOT EXISTS idx_maintenance_type ON maintenance(maintenance_type);
CREATE INDEX IF NOT EXISTS idx_maintenance_next_service ON maintenance(next_service_date);
CREATE INDEX IF NOT EXISTS idx_maintenance_vehicle_date ON maintenance(vehicle_id, maintenance_date DESC);

\echo '============================================================================'
\echo 'Index Creation Complete!'
\echo '============================================================================'
\echo ''
\echo 'Summary:'
\echo '  - Branch:          3 indexes'
\echo '  - Vehicle Category: 2 indexes'
\echo '  - Vehicle:         6 indexes'
\echo '  - Customer:        4 indexes'
\echo '  - Employee:        2 indexes'
\echo '  - Rental:          8 indexes'
\echo '  - Payment:         4 indexes'
\echo '  - Maintenance:     5 indexes'
\echo '  - TOTAL:          34 indexes'
\echo ''
\echo 'Check index usage with:'
\echo '  SELECT tablename, indexname, idx_scan FROM pg_stat_user_indexes ORDER BY idx_scan DESC;'
\echo ''





