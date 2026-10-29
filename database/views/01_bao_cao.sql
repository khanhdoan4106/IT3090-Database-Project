/* =====================================================================
   01_bao_cao.sql
   Reporting views: revenue, ridership, card status and balance audit.
   ===================================================================== */

USE QuanLyTheVeDienTu;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* Money per day.
   TienNap / TienHoan: money received from top-ups and paid back by refunds.
   TienBanGoiThang: monthly passes sold.
   TienVe: fares taken from wallets for completed rides (by day of boarding).
   TienPhat: penalty fares for metro journeys never tapped out.
   DoanhThu: revenue earned = passes sold + fares + penalties. Top-ups are
   prepaid money, not revenue, until they are spent. */
CREATE VIEW dbo.v_DoanhThuTheoNgay
AS
SELECT Ngay,
       SUM(TienNap)                          AS TienNap,
       SUM(TienHoan)                         AS TienHoan,
       SUM(TienBanGoiThang)                  AS TienBanGoiThang,
       SUM(TienVe)                           AS TienVe,
       SUM(TienPhat)                         AS TienPhat,
       SUM(TienBanGoiThang + TienVe + TienPhat) AS DoanhThu
FROM (
    SELECT CAST(ThoiDiemGiaoDich AS date) AS Ngay,
           CASE WHEN LoaiGiaoDich = 'NAP_TIEN'      THEN SoTien ELSE 0 END AS TienNap,
           CASE WHEN LoaiGiaoDich = 'HOAN_TIEN'     THEN SoTien ELSE 0 END AS TienHoan,
           CASE WHEN LoaiGiaoDich = 'MUA_GOI_THANG' THEN SoTien ELSE 0 END AS TienBanGoiThang,
           CAST(0 AS numeric(12,0)) AS TienVe,
           CAST(0 AS numeric(12,0)) AS TienPhat
    FROM   GiaoDich
    UNION ALL
    SELECT CAST(ThoiDiemQuetVao AS date),
           0, 0, 0,
           CASE WHEN TrangThai = 'HOAN_THANH'    THEN SoTienDaTru ELSE 0 END,
           CASE WHEN TrangThai = 'KHONG_QUET_RA' THEN SoTienDaTru ELSE 0 END
    FROM   LuotQuetThe
) AS TienTheoNgay
GROUP BY Ngay;
GO

/* Completed rides and fares per day and route. Metro journeys that changed
   lines have no single route and are grouped as N'Liên tuyến metro'. */
CREATE VIEW dbo.v_LuotDiTheoTuyen
AS
SELECT CAST(q.ThoiDiemQuetVao AS date)          AS Ngay,
       q.LoaiPhuongTien,
       q.MaTuyen,
       ISNULL(tu.TenTuyen, N'Liên tuyến metro') AS TenTuyen,
       COUNT(*)                                 AS SoLuotDi,
       SUM(q.SoTienDaTru)                       AS TienVe
FROM   LuotQuetThe q
       LEFT JOIN Tuyen tu ON tu.MaTuyen = q.MaTuyen
WHERE  q.TrangThai = 'HOAN_THANH'
GROUP BY CAST(q.ThoiDiemQuetVao AS date), q.LoaiPhuongTien, q.MaTuyen, tu.TenTuyen;
GO

/* Entries per station, day and hour, for spotting peak hours. */
CREATE VIEW dbo.v_LuotVaoTheoGa
AS
SELECT CAST(q.ThoiDiemQuetVao AS date)  AS Ngay,
       DATEPART(hour, q.ThoiDiemQuetVao) AS Gio,
       q.MaTramQuetVao                  AS MaTram,
       tr.TenTram,
       tr.LoaiPhuongTien,
       COUNT(*)                         AS SoLuotVao
FROM   LuotQuetThe q
       INNER JOIN Tram tr ON tr.MaTram = q.MaTramQuetVao
GROUP BY CAST(q.ThoiDiemQuetVao AS date), DATEPART(hour, q.ThoiDiemQuetVao),
         q.MaTramQuetVao, tr.TenTram, tr.LoaiPhuongTien;
GO

/* Current state of every card: owner, product, balance, pass status as of
   today, lock and replacement status, and last use. */
CREATE VIEW dbo.v_TinhTrangThe
AS
SELECT t.MaTheDienTu,
       h.MaHanhKhach,
       h.HoTen,
       h.NhomDoiTuong,
       l.TenLoaiThe,
       t.SoDuVi,
       t.NgayHetHan,
       CASE WHEN t.NgayHetHan IS NULL                           THEN 'KHONG_CO'
            WHEN t.NgayHetHan >= CAST(GETDATE() AS date)        THEN 'CON_HAN'
            ELSE 'HET_HAN' END                                  AS TrangThaiVeThang,
       t.BiKhoa,
       t.MaTheCu,
       (SELECT m.MaTheDienTu FROM TheVeDienTu m
        WHERE  m.MaTheCu = t.MaTheDienTu)                       AS MaTheThayThe,
       (SELECT MAX(q.ThoiDiemQuetVao) FROM LuotQuetThe q
        WHERE  q.MaTheDienTu = t.MaTheDienTu)                   AS LanDungCuoi
FROM   TheVeDienTu t
       INNER JOIN HanhKhach h ON h.MaHanhKhach = t.MaHanhKhach
       INNER JOIN LoaiThe l   ON l.MaLoaiThe   = t.MaLoaiThe;
GO

/* Balance audit: for every card, the balance rebuilt from its history
   (top-ups - refunds - balance moved out + balance moved in - fares and
   penalties) next to the stored balance. ChenhLech must always be 0. */
CREATE VIEW dbo.v_DoiSoatSoDu
AS
SELECT t.MaTheDienTu,
       t.SoDuVi,
       g.TongNap - g.TongHoan - g.TongChuyenDi + g.TongChuyenDen - ISNULL(q.TongTru, 0)
                                              AS SoDuTheoLichSu,
       t.SoDuVi - (g.TongNap - g.TongHoan - g.TongChuyenDi + g.TongChuyenDen
                   - ISNULL(q.TongTru, 0))    AS ChenhLech
FROM   TheVeDienTu t
       CROSS APPLY (SELECT ISNULL(SUM(CASE WHEN LoaiGiaoDich = 'NAP_TIEN'   THEN SoTien END), 0) AS TongNap,
                           ISNULL(SUM(CASE WHEN LoaiGiaoDich = 'HOAN_TIEN'  THEN SoTien END), 0) AS TongHoan,
                           ISNULL(SUM(CASE WHEN LoaiGiaoDich = 'CHUYEN_DI'  THEN SoTien END), 0) AS TongChuyenDi,
                           ISNULL(SUM(CASE WHEN LoaiGiaoDich = 'CHUYEN_DEN' THEN SoTien END), 0) AS TongChuyenDen
                    FROM   GiaoDich gd
                    WHERE  gd.MaTheDienTu = t.MaTheDienTu) AS g
       OUTER APPLY (SELECT SUM(SoTienDaTru) AS TongTru
                    FROM   LuotQuetThe lq
                    WHERE  lq.MaTheDienTu = t.MaTheDienTu) AS q;
GO
