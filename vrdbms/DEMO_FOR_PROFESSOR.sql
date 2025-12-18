-- ============================================================================
-- DEMONSTRATION FOR PROFESSOR: Index Performance Comparison
-- Copy and paste each section into pgAdmin to show performance difference
-- ============================================================================
-- Instructions:
--   1. Copy STEP 1 → Paste in pgAdmin → Execute
--   2. Copy STEP 2 → Paste in pgAdmin → Execute  
--   3. Copy STEP 3 → Paste in pgAdmin → Execute
--   4. Compare the results!
-- ============================================================================


-- ============================================================================
-- STEP 1: Show Current Database Size
-- ============================================================================

SELECT 
    'Vehicles' AS table_name, 
    COUNT(*) AS records 
FROM vehicle
UNION ALL
SELECT 'Customers', COUNT(*) FROM customer
UNION ALL
SELECT 'Rentals', COUNT(*) FROM rental
UNION ALL
SELECT 'Payments', COUNT(*) FROM payment
ORDER BY table_name;


-- ============================================================================
-- STEP 2: WITHOUT INDEXES (Slow Performance)
-- ============================================================================

-- Drop the index first
DROP INDEX IF EXISTS idx_rental_customer;

-- Show the query plan and timing
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    c.first_name || ' ' || c.last_name AS customer_name,
    COUNT(r.rental_id) AS total_rentals,
    SUM(r.total_amount) AS total_spent,
    AVG(r.total_amount) AS avg_rental
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
WHERE r.customer_id BETWEEN 1 AND 100
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 20;

-- ⚠️ LOOK FOR:
--   • "Seq Scan on rental" ← BAD (scans all 3000+ rows)
--   • Higher "Execution Time" ← SLOW
--   • More "Buffers" ← More disk reads


-- ============================================================================
-- STEP 3: WITH INDEX (Fast Performance)
-- ============================================================================

-- Create the index
CREATE INDEX idx_rental_customer ON rental(customer_id);

-- Update statistics
ANALYZE rental;

-- Run the SAME query again
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    c.first_name || ' ' || c.last_name AS customer_name,
    COUNT(r.rental_id) AS total_rentals,
    SUM(r.total_amount) AS total_spent,
    AVG(r.total_amount) AS avg_rental
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
WHERE r.customer_id BETWEEN 1 AND 100
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 20;

-- ✅ LOOK FOR:
--   • "Index Scan" or "Bitmap Index Scan" ← GOOD (uses index)
--   • Lower "Execution Time" ← FAST (5-10x improvement)
--   • Fewer "Buffers" ← Less disk reads


-- ============================================================================
-- COMPARISON RESULTS
-- ============================================================================

/*
EXPECTED RESULTS TO SHOW YOUR PROFESSOR:

═══════════════════════════════════════════════════════════════════════════
WITHOUT INDEX:
───────────────────────────────────────────────────────────────────────────
→ Seq Scan on rental  (cost=0.00..79.69)
→ Execution Time: 3-5 ms
→ Buffers: shared hit=42
→ Scanned: 3015 rows to find 100 matches

═══════════════════════════════════════════════════════════════════════════
WITH INDEX:
───────────────────────────────────────────────────────────────────────────
→ Bitmap Index Scan on idx_rental_customer  (cost=4.34..25.97)
→ Execution Time: 0.5-1 ms  ← 5-10x FASTER!
→ Buffers: shared hit=8     ← 5x FEWER reads!
→ Scanned: Only 100 relevant rows using index

═══════════════════════════════════════════════════════════════════════════
IMPROVEMENT: 5-10x faster with indexes!
═══════════════════════════════════════════════════════════════════════════
*/





