# Coursework assignment

The IT3090 database assignment as submitted to the instructor. Files in this folder are kept unchanged; further development happens in [`database/`](../database/).

## Contents

| File | Description |
|---|---|
| `sql/quan_ly_the_ve_sqlserver.sql` | Creates the `QuanLyTheVe` database and its 14 tables, followed by 5 multi-table queries and 5 `GROUP BY` queries |
| `diagrams/so_do_thuc_the_lien_ket.png` | Entity–relationship diagram |
| `diagrams/so_do_quan_he.png` | Relational schema diagram |
| `diagrams/bien_doi_so_do_quan_he.pdf` | ERD-to-relational-schema transformation and attribute domains |
| `queries.md` | What each query in the script answers |

## Running the script

1. Open `sql/quan_ly_the_ve_sqlserver.sql` in SSMS.
2. Execute the whole script (F5). It creates the database, the tables, and then runs the example queries.

The script contains no sample data, so the queries return empty results until data is inserted. Because it starts with `CREATE DATABASE QuanLyTheVe`, drop that database before running the script a second time.
