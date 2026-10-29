/* =====================================================================
   05_van_hanh.sql
   Bus operations: create a trip from the timetable and move it through
   its statuses.
   Error codes are listed in docs/business-rules.md.
   ===================================================================== */

USE QuanLyTheVeDienTu;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* Creates the trip of timetable entry @MaLich on @NgayChay, with bus @MaXe,
   driver @MaTaiXe and attendant @MaPhuXe. The day must match the entry's
   service days (weekdays, weekends or every day), the bus must be in
   service, and each timetable entry runs at most once per day.
   The trip ID is 'CX' + yyyymmdd + MaLich, e.g. CX20261031L32V0700. */
CREATE PROCEDURE dbo.usp_TaoChuyenXe
    @MaLich   varchar(10),
    @NgayChay date,
    @MaXe     varchar(10),
    @MaTaiXe  varchar(10),
    @MaPhuXe  varchar(10),
    @MaChuyen varchar(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NgayTrongTuan varchar(15);

    SELECT @NgayTrongTuan = NgayTrongTuan
    FROM   LichChay
    WHERE  MaLich = @MaLich;

    IF @NgayTrongTuan IS NULL
        THROW 50026, N'Lịch chạy không tồn tại.', 1;

    -- Day of the week independent of SET DATEFIRST and language:
    -- 1900-01-01 was a Monday, so 0 = Monday ... 5 = Saturday, 6 = Sunday.
    DECLARE @Thu int;
    SET @Thu = DATEDIFF(day, '19000101', @NgayChay) % 7;

    IF (@NgayTrongTuan = 'NGAY_THUONG' AND @Thu >= 5)
       OR (@NgayTrongTuan = 'CUOI_TUAN' AND @Thu < 5)
        THROW 50027, N'Ngày chạy không thuộc các ngày phục vụ của lịch chạy.', 1;

    IF NOT EXISTS (SELECT 1 FROM XeBuyt WHERE MaXe = @MaXe AND TrangThai = 'HOAT_DONG')
        THROW 50028, N'Xe buýt không tồn tại hoặc không ở trạng thái hoạt động.', 1;

    IF NOT EXISTS (SELECT 1 FROM TaiXe WHERE MaNhanVien = @MaTaiXe)
       OR NOT EXISTS (SELECT 1 FROM PhuXe WHERE MaNhanVien = @MaPhuXe)
       OR @MaTaiXe = @MaPhuXe
        THROW 50029, N'Tài xế hoặc phụ xe không hợp lệ.', 1;

    IF EXISTS (SELECT 1 FROM ChuyenXe WHERE MaLich = @MaLich AND NgayChay = @NgayChay)
        THROW 50031, N'Lịch chạy này đã có chuyến trong ngày.', 1;

    SET @MaChuyen = 'CX' + CONVERT(char(8), @NgayChay, 112) + @MaLich;

    INSERT INTO ChuyenXe(MaChuyen, NgayChay, TrangThai, MaLich, MaXe, MaTaiXe, MaPhuXe)
    VALUES (@MaChuyen, @NgayChay, 'CHUA_CHAY', @MaLich, @MaXe, @MaTaiXe, @MaPhuXe);
END
GO

/* Moves trip @MaChuyen to status @TrangThaiMoi. Allowed changes:
   CHUA_CHAY -> DANG_CHAY (departure; the bus must be in service),
   CHUA_CHAY -> HUY (cancelled), DANG_CHAY -> HOAN_THANH (arrived).
   Cards can be scanned only while the trip is DANG_CHAY. */
CREATE PROCEDURE dbo.usp_CapNhatTrangThaiChuyen
    @MaChuyen     varchar(20),
    @TrangThaiMoi varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @TrangThai varchar(20), @MaXe varchar(10);

        SELECT @TrangThai = TrangThai,
               @MaXe      = MaXe
        FROM   ChuyenXe WITH (UPDLOCK, HOLDLOCK)
        WHERE  MaChuyen = @MaChuyen;

        IF @TrangThai IS NULL
            THROW 50010, N'Chuyến xe không tồn tại hoặc không đang chạy.', 1;

        IF NOT ((@TrangThai = 'CHUA_CHAY' AND @TrangThaiMoi IN ('DANG_CHAY', 'HUY'))
                OR (@TrangThai = 'DANG_CHAY' AND @TrangThaiMoi = 'HOAN_THANH'))
            THROW 50030, N'Không thể chuyển chuyến xe sang trạng thái này.', 1;

        IF @TrangThaiMoi = 'DANG_CHAY'
           AND NOT EXISTS (SELECT 1 FROM XeBuyt WHERE MaXe = @MaXe AND TrangThai = 'HOAT_DONG')
            THROW 50028, N'Xe buýt không tồn tại hoặc không ở trạng thái hoạt động.', 1;

        UPDATE ChuyenXe
        SET    TrangThai = @TrangThaiMoi
        WHERE  MaChuyen = @MaChuyen;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
