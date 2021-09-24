DROP MATERIALIZED VIEW IF EXISTS tx_ringmember_list;

CREATE MATERIALIZED VIEW tx_ringmember_list AS (
    /*
        Ring Membership SQL
        (c) 2020-2021 Neptune Research
        SPDX-License-Identifier: BSD-3-Clause

        tx_ringmember_list: Linking key offsets (tx_input_list) to the output amount index (txo_amount_index), list the ring members for each transaction input.
    */

    SELECT
        -- tx_input_list
        TXI.height                  AS source_height,
        TXI.block_timestamp         AS source_block_timestamp,
        TXI.tx_index                AS source_tx_index,
        TXI.tx_hash                 AS source_tx_hash,
        TXI.vin_index               AS source_vin_index,
        --   Optional: key image
        --TXI.vin_k_image             AS source_vin_k_image,

        -- [RingCT Only]: Omit this column since it will always be zero in value.
        -- [Pre-RingCT]: Include this column.
        TXI.vin_amount              AS source_vin_amount,
        
        TXI.vin_key_offset_index    AS ringmember_index,
        TXI.amount_index            AS ringmember_amount_index,

        -- txo_amount_index
        RING.height                 AS ringmember_height,
        RING.block_timestamp        AS ringmember_block_timestamp,
        RING.tx_index               AS ringmember_tx_index,
        RING.tx_hash                AS ringmember_tx_hash,
        RING.txo_index              AS ringmember_txo_index
        --   Optional: output key
        --RING.txo_key                AS ringmember_txo_key
    FROM tx_input_list TXI
    JOIN txo_amount_index RING 
        -- [RingCT Only]: Omit this JOIN condition for vin_amount.
        -- [Pre-RingCT]: Include this JOIN condition for vin_amount.
        ON RING.txo_amount = TXI.vin_amount 
        -- [Pre-RingCT and RingCT Only]: Always include JOIN condition for amount_index.
        AND RING.amount_index = TXI.amount_index
    ORDER BY 
        TXI.height ASC, 
        TXI.tx_index ASC, 
        TXI.vin_index ASC, 
        TXI.vin_key_offset_index ASC
) WITH NO DATA;