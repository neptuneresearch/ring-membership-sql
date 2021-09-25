CREATE OR REPLACE VIEW txo_first_ring_distance AS
SELECT
    -- All columns
    txo_block_height,
    txo_tx_index,
    txo_txo_index,
    txo_block_timestamp,
    txo_tx_hash,
    txo_txo_amount,
    txo_amount_index,
    ring_block_height,
    ring_block_timestamp,
    ring_tx_hash,
    -- Computed columns
    ring_block_height - txo_block_height AS d_block_height,
    ring_block_timestamp - txo_block_timestamp AS d_block_timestamp
FROM txo_first_ring
ORDER BY
    txo_txo_amount ASC,
    txo_amount_index ASC;