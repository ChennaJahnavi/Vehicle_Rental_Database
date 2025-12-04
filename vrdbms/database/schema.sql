-- ============================================================================
-- VEHICLE RENTAL DATABASE MANAGEMENT SYSTEM (VRDBMS)
-- Database Schema - PostgreSQL Implementation
-- ============================================================================

-- Drop existing tables if they exist (for clean setup)
DROP TABLE IF EXISTS maintenance CASCADE;
DROP TABLE IF EXISTS payment CASCADE;
DROP TABLE IF EXISTS rental CASCADE;
DROP TABLE IF EXISTS vehicle CASCADE;
DROP TABLE IF EXISTS customer CASCADE;
DROP TABLE IF EXISTS branch CASCADE;
DROP TABLE IF EXISTS employee CASCADE;
DROP TABLE IF EXISTS vehicle_category CASCADE;

-- Drop existing types if they exist
DROP TYPE IF EXISTS rental_status CASCADE;
DROP TYPE IF EXISTS payment_method CASCADE;
DROP TYPE IF EXISTS vehicle_status CASCADE;
DROP TYPE IF EXISTS maintenance_type CASCADE;

-- ============================================================================
-- CUSTOM TYPES
-- ============================================================================

CREATE TYPE rental_status AS ENUM ('pending', 'active', 'completed', 'cancelled');
CREATE TYPE payment_method AS ENUM ('cash', 'credit_card', 'debit_card', 'online');
CREATE TYPE vehicle_status AS ENUM ('available', 'rented', 'maintenance', 'retired');
CREATE TYPE maintenance_type AS ENUM ('routine', 'repair', 'inspection', 'emergency');

-- ============================================================================
-- TABLE: branch
-- Stores information about rental company branches
-- ============================================================================

CREATE TABLE branch (
    branch_id SERIAL PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    zip_code VARCHAR(10) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    manager_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_branch_phone UNIQUE(phone),
    CONSTRAINT unique_branch_email UNIQUE(email)
);

-- ============================================================================
-- TABLE: vehicle_category
-- Stores vehicle categories/types
-- ============================================================================

CREATE TABLE vehicle_category (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    daily_rate DECIMAL(10, 2) NOT NULL CHECK (daily_rate > 0),
    seating_capacity INTEGER NOT NULL CHECK (seating_capacity > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- TABLE: vehicle
-- Stores vehicle inventory information
-- ============================================================================

CREATE TABLE vehicle (
    vehicle_id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES vehicle_category(category_id) ON DELETE RESTRICT,
    branch_id INTEGER NOT NULL REFERENCES branch(branch_id) ON DELETE RESTRICT,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INTEGER NOT NULL CHECK (year >= 1900 AND year <= EXTRACT(YEAR FROM CURRENT_DATE) + 1),
    license_plate VARCHAR(20) NOT NULL UNIQUE,
    vin VARCHAR(17) UNIQUE,
    color VARCHAR(30),
    mileage INTEGER DEFAULT 0 CHECK (mileage >= 0),
    status vehicle_status DEFAULT 'available',
    last_maintenance_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_vehicle_status ON vehicle(status);
CREATE INDEX idx_vehicle_branch ON vehicle(branch_id);
CREATE INDEX idx_vehicle_category ON vehicle(category_id);

-- ============================================================================
-- TABLE: customer
-- Stores customer information
-- ============================================================================

CREATE TABLE customer (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    license_number VARCHAR(50) NOT NULL UNIQUE,
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    date_of_birth DATE NOT NULL,
    registration_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_age CHECK (EXTRACT(YEAR FROM AGE(date_of_birth)) >= 18)
);

CREATE INDEX idx_customer_email ON customer(email);
CREATE INDEX idx_customer_phone ON customer(phone);

-- ============================================================================
-- TABLE: employee
-- Stores employee information
-- ============================================================================

CREATE TABLE employee (
    employee_id SERIAL PRIMARY KEY,
    branch_id INTEGER NOT NULL REFERENCES branch(branch_id) ON DELETE RESTRICT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    position VARCHAR(50) NOT NULL,
    hire_date DATE DEFAULT CURRENT_DATE,
    salary DECIMAL(10, 2) CHECK (salary > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- TABLE: rental
-- Stores rental/booking information
-- ============================================================================

CREATE TABLE rental (
    rental_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customer(customer_id) ON DELETE RESTRICT,
    vehicle_id INTEGER NOT NULL REFERENCES vehicle(vehicle_id) ON DELETE RESTRICT,
    branch_id INTEGER NOT NULL REFERENCES branch(branch_id) ON DELETE RESTRICT,
    employee_id INTEGER REFERENCES employee(employee_id) ON DELETE SET NULL,
    rental_date DATE NOT NULL DEFAULT CURRENT_DATE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    return_date DATE,
    start_mileage INTEGER NOT NULL CHECK (start_mileage >= 0),
    end_mileage INTEGER CHECK (end_mileage >= start_mileage),
    daily_rate DECIMAL(10, 2) NOT NULL CHECK (daily_rate > 0),
    total_amount DECIMAL(10, 2),
    status rental_status DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_rental_dates CHECK (end_date >= start_date),
    CONSTRAINT check_return_date CHECK (return_date IS NULL OR return_date >= start_date)
);

CREATE INDEX idx_rental_customer ON rental(customer_id);
CREATE INDEX idx_rental_vehicle ON rental(vehicle_id);
CREATE INDEX idx_rental_status ON rental(status);
CREATE INDEX idx_rental_dates ON rental(start_date, end_date);

-- ============================================================================
-- TABLE: payment
-- Stores payment transaction information
-- ============================================================================

CREATE TABLE payment (
    payment_id SERIAL PRIMARY KEY,
    rental_id INTEGER NOT NULL REFERENCES rental(rental_id) ON DELETE CASCADE,
    payment_date DATE DEFAULT CURRENT_DATE,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    payment_method payment_method NOT NULL,
    transaction_id VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payment_rental ON payment(rental_id);
CREATE INDEX idx_payment_date ON payment(payment_date);

-- ============================================================================
-- TABLE: maintenance
-- Stores vehicle maintenance records
-- ============================================================================

CREATE TABLE maintenance (
    maintenance_id SERIAL PRIMARY KEY,
    vehicle_id INTEGER NOT NULL REFERENCES vehicle(vehicle_id) ON DELETE CASCADE,
    maintenance_type maintenance_type NOT NULL,
    maintenance_date DATE NOT NULL DEFAULT CURRENT_DATE,
    description TEXT NOT NULL,
    cost DECIMAL(10, 2) CHECK (cost >= 0),
    performed_by VARCHAR(100),
    next_service_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_next_service CHECK (next_service_date IS NULL OR next_service_date > maintenance_date)
);

CREATE INDEX idx_maintenance_vehicle ON maintenance(vehicle_id);
CREATE INDEX idx_maintenance_date ON maintenance(maintenance_date);

-- ============================================================================
-- VIEWS
-- ============================================================================

CREATE VIEW available_vehicles AS
SELECT 
    v.vehicle_id, v.make, v.model, v.year, v.license_plate, v.color, v.mileage,
    vc.category_name, vc.daily_rate, vc.seating_capacity,
    b.branch_name, b.city AS branch_city
FROM vehicle v
JOIN vehicle_category vc ON v.category_id = vc.category_id
JOIN branch b ON v.branch_id = b.branch_id
WHERE v.status = 'available';

CREATE VIEW active_rentals AS
SELECT 
    r.rental_id, r.rental_date, r.start_date, r.end_date,
    c.first_name || ' ' || c.last_name AS customer_name, c.phone AS customer_phone,
    v.make || ' ' || v.model AS vehicle, v.license_plate,
    b.branch_name, r.daily_rate, r.total_amount, r.status
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
JOIN branch b ON r.branch_id = b.branch_id
WHERE r.status = 'active';

CREATE VIEW customer_rental_history AS
SELECT 
    c.customer_id, c.first_name || ' ' || c.last_name AS customer_name, c.email,
    COUNT(r.rental_id) AS total_rentals,
    SUM(r.total_amount) AS total_spent,
    MAX(r.rental_date) AS last_rental_date
FROM customer c
LEFT JOIN rental r ON c.customer_id = r.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email;

CREATE VIEW vehicle_maintenance_summary AS
SELECT 
    v.vehicle_id, v.make || ' ' || v.model AS vehicle, v.license_plate,
    COUNT(m.maintenance_id) AS maintenance_count,
    SUM(m.cost) AS total_maintenance_cost,
    MAX(m.maintenance_date) AS last_maintenance,
    MIN(m.next_service_date) AS next_service_due
FROM vehicle v
LEFT JOIN maintenance m ON v.vehicle_id = m.vehicle_id
GROUP BY v.vehicle_id, v.make, v.model, v.license_plate;

CREATE VIEW branch_revenue AS
SELECT 
    b.branch_id, b.branch_name, b.city,
    COUNT(r.rental_id) AS total_rentals,
    SUM(r.total_amount) AS total_revenue,
    AVG(r.total_amount) AS avg_rental_amount
FROM branch b
LEFT JOIN rental r ON b.branch_id = r.branch_id
WHERE r.status = 'completed'
GROUP BY b.branch_id, b.branch_name, b.city;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE OR REPLACE FUNCTION update_vehicle_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'active' THEN
        UPDATE vehicle SET status = 'rented' WHERE vehicle_id = NEW.vehicle_id;
    ELSIF NEW.status = 'completed' OR NEW.status = 'cancelled' THEN
        UPDATE vehicle SET status = 'available' WHERE vehicle_id = NEW.vehicle_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_vehicle_status
AFTER INSERT OR UPDATE OF status ON rental
FOR EACH ROW EXECUTE FUNCTION update_vehicle_status();

CREATE OR REPLACE FUNCTION calculate_rental_amount()
RETURNS TRIGGER AS $$
DECLARE days_rented INTEGER;
BEGIN
    IF NEW.return_date IS NOT NULL AND NEW.status = 'completed' THEN
        days_rented := NEW.return_date - NEW.start_date;
    ELSE
        days_rented := NEW.end_date - NEW.start_date;
    END IF;
    IF days_rented < 1 THEN days_rented := 1; END IF;
    NEW.total_amount := days_rented * NEW.daily_rate;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_rental_amount
BEFORE INSERT OR UPDATE ON rental
FOR EACH ROW EXECUTE FUNCTION calculate_rental_amount();

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_vehicle_timestamp
BEFORE UPDATE ON vehicle
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trigger_update_rental_timestamp
BEFORE UPDATE ON rental
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE OR REPLACE FUNCTION update_last_maintenance()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE vehicle SET last_maintenance_date = NEW.maintenance_date WHERE vehicle_id = NEW.vehicle_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_last_maintenance
AFTER INSERT ON maintenance
FOR EACH ROW EXECUTE FUNCTION update_last_maintenance();

-- ============================================================================
-- STORED PROCEDURES
-- ============================================================================

CREATE OR REPLACE FUNCTION create_rental(
    p_customer_id INTEGER, p_vehicle_id INTEGER, p_branch_id INTEGER,
    p_employee_id INTEGER, p_start_date DATE, p_end_date DATE, p_start_mileage INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_vehicle_status vehicle_status;
    v_daily_rate DECIMAL(10, 2);
    v_rental_id INTEGER;
BEGIN
    SELECT status INTO v_vehicle_status FROM vehicle WHERE vehicle_id = p_vehicle_id;
    IF v_vehicle_status != 'available' THEN
        RAISE EXCEPTION 'Vehicle is not available for rental';
    END IF;
    SELECT vc.daily_rate INTO v_daily_rate
    FROM vehicle v
    JOIN vehicle_category vc ON v.category_id = vc.category_id
    WHERE v.vehicle_id = p_vehicle_id;
    INSERT INTO rental (customer_id, vehicle_id, branch_id, employee_id, start_date, end_date, start_mileage, daily_rate, status)
    VALUES (p_customer_id, p_vehicle_id, p_branch_id, p_employee_id, p_start_date, p_end_date, p_start_mileage, v_daily_rate, 'pending')
    RETURNING rental_id INTO v_rental_id;
    RETURN v_rental_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION complete_rental(p_rental_id INTEGER, p_return_date DATE, p_end_mileage INTEGER)
RETURNS VOID AS $$
BEGIN
    UPDATE rental SET return_date = p_return_date, end_mileage = p_end_mileage, status = 'completed'
    WHERE rental_id = p_rental_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Rental not found'; END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION process_payment(
    p_rental_id INTEGER, p_amount DECIMAL(10, 2), p_payment_method payment_method, p_transaction_id VARCHAR(100) DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE v_payment_id INTEGER;
BEGIN
    INSERT INTO payment (rental_id, amount, payment_method, transaction_id)
    VALUES (p_rental_id, p_amount, p_payment_method, p_transaction_id)
    RETURNING payment_id INTO v_payment_id;
    RETURN v_payment_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_available_vehicles_by_date(
    p_start_date DATE, p_end_date DATE, p_branch_id INTEGER DEFAULT NULL
) RETURNS TABLE (
    vehicle_id INTEGER, make VARCHAR(50), model VARCHAR(50), year INTEGER,
    category_name VARCHAR(50), daily_rate DECIMAL(10, 2), branch_name VARCHAR(100)
) AS $$
BEGIN
    RETURN QUERY
    SELECT v.vehicle_id, v.make, v.model, v.year, vc.category_name, vc.daily_rate, b.branch_name
    FROM vehicle v
    JOIN vehicle_category vc ON v.category_id = vc.category_id
    JOIN branch b ON v.branch_id = b.branch_id
    WHERE v.status = 'available'
    AND (p_branch_id IS NULL OR v.branch_id = p_branch_id)
    AND NOT EXISTS (
        SELECT 1 FROM rental r WHERE r.vehicle_id = v.vehicle_id AND r.status IN ('pending', 'active')
        AND ((p_start_date BETWEEN r.start_date AND r.end_date) OR
             (p_end_date BETWEEN r.start_date AND r.end_date) OR
             (r.start_date BETWEEN p_start_date AND p_end_date))
    );
END;
$$ LANGUAGE plpgsql;
