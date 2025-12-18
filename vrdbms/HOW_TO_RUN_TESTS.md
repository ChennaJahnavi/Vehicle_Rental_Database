# How to Run Tests for VRDBMS

This guide shows you how to run the tests mentioned in `TEST_RESULTS.md`.

## Prerequisites

- PostgreSQL database `vrdbms` is set up
- Database user: `ceejayy` (or your username)
- Database is populated with test data

---

## 1. Index Performance Tests

### Quick Verification (5 seconds)
```bash
cd /Users/ceejayy/Documents/180B_Project1/vrdbms
psql -U ceejayy -d vrdbms -f database/quick_verify.sql
```

**What it does:** Quickly checks that all 34 indexes are created and shows basic index usage.

### Comprehensive Benchmark (2-3 minutes)
```bash
psql -U ceejayy -d vrdbms -f database/benchmark_comparison.sql
```

**What it does:** Compares query performance with and without indexes, showing execution times and improvements.

### Detailed Analysis
```bash
psql -U ceejayy -d vrdbms -f database/test_optimization.sql
```

**What it does:** Detailed EXPLAIN ANALYZE output showing query plans and performance metrics.

### Test Index Performance
```bash
psql -U ceejayy -d vrdbms -f database/test_index_performance.sql
```

**What it does:** Tests specific index performance scenarios.

---

## 2. Concurrency Tests

### Option A: Interactive Demo (Recommended - Most Visual)

**Terminal 1:**
```bash
cd /Users/ceejayy/Documents/180B_Project1/vrdbms
psql -U ceejayy -d vrdbms -f database/concurrency_terminal1.sql
```

**Terminal 2 (open a new terminal window and run simultaneously):**
```bash
cd /Users/ceejayy/Documents/180B_Project1/vrdbms
psql -U ceejayy -d vrdbms -f database/concurrency_terminal2.sql
```

**What it does:** Simulates two users trying to book the same vehicle simultaneously. You'll see:
- Race conditions without locking
- Proper locking with `SELECT FOR UPDATE`
- Deadlock detection

### Option B: Educational Overview
```bash
psql -U ceejayy -d vrdbms -f database/concurrency_tests.sql
```

**What it does:** Shows all concurrency test scenarios with explanations.

### Option C: Web UI Demo (Easiest - No SQL needed!)

1. Make sure your Flask app is running:
   ```bash
   cd /Users/ceejayy/Documents/180B_Project1/vrdbms/app
   python3 app.py
   ```

2. Open browser: `http://localhost:5001/concurrency-demo`

3. Click "Start Demo" and test both modes:
   - ❌ **WITHOUT Locking** - Shows race condition (both users can book)
   - ✅ **WITH Locking** - Shows proper prevention (only one user can book)

---

## 3. Demo Scripts (For Presentations)

### Demo with Indexes
```bash
psql -U ceejayy -d vrdbms -f database/demo_with_indexes.sql
```

### Demo without Indexes (for comparison)
```bash
psql -U ceejayy -d vrdbms -f database/demo_without_indexes.sql
```

### Performance Comparison Demo
```bash
psql -U ceejayy -d vrdbms -f database/demo_performance_comparison.sql
```

---

## 4. Quick Test Checklist

Run these in order to verify everything works:

```bash
# 1. Quick index check (5 seconds)
psql -U ceejayy -d vrdbms -f database/quick_verify.sql

# 2. Web UI concurrency demo (easiest)
# Just open http://localhost:5001/concurrency-demo in browser

# 3. Full benchmark (2-3 minutes)
psql -U ceejayy -d vrdbms -f database/benchmark_comparison.sql
```

---

## 5. Understanding Test Results

### Index Performance
- **Execution Time:** Should be < 1ms for indexed queries
- **Scan Method:** Should show "Index Scan" or "Bitmap Index Scan" (not "Seq Scan")
- **Improvement:** Expect 8x to 106x speedup with indexes

### Concurrency Tests
- **WITHOUT Locking:** Both users can book same vehicle (❌ bug)
- **WITH Locking:** Only one user can book (✅ correct)
- **Deadlock:** PostgreSQL automatically detects and resolves

---

## 6. Troubleshooting

### "Database does not exist"
```bash
createdb -U ceejayy vrdbms
psql -U ceejayy -d vrdbms -f database/schema.sql
psql -U ceejayy -d vrdbms -f database/sample_data.sql
```

### "Indexes not found"
```bash
psql -U ceejayy -d vrdbms -f database/add_indexes.sql
```

### "Permission denied"
Make sure you're using the correct username. Check your `app.py` for the database user.

---

## 7. Test Results Summary

After running tests, you should see:

✅ **Index Performance:**
- 27x average speedup
- 106x improvement on customer lookups
- 99.7% reduction in rows scanned

✅ **Concurrency:**
- Zero race conditions with proper locking
- Deadlock detection working
- Data integrity maintained

---

**Need help?** Check `TEST_RESULTS.md` for detailed test results and explanations.

