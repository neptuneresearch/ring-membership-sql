CREATE OR REPLACE PROCEDURE ring_refresh(
    indices_enabled BOOLEAN DEFAULT TRUE,
    index_level INTEGER DEFAULT NULL   
) LANGUAGE plpgsql AS $$ 
BEGIN
    /*
        Ring Membership SQL
        (c) 2020-2021 Neptune Research
        SPDX-License-Identifier: BSD-3-Clause

        ring_refresh: Refresh materialized views for ring membership.
    */

    -- Indices: drop all before refresh
    --   Note that this CALL does not use the index_level parameter, for 2 reasons:
    --   (1) New index_level is not guaranteed to be equal to level of existing indices,
    --       so if it was different, the existing level wouldn't be dropped.
    --   (2) With respect to best performance, no indices should exist anyway during refresh.
    IF indices_enabled THEN
        RAISE NOTICE 'ring_refresh [%]: Dropping indices before refresh', timeofday()::timestamp;
        CALL ring_schema_indices(NULL, FALSE);
    END IF;

    --   tx_input_list
    RAISE NOTICE 'ring_refresh [%]: Refreshing tx_input_list', timeofday()::timestamp;
    REFRESH MATERIALIZED VIEW tx_input_list;
    --   txo_amount_index
    RAISE NOTICE 'ring_refresh [%]: Refreshing txo_amount_index', timeofday()::timestamp;
    REFRESH MATERIALIZED VIEW txo_amount_index;
    --   tx_ringmember_list
    RAISE NOTICE 'ring_refresh [%]: Refreshing tx_ringmember_list', timeofday()::timestamp;
    REFRESH MATERIALIZED VIEW tx_ringmember_list;

    -- Indices: drop all before refresh
    IF indices_enabled THEN
        RAISE NOTICE 'ring_refresh [%]: Creating indices after refresh', timeofday()::timestamp;
        CALL ring_schema_indices(index_level);
    END IF;

    RAISE NOTICE 'ring_refresh [%]: OK', timeofday()::timestamp;
END;
$$;