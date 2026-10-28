# Database design overview

## Purpose

The database models electronic transit cards and their use across bus and metro services.

## Main entity groups

### Passengers and cards
- `HanhKhach`: passenger identity and passenger category.
- `LoaiThe`: card/product type.
- `TheVeDienTu`: electronic card, balance, status, expiry, passenger and card type.

### Financial activity
- `GiaoDich`: top-ups, monthly-package purchases and refunds.
- `LuotQuetThe`: card validation/use event, including entry/exit station, time, charged amount, transport type and optional route/trip.

### Transport network
- `Tram`: station/stop.
- `Tuyen`: route.
- `TuyenTram`: ordered stops along a route.
- `LichChay`: route direction and scheduled departure.
- `ChuyenXe`: scheduled bus trip, vehicle and assigned staff.
- `XeBuyt`: bus fleet.

### Staff
- `NhanVien`: common staff information.
- `TaiXe`: driver-specific information.
- `PhuXe`: bus-attendant specialization.

## Design review notes

These are review items, not confirmed defects:

1. `LoaiThe.SoNgayHieuLuc` is nullable, while its check constraint requires values to be positive when present. Confirm which card products may have no fixed expiry.
2. `ChuyenXe` requires a bus, driver and attendant, while `LichChay` references the generic `Tuyen` table that allows both BUS and METRO. Confirm that `ChuyenXe` is intentionally bus-only.
3. `LuotQuetThe` has foreign keys to station and route, but foreign keys alone do not guarantee that the station belongs to the selected route or matches the transport type.
4. `GiaoDich` records a refund type but has no explicit reference to the original transaction. Decide whether refund traceability is required by the assignment.
5. Business rules such as balance updates, duplicate validations and transaction consistency need to be enforced by a documented application/SQL mechanism if they are in scope.

Do not change the schema based only on these notes. Compare proposed changes with the assignment requirements and existing diagrams first.
