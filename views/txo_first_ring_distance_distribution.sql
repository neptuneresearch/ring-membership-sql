CREATE OR REPLACE VIEW txo_first_ring_distance_distribution AS
SELECT
    ring_block_height - txo_block_height AS d_block_height,
    COUNT(1) AS n
FROM txo_first_ring
GROUP BY ring_block_height - txo_block_height
ORDER BY n DESC;