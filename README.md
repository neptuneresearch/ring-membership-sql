# Ring Membership SQL
Ring Membership SQL is a set of Materialized Views for PostgreSQL that can be used to show ring member relationships between Monero transactions.

---
## Table of Contents
- [Overview](#Overview)
- [Requirements](#Requirements)
- [Installation](#Installation)
- [Materialized View txo_amount_index](#Materialized-View-txo_amount_index)
- [Materialized View tx_input_list](#Materialized-View-tx_input_list)
- [Materialized View tx_ringmember_list](#Materialized-View-tx_ringmember_list)
- [Applications (In Development)](#Applications-In-Development)
- [Stored Procedure ring_refresh](#Stored-Procedure-ring_refresh)
- [Stored Procedure ring_schema_indices](#Stored-Procedure-ring_schema_indices)
- [References](#References)
  
---
# Overview
In Monero [[1]](#References), two byproducts of blockchain data are needed in order to link a transaction to its ring members.

1. **Amount Index**: A chronological index of every transaction output on the blockchain, per amount. This is what is computed in Materialized View `txo_amount_index`.

    *Note*: Since amounts are hidden in RingCT, there is only one Amount Index for RingCT transactions, the index for the zero amount.

2. **Key Offsets**: Every transaction input has a list of Key Offsets, which are the Amount Indices of its ring members, but differentially encoded, i.e. `{ 100, 1, 2 } = { 100, 101, 103 }`. So this must be decoded to make use of it. This is what is computed in Materialized View `tx_input_list`.

Given those two data sets, ring member relationships between transactions can be shown. This is what is computed in Materialized View `tx_ringmember_list`.


---
# Requirements

- PostgreSQL 11+
  - These procedures and tables were written and tested with PostgreSQL versions 11.5 and 12.3. Older versions may work.

- Monero blockchain data
  - A table of blocks, where each block row includes an array-typed column of transactions, and each transaction row includes further arrays for inputs and outputs, with key offsets, amounts, and output keys.

    This set of Materialized Views is designed specifically to work with the Monero schema in `coinmetrics-export` [[2]](#References), but it could be ported to any schema that has the sufficient data.


---
# Installation
## Using SQL Files
To install a SQL file, run the entire file contents against your PostgreSQL database.

Example for PostgreSQL CLI, where `DB_NAME` is the name of the target database, and `FILE.SQL` is the source filename:

  ```
  psql -d DB_NAME -f FILE.SQL
  ```

## Materialized Views
The core of this package is composed of 2 materialized views.

| File | Description |
| - | - |
| `tx_input_list.sql` | Decodes key offsets to amount indices |
| `txo_amount_index.sql` | Creates a chronological index of all transaction outputs per amount |

The default applications join them together.

| File | Description |
| - | - |
| `tx_ringmember_list.sql` | List ring members (`txo_amount_index`) per transaction input (`tx_input_list`) |
| `ringmember_tx_list.sql` | List ring member usage (`tx_input_list`) per transaction output (`txo_amount_index`) |

Materialized views are created `WITH NO DATA` and must be refreshed before usage. See [Stored Procedure `ring_refresh`](#Stored_Procedure_ring_refresh).

## Stored Procedures
This package includes the following stored procedures.

| File | Description |
| - | - |
| `ring_refresh.sql` | Refresh all Materialized Views |
| `ring_schema_indices.sql` | Create indices on all Materialized Views |


---
# Materialized View `txo_amount_index`
Every transaction output, including coinbase transactions, indexed by amount.

| Column | Description | Type | Source |
| - | - | - | - |
| `height` | Block height | `BIGINT` | Block |
| `block_timestamp` | Block timestamp | `BIGINT` | Block |
| `tx_index` | Ordinality of transaction *(see Note 1)* | `BIGINT` (per `WITH ORDINALITY`) | Block |
| `tx_hash` | Transaction hash | `BYTEA` | Transaction |
| `txo_index` | Ordinality of transaction output | `BIGINT` (per `WITH ORDINALITY`) | Transaction |
| `txo_key` | Transaction output key | `BYTEA` | Transaction output |
| `txo_amount` | Transaction output amount *(see Note 2)* | `BIGINT` | Transaction output |
| `amount_index` | Amount index *(see Note 3)* | `BIGINT` (per `ROW_NUMBER`) | Computed |

### Notes
1. `tx_index`: Coinbase transactions use index `-1`.

2. `txo_amount`: Amount for RingCT transaction outputs is always `0`. RingCT coinbases are also indexed under amount `0` even though they have nonzero amount values (see Monero Core `blockchain_db/blockchain_db.cpp: BlockchainDB::add_transaction`).

3. `amount_index`: Amount Index starts at `0`.

## Transaction version filter
Two filters are possible for this view: Pre-RingCT and RingCT Only.

Pre-RingCT filter will include transactions of both Version 1 (blocks 0-1220515) and Version 2 (blocks 1220516+)
- Version 1 (Pre-RingCT) Transactions have a separate index per amount. JOIN keys are `txo_amount, amount_index`.
- Version 2 (RingCT) Transactions are all in one index for the amount 0. JOIN key is `amount_index`.

RingCT Only filter will only include Transactions of Version 2 (blocks 1220516+). JOIN key is `amount_index`.

To switch filters, comment/uncomment the respective sections in the materialized view to change its query, and refresh the materialized view.
- Column `txo_amount`
- `WHERE` clauses

Default filter is Pre-RingCT.

## Indices
`ring_schema_indices()` includes the following indices for `txo_amount_index`.

- `txo_amount_index_idx`: index on `{ amount_index }`
- `txo_amount_index_tx_hash_idx`: index on `{ tx_hash }`
- `txo_amount_index_txo_key_idx`: index on `{ txo_key }`


---
# Materialized View `tx_input_list`
List absolute key offsets per transaction input per transaction per block.

| Column | Description | Type | Source |
| - | - | - | - |
| `height` | Block height | `BIGINT` | Block |
| `block_timestamp` | Block timestamp | `BIGINT` | Block |
| `tx_index` | Ordinality of transaction | `BIGINT` (per `WITH ORDINALITY`) | Block |
| `tx_hash` | Transaction hash | `BYTEA` | Transaction |
| `vin_index` | Ordinality of transaction input | `BIGINT` (per `WITH ORDINALITY`) | Transaction |
| `vin_k_image` | Transaction input key image | `BYTEA` | Transaction input |
| `vin_amount` | Transaction input amount *(see Note 1)* | `BIGINT` | Transaction input |
| `vin_key_offset_index` | Ordinality of key offset | `BIGINT` (per `WITH ORDINALITY`) | Transaction input |
| `vin_key_offset` | Differential key offset | `BIGINT` | Key offset |
| `amount_index` | Absolute key offset | `NUMERIC` (per `SUM(BIGINT)`) | Key offset |

### Notes
1. `vin_amount`: Amount for RingCT transactions is always `0`.

## Transaction version filter
Two transaction version filters are possible for this view: Pre-RingCT and RingCT Only.
  
Pre-RingCT filter will include transactions of both Version 1 (blocks 0-1220515) and Version 2 (blocks 1220516+).  
RingCT Only filter will only include Transactions of Version 2 (blocks 1220516+).

To switch filters, comment/uncomment the respective sections in the materialized view to change its query, and refresh the materialized view.
- `WHERE` clause

Default filter is Pre-RingCT.

## Indices
`ring_schema_indices()` includes the following indices for `tx_input_list`.

- `tx_input_list_height_idx`: index on `{ height }`
- `tx_input_list_tx_hash_idx`: index on `{ tx_hash }`
- `tx_input_list_amount_index_idx`: index on `{ amount_index }`

---
# Materialized View `tx_ringmember_list`
Linking key offsets (`tx_input_list`) to the output amount index (`txo_amount_index`), list the ring members for each transaction input.

| Column | Description | Type | Source |
| - | - | - | - |
| `source_height` | Block height | `BIGINT` | `tx_input_list` |
| `source_block_timestamp` | Block timestamp | `BIGINT` | `tx_input_list` |
| `source_tx_hash` | Transaction hash | `BYTEA` | `tx_input_list` |
| `source_tx_index` | Ordinality of transaction | `BIGINT` (per `WITH ORDINALITY`) | `tx_input_list` |
| `source_vin_index` | Ordinality of transaction input | `BIGINT` (per `WITH ORDINALITY`) | `tx_input_list` |
| `source_k_image` | Transaction input key image | `BYTEA` | `tx_input_list` |
| `ringmember_index` | Transaction input key offset index | `BIGINT` (per `WITH ORDINALITY`) | `tx_input_list` |
| `ringmember_amount_index` | Ring member amount index | `BIGINT` | `txo_amount_index` |
| `ringmember_txo_key` | Ring member output key | `BYTEA` | `txo_amount_index` |
| `ringmember_height` | Ring member block height | `BIGINT` | `txo_amount_index` |
| `ringmember_block_timestamp` | Ring member block timestamp | `BIGINT` | `txo_amount_index` |

## Indices
`ring_schema_indices()` includes the following indices for `tx_input_list`.

- `tx_ringmember_list_source_height_idx`: index on `{ source_height }`
- `tx_ringmember_list_ringmember_height_idx`: index on `{ ringmember_height }`
- `tx_ringmember_list_source_tx_hash_idx`: index on `{ source_tx_hash }`
- `tx_ringmember_list_ringmember_txo_key_idx`: index on `{ ringmember_txo_key }`
- `tx_ringmember_list_ringmember_amount_index_idx`: index on `{ ringmember_amount_index }`


---
# Applications (In Development)
These are still in development and are not yet included in the refresh or index procs.

- `ringmember_tx_list`: Linking the output amount index (txo_amount_index) to key offsets (tx_input_list), list the transactions which use each output as a ring member.
- `txo_first_ring`: For each transaction output, find the first transaction which uses it as a ring member.
- `txo_no_ring`: Transaction outputs that have never been used as ring members.


---
# Stored Procedure `ring_refresh`
Utility procedure to refresh all materialized views in this package.

```
CALL ring_refresh();
```

Note that, as of PostgreSQL 11, materialized view refresh is not incremental: each refresh must always rebuild all data starting from block 0.

---
# Stored Procedure `ring_schema_indices`
Indices on materialized views are created by the stored procedure `ring_schema_indices`.

1. Use the file `ring_schema_indices.sql` to create the stored procedure `ring_schema_indices`.

    ```
    psql -d DB_NAME -f ring_schema_indices.sql
    ```

2. WHEN READY to create indices on output tables, execute the stored procedure `ring_schema_indices()`.

    ```
    CALL ring_schema_indices();
    ```

    - Indices make queries faster, so they are recommended to be installed BEFORE querying any materialized views. 
    - Indices will update themselves at time of materialized view refresh.


# References
[1] Monero - secure, private, untraceable. [https://web.getmonero.org](https://web.getmonero.org)

[2] GitHub - coinmetrics-io/haskell-tools: Tools for exporting blockchain data to analytical databases. [https://github.com/coinmetrics-io/haskell-tools](https://github.com/coinmetrics-io/haskell-tools)

[3] Monero StackExchange - Understanding the structure of a Monero transaction. https://monero.stackexchange.com/questions/2136/understanding-the-structure-of-a-monero-transaction

[4] Monero StackExchange - RPC method to translate key_offsets. https://monero.stackexchange.com/questions/7576/rpc-method-to-translate-key-offsets

[5] Monero StackExchange - How does input reference the output of some transaction? https://monero.stackexchange.com/questions/6736/how-does-input-reference-the-output-of-some-transaction

[6] GitHub - moneroexamples/transactions-export. https://github.com/moneroexamples/transactions-export

[7] PostgreSQL Wiki - Incremental View Maintenance. https://wiki.postgresql.org/wiki/Incremental_View_Maintenance  
