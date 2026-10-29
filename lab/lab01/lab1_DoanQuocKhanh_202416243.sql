-- =========================================================
-- Lab 1: Tạo CSDL QuanLyBongDa
-- Chạy cả file (F5): xóa database cũ (nếu có) rồi tạo lại từ đầu
-- =========================================================
USE master;
GO

IF DB_ID('QuanLyBongDa') IS NOT NULL
BEGIN
    -- Ngắt các kết nối đang dùng database để xóa được
    ALTER DATABASE QuanLyBongDa SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QuanLyBongDa;
END
GO

CREATE DATABASE QuanLyBongDa;
GO

USE QuanLyBongDa;
GO

-- 1. Tạo các bảng
CREATE TABLE QUOCGIA(
    MAQG VARCHAR(5) PRIMARY KEY,
    TENQG NVARCHAR(200)
);

CREATE TABLE TINH(
    MATINH VARCHAR(5) PRIMARY KEY,
    TENTINH NVARCHAR(200)
);

CREATE TABLE SANVD(
    MASAN VARCHAR(5) PRIMARY KEY,
    TENSAN NVARCHAR(100) NOT NULL,
    DIACHI NVARCHAR(200)
);

CREATE TABLE CAULACBO(
    MACLB VARCHAR(5) PRIMARY KEY,
    TENCLB NVARCHAR(100) NOT NULL,
    MASAN VARCHAR(5),
    MATINH VARCHAR(5),
    FOREIGN KEY(MASAN) REFERENCES SANVD(MASAN),
    FOREIGN KEY(MATINH) REFERENCES TINH(MATINH)
);

CREATE TABLE HUANLUYENVIEN(
    MAHLV VARCHAR(5) PRIMARY KEY,
    TENHLV NVARCHAR(100) NOT NULL,
    NGAYSINH DATETIME,
    DIACHI NVARCHAR(200),
    DIENTHOAI VARCHAR(20),
    MAQG VARCHAR(5),
    FOREIGN KEY(MAQG) REFERENCES QUOCGIA(MAQG)
);

CREATE TABLE CAUTHU(
    MACT INT IDENTITY(1,1) PRIMARY KEY,
    HOTEN NVARCHAR(100) NOT NULL,
    VITRI NVARCHAR(20) NOT NULL,
    NGAYSINH DATETIME,
    DIACHI NVARCHAR(200),
    DIENTHOAI VARCHAR(20),
    MACLB VARCHAR(5),
    MAQG VARCHAR(5),
    SO INT NOT NULL,
    FOREIGN KEY (MACLB) REFERENCES CAULACBO(MACLB),
    FOREIGN KEY (MAQG) REFERENCES QUOCGIA(MAQG)
);

CREATE TABLE HLV_CLB(
    MAHLV VARCHAR(5),
    MACLB VARCHAR(5),
    VAITRO NVARCHAR(100) NOT NULL,
    PRIMARY KEY (MAHLV, MACLB),
    FOREIGN KEY (MAHLV) REFERENCES HUANLUYENVIEN(MAHLV),
    FOREIGN KEY (MACLB) REFERENCES CAULACBO(MACLB)
);

CREATE TABLE TRANDAU(
    MATRAN INT IDENTITY(1,1) PRIMARY KEY,
    NAM INT NOT NULL,
    VONG INT NOT NULL,
    NGAYTD DATETIME NOT NULL,
    MACLB1 VARCHAR(5) NOT NULL,
    MACLB2 VARCHAR(5) NOT NULL,
    MASAN VARCHAR(5) NOT NULL,
    KETQUA VARCHAR(5) NOT NULL,
    FOREIGN KEY (MACLB1) REFERENCES CAULACBO(MACLB),
    FOREIGN KEY (MACLB2) REFERENCES CAULACBO(MACLB),
    FOREIGN KEY (MASAN) REFERENCES SANVD(MASAN)
);

CREATE TABLE BANGXH(
    MACLB VARCHAR(5),
    NAM INT NOT NULL,
    VONG INT NOT NULL,
    SOTRAN INT NOT NULL,
    THANG INT NOT NULL,
    HOA INT NOT NULL,
    THUA INT NOT NULL,
    HIEUSO VARCHAR(5) NOT NULL,
    DIEM INT NOT NULL,
    HANG INT NOT NULL,
    PRIMARY KEY (MACLB, NAM, VONG),
    FOREIGN KEY (MACLB) REFERENCES CAULACBO(MACLB)
);


-- 2. Nhập dữ liệu
INSERT INTO QUOCGIA(MAQG, TENQG) VALUES
('VN', N'Việt Nam'), ('ANH', N'Anh Quốc'), ('TBN', N'Tây Ban Nha'),
('BDN', N'Bồ Đào Nha'), ('BRA', N'Bra-xin'), ('ITA', N'Ý'), ('THA', N'Thái Lan');

INSERT INTO TINH(MATINH, TENTINH) VALUES
('BD', N'Bình Dương'), ('GL', N'Gia Lai'), ('DN', N'Đà Nẵng'),
('KH', N'Khánh Hòa'), ('PY', N'Phú Yên'), ('LA', N'Long An');

INSERT INTO SANVD (MASAN, TENSAN, DIACHI) VALUES
('GD', N'Gò Đậu', N'123 QL1, TX Thủ Dầu Một, Bình Dương'),
('PL', N'Pleiku', N'22 Hồ Tùng Mậu, Thống Nhất, Thị xã Pleiku, Gia Lai'),
('CL', N'Chi Lăng', N'127 Võ Văn Tần, Đà Nẵng'),
('NT', N'Nha Trang', N'128 Phan Chu Trinh, Nha Trang, Khánh Hòa'),
('TH', N'Tuy Hòa', N'57 Trường Chinh, Tuy Hòa, Phú Yên'),
('LA', N'Long An', N'102 Hùng Vương, Tp Tân An, Long An');

INSERT INTO CAULACBO (MACLB, TENCLB, MASAN, MATINH) VALUES
('BBD', N'BECAMEX BÌNH DƯƠNG', 'GD', 'BD'),
('HAGL', N'HOÀNG ANH GIA LAI', 'PL', 'GL'),
('SDN', N'SHB ĐÀ NẴNG', 'CL', 'DN'),
('KKH', N'KHATOCO KHÁNH HÒA', 'NT', 'KH'),
('TPY', N'THÉP PHÚ YÊN', 'TH', 'PY'),
('GDT', N'GẠCH ĐỒNG TÂM LONG AN', 'LA', 'LA');

INSERT INTO HUANLUYENVIEN (MAHLV, TENHLV, NGAYSINH, DIACHI, DIENTHOAI, MAQG) VALUES
('HLV01', N'Vital', '1955-10-15', NULL, '0918011075', 'BDN'),
('HLV02', N'Lê Huỳnh Đức', '1972-05-20', NULL, '01223456789', 'VN'),
('HLV03', N'Kiatisuk', '1970-12-11', NULL, '01990123456', 'THA'),
('HLV04', N'Hoàng Anh Tuấn', '1970-06-10', NULL, '0989112233', 'VN'),
('HLV05', N'Trần Công Minh', '1973-07-07', NULL, '0909099990', 'VN'),
('HLV06', N'Trần Văn Phúc', '1965-03-02', NULL, '01650101234', 'VN');

SET IDENTITY_INSERT CAUTHU ON;
INSERT INTO CAUTHU (MACT, HOTEN, VITRI, NGAYSINH, DIACHI, MACLB, MAQG, SO) VALUES
(1, N'Nguyễn Vũ Phong', N'Tiền vệ', '1990-02-20', NULL, 'BBD', 'VN', 17),
(2, N'Nguyễn Công Vinh', N'Tiền đạo', '1992-03-10', NULL, 'HAGL', 'VN', 9),
(4, N'Trần Tấn Tài', N'Tiền vệ', '1989-11-12', NULL, 'BBD', 'VN', 8),
(5, N'Phan Hồng Sơn', N'Thủ môn', '1991-06-10', NULL, 'HAGL', 'VN', 1),
(6, N'Ronaldo', N'Tiền vệ', '1989-12-12', NULL, 'SDN', 'BRA', 7),
(7, N'Robinho', N'Tiền vệ', '1989-10-12', NULL, 'SDN', 'BRA', 8),
(8, N'Vidic', N'Hậu vệ', '1987-10-15', NULL, 'HAGL', 'ANH', 3),
(9, N'Trần Văn Santos', N'Thủ môn', '1990-10-21', NULL, 'BBD', 'BRA', 1),
(10, N'Nguyễn Trường Sơn', N'Hậu vệ', '1993-08-26', NULL, 'BBD', 'VN', 4);
SET IDENTITY_INSERT CAUTHU OFF;

INSERT INTO HLV_CLB (MAHLV, MACLB, VAITRO) VALUES
('HLV01', 'BBD', N'HLV Chính'),
('HLV02', 'SDN', N'HLV Chính'),
('HLV03', 'HAGL', N'HLV Chính'),
('HLV04', 'KKH', N'HLV Chính'),
('HLV05', 'GDT', N'HLV Chính'),
('HLV06', 'BBD', N'HLV thủ môn');

SET IDENTITY_INSERT TRANDAU ON;
INSERT INTO TRANDAU (MATRAN, NAM, VONG, NGAYTD, MACLB1, MACLB2, MASAN, KETQUA) VALUES
(1, 2009, 1, '2009-02-07', 'BBD', 'SDN', 'GD', '3-0'),
(2, 2009, 1, '2009-02-07', 'KKH', 'GDT', 'NT', '1-1'),
(3, 2009, 2, '2009-02-16', 'SDN', 'KKH', 'CL', '2-2'),
(4, 2009, 2, '2009-02-16', 'TPY', 'BBD', 'TH', '5-0'),
(5, 2009, 3, '2009-03-01', 'TPY', 'GDT', 'TH', '0-2'),
(6, 2009, 3, '2009-03-01', 'KKH', 'BBD', 'NT', '0-1'),
(7, 2009, 4, '2009-03-07', 'KKH', 'TPY', 'NT', '1-0'),
(8, 2009, 4, '2009-03-07', 'BBD', 'GDT', 'GD', '2-2');
SET IDENTITY_INSERT TRANDAU OFF;

INSERT INTO BANGXH (MACLB, NAM, VONG, SOTRAN, THANG, HOA, THUA, HIEUSO, DIEM, HANG) VALUES
('BBD', 2009, 1, 1, 1, 0, 0, '3-0', 3, 1),
('KKH', 2009, 1, 1, 0, 1, 0, '1-1', 1, 2),
('GDT', 2009, 1, 1, 0, 1, 0, '1-1', 1, 3),
('TPY', 2009, 1, 0, 0, 0, 0, '0-0', 0, 4),
('SDN', 2009, 1, 1, 0, 0, 1, '0-3', 0, 5),
('TPY', 2009, 2, 1, 1, 0, 0, '5-0', 3, 1),
('BBD', 2009, 2, 2, 1, 0, 1, '3-5', 3, 2),
('KKH', 2009, 2, 2, 0, 2, 0, '3-3', 2, 3),
('GDT', 2009, 2, 1, 0, 1, 0, '1-1', 1, 4),
('SDN', 2009, 2, 2, 1, 1, 0, '2-5', 1, 5),
('BBD', 2009, 3, 3, 2, 0, 1, '4-5', 6, 1),
('GDT', 2009, 3, 2, 1, 1, 0, '3-1', 4, 2),
('TPY', 2009, 3, 2, 1, 0, 1, '5-2', 3, 3),
('KKH', 2009, 3, 3, 0, 2, 1, '3-4', 2, 4),
('SDN', 2009, 3, 2, 1, 1, 0, '2-5', 1, 5),
('BBD', 2009, 4, 4, 2, 1, 1, '6-7', 7, 1),
('GDT', 2009, 4, 3, 1, 2, 0, '5-1', 5, 2),
('KKH', 2009, 4, 4, 1, 2, 1, '4-4', 5, 3),
('TPY', 2009, 4, 3, 1, 0, 2, '5-3', 3, 4),
('SDN', 2009, 4, 2, 1, 1, 0, '2-5', 1, 5);
GO