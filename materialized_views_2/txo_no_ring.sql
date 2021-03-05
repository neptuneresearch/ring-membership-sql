DROP MATERIALIZED VIEW IF EXISTS txo_no_ring;

CREATE MATERIALIZED VIEW txo_no_ring AS (
    /*
        Ring Membership SQL
        (c) 2021 Neptune Research
        SPDX-License-Identifier: BSD-3-Clause

        txo_no_ring: Transaction outputs that have never been used as ring members.
    */

	SELECT 
        TXO.*
	FROM txo_amount_index TXO 
	LEFT JOIN tx_input_list RING 
		ON RING.vin_amount = TXO.txo_amount
		AND RING.amount_index = TXO.amount_index 
	WHERE RING.amount_index IS NULL
) WITH NO DATA;