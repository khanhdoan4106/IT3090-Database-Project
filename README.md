# IT3090 Database Project

A SQL Server database for managing electronic transit cards on Hanoi's bus and metro network: passengers, card products, wallet top-ups, card validations, routes, stations and bus operations.

The repository started as the coursework for IT3090 (Databases, HUST) and is being developed into a complete, business-oriented database project.

## Repository structure

| Path | Contents |
|---|---|
| [`agm/`](agm/) | Coursework assignment as submitted: SQL script, ERD, relational schema and query catalog. Kept unchanged as the graded version. |
| [`lab/`](lab/) | In-class lab exercises (separate `QuanLyBongDa` database). |
| [`database/`](database/) | The full project: schema, seed data, stored procedures, views and tests. |
| [`docs/`](docs/) | Project documentation: design, data dictionary and roadmap. |

## Getting started

Requirements: Microsoft SQL Server 2016 or later and SQL Server Management Studio (SSMS) or another SQL Server client.

- **Coursework version:** open [`agm/sql/quan_ly_the_ve_sqlserver.sql`](agm/sql/quan_ly_the_ve_sqlserver.sql) and execute it. See [`agm/README.md`](agm/README.md).
- **Project version:** run [`database/build.sql`](database/build.sql) in SQLCMD mode; it builds `QuanLyTheVeDienTu`, loads sample data and runs the tests. See [`database/README.md`](database/README.md).

> The coursework script creates `QuanLyTheVe`; the project build drops and recreates `QuanLyTheVeDienTu`. Run them only on a development or test SQL Server instance.

## Documentation

- [Database design](docs/database-design.md)
- [Business rules and error codes](docs/business-rules.md)
- [Data dictionary](docs/data-dictionary.md)
- [Roadmap](docs/roadmap.md)
- [Coursework query catalog](agm/queries.md)
