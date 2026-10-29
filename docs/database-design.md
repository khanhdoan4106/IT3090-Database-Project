# Database design

## Purpose

The database models electronic transit cards and their use across Hanoi's bus and metro services: who holds a card, how money enters the card, and every time the card is scanned on a bus or at a metro gate.

## Entity groups

### Passengers and cards
- `UuDaiDoiTuong`: discount per passenger category.
- `HanhKhach`: passenger identity and passenger category (standard, student, senior).
- `LoaiThe`: card product (single-ride wallet, monthly bus, monthly metro, combined pass) with its price and validity period.
- `TheVeDienTu`: an issued card, with its wallet balance, expiry date, lock status and, for a replacement card, the card it replaces.

### Money and usage
- `GiaoDich`: top-ups, monthly-pass purchases and refunds; a refund references the top-up it refunds.
- `LuotQuetThe`: one card scan, with entry station and time, exit station and time (metro only), amount charged, status, and the route and bus trip when known.

### Transport network
- `Tram`: bus stop or metro station.
- `Tuyen`: bus or metro route.
- `TuyenTram`: stations on a route and their order.
- `GiaVe`: fare rule per transport type (base fare, amount per station travelled, maximum).

### Bus operations
- `LichChay`: recurring timetable entry for a route (direction, departure time, service days).
- `ChuyenXe`: one actual bus run on a given day, with its bus, driver and attendant.
- `XeBuyt`: bus fleet.
- `NhanVien`: common staff data, specialised into `TaiXe` (driver, with licence details) and `PhuXe` (bus attendant).

## Design decisions

- **Wallet and pass cards share one table.** `NgayHetHan` and `LoaiThe.SoNgayHieuLuc` are `NULL` for wallet cards, which do not expire.
- **Only buses have trips.** A metro scan has no `MaChuyen`; this is enforced by `CHECK(LoaiPhuongTien = 'BUS' OR MaChuyen IS NULL)`.
- **Metro scans record both entry and exit**, because metro fares depend on distance; bus scans record entry only. Exit station and exit time are either both present or both `NULL`.
- **Timetable and actual run are separate.** `LichChay` is the template; `ChuyenXe` is what actually ran on a date, and each timetable entry runs at most once per day.
- **Drivers and attendants are specialisations of staff**, sharing `NhanVien`'s primary key.
- **A metro journey has a status.** `DANG_DI` while in progress, `HOAN_THANH` once tapped out, `KHONG_QUET_RA` when closed with a penalty; a filtered unique index allows one journey in progress per card.
- **Metro fares follow the network, not a single line.** The number of stations travelled is the shortest path over adjacent stations of all metro lines, so a journey can change lines where they share a station.
- **Discounts are data.** Percentages per passenger category live in `UuDaiDoiTuong`, so a policy change needs no code change.
- **A replacement card keeps the history traceable.** The new card points to the old one, and the moved balance is recorded as a linked pair of transactions on both cards.

Diagrams: [ERD](../agm/diagrams/so_do_thuc_the_lien_ket.png) · [relational schema](../agm/diagrams/so_do_quan_he.png).
