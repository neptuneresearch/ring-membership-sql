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
        TXO.block_height            AS txo_block_height,
        TXO.block_timestamp         AS txo_block_timestamp,
        TXO.tx_index                AS txo_block_tx_index,
        TXO.tx_hash                 AS txo_tx_hash,
        TXO.txo_index               AS txo_tx_txo_index,
        --   Optional: output key
        --TXO.txo_key                 AS txo_key,

        -- [RingCT Only]: Omit this column since it will always be zero in value.
        -- [Pre-RingCT]: Include this column.
        TXO.txo_amount              AS txo_amount,

        TXO.amount_index            AS txo_amount_index,

        -- tx_input_list
        RING.block_height           AS ringtx_block_height,
        RING.block_timestamp        AS ringtx_block_timestamp,
        RING.tx_index               AS ringtx_block_tx_index,
        RING.tx_hash                AS ringtx_tx_hash,
        RING.vin_index              AS ringtx_vin_index,
        RING.vin_key_offset_index   AS ringtx_vin_ringmember_index
        --   Optional: key image
        --RING.vin_k_image            AS ringtx_vin_k_image
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
        RING.block_height ASC,
        RING.tx_index ASC,
        RING.vin_index ASC,
        RING.vin_key_offset_index ASC
) WITH NO DATA;