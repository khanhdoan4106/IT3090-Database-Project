# Data dictionary

This is a concise inventory derived from the current SQL script. Column-level types, nullability, defaults and constraints remain defined in `assignment/sql/quan_ly_the_ve_sqlserver.sql`.

| Table | Purpose |
|---|---|
| `HanhKhach` | Passenger information and passenger category |
| `LoaiThe` | Electronic-card/product types |
| `TheVeDienTu` | Issued card, wallet balance, lock state and expiry |
| `GiaoDich` | Top-up, monthly-package purchase and refund transactions |
| `Tram` | Bus stops and metro stations |
| `Tuyen` | Bus or metro route |
| `TuyenTram` | Route-to-station relationship and stop order |
| `XeBuyt` | Bus fleet and operational status |
| `NhanVien` | Shared employee information |
| `TaiXe` | Driver specialization and driving-license details |
| `PhuXe` | Bus-attendant specialization |
| `LichChay` | Route direction, departure time and service-day pattern |
| `ChuyenXe` | Scheduled bus trip, vehicle, driver and attendant |
| `LuotQuetThe` | Card-validation event and fare charged |

Update this document whenever the schema changes. For a formal submission, add each table's columns, data types, PK/FK relationships, nullability and business meaning.
