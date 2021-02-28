DROP MATERIALIZED VIEW IF EXISTS ringmember_tx_list;

CREATE MATERIALIZED VIEW ringmember_tx_list AS (
    /*
        Ring Membership SQL
        (c) 2021 Neptune Research
        SPDX-License-Identifier: BSD-3-Clause

        ringmember_tx_list: Linking the output amount index (txo_amount_index) to key offsets (tx_input_list), list the transactions which use each output as a ring member.
    */

	SELECT
		TXO.amount_index 				AS ringmember_amount_index,
		TXO.txo_key 					AS ringmember_txo_key,
		TXO.height 						AS ringmember_height,
		TXO.block_timestamp 			AS ringmember_block_timestamp,
		RING.height 					AS source_height,
		RING.block_timestamp 			AS source_block_timestamp,
		RING.tx_hash 					AS source_tx_hash,
		RING.tx_index 					AS source_tx_index,
		RING.vin_index 					AS source_vin_index,
		RING.vin_k_image 				AS source_k_image,
		RING.vin_key_offset_index 		AS ringmember_index
	FROM txo_amount_index TXO
	-- LEFT JOIN: a transaction output may not have ever been used as a ring member.
	LEFT JOIN tx_input_list RING 
		ON RING.txo_amount = TXO.vin_amount 
		AND RING.amount_index = TXO.amount_index
	-- Only return transaction outputs that have been used.
	WHERE RING.height IS NOT NULL
	ORDER BY 
		TXO.amount_index ASC,
		RING.height ASC,
		RING.tx_index ASC,
		RING.vin_index ASC,
		RING.vin_key_offset_index ASC
) WITH NO DATA;