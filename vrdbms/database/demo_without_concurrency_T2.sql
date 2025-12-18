-- ============================================================================
-- DEMONSTRATION: WITHOUT CONCURRENCY CONTROL - TERMINAL 2
-- Shows problems that occur without proper locking
-- ============================================================================
-- Run this in TERMINAL 2 while running demo_without_concurrency_T1.sql in TERMINAL 1
-- ============================================================================

\echo '============================================================================'
\echo '  TERMINAL 2: Demonstration WITHOUT Concurrency Control'
\echo '  Customer: Bob'
\echo '============================================================================'
\echo ''
\echo 'This terminal represents Bob (customer 2)'
\echo ''
\echo 'Wait for Terminal 1 (Alice) to start, then follow prompts'
\echo ''
\prompt 'Press Enter to begin: ' dummy
\echo ''

-- ============================================================================
-- PROBLEM 1: Race Condition (Double Booking)
-- ============================================================================

\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'PROBLEM 1: Race Condition - Double Booking'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo 'Terminal 2 (Bob): Starting rental process...'
\echo 'Wait for Terminal 1 to start, then press Enter'
\prompt 'Press Enter (after Terminal 1 starts): ' dummy

-- Small delay so Terminal 1 goes first
SELECT pg_sleep(2);

BEGIN;
\echo '✓ Transaction started'

\echo ''
\echo 'Bob checks if vehicle 5 is available...'
SELECT vehicle_id, make, model, status 
FROM vehicle 
WHERE vehicle_id = 5;

\echo ''
\echo '✓ Vehicle appears available to Bob too!'
\echo '   (Alice is still processing in Terminal 1)'
\echo ''
\echo 'Bob is also processing (payment, paperwork, etc.)...'
\echo 'Simulating 7 seconds of processing...'
SELECT pg_sleep(7);

\echo ''
\echo 'Bob completes booking...'
INSERT INTO rental (customer_id, vehicle_id, branch_id, start_date, end_date, start_mileage, daily_rate, status)
VALUES (2, 5, 1, CURRENT_DATE, CURRENT_DATE + 7, 
        (SELECT mileage FROM vehicle WHERE vehicle_id = 5), 
        50.00, 'pending')
RETURNING rental_id, customer_id, vehicle_id;

COMMIT;
\echo '✓ Bob''s rental committed!'
\echo ''

\echo 'Bob successfully rented vehicle 5!'
\echo ''
\echo '⚠️  BUT WAIT - Alice ALSO rented the same vehicle!'
\echo '    This is the RACE CONDITION problem.'
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
\echo 'Terminal 2 (Bob): Updating vehicle 3 mileage...'
\echo 'Wait for Terminal 1 to start Problem 2'
\prompt 'Press Enter to start: ' dummy

-- Small delay so Terminal 1 reads first
SELECT pg_sleep(2);

BEGIN;
\echo '✓ Transaction started'

\echo ''
\echo 'Reading current mileage of vehicle 3...'
SELECT vehicle_id, mileage FROM vehicle WHERE vehicle_id = 3;

-- Store value
\gset v_

\echo 'Current mileage: ' :v_mileage
\echo '   (Same value Alice read!)'
\echo ''
\echo 'Bob will add 50 miles...'
\echo 'Waiting 5 seconds...'
SELECT pg_sleep(5);

\echo ''
\echo 'Bob updates mileage: ' :v_mileage ' + 50 = ' :v_mileage + 50
-- WRONG WAY - This will overwrite Alice's update:
UPDATE vehicle SET mileage = :v_mileage + 50 WHERE vehicle_id = 3;

COMMIT;
\echo '✓ Bob''s update committed'
\echo ''

\echo '⚠️  PROBLEM: Bob just overwrote Alice''s update!'
\echo '    Alice''s +100 miles was LOST'
\echo '    Only Bob''s +50 miles is in the database'
\echo ''
\prompt 'Press Enter to continue to Problem 3...' dummy

-- ============================================================================
-- PROBLEM 3: Non-Repeatable Reads
-- ============================================================================

\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'PROBLEM 3: Non-Repeatable Reads'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo 'Terminal 2 (Bob): Changing vehicle status...'
\echo 'Wait for Terminal 1 to start Problem 3'
\prompt 'Press Enter to start: ' dummy

-- Wait for Terminal 1 to read first
SELECT pg_sleep(3);

\echo ''
\echo 'Bob changes vehicle status from available to maintenance...'
UPDATE vehicle SET status = 'maintenance' WHERE vehicle_id = 7 AND status = 'available';

\echo '✓ Status changed'
\echo ''
\echo '   This change will be visible to Alice''s second read'
\echo '   even though she''s in the same transaction!'
\echo ''

-- ============================================================================
-- SUMMARY
-- ============================================================================

\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'TERMINAL 2: Summary'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo 'Bob''s Perspective:'
\echo ''
\echo '1. ✓ Bob successfully rented vehicle 5'
\echo '   ⚠️  But so did Alice - DOUBLE BOOKING!'
\echo ''
\echo '2. ✓ Bob updated vehicle mileage'
\echo '   ⚠️  But overwrote Alice''s update - LOST UPDATE!'
\echo ''
\echo '3. ✓ Bob changed vehicle status'
\echo '   ⚠️  Alice saw inconsistent data - NON-REPEATABLE READ!'
\echo ''
\echo 'All of these are SERIOUS bugs that occur WITHOUT proper concurrency control!'
\echo ''
\echo 'Next: Run the WITH concurrency demo to see how these are prevented.'
\echo ''





