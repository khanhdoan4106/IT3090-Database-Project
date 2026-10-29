# Data dictionary

Tables of the project database `QuanLyTheVeDienTu`. Column types, keys and constraints are defined in [`database/schema/02_tables.sql`](../database/schema/02_tables.sql). The coursework version, without the project's additions, is in [`agm/`](../agm/).

| Table | Purpose | Primary key | References |
|---|---|---|---|
| `UuDaiDoiTuong` | Discounts per passenger category: on rides and on monthly passes | `NhomDoiTuong` | — |
| `HanhKhach` | Passenger and passenger category | `MaHanhKhach` | `UuDaiDoiTuong` |
| `LoaiThe` | Card product, price and validity period | `MaLoaiThe` | — |
| `TheVeDienTu` | Issued card, wallet balance, expiry and lock status; a replacement card points to the card it replaces | `MaTheDienTu` | `LoaiThe`, `HanhKhach`, `TheVeDienTu` (replaced card) |
| `GiaoDich` | Top-up, monthly-pass purchase, refund, or balance moved to a replacement card | `MaGiaoDich` | `TheVeDienTu`, `GiaoDich` (refunded top-up or sent balance) |
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
| `LuotQuetThe` | Card scan or metro journey, its status and the amount charged | `MaLuotQuet` | `Tram` (entry, exit), `TheVeDienTu`, `Tuyen`, `ChuyenXe` |
