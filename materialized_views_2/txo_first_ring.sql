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
        TXO.tx_hash             AS txo_tx_hash,
        TXO.amount_index        AS txo_amount_index,
        RING.height             AS ring_height,
        RING.block_timestamp    AS ring_block_timestamp,
        RING.tx_hash            AS ring_tx_hash
    FROM txo_amount_index TXO
    LEFT JOIN LATERAL (
        SELECT
            height,
            block_timestamp,
            tx_hash
        FROM tx_input_list _RING
        WHERE 
            _RING.vin_amount = TXO.txo_amount
            AND _RING.amount_index = TXO.amount_index
        ORDER BY 
            _RING.height ASC,
            _RING.tx_index ASC,
            _RING.vin_index ASC,
            _RING.vin_key_offset_index ASC
        FETCH FIRST 1 ROW ONLY
    ) RING ON TRUE
    ORDER BY amount_index ASC
) WITH NO DATA;