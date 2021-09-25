SELECT
	COUNT(1)
FROM txo_first_ring
WHERE 
	ring_block_height >= 1978433 -- Block height for HF_VERSION_ENFORCE_MIN_AGE
	AND ring_block_height - txo_block_height < 10; -- CRYPTONOTE_DEFAULT_TX_SPENDABLE_AGE