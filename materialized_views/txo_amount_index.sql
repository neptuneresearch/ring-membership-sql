DROP MATERIALIZED VIEW IF EXISTS txo_amount_index;

CREATE MATERIALIZED VIEW txo_amount_index AS (
    /*
        Ring Membership SQL
        (c) 2020-2021 Neptune Research
        SPDX-License-Identifier: BSD-3-Clause

        txo_amount_index: Global output amount index (txo_amount_index).
    */

    WITH miner_txs AS (
        SELECT
            block.height                    AS height,
            block.timestamp                 AS block_timestamp,
            -1                              AS tx_index,
            (miner_tx).hash                 AS tx_hash,
            vout.ordinality                 AS txo_index,
            vout.key                        AS txo_key,

            -- [RingCT Only]: Use this txo_amount.
            --0                               AS txo_amount

            -- [Pre-RingCT]: Use this txo_amount.
            /*
                RingCT coinbase tx are indexed under amount 0 although they have amounts.
                See Monero Core blockchain_db/blockchain_db.cpp: BlockchainDB::add_transaction
            */
            CASE WHEN (miner_tx).version = 2 THEN 0 ELSE vout.amount END AS txo_amount

        FROM monero block,
        LATERAL UNNEST((miner_tx).vout) WITH ORDINALITY vout

        -- [RingCT Only]: Include this WHERE.
        -- [Pre-RingCT]: Omit this WHERE.
        --WHERE block.height >= 1220516 AND (miner_tx).version = 2
    ),
    tx_outputs AS (
        SELECT
            block.height                    AS height,
            block.timestamp                 AS block_timestamp,
            tx.ordinality                   AS tx_index,
            tx.hash                         AS tx_hash,
            vout.ordinality                 AS txo_index,
            vout.key                        AS txo_key,

            -- [RingCT Only]: Use this txo_amount.
            --0                               AS txo_amount

            -- [Pre-RingCT]: Use this txo_amount.
            vout.amount                     AS txo_amount

        FROM monero block,
        LATERAL UNNEST(block.transactions) WITH ORDINALITY tx,
        LATERAL UNNEST(tx.vout) WITH ORDINALITY vout

        -- [RingCT Only]: Include this WHERE.
        -- [Pre-RingCT]: Omit this WHERE.
        --WHERE block.height >= 1220516 AND tx.version = 2
    ),
    combine_miner_txs_with_tx_outputs AS (
        SELECT
            *
        FROM miner_txs

        UNION

        SELECT
            *
        FROM tx_outputs
    )
    SELECT 
        height,
        block_timestamp,
        tx_index,
        tx_hash,
        txo_index,
        txo_key,
        txo_amount,
        -- ROW_NUMBER starts at 1; add -1 so Amount Index starts at 0.
        ROW_NUMBER() OVER (PARTITION BY txo_amount ORDER BY height ASC, tx_index ASC, txo_index ASC) - 1 AS amount_index
    FROM combine_miner_txs_with_tx_outputs
    ORDER BY
        height ASC,
        tx_index ASC,
        txo_index ASC
) WITH NO DATA;