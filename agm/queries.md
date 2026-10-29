# Coursework query catalog

Queries in [`sql/quan_ly_the_ve_sqlserver.sql`](sql/quan_ly_the_ve_sqlserver.sql), with the SQL technique each one demonstrates.

## Multi-table queries

| # | Question | Technique |
|---|---|---|
| 1 | Passenger name, card ID and card type of every card | Join of 3 tables |
| 2 | Stations on route `T01`, in stop order | Join + `ORDER BY` |
| 3 | Unlocked cards that have never been scanned | `LEFT JOIN` + `IS NULL` |
| 4 | Passengers who have used both bus and metro | `INTERSECT` |
| 5 | Passengers who have scanned in or out at every station of metro route `M01` | Relational division with nested `NOT EXISTS` |

## Aggregation queries

| # | Question | Technique |
|---|---|---|
| 1 | Number of passengers per passenger category | `GROUP BY` + `COUNT` |
| 2 | Number of issued cards per card type, including types with no cards | `LEFT JOIN` + `GROUP BY` |
| 3 | Monthly number of scans and total amount charged in 2026, by transport type | `GROUP BY` on an expression and a column |
| 4 | Passengers whose top-ups in October 2026 total at least 500,000 VND | `GROUP BY` + `HAVING SUM` |
| 5 | Route(s) with the most card scans, including ties | `HAVING COUNT >= ALL` (subquery) |

Identifiers such as `T01`, `M01` and the dates are example values.
