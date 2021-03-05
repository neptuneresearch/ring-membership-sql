DROP MATERIALIZED VIEW IF EXISTS txo_first_ring;

CREATE MATERIALIZED VIEW txo_first_ring AS (
    /*
        Ring Membership SQL
        (c) 2021 Neptune Research
        SPDX-License-Identifier: BSD-3-Clause

        txo_first_ring: For each transaction output, find the first transaction which uses it as a ring member.
    */

    SELECT
        TXO.height              AS txo_height,
        TXO.tx_index            AS txo_tx_index,
        TXO.txo_index           AS txo_txo_index,
        TXO.block_timestamp     AS txo_block_timestamp,
        TXO.tx_hash             AS txo_tx_hash,
        TXO.txo_amount          AS txo_txo_amount,
        TXO.amount_index        AS txo_amount_index,
        RING.height             AS ring_height,
        RING.block_timestamp    AS ring_block_timestamp,
        RING.tx_hash            AS ring_tx_hash
    FROM txo_amount_index TXO
    JOIN (
        SELECT
        	vin_amount,
        	amount_index,
            ROW_NUMBER() OVER (
                PARTITION BY 
                    _RING.vin_amount, 
                    _RING.amount_index 
                ORDER BY 
                    _RING.height ASC,
                    _RING.tx_index ASC,
                    _RING.vin_index ASC,
                    _RING.vin_key_offset_index ASC
            ) AS ring_index,
            height,
            block_timestamp,
            tx_hash
        FROM tx_input_list _RING
    ) AS RING 
        ON RING.vin_amount = TXO.txo_amount
        AND RING.amount_index = TXO.amount_index
        AND RING.ring_index = 1
    ORDER BY 
        TXO.height ASC,
        TXO.tx_index ASC,
        TXO.txo_index ASC
) WITH NO DATA;