# Data dictionary

Tables of the project database `QuanLyTheVeDienTu`. Column types, keys and constraints are defined in [`database/schema/02_tables.sql`](../database/schema/02_tables.sql). The coursework version (without `GiaVe` and `GiaoDich.MaGiaoDichGoc`) is in [`agm/`](../agm/).

| Table | Purpose | Primary key | References |
|---|---|---|---|
| `HanhKhach` | Passenger and passenger category | `MaHanhKhach` | — |
| `LoaiThe` | Card product, price and validity period | `MaLoaiThe` | — |
| `TheVeDienTu` | Issued card, wallet balance, expiry and lock status | `MaTheDienTu` | `LoaiThe`, `HanhKhach` |
| `GiaoDich` | Top-up, monthly-pass purchase or refund; a refund points to the top-up it refunds | `MaGiaoDich` | `TheVeDienTu`, `GiaoDich` (original top-up) |
| `Tram` | Bus stop or metro station | `MaTram` | — |
| `Tuyen` | Bus or metro route | `MaTuyen` | — |
| `TuyenTram` | Station on a route and its stop order | `MaTuyen, MaTram` | `Tuyen`, `Tram` |
| `GiaVe` | Fare rule per transport type: base fare, per-station fare, maximum | `LoaiPhuongTien` | — |
| `XeBuyt` | Bus and its operating status | `MaXe` | — |
| `NhanVien` | Common staff data | `MaNhanVien` | — |
| `TaiXe` | Driver and driving licence | `MaNhanVien` | `NhanVien` |
| `PhuXe` | Bus attendant | `MaNhanVien` | `NhanVien` |
| `LichChay` | Timetable entry: direction, departure time, service days | `MaLich` | `Tuyen` |
| `ChuyenXe` | Bus run on a date, with bus, driver and attendant | `MaChuyen` | `LichChay`, `XeBuyt`, `TaiXe`, `PhuXe` |
| `LuotQuetThe` | Card scan and amount charged | `MaLuotQuet` | `Tram` (entry, exit), `TheVeDienTu`, `Tuyen`, `ChuyenXe` |
