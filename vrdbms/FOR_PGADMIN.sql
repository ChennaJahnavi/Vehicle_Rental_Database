-- ============================================================================
-- FOR PGADMIN - INDEX PERFORMANCE DEMO
-- Copy each section separately and run in pgAdmin
-- ============================================================================

-- ============================================================================
-- STEP 1: Verify Database Size (Run this first)
-- ============================================================================

SELECT 'Total Rentals:' AS info, COUNT(*) AS value FROM rental;


-- ============================================================================
-- STEP 2: WITHOUT INDEX - Run this and NOTE THE EXECUTION TIME
-- ============================================================================

-- Drop the index
DROP INDEX IF EXISTS idx_rental_status;

-- Run query WITHOUT index
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    rental_id,
    customer_id,
    vehicle_id,
    rental_date,
    total_amount
FROM rental
WHERE status = 'completed'
ORDER BY rental_date DESC
LIMIT 50;

-- ⚠️ LOOK AT THE OUTPUT ABOVE:
--    • Find "Execution Time: X.XXX ms" ← Write this down!
--    • Look for "Seq Scan" or "Filter"
--    • Look at "Buffers: shared hit=XX" 


-- ============================================================================
-- STEP 3: WITH INDEX - Run this and COMPARE THE EXECUTION TIME
-- ============================================================================

-- Create the index
CREATE INDEX idx_rental_status ON rental(status);

-- Update statistics
ANALYZE rental;

-- Run the SAME query WITH index
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    rental_id,
    customer_id,
    vehicle_id,
    rental_date,
    total_amount
FROM rental
WHERE status = 'completed'
ORDER BY rental_date DESC
LIMIT 50;

-- ✅ LOOK AT THE OUTPUT ABOVE:
--    • Find "Execution Time: X.XXX ms" ← Should be LOWER!
--    • Look for "Index Scan" or "Bitmap Index Scan"
--    • Look at "Buffers: shared hit=XX" ← Should be fewer!


-- ============================================================================
-- IMPORTANT: How to Compare
-- ============================================================================

/*

TELL YOUR PROFESSOR:
═══════════════════════════════════════════════════════════════════════════

Look at these specific values in the EXPLAIN output:

1. SCAN METHOD:
   WITHOUT: "Seq Scan on rental" or "Filter: (status = 'completed')"
   WITH:    "Index Scan" or "Bitmap Index Scan on idx_rental_status"
   
2. EXECUTION TIME (at the bottom of EXPLAIN output):
   WITHOUT: Execution Time: 1.234 ms
   WITH:    Execution Time: 0.234 ms  ← Should be 3-5x lower!

3. BUFFERS (shared hit = pages read):
   WITHOUT: Buffers: shared hit=42
   WITH:    Buffers: shared hit=8     ← Should be 3-5x lower!

4. ROWS PROCESSED:
   WITHOUT: Scans all rows, then filters
   WITH:    Uses index to find only relevant rows

═══════════════════════════════════════════════════════════════════════════

KEY POINT: 
If execution time doesn't improve much, it means:
  - Table is small enough that Seq Scan is optimal
  - Both queries are already very fast (< 1ms)
  - This is actually PostgreSQL being SMART!
  
For production with 100,000+ rows, indexes provide 10-100x improvement!

*/





