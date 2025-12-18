-- ============================================================================
-- DEMONSTRATION: WITH CONCURRENCY CONTROL - TERMINAL 1
-- Shows how proper locking prevents problems
-- ============================================================================
-- Run this in TERMINAL 1 while running demo_with_concurrency_T2.sql in TERMINAL 2
-- ============================================================================

\echo '============================================================================'
\echo '  TERMINAL 1: Demonstration WITH Concurrency Control'
\echo '  Customer: Alice'
\echo '============================================================================'
\echo ''
\echo 'This demo shows how proper concurrency control prevents problems:'
\echo '  ✓ SELECT FOR UPDATE prevents race conditions'
\echo '  ✓ Atomic operations prevent lost updates'
\echo '  ✓ Proper isolation prevents inconsistent reads'
\echo ''
\echo 'Make sure Terminal 2 is ready with demo_with_concurrency_T2.sql'
\echo ''
\prompt 'Press Enter when Terminal 2 is ready: ' dummy
\echo ''

-- ============================================================================
-- SOLUTION 1: SELECT FOR UPDATE (Prevents Race Conditions)
-- ============================================================================

\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'SOLUTION 1: SELECT FOR UPDATE - Prevents Double Booking'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo 'Scenario: Alice and Bob both try to rent vehicle 10'
\echo 'WITH proper locking, only one will succeed!'
\echo ''
\echo 'Terminal 1 (Alice): Starting rental process WITH LOCKING...'
\prompt 'Press Enter to start: ' dummy

BEGIN;
\echo '✓ Transaction started'

\echo ''
\echo 'Alice checks AND LOCKS vehicle 10...'
SELECT vehicle_id, make, model, status 
FROM vehicle 
WHERE vehicle_id = 10
FOR UPDATE;  -- ← THIS IS THE KEY! Locks the row

\echo ''
\echo '✓ Vehicle 10 is now LOCKED for Alice'
\echo '✓ Bob in Terminal 2 will have to WAIT'
\echo ''
\echo 'Alice is processing (payment, paperwork, etc.)...'
\echo 'Simulating 10 seconds of processing...'
SELECT pg_sleep(10);

\echo ''
\echo 'Alice updates status and completes booking...'
UPDATE vehicle SET status = 'rented' WHERE vehicle_id = 10;

INSERT INTO rental (customer_id, vehicle_id, branch_id, start_date, end_date, start_mileage, daily_rate, status)
VALUES (1, 10, 1, CURRENT_DATE, CURRENT_DATE + 7, 
        (SELECT mileage FROM vehicle WHERE vehicle_id = 10), 
        50.00, 'active')
RETURNING rental_id, customer_id, vehicle_id;

COMMIT;
\echo '✓ Alice''s rental committed and lock released!'
\echo ''

\echo 'Checking rentals for vehicle 10...'
SELECT 
    rental_id,
    customer_id,
    CASE customer_id WHEN 1 THEN 'Alice' WHEN 2 THEN 'Bob' ELSE 'Other' END AS customer,
    vehicle_id,
    status,
    created_at
FROM rental 
WHERE vehicle_id = 10 
  AND created_at >= CURRENT_TIMESTAMP - INTERVAL '1 minute'
ORDER BY rental_id DESC;

\echo ''
\echo 'Vehicle status:'
SELECT vehicle_id, status FROM vehicle WHERE vehicle_id = 10;

\echo ''
\echo '✅ SUCCESS: Only ONE rental created!'
\echo '    Bob in Terminal 2 waited, then saw vehicle was taken.'
\echo '    NO DOUBLE BOOKING!'
\echo ''
\prompt 'Press Enter to continue to Solution 2...' dummy

-- ============================================================================
-- SOLUTION 2: Atomic Operations (Prevents Lost Updates)
-- ============================================================================

\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'SOLUTION 2: Atomic Operations - Prevents Lost Updates'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo 'Scenario: Alice and Bob both update vehicle mileage'
\echo 'WITH atomic operations, both updates are preserved!'
\echo ''
\echo 'Terminal 1 (Alice): Updating vehicle 8 mileage ATOMICALLY...'
\prompt 'Press Enter to start: ' dummy

\echo ''
\echo 'Current mileage of vehicle 8:'
SELECT vehicle_id, mileage FROM vehicle WHERE vehicle_id = 8;

\echo ''
\echo 'Alice will add 100 miles using ATOMIC operation...'
\echo 'Waiting 8 seconds (Bob is also updating)...'
SELECT pg_sleep(8);

\echo ''
\echo 'Alice updates mileage ATOMICALLY: mileage = mileage + 100'
-- RIGHT WAY - Atomic operation:
UPDATE vehicle SET mileage = mileage + 100 WHERE vehicle_id = 8;

\echo '✓ Alice''s atomic update completed'
\echo ''

\echo 'Waiting for Bob to finish...'
SELECT pg_sleep(5);

\echo ''
\echo 'Final mileage of vehicle 8:'
SELECT vehicle_id, mileage FROM vehicle WHERE vehicle_id = 8;

\echo ''
\echo '✅ SUCCESS: Both updates were applied!'
\echo '    Alice: +100, Bob: +50'
\echo '    Total: +150 (both preserved)'
\echo '    NO LOST UPDATES!'
\echo ''
\prompt 'Press Enter to continue to Solution 3...' dummy

-- ============================================================================
-- SOLUTION 3: REPEATABLE READ Isolation (Prevents Non-Repeatable Reads)
-- ============================================================================

\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'SOLUTION 3: REPEATABLE READ - Prevents Inconsistent Reads'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo 'Scenario: Alice reads data in REPEATABLE READ mode'
\echo 'Bob changes data, but Alice sees consistent snapshot!'
\echo ''
\echo 'Terminal 1 (Alice): Checking available vehicles with REPEATABLE READ...'
\prompt 'Press Enter to start: ' dummy

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;  -- ← THIS IS THE KEY!
\echo '✓ Transaction started with REPEATABLE READ isolation'

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

\echo '✅ SUCCESS: Both counts are IDENTICAL!'
\echo '    REPEATABLE READ provides consistent snapshot'
\echo '    Bob''s changes not visible until after commit'
\echo '    NO INCONSISTENT READS!'
\echo ''
\prompt 'Press Enter to continue to Bonus...' dummy

-- ============================================================================
-- BONUS: Using Safe Functions
-- ============================================================================

\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'BONUS: Using Production-Safe Functions'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo 'The concurrency_safe_rental.sql provides ready-to-use functions:'
\echo ''

\echo 'Example: Safely book vehicle 15 for Alice:'
SELECT * FROM book_vehicle_safe(
    p_customer_id := 1,
    p_vehicle_id := 15,
    p_branch_id := 1,
    p_start_date := CURRENT_DATE + 1,
    p_end_date := CURRENT_DATE + 8
);

\echo ''
\echo 'Try to book the SAME vehicle again (should fail):'
SELECT * FROM book_vehicle_safe(
    p_customer_id := 2,
    p_vehicle_id := 15,
    p_branch_id := 1,
    p_start_date := CURRENT_DATE + 1,
    p_end_date := CURRENT_DATE + 8
);

\echo ''
\echo '✅ The function handles all locking automatically!'
\echo '    - Uses SELECT FOR UPDATE internally'
\echo '    - Checks for conflicts'
\echo '    - Returns success/failure clearly'
\echo ''

-- ============================================================================
-- SUMMARY
-- ============================================================================

\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'TERMINAL 1: Summary - WITH Concurrency Control'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo 'Solutions Demonstrated:'
\echo ''
\echo '1. ✅ SELECT FOR UPDATE: Prevented double booking'
\echo '      → Second user waited and saw vehicle was taken'
\echo ''
\echo '2. ✅ ATOMIC OPERATIONS: Both updates preserved'
\echo '      → Used UPDATE SET x = x + value instead of read-modify-write'
\echo ''
\echo '3. ✅ REPEATABLE READ: Consistent data within transaction'
\echo '      → Snapshot isolation prevented inconsistent reads'
\echo ''
\echo '4. ✅ SAFE FUNCTIONS: Production-ready with built-in protection'
\echo '      → Encapsulated locking logic, easy to use'
\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'CONCLUSION:'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo 'Proper concurrency control is ESSENTIAL for multi-user systems!'
\echo ''
\echo 'Key Techniques:'
\echo '  • SELECT FOR UPDATE - for critical sections'
\echo '  • Atomic operations - for numeric updates'
\echo '  • Proper isolation levels - for consistency'
\echo '  • Safe functions - for production use'
\echo ''
\echo 'Benefits:'
\echo '  ✓ Data integrity maintained'
\echo '  ✓ No double bookings'
\echo '  ✓ No lost updates'
\echo '  ✓ Consistent reporting'
\echo '  ✓ Happy customers!'
\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''





