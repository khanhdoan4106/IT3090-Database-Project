# Business rules

How the stored procedures in [`database/procedures/`](../database/procedures/) operate the card system. Balances, pass expiry dates, transactions, scans and trip statuses are changed only through these procedures.

## Operations

| Area | Procedure | Operation |
|---|---|---|
| Cards | `usp_PhatHanhThe` | Issue a card of a given type to a passenger |
| | `usp_KhoaThe` | Lock or unlock a card |
| | `usp_DoiThe` | Replace a lost or damaged card, moving its balance and pass |
| Payments | `usp_NapTien` | Top up the wallet |
| | `usp_MuaGoiThang` | Buy or renew a monthly pass |
| | `usp_HoanTien` | Refund a top-up |
| Scans | `usp_QuetTheXeBuyt` | Scan a card when boarding a bus |
| | `usp_QuetVaoMetro` | Tap in at a metro station |
| | `usp_QuetRaMetro` | Tap out at a metro station and pay the fare |
| | `usp_DongHanhTrinhMetro` | Staff: close a card's open metro journey with a penalty |
| | `usp_DongHanhTrinhQuaHan` | Nightly job: close every open journey from earlier days with a penalty |
| Bus operations | `usp_TaoChuyenXe` | Create a trip from a timetable entry |
| | `usp_CapNhatTrangThaiChuyen` | Start, cancel or complete a trip |

Every procedure that changes money runs in a single transaction and locks the card row first, so the transaction or scan record and the card's balance always change together, and two operations on the same card are applied one after the other. Identifiers are generated from sequences: `TH…` for cards, `GD…` for transactions, `LQ…` for scans. Trips are identified by `CX` + date + timetable entry, e.g. `CX20261031L32V0700`.

## Cards

- Every card has a wallet (`SoDuVi`), starting at 0. Pass products (`THANG_BUS`, `THANG_METRO`, `LIEN_THONG`) also carry a pass expiry date (`NgayHetHan`).
- A locked card cannot be topped up, buy a pass or be scanned. Its balance is kept, and its top-ups can still be refunded.
- **Replacement:** a lost or damaged card is replaced by a new card of the same type for the same passenger. The balance and the pass expiry move to the new card, and the old card is locked for good: it cannot be unlocked or replaced again. A non-zero balance is recorded as a `CHUYEN_DI` transaction on the old card and a `CHUYEN_DEN` transaction on the new one, linked to each other. A card with a metro journey in progress must have it closed first.

## Payments

- **Top-up:** amount > 0, paid by cash, VNPay, MoMo or bank transfer.
- **Monthly pass:** costs `LoaiThe.GiaBan` less the passenger category's pass discount and lasts `LoaiThe.SoNgayHieuLuc` days, paid by an external method (not from the wallet). A pass that is still valid is extended from the day after it expires; otherwise the new period starts on the purchase day. The stored-value card `VE_LUOT` has no pass.
- **Refund:** only top-ups can be refunded, in full, to the original payment method, at most once, and only while the wallet still holds the amount. Monthly passes are not refundable.

## Fares

A ride is free when the card has a valid pass for that transport type on the day of travel: `THANG_BUS` covers the bus, `THANG_METRO` the metro, `LIEN_THONG` both. Otherwise the fare is taken from the wallet, and the scan is refused if the wallet cannot cover it.

Fares come from table `GiaVe`: `GiaCoBan + GiaMoiGa × stations travelled`, capped at `GiaToiDa`, then reduced by the passenger category's per-ride discount from `UuDaiDoiTuong` and rounded to the nearest 100 VND. With the sample data, the bus costs a flat 7,000 VND and the metro 8,000 VND plus 700 VND per station, at most 15,000 VND; seniors get 50% off rides, and students and seniors 50% off monthly passes.

### Bus

One scan when boarding. The trip must be running (`DANG_CHAY`) on the day of the scan, the stop must be on the trip's route, and a card can be scanned only once per trip.

### Metro

- **Tap in:** the station must be a metro station. Without a valid metro pass, the wallet must hold at least the minimum fare after discount. Nothing is charged yet.
- **Tap out:** closes the journey in progress. The fare counts the stations on the shortest path through the metro network; passengers change lines where two lines share a station. A journey on a single line is recorded on that line; a journey that changed lines has no single line (`MaTuyen` NULL). Pass coverage is decided on the day of entry. If the wallet cannot cover the fare, the exit is refused and the journey stays open until the card is topped up.

### Journeys never tapped out

A card has at most one journey in progress (`TrangThai = 'DANG_DI'`). A journey that is never tapped out is closed with a penalty: the maximum metro fare less the per-ride discount, nothing if a metro pass covered the day of entry, and never more than the wallet holds. The journey keeps no exit station and gets status `KHONG_QUET_RA`. This happens:

- automatically at the next tap-in, when the open journey started on an earlier day (a same-day open journey refuses the new tap-in instead);
- when staff close it (`usp_DongHanhTrinhMetro`), e.g. a card lost during the journey or before it is replaced;
- in the nightly job (`usp_DongHanhTrinhQuaHan`) for every journey from an earlier day.

## Bus operations

- A timetable entry (`LichChay`) can only belong to a bus route; this is enforced by a trigger on insert and update.
- **Creating a trip:** the date must match the entry's service days (`NGAY_THUONG` Monday–Friday, `CUOI_TUAN` Saturday–Sunday, `HANG_NGAY` every day), the bus must be in service (`HOAT_DONG`), the driver must be a `TaiXe` and the attendant a `PhuXe`, and each entry runs at most once per day. A new trip starts as `CHUA_CHAY`.
- **Trip status:** `CHUA_CHAY → DANG_CHAY` (departure; the bus must be in service), `CHUA_CHAY → HUY` (cancelled) and `DANG_CHAY → HOAN_THANH` (arrived). No other change is allowed.

## Reports

Views in [`database/views/01_bao_cao.sql`](../database/views/01_bao_cao.sql):

| View | Contents |
|---|---|
| `v_DoanhThuTheoNgay` | Per day: top-ups, refunds, passes sold, fares, penalties, and revenue (passes + fares + penalties) |
| `v_LuotDiTheoTuyen` | Completed rides and fares per day and route; line-changing metro journeys grouped as "Liên tuyến metro" |
| `v_LuotVaoTheoGa` | Entries per station, day and hour |
| `v_TinhTrangThe` | Each card's owner, product, balance, pass status today, lock and replacement status, last use |
| `v_DoiSoatSoDu` | Balance audit: stored balance against the balance rebuilt from history; `ChenhLech` must be 0 |

## Error codes

Business errors are raised with `THROW` and the codes below; the message is in Vietnamese for display to passengers and staff.

| Code | Meaning |
|---|---|
| 50001 | Card does not exist |
| 50002 | Card is locked |
| 50003 | Amount must be greater than 0 |
| 50004 | Invalid payment method |
| 50005 | Card type has no monthly pass |
| 50006 | Original transaction does not exist |
| 50007 | Only top-ups can be refunded |
| 50008 | Transaction already refunded |
| 50009 | Insufficient wallet balance |
| 50010 | Bus trip does not exist or is not running at the scan time |
| 50011 | Stop is not on the trip's route |
| 50012 | Card already scanned on this trip |
| 50013 | Station is not a metro station |
| 50014 | Card already has a metro journey in progress today |
| 50015 | Card has no metro journey in progress |
| 50016 | Entry and exit stations are not connected by the metro network |
| 50017 | Invalid time (exit before entry, refund before top-up) |
| 50018 | Passenger does not exist |
| 50019 | Card type does not exist |
| 50020 | Timetable entry or trip is not on a bus route |
| 50021 | No fare configured for the transport type |
| 50022 | Invalid lock status (must be 0 or 1) |
| 50023 | Card has a metro journey in progress and cannot be replaced |
| 50024 | Card has already been replaced |
| 50026 | Timetable entry does not exist |
| 50027 | Trip date is not a service day of the timetable entry |
| 50028 | Bus does not exist or is not in service |
| 50029 | Invalid driver or attendant |
| 50030 | Trip status change not allowed |
| 50031 | Timetable entry already has a trip on that day |
| 50033 | Internal procedure called outside a transaction |

## Not covered

- Proof of eligibility for student and senior discounts is checked at the counter, outside the database.
- The penalty never takes the wallet below zero; a balance shortfall is not carried as debt.
