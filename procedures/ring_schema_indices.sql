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
        RAISE NOTICE 'Dropping tx_input_list_height_idx';
        DROP INDEX IF EXISTS tx_input_list_height_idx;

        IF create_enabled THEN
            RAISE NOTICE 'Creating tx_input_list_height_idx';
            CREATE INDEX tx_input_list_height_idx ON tx_input_list (height);
        END IF;
    END IF;

    IF index_level IS NULL OR index_level = 3 THEN
        RAISE NOTICE 'Dropping tx_input_list_tx_hash_idx';
        DROP INDEX IF EXISTS tx_input_list_tx_hash_idx;

        IF create_enabled THEN
            RAISE NOTICE 'Creating tx_input_list_tx_hash_idx';
            CREATE INDEX tx_input_list_tx_hash_idx ON tx_input_list (tx_hash);
        END IF;
    END IF;
    
    IF index_level IS NULL OR index_level = 2 THEN
        -- [Pre-RingCT]: Index on pair { vin_amount, amount_index }.
        RAISE NOTICE 'Dropping tx_input_list_vin_amount_amount_index_idx';
        DROP INDEX IF EXISTS tx_input_list_vin_amount_amount_index_idx;

        IF create_enabled THEN
            RAISE NOTICE 'Creating tx_input_list_vin_amount_amount_index_idx';
            CREATE INDEX tx_input_list_vin_amount_amount_index_idx ON tx_input_list (vin_amount, amount_index);
        END IF;

        -- [RingCT Only]: Omit vin_amount because vin_amount = 0 always.
        /*
        RAISE NOTICE 'Dropping tx_input_list_amount_index_idx';
        DROP INDEX IF EXISTS tx_input_list_amount_index_idx;

        IF create_enabled THEN
            RAISE NOTICE 'Creating tx_input_list_amount_index_idx';
            CREATE INDEX tx_input_list_amount_index_idx ON tx_input_list (amount_index);
        END IF;
        */
    END IF;

    -- txo_amount_index
    IF index_level IS NULL OR index_level = 1 THEN
        RAISE NOTICE 'Dropping txo_amount_index_height_idx';
        DROP INDEX IF EXISTS txo_amount_index_height_idx;

        IF create_enabled THEN
            RAISE NOTICE 'Creating txo_amount_index_height_idx';
            CREATE INDEX txo_amount_index_height_idx ON txo_amount_index (height);
        END IF;
    END IF;

    IF index_level IS NULL OR index_level = 3 THEN
        RAISE NOTICE 'Dropping txo_amount_index_tx_hash_idx';
        DROP INDEX IF EXISTS txo_amount_index_tx_hash_idx;

        IF create_enabled THEN
            RAISE NOTICE 'Creating txo_amount_index_tx_hash_idx';
            CREATE INDEX txo_amount_index_tx_hash_idx ON txo_amount_index (tx_hash);
        END IF;
    END IF;
    
    IF index_level IS NULL OR index_level = 2 THEN
        -- [Pre-RingCT]: Index on pair { txo_amount, amount_index }.
        RAISE NOTICE 'Dropping txo_amount_index_txo_amount_amount_index_idx';
        DROP INDEX IF EXISTS txo_amount_index_txo_amount_amount_index_idx;

        IF create_enabled THEN
            RAISE NOTICE 'Creating txo_amount_index_txo_amount_amount_index_idx';
            CREATE INDEX txo_amount_index_txo_amount_amount_index_idx ON txo_amount_index (txo_amount, amount_index);
        END IF;

        -- [RingCT Only]: Omit txo_amount because txo_amount = 0 always.
        /*
        RAISE NOTICE 'Dropping txo_amount_index_amount_index_idx';
        DROP INDEX IF EXISTS txo_amount_index_amount_index_idx;

        IF create_enabled THEN
            RAISE NOTICE 'Creating txo_amount_index_amount_index_idx';
            CREATE INDEX txo_amount_index_amount_index_idx ON txo_amount_index (amount_index);
        END IF;
        */
    END IF;

    -- tx_ringmember_list
    IF index_level IS NULL OR index_level = 1 THEN
        RAISE NOTICE 'Dropping tx_ringmember_list_source_height_idx';
        DROP INDEX IF EXISTS tx_ringmember_list_source_height_idx;

        IF create_enabled THEN
            RAISE NOTICE 'Creating tx_ringmember_list_source_height_idx';
            CREATE INDEX tx_ringmember_list_source_height_idx ON tx_ringmember_list (source_height);
        END IF;
    END IF;

    IF index_level IS NULL OR index_level = 1 THEN
        RAISE NOTICE 'Dropping tx_ringmember_list_ringmember_height_idx';
        DROP INDEX IF EXISTS tx_ringmember_list_ringmember_height_idx;

        IF create_enabled THEN
            RAISE NOTICE 'Creating tx_ringmember_list_ringmember_height_idx';
            CREATE INDEX tx_ringmember_list_ringmember_height_idx ON tx_ringmember_list (ringmember_height);
        END IF;
    END IF;

    IF index_level IS NULL OR index_level = 2 THEN
        -- [Pre-RingCT]: Index on pair { source_vin_amount, ringmember_amount_index }.
        RAISE NOTICE 'Dropping tx_ringmember_list_source_vin_amt_ringmember_amt_index_idx';
        DROP INDEX IF EXISTS tx_ringmember_list_source_vin_amt_ringmember_amt_index_idx;

        IF create_enabled THEN
            RAISE NOTICE 'Creating tx_ringmember_list_source_vin_amt_ringmember_amt_index_idx';
            CREATE INDEX tx_ringmember_list_source_vin_amt_ringmember_amt_index_idx ON tx_ringmember_list (source_vin_amount, ringmember_amount_index);
        END IF;

        -- [RingCT Only]: Omit source_vin_amount because source_vin_amount = 0 always.
        /*
        RAISE NOTICE 'Dropping tx_ringmember_list_ringmember_amount_index_idx';
        DROP INDEX IF EXISTS tx_ringmember_list_ringmember_amount_index_idx;

        IF create_enabled THEN
            RAISE NOTICE 'Creating tx_ringmember_list_ringmember_amount_index_idx';
            CREATE INDEX tx_ringmember_list_ringmember_amount_index_idx ON tx_ringmember_list (ringmember_amount_index);
        END IF;
        */
    END IF;

    IF index_level IS NULL OR index_level = 3 THEN
        RAISE NOTICE 'Dropping tx_ringmember_list_source_tx_hash_idx';
        DROP INDEX IF EXISTS tx_ringmember_list_source_tx_hash_idx;

        IF create_enabled THEN
            RAISE NOTICE 'Creating tx_ringmember_list_source_tx_hash_idx';
            CREATE INDEX tx_ringmember_list_source_tx_hash_idx ON tx_ringmember_list (source_tx_hash);
        END IF;
    END IF;

    IF index_level IS NULL OR index_level = 3 THEN
        RAISE NOTICE 'Dropping tx_ringmember_list_ringmember_tx_hash_idx';
        DROP INDEX IF EXISTS tx_ringmember_list_ringmember_tx_hash_idx;

        IF create_enabled THEN
            RAISE NOTICE 'Creating tx_ringmember_list_ringmember_tx_hash_idx';
            CREATE INDEX tx_ringmember_list_ringmember_tx_hash_idx ON tx_ringmember_list (ringmember_tx_hash);
        END IF;
    END IF;        

    RAISE NOTICE 'ring_schema_indices: OK';
END;
$$;