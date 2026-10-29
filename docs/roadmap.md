# Roadmap

The coursework schema stores the data correctly but leaves the business rules to whoever writes into it. The project closes those gaps.

## Gaps in the coursework schema

| Area | Gap |
|---|---|
| Balance | Nothing updates `SoDuVi` when a top-up or scan is recorded, so the balance can drift from the transaction history. |
| Refunds | A refund in `GiaoDich` cannot be traced back to the transaction it refunds. |
| Scan validity | A scan's station is not checked against its route or transport type, and the same card can be scanned twice in a row. |
| Card status | Nothing prevents a locked or expired card from being used. |
| Bus trips | `ChuyenXe` can reference a timetable entry on a metro route. |

## Phases

1. **Repository structure** — coursework in `agm/`, labs in `lab/`, project skeleton in `database/`.
2. **Schema v2** — schema changes needed by the business rules above, plus indexes for the main lookups.
3. **Business operations** — stored procedures for top-up, monthly-pass purchase, card scan and refund, each in a transaction so balance and history stay consistent.
4. **Sample data and tests** — realistic seed data and test scripts that check each procedure and query against expected results.
5. **Reporting** — views for revenue, ridership by route and station, and card usage.
