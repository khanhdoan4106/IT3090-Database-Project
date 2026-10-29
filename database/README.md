# Project database

The full version of the transit card database. It starts from the coursework schema in [`agm/`](../agm/) and extends it with the business logic a real card system needs. See the [roadmap](../docs/roadmap.md) for what is planned.

## Layout

| Folder | Contents |
|---|---|
| `schema/` | Database and table creation scripts, constraints and indexes |
| `seed/` | Sample data for development and testing |
| `procedures/` | Stored procedures for business operations (top-up, card scan, refund, ...) |
| `views/` | Views for reporting |
| `tests/` | Test scripts with their expected results |

## Execution order

To be documented once the first scripts are added. Scripts will run in the order `schema` → `procedures` → `views` → `seed` → `tests`, and each file will be prefixed with a number (`01_`, `02_`, ...) to fix the order within a folder.
