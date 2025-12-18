-- ============================================================================
-- CONCURRENCY TEST - TERMINAL 2 (Run this in second terminal window)
-- ============================================================================
-- Instructions:
--   1. Start Terminal 1 first with concurrency_terminal1.sql
--   2. When Terminal 1 prompts you, run this file: psql -U ceejayy -d vrdbms -f concurrency_terminal2.sql
--   3. Follow the prompts to observe concurrency behavior
-- ============================================================================

\echo '============================================================================'
\echo '  TERMINAL 2 - Concurrency Testing'
\echo '============================================================================'
\echo ''
\echo 'This terminal will interact with Terminal 1 to demonstrate concurrency.'
\echo ''
\echo 'Press Enter to start...'
\prompt 'Press Enter: ' dummy
\echo ''

-- ============================================================================
-- SCENARIO 1: Race Condition - Both Try to Rent Same Vehicle
-- ============================================================================

\echo '============================================================================'
\echo 'SCENARIO 1: Race Condition (WITHOUT Locking)'
\echo '============================================================================'
\echo ''
\echo 'Terminal 2: Customer Bob tries to rent vehicle 5'
\echo 'Wait for Terminal 1 to start, then press Enter here...'
\prompt 'Press Enter to start (after Terminal 1 begins): ' dummy

-- Small delay so Terminal 1 starts first
SELECT pg_sleep(1);

BEGIN;
\echo '✓ Transaction started'

SELECT vehicle_id, make, model, status 
FROM vehicle 
WHERE vehicle_id = 5;
\echo '✓ Vehicle checked - appears available'

\echo ''
\echo 'Simulating processing time...'
SELECT pg_sleep(6);

\echo ''
\echo 'Now creating rental for Bob (customer_id = 2)...'
INSERT INTO rental (customer_id, vehicle_id, branch_id, start_date, end_date, start_mileage, daily_rate, status)
VALUES (2, 5, 1, CURRENT_DATE, CURRENT_DATE + 7, 
        (SELECT mileage FROM vehicle WHERE vehicle_id = 5), 
        50.00, 'pending');

COMMIT;
\echo '✓ Bob''s rental committed!'
\echo ''

\echo 'Check: Both customers booked the same vehicle:'
SELECT rental_id, customer_id, vehicle_id, status 
FROM rental 
WHERE vehicle_id = 5 
  AND start_date = CURRENT_DATE
ORDER BY rental_id DESC;

\echo ''
\echo '⚠️  DOUBLE BOOKING OCCURRED! This is the race condition problem.'
\echo '    In production, this would be a serious bug.'
\echo ''
\prompt 'Press Enter to continue to SOLUTION...' dummy

-- ============================================================================
-- SCENARIO 2: Proper Locking with SELECT FOR UPDATE
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'SCENARIO 2: SOLUTION - Using SELECT FOR UPDATE'
\echo '============================================================================'
\echo ''
\echo 'Terminal 2: Bob tries to rent vehicle 10 (WITH locking)'
\echo 'Wait for Terminal 1 to start Scenario 2, then press Enter...'
\prompt 'Press Enter to start: ' dummy

-- Small delay so Terminal 1 starts first
SELECT pg_sleep(2);

BEGIN;
\echo '✓ Transaction started'

\echo 'Trying to lock vehicle 10...'
\echo '⏳ WAITING - Terminal 1 has the lock, we must wait...'
SELECT vehicle_id, make, model, status 
FROM vehicle 
WHERE vehicle_id = 10
FOR UPDATE;
\echo '✓ Lock acquired! (Terminal 1 released it)'

\echo ''
\echo 'Checking if vehicle is still available...'
SELECT vehicle_id, status FROM vehicle WHERE vehicle_id = 10;

\echo ''
\echo 'Vehicle status shows "rented" - Alice got it first!'
\echo 'Bob cannot rent this vehicle.'

ROLLBACK;
\echo '✓ Transaction rolled back - no double booking!'
\echo ''
\echo '✅ SUCCESS: SELECT FOR UPDATE prevented the race condition'
\echo ''

\prompt 'Press Enter to continue...' dummy

-- ============================================================================
-- SCENARIO 3: Deadlock Demonstration
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'SCENARIO 3: Deadlock Detection'
\echo '============================================================================'
\echo ''
\echo 'Terminal 2 will lock vehicle 2, then try to lock vehicle 1'
\echo 'This creates a deadlock with Terminal 1'
\echo 'Wait for Terminal 1, then press Enter...'
\prompt 'Press Enter to start: ' dummy

-- Small delay so Terminal 1 locks vehicle 1 first
SELECT pg_sleep(1);

BEGIN;
\echo '✓ Transaction started'

\echo 'Locking vehicle 2...'
UPDATE vehicle SET mileage = mileage + 1 WHERE vehicle_id = 2;
\echo '✓ Vehicle 2 locked'

\echo ''
\echo 'Waiting 5 seconds...'
SELECT pg_sleep(5);

\echo ''
\echo 'Now trying to lock vehicle 1 (Terminal 1 has it)...'
\echo '⏳ This will create a DEADLOCK...'

-- This will likely be aborted by PostgreSQL's deadlock detector
UPDATE vehicle SET mileage = mileage + 1 WHERE vehicle_id = 1;
\echo '✓ Vehicle 1 updated'

COMMIT;
\echo '✓ Committed'
\echo ''
\echo 'If you see an error above, PostgreSQL detected the deadlock and aborted'
\echo 'one of the transactions. This is normal and expected behavior.'
\echo ''

\prompt 'Press Enter to continue...' dummy

-- ============================================================================
-- SCENARIO 4: SKIP LOCKED - Job Queue Pattern
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'SCENARIO 4: SKIP LOCKED - Parallel Workers'
\echo '============================================================================'
\echo ''
\echo 'Terminal 2: Worker picking up available vehicles (different from Terminal 1)'
\echo 'Wait for Terminal 1, then press Enter...'
\prompt 'Press Enter to start: ' dummy

-- Start slightly after Terminal 1
SELECT pg_sleep(1);

BEGIN;
\echo '✓ Transaction started'

\echo 'Getting next available vehicle (non-blocking)...'
SELECT vehicle_id, make, model, status
FROM vehicle
WHERE status = 'available'
ORDER BY vehicle_id
FOR UPDATE SKIP LOCKED
LIMIT 1;
\echo '✓ Got a DIFFERENT vehicle than Terminal 1 (no waiting!)'

\echo ''
\echo 'Processing this vehicle...'
SELECT pg_sleep(3);

\echo ''
\echo 'Marking as rented...'
UPDATE vehicle 
SET status = 'rented' 
WHERE vehicle_id = (
    SELECT vehicle_id FROM vehicle 
    WHERE status = 'available' 
    ORDER BY vehicle_id 
    FOR UPDATE SKIP LOCKED 
    LIMIT 1
);

COMMIT;
\echo '✓ Worker 2 completed!'
\echo ''
\echo '✅ Both workers processed different vehicles in parallel without blocking'
\echo ''

\prompt 'Press Enter to continue...' dummy

-- ============================================================================
-- SCENARIO 5: Lost Update Problem
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'SCENARIO 5: Lost Update Problem'
\echo '============================================================================'
\echo ''
\echo 'Terminal 2 will also update vehicle 3 mileage'
\echo 'Wait for Terminal 1, then press Enter...'
\prompt 'Press Enter to start: ' dummy

-- Start slightly after Terminal 1
SELECT pg_sleep(1);

BEGIN;
\echo '✓ Transaction started'

\echo 'Reading current mileage of vehicle 3...'
SELECT vehicle_id, mileage FROM vehicle WHERE vehicle_id = 3 \gset v_

\echo 'Current mileage: ' :v_mileage

\echo ''
\echo 'Waiting...'
SELECT pg_sleep(3);

\echo ''
\echo 'Adding 50 miles to mileage...'
-- RIGHT WAY (atomic update - no lost updates):
UPDATE vehicle SET mileage = mileage + 50 WHERE vehicle_id = 3;

COMMIT;
\echo '✓ Committed'

\echo ''
\echo 'Final mileage of vehicle 3:'
SELECT vehicle_id, mileage FROM vehicle WHERE vehicle_id = 3;
\echo ''
\echo '✅ Both updates applied correctly (Terminal 1: +100, Terminal 2: +50)'
\echo '   Using atomic operations prevents lost updates'
\echo ''

\prompt 'Press Enter to view final results...' dummy

-- ============================================================================
-- FINAL RESULTS
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'FINAL RESULTS - Comparison'
\echo '============================================================================'
\echo ''

\echo 'Scenario 1 - Race Condition (NO locking):'
SELECT 
    'Vehicle 5' AS vehicle,
    COUNT(*) AS rental_count,
    STRING_AGG(customer_id::text, ', ') AS customers
FROM rental 
WHERE vehicle_id = 5 
  AND start_date = CURRENT_DATE;
\echo '  ⚠️  Multiple rentals = PROBLEM'

\echo ''
\echo 'Scenario 2 - SELECT FOR UPDATE (WITH locking):'
SELECT 
    'Vehicle 10' AS vehicle,
    COUNT(*) AS rental_count,
    customer_id
FROM rental 
WHERE vehicle_id = 10 
  AND start_date = CURRENT_DATE
GROUP BY customer_id;
\echo '  ✅ Only one rental = CORRECT'

\echo ''
\echo 'Active transactions (should be minimal now):'
SELECT COUNT(*) FROM pg_stat_activity WHERE state != 'idle' AND datname = 'vrdbms';

\echo ''
\echo '============================================================================'
\echo 'TERMINAL 2 - TESTS COMPLETE'
\echo '============================================================================'
\echo ''
\echo 'Summary of Concurrency Patterns Demonstrated:'
\echo ''
\echo '1. RACE CONDITION:'
\echo '   Problem: Two transactions see the same state and both proceed'
\echo '   Result: Double booking, data corruption'
\echo ''
\echo '2. SELECT FOR UPDATE:'
\echo '   Solution: Lock rows before reading them'
\echo '   Result: Second transaction waits, sees updated state'
\echo ''
\echo '3. DEADLOCK:'
\echo '   Problem: Circular wait for locks'
\echo '   Result: PostgreSQL detects and aborts one transaction'
\echo ''
\echo '4. SKIP LOCKED:'
\echo '   Use Case: Job queues, parallel workers'
\echo '   Result: Workers process different items without blocking'
\echo ''
\echo '5. LOST UPDATES:'
\echo '   Problem: Read-modify-write cycles can lose changes'
\echo '   Solution: Use atomic operations (UPDATE ... SET x = x + 1)'
\echo ''
\echo 'Clean up test data:'
\echo '  DELETE FROM rental WHERE created_at >= CURRENT_DATE;'
\echo '  UPDATE vehicle SET status = ''available'' WHERE vehicle_id IN (5, 10);'
\echo ''





