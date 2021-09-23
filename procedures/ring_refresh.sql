CREATE OR REPLACE PROCEDURE ring_refresh() LANGUAGE plpgsql AS $$ 
BEGIN
    /*
        Ring Membership SQL
        (c) 2020-2021 Neptune Research
        SPDX-License-Identifier: BSD-3-Clause

        ring_refresh: Refresh materialized views for ring membership
    */

    --   tx_input_list
    RAISE NOTICE 'Refreshing tx_input_list';
    REFRESH MATERIALIZED VIEW tx_input_list;
    --   txo_amount_index
    RAISE NOTICE 'Refreshing txo_amount_index';
    REFRESH MATERIALIZED VIEW txo_amount_index;
    --   tx_ringmember_list
    RAISE NOTICE 'Refreshing tx_ringmember_list';
    REFRESH MATERIALIZED VIEW tx_ringmember_list;

    RAISE NOTICE 'Ring Membership refresh OK';
END;
$$;