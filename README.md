# Ring Membership SQL
Ring Membership SQL is a set of Materialized Views for PostgreSQL that can be used to show ring member relationships between Monero transactions.

---
## Table of Contents
- [Overview](#Overview)
- [Requirements](#Requirements)
- [Installation](#Installation)
- [Materialized View txo_amount_index](#Materialized-View-txo_amount_index)
  - [Notes](#Notes)
  - [Transaction version filter](#Transaction-version-filter)
  - [Indices](#Indices)
- [Materialized View tx_input_list](#Materialized-View-tx_input_list)
  - [Notes](#Notes-1)
  - [Transaction version filter](#Transaction-version-filter-1)
  - [Indices](#Indices-1)
- [Materialized View tx_ringmember_list](#Materialized-View-tx_ringmember_list)
  - [Columns always included](#Columns-always-included)
  - [Columns optionally included](#Columns-optionally-included)
  - [Columns never included](#Columns-never-included)
  - [Transaction version filter](#Transaction-version-filter-2)
  - [Indices](#Indices-2)
- [Other Queries](#Other-Queries)
- [Stored Procedure ring_refresh](#Stored-Procedure-ring_refresh)
  - [Parameters](#Parameters)
- [Stored Procedure ring_schema_indices](#Stored-Procedure-ring_schema_indices)
  - [Parameters](#Parameters-1)
  - [Index Levels](#Index-Levels)
  - [Transaction version filter](#Transaction-version-filter-3)
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

- PostgreSQL 13+
  - This package was last tested with PostgreSQL version 13.3. Older versions may work; development has taken place under versions 11.5, 12.3, 13.2.

- Monero blockchain data
  - A table of blocks, where each block row includes an array-typed column of transactions, and each transaction row includes further arrays for inputs and outputs, with key offsets, amounts, and output keys.

    This set of Materialized Views is designed specifically to work with the Monero schema in `coinmetrics-export` [[2]](#References), but it could be ported to any schema that has the sufficient data.

- Disk space (estimate)

  - As of mainnet block height 2457499 (date 2021-09-26), with all [index levels](#Index-Levels):

    |Object|Table Size|Indices Size|Total Size|
      |----------|----------|------------|----------|
      |tx_input_list|63 GB|18 GB|81 GB|
      |txo_amount_index|8990 MB|3696 MB|12 GB|
      |tx_ringmember_list|72 GB|16 GB|88 GB|


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

Everything in this package uses these 2 materialized views: install them both first before installing any other files.

| File | Description |
| - | - |
| `tx_input_list.sql` | Decodes key offsets to amount indices |
| `txo_amount_index.sql` | Creates a chronological index of all transaction outputs per amount |

The default applications join them together.

| File | Description |
| - | - |
| `tx_ringmember_list.sql` | List ring members (`txo_amount_index`) per transaction input (`tx_input_list`) |
| `ringmember_tx_list.sql` | List ring member usage (`tx_input_list`) per transaction output (`txo_amount_index`) |

Materialized views are created `WITH NO DATA` and must be refreshed before usage. See [Stored Procedure `ring_refresh`](#Stored-Procedure-ring_refresh).

Note that when installing materialized views, the following message is normal and is not an issue:

    materialized view "materialized_view_name" does not exist, skipping

This message occurs because the file first tries to `DROP` the given materialized view before it `CREATE`s it, in case it already exists.

## Stored Procedures
This package includes the following stored procedures.

| File | Description |
| - | - |
| `ring_refresh.sql` | Refresh Materialized Views `tx_input_list, txo_amount_index, tx_ringmember_list` |
| `ring_schema_indices.sql` | Create or drop indices on Materialized Views `tx_input_list, txo_amount_index, tx_ringmember_list` |


---
# Materialized View `txo_amount_index`
Every transaction output, including coinbase transactions, indexed by amount.

| Column | Description | Type | Source |
| - | - | - | - |
| `block_height` | Block height | `BIGINT` | Block |
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

| Index level | Column(s) | Index name |
| - | - | - |
| 1 | `block_height` | `txo_amount_index_block_height_idx` |
| 2 (Pre-RingCT) | `txo_amount, amount_index` | `txo_amount_index_txo_amount_amount_index_idx` |
| 2 (RingCT Only) | `amount_index` | `txo_amount_index_amount_index_idx` |
| 3 | `tx_hash` | `txo_amount_index_tx_hash_idx` |


---
# Materialized View `tx_input_list`
List absolute key offsets per transaction input per transaction per block.

| Column | Description | Type | Source |
| - | - | - | - |
| `block_height` | Block height | `BIGINT` | Block |
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
  
Pre-RingCT filter will include all transaction inputs of all transactions of all versions.

RingCT Only filter will only include transaction inputs of zero amount from transactions of version 2 (blocks 1220516+).

To switch filters, comment/uncomment the respective sections in the materialized view to change its query, and refresh the materialized view.
- `WHERE` clause

Default filter is Pre-RingCT.

## Indices
`ring_schema_indices()` includes the following indices for `tx_input_list`.

| Index level | Column(s) | Index name |
| - | - | - |
| 1 | `block_height` | `tx_input_list_block_height_idx` |
| 2 (Pre-RingCT) | `vin_amount, amount_index` | `tx_input_list_vin_amount_amount_index_idx` |
| 2 (RingCT Only) | `amount_index` | `tx_input_list_amount_index_idx` |
| 3 | `tx_hash` | `tx_input_list_tx_hash_idx` |


---
# Materialized View `tx_ringmember_list`
Linking key offsets (`tx_input_list`) to the output amount index (`txo_amount_index`), list the ring members for each transaction input.

Inclusion in the `SELECT` list for columns from the given tables is categorized into:
- Always
- Optional
- Never

## Columns always included

| Column | Description | Type | Source |
| - | - | - | - |
| `tx_block_height` | Block height of transaction | `BIGINT` | `tx_input_list` |
| `tx_block_timestamp` | Block timestamp of transaction | `BIGINT` | `tx_input_list` |
| `tx_block_tx_index` | Ordinality of transaction in its block | `BIGINT` (per `WITH ORDINALITY`) | `tx_input_list` |
| `tx_hash` | Transaction hash of transaction | `BYTEA` | `tx_input_list` |
| `tx_vin_index` | Ordinality of transaction input in its transaction | `BIGINT` (per `WITH ORDINALITY`) | `tx_input_list` |
| `tx_vin_amount` | Transaction input amount | `BIGINT` | `tx_input_list` |
| `tx_vin_ringmember_index` | Transaction input key offset index | `BIGINT` (per `WITH ORDINALITY`) | `tx_input_list` |
| `ringmember_block_height` | Block height of ring member | `BIGINT` | `txo_amount_index` |
| `ringmember_block_timestamp` | Block timestamp of ring member | `BIGINT` | `txo_amount_index` |
| `ringmember_block_tx_index` | Ordinality of ring member's transaction in its block | `BIGINT` (per `WITH ORDINALITY`) | `txo_amount_index` |
| `ringmember_tx_hash` | Transaction hash of ring member's transaction | `BYTEA` | `txo_amount_index` |
| `ringmember_tx_txo_index` | Ordinality of transaction output in ring member's transaction | `BIGINT` (per `WITH ORDINALITY`) | `txo_amount_index` |
| `ringmember_txo_amount_index` | Ring member output amount index | `BIGINT` | `txo_amount_index` |

## Columns optionally included
Uncomment these columns to add them.

| Column | Description | Type | Source |
| - | - | - | - |
| `tx_vin_k_image` | Transaction input key image | `BYTEA` | `tx_input_list` |
| `ringmember_txo_key` | Ring member output key | `BYTEA` | `txo_amount_index` |

## Columns never included

- `tx_input_list.vin_key_offset`: the differentially-encoded output amount index; being encoded, it is only useful after `tx_input_list` decodes it into `amount_index`.

- `tx_input_list.amount_index`: per the JOIN, this is equal to `txo_amount_index.amount_index`, which is always included as `ringmember_txo_amount_index`.

- `txo_amount_index.txo_amount`: per the JOIN, this is equal to `tx_input_list.vin_amount`, which is always included as `tx_vin_amount`.

## Transaction version filter
Two transaction version filters are possible for this view: Pre-RingCT and RingCT Only.
  
Pre-RingCT filter will JOIN the given tables on both Amount and Amount Index, and output the `tx_vin_amount` column.

RingCT Only filter will JOIN the given tables only on Amount Index since the Amount is guaranteed to be zero, and not output the `tx_vin_amount` column for the same reason.

To switch filters, comment/uncomment the respective sections in the materialized view to change its query, and refresh the materialized view.
- `tx_vin_amount` column
- `JOIN` clause

Default filter is Pre-RingCT.

## Indices
`ring_schema_indices()` includes the following indices for `tx_ringmember_list`.

Note: because of the default PostgreSQL limit on identifier length (`NAMEDATALEN = 64`), the following indices have names which don't exactly match their source columns:
- `tx_ringmember_list_tx_vin_amt_ringmember_amt_index_idx [54]` (would be `tx_ringmember_list_tx_vin_amount_ringmember_txo_amount_index_idx [64]`)
        
| Index level | Column(s) | Index name |
| - | - | - |
| 1 | `tx_block_height` | `tx_ringmember_list_tx_block_height_idx` |
| 1 | `ringmember_block_height` | `tx_ringmember_list_ringmember_block_height_idx` |
| 2 (Pre-RingCT) | `tx_vin_amount, ringmember_txo_amount_index` | `tx_ringmember_list_tx_vin_amt_ringmember_txo_amt_index_idx` |
| 2 (RingCT Only) | `ringmember_txo_amount_index` | `tx_ringmember_list_ringmember_txo_amount_index_idx` |
| 3 | `tx_hash` | `tx_ringmember_list_tx_hash_idx` |
| 3 | `ringmember_tx_hash` | `tx_ringmember_list_ringmember_tx_hash_idx` |

---
# Other Queries
Some other queries are provided. 

- Materialized Views (in directory `materialized_views_2`)
  - `ringmember_tx_list`: Inverse of `tx_ringmember_list`: linking the output amount index (`txo_amount_index`) to key offsets (`tx_input_list`), list the transactions which use each output as a ring member.
  - `txo_first_ring`: List all transaction outputs and the first transaction which uses each as a ring member.
  - `txo_no_ring`: List all transaction outputs that have never been used as ring members.
  - *Note: these Materialized Views are not included in `ring_refresh()` or `ring_schema_indices()`, and must be refreshed or indexed manually.*

- Views for `txo_first_ring` (in directory `views`):
  - `txo_first_ring_distance`: helper view that adds columns for age in terms of block height and timestamp.
  - `txo_first_ring_distance_distribution`: age distribution for first usage of ring members.
  - `txo_first_ring_spendable_age_invalid`: tests the "10 block lock time for incoming outputs" introduced in HF v12 (result: no results because the consensus rule works).


---
# Stored Procedure `ring_refresh`
Utility procedure to refresh the ring membership materialized views `tx_input_list, txo_amount_index, tx_ringmember_list`.


```
CALL ring_refresh(indices_enabled, index_level);
```

All parameters are optional. By default (no parameters specified), indices will be (re)created at full [index level](#Index-Levels), after the materialized views are refreshed. See [Stored Procedure `ring_schema_indices`](#Stored-Procedure-ring_schema_indices) for more information regarding materialized view refreshing and indices.

Note that, as of PostgreSQL 11, materialized view refresh is not incremental: each refresh must always rebuild all data starting from block 0.

## Parameters
| Parameter | Type | Description |
| - | - | - |
| ```indices_enabled``` | ```BOOLEAN``` | *Optional*: Use `FALSE` to disable index (re)creation. Defaults to `TRUE` (indices will be (re)created). |
| ```index_level``` | ```INTEGER``` | *Optional*: Only used when `indices_enabled = TRUE`. See ["ring_schema_indices: Index Levels"](#Index-Levels). Defaults to ```NULL``` (all levels). |


---
# Stored Procedure `ring_schema_indices`
Create or drop indices on the ring membership materialized views `tx_input_list, txo_amount_index, tx_ringmember_list`.

```
CALL ring_schema_indices(index_level, create_enabled);
```

All parameters are optional. By default (no parameters specified), all indices will be created.

Indices make queries faster, so they are recommended to be created BEFORE querying any materialized views. 

However, after their initial creation, indices are updated whenever materialized views are refreshed. For maximum efficiency, it is recommended drop indices BEFORE refreshing materialized views, and only create them AFTER all refreshes are completed.

## Parameters
| Parameter | Type | Description |
| - | - | - |
| ```index_level``` | ```INTEGER``` | *Optional*: See ["ring_schema_indices: Index Levels"](#Index-Levels). Defaults to ```NULL``` (all levels). |
| ```create_enabled``` | ```BOOLEAN``` | *Optional*: Use `FALSE` to drop indices without recreating them. Defaults to `TRUE` (drop if exist, then create). |

## Index Levels
Only build the indices you need: an index level is a subset of indices related to the same type of data.

Levels are additive, i.e. level 2 does not include level 1.

| Index Level | Description |
| - | - |
| 1 | Block height |
| 2 | Amount (Pre-RingCT) and Amount Index (Pre-RingCT and RingCT Only) |
| 3 | Transaction hash |

## Transaction version filter
Two filters are possible for this procedure: Pre-RingCT and RingCT Only.

Pre-RingCT filter will include the Amount value in the Amount Index indices.

RingCT Only filter will not include the Amount value in the Amount Index indices, because the Amount is guaranteed to always have the value `0`.

To switch filters, comment/uncomment the respective sections in the stored procedure.
- `tx_input_list`: switch instruction set inside `IF` block for Level 2
- `txo_amount_index`: switch instruction set inside `IF` block for Level 2
- `tx_ringmember_list`: switch instruction set inside `IF` block for Level 2

Default filter is Pre-RingCT.


# References
[1] Monero - secure, private, untraceable. [https://web.getmonero.org](https://web.getmonero.org)

[2] GitHub - coinmetrics-io/haskell-tools: Tools for exporting blockchain data to analytical databases. [https://github.com/coinmetrics-io/haskell-tools](https://github.com/coinmetrics-io/haskell-tools)

[3] Monero StackExchange - Understanding the structure of a Monero transaction. https://monero.stackexchange.com/questions/2136/understanding-the-structure-of-a-monero-transaction

[4] Monero StackExchange - RPC method to translate key_offsets. https://monero.stackexchange.com/questions/7576/rpc-method-to-translate-key-offsets

[5] Monero StackExchange - How does input reference the output of some transaction? https://monero.stackexchange.com/questions/6736/how-does-input-reference-the-output-of-some-transaction

[6] GitHub - moneroexamples/transactions-export. https://github.com/moneroexamples/transactions-export

[7] PostgreSQL Wiki - Incremental View Maintenance. https://wiki.postgresql.org/wiki/Incremental_View_Maintenance  
