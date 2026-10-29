# Data dictionary

Tables in the current schema. Column types, keys and constraints are defined in [`agm/sql/quan_ly_the_ve_sqlserver.sql`](../agm/sql/quan_ly_the_ve_sqlserver.sql); attribute domains are listed in [`agm/diagrams/bien_doi_so_do_quan_he.pdf`](../agm/diagrams/bien_doi_so_do_quan_he.pdf).

| Table | Purpose | Primary key | References |
|---|---|---|---|
| `HanhKhach` | Passenger and passenger category | `MaHanhKhach` | — |
| `LoaiThe` | Card product, price and validity period | `MaLoaiThe` | — |
| `TheVeDienTu` | Issued card, wallet balance, expiry and lock status | `MaTheDienTu` | `LoaiThe`, `HanhKhach` |
| `GiaoDich` | Top-up, monthly-pass purchase or refund | `MaGiaoDich` | `TheVeDienTu` |
| `Tram` | Bus stop or metro station | `MaTram` | — |
| `Tuyen` | Bus or metro route | `MaTuyen` | — |
| `TuyenTram` | Station on a route and its stop order | `MaTuyen, MaTram` | `Tuyen`, `Tram` |
| `XeBuyt` | Bus and its operating status | `MaXe` | — |
| `NhanVien` | Common staff data | `MaNhanVien` | — |
| `TaiXe` | Driver and driving licence | `MaNhanVien` | `NhanVien` |
| `PhuXe` | Bus attendant | `MaNhanVien` | `NhanVien` |
| `LichChay` | Timetable entry: direction, departure time, service days | `MaLich` | `Tuyen` |
| `ChuyenXe` | Bus run on a date, with bus, driver and attendant | `MaChuyen` | `LichChay`, `XeBuyt`, `TaiXe`, `PhuXe` |
| `LuotQuetThe` | Card scan and amount charged | `MaLuotQuet` | `Tram` (entry, exit), `TheVeDienTu`, `Tuyen`, `ChuyenXe` |
