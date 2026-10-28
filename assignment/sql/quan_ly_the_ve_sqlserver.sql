-- =====================================================================
--  CSDL QUẢN LÝ THẺ VÉ ĐIỆN TỬ XE BUÝT VÀ METRO  (SQL Server)
-- =====================================================================

CREATE DATABASE QuanLyTheVe;
GO
USE QuanLyTheVe;
GO

-- =====================================================================
--  PHẦN 1. TẠO BẢNG
-- =====================================================================

CREATE TABLE HanhKhach(
    MaHanhKhach  varchar(10)   NOT NULL,
    HoTen        nvarchar(50)  NOT NULL,
    SoCCCD       char(12),
    SoDienThoai  varchar(15),
    NhomDoiTuong varchar(20)   NOT NULL,
    CONSTRAINT pk_HanhKhach PRIMARY KEY(MaHanhKhach),
    CHECK(NhomDoiTuong IN ('TIEU_CHUAN', 'HSSV', 'NGUOI_CAO_TUOI'))
);

CREATE TABLE LoaiThe(
    MaLoaiThe     varchar(20)   NOT NULL,
    TenLoaiThe    nvarchar(50)  NOT NULL,
    GiaBan        numeric(12,0) NOT NULL,
    SoNgayHieuLuc int,                       -- NULL: thẻ ví/nạp tiền
    CONSTRAINT pk_LoaiThe PRIMARY KEY(MaLoaiThe),
    CHECK(MaLoaiThe IN ('VE_LUOT', 'THANG_BUS', 'THANG_METRO', 'LIEN_THONG')),
    CHECK(GiaBan >= 0),
    CHECK(SoNgayHieuLuc > 0)
);

CREATE TABLE TheVeDienTu(
    MaTheDienTu  varchar(20)   NOT NULL,
    SoDuVi       numeric(12,0) NOT NULL,
    NgayHetHan   date,                       -- NULL: thẻ ví/nạp tiền
    BiKhoa       smallint      NOT NULL,     -- 0: hoạt động, 1: bị khóa
    MaLoaiThe    varchar(20)   NOT NULL,
    MaHanhKhach  varchar(10)   NOT NULL,
    CONSTRAINT pk_TheVeDienTu PRIMARY KEY(MaTheDienTu),
    FOREIGN KEY(MaLoaiThe)   REFERENCES LoaiThe(MaLoaiThe),
    FOREIGN KEY(MaHanhKhach) REFERENCES HanhKhach(MaHanhKhach),
    CHECK(SoDuVi >= 0),
    CHECK(BiKhoa IN (0, 1))
);

CREATE TABLE GiaoDich(
    MaGiaoDich          varchar(20)   NOT NULL,
    LoaiGiaoDich        varchar(20)   NOT NULL,
    SoTien              numeric(12,0) NOT NULL,
    ThoiDiemGiaoDich    datetime      NOT NULL,
    PhuongThucThanhToan varchar(20)   NOT NULL,
    MaTheDienTu         varchar(20)   NOT NULL,
    CONSTRAINT pk_GiaoDich PRIMARY KEY(MaGiaoDich),
    FOREIGN KEY(MaTheDienTu) REFERENCES TheVeDienTu(MaTheDienTu),
    CHECK(LoaiGiaoDich IN ('NAP_TIEN', 'MUA_GOI_THANG', 'HOAN_TIEN')),
    CHECK(PhuongThucThanhToan IN ('TIEN_MAT', 'VNPAY', 'MOMO', 'NGAN_HANG')),
    CHECK(SoTien > 0)
);

CREATE TABLE Tram(
    MaTram         varchar(10)   NOT NULL,
    TenTram        nvarchar(100) NOT NULL,
    LoaiPhuongTien varchar(10)   NOT NULL,
    CONSTRAINT pk_Tram PRIMARY KEY(MaTram),
    CHECK(LoaiPhuongTien IN ('BUS', 'METRO'))
);

CREATE TABLE Tuyen(
    MaTuyen        varchar(10)   NOT NULL,
    TenTuyen       nvarchar(100) NOT NULL,
    LoaiPhuongTien varchar(10)   NOT NULL,
    CONSTRAINT pk_Tuyen PRIMARY KEY(MaTuyen),
    CHECK(LoaiPhuongTien IN ('BUS', 'METRO'))
);

CREATE TABLE TuyenTram(
    MaTuyen   varchar(10) NOT NULL,
    MaTram    varchar(10) NOT NULL,
    ThuTuTram smallint    NOT NULL,
    CONSTRAINT pk_TuyenTram PRIMARY KEY(MaTuyen, MaTram),
    FOREIGN KEY(MaTuyen) REFERENCES Tuyen(MaTuyen),
    FOREIGN KEY(MaTram)  REFERENCES Tram(MaTram),
    UNIQUE(MaTuyen, ThuTuTram),
    CHECK(ThuTuTram > 0)
);

CREATE TABLE XeBuyt(
    MaXe      varchar(10) NOT NULL,
    BienSo    varchar(15) NOT NULL,
    SoChoNgoi smallint    NOT NULL,
    TrangThai varchar(20) NOT NULL,
    CONSTRAINT pk_XeBuyt PRIMARY KEY(MaXe),
    UNIQUE(BienSo),
    CHECK(SoChoNgoi > 0),
    CHECK(TrangThai IN ('HOAT_DONG', 'BAO_TRI', 'NGUNG'))
);

CREATE TABLE NhanVien(
    MaNhanVien  varchar(10)  NOT NULL,
    HoTen       nvarchar(50) NOT NULL,
    SoDienThoai varchar(15),
    CONSTRAINT pk_NhanVien PRIMARY KEY(MaNhanVien)
);

-- Tài xế, Phụ xe: chuyên biệt hóa từ Nhân viên
-- (MaNhanVien vừa là khóa chính vừa là khóa ngoại)
CREATE TABLE TaiXe(
    MaNhanVien varchar(10) NOT NULL,
    SoGPLX     varchar(20) NOT NULL,
    HangGPLX   varchar(2)  NOT NULL,
    CONSTRAINT pk_TaiXe PRIMARY KEY(MaNhanVien),
    FOREIGN KEY(MaNhanVien) REFERENCES NhanVien(MaNhanVien),
    UNIQUE(SoGPLX),
    -- D1, D2, D: hạng chở người theo Luật TTATGT đường bộ 2024 (từ 01/01/2025);
    -- E: GPLX cấp trước 2025, vẫn được sử dụng đến khi hết hạn
    CHECK(HangGPLX IN ('D1', 'D2', 'D', 'E'))
);

CREATE TABLE PhuXe(
    MaNhanVien varchar(10) NOT NULL,
    CONSTRAINT pk_PhuXe PRIMARY KEY(MaNhanVien),
    FOREIGN KEY(MaNhanVien) REFERENCES NhanVien(MaNhanVien)
);

CREATE TABLE LichChay(
    MaLich        varchar(10) NOT NULL,
    ChieuDi       varchar(10) NOT NULL,
    GioXuatBen    time        NOT NULL,
    NgayTrongTuan varchar(15) NOT NULL,
    MaTuyen       varchar(10) NOT NULL,
    CONSTRAINT pk_LichChay PRIMARY KEY(MaLich),
    FOREIGN KEY(MaTuyen) REFERENCES Tuyen(MaTuyen),
    CHECK(ChieuDi IN ('LUOT_DI', 'LUOT_VE')),
    CHECK(NgayTrongTuan IN ('NGAY_THUONG', 'CUOI_TUAN', 'HANG_NGAY'))
);

CREATE TABLE ChuyenXe(
    MaChuyen  varchar(20) NOT NULL,
    NgayChay  date        NOT NULL,
    TrangThai varchar(20) NOT NULL,
    MaLich    varchar(10) NOT NULL,
    MaXe      varchar(10) NOT NULL,
    MaTaiXe   varchar(10) NOT NULL,
    MaPhuXe   varchar(10) NOT NULL,
    CONSTRAINT pk_ChuyenXe PRIMARY KEY(MaChuyen),
    FOREIGN KEY(MaLich)  REFERENCES LichChay(MaLich),
    FOREIGN KEY(MaXe)    REFERENCES XeBuyt(MaXe),
    FOREIGN KEY(MaTaiXe) REFERENCES TaiXe(MaNhanVien),
    FOREIGN KEY(MaPhuXe) REFERENCES PhuXe(MaNhanVien),
    UNIQUE(MaLich, NgayChay),                -- mỗi lịch chạy 1 chuyến/ngày
    CHECK(TrangThai IN ('CHUA_CHAY', 'DANG_CHAY', 'HOAN_THANH', 'HUY')),
    CHECK(MaTaiXe <> MaPhuXe)
);

CREATE TABLE LuotQuetThe(
    MaLuotQuet      varchar(20)   NOT NULL,
    LoaiPhuongTien  varchar(10)   NOT NULL,
    MaTramQuetVao   varchar(10)   NOT NULL,
    ThoiDiemQuetVao datetime      NOT NULL,
    MaTramQuetRa    varchar(10),             -- NULL khi chưa/không quét ra
    ThoiDiemQuetRa  datetime,
    SoTienDaTru     numeric(12,0) NOT NULL,
    MaTheDienTu     varchar(20)   NOT NULL,
    MaTuyen         varchar(10),             -- NULL khi không xác định tuyến
    MaChuyen        varchar(20),             -- NULL với lượt quẹt metro
    CONSTRAINT pk_LuotQuetThe PRIMARY KEY(MaLuotQuet),
    FOREIGN KEY(MaTramQuetVao) REFERENCES Tram(MaTram),
    FOREIGN KEY(MaTramQuetRa)  REFERENCES Tram(MaTram),
    FOREIGN KEY(MaTheDienTu)   REFERENCES TheVeDienTu(MaTheDienTu),
    FOREIGN KEY(MaTuyen)       REFERENCES Tuyen(MaTuyen),
    FOREIGN KEY(MaChuyen)      REFERENCES ChuyenXe(MaChuyen),
    CHECK(LoaiPhuongTien IN ('BUS', 'METRO')),
    CHECK(SoTienDaTru >= 0),
    -- trạm quét ra và thời điểm quét ra cùng có giá trị hoặc cùng NULL
    CHECK((MaTramQuetRa IS NULL AND ThoiDiemQuetRa IS NULL)
       OR (MaTramQuetRa IS NOT NULL AND ThoiDiemQuetRa IS NOT NULL)),
    CHECK(ThoiDiemQuetRa > ThoiDiemQuetVao),
    CHECK(LoaiPhuongTien = 'BUS' OR MaChuyen IS NULL)   -- metro không có chuyến
);


-- =====================================================================
--  PHẦN 2. TRUY VẤN TRÊN NHIỀU BẢNG
-- =====================================================================

-- 1) Đưa ra họ tên hành khách, mã thẻ và tên loại thẻ mà hành khách đó sở hữu
SELECT H.HoTen, T.MaTheDienTu, L.TenLoaiThe
FROM   HanhKhach H, TheVeDienTu T, LoaiThe L
WHERE  H.MaHanhKhach = T.MaHanhKhach AND T.MaLoaiThe = L.MaLoaiThe;

-- 2) Đưa ra tên các trạm mà tuyến T01 đi qua, sắp xếp theo thứ tự trạm
SELECT TR.TenTram, TT.ThuTuTram
FROM   Tram TR, TuyenTram TT
WHERE  TR.MaTram = TT.MaTram AND TT.MaTuyen = 'T01'
ORDER BY TT.ThuTuTram ASC;

-- 3) Đưa ra họ tên hành khách và mã các thẻ chưa bị khóa nhưng chưa từng
--    được quẹt lần nào (kết nối ngoài trái, giữ lại các thẻ không có lượt quẹt
--    tương ứng, sau đó lọc các dòng có Q.MaLuotQuet IS NULL)
SELECT H.HoTen, T.MaTheDienTu
FROM   HanhKhach H
       INNER JOIN TheVeDienTu T ON H.MaHanhKhach = T.MaHanhKhach
       LEFT JOIN  LuotQuetThe Q ON T.MaTheDienTu = Q.MaTheDienTu
WHERE  T.BiKhoa = 0
  AND  Q.MaLuotQuet IS NULL;

-- 4) Đưa ra mã và họ tên các hành khách sử dụng cả xe buýt lẫn metro
--    (phép giao INTERSECT)
SELECT H.MaHanhKhach, H.HoTen
FROM   HanhKhach H, TheVeDienTu T, LuotQuetThe Q
WHERE  H.MaHanhKhach = T.MaHanhKhach AND T.MaTheDienTu = Q.MaTheDienTu
  AND  Q.LoaiPhuongTien = 'BUS'
INTERSECT
SELECT H.MaHanhKhach, H.HoTen
FROM   HanhKhach H, TheVeDienTu T, LuotQuetThe Q
WHERE  H.MaHanhKhach = T.MaHanhKhach AND T.MaTheDienTu = Q.MaTheDienTu
  AND  Q.LoaiPhuongTien = 'METRO';

-- 5) Đưa ra mã và họ tên các hành khách đã từng quét thẻ (vào hoặc ra)
--    tại TẤT CẢ các ga của tuyến metro M01
--    (phép chia, biểu diễn bằng hai lớp NOT EXISTS:
--     không tồn tại ga nào của tuyến M01 mà hành khách đó chưa từng quét thẻ)
SELECT H.MaHanhKhach, H.HoTen
FROM   HanhKhach H
WHERE  NOT EXISTS (
         SELECT * FROM TuyenTram TT
         WHERE  TT.MaTuyen = 'M01'
           AND  NOT EXISTS (
                  SELECT * FROM TheVeDienTu T, LuotQuetThe Q
                  WHERE  T.MaTheDienTu = Q.MaTheDienTu
                    AND  T.MaHanhKhach = H.MaHanhKhach
                    AND  (Q.MaTramQuetVao = TT.MaTram
                          OR Q.MaTramQuetRa = TT.MaTram)));


-- =====================================================================
--  PHẦN 3. TRUY VẤN CÓ SỬ DỤNG GROUP BY
-- =====================================================================

-- 1) Đưa ra số hành khách theo từng nhóm đối tượng
SELECT NhomDoiTuong, COUNT(MaHanhKhach) AS SoHanhKhach
FROM   HanhKhach
GROUP BY NhomDoiTuong;

-- 2) Đưa ra mã, tên loại thẻ và số thẻ đã phát hành của từng loại
--    (kết nối ngoài trái để loại thẻ chưa phát hành thẻ nào vẫn hiện số 0)
SELECT L.MaLoaiThe, L.TenLoaiThe, COUNT(T.MaTheDienTu) AS SoThe
FROM   LoaiThe L LEFT JOIN TheVeDienTu T ON L.MaLoaiThe = T.MaLoaiThe
GROUP BY L.MaLoaiThe, L.TenLoaiThe;

-- 3) Thống kê số lượt quẹt thẻ và tổng số tiền đã trừ vào ví theo từng tháng
--    của năm 2026, tách riêng xe buýt và metro
SELECT MONTH(ThoiDiemQuetVao) AS Thang, LoaiPhuongTien,
       COUNT(MaLuotQuet) AS SoLuot, SUM(SoTienDaTru) AS TongTienDaTru
FROM   LuotQuetThe
WHERE  ThoiDiemQuetVao >= '20260101' AND ThoiDiemQuetVao < '20270101'
GROUP BY MONTH(ThoiDiemQuetVao), LoaiPhuongTien
ORDER BY Thang, LoaiPhuongTien;

-- 4) Đưa ra họ tên và tổng tiền đã nạp trong tháng 10/2026 của các hành khách
--    nạp từ 500.000 đồng trở lên
SELECT H.MaHanhKhach, H.HoTen, SUM(G.SoTien) AS TongTienNap
FROM   HanhKhach H, TheVeDienTu T, GiaoDich G
WHERE  H.MaHanhKhach = T.MaHanhKhach AND T.MaTheDienTu = G.MaTheDienTu
  AND  G.LoaiGiaoDich = 'NAP_TIEN'
  AND  G.ThoiDiemGiaoDich >= '20261001' AND G.ThoiDiemGiaoDich < '20261101'
GROUP BY H.MaHanhKhach, H.HoTen
HAVING SUM(G.SoTien) >= 500000
ORDER BY TongTienNap DESC;

-- 5) Đưa ra mã, tên tuyến có nhiều lượt quẹt thẻ nhất (nếu nhiều tuyến
--    cùng nhiều nhất thì đưa ra tất cả; so sánh tập hợp với >= ALL)
SELECT TU.MaTuyen, TU.TenTuyen, COUNT(Q.MaLuotQuet) AS SoLuot
FROM   Tuyen TU, LuotQuetThe Q
WHERE  TU.MaTuyen = Q.MaTuyen
GROUP BY TU.MaTuyen, TU.TenTuyen
HAVING COUNT(Q.MaLuotQuet) >= ALL (
         SELECT COUNT(MaLuotQuet)
         FROM   LuotQuetThe
         WHERE  MaTuyen IS NOT NULL
         GROUP BY MaTuyen);