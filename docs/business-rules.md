# Business rules

How the stored procedures in [`database/procedures/`](../database/procedures/) operate the card system. Balances, pass expiry dates, transactions and scans are changed only through these procedures.

## Operations

| Procedure | Operation |
|---|---|
| `usp_PhatHanhThe` | Issue a card of a given type to a passenger |
| `usp_KhoaThe` | Lock or unlock a card |
| `usp_NapTien` | Top up the wallet |
| `usp_MuaGoiThang` | Buy or renew a monthly pass |
| `usp_HoanTien` | Refund a top-up |
| `usp_QuetTheXeBuyt` | Scan a card when boarding a bus |
| `usp_QuetVaoMetro` | Tap in at a metro station |
| `usp_QuetRaMetro` | Tap out at a metro station and pay the fare |

Every procedure that changes money runs in a single transaction and locks the card row first, so the transaction or scan record and the card's balance always change together, and two operations on the same card are applied one after the other. Identifiers are generated from sequences: `TH…` for cards, `GD…` for transactions, `LQ…` for scans.

## Cards

- Every card has a wallet (`SoDuVi`), starting at 0. Pass products (`THANG_BUS`, `THANG_METRO`, `LIEN_THONG`) also carry a pass expiry date (`NgayHetHan`).
- A locked card cannot be topped up, buy a pass or be scanned. Its balance is kept, and its top-ups can still be refunded (e.g. a lost card).

## Payments

- **Top-up:** amount > 0, paid by cash, VNPay, MoMo or bank transfer.
- **Monthly pass:** costs `LoaiThe.GiaBan` and lasts `LoaiThe.SoNgayHieuLuc` days, paid by an external method (not from the wallet). A pass that is still valid is extended from the day after it expires; otherwise the new period starts on the purchase day. The stored-value card `VE_LUOT` has no pass.
- **Refund:** only top-ups can be refunded, in full, to the original payment method, at most once, and only while the wallet still holds the amount. Monthly passes are not refundable.

## Fares

A ride is free when the card has a valid pass for that transport type on the day of travel: `THANG_BUS` covers the bus, `THANG_METRO` the metro, `LIEN_THONG` both. Otherwise the fare is taken from the wallet, and the scan is refused if the wallet cannot cover it.

Fares come from table `GiaVe`: `GiaCoBan + GiaMoiGa × stations travelled`, capped at `GiaToiDa`. With the sample data, the bus costs a flat 7,000 VND and the metro 8,000 VND plus 700 VND per station, at most 15,000 VND.

### Bus

One scan when boarding. The trip must be running (`DANG_CHAY`) on the day of the scan, its timetable must belong to a bus route, the stop must be on that route, and a card can be scanned only once per trip.

### Metro

- **Tap in:** the station must be a metro station, and the card must not have a journey that was not tapped out. Without a valid metro pass, the wallet must hold at least the minimum fare. Nothing is charged yet.
- **Tap out:** closes the open journey. Entry and exit stations must be on the same metro line; the fare depends on the number of stations between them (exiting at the entry station costs the minimum fare). Pass coverage is decided on the day of entry. If the wallet cannot cover the fare, the exit is refused and the journey stays open until the card is topped up.

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
| 50014 | Card already has an open metro journey |
| 50015 | Card has no open metro journey |
| 50016 | Entry and exit stations are not on the same metro line |
| 50017 | Invalid time (exit before entry, refund before top-up) |
| 50018 | Passenger does not exist |
| 50019 | Card type does not exist |
| 50020 | Bus trip is not on a bus route |
| 50021 | No fare configured for the transport type |
| 50022 | Invalid lock status (must be 0 or 1) |

## Not covered yet

- Transfers between metro lines in one journey.
- Fare discounts by passenger category (`NhomDoiTuong`).
- Closing journeys that were never tapped out (penalty fare or staff correction).
- Rejecting timetable entries on metro routes when they are inserted; today such a trip is only refused at scan time (50020).
