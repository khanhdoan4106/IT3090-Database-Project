/* =====================================================================
   03_indexes_sequences.sql
   Sequences for generated identifiers, rule-enforcing unique indexes,
   and indexes for the main lookups.
   ===================================================================== */

USE QuanLyTheVeDienTu;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------- Sequences ----------
   Identifiers created by the procedures: a 2-letter prefix followed by a
   10-digit number, e.g. TH0000000001, GD0000000001, LQ0000000001. */

CREATE SEQUENCE dbo.seq_TheVeDienTu AS bigint START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE dbo.seq_GiaoDich    AS bigint START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE dbo.seq_LuotQuetThe AS bigint START WITH 1 INCREMENT BY 1;
GO

/* ---------- Unique indexes enforcing business rules ---------- */

-- A citizen ID belongs to at most one passenger; passengers without one are allowed.
CREATE UNIQUE INDEX uix_HanhKhach_SoCCCD
    ON HanhKhach(SoCCCD) WHERE SoCCCD IS NOT NULL;

-- A top-up can be refunded at most once.
CREATE UNIQUE INDEX uix_GiaoDich_MaGiaoDichGoc
    ON GiaoDich(MaGiaoDichGoc) WHERE MaGiaoDichGoc IS NOT NULL;

-- A card has at most one metro journey that has not been tapped out.
CREATE UNIQUE INDEX uix_LuotQuetThe_MetroDangMo
    ON LuotQuetThe(MaTheDienTu)
    WHERE LoaiPhuongTien = 'METRO' AND MaTramQuetRa IS NULL;

-- A card is scanned at most once per bus trip.
CREATE UNIQUE INDEX uix_LuotQuetThe_The_Chuyen
    ON LuotQuetThe(MaTheDienTu, MaChuyen) WHERE MaChuyen IS NOT NULL;

/* ---------- Indexes for frequent lookups ---------- */

-- Card history: scans and transactions of one card, newest first.
CREATE INDEX ix_LuotQuetThe_The_ThoiDiem ON LuotQuetThe(MaTheDienTu, ThoiDiemQuetVao);
CREATE INDEX ix_GiaoDich_The_ThoiDiem    ON GiaoDich(MaTheDienTu, ThoiDiemGiaoDich);

-- Cards of a passenger.
CREATE INDEX ix_TheVeDienTu_HanhKhach ON TheVeDienTu(MaHanhKhach);

-- Routes passing through a station (the primary key covers route -> stations).
CREATE INDEX ix_TuyenTram_Tram ON TuyenTram(MaTram);

-- Ridership reports by route and by period.
CREATE INDEX ix_LuotQuetThe_Tuyen_ThoiDiem ON LuotQuetThe(MaTuyen, ThoiDiemQuetVao);
GO
