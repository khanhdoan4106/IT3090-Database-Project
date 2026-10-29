# Lab exercises

In-class lab work for IT3090, written in T-SQL on SQL Server / SSMS. The labs use a separate football database, `QuanLyBongDa`, and are independent of the transit card project.

## Labs

| Lab | File | Contents |
|---|---|---|
| 1 | [`lab01/lab1_DoanQuocKhanh_202416243.sql`](lab01/lab1_DoanQuocKhanh_202416243.sql) | Creates the `QuanLyBongDa` database (9 tables) and loads the sample data |
| 2 | [`lab02/lab2_DoanQuocKhanh_202416243.sql`](lab02/lab2_DoanQuocKhanh_202416243.sql) | Queries: basic queries (a1–a10), grouping and aggregation (b1–b5), `EXISTS` / `NOT EXISTS` / `IN` subqueries (c1–c4) |

## Running

Run Lab 1 first: it drops and recreates `QuanLyBongDa`, so it can be re-run at any time to reset the data. Later labs run against that database.

## Naming

One folder per lab session (`lab01/`, `lab02/`, ...). Each file is named `lab<N>_<Name>_<StudentID>.sql`.
