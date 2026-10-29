# Project database

The full version of the transit card database, `QuanLyTheVeDienTu`. It starts from the coursework schema in [`agm/`](../agm/) and adds the business operations a real card system needs: card issue and replacement, top-ups, monthly passes, refunds, bus and metro scans with network fares and category discounts, penalties for journeys never tapped out, bus trip operations, and reports. The rules are described in [docs/business-rules.md](../docs/business-rules.md).

## Layout

| Folder | Contents |
|---|---|
| `schema/` | Database, tables, sequences, indexes and triggers |
| `procedures/` | Helper functions and the business procedures |
| `views/` | Reporting views |
| `seed/` | Sample reference data and demo activity |
| `tests/` | Test script that reports PASS/FAIL for each business rule |
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
schema/04_triggers.sql
procedures/01_functions.sql
procedures/02_the.sql
procedures/03_giao_dich.sql
procedures/04_quet_the.sql
procedures/05_van_hanh.sql
views/01_bao_cao.sql
seed/01_reference_data.sql
seed/02_demo_activity.sql
tests/01_test_business_rules.sql
```

## Tests

`tests/01_test_business_rules.sql` runs 71 checks: success cases, every business error code, the reports, and a final balance audit (`v_DoiSoatSoDu`) proving that each card's balance matches its history. It ends with the list of results and a PASS/FAIL count. The tests change data, so rebuild the database before running them again.

## Changes from the coursework schema

| Change | Reason |
|---|---|
| New table `GiaVe` | Fare rules per transport type, used to compute each scan's charge |
| New column `GiaoDich.MaGiaoDichGoc` | Links a refund to the top-up it refunds, and a received balance to the balance sent; at most one of each |
| New table `UuDaiDoiTuong` | Per-ride and monthly-pass discounts per passenger category |
| New column `TheVeDienTu.MaTheCu` | Links a replacement card to the card it replaces; a card is replaced at most once |
| `GiaoDich.LoaiGiaoDich` adds `CHUYEN_DI`, `CHUYEN_DEN` | Balance moved to a replacement card; no payment method |
| New column `LuotQuetThe.TrangThai` | Journey status (`DANG_DI`, `HOAN_THANH`, `KHONG_QUET_RA`), so abandoned journeys can be closed with a penalty |
| Triggers on `LichChay` and `Tuyen` | Timetables only on bus routes |
| Bus scans require a trip and have no exit | Enforced by `ck_LuotQuetThe_Bus` |
| Unique filtered indexes | One metro journey in progress per card; one scan per card per bus trip; unique citizen ID when present |
| `TaiXe.HangGPLX` accepts D1, D2, D, E | Licence classes since 2025-01-01, plus E for licences issued earlier |
| Sequences `seq_TheVeDienTu`, `seq_GiaoDich`, `seq_LuotQuetThe` | Generate identifiers safely under concurrent use |
| Named defaults and constraints throughout | Easier maintenance and clearer error messages |
