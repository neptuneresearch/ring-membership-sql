DROP MATERIALIZED VIEW IF EXISTS tx_ringmember_list;

CREATE MATERIALIZED VIEW tx_ringmember_list AS (
    /*
        Ring Membership SQL
        (c) 2020 Neptune Research
        SPDX-License-Identifier: BSD-3-Clause

        tx_ringmember_list: Linking key offsets (tx_input_list) to the output amount index (txo_amount_index), list the ring members for each transaction input.
    */

	SELECT
		TXI.height 						AS source_height,
		TXI.block_timestamp 			AS source_block_timestamp,
		TXI.tx_hash 					AS source_tx_hash,
		TXI.tx_index 					AS source_tx_index,
		TXI.vin_index 					AS source_vin_index,
		TXI.vin_k_image 				AS source_k_image,
		TXI.vin_key_offset_index 		AS ringmember_index,
		RING.amount_index 				AS ringmember_amount_index,
		RING.txo_key 					AS ringmember_txo_key,
		RING.height 					AS ringmember_height,
		RING.block_timestamp 			AS ringmember_block_timestamp
	FROM tx_input_list TXI
	JOIN txo_amount_index RING ON RING.amount_index = TXI.amount_index
	ORDER BY TXI.height ASC, TXI.tx_index ASC, TXI.vin_index ASC, TXI.vin_key_offset_index ASC
) WITH NO DATA;