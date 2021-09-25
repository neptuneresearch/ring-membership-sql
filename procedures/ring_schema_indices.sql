CREATE OR REPLACE PROCEDURE ring_schema_indices(
    index_level INTEGER DEFAULT NULL,
    create_enabled BOOLEAN DEFAULT TRUE
) LANGUAGE plpgsql AS $$ 
BEGIN
    /*
        Ring Membership SQL
        (c) 2020-2021 Neptune Research
        SPDX-License-Identifier: BSD-3-Clause

        ring_schema_indices: Indices for ring membership materialized views.
    */

    -- tx_input_list
    IF index_level IS NULL OR index_level = 1 THEN
        RAISE NOTICE 'ring_schema_indices [%]: Dropping tx_input_list_block_height_idx', timeofday()::timestamp;
        DROP INDEX IF EXISTS tx_input_list_block_height_idx;

        IF create_enabled THEN
            RAISE NOTICE 'ring_schema_indices [%]: Creating tx_input_list_block_height_idx', timeofday()::timestamp;
            CREATE INDEX tx_input_list_block_height_idx ON tx_input_list (block_height);
        END IF;
    END IF;

    IF index_level IS NULL OR index_level = 3 THEN
        RAISE NOTICE 'ring_schema_indices [%]: Dropping tx_input_list_tx_hash_idx', timeofday()::timestamp;
        DROP INDEX IF EXISTS tx_input_list_tx_hash_idx;

        IF create_enabled THEN
            RAISE NOTICE 'ring_schema_indices [%]: Creating tx_input_list_tx_hash_idx', timeofday()::timestamp;
            CREATE INDEX tx_input_list_tx_hash_idx ON tx_input_list (tx_hash);
        END IF;
    END IF;
    
    IF index_level IS NULL OR index_level = 2 THEN
        -- [Pre-RingCT]: Index on pair { vin_amount, amount_index }.
        RAISE NOTICE 'ring_schema_indices [%]: Dropping tx_input_list_vin_amount_amount_index_idx', timeofday()::timestamp;
        DROP INDEX IF EXISTS tx_input_list_vin_amount_amount_index_idx;

        IF create_enabled THEN
            RAISE NOTICE 'ring_schema_indices [%]: Creating tx_input_list_vin_amount_amount_index_idx', timeofday()::timestamp;
            CREATE INDEX tx_input_list_vin_amount_amount_index_idx ON tx_input_list (vin_amount, amount_index);
        END IF;

        -- [RingCT Only]: Omit vin_amount because vin_amount = 0 always.
        /*
        RAISE NOTICE 'ring_schema_indices [%]: Dropping tx_input_list_amount_index_idx', timeofday()::timestamp;
        DROP INDEX IF EXISTS tx_input_list_amount_index_idx;

        IF create_enabled THEN
            RAISE NOTICE 'ring_schema_indices [%]: Creating tx_input_list_amount_index_idx', timeofday()::timestamp;
            CREATE INDEX tx_input_list_amount_index_idx ON tx_input_list (amount_index);
        END IF;
        */
    END IF;

    -- txo_amount_index
    IF index_level IS NULL OR index_level = 1 THEN
        RAISE NOTICE 'ring_schema_indices [%]: Dropping txo_amount_index_block_height_idx', timeofday()::timestamp;
        DROP INDEX IF EXISTS txo_amount_index_block_height_idx;

        IF create_enabled THEN
            RAISE NOTICE 'ring_schema_indices [%]: Creating txo_amount_index_block_height_idx', timeofday()::timestamp;
            CREATE INDEX txo_amount_index_block_height_idx ON txo_amount_index (block_height);
        END IF;
    END IF;

    IF index_level IS NULL OR index_level = 3 THEN
        RAISE NOTICE 'ring_schema_indices [%]: Dropping txo_amount_index_tx_hash_idx', timeofday()::timestamp;
        DROP INDEX IF EXISTS txo_amount_index_tx_hash_idx;

        IF create_enabled THEN
            RAISE NOTICE 'ring_schema_indices [%]: Creating txo_amount_index_tx_hash_idx', timeofday()::timestamp;
            CREATE INDEX txo_amount_index_tx_hash_idx ON txo_amount_index (tx_hash);
        END IF;
    END IF;
    
    IF index_level IS NULL OR index_level = 2 THEN
        -- [Pre-RingCT]: Index on pair { txo_amount, amount_index }.
        RAISE NOTICE 'ring_schema_indices [%]: Dropping txo_amount_index_txo_amount_amount_index_idx', timeofday()::timestamp;
        DROP INDEX IF EXISTS txo_amount_index_txo_amount_amount_index_idx;

        IF create_enabled THEN
            RAISE NOTICE 'ring_schema_indices [%]: Creating txo_amount_index_txo_amount_amount_index_idx', timeofday()::timestamp;
            CREATE INDEX txo_amount_index_txo_amount_amount_index_idx ON txo_amount_index (txo_amount, amount_index);
        END IF;

        -- [RingCT Only]: Omit txo_amount because txo_amount = 0 always.
        /*
        RAISE NOTICE 'ring_schema_indices [%]: Dropping txo_amount_index_amount_index_idx', timeofday()::timestamp;
        DROP INDEX IF EXISTS txo_amount_index_amount_index_idx;

        IF create_enabled THEN
            RAISE NOTICE 'ring_schema_indices [%]: Creating txo_amount_index_amount_index_idx', timeofday()::timestamp;
            CREATE INDEX txo_amount_index_amount_index_idx ON txo_amount_index (amount_index);
        END IF;
        */
    END IF;

    -- tx_ringmember_list
    IF index_level IS NULL OR index_level = 1 THEN
        RAISE NOTICE 'ring_schema_indices [%]: Dropping tx_ringmember_list_source_block_height_idx', timeofday()::timestamp;
        DROP INDEX IF EXISTS tx_ringmember_list_source_block_height_idx;

        IF create_enabled THEN
            RAISE NOTICE 'ring_schema_indices [%]: Creating tx_ringmember_list_source_block_height_idx', timeofday()::timestamp;
            CREATE INDEX tx_ringmember_list_source_block_height_idx ON tx_ringmember_list (source_block_height);
        END IF;
    END IF;

    IF index_level IS NULL OR index_level = 1 THEN
        RAISE NOTICE 'ring_schema_indices [%]: Dropping tx_ringmember_list_ringmember_block_height_idx', timeofday()::timestamp;
        DROP INDEX IF EXISTS tx_ringmember_list_ringmember_block_height_idx;

        IF create_enabled THEN
            RAISE NOTICE 'ring_schema_indices [%]: Creating tx_ringmember_list_ringmember_block_height_idx', timeofday()::timestamp;
            CREATE INDEX tx_ringmember_list_ringmember_block_height_idx ON tx_ringmember_list (ringmember_block_height);
        END IF;
    END IF;

    IF index_level IS NULL OR index_level = 2 THEN
        -- [Pre-RingCT]: Index on pair { source_vin_amount, ringmember_amount_index }.
        RAISE NOTICE 'ring_schema_indices [%]: Dropping tx_ringmember_list_source_vin_amt_ringmember_amt_index_idx', timeofday()::timestamp;
        DROP INDEX IF EXISTS tx_ringmember_list_source_vin_amt_ringmember_amt_index_idx;

        IF create_enabled THEN
            RAISE NOTICE 'ring_schema_indices [%]: Creating tx_ringmember_list_source_vin_amt_ringmember_amt_index_idx', timeofday()::timestamp;
            CREATE INDEX tx_ringmember_list_source_vin_amt_ringmember_amt_index_idx ON tx_ringmember_list (source_vin_amount, ringmember_amount_index);
        END IF;

        -- [RingCT Only]: Omit source_vin_amount because source_vin_amount = 0 always.
        /*
        RAISE NOTICE 'ring_schema_indices [%]: Dropping tx_ringmember_list_ringmember_amount_index_idx', timeofday()::timestamp;
        DROP INDEX IF EXISTS tx_ringmember_list_ringmember_amount_index_idx;

        IF create_enabled THEN
            RAISE NOTICE 'ring_schema_indices [%]: Creating tx_ringmember_list_ringmember_amount_index_idx', timeofday()::timestamp;
            CREATE INDEX tx_ringmember_list_ringmember_amount_index_idx ON tx_ringmember_list (ringmember_amount_index);
        END IF;
        */
    END IF;

    IF index_level IS NULL OR index_level = 3 THEN
        RAISE NOTICE 'ring_schema_indices [%]: Dropping tx_ringmember_list_source_tx_hash_idx', timeofday()::timestamp;
        DROP INDEX IF EXISTS tx_ringmember_list_source_tx_hash_idx;

        IF create_enabled THEN
            RAISE NOTICE 'ring_schema_indices [%]: Creating tx_ringmember_list_source_tx_hash_idx', timeofday()::timestamp;
            CREATE INDEX tx_ringmember_list_source_tx_hash_idx ON tx_ringmember_list (source_tx_hash);
        END IF;
    END IF;

    IF index_level IS NULL OR index_level = 3 THEN
        RAISE NOTICE 'ring_schema_indices [%]: Dropping tx_ringmember_list_ringmember_tx_hash_idx', timeofday()::timestamp;
        DROP INDEX IF EXISTS tx_ringmember_list_ringmember_tx_hash_idx;

        IF create_enabled THEN
            RAISE NOTICE 'ring_schema_indices [%]: Creating tx_ringmember_list_ringmember_tx_hash_idx', timeofday()::timestamp;
            CREATE INDEX tx_ringmember_list_ringmember_tx_hash_idx ON tx_ringmember_list (ringmember_tx_hash);
        END IF;
    END IF;        

    RAISE NOTICE 'ring_schema_indices [%]: OK', timeofday()::timestamp;
END;
$$;