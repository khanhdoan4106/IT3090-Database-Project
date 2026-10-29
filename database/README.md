# Project database

The full version of the transit card database, `QuanLyTheVeDienTu`. It starts from the coursework schema in [`agm/`](../agm/) and adds the business operations a real card system needs: top-ups, monthly passes, refunds, and bus and metro scans with fare calculation. The rules are described in [docs/business-rules.md](../docs/business-rules.md).

## Layout

| Folder | Contents |
|---|---|
| `schema/` | Database, tables, sequences and indexes |
| `procedures/` | Helper functions and the business procedures |
| `seed/` | Sample reference data and demo card activity |
| `tests/` | Test script that reports PASS/FAIL for each business rule |
| `views/` | Reporting views (planned) |
| `build.sql` | Runs every script in order |

## Building

Requirements: SQL Server 2016 or later.

1. Open `build.sql` and set `root` to the absolute path of this folder.
2. In SSMS, turn on **Query > SQLCMD Mode** and execute the file (F5). From a terminal: `sqlcmd -S <server> -E -I -f 65001 -i build.sql`.

The build drops and recreates `QuanLyTheVeDienTu`; the coursework database `QuanLyTheVe` is not touched. To run the scripts by hand instead, execute them in this order:

```
schema/01_create_database.sql
schema/02_tables.sql
schema/03_indexes_sequences.sql
procedures/01_functions.sql
procedures/02_the.sql
procedures/03_giao_dich.sql
procedures/04_quet_the.sql
seed/01_reference_data.sql
seed/02_demo_activity.sql
tests/01_test_business_rules.sql
```

## Tests

`tests/01_test_business_rules.sql` runs 43 checks: success cases, every business error code, and a final check that each card's balance equals its top-ups minus refunds minus fares charged. It ends with the list of results and a PASS/FAIL count. The tests change data, so rebuild the database before running them again.

## Changes from the coursework schema

| Change | Reason |
|---|---|
| New table `GiaVe` | Fare rules per transport type, used to compute each scan's charge |
| New column `GiaoDich.MaGiaoDichGoc` | Links a refund to the top-up it refunds; at most one refund per top-up |
| Bus scans require a trip and have no exit | Enforced by `ck_LuotQuetThe_Bus` |
| Unique filtered indexes | One open metro journey per card; one scan per card per bus trip; unique citizen ID when present |
| `TaiXe.HangGPLX` accepts D1, D2, D, E | Licence classes since 2025-01-01, plus E for licences issued earlier |
| Sequences `seq_TheVeDienTu`, `seq_GiaoDich`, `seq_LuotQuetThe` | Generate identifiers safely under concurrent use |
| Named defaults and constraints throughout | Easier maintenance and clearer error messages |
