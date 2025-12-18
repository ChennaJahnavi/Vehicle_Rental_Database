-- ============================================================================
-- QUICK DEMO FOR PGADMIN - Just Copy & Run Each Block
-- ============================================================================

-- Block 1: Check database size
SELECT COUNT(*) AS total_rentals FROM rental;


-- Block 2: WITHOUT INDEX (Run this, note execution time)
DROP INDEX IF EXISTS idx_rental_customer;

EXPLAIN ANALYZE
SELECT * FROM rental WHERE customer_id = 50;


-- Block 3: WITH INDEX (Run this, compare execution time)
CREATE INDEX idx_rental_customer ON rental(customer_id);
ANALYZE rental;

EXPLAIN ANALYZE
SELECT * FROM rental WHERE customer_id = 50;


-- ============================================================================
-- WHAT TO COMPARE:
-- Look at "Execution Time" at the bottom of each EXPLAIN output
-- WITHOUT index: Higher time (e.g., 1-3 ms)
-- WITH index: Lower time (e.g., 0.1-0.5 ms) ← 5-10x faster!
-- ============================================================================





