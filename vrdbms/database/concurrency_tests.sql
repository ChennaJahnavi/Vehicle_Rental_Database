-- ============================================================================
-- CONCURRENCY TESTING FOR VRDBMS
-- Tests for concurrent transactions, locking, and race conditions
-- ============================================================================
-- IMPORTANT: Run these tests in MULTIPLE terminal windows simultaneously
-- to see concurrency in action!
-- ============================================================================

\echo '============================================================================'
\echo '          CONCURRENCY TESTING SETUP'
\echo '============================================================================'
\echo ''
\echo 'This file contains tests that should be run in multiple terminals.'
\echo 'Each section has instructions for Terminal 1, Terminal 2, etc.'
\echo ''
\echo 'Current PostgreSQL settings:'
SELECT name, setting, unit, short_desc 
FROM pg_settings 
WHERE name IN ('max_connections', 'default_transaction_isolation', 'deadlock_timeout');
\echo ''

-- ============================================================================
-- TEST 1: Basic Transaction Isolation Levels
-- ============================================================================

\echo '============================================================================'
\echo 'TEST 1: Transaction Isolation Levels'
\echo '============================================================================'
\echo ''
\echo 'PostgreSQL supports 3 isolation levels:'
\echo '  - READ COMMITTED (default)'
\echo '  - REPEATABLE READ'
\echo '  - SERIALIZABLE'
\echo ''

-- Show current isolation level
\echo 'Current isolation level:'
SHOW transaction_isolation;
\echo ''

-- Demonstrate READ COMMITTED (default)
\echo 'Example: READ COMMITTED behavior'
\echo '-----------------------------------'
\echo 'Terminal 1: START TRANSACTION; SELECT COUNT(*) FROM vehicle WHERE status = ''available'';'
\echo 'Terminal 2: UPDATE vehicle SET status = ''maintenance'' WHERE vehicle_id = 1; COMMIT;'
\echo 'Terminal 1: SELECT COUNT(*) FROM vehicle WHERE status = ''available''; -- Will see updated count'
\echo 'Terminal 1: COMMIT;'
\echo ''

-- Demonstrate REPEATABLE READ
\echo 'Example: REPEATABLE READ behavior'
\echo '-----------------------------------'
\echo 'Terminal 1: BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;'
\echo 'Terminal 1: SELECT COUNT(*) FROM vehicle WHERE status = ''available'';'
\echo 'Terminal 2: UPDATE vehicle SET status = ''maintenance'' WHERE vehicle_id = 1; COMMIT;'
\echo 'Terminal 1: SELECT COUNT(*) FROM vehicle WHERE status = ''available''; -- Same count (snapshot)'
\echo 'Terminal 1: COMMIT;'
\echo ''

-- ============================================================================
-- TEST 2: Concurrent Vehicle Rental (Race Condition)
-- ============================================================================

\echo '============================================================================'
\echo 'TEST 2: Race Condition - Two Users Booking Same Vehicle'
\echo '============================================================================'
\echo ''
\echo 'Scenario: Two customers try to rent the same vehicle simultaneously'
\echo ''
\echo '### WITHOUT PROPER LOCKING (Race Condition Possible) ###'
\echo ''
\echo 'Open TWO terminal windows and run these commands AT THE SAME TIME:'
\echo ''
\echo '=== TERMINAL 1 (Customer A) ==='
\echo 'BEGIN;'
\echo 'SELECT vehicle_id, status FROM vehicle WHERE vehicle_id = 1;'
\echo '-- Wait 5 seconds --'
\echo 'SELECT pg_sleep(5);'
\echo 'INSERT INTO rental (customer_id, vehicle_id, branch_id, start_date, end_date, start_mileage, daily_rate, status)'
\echo 'VALUES (1, 1, 1, CURRENT_DATE, CURRENT_DATE + 7, 10000, 50.00, ''pending'');'
\echo 'COMMIT;'
\echo ''
\echo '=== TERMINAL 2 (Customer B) - Start immediately after Terminal 1 ==='
\echo 'BEGIN;'
\echo 'SELECT vehicle_id, status FROM vehicle WHERE vehicle_id = 1;'
\echo '-- Wait 5 seconds --'
\echo 'SELECT pg_sleep(5);'
\echo 'INSERT INTO rental (customer_id, vehicle_id, branch_id, start_date, end_date, start_mileage, daily_rate, status)'
\echo 'VALUES (2, 1, 1, CURRENT_DATE, CURRENT_DATE + 7, 10000, 50.00, ''pending'');'
\echo 'COMMIT;'
\echo ''
\echo '⚠️  PROBLEM: Both transactions see vehicle as available and create rentals!'
\echo ''

-- ============================================================================
-- TEST 3: Concurrent Rental with SELECT FOR UPDATE (Solution)
-- ============================================================================

\echo '============================================================================'
\echo 'TEST 3: SOLUTION - Using SELECT FOR UPDATE'
\echo '============================================================================'
\echo ''
\echo 'SELECT FOR UPDATE locks the row, preventing race conditions'
\echo ''
\echo '=== TERMINAL 1 (Customer A) ==='
\echo 'BEGIN;'
\echo 'SELECT vehicle_id, status FROM vehicle WHERE vehicle_id = 1 FOR UPDATE;'
\echo '-- Vehicle is now LOCKED for Terminal 1 --'
\echo 'SELECT pg_sleep(5);'
\echo 'UPDATE vehicle SET status = ''rented'' WHERE vehicle_id = 1;'
\echo 'INSERT INTO rental (customer_id, vehicle_id, branch_id, start_date, end_date, start_mileage, daily_rate, status)'
\echo 'VALUES (1, 1, 1, CURRENT_DATE, CURRENT_DATE + 7, 10000, 50.00, ''active'');'
\echo 'COMMIT;'
\echo ''
\echo '=== TERMINAL 2 (Customer B) - Start immediately ==='
\echo 'BEGIN;'
\echo 'SELECT vehicle_id, status FROM vehicle WHERE vehicle_id = 1 FOR UPDATE;'
\echo '-- This will WAIT until Terminal 1 commits --'
\echo 'SELECT status FROM vehicle WHERE vehicle_id = 1;'
\echo '-- Will see status = ''rented'', can handle appropriately --'
\echo 'ROLLBACK;'
\echo ''
\echo '✅ SOLUTION: Terminal 2 waits, then sees updated status'
\echo ''

-- ============================================================================
-- TEST 4: Deadlock Scenario
-- ============================================================================

\echo '============================================================================'
\echo 'TEST 4: Deadlock Detection'
\echo '============================================================================'
\echo ''
\echo 'Scenario: Two transactions lock resources in opposite order'
\echo ''
\echo '=== TERMINAL 1 ==='
\echo 'BEGIN;'
\echo 'UPDATE vehicle SET mileage = mileage + 10 WHERE vehicle_id = 1;'
\echo 'SELECT pg_sleep(3);'
\echo 'UPDATE vehicle SET mileage = mileage + 10 WHERE vehicle_id = 2;'
\echo 'COMMIT;'
\echo ''
\echo '=== TERMINAL 2 (start immediately) ==='
\echo 'BEGIN;'
\echo 'UPDATE vehicle SET mileage = mileage + 10 WHERE vehicle_id = 2;'
\echo 'SELECT pg_sleep(3);'
\echo 'UPDATE vehicle SET mileage = mileage + 10 WHERE vehicle_id = 1;'
\echo '-- DEADLOCK! PostgreSQL will abort one transaction --'
\echo 'COMMIT;'
\echo ''
\echo '⚠️  PostgreSQL detects deadlock and aborts one transaction'
\echo '✅ Application should retry the aborted transaction'
\echo ''

-- ============================================================================
-- TEST 5: Optimistic Locking with Version Numbers
-- ============================================================================

\echo '============================================================================'
\echo 'TEST 5: Optimistic Locking Pattern'
\echo '============================================================================'
\echo ''
\echo 'First, add a version column (for demonstration):'
\echo 'ALTER TABLE vehicle ADD COLUMN version INTEGER DEFAULT 1;'
\echo ''
\echo '=== TERMINAL 1 ==='
\echo 'BEGIN;'
\echo 'SELECT vehicle_id, mileage, version FROM vehicle WHERE vehicle_id = 1;'
\echo '-- Note the version number (e.g., version = 5) --'
\echo 'SELECT pg_sleep(5);'
\echo 'UPDATE vehicle SET mileage = 15000, version = version + 1'
\echo 'WHERE vehicle_id = 1 AND version = 5;'
\echo '-- Check rows affected: GET DIAGNOSTICS var = ROW_COUNT;'
\echo 'COMMIT;'
\echo ''
\echo '=== TERMINAL 2 (start immediately) ==='
\echo 'BEGIN;'
\echo 'SELECT vehicle_id, mileage, version FROM vehicle WHERE vehicle_id = 1;'
\echo '-- Same version number (version = 5) --'
\echo 'SELECT pg_sleep(3);'
\echo 'UPDATE vehicle SET mileage = 16000, version = version + 1'
\echo 'WHERE vehicle_id = 1 AND version = 5;'
\echo '-- This will update 0 rows! Version already changed by Terminal 1'
\echo 'COMMIT;'
\echo ''
\echo '✅ Optimistic locking detects concurrent modifications'
\echo ''

-- ============================================================================
-- TEST 6: Advisory Locks
-- ============================================================================

\echo '============================================================================'
\echo 'TEST 6: Advisory Locks (Application-level locks)'
\echo '============================================================================'
\echo ''
\echo 'Advisory locks are custom locks for application logic'
\echo ''
\echo '=== TERMINAL 1 ==='
\echo 'SELECT pg_advisory_lock(1);  -- Lock acquired'
\echo '-- Do some work --'
\echo 'SELECT pg_sleep(10);'
\echo 'SELECT pg_advisory_unlock(1);  -- Release lock'
\echo ''
\echo '=== TERMINAL 2 (start immediately) ==='
\echo 'SELECT pg_advisory_lock(1);  -- WAITS for Terminal 1'
\echo '-- Work starts only after Terminal 1 releases lock --'
\echo 'SELECT pg_advisory_unlock(1);'
\echo ''
\echo '✅ Useful for coordinating application-level operations'
\echo ''

-- ============================================================================
-- TEST 7: Read vs Write Lock Contention
-- ============================================================================

\echo '============================================================================'
\echo 'TEST 7: Read vs Write Lock Contention'
\echo '============================================================================'
\echo ''
\echo 'Multiple readers can read simultaneously, writers block everyone'
\echo ''
\echo '=== TERMINAL 1 (Reader 1) ==='
\echo 'BEGIN;'
\echo 'SELECT * FROM vehicle WHERE vehicle_id = 1;'
\echo 'SELECT pg_sleep(10);'
\echo 'COMMIT;'
\echo ''
\echo '=== TERMINAL 2 (Reader 2) - starts during Terminal 1 sleep ==='
\echo 'BEGIN;'
\echo 'SELECT * FROM vehicle WHERE vehicle_id = 1;'
\echo '-- ✅ Does NOT wait, reads proceed concurrently'
\echo 'COMMIT;'
\echo ''
\echo '=== TERMINAL 3 (Writer) - starts during sleep ==='
\echo 'BEGIN;'
\echo 'UPDATE vehicle SET mileage = 20000 WHERE vehicle_id = 1;'
\echo '-- ⏳ WAITS for all readers to finish'
\echo 'COMMIT;'
\echo ''

-- ============================================================================
-- TEST 8: SKIP LOCKED (Non-blocking reads)
-- ============================================================================

\echo '============================================================================'
\echo 'TEST 8: SKIP LOCKED - Non-blocking Queues'
\echo '============================================================================'
\echo ''
\echo 'Useful for job queues - skip locked rows instead of waiting'
\echo ''
\echo '=== TERMINAL 1 (Worker 1) ==='
\echo 'BEGIN;'
\echo 'SELECT * FROM vehicle WHERE status = ''available'''
\echo 'ORDER BY vehicle_id FOR UPDATE SKIP LOCKED LIMIT 1;'
\echo '-- Got vehicle_id = 1, now processing...'
\echo 'SELECT pg_sleep(10);'
\echo 'UPDATE vehicle SET status = ''rented'' WHERE vehicle_id = 1;'
\echo 'COMMIT;'
\echo ''
\echo '=== TERMINAL 2 (Worker 2) - starts immediately ==='
\echo 'BEGIN;'
\echo 'SELECT * FROM vehicle WHERE status = ''available'''
\echo 'ORDER BY vehicle_id FOR UPDATE SKIP LOCKED LIMIT 1;'
\echo '-- ✅ Skips vehicle_id = 1, returns vehicle_id = 2 instead'
\echo 'SELECT pg_sleep(5);'
\echo 'UPDATE vehicle SET status = ''rented'' WHERE vehicle_id = 2;'
\echo 'COMMIT;'
\echo ''
\echo '✅ Both workers process different vehicles without blocking'
\echo ''

-- ============================================================================
-- TEST 9: Lost Update Problem
-- ============================================================================

\echo '============================================================================'
\echo 'TEST 9: Lost Update Problem'
\echo '============================================================================'
\echo ''
\echo 'Scenario: Two users update the same record, one update gets lost'
\echo ''
\echo '=== TERMINAL 1 ==='
\echo 'BEGIN;'
\echo 'SELECT mileage FROM vehicle WHERE vehicle_id = 1;  -- Returns 10000'
\echo 'SELECT pg_sleep(5);'
\echo '-- Calculate: new_mileage = 10000 + 100 = 10100'
\echo 'UPDATE vehicle SET mileage = 10100 WHERE vehicle_id = 1;'
\echo 'COMMIT;'
\echo ''
\echo '=== TERMINAL 2 (start immediately) ==='
\echo 'BEGIN;'
\echo 'SELECT mileage FROM vehicle WHERE vehicle_id = 1;  -- Also returns 10000'
\echo 'SELECT pg_sleep(3);'
\echo '-- Calculate: new_mileage = 10000 + 50 = 10050'
\echo 'UPDATE vehicle SET mileage = 10050 WHERE vehicle_id = 1;'
\echo 'COMMIT;'
\echo ''
\echo '⚠️  PROBLEM: Final mileage is 10050, but should be 10150!'
\echo '✅ SOLUTION: Use UPDATE ... SET mileage = mileage + 50 (atomic)'
\echo ''

-- ============================================================================
-- TEST 10: Phantom Reads
-- ============================================================================

\echo '============================================================================'
\echo 'TEST 10: Phantom Reads'
\echo '============================================================================'
\echo ''
\echo 'Scenario: New rows appear in a transaction'
\echo ''
\echo '=== TERMINAL 1 ==='
\echo 'BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;'
\echo 'SELECT COUNT(*) FROM rental WHERE customer_id = 1;  -- Returns 5'
\echo 'SELECT pg_sleep(5);'
\echo 'SELECT COUNT(*) FROM rental WHERE customer_id = 1;  -- Still returns 5'
\echo 'COMMIT;'
\echo ''
\echo '=== TERMINAL 2 (start during sleep) ==='
\echo 'INSERT INTO rental (customer_id, vehicle_id, branch_id, start_date, end_date, start_mileage, daily_rate)'
\echo 'VALUES (1, 5, 1, CURRENT_DATE, CURRENT_DATE + 7, 1000, 50.00);'
\echo 'COMMIT;'
\echo ''
\echo '✅ REPEATABLE READ prevents phantom reads (Terminal 1 sees consistent snapshot)'
\echo ''

-- ============================================================================
-- MONITORING QUERIES
-- ============================================================================

\echo '============================================================================'
\echo 'MONITORING: Current Locks and Blocking Queries'
\echo '============================================================================'
\echo ''

\echo 'Current locks in the database:'
\echo '-----------------------------------'
SELECT 
    locktype,
    relation::regclass AS table_name,
    mode,
    granted,
    pid,
    pg_blocking_pids(pid) AS blocking_pids
FROM pg_locks
WHERE relation IS NOT NULL
  AND relation::regclass::text NOT LIKE 'pg_%'
ORDER BY pid;
\echo ''

\echo 'Active transactions:'
\echo '-----------------------------------'
SELECT 
    pid,
    usename,
    application_name,
    state,
    query_start,
    state_change,
    wait_event_type,
    wait_event,
    LEFT(query, 60) AS query
FROM pg_stat_activity
WHERE state != 'idle'
  AND pid != pg_backend_pid()
ORDER BY query_start;
\echo ''

\echo 'Blocking and blocked queries:'
\echo '-----------------------------------'
SELECT 
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_statement,
    blocking_activity.query AS blocking_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks 
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
\echo ''

\echo 'Deadlock count (since last reset):'
\echo '-----------------------------------'
SELECT 
    datname,
    deadlocks,
    conflicts,
    temp_files,
    temp_bytes
FROM pg_stat_database
WHERE datname = 'vrdbms';
\echo ''

-- ============================================================================
-- SUMMARY
-- ============================================================================

\echo '============================================================================'
\echo 'CONCURRENCY TESTING SUMMARY'
\echo '============================================================================'
\echo ''
\echo 'Key Concepts Covered:'
\echo '  1. Transaction Isolation Levels'
\echo '  2. Race Conditions in vehicle booking'
\echo '  3. SELECT FOR UPDATE (pessimistic locking)'
\echo '  4. Deadlock detection and handling'
\echo '  5. Optimistic locking with version numbers'
\echo '  6. Advisory locks for custom logic'
\echo '  7. Read vs Write lock contention'
\echo '  8. SKIP LOCKED for job queues'
\echo '  9. Lost update problem'
\echo '  10. Phantom reads'
\echo ''
\echo 'To see these in action:'
\echo '  1. Open multiple terminal windows'
\echo '  2. Connect to the database: psql -U ceejayy -d vrdbms'
\echo '  3. Run the commands from each test simultaneously'
\echo '  4. Observe locking, waiting, and conflict resolution'
\echo ''
\echo 'Monitoring commands:'
\echo '  - View current locks: SELECT * FROM pg_locks WHERE relation IS NOT NULL;'
\echo '  - View active queries: SELECT * FROM pg_stat_activity;'
\echo '  - Kill a query: SELECT pg_cancel_backend(pid);'
\echo '  - Force terminate: SELECT pg_terminate_backend(pid);'
\echo ''
\echo '============================================================================'





