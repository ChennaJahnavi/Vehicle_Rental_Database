

# Concurrency Testing Guide for VRDBMS

## Overview

This guide explains how to test and demonstrate concurrency control in your Vehicle Rental Database Management System. Concurrency is critical for preventing issues like double-booking, lost updates, and race conditions when multiple users access the system simultaneously.

---

## 📁 Files Created

### Test Scripts
1. **`concurrency_tests.sql`** - Educational guide with all concurrency concepts
2. **`concurrency_terminal1.sql`** - Interactive tests for Terminal 1
3. **`concurrency_terminal2.sql`** - Interactive tests for Terminal 2 (runs alongside Terminal 1)
4. **`concurrency_safe_rental.sql`** - Production-ready functions with proper locking

### Documentation
5. **`CONCURRENCY_GUIDE.md`** - This file (complete guide)

---

## 🎯 Concurrency Issues Demonstrated

### 1. **Race Conditions**
**Problem:** Two users try to book the same vehicle simultaneously  
**Demo:** Scenario 1 in terminal scripts  
**Solution:** Use `SELECT FOR UPDATE` to lock rows

### 2. **Deadlocks**
**Problem:** Two transactions lock resources in opposite order  
**Demo:** Scenario 3 in terminal scripts  
**Solution:** PostgreSQL automatically detects and aborts one transaction

### 3. **Lost Updates**
**Problem:** Concurrent updates override each other  
**Demo:** Scenario 5 in terminal scripts  
**Solution:** Use atomic operations (`UPDATE SET x = x + 1`)

### 4. **Phantom Reads**
**Problem:** New rows appear during a transaction  
**Demo:** concurrency_tests.sql  
**Solution:** Use `REPEATABLE READ` isolation level

### 5. **Blocking vs Non-Blocking**
**Problem:** Workers waiting on locked resources  
**Demo:** Scenario 4 (SKIP LOCKED) in terminal scripts  
**Solution:** Use `FOR UPDATE SKIP LOCKED` for job queues

---

## 🚀 Quick Start - Interactive Demo

### Prerequisites
```bash
# Ensure database is running
psql -U ceejayy -d vrdbms -c "SELECT 1"
```

### Method 1: Side-by-Side Terminal Demo (Recommended)

**Step 1: Open two terminal windows**

**Terminal 1:**
```bash
cd /Users/ceejayy/Documents/180B_Project1/vrdbms
psql -U ceejayy -d vrdbms -f database/concurrency_terminal1.sql
```

**Terminal 2:**
```bash
cd /Users/ceejayy/Documents/180B_Project1/vrdbms
psql -U ceejayy -d vrdbms -f database/concurrency_terminal2.sql
```

**Follow the prompts** - Each script will pause and tell you when to start the other terminal. This demonstrates:
- ✅ Race conditions (double booking)
- ✅ SELECT FOR UPDATE (proper locking)
- ✅ Deadlock detection
- ✅ SKIP LOCKED pattern
- ✅ Lost update prevention

**Duration:** 5-10 minutes

---

### Method 2: Educational Overview

**Read about all concepts:**
```bash
psql -U ceejayy -d vrdbms -f database/concurrency_tests.sql
```

This file explains 10 concurrency scenarios with examples for manual testing.

**Duration:** 2-3 minutes to read through

---

### Method 3: Install Production-Ready Functions

**Add concurrency-safe booking functions:**
```bash
psql -U ceejayy -d vrdbms -f database/concurrency_safe_rental.sql
```

This creates:
- `book_vehicle_safe()` - Prevents race conditions
- `activate_rental_safe()` - Safe activation
- `complete_rental_safe()` - Safe completion
- `cancel_rental_safe()` - Safe cancellation
- `get_available_vehicles_concurrent()` - Thread-safe availability check

**Duration:** 30 seconds

---

## 📊 Detailed Scenarios

### Scenario 1: Race Condition (Double Booking)

**The Problem:**
```sql
-- Terminal 1 (Alice)
BEGIN;
SELECT * FROM vehicle WHERE vehicle_id = 5;  -- Available ✓
-- Wait 5 seconds
INSERT INTO rental (...) VALUES (1, 5, ...);  -- Books it
COMMIT;

-- Terminal 2 (Bob) - starts during wait
BEGIN;
SELECT * FROM vehicle WHERE vehicle_id = 5;  -- Still shows available! ✗
-- Wait 3 seconds
INSERT INTO rental (...) VALUES (2, 5, ...);  -- Also books it!
COMMIT;

-- RESULT: Both Alice and Bob booked the same vehicle!
```

**The Solution:**
```sql
-- Terminal 1 (Alice)
BEGIN;
SELECT * FROM vehicle WHERE vehicle_id = 5 FOR UPDATE;  -- LOCKED ✓
-- Vehicle is now locked for Terminal 1
UPDATE vehicle SET status = 'rented' WHERE vehicle_id = 5;
INSERT INTO rental (...) VALUES (1, 5, ...);
COMMIT;  -- Lock released

-- Terminal 2 (Bob)
BEGIN;
SELECT * FROM vehicle WHERE vehicle_id = 5 FOR UPDATE;  -- WAITS for lock
-- Once lock is released, sees status = 'rented'
-- Can now show user "Vehicle unavailable"
ROLLBACK;

-- RESULT: Only Alice gets the vehicle. Bob sees it's taken. ✓
```

---

### Scenario 2: Deadlock

**The Problem:**
```sql
-- Terminal 1
BEGIN;
UPDATE vehicle SET mileage = mileage + 1 WHERE vehicle_id = 1;  -- Lock V1
-- Wait
UPDATE vehicle SET mileage = mileage + 1 WHERE vehicle_id = 2;  -- Wait for V2...

-- Terminal 2
BEGIN;
UPDATE vehicle SET mileage = mileage + 1 WHERE vehicle_id = 2;  -- Lock V2
-- Wait
UPDATE vehicle SET mileage = mileage + 1 WHERE vehicle_id = 1;  -- Wait for V1...

-- DEADLOCK! T1 waits for T2, T2 waits for T1
```

**PostgreSQL's Solution:**
- Automatically detects the deadlock (after `deadlock_timeout`, default 1 second)
- Aborts one transaction with error: `deadlock detected`
- Other transaction proceeds
- **Application should retry** the aborted transaction

---

### Scenario 3: Lost Update

**The Problem:**
```sql
-- Terminal 1
BEGIN;
SELECT mileage FROM vehicle WHERE vehicle_id = 1;  -- Returns 10000
-- Calculate: new_mileage = 10000 + 100 = 10100
UPDATE vehicle SET mileage = 10100 WHERE vehicle_id = 1;
COMMIT;

-- Terminal 2 (overlapping)
BEGIN;
SELECT mileage FROM vehicle WHERE vehicle_id = 1;  -- Also returns 10000
-- Calculate: new_mileage = 10000 + 50 = 10050
UPDATE vehicle SET mileage = 10050 WHERE vehicle_id = 1;
COMMIT;

-- RESULT: Mileage is 10050, but should be 10150! (Lost 100 miles)
```

**The Solution:**
```sql
-- Both terminals use atomic operations:
UPDATE vehicle SET mileage = mileage + 100 WHERE vehicle_id = 1;  -- T1
UPDATE vehicle SET mileage = mileage + 50 WHERE vehicle_id = 1;   -- T2

-- RESULT: Mileage correctly becomes 10150 ✓
```

---

### Scenario 4: SKIP LOCKED (Job Queue Pattern)

**Use Case:** Multiple workers processing available vehicles

```sql
-- Worker 1
BEGIN;
SELECT * FROM vehicle 
WHERE status = 'available'
ORDER BY vehicle_id
FOR UPDATE SKIP LOCKED  -- Get first available, skip locked ones
LIMIT 1;
-- Got vehicle_id = 5
-- Process it...
UPDATE vehicle SET status = 'maintenance' WHERE vehicle_id = 5;
COMMIT;

-- Worker 2 (running simultaneously)
BEGIN;
SELECT * FROM vehicle 
WHERE status = 'available'
ORDER BY vehicle_id
FOR UPDATE SKIP LOCKED
LIMIT 1;
-- Got vehicle_id = 7 (skipped locked vehicle 5)
-- Process it...
UPDATE vehicle SET status = 'maintenance' WHERE vehicle_id = 7;
COMMIT;

-- RESULT: Both workers processed different vehicles without blocking! ✓
```

---

## 🔧 Transaction Isolation Levels

PostgreSQL supports 3 isolation levels:

### 1. **READ COMMITTED** (Default)
- Sees committed changes from other transactions during execution
- Good for most applications
- Prevents dirty reads

```sql
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

### 2. **REPEATABLE READ**
- Sees a consistent snapshot throughout the transaction
- Prevents phantom reads
- Good for reports and analytics

```sql
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```

### 3. **SERIALIZABLE**
- Strongest isolation
- Transactions appear to run serially
- May cause more serialization errors
- Use when absolute consistency is required

```sql
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

---

## 💡 Locking Strategies

### 1. **SELECT FOR UPDATE** (Pessimistic Locking)
Locks rows immediately.

```sql
BEGIN;
SELECT * FROM vehicle WHERE vehicle_id = 1 FOR UPDATE;
-- Row is locked until COMMIT or ROLLBACK
UPDATE vehicle SET status = 'rented' WHERE vehicle_id = 1;
COMMIT;
```

**Use when:**
- High contention expected
- Critical to prevent conflicts
- Short transaction duration

### 2. **SELECT FOR UPDATE NOWAIT**
Returns error immediately if row is locked.

```sql
SELECT * FROM vehicle WHERE vehicle_id = 1 FOR UPDATE NOWAIT;
-- Returns immediately with error if locked
```

**Use when:**
- Can't wait for locks
- Want to show "try again later" to user

### 3. **SELECT FOR UPDATE SKIP LOCKED**
Skips locked rows.

```sql
SELECT * FROM vehicle 
WHERE status = 'available'
FOR UPDATE SKIP LOCKED
LIMIT 1;
-- Returns first unlocked available vehicle
```

**Use when:**
- Job queues
- Parallel workers
- Any unlocked row is acceptable

### 4. **Optimistic Locking** (Version Numbers)
Detects conflicts at commit time.

```sql
-- Add version column
ALTER TABLE vehicle ADD COLUMN version INTEGER DEFAULT 1;

-- Application flow:
-- 1. Read with version
SELECT vehicle_id, mileage, version FROM vehicle WHERE vehicle_id = 1;
-- Returns: version = 5

-- 2. User makes changes

-- 3. Update with version check
UPDATE vehicle 
SET mileage = 15000, version = version + 1
WHERE vehicle_id = 1 AND version = 5;  -- Fails if version changed

-- 4. Check rows affected
-- If 0 rows updated, someone else modified it - show error to user
```

**Use when:**
- Low contention
- Long-running transactions (web forms)
- Better user experience (no waiting)

---

## 🛡️ Using the Safe Functions

After installing `concurrency_safe_rental.sql`, use these functions:

### Book a Vehicle (Safe)
```sql
SELECT * FROM book_vehicle_safe(
    p_customer_id := 1,
    p_vehicle_id := 15,
    p_branch_id := 1,
    p_start_date := CURRENT_DATE + 1,
    p_end_date := CURRENT_DATE + 8,
    p_employee_id := 5
);

-- Returns:
-- success | rental_id | message
-- --------+-----------+---------------------------
-- true    | 142       | Rental 142 created successfully
```

### Handle Errors
```sql
SELECT * FROM book_vehicle_safe(
    p_customer_id := 1,
    p_vehicle_id := 99,  -- Doesn't exist
    p_branch_id := 1,
    p_start_date := CURRENT_DATE + 1,
    p_end_date := CURRENT_DATE + 8
);

-- Returns:
-- success | rental_id | message
-- --------+-----------+------------------
-- false   | NULL      | Vehicle not found
```

### Get Available Vehicles (Thread-Safe)
```sql
-- Regular query (no locking)
SELECT * FROM get_available_vehicles_concurrent(
    p_start_date := CURRENT_DATE + 1,
    p_end_date := CURRENT_DATE + 8,
    p_branch_id := 1,
    p_lock_for_booking := FALSE
);

-- With locking (in a transaction before booking)
BEGIN;
SELECT * FROM get_available_vehicles_concurrent(
    p_start_date := CURRENT_DATE + 1,
    p_end_date := CURRENT_DATE + 8,
    p_branch_id := 1,
    p_lock_for_booking := TRUE  -- Locks results
);
-- Now safe to book one of these vehicles
SELECT * FROM book_vehicle_safe(...);
COMMIT;
```

---

## 📈 Monitoring Concurrency

### View Current Locks
```sql
SELECT 
    locktype,
    relation::regclass AS table_name,
    mode,
    granted,
    pid
FROM pg_locks
WHERE relation IS NOT NULL
ORDER BY pid;
```

### View Blocking Queries
```sql
SELECT 
    blocked_locks.pid AS blocked_pid,
    blocking_locks.pid AS blocking_pid,
    blocked_activity.query AS blocked_query,
    blocking_activity.query AS blocking_query
FROM pg_locks blocked_locks
JOIN pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

### View Active Transactions
```sql
SELECT 
    pid,
    usename,
    state,
    query_start,
    wait_event_type,
    wait_event,
    query
FROM pg_stat_activity
WHERE state != 'idle'
  AND datname = 'vrdbms';
```

### Kill a Blocking Query
```sql
-- Cancel gracefully
SELECT pg_cancel_backend(12345);  -- Replace with actual PID

-- Force terminate (if cancel doesn't work)
SELECT pg_terminate_backend(12345);
```

### Check Deadlock Statistics
```sql
SELECT 
    datname,
    deadlocks,
    conflicts
FROM pg_stat_database
WHERE datname = 'vrdbms';
```

---

## 🧪 Testing Checklist

### Manual Tests

- [ ] Run terminal1 and terminal2 scripts side-by-side
- [ ] Observe race condition (Scenario 1)
- [ ] Observe SELECT FOR UPDATE preventing race (Scenario 2)
- [ ] Trigger a deadlock (Scenario 3)
- [ ] Test SKIP LOCKED with parallel workers (Scenario 4)
- [ ] Demonstrate lost updates and solution (Scenario 5)

### Automated Tests

- [ ] Install safe functions: `psql -U ceejayy -d vrdbms -f concurrency_safe_rental.sql`
- [ ] Test booking same vehicle twice (should fail second time)
- [ ] Test concurrent bookings of different vehicles (should succeed)
- [ ] Test date conflict detection
- [ ] Test activation, completion, cancellation flows

### Load Tests

- [ ] Simulate multiple users booking simultaneously
- [ ] Monitor lock wait times
- [ ] Check for deadlocks under load
- [ ] Verify no double bookings occur

---

## ⚠️ Best Practices

### DO:
✅ Use `SELECT FOR UPDATE` when booking vehicles  
✅ Keep transactions short  
✅ Use `SKIP LOCKED` for job queues  
✅ Handle deadlock errors with retry logic  
✅ Use atomic operations (`UPDATE SET x = x + 1`)  
✅ Monitor long-running transactions  

### DON'T:
❌ Hold locks during user input/wait times  
❌ Lock more rows than necessary  
❌ Use `SELECT FOR UPDATE` on large result sets  
❌ Ignore deadlock errors  
❌ Use read-modify-write patterns without locking  
❌ Leave transactions open indefinitely  

---

## 📚 Additional Resources

### PostgreSQL Documentation
- [Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html)
- [Explicit Locking](https://www.postgresql.org/docs/current/explicit-locking.html)
- [Monitoring Locks](https://www.postgresql.org/docs/current/view-pg-locks.html)

### Common Issues

**Q: Transaction waiting forever?**
```sql
-- Find blocking queries
SELECT * FROM pg_stat_activity WHERE wait_event_type = 'Lock';

-- Kill blocking transaction
SELECT pg_terminate_backend(blocking_pid);
```

**Q: Too many deadlocks?**
- Ensure consistent lock order
- Keep transactions short
- Use optimistic locking for long operations

**Q: Performance degradation?**
- Monitor lock waits
- Reduce transaction scope
- Use connection pooling
- Consider partitioning for large tables

---

## 🎓 Summary

You now have comprehensive concurrency testing for VRDBMS:

1. **Educational Scripts** - Learn concepts (`concurrency_tests.sql`)
2. **Interactive Demos** - See it in action (terminal1/terminal2)
3. **Production Functions** - Use in your app (`concurrency_safe_rental.sql`)
4. **Monitoring Tools** - Track performance (queries in this guide)

**Start testing:**
```bash
cd /Users/ceejayy/Documents/180B_Project1/vrdbms
# Open two terminals and run these simultaneously:
psql -U ceejayy -d vrdbms -f database/concurrency_terminal1.sql  # Terminal 1
psql -U ceejayy -d vrdbms -f database/concurrency_terminal2.sql  # Terminal 2
```

**For production use:**
```bash
psql -U ceejayy -d vrdbms -f database/concurrency_safe_rental.sql
```

Happy concurrent programming! 🚀





