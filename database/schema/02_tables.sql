/* =====================================================================
   02_tables.sql
   Tables of the project schema (v2).

   Starts from the coursework schema in agm/ with these changes:
   - GiaVe (new): fare rules per transport type, used to compute the
     amount charged for each scan.
   - GiaoDich.MaGiaoDichGoc (new): links a refund to the top-up it refunds,
     and a balance received by a replacement card to the balance sent.
   - GiaoDich.LoaiGiaoDich: CHUYEN_DI / CHUYEN_DEN record a balance moved to
     a replacement card; they have no payment method.
   - UuDaiDoiTuong (new): discount per passenger category.
   - TheVeDienTu.MaTheCu (new): the card a replacement card replaces.
   - LuotQuetThe.TrangThai (new): journey status, so that a metro journey
     that was never tapped out can be closed with a penalty fare.
   - TaiXe.HangGPLX: licence classes D1, D2, D (Road Traffic Order and
     Safety Law, in force from 2025-01-01) and E (licences issued earlier).
   - Defaults for balances, lock status and statuses; every constraint is named.
   ===================================================================== */

USE QuanLyTheVeDienTu;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------- Passengers and cards ---------- */

-- Discount (percent) per passenger category: on each ride paid from the
-- wallet, and on monthly passes. A pass is never free (< 100).
CREATE TABLE UuDaiDoiTuong(
    NhomDoiTuong          varchar(20)   NOT NULL,
    TenNhom               nvarchar(50)  NOT NULL,
    PhanTramGiamVeLuot    tinyint       NOT NULL CONSTRAINT df_UuDaiDoiTuong_VeLuot DEFAULT 0,
    PhanTramGiamGoiThang  tinyint       NOT NULL CONSTRAINT df_UuDaiDoiTuong_GoiThang DEFAULT 0,
    CONSTRAINT pk_UuDaiDoiTuong PRIMARY KEY(NhomDoiTuong),
    CONSTRAINT ck_UuDaiDoiTuong_NhomDoiTuong
        CHECK(NhomDoiTuong IN ('TIEU_CHUAN', 'HSSV', 'NGUOI_CAO_TUOI')),
    CONSTRAINT ck_UuDaiDoiTuong_VeLuot   CHECK(PhanTramGiamVeLuot <= 100),
    CONSTRAINT ck_UuDaiDoiTuong_GoiThang CHECK(PhanTramGiamGoiThang < 100)
);

CREATE TABLE HanhKhach(
    MaHanhKhach  varchar(10)   NOT NULL,
    HoTen        nvarchar(50)  NOT NULL,
    SoCCCD       char(12)      NULL,
    SoDienThoai  varchar(15)   NULL,
    NhomDoiTuong varchar(20)   NOT NULL
        CONSTRAINT df_HanhKhach_NhomDoiTuong DEFAULT 'TIEU_CHUAN',
    CONSTRAINT pk_HanhKhach PRIMARY KEY(MaHanhKhach),
    CONSTRAINT fk_HanhKhach_UuDaiDoiTuong
        FOREIGN KEY(NhomDoiTuong) REFERENCES UuDaiDoiTuong(NhomDoiTuong),
    CONSTRAINT ck_HanhKhach_NhomDoiTuong
        CHECK(NhomDoiTuong IN ('TIEU_CHUAN', 'HSSV', 'NGUOI_CAO_TUOI'))
);

-- GiaBan: price of one validity period for pass products (THANG_*, LIEN_THONG);
--         0 for the stored-value card VE_LUOT.
-- SoNgayHieuLuc: length of one validity period; NULL for VE_LUOT (no expiry).
CREATE TABLE LoaiThe(
    MaLoaiThe     varchar(20)   NOT NULL,
    TenLoaiThe    nvarchar(50)  NOT NULL,
    GiaBan        numeric(12,0) NOT NULL,
    SoNgayHieuLuc int           NULL,
    CONSTRAINT pk_LoaiThe PRIMARY KEY(MaLoaiThe),
    CONSTRAINT ck_LoaiThe_MaLoaiThe
        CHECK(MaLoaiThe IN ('VE_LUOT', 'THANG_BUS', 'THANG_METRO', 'LIEN_THONG')),
    CONSTRAINT ck_LoaiThe_GiaBan CHECK(GiaBan >= 0),
    CONSTRAINT ck_LoaiThe_SoNgayHieuLuc CHECK(SoNgayHieuLuc > 0)
);

-- NgayHetHan: last day the pass is valid; NULL when no pass has been bought.
-- MaTheCu: for a replacement card, the lost or damaged card it replaces.
-- SoDuVi is changed only by the stored procedures (see docs/business-rules.md).
CREATE TABLE TheVeDienTu(
    MaTheDienTu varchar(20)   NOT NULL,
    SoDuVi      numeric(12,0) NOT NULL CONSTRAINT df_TheVeDienTu_SoDuVi DEFAULT 0,
    NgayHetHan  date          NULL,
    BiKhoa      smallint      NOT NULL CONSTRAINT df_TheVeDienTu_BiKhoa DEFAULT 0,
    MaLoaiThe   varchar(20)   NOT NULL,
    MaHanhKhach varchar(10)   NOT NULL,
    MaTheCu     varchar(20)   NULL,
    CONSTRAINT pk_TheVeDienTu PRIMARY KEY(MaTheDienTu),
    CONSTRAINT fk_TheVeDienTu_LoaiThe   FOREIGN KEY(MaLoaiThe)   REFERENCES LoaiThe(MaLoaiThe),
    CONSTRAINT fk_TheVeDienTu_HanhKhach FOREIGN KEY(MaHanhKhach) REFERENCES HanhKhach(MaHanhKhach),
    CONSTRAINT fk_TheVeDienTu_TheCu     FOREIGN KEY(MaTheCu)     REFERENCES TheVeDienTu(MaTheDienTu),
    CONSTRAINT ck_TheVeDienTu_TheCu CHECK(MaTheCu <> MaTheDienTu),
    CONSTRAINT ck_TheVeDienTu_SoDuVi CHECK(SoDuVi >= 0),
    CONSTRAINT ck_TheVeDienTu_BiKhoa CHECK(BiKhoa IN (0, 1))
);

-- MaGiaoDichGoc: for HOAN_TIEN, the top-up being refunded; for CHUYEN_DEN,
--                the CHUYEN_DI it receives; NULL otherwise.
-- PhuongThucThanhToan: NULL only for balance transfers (CHUYEN_DI, CHUYEN_DEN).
CREATE TABLE GiaoDich(
    MaGiaoDich          varchar(20)   NOT NULL,
    LoaiGiaoDich        varchar(20)   NOT NULL,
    SoTien              numeric(12,0) NOT NULL,
    ThoiDiemGiaoDich    datetime      NOT NULL,
    PhuongThucThanhToan varchar(20)   NULL,
    MaTheDienTu         varchar(20)   NOT NULL,
    MaGiaoDichGoc       varchar(20)   NULL,
    CONSTRAINT pk_GiaoDich PRIMARY KEY(MaGiaoDich),
    CONSTRAINT fk_GiaoDich_TheVeDienTu FOREIGN KEY(MaTheDienTu)   REFERENCES TheVeDienTu(MaTheDienTu),
    CONSTRAINT fk_GiaoDich_GiaoDichGoc FOREIGN KEY(MaGiaoDichGoc) REFERENCES GiaoDich(MaGiaoDich),
    CONSTRAINT ck_GiaoDich_LoaiGiaoDich
        CHECK(LoaiGiaoDich IN ('NAP_TIEN', 'MUA_GOI_THANG', 'HOAN_TIEN',
                               'CHUYEN_DI', 'CHUYEN_DEN')),
    CONSTRAINT ck_GiaoDich_PhuongThucThanhToan
        CHECK(PhuongThucThanhToan IN ('TIEN_MAT', 'VNPAY', 'MOMO', 'NGAN_HANG')),
    CONSTRAINT ck_GiaoDich_SoTien CHECK(SoTien > 0),
    CONSTRAINT ck_GiaoDich_CoPhuongThuc
        CHECK((LoaiGiaoDich IN ('CHUYEN_DI', 'CHUYEN_DEN') AND PhuongThucThanhToan IS NULL)
           OR (LoaiGiaoDich NOT IN ('CHUYEN_DI', 'CHUYEN_DEN') AND PhuongThucThanhToan IS NOT NULL)),
    CONSTRAINT ck_GiaoDich_MaGiaoDichGoc
        CHECK((LoaiGiaoDich IN ('HOAN_TIEN', 'CHUYEN_DEN') AND MaGiaoDichGoc IS NOT NULL)
           OR (LoaiGiaoDich NOT IN ('HOAN_TIEN', 'CHUYEN_DEN') AND MaGiaoDichGoc IS NULL))
);

/* ---------- Transport network and fares ---------- */

CREATE TABLE Tram(
    MaTram         varchar(10)   NOT NULL,
    TenTram        nvarchar(100) NOT NULL,
    LoaiPhuongTien varchar(10)   NOT NULL,
    CONSTRAINT pk_Tram PRIMARY KEY(MaTram),
    CONSTRAINT ck_Tram_LoaiPhuongTien CHECK(LoaiPhuongTien IN ('BUS', 'METRO'))
);

CREATE TABLE Tuyen(
    MaTuyen        varchar(10)   NOT NULL,
    TenTuyen       nvarchar(100) NOT NULL,
    LoaiPhuongTien varchar(10)   NOT NULL,
    CONSTRAINT pk_Tuyen PRIMARY KEY(MaTuyen),
    CONSTRAINT ck_Tuyen_LoaiPhuongTien CHECK(LoaiPhuongTien IN ('BUS', 'METRO'))
);

CREATE TABLE TuyenTram(
    MaTuyen   varchar(10) NOT NULL,
    MaTram    varchar(10) NOT NULL,
    ThuTuTram smallint    NOT NULL,
    CONSTRAINT pk_TuyenTram PRIMARY KEY(MaTuyen, MaTram),
    CONSTRAINT fk_TuyenTram_Tuyen FOREIGN KEY(MaTuyen) REFERENCES Tuyen(MaTuyen),
    CONSTRAINT fk_TuyenTram_Tram  FOREIGN KEY(MaTram)  REFERENCES Tram(MaTram),
    CONSTRAINT uq_TuyenTram_ThuTuTram UNIQUE(MaTuyen, ThuTuTram),
    CONSTRAINT ck_TuyenTram_ThuTuTram CHECK(ThuTuTram > 0)
);

-- Fare of one ride = GiaCoBan + GiaMoiGa * (number of stations travelled),
-- capped at GiaToiDa when it is set. Bus fares are flat (GiaMoiGa = 0).
CREATE TABLE GiaVe(
    LoaiPhuongTien varchar(10)   NOT NULL,
    GiaCoBan       numeric(12,0) NOT NULL,
    GiaMoiGa       numeric(12,0) NOT NULL CONSTRAINT df_GiaVe_GiaMoiGa DEFAULT 0,
    GiaToiDa       numeric(12,0) NULL,
    CONSTRAINT pk_GiaVe PRIMARY KEY(LoaiPhuongTien),
    CONSTRAINT ck_GiaVe_LoaiPhuongTien CHECK(LoaiPhuongTien IN ('BUS', 'METRO')),
    CONSTRAINT ck_GiaVe_GiaCoBan CHECK(GiaCoBan >= 0),
    CONSTRAINT ck_GiaVe_GiaMoiGa CHECK(GiaMoiGa >= 0),
    CONSTRAINT ck_GiaVe_GiaToiDa CHECK(GiaToiDa IS NULL OR GiaToiDa >= GiaCoBan)
);

/* ---------- Bus operations ---------- */

CREATE TABLE XeBuyt(
    MaXe      varchar(10) NOT NULL,
    BienSo    varchar(15) NOT NULL,
    SoChoNgoi smallint    NOT NULL,
    TrangThai varchar(20) NOT NULL CONSTRAINT df_XeBuyt_TrangThai DEFAULT 'HOAT_DONG',
    CONSTRAINT pk_XeBuyt PRIMARY KEY(MaXe),
    CONSTRAINT uq_XeBuyt_BienSo UNIQUE(BienSo),
    CONSTRAINT ck_XeBuyt_SoChoNgoi CHECK(SoChoNgoi > 0),
    CONSTRAINT ck_XeBuyt_TrangThai CHECK(TrangThai IN ('HOAT_DONG', 'BAO_TRI', 'NGUNG'))
);

CREATE TABLE NhanVien(
    MaNhanVien  varchar(10)  NOT NULL,
    HoTen       nvarchar(50) NOT NULL,
    SoDienThoai varchar(15)  NULL,
    CONSTRAINT pk_NhanVien PRIMARY KEY(MaNhanVien)
);

CREATE TABLE TaiXe(
    MaNhanVien varchar(10) NOT NULL,
    SoGPLX     varchar(20) NOT NULL,
    HangGPLX   varchar(2)  NOT NULL,
    CONSTRAINT pk_TaiXe PRIMARY KEY(MaNhanVien),
    CONSTRAINT fk_TaiXe_NhanVien FOREIGN KEY(MaNhanVien) REFERENCES NhanVien(MaNhanVien),
    CONSTRAINT uq_TaiXe_SoGPLX UNIQUE(SoGPLX),
    CONSTRAINT ck_TaiXe_HangGPLX CHECK(HangGPLX IN ('D1', 'D2', 'D', 'E'))
);

CREATE TABLE PhuXe(
    MaNhanVien varchar(10) NOT NULL,
    CONSTRAINT pk_PhuXe PRIMARY KEY(MaNhanVien),
    CONSTRAINT fk_PhuXe_NhanVien FOREIGN KEY(MaNhanVien) REFERENCES NhanVien(MaNhanVien)
);

CREATE TABLE LichChay(
    MaLich        varchar(10) NOT NULL,
    ChieuDi       varchar(10) NOT NULL,
    GioXuatBen    time(0)     NOT NULL,
    NgayTrongTuan varchar(15) NOT NULL,
    MaTuyen       varchar(10) NOT NULL,
    CONSTRAINT pk_LichChay PRIMARY KEY(MaLich),
    CONSTRAINT fk_LichChay_Tuyen FOREIGN KEY(MaTuyen) REFERENCES Tuyen(MaTuyen),
    CONSTRAINT ck_LichChay_ChieuDi CHECK(ChieuDi IN ('LUOT_DI', 'LUOT_VE')),
    CONSTRAINT ck_LichChay_NgayTrongTuan
        CHECK(NgayTrongTuan IN ('NGAY_THUONG', 'CUOI_TUAN', 'HANG_NGAY'))
);

CREATE TABLE ChuyenXe(
    MaChuyen  varchar(20) NOT NULL,
    NgayChay  date        NOT NULL,
    TrangThai varchar(20) NOT NULL CONSTRAINT df_ChuyenXe_TrangThai DEFAULT 'CHUA_CHAY',
    MaLich    varchar(10) NOT NULL,
    MaXe      varchar(10) NOT NULL,
    MaTaiXe   varchar(10) NOT NULL,
    MaPhuXe   varchar(10) NOT NULL,
    CONSTRAINT pk_ChuyenXe PRIMARY KEY(MaChuyen),
    CONSTRAINT fk_ChuyenXe_LichChay FOREIGN KEY(MaLich)  REFERENCES LichChay(MaLich),
    CONSTRAINT fk_ChuyenXe_XeBuyt   FOREIGN KEY(MaXe)    REFERENCES XeBuyt(MaXe),
    CONSTRAINT fk_ChuyenXe_TaiXe    FOREIGN KEY(MaTaiXe) REFERENCES TaiXe(MaNhanVien),
    CONSTRAINT fk_ChuyenXe_PhuXe    FOREIGN KEY(MaPhuXe) REFERENCES PhuXe(MaNhanVien),
    CONSTRAINT uq_ChuyenXe_MaLich_NgayChay UNIQUE(MaLich, NgayChay),
    CONSTRAINT ck_ChuyenXe_TrangThai
        CHECK(TrangThai IN ('CHUA_CHAY', 'DANG_CHAY', 'HOAN_THANH', 'HUY')),
    CONSTRAINT ck_ChuyenXe_NhanSu CHECK(MaTaiXe <> MaPhuXe)
);

/* ---------- Card scans ---------- */

-- TrangThai: DANG_DI     metro journey tapped in, not yet tapped out;
--            HOAN_THANH  bus scan, or metro journey tapped out;
--            KHONG_QUET_RA metro journey never tapped out, closed with a
--                        penalty fare (no exit station).
CREATE TABLE LuotQuetThe(
    MaLuotQuet      varchar(20)   NOT NULL,
    LoaiPhuongTien  varchar(10)   NOT NULL,
    MaTramQuetVao   varchar(10)   NOT NULL,
    ThoiDiemQuetVao datetime      NOT NULL,
    MaTramQuetRa    varchar(10)   NULL,
    ThoiDiemQuetRa  datetime      NULL,
    SoTienDaTru     numeric(12,0) NOT NULL CONSTRAINT df_LuotQuetThe_SoTienDaTru DEFAULT 0,
    MaTheDienTu     varchar(20)   NOT NULL,
    MaTuyen         varchar(10)   NULL,
    MaChuyen        varchar(20)   NULL,
    TrangThai       varchar(20)   NOT NULL,
    CONSTRAINT pk_LuotQuetThe PRIMARY KEY(MaLuotQuet),
    CONSTRAINT fk_LuotQuetThe_TramVao     FOREIGN KEY(MaTramQuetVao) REFERENCES Tram(MaTram),
    CONSTRAINT fk_LuotQuetThe_TramRa      FOREIGN KEY(MaTramQuetRa)  REFERENCES Tram(MaTram),
    CONSTRAINT fk_LuotQuetThe_TheVeDienTu FOREIGN KEY(MaTheDienTu)   REFERENCES TheVeDienTu(MaTheDienTu),
    CONSTRAINT fk_LuotQuetThe_Tuyen       FOREIGN KEY(MaTuyen)       REFERENCES Tuyen(MaTuyen),
    CONSTRAINT fk_LuotQuetThe_ChuyenXe    FOREIGN KEY(MaChuyen)      REFERENCES ChuyenXe(MaChuyen),
    CONSTRAINT ck_LuotQuetThe_LoaiPhuongTien CHECK(LoaiPhuongTien IN ('BUS', 'METRO')),
    CONSTRAINT ck_LuotQuetThe_SoTienDaTru CHECK(SoTienDaTru >= 0),
    CONSTRAINT ck_LuotQuetThe_QuetRa
        CHECK((MaTramQuetRa IS NULL AND ThoiDiemQuetRa IS NULL)
           OR (MaTramQuetRa IS NOT NULL AND ThoiDiemQuetRa IS NOT NULL)),
    CONSTRAINT ck_LuotQuetThe_ThoiDiem CHECK(ThoiDiemQuetRa > ThoiDiemQuetVao),
    CONSTRAINT ck_LuotQuetThe_Bus
        CHECK(LoaiPhuongTien = 'METRO' OR (MaChuyen IS NOT NULL AND MaTramQuetRa IS NULL)),
    CONSTRAINT ck_LuotQuetThe_Metro
        CHECK(LoaiPhuongTien = 'BUS' OR MaChuyen IS NULL),
    CONSTRAINT ck_LuotQuetThe_TrangThai
        CHECK((TrangThai = 'HOAN_THANH' AND (LoaiPhuongTien = 'BUS' OR MaTramQuetRa IS NOT NULL))
           OR (TrangThai IN ('DANG_DI', 'KHONG_QUET_RA')
               AND LoaiPhuongTien = 'METRO' AND MaTramQuetRa IS NULL))
);
GO
