DROP MATERIALIZED VIEW IF EXISTS ringmember_tx_list;

CREATE MATERIALIZED VIEW ringmember_tx_list AS (
    /*
        Ring Membership SQL
        (c) 2021 Neptune Research
        SPDX-License-Identifier: BSD-3-Clause

        ringmember_tx_list: Linking the output amount index (txo_amount_index) to key offsets (tx_input_list), list the transactions which use each output as a ring member.
    */

	SELECT
		-- txo_amount_index
		TXO.height 					AS output_height,
		TXO.block_timestamp 		AS output_block_timestamp,
		TXO.tx_index				AS output_tx_index,
		TXO.tx_hash					AS output_tx_hash,
		TXO.txo_index				AS output_txo_index,
		--   Optional: output key
		--TXO.txo_key				AS output_txo_key,

		-- [RingCT Only]: Omit this column since it will always be zero in value.
		-- [Pre-RingCT]: Include this column.
        TXO.txo_amount              AS output_amount,

		TXO.amount_index			AS output_amount_index,

		-- tx_input_list
		RING.vin_key_offset_index	AS ringmember_index,
        RING.height 				AS ring_height,
		RING.block_timestamp 		AS ring_block_timestamp,
		RING.tx_index				AS ring_tx_index,
		RING.tx_hash 				AS ring_tx_hash,
		RING.vin_index 				AS ring_vin_index
		--   Optional: key image
		--RING.vin_k_image			AS ring_vin_k_image
	FROM txo_amount_index TXO
	-- JOIN: transaction outputs that have not ever been used as a ring member will not be included.
	JOIN tx_input_list RING
		-- [RingCT Only]: Omit this JOIN condition for vin_amount.
		-- [Pre-RingCT]: Include this JOIN condition for vin_amount.
		ON RING.vin_amount = TXO.txo_amount
		-- [Pre-RingCT and RingCT Only]: Always include JOIN condition for amount_index.
		AND RING.amount_index = TXO.amount_index
	ORDER BY 
		TXO.amount_index ASC,
		RING.height ASC,
		RING.tx_index ASC,
		RING.vin_index ASC,
		RING.vin_key_offset_index ASC
) WITH NO DATA;