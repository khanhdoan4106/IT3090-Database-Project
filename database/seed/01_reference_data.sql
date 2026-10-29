/* =====================================================================
   01_reference_data.sql
   Reference data: card products, fares, passenger-category discounts,
   stations, routes, buses, staff, timetable, bus trips and passengers.

   Sample data for development and testing. Metro stations follow lines 2A
   (Cát Linh – Hà Đông) and 3 (elevated section Nhổn – Cầu Giấy); bus
   routes, stops, prices, discounts, people and documents are illustrative.
   ===================================================================== */

USE QuanLyTheVeDienTu;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

INSERT INTO LoaiThe(MaLoaiThe, TenLoaiThe, GiaBan, SoNgayHieuLuc) VALUES
('VE_LUOT',     N'Thẻ trả trước (trừ tiền theo lượt)', 0,      NULL),
('THANG_BUS',   N'Vé tháng xe buýt',                   140000, 30),
('THANG_METRO', N'Vé tháng metro',                     200000, 30),
('LIEN_THONG',  N'Vé tháng liên thông buýt – metro',   280000, 30);

-- Bus: flat fare. Metro: 8,000 + 700 per station travelled, at most 15,000.
INSERT INTO GiaVe(LoaiPhuongTien, GiaCoBan, GiaMoiGa, GiaToiDa) VALUES
('BUS',   7000, 0,   NULL),
('METRO', 8000, 700, 15000);

/* ---------- Metro ---------- */

INSERT INTO Tuyen(MaTuyen, TenTuyen, LoaiPhuongTien) VALUES
('M2A', N'Tuyến 2A: Cát Linh – Hà Đông', 'METRO'),
('M3',  N'Tuyến 3: Nhổn – Cầu Giấy',     'METRO');

INSERT INTO Tram(MaTram, TenTram, LoaiPhuongTien) VALUES
('M2A01', N'Ga Cát Linh',     'METRO'),
('M2A02', N'Ga La Thành',     'METRO'),
('M2A03', N'Ga Thái Hà',      'METRO'),
('M2A04', N'Ga Láng',         'METRO'),
('M2A05', N'Ga Thượng Đình',  'METRO'),
('M2A06', N'Ga Vành Đai 3',   'METRO'),
('M2A07', N'Ga Phùng Khoang', 'METRO'),
('M2A08', N'Ga Văn Quán',     'METRO'),
('M2A09', N'Ga Hà Đông',      'METRO'),
('M2A10', N'Ga La Khê',       'METRO'),
('M2A11', N'Ga Văn Khê',      'METRO'),
('M2A12', N'Ga Yên Nghĩa',    'METRO'),
('M301',  N'Ga Nhổn',            'METRO'),
('M302',  N'Ga Minh Khai',       'METRO'),
('M303',  N'Ga Phú Diễn',        'METRO'),
('M304',  N'Ga Cầu Diễn',        'METRO'),
('M305',  N'Ga Lê Đức Thọ',      'METRO'),
('M306',  N'Ga Đại học Quốc gia','METRO'),
('M307',  N'Ga Chùa Hà',         'METRO'),
('M308',  N'Ga Cầu Giấy',        'METRO');

INSERT INTO TuyenTram(MaTuyen, MaTram, ThuTuTram) VALUES
('M2A', 'M2A01', 1), ('M2A', 'M2A02', 2),  ('M2A', 'M2A03', 3),  ('M2A', 'M2A04', 4),
('M2A', 'M2A05', 5), ('M2A', 'M2A06', 6),  ('M2A', 'M2A07', 7),  ('M2A', 'M2A08', 8),
('M2A', 'M2A09', 9), ('M2A', 'M2A10', 10), ('M2A', 'M2A11', 11), ('M2A', 'M2A12', 12),
('M3', 'M301', 1), ('M3', 'M302', 2), ('M3', 'M303', 3), ('M3', 'M304', 4),
('M3', 'M305', 5), ('M3', 'M306', 6), ('M3', 'M307', 7), ('M3', 'M308', 8);

/* ---------- Bus ---------- */

INSERT INTO Tuyen(MaTuyen, TenTuyen, LoaiPhuongTien) VALUES
('B32', N'Tuyến 32: BX Giáp Bát – Nhổn',     'BUS'),
('B09', N'Tuyến 09: Bờ Hồ – Cầu Giấy',       'BUS');

INSERT INTO Tram(MaTram, TenTram, LoaiPhuongTien) VALUES
('B001', N'Bến xe Giáp Bát',     'BUS'),
('B002', N'Ngã tư Vọng',         'BUS'),
('B003', N'Đại học Bách khoa',   'BUS'),
('B004', N'Cầu Giấy',            'BUS'),
('B005', N'Đại học Quốc gia',    'BUS'),
('B006', N'Nhổn',                'BUS'),
('B007', N'Bờ Hồ',               'BUS'),
('B008', N'Hàng Đậu',            'BUS'),
('B009', N'Kim Mã',              'BUS');

INSERT INTO TuyenTram(MaTuyen, MaTram, ThuTuTram) VALUES
('B32', 'B001', 1), ('B32', 'B002', 2), ('B32', 'B003', 3),
('B32', 'B004', 4), ('B32', 'B005', 5), ('B32', 'B006', 6),
('B09', 'B007', 1), ('B09', 'B008', 2), ('B09', 'B009', 3), ('B09', 'B004', 4);

INSERT INTO XeBuyt(MaXe, BienSo, SoChoNgoi, TrangThai) VALUES
('XB01', '29B-100.01', 60, 'HOAT_DONG'),
('XB02', '29B-100.02', 60, 'HOAT_DONG'),
('XB03', '29B-100.03', 40, 'HOAT_DONG'),
('XB04', '29B-100.04', 40, 'BAO_TRI');

INSERT INTO NhanVien(MaNhanVien, HoTen, SoDienThoai) VALUES
('NV01', N'Nguyễn Văn Hùng', '0912000001'),
('NV02', N'Trần Quốc Bảo',   '0912000002'),
('NV03', N'Lê Minh Tuấn',    '0912000003'),
('NV04', N'Phạm Thị Lan',    '0912000004'),
('NV05', N'Hoàng Thu Trang', '0912000005'),
('NV06', N'Đỗ Thị Mai',      '0912000006');

INSERT INTO TaiXe(MaNhanVien, SoGPLX, HangGPLX) VALUES
('NV01', '010100000001', 'D2'),
('NV02', '010100000002', 'D'),
('NV03', '010100000003', 'E');

INSERT INTO PhuXe(MaNhanVien) VALUES ('NV04'), ('NV05'), ('NV06');

INSERT INTO LichChay(MaLich, ChieuDi, GioXuatBen, NgayTrongTuan, MaTuyen) VALUES
('L32D0600', 'LUOT_DI', '06:00', 'HANG_NGAY',   'B32'),
('L32V0700', 'LUOT_VE', '07:00', 'HANG_NGAY',   'B32'),
('L09D0630', 'LUOT_DI', '06:30', 'NGAY_THUONG', 'B09');

-- Trips on 2026-10-28 are inserted as running so the demo activity can scan
-- on them, then marked completed in 02_demo_activity.sql.
INSERT INTO ChuyenXe(MaChuyen, NgayChay, TrangThai, MaLich, MaXe, MaTaiXe, MaPhuXe) VALUES
('CX20261028001', '20261028', 'DANG_CHAY', 'L32D0600', 'XB01', 'NV01', 'NV04'),
('CX20261028002', '20261028', 'DANG_CHAY', 'L09D0630', 'XB03', 'NV03', 'NV06'),
('CX20261029001', '20261029', 'DANG_CHAY', 'L32D0600', 'XB01', 'NV01', 'NV04'),
('CX20261029002', '20261029', 'CHUA_CHAY', 'L32V0700', 'XB02', 'NV02', 'NV05'),
('CX20261029003', '20261029', 'DANG_CHAY', 'L09D0630', 'XB03', 'NV03', 'NV06');

/* ---------- Passengers ---------- */

-- Discounts in percent: on each ride paid from the wallet, and on monthly passes.
INSERT INTO UuDaiDoiTuong(NhomDoiTuong, TenNhom, PhanTramGiamVeLuot, PhanTramGiamGoiThang) VALUES
('TIEU_CHUAN',     N'Tiêu chuẩn',        0,  0),
('HSSV',           N'Học sinh, sinh viên', 0,  50),
('NGUOI_CAO_TUOI', N'Người cao tuổi',    50, 50);

INSERT INTO HanhKhach(MaHanhKhach, HoTen, SoCCCD, SoDienThoai, NhomDoiTuong) VALUES
('HK001', N'Nguyễn Minh Anh',  '001205000001', '0987000001', 'HSSV'),
('HK002', N'Trần Đức Long',    '001095000002', '0987000002', 'TIEU_CHUAN'),
('HK003', N'Lê Thu Hà',        '001190000003', '0987000003', 'TIEU_CHUAN'),
('HK004', N'Phạm Văn Bình',    '001958000004', '0987000004', 'NGUOI_CAO_TUOI'),
('HK005', N'Vũ Hoàng Nam',     '001204000005', '0987000005', 'HSSV'),
('HK006', N'Đặng Thị Hương',   NULL,           '0987000006', 'TIEU_CHUAN');
GO
