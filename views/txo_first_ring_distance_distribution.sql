CREATE OR REPLACE VIEW txo_first_ring_distance_distribution AS
SELECT
    ring_height - txo_height AS d_height,
    COUNT(1) AS n
FROM txo_first_ring
GROUP BY ring_height - txo_height
ORDER BY n DESC;