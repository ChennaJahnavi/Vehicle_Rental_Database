-- ============================================================================
-- INDEX PERFORMANCE DEMO FOR PGADMIN
-- Copy and paste each section into pgAdmin and run
-- ============================================================================


-- ============================================================================
-- STEP 1: Check Database Size
-- ============================================================================

SELECT 'Total Rentals' AS table_name, COUNT(*) AS records FROM rental
UNION ALL
SELECT 'Total Vehicles', COUNT(*) FROM vehicle
UNION ALL
SELECT 'Total Customers', COUNT(*) FROM customer;


-- ============================================================================
-- STEP 2: WITHOUT INDEX (Baseline - SLOWER)
-- ============================================================================

-- Remove index to show baseline performance
DROP INDEX IF EXISTS idx_rental_customer;

-- Query WITHOUT index
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    r.rental_id,
    r.customer_id,
    r.vehicle_id,
    r.rental_date,
    r.total_amount,
    r.status
FROM rental r
WHERE r.customer_id IN (10, 20, 30, 40, 50, 60, 70, 80, 90, 100)
ORDER BY r.rental_date DESC;

-- Run 3 times to measure timing
SELECT COUNT(*) FROM rental WHERE customer_id IN (10, 20, 30, 40, 50);
SELECT COUNT(*) FROM rental WHERE customer_id IN (10, 20, 30, 40, 50);
SELECT COUNT(*) FROM rental WHERE customer_id IN (10, 20, 30, 40, 50);


-- ============================================================================
-- STEP 3: WITH INDEX (Optimized - FASTER)
-- ============================================================================

-- Create the index
CREATE INDEX idx_rental_customer ON rental(customer_id);

-- Update statistics
ANALYZE rental;

-- Same query WITH index
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT 
    r.rental_id,
    r.customer_id,
    r.vehicle_id,
    r.rental_date,
    r.total_amount,
    r.status
FROM rental r
WHERE r.customer_id IN (10, 20, 30, 40, 50, 60, 70, 80, 90, 100)
ORDER BY r.rental_date DESC;

-- Run 3 times to measure timing
SELECT COUNT(*) FROM rental WHERE customer_id IN (10, 20, 30, 40, 50);
SELECT COUNT(*) FROM rental WHERE customer_id IN (10, 20, 30, 40, 50);
SELECT COUNT(*) FROM rental WHERE customer_id IN (10, 20, 30, 40, 50);


-- ============================================================================
-- COMPARISON GUIDE
-- ============================================================================

/*
WHAT TO SHOW YOUR PROFESSOR:
═════════════════════════════════════════════════════════════════════════

Compare the two EXPLAIN ANALYZE outputs above:

WITHOUT INDEX (Step 2):
───────────────────────────────────────────────────────────────────────
• Seq Scan on rental
• Execution Time: ~2-5 ms
• Rows Removed by Filter: ~2900+
• Buffers: shared hit=40-50

WITH INDEX (Step 3):
───────────────────────────────────────────────────────────────────────
• Bitmap Index Scan on idx_rental_customer
• Execution Time: ~0.3-1 ms  ← 3-10x FASTER!
• No rows removed (index finds exact matches)
• Buffers: shared hit=8-15  ← 3-5x FEWER page reads!

KEY METRICS:
  ✓ Execution Time: 3-10x improvement
  ✓ Scan Method: Seq Scan → Index Scan
  ✓ Buffer Reads: 3-5x reduction
  ✓ Efficiency: Reads only relevant rows

═════════════════════════════════════════════════════════════════════════
*/





