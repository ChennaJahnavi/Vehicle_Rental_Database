-- ============================================================================
-- CONCURRENCY TEST - TERMINAL 1 (Run this in first terminal window)
-- ============================================================================
-- Instructions:
--   1. Open this file in Terminal 1: psql -U ceejayy -d vrdbms -f concurrency_terminal1.sql
--   2. Run concurrency_terminal2.sql in a SECOND terminal simultaneously
--   3. Observe locking, waiting, and conflict resolution
-- ============================================================================

\echo '============================================================================'
\echo '  TERMINAL 1 - Concurrency Testing'
\echo '============================================================================'
\echo ''
\echo 'Ready to start concurrency tests.'
\echo 'Make sure Terminal 2 is ready with concurrency_terminal2.sql'
\echo ''
\echo 'Press Enter to continue...'
\prompt 'Press Enter: ' dummy
\echo ''

-- ============================================================================
-- SCENARIO 1: Race Condition - Both Try to Rent Same Vehicle
-- ============================================================================

\echo '============================================================================'
\echo 'SCENARIO 1: Race Condition (WITHOUT Locking)'
\echo '============================================================================'
\echo ''
\echo 'Terminal 1: Customer Alice tries to rent vehicle 5'
\echo 'Start Terminal 2 NOW, then press Enter here...'
\prompt 'Press Enter when Terminal 2 is ready: ' dummy

BEGIN;
\echo '✓ Transaction started'

SELECT vehicle_id, make, model, status 
FROM vehicle 
WHERE vehicle_id = 5;
\echo '✓ Vehicle checked - appears available'

\echo ''
\echo 'Simulating processing time (thinking, payment processing, etc.)...'
SELECT pg_sleep(8);

\echo ''
\echo 'Now creating rental for Alice (customer_id = 1)...'
INSERT INTO rental (customer_id, vehicle_id, branch_id, start_date, end_date, start_mileage, daily_rate, status)
VALUES (1, 5, 1, CURRENT_DATE, CURRENT_DATE + 7, 
        (SELECT mileage FROM vehicle WHERE vehicle_id = 5), 
        50.00, 'pending');

COMMIT;
\echo '✓ Alice''s rental committed!'
\echo ''

\echo 'Check: How many rentals for vehicle 5?'
SELECT rental_id, customer_id, vehicle_id, status 
FROM rental 
WHERE vehicle_id = 5 
  AND start_date = CURRENT_DATE
ORDER BY rental_id DESC;

\echo ''
\echo '⚠️  PROBLEM: If Terminal 2 also succeeded, we have a DOUBLE BOOKING!'
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
\echo 'Terminal 1: Alice tries to rent vehicle 10 (WITH locking)'
\echo 'Start Terminal 2 NOW, then press Enter here...'
\prompt 'Press Enter when Terminal 2 is ready: ' dummy

BEGIN;
\echo '✓ Transaction started'

\echo 'Locking vehicle 10...'
SELECT vehicle_id, make, model, status 
FROM vehicle 
WHERE vehicle_id = 10
FOR UPDATE;
\echo '✓ Vehicle 10 LOCKED for Terminal 1 (Terminal 2 will have to wait)'

\echo ''
\echo 'Simulating processing time...'
SELECT pg_sleep(8);

\echo ''
\echo 'Updating vehicle status and creating rental...'
UPDATE vehicle SET status = 'rented' WHERE vehicle_id = 10;
INSERT INTO rental (customer_id, vehicle_id, branch_id, start_date, end_date, start_mileage, daily_rate, status)
VALUES (1, 10, 1, CURRENT_DATE, CURRENT_DATE + 7, 
        (SELECT mileage FROM vehicle WHERE vehicle_id = 10), 
        50.00, 'active');

COMMIT;
\echo '✓ Alice''s rental committed and vehicle marked as rented!'
\echo ''
\echo 'Terminal 2 will now see vehicle is unavailable.'
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
\echo 'Terminal 1 will lock vehicle 1, then try to lock vehicle 2'
\echo 'Terminal 2 will lock vehicle 2, then try to lock vehicle 1'
\echo 'Start Terminal 2 NOW, then press Enter here...'
\prompt 'Press Enter when Terminal 2 is ready: ' dummy

BEGIN;
\echo '✓ Transaction started'

\echo 'Locking vehicle 1...'
UPDATE vehicle SET mileage = mileage + 1 WHERE vehicle_id = 1;
\echo '✓ Vehicle 1 locked'

\echo ''
\echo 'Waiting 5 seconds (Terminal 2 should lock vehicle 2 now)...'
SELECT pg_sleep(5);

\echo ''
\echo 'Now trying to lock vehicle 2...'
\echo '(This will create a deadlock with Terminal 2)'
UPDATE vehicle SET mileage = mileage + 1 WHERE vehicle_id = 2;
\echo '✓ Vehicle 2 updated (or deadlock detected)'

COMMIT;
\echo '✓ Committed (if not aborted by deadlock detector)'
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
\echo 'Terminal 1: Worker picking up available vehicles to process'
\echo 'Start Terminal 2 NOW, then press Enter here...'
\prompt 'Press Enter when Terminal 2 is ready: ' dummy

BEGIN;
\echo '✓ Transaction started'

\echo 'Getting next available vehicle (non-blocking)...'
SELECT vehicle_id, make, model, status
FROM vehicle
WHERE status = 'available'
ORDER BY vehicle_id
FOR UPDATE SKIP LOCKED
LIMIT 1;
\echo '✓ Got a vehicle (Terminal 2 will get a different one)'

\echo ''
\echo 'Processing this vehicle...'
SELECT pg_sleep(5);

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
\echo '✓ Worker 1 completed!'
\echo ''

\prompt 'Press Enter to continue...' dummy

-- ============================================================================
-- SCENARIO 5: Lost Update Problem
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'SCENARIO 5: Lost Update Problem (Demonstration)'
\echo '============================================================================'
\echo ''
\echo 'Both terminals will update vehicle mileage'
\echo 'Start Terminal 2 NOW, then press Enter here...'
\prompt 'Press Enter when Terminal 2 is ready: ' dummy

BEGIN;
\echo '✓ Transaction started'

\echo 'Reading current mileage of vehicle 3...'
SELECT vehicle_id, mileage FROM vehicle WHERE vehicle_id = 3 \gset v_

\echo 'Current mileage: ' :v_mileage

\echo ''
\echo 'Waiting (Terminal 2 is also reading)...'
SELECT pg_sleep(5);

\echo ''
\echo 'Adding 100 miles to mileage...'
-- WRONG WAY (can cause lost updates):
-- UPDATE vehicle SET mileage = :v_mileage + 100 WHERE vehicle_id = 3;

-- RIGHT WAY (atomic update):
UPDATE vehicle SET mileage = mileage + 100 WHERE vehicle_id = 3;

COMMIT;
\echo '✓ Committed'

\echo ''
\echo 'Final mileage of vehicle 3:'
SELECT vehicle_id, mileage FROM vehicle WHERE vehicle_id = 3;
\echo ''

\prompt 'Press Enter to view monitoring info...' dummy

-- ============================================================================
-- MONITORING AND CLEANUP
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'MONITORING: Current Database State'
\echo '============================================================================'
\echo ''

\echo 'Active transactions:'
SELECT 
    pid,
    usename,
    state,
    wait_event_type,
    wait_event,
    query_start,
    LEFT(query, 50) AS query
FROM pg_stat_activity
WHERE state != 'idle'
  AND datname = 'vrdbms'
ORDER BY query_start;

\echo ''
\echo 'Current locks:'
SELECT 
    locktype,
    relation::regclass AS table_name,
    mode,
    granted,
    pid
FROM pg_locks
WHERE relation IS NOT NULL
  AND relation::regclass::text NOT LIKE 'pg_%'
ORDER BY pid;

\echo ''
\echo 'Deadlock statistics:'
SELECT deadlocks FROM pg_stat_database WHERE datname = 'vrdbms';

\echo ''
\echo '============================================================================'
\echo 'TERMINAL 1 - TESTS COMPLETE'
\echo '============================================================================'
\echo ''
\echo 'Key Takeaways:'
\echo '  1. Race conditions happen without proper locking'
\echo '  2. SELECT FOR UPDATE prevents concurrent access'
\echo '  3. Deadlocks are detected and one transaction is aborted'
\echo '  4. SKIP LOCKED enables non-blocking parallel processing'
\echo '  5. Use atomic operations to prevent lost updates'
\echo ''
\echo 'Clean up rentals created during testing:'
\echo '  DELETE FROM rental WHERE created_at >= CURRENT_DATE;'
\echo ''





