DROP MATERIALIZED VIEW IF EXISTS tx_input_list;

CREATE MATERIALIZED VIEW tx_input_list AS (
	/*
		Ring Membership SQL
		(c) 2020 Neptune Research
		SPDX-License-Identifier: BSD-3-Clause

		tx_input_list: List absolute key offsets per transaction input per transaction per block.
	*/

	SELECT
		-- Transactions
        block.height                            AS height,
        block.timestamp                         AS block_timestamp,
        tx.ordinality                           AS tx_index,
        tx.hash                                 AS tx_hash,
        -- Transaction Inputs
        vin.ordinality                          AS vin_index,
        vin.k_image                             AS vin_k_image,
        vin.amount                              AS vin_amount,
        -- Key Offsets
        vin_key_offsets.vin_key_offset_index    AS vin_key_offset_index,
        vin_key_offsets.vin_key_offset          AS vin_key_offset,
        SUM(vin_key_offsets.vin_key_offset) OVER (PARTITION BY block.height, tx.ordinality, vin.ordinality ORDER BY vin_key_offset_index ASC) AS amount_index
	FROM monero AS block,
	LATERAL UNNEST(block.transactions) WITH ORDINALITY tx(hash, version, unlock_time, vin, vout, extra, fee),
	LATERAL UNNEST(tx.vin) WITH ORDINALITY vin(amount),
	LATERAL UNNEST(vin.key_offsets) WITH ORDINALITY vin_key_offsets(vin_key_offset, vin_key_offset_index)

	-- [RingCT Only]: Include this WHERE.
	-- [Pre-RingCT]: Omit this WHERE.
	--WHERE block.height >= 1220516 AND tx.version = 2 AND vin.amount = 0

	ORDER BY block.height ASC, tx.ordinality ASC, vin.ordinality ASC, vin_key_offsets.vin_key_offset_index ASC
) WITH NO DATA;