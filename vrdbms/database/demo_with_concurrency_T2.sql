-- ============================================================================
-- DEMONSTRATION: WITH CONCURRENCY CONTROL - TERMINAL 2
-- Shows how proper locking prevents problems
-- ============================================================================
-- Run this in TERMINAL 2 while running demo_with_concurrency_T1.sql in TERMINAL 1
-- ============================================================================

\echo '============================================================================'
\echo '  TERMINAL 2: Demonstration WITH Concurrency Control'
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
-- SOLUTION 1: SELECT FOR UPDATE (Prevents Race Conditions)
-- ============================================================================

\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'SOLUTION 1: SELECT FOR UPDATE - Prevents Double Booking'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo 'Terminal 2 (Bob): Trying to rent vehicle 10...'
\echo 'Wait for Terminal 1 to start, then press Enter'
\prompt 'Press Enter (after Terminal 1 starts): ' dummy

-- Small delay so Terminal 1 locks first
SELECT pg_sleep(2);

BEGIN;
\echo '✓ Transaction started'

\echo ''
\echo 'Bob tries to check AND LOCK vehicle 10...'
\echo '⏳ WAITING... (Alice has the lock in Terminal 1)'

SELECT vehicle_id, make, model, status 
FROM vehicle 
WHERE vehicle_id = 10
FOR UPDATE;  -- This will WAIT for Alice to release the lock

\echo ''
\echo '✓ Lock acquired! Alice released it.'
\echo ''
\echo 'Bob now checks the current status:'
SELECT vehicle_id, status FROM vehicle WHERE vehicle_id = 10;

\echo ''
\echo '✓ Bob sees the vehicle is now "rented" (Alice got it)'
\echo '✓ Bob cannot book this vehicle'

ROLLBACK;
\echo '✓ Bob rolls back (no booking created)'
\echo ''

\echo '✅ SUCCESS: SELECT FOR UPDATE prevented double booking!'
\echo '    Bob WAITED for Alice to finish'
\echo '    Bob then saw the correct status'
\echo '    NO RACE CONDITION!'
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
\echo 'Terminal 2 (Bob): Updating vehicle 8 mileage ATOMICALLY...'
\echo 'Wait for Terminal 1 to start Solution 2'
\prompt 'Press Enter to start: ' dummy

-- Small delay so Terminal 1 goes first
SELECT pg_sleep(2);

\echo ''
\echo 'Current mileage of vehicle 8:'
SELECT vehicle_id, mileage FROM vehicle WHERE vehicle_id = 8;

\echo ''
\echo 'Bob will add 50 miles using ATOMIC operation...'
\echo 'Waiting 5 seconds...'
SELECT pg_sleep(5);

\echo ''
\echo 'Bob updates mileage ATOMICALLY: mileage = mileage + 50'
-- RIGHT WAY - Atomic operation:
UPDATE vehicle SET mileage = mileage + 50 WHERE vehicle_id = 8;

\echo '✓ Bob''s atomic update completed'
\echo ''

\echo '✅ SUCCESS: Bob''s update will be applied on top of Alice''s!'
\echo '    Both updates are preserved'
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
\echo 'Terminal 2 (Bob): Changing vehicle status...'
\echo 'Wait for Terminal 1 to start Solution 3'
\prompt 'Press Enter to start: ' dummy

-- Wait for Terminal 1 to read first
SELECT pg_sleep(3);

\echo ''
\echo 'Bob changes vehicle status from available to maintenance...'
UPDATE vehicle SET status = 'maintenance' WHERE vehicle_id = 12 AND status = 'available';

\echo '✓ Status changed'
\echo ''
\echo '   Alice in Terminal 1 is using REPEATABLE READ'
\echo '   She will NOT see this change until she commits'
\echo '   Her view remains consistent!'
\echo ''

\echo '✅ SUCCESS: Alice maintains consistent snapshot!'
\echo '    Her two reads show the same count'
\echo '    NO INCONSISTENT READS!'
\echo ''

-- ============================================================================
-- BONUS: Monitoring
-- ============================================================================

\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'BONUS: Monitoring Concurrent Activity'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''

\echo 'Active locks right now:'
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

\echo 'Active transactions:'
SELECT 
    pid,
    usename,
    state,
    wait_event_type,
    wait_event,
    LEFT(query, 50) AS query
FROM pg_stat_activity
WHERE state != 'idle'
  AND datname = 'vrdbms'
ORDER BY query_start;
\echo ''

-- ============================================================================
-- SUMMARY
-- ============================================================================

\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'TERMINAL 2: Summary - WITH Concurrency Control'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo 'Bob''s Experience:'
\echo ''
\echo '1. ✅ Tried to book vehicle 10'
\echo '      • WAITED for Alice to finish (didn''t proceed blindly)'
\echo '      • Saw correct status after Alice committed'
\echo '      • No double booking occurred'
\echo ''
\echo '2. ✅ Updated vehicle mileage atomically'
\echo '      • Both Alice''s and Bob''s updates preserved'
\echo '      • No data loss'
\echo ''
\echo '3. ✅ Alice maintained consistent view'
\echo '      • Bob''s changes not visible mid-transaction'
\echo '      • Proper snapshot isolation'
\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo 'KEY DIFFERENCES: WITH vs WITHOUT Concurrency Control'
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo '┌─────────────────────────┬────────────────────┬────────────────────┐'
\echo '│ Scenario                │ WITHOUT Control    │ WITH Control       │'
\echo '├─────────────────────────┼────────────────────┼────────────────────┤'
\echo '│ Double Booking          │ ❌ Happens          │ ✅ Prevented        │'
\echo '│ Lost Updates            │ ❌ Data lost        │ ✅ All preserved    │'
\echo '│ Inconsistent Reads      │ ❌ Different values │ ✅ Consistent       │'
\echo '│ Data Integrity          │ ❌ Corrupted        │ ✅ Maintained       │'
\echo '│ User Experience         │ ❌ Angry customers  │ ✅ Happy customers  │'
\echo '│ Production Ready        │ ❌ NO               │ ✅ YES              │'
\echo '└─────────────────────────┴────────────────────┴────────────────────┘'
\echo ''
\echo 'Implementation Techniques:'
\echo '  • SELECT FOR UPDATE → Prevents race conditions'
\echo '  • Atomic operations → Prevents lost updates'
\echo '  • REPEATABLE READ → Prevents inconsistent reads'
\echo '  • Safe functions → Encapsulates best practices'
\echo ''
\echo 'Performance Impact:'
\echo '  • Minimal overhead (1-5ms per lock)'
\echo '  • MUCH better than dealing with data corruption'
\echo '  • Essential for multi-user systems'
\echo ''
\echo '════════════════════════════════════════════════════════════════════════════'
\echo ''





