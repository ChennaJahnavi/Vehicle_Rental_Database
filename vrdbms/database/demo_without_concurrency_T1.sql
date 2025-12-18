-- ============================================================================
-- DEMONSTRATION: WITHOUT CONCURRENCY CONTROL - TERMINAL 1
-- Shows problems that occur without proper locking
-- ============================================================================
-- Run this in TERMINAL 1 while running demo_without_concurrency_T2.sql in TERMINAL 2
-- ============================================================================

\echo '============================================================================'
\echo '  TERMINAL 1: Demonstration WITHOUT Concurrency Control'
\echo '  Customer: Alice'
\echo '============================================================================'
\echo ''
\echo 'This demo shows what happens WITHOUT proper locking:'
\echo '  - Race conditions (double booking)'
\echo '  - Lost updates'
\echo '  - Data inconsistency'
\echo ''
\echo 'Make sure Terminal 2 is ready with demo_without_concurrency_T2.sql'
\echo ''
\prompt 'Press Enter when Terminal 2 is ready: ' dummy
\echo ''

-- ============================================================================
-- PROBLEM 1: Race Condition (Double Booking)
-- ============================================================================

\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'PROBLEM 1: Race Condition - Double Booking'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo 'Scenario: Alice and Bob both try to rent vehicle 5'
\echo 'WITHOUT proper locking, both will succeed!'
\echo ''
\echo 'Terminal 1 (Alice): Starting rental process...'
\prompt 'Press Enter to start: ' dummy

BEGIN;
\echo '✓ Transaction started'

\echo ''
\echo 'Alice checks if vehicle 5 is available...'
SELECT vehicle_id, make, model, status 
FROM vehicle 
WHERE vehicle_id = 5;

\echo ''
\echo '✓ Vehicle appears available to Alice'
\echo ''
\echo 'Alice is now processing (payment, paperwork, etc.)...'
\echo 'Meanwhile, Bob in Terminal 2 is ALSO checking the same vehicle!'
\echo ''
\echo 'Simulating 10 seconds of processing...'
SELECT pg_sleep(10);

\echo ''
\echo 'Alice completes booking...'
INSERT INTO rental (customer_id, vehicle_id, branch_id, start_date, end_date, start_mileage, daily_rate, status)
VALUES (1, 5, 1, CURRENT_DATE, CURRENT_DATE + 7, 
        (SELECT mileage FROM vehicle WHERE vehicle_id = 5), 
        50.00, 'pending')
RETURNING rental_id, customer_id, vehicle_id;

COMMIT;
\echo '✓ Alice''s rental committed!'
\echo ''

\echo 'Checking rentals for vehicle 5...'
SELECT 
    rental_id,
    customer_id,
    CASE customer_id WHEN 1 THEN 'Alice' WHEN 2 THEN 'Bob' ELSE 'Other' END AS customer,
    vehicle_id,
    status,
    created_at
FROM rental 
WHERE vehicle_id = 5 
  AND created_at >= CURRENT_TIMESTAMP - INTERVAL '1 minute'
ORDER BY rental_id DESC;

\echo ''
\echo '⚠️  PROBLEM: If you see TWO rentals above, we have DOUBLE BOOKING!'
\echo '    Both Alice and Bob rented the same vehicle for the same dates.'
\echo '    This is a SERIOUS BUG that happens without proper locking!'
\echo ''
\prompt 'Press Enter to continue to Problem 2...' dummy

-- ============================================================================
-- PROBLEM 2: Lost Update
-- ============================================================================

\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'PROBLEM 2: Lost Update'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo 'Scenario: Alice and Bob both update vehicle mileage'
\echo 'WITHOUT atomic operations, one update will be lost!'
\echo ''
\echo 'Terminal 1 (Alice): Updating vehicle 3 mileage...'
\prompt 'Press Enter to start: ' dummy

BEGIN;
\echo '✓ Transaction started'

\echo ''
\echo 'Reading current mileage of vehicle 3...'
SELECT vehicle_id, mileage FROM vehicle WHERE vehicle_id = 3;

-- Store value
\gset v_

\echo 'Current mileage: ' :v_mileage
\echo ''
\echo 'Alice will add 100 miles...'
\echo 'Waiting 8 seconds (Bob is also reading the value now)...'
SELECT pg_sleep(8);

\echo ''
\echo 'Alice updates mileage: ' :v_mileage ' + 100 = ' :v_mileage + 100
-- WRONG WAY - This causes lost updates:
UPDATE vehicle SET mileage = :v_mileage + 100 WHERE vehicle_id = 3;

COMMIT;
\echo '✓ Alice''s update committed'
\echo ''

\echo 'Waiting for Bob to finish...'
SELECT pg_sleep(5);

\echo ''
\echo 'Final mileage of vehicle 3:'
SELECT vehicle_id, mileage FROM vehicle WHERE vehicle_id = 3;

\echo ''
\echo '⚠️  PROBLEM: Check the final mileage!'
\echo '    Alice added 100 miles, Bob added 50 miles'
\echo '    Expected: original + 150'
\echo '    Actual: original + 50 (Alice''s update was LOST!)'
\echo ''
\prompt 'Press Enter to continue to Problem 3...' dummy

-- ============================================================================
-- PROBLEM 3: Read Uncommitted Data (Would happen in READ UNCOMMITTED)
-- ============================================================================

\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'PROBLEM 3: Non-Repeatable Reads'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo 'Scenario: Alice reads data, Bob changes it, Alice reads again'
\echo 'In READ COMMITTED (default), Alice sees different values!'
\echo ''
\echo 'Terminal 1 (Alice): Checking available vehicles...'
\prompt 'Press Enter to start: ' dummy

BEGIN;
\echo '✓ Transaction started (READ COMMITTED isolation)'

\echo ''
\echo 'First count of available vehicles:'
SELECT COUNT(*) as available_count FROM vehicle WHERE status = 'available';

\echo ''
\echo 'Waiting 8 seconds (Bob is changing vehicle status now)...'
SELECT pg_sleep(8);

\echo ''
\echo 'Second count of available vehicles (in SAME transaction):'
SELECT COUNT(*) as available_count FROM vehicle WHERE status = 'available';

COMMIT;
\echo '✓ Transaction ended'
\echo ''

\echo '⚠️  PROBLEM: The counts are DIFFERENT within the same transaction!'
\echo '    This is "non-repeatable read" - data changed mid-transaction'
\echo '    Can cause inconsistent reports or calculations'
\echo ''

-- ============================================================================
-- CLEANUP
-- ============================================================================

\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'TERMINAL 1: Summary of Problems WITHOUT Concurrency Control'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo 'Problems Demonstrated:'
\echo ''
\echo '1. ❌ RACE CONDITION: Two customers booked the same vehicle'
\echo '      → Leads to double booking, angry customers, lost revenue'
\echo ''
\echo '2. ❌ LOST UPDATE: One user''s mileage update was overwritten'
\echo '      → Leads to data corruption, incorrect records'
\echo ''
\echo '3. ❌ NON-REPEATABLE READ: Count changed mid-transaction'
\echo '      → Leads to inconsistent reports, calculation errors'
\echo ''
\echo 'These are SERIOUS problems that WILL occur in production without'
\echo 'proper concurrency control!'
\echo ''
\echo 'Now run the WITH concurrency demo to see how these are prevented.'
\echo ''
\echo 'Cleanup commands:'
\echo '  DELETE FROM rental WHERE vehicle_id = 5 AND created_at >= CURRENT_DATE;'
\echo ''





