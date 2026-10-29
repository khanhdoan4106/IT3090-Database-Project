# Roadmap

The coursework schema stores the data correctly but leaves the business rules to whoever writes into it. The project closes those gaps.

## Gaps in the coursework schema

| Area | Gap | Status |
|---|---|---|
| Balance | Nothing updates `SoDuVi` when a top-up or scan is recorded, so the balance can drift from the transaction history. | Done: balances change only inside the procedures' transactions |
| Refunds | A refund in `GiaoDich` cannot be traced back to the transaction it refunds. | Done: `MaGiaoDichGoc`, one refund per top-up |
| Scan validity | A scan's station is not checked against its route or transport type, and the same card can be scanned twice in a row. | Done: checked by the scan procedures and unique indexes |
| Card status | Nothing prevents a locked or expired card from being used. | Done: locked cards refused; expired passes fall back to the wallet |
| Bus trips | `ChuyenXe` can reference a timetable entry on a metro route. | Done: a trigger keeps timetables on bus routes |

## Phases

1. **Repository structure** — coursework in `agm/`, labs in `lab/`, project skeleton in `database/`. *Done.*
2. **Schema v2** — fare table, refund link, sequences, rule-enforcing and lookup indexes. *Done.*
3. **Business operations** — procedures for card issue and lock, top-up, monthly pass, refund, bus scan and metro tap-in/tap-out. *Done.*
4. **Sample data and tests** — Hanoi reference data, demo activity and a test script (now 71 checks). *Done.*
5. **Remaining operations** — card replacement, penalties for journeys never tapped out, bus trip creation and status, discounts by passenger category, metro line changes. *Done.*
6. **Reporting** — views for daily revenue, ridership by route, entries by station and hour, card status, and balance audit. *Done.*
7. **Verification** — build on SQL Server and get 71/71 tests passing.
