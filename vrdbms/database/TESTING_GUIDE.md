# Index Optimization Testing Guide

This guide explains how to test and prove that the index optimizations are working.

## Available Test Scripts

### 1. **quick_verify.sql** ⚡ (Recommended First)
**Purpose:** Fast verification that indexes exist and are working  
**Runtime:** ~5 seconds  
**Safe:** Yes (read-only)

```bash
cd /Users/ceejayy/Documents/180B_Project1/vrdbms
psql -U ceejayy -d vrdbms -f database/quick_verify.sql
```

**What it shows:**
- ✅ Counts all 34 indexes
- ✅ Proves indexes are being used via EXPLAIN
- ✅ Shows index usage statistics
- ✅ Displays query execution times

**Perfect for:** Quick confirmation everything is working

---

### 2. **test_optimization.sql** 📊 (Most Comprehensive)
**Purpose:** Detailed analysis of all optimized queries  
**Runtime:** ~30-60 seconds  
**Safe:** Yes (read-only)

```bash
cd /Users/ceejayy/Documents/180B_Project1/vrdbms
psql -U ceejayy -d vrdbms -f database/test_optimization.sql
```

**What it shows:**
- ✅ EXPLAIN ANALYZE for all major queries
- ✅ Dashboard queries from app.py
- ✅ Complex business queries with joins
- ✅ Date range and aggregation queries
- ✅ Index usage statistics
- ✅ Performance metrics

**Perfect for:** Understanding exactly how each query is optimized

---

### 3. **benchmark_comparison.sql** 📈 (Before/After Proof)
**Purpose:** Shows performance WITH vs WITHOUT indexes  
**Runtime:** ~2-3 minutes  
**Safe:** ⚠️ Temporarily drops/recreates indexes (test database recommended)

```bash
cd /Users/ceejayy/Documents/180B_Project1/vrdbms
psql -U ceejayy -d vrdbms -f database/benchmark_comparison.sql
```

**What it shows:**
- ✅ Query performance WITH indexes
- ✅ Query performance WITHOUT indexes (after temporarily dropping)
- ✅ Concrete timing comparisons
- ✅ EXPLAIN output differences
- ✅ Automatic index restoration

**Perfect for:** Demonstrating tangible performance improvements

⚠️ **Warning:** This script temporarily drops indexes for comparison, then restores them. While safe, it's best run on a test database or during off-hours.

---

### 4. **analyze_indexes.sql** 🔍 (Monitoring & Analysis)
**Purpose:** Deep dive into index health and usage  
**Runtime:** ~10-20 seconds  
**Safe:** Yes (read-only)

```bash
cd /Users/ceejayy/Documents/180B_Project1/vrdbms
psql -U ceejayy -d vrdbms -f database/analyze_indexes.sql
```

**What it shows:**
- ✅ All indexes with sizes
- ✅ Index usage statistics (which are used most)
- ✅ Potentially unused indexes
- ✅ Table sizes with index overhead
- ✅ Foreign key index coverage
- ✅ EXPLAIN ANALYZE for key dashboard queries

**Perfect for:** Ongoing monitoring and optimization analysis

---

## Quick Start - Run All Tests

To run a complete verification suite:

```bash
cd /Users/ceejayy/Documents/180B_Project1/vrdbms

# 1. Quick check (5 sec)
echo "=== QUICK VERIFICATION ==="
psql -U ceejayy -d vrdbms -f database/quick_verify.sql

# 2. Comprehensive test (1 min)
echo "=== COMPREHENSIVE TEST ==="
psql -U ceejayy -d vrdbms -f database/test_optimization.sql

# 3. Before/after comparison (2-3 min)
echo "=== BENCHMARK COMPARISON ==="
psql -U ceejayy -d vrdbms -f database/benchmark_comparison.sql

# 4. Index analysis (10 sec)
echo "=== INDEX ANALYSIS ==="
psql -U ceejayy -d vrdbms -f database/analyze_indexes.sql
```

Or save output to files for review:

```bash
cd /Users/ceejayy/Documents/180B_Project1/vrdbms

psql -U ceejayy -d vrdbms -f database/quick_verify.sql > test_results/quick_verify_output.txt
psql -U ceejayy -d vrdbms -f database/test_optimization.sql > test_results/test_output.txt
psql -U ceejayy -d vrdbms -f database/benchmark_comparison.sql > test_results/benchmark_output.txt
psql -U ceejayy -d vrdbms -f database/analyze_indexes.sql > test_results/analyze_output.txt
```

---

## Understanding the Output

### What to Look For in EXPLAIN Output

#### ✅ **GOOD - Index is Being Used:**
```
Index Scan using idx_vehicle_status on vehicle
  Index Cond: (status = 'available'::vehicle_status)
```

```
Bitmap Index Scan on idx_rental_dates
  Index Cond: ((start_date >= ...) AND (end_date <= ...))
```

#### ❌ **BAD - Index NOT Being Used:**
```
Seq Scan on vehicle
  Filter: (status = 'available'::vehicle_status)
```

### Key Metrics to Check

1. **Execution Time:**
   - WITH indexes: Usually < 5ms for simple queries
   - WITHOUT indexes: Can be 10-100x slower

2. **Cost Values:**
   - Lower is better
   - Compare "cost=X..Y" in EXPLAIN output

3. **Index Scan Count (idx_scan):**
   - Higher numbers = index is being used frequently
   - 0 = index hasn't been used yet (may indicate issue)

4. **Buffers:**
   - "shared hit" = data found in cache (good)
   - "shared read" = data read from disk (slower but normal)

---

## Common Test Scenarios

### Scenario 1: Verify Dashboard Performance

```bash
psql -U ceejayy -d vrdbms -f database/quick_verify.sql
```

Look for:
- "Index Scan" in sections 3-7
- Query times < 5ms in section 10

---

### Scenario 2: Prove Optimization to Others

```bash
psql -U ceejayy -d vrdbms -f database/benchmark_comparison.sql > benchmark_results.txt
```

Show the timing differences between WITH and WITHOUT indexes.

---

### Scenario 3: Debug Slow Query

```sql
-- In psql:
EXPLAIN (ANALYZE, BUFFERS, COSTS, TIMING) 
SELECT ... your slow query ...;
```

If you see "Seq Scan" on large tables, you may need an additional index.

---

### Scenario 4: Monitor Index Usage Over Time

```bash
# Run initially
psql -U ceejayy -d vrdbms -f database/analyze_indexes.sql > indexes_day1.txt

# Use application for a day

# Run again
psql -U ceejayy -d vrdbms -f database/analyze_indexes.sql > indexes_day2.txt

# Compare idx_scan values
diff indexes_day1.txt indexes_day2.txt
```

---

## Troubleshooting

### Problem: "Index Scan" not showing in EXPLAIN

**Solutions:**
1. Update table statistics:
   ```sql
   ANALYZE table_name;
   ```

2. Check if table is too small (< 100 rows) - PostgreSQL may skip index
3. Verify WHERE clause matches index columns exactly

### Problem: Query still slow despite index

**Solutions:**
1. Check data types match in WHERE clause
2. Use EXPLAIN ANALYZE to see actual timing
3. Consider if index is correct type for query pattern
4. Check if too many rows match (index less helpful for common values)

### Problem: idx_scan shows 0 for some indexes

**Explanation:** 
- Index hasn't been needed yet
- Query hasn't been run yet
- Table too small for PostgreSQL to use index

**Action:** Run application queries, then check again

---

## Performance Benchmarks

Expected results on sample data (~117 records):

| Query Type | Without Index | With Index | Speedup |
|------------|---------------|------------|---------|
| Simple status filter | 0.5-1ms | 0.1-0.3ms | 2-3x |
| Customer name search | 1-2ms | 0.2-0.5ms | 3-5x |
| Foreign key join | 2-5ms | 0.5-1ms | 4-10x |
| Date range query | 2-4ms | 0.3-0.8ms | 5-10x |
| Complex dashboard query | 5-10ms | 1-2ms | 5-10x |

**Note:** Performance gains scale with data volume. With 10,000+ records, improvements can be 50-100x.

---

## Advanced Testing

### Create Test Data for Large-Scale Testing

```sql
-- Generate 10,000 test rentals
INSERT INTO rental (customer_id, vehicle_id, branch_id, start_date, end_date, start_mileage, daily_rate, status)
SELECT 
    (random() * 20 + 1)::int,  -- Random customer
    (random() * 50 + 1)::int,  -- Random vehicle
    (random() * 5 + 1)::int,   -- Random branch
    CURRENT_DATE - (random() * 365)::int,
    CURRENT_DATE - (random() * 365)::int + (random() * 30)::int,
    (random() * 50000)::int,
    50.0 + (random() * 200),
    (ARRAY['pending','active','completed','cancelled'])[floor(random() * 4 + 1)]
FROM generate_series(1, 10000);

-- Update statistics
ANALYZE;

-- Now test performance
\i database/test_optimization.sql
```

### Compare Query Plans

```sql
-- See detailed query plan
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS, TIMING)
SELECT ... your query ...;
```

---

## Summary Checklist

Before declaring optimization complete, verify:

- [ ] All 34 indexes created (check with quick_verify.sql)
- [ ] EXPLAIN shows "Index Scan" for key queries
- [ ] Dashboard queries execute in < 10ms
- [ ] JOIN operations use index lookups
- [ ] No unexpected "Seq Scan" on large tables
- [ ] Index usage counts (idx_scan) increasing with use
- [ ] Before/after comparison shows improvement

---

## Questions?

**Q: How often should I run these tests?**  
A: Run `quick_verify.sql` weekly, `analyze_indexes.sql` monthly, full suite before major releases.

**Q: Can I run tests on production?**  
A: Yes for all EXCEPT `benchmark_comparison.sql` (which drops/recreates indexes).

**Q: What if a query is still slow?**  
A: Run EXPLAIN ANALYZE on it, check the execution plan, and consult the troubleshooting section.

**Q: Do I need to maintain indexes?**  
A: PostgreSQL maintains them automatically. Just run `ANALYZE` after bulk data changes.

---

## Documentation Reference

- **INDEX_OPTIMIZATIONS.md** - Complete index documentation
- **INDEX_README.md** - Quick start guide
- **schema.sql** - Full schema with all indexes
- **add_indexes.sql** - Add indexes to existing DB

---

**Ready to Test?** Start with:
```bash
psql -U ceejayy -d vrdbms -f database/quick_verify.sql
```





