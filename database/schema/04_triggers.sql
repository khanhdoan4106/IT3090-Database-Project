/* =====================================================================
   04_triggers.sql
   Rules that a CHECK constraint cannot express because they involve
   another table.
   ===================================================================== */

USE QuanLyTheVeDienTu;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* Timetables and trips exist only for buses: a timetable entry must
   belong to a bus route. */
CREATE TRIGGER dbo.trg_LichChay_TuyenXeBuyt
ON dbo.LichChay
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM   inserted i
                      INNER JOIN Tuyen tu ON tu.MaTuyen = i.MaTuyen
               WHERE  tu.LoaiPhuongTien <> 'BUS')
        THROW 50020, N'Lịch chạy chỉ được gắn với tuyến xe buýt.', 1;
END
GO

/* A route that already has timetable entries cannot become a metro route. */
CREATE TRIGGER dbo.trg_Tuyen_LoaiPhuongTien
ON dbo.Tuyen
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM   inserted i
                      INNER JOIN LichChay lc ON lc.MaTuyen = i.MaTuyen
               WHERE  i.LoaiPhuongTien <> 'BUS')
        THROW 50020, N'Tuyến đã có lịch chạy xe buýt, không thể đổi loại phương tiện.', 1;
END
GO
