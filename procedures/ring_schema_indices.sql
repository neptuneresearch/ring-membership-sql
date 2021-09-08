CREATE OR REPLACE PROCEDURE ring_schema_indices() LANGUAGE plpgsql AS $$ 
BEGIN
    /*
        Ring Membership SQL
        (c) 2020 Neptune Research
        SPDX-License-Identifier: BSD-3-Clause

        ring_schema_indices: Indices for ring membership schema
    */

    -- Drop indices
    --   tx_input_list
    DROP INDEX IF EXISTS tx_input_list_height_idx;
    DROP INDEX IF EXISTS tx_input_list_tx_hash_idx;
    DROP INDEX IF EXISTS tx_input_list_amount_index_idx;
    --   txo_amount_index
    DROP INDEX IF EXISTS txo_amount_index_idx;
    DROP INDEX IF EXISTS txo_amount_index_tx_hash_idx;
    DROP INDEX IF EXISTS txo_amount_index_txo_key_idx;
    --   tx_ringmember_list
    DROP INDEX IF EXISTS tx_ringmember_list_source_height_idx;
    DROP INDEX IF EXISTS tx_ringmember_list_ringmember_height_idx;
    DROP INDEX IF EXISTS tx_ringmember_list_source_tx_hash_idx;
    DROP INDEX IF EXISTS tx_ringmember_list_ringmember_txo_key_idx;
    DROP INDEX IF EXISTS tx_ringmember_list_ringmember_amount_index_idx;

    RAISE NOTICE 'Indices dropped';

    -- Create indices
    --   tx_input_list
    RAISE NOTICE 'Creating tx_input_list_height_idx';
    CREATE INDEX tx_input_list_height_idx ON tx_input_list (height);
    RAISE NOTICE 'Creating tx_input_list_tx_hash_idx';
    CREATE INDEX tx_input_list_tx_hash_idx ON tx_input_list (tx_hash);
    RAISE NOTICE 'Creating tx_input_list_amount_index_idx';
    CREATE INDEX tx_input_list_amount_index_idx ON tx_input_list (amount_index);
    --   txo_amount_index
    RAISE NOTICE 'Creating txo_amount_index_idx';
    CREATE INDEX txo_amount_index_idx ON txo_amount_index (amount_index);
    RAISE NOTICE 'Creating txo_amount_index_tx_hash_idx';
    CREATE INDEX txo_amount_index_tx_hash_idx ON txo_amount_index (tx_hash);
    RAISE NOTICE 'Creating txo_amount_index_txo_key_idx';
    CREATE INDEX txo_amount_index_txo_key_idx ON txo_amount_index (txo_key);
    --   tx_ringmember_list
    RAISE NOTICE 'Creating tx_ringmember_list_source_height_idx';
    CREATE INDEX tx_ringmember_list_source_height_idx ON tx_ringmember_list (source_height);
    RAISE NOTICE 'Creating tx_ringmember_list_ringmember_height_idx';
    CREATE INDEX tx_ringmember_list_ringmember_height_idx ON tx_ringmember_list (ringmember_height);
    RAISE NOTICE 'Creating tx_ringmember_list_source_tx_hash_idx';
    CREATE INDEX tx_ringmember_list_source_tx_hash_idx ON tx_ringmember_list (source_tx_hash);
    RAISE NOTICE 'Creating tx_ringmember_list_ringmember_txo_key_idx';
    CREATE INDEX tx_ringmember_list_ringmember_txo_key_idx ON tx_ringmember_list (ringmember_txo_key);
    RAISE NOTICE 'Creating tx_ringmember_list_ringmember_amount_index_idx';
    CREATE INDEX tx_ringmember_list_ringmember_amount_index_idx ON tx_ringmember_list (ringmember_amount_index);

    RAISE NOTICE 'Indices created';
END;
$$;
