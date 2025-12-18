-- ============================================================================
-- CONCURRENCY-SAFE RENTAL BOOKING FUNCTIONS
-- Production-ready functions with proper locking and error handling
-- ============================================================================

\echo '============================================================================'
\echo 'Installing Concurrency-Safe Rental Functions'
\echo '============================================================================'
\echo ''

-- ============================================================================
-- Function: book_vehicle_safe
-- Safely books a vehicle with proper locking to prevent race conditions
-- ============================================================================

CREATE OR REPLACE FUNCTION book_vehicle_safe(
    p_customer_id INTEGER,
    p_vehicle_id INTEGER,
    p_branch_id INTEGER,
    p_start_date DATE,
    p_end_date DATE,
    p_employee_id INTEGER DEFAULT NULL
)
RETURNS TABLE (
    success BOOLEAN,
    rental_id INTEGER,
    message TEXT
) AS $$
DECLARE
    v_vehicle_status vehicle_status;
    v_daily_rate DECIMAL(10, 2);
    v_start_mileage INTEGER;
    v_rental_id INTEGER;
    v_existing_rentals INTEGER;
BEGIN
    -- Lock the vehicle row to prevent race conditions
    SELECT v.status, vc.daily_rate, v.mileage
    INTO v_vehicle_status, v_daily_rate, v_start_mileage
    FROM vehicle v
    JOIN vehicle_category vc ON v.category_id = vc.category_id
    WHERE v.vehicle_id = p_vehicle_id
    FOR UPDATE;  -- This locks the row
    
    -- Check if vehicle exists
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::INTEGER, 'Vehicle not found'::TEXT;
        RETURN;
    END IF;
    
    -- Check if vehicle is available
    IF v_vehicle_status != 'available' THEN
        RETURN QUERY SELECT FALSE, NULL::INTEGER, 
            format('Vehicle is not available (current status: %s)', v_vehicle_status);
        RETURN;
    END IF;
    
    -- Check for date conflicts (even with 'available' status)
    SELECT COUNT(*)
    INTO v_existing_rentals
    FROM rental
    WHERE vehicle_id = p_vehicle_id
      AND status IN ('pending', 'active')
      AND (
          (p_start_date BETWEEN start_date AND end_date) OR
          (p_end_date BETWEEN start_date AND end_date) OR
          (start_date BETWEEN p_start_date AND p_end_date)
      );
    
    IF v_existing_rentals > 0 THEN
        RETURN QUERY SELECT FALSE, NULL::INTEGER, 
            'Vehicle has conflicting rental dates'::TEXT;
        RETURN;
    END IF;
    
    -- Validate dates
    IF p_start_date > p_end_date THEN
        RETURN QUERY SELECT FALSE, NULL::INTEGER, 
            'Start date must be before end date'::TEXT;
        RETURN;
    END IF;
    
    -- All checks passed - create the rental
    INSERT INTO rental (
        customer_id, vehicle_id, branch_id, employee_id,
        start_date, end_date, start_mileage, daily_rate, status
    )
    VALUES (
        p_customer_id, p_vehicle_id, p_branch_id, p_employee_id,
        p_start_date, p_end_date, v_start_mileage, v_daily_rate, 'pending'
    )
    RETURNING rental.rental_id INTO v_rental_id;
    
    -- Success!
    RETURN QUERY SELECT TRUE, v_rental_id, 
        format('Rental %s created successfully', v_rental_id);
    RETURN;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Handle any unexpected errors
        RETURN QUERY SELECT FALSE, NULL::INTEGER, 
            format('Error: %s', SQLERRM);
        RETURN;
END;
$$ LANGUAGE plpgsql;

\echo '✓ Function book_vehicle_safe created'

-- ============================================================================
-- Function: activate_rental_safe
-- Activates a pending rental with proper locking
-- ============================================================================

CREATE OR REPLACE FUNCTION activate_rental_safe(p_rental_id INTEGER)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_rental_status rental_status;
    v_vehicle_id INTEGER;
BEGIN
    -- Lock the rental record
    SELECT status, vehicle_id
    INTO v_rental_status, v_vehicle_id
    FROM rental
    WHERE rental_id = p_rental_id
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Rental not found'::TEXT;
        RETURN;
    END IF;
    
    IF v_rental_status != 'pending' THEN
        RETURN QUERY SELECT FALSE, 
            format('Rental status is %s, can only activate pending rentals', v_rental_status);
        RETURN;
    END IF;
    
    -- Update rental status
    UPDATE rental
    SET status = 'active', updated_at = CURRENT_TIMESTAMP
    WHERE rental_id = p_rental_id;
    
    -- Vehicle status is updated by trigger
    
    RETURN QUERY SELECT TRUE, 'Rental activated successfully'::TEXT;
    RETURN;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT FALSE, format('Error: %s', SQLERRM);
        RETURN;
END;
$$ LANGUAGE plpgsql;

\echo '✓ Function activate_rental_safe created'

-- ============================================================================
-- Function: complete_rental_safe
-- Completes a rental with proper locking
-- ============================================================================

CREATE OR REPLACE FUNCTION complete_rental_safe(
    p_rental_id INTEGER,
    p_return_date DATE,
    p_end_mileage INTEGER
)
RETURNS TABLE (
    success BOOLEAN,
    total_amount DECIMAL(10, 2),
    message TEXT
) AS $$
DECLARE
    v_rental_status rental_status;
    v_start_mileage INTEGER;
    v_vehicle_id INTEGER;
    v_total_amount DECIMAL(10, 2);
BEGIN
    -- Lock the rental record
    SELECT status, start_mileage, vehicle_id, rental.total_amount
    INTO v_rental_status, v_start_mileage, v_vehicle_id, v_total_amount
    FROM rental
    WHERE rental_id = p_rental_id
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::DECIMAL, 'Rental not found'::TEXT;
        RETURN;
    END IF;
    
    IF v_rental_status != 'active' THEN
        RETURN QUERY SELECT FALSE, NULL::DECIMAL,
            format('Cannot complete rental with status: %s', v_rental_status);
        RETURN;
    END IF;
    
    IF p_end_mileage < v_start_mileage THEN
        RETURN QUERY SELECT FALSE, NULL::DECIMAL,
            'End mileage cannot be less than start mileage'::TEXT;
        RETURN;
    END IF;
    
    -- Update rental
    UPDATE rental
    SET return_date = p_return_date,
        end_mileage = p_end_mileage,
        status = 'completed',
        updated_at = CURRENT_TIMESTAMP
    WHERE rental_id = p_rental_id
    RETURNING rental.total_amount INTO v_total_amount;
    
    -- Update vehicle mileage
    UPDATE vehicle
    SET mileage = p_end_mileage
    WHERE vehicle_id = v_vehicle_id;
    
    -- Vehicle status updated by trigger
    
    RETURN QUERY SELECT TRUE, v_total_amount, 
        format('Rental completed. Total amount: $%.2f', v_total_amount);
    RETURN;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT FALSE, NULL::DECIMAL, format('Error: %s', SQLERRM);
        RETURN;
END;
$$ LANGUAGE plpgsql;

\echo '✓ Function complete_rental_safe created'

-- ============================================================================
-- Function: cancel_rental_safe
-- Cancels a rental with proper locking
-- ============================================================================

CREATE OR REPLACE FUNCTION cancel_rental_safe(
    p_rental_id INTEGER,
    p_reason TEXT DEFAULT NULL
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_rental_status rental_status;
BEGIN
    -- Lock the rental record
    SELECT status
    INTO v_rental_status
    FROM rental
    WHERE rental_id = p_rental_id
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Rental not found'::TEXT;
        RETURN;
    END IF;
    
    IF v_rental_status = 'completed' THEN
        RETURN QUERY SELECT FALSE, 'Cannot cancel a completed rental'::TEXT;
        RETURN;
    END IF;
    
    IF v_rental_status = 'cancelled' THEN
        RETURN QUERY SELECT FALSE, 'Rental is already cancelled'::TEXT;
        RETURN;
    END IF;
    
    -- Update rental
    UPDATE rental
    SET status = 'cancelled',
        notes = COALESCE(notes || E'\n' || 'Cancellation: ' || p_reason, 'Cancelled: ' || p_reason),
        updated_at = CURRENT_TIMESTAMP
    WHERE rental_id = p_rental_id;
    
    -- Vehicle status updated by trigger
    
    RETURN QUERY SELECT TRUE, 'Rental cancelled successfully'::TEXT;
    RETURN;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT FALSE, format('Error: %s', SQLERRM);
        RETURN;
END;
$$ LANGUAGE plpgsql;

\echo '✓ Function cancel_rental_safe created'

-- ============================================================================
-- Function: get_available_vehicles_concurrent
-- Gets available vehicles with proper locking for booking flow
-- ============================================================================

CREATE OR REPLACE FUNCTION get_available_vehicles_concurrent(
    p_start_date DATE,
    p_end_date DATE,
    p_branch_id INTEGER DEFAULT NULL,
    p_category_id INTEGER DEFAULT NULL,
    p_lock_for_booking BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    vehicle_id INTEGER,
    make VARCHAR(50),
    model VARCHAR(50),
    year INTEGER,
    category_name VARCHAR(50),
    daily_rate DECIMAL(10, 2),
    branch_name VARCHAR(100),
    status vehicle_status
) AS $$
BEGIN
    IF p_lock_for_booking THEN
        -- Lock vehicles for booking (use with caution in transactions)
        RETURN QUERY
        SELECT 
            v.vehicle_id,
            v.make,
            v.model,
            v.year,
            vc.category_name,
            vc.daily_rate,
            b.branch_name,
            v.status
        FROM vehicle v
        JOIN vehicle_category vc ON v.category_id = vc.category_id
        JOIN branch b ON v.branch_id = b.branch_id
        WHERE v.status = 'available'
          AND (p_branch_id IS NULL OR v.branch_id = p_branch_id)
          AND (p_category_id IS NULL OR v.category_id = p_category_id)
          AND NOT EXISTS (
              SELECT 1 FROM rental r 
              WHERE r.vehicle_id = v.vehicle_id 
                AND r.status IN ('pending', 'active')
                AND (
                    (p_start_date BETWEEN r.start_date AND r.end_date) OR
                    (p_end_date BETWEEN r.start_date AND r.end_date) OR
                    (r.start_date BETWEEN p_start_date AND p_end_date)
                )
          )
        FOR UPDATE OF v;
    ELSE
        -- Normal query without locking
        RETURN QUERY
        SELECT 
            v.vehicle_id,
            v.make,
            v.model,
            v.year,
            vc.category_name,
            vc.daily_rate,
            b.branch_name,
            v.status
        FROM vehicle v
        JOIN vehicle_category vc ON v.category_id = vc.category_id
        JOIN branch b ON v.branch_id = b.branch_id
        WHERE v.status = 'available'
          AND (p_branch_id IS NULL OR v.branch_id = p_branch_id)
          AND (p_category_id IS NULL OR v.category_id = p_category_id)
          AND NOT EXISTS (
              SELECT 1 FROM rental r 
              WHERE r.vehicle_id = v.vehicle_id 
                AND r.status IN ('pending', 'active')
                AND (
                    (p_start_date BETWEEN r.start_date AND r.end_date) OR
                    (p_end_date BETWEEN r.start_date AND r.end_date) OR
                    (r.start_date BETWEEN p_start_date AND p_end_date)
                )
          );
    END IF;
END;
$$ LANGUAGE plpgsql;

\echo '✓ Function get_available_vehicles_concurrent created'

-- ============================================================================
-- USAGE EXAMPLES
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'USAGE EXAMPLES'
\echo '============================================================================'
\echo ''

\echo 'Example 1: Book a vehicle safely'
\echo '-----------------------------------'
\echo 'SELECT * FROM book_vehicle_safe('
\echo '    p_customer_id := 1,'
\echo '    p_vehicle_id := 15,'
\echo '    p_branch_id := 1,'
\echo '    p_start_date := CURRENT_DATE + 1,'
\echo '    p_end_date := CURRENT_DATE + 8'
\echo ');'
\echo ''

\echo 'Example 2: Activate a rental'
\echo '-----------------------------------'
\echo 'SELECT * FROM activate_rental_safe(123);'
\echo ''

\echo 'Example 3: Complete a rental'
\echo '-----------------------------------'
\echo 'SELECT * FROM complete_rental_safe('
\echo '    p_rental_id := 123,'
\echo '    p_return_date := CURRENT_DATE,'
\echo '    p_end_mileage := 15500'
\echo ');'
\echo ''

\echo 'Example 4: Cancel a rental'
\echo '-----------------------------------'
\echo 'SELECT * FROM cancel_rental_safe('
\echo '    p_rental_id := 123,'
\echo '    p_reason := ''Customer requested cancellation'''
\echo ');'
\echo ''

\echo 'Example 5: Get available vehicles (read-only)'
\echo '-----------------------------------'
\echo 'SELECT * FROM get_available_vehicles_concurrent('
\echo '    p_start_date := CURRENT_DATE + 1,'
\echo '    p_end_date := CURRENT_DATE + 8,'
\echo '    p_branch_id := 1'
\echo ');'
\echo ''

\echo 'Example 6: Get and lock available vehicles (in transaction)'
\echo '-----------------------------------'
\echo 'BEGIN;'
\echo 'SELECT * FROM get_available_vehicles_concurrent('
\echo '    p_start_date := CURRENT_DATE + 1,'
\echo '    p_end_date := CURRENT_DATE + 8,'
\echo '    p_branch_id := 1,'
\echo '    p_lock_for_booking := TRUE'
\echo ');'
\echo '-- Process booking...'
\echo 'COMMIT;'
\echo ''

-- ============================================================================
-- TEST THE FUNCTIONS
-- ============================================================================

\echo '============================================================================'
\echo 'TESTING CONCURRENCY-SAFE FUNCTIONS'
\echo '============================================================================'
\echo ''

\echo 'Test 1: Book an available vehicle'
SELECT * FROM book_vehicle_safe(
    p_customer_id := 1,
    p_vehicle_id := 15,
    p_branch_id := 1,
    p_start_date := CURRENT_DATE + 1,
    p_end_date := CURRENT_DATE + 8
);
\echo ''

\echo 'Test 2: Try to book the same vehicle again (should fail)'
SELECT * FROM book_vehicle_safe(
    p_customer_id := 2,
    p_vehicle_id := 15,
    p_branch_id := 1,
    p_start_date := CURRENT_DATE + 1,
    p_end_date := CURRENT_DATE + 8
);
\echo ''

\echo 'Test 3: Get available vehicles'
SELECT * FROM get_available_vehicles_concurrent(
    p_start_date := CURRENT_DATE + 1,
    p_end_date := CURRENT_DATE + 8,
    p_branch_id := 1
)
LIMIT 5;
\echo ''

\echo '============================================================================'
\echo 'CONCURRENCY-SAFE FUNCTIONS INSTALLED SUCCESSFULLY'
\echo '============================================================================'
\echo ''
\echo 'These functions provide:'
\echo '  ✓ Proper locking with SELECT FOR UPDATE'
\echo '  ✓ Race condition prevention'
\echo '  ✓ Data validation'
\echo '  ✓ Error handling'
\echo '  ✓ Transaction safety'
\echo ''
\echo 'Use these functions in your application for safe concurrent operations!'
\echo ''





