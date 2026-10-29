/* =====================================================================
   04_quet_the.sql
   Card scans: boarding a bus, entering and leaving the metro.

   Fare rule: a card with a valid pass for the transport type rides free;
   otherwise the fare from GiaVe is taken from the wallet, and the scan is
   refused when the wallet cannot cover it.
   Each procedure runs in one transaction with the card row locked, so the
   scan record and the balance always change together.
   Error codes are listed in docs/business-rules.md.
   ===================================================================== */

USE QuanLyTheVeDienTu;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* Scans card @MaTheDienTu when boarding bus trip @MaChuyen at stop @MaTram.
   The trip must be running on the day of the scan, the stop must be on the
   trip's route, and a card can be scanned only once per trip. */
CREATE PROCEDURE dbo.usp_QuetTheXeBuyt
    @MaTheDienTu varchar(20),
    @MaChuyen    varchar(20),
    @MaTram      varchar(10),
    @ThoiDiem    datetime = NULL,
    @MaLuotQuet  varchar(20)   OUTPUT,
    @SoTienDaTru numeric(12,0) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @ThoiDiem = ISNULL(@ThoiDiem, GETDATE());

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @BiKhoa smallint, @SoDuVi numeric(12,0),
                @MaLoaiThe varchar(20), @NgayHetHan date;

        SELECT @BiKhoa     = BiKhoa,
               @SoDuVi     = SoDuVi,
               @MaLoaiThe  = MaLoaiThe,
               @NgayHetHan = NgayHetHan
        FROM   TheVeDienTu WITH (UPDLOCK, HOLDLOCK)
        WHERE  MaTheDienTu = @MaTheDienTu;

        IF @BiKhoa IS NULL
            THROW 50001, N'Thẻ không tồn tại.', 1;
        IF @BiKhoa = 1
            THROW 50002, N'Thẻ đã bị khóa.', 1;

        DECLARE @MaTuyen varchar(10), @LoaiTuyen varchar(10),
                @TrangThai varchar(20), @NgayChay date;

        SELECT @MaTuyen   = lc.MaTuyen,
               @LoaiTuyen = tu.LoaiPhuongTien,
               @TrangThai = c.TrangThai,
               @NgayChay  = c.NgayChay
        FROM   ChuyenXe c
               INNER JOIN LichChay lc ON lc.MaLich  = c.MaLich
               INNER JOIN Tuyen tu    ON tu.MaTuyen = lc.MaTuyen
        WHERE  c.MaChuyen = @MaChuyen;

        IF @MaTuyen IS NULL OR @TrangThai <> 'DANG_CHAY'
           OR @NgayChay <> CAST(@ThoiDiem AS date)
            THROW 50010, N'Chuyến xe không tồn tại hoặc không đang chạy.', 1;
        IF @LoaiTuyen <> 'BUS'
            THROW 50020, N'Chuyến xe không thuộc tuyến xe buýt.', 1;

        IF NOT EXISTS (SELECT 1 FROM TuyenTram
                       WHERE MaTuyen = @MaTuyen AND MaTram = @MaTram)
            THROW 50011, N'Trạm không thuộc tuyến của chuyến xe.', 1;

        IF EXISTS (SELECT 1 FROM LuotQuetThe
                   WHERE MaTheDienTu = @MaTheDienTu AND MaChuyen = @MaChuyen)
            THROW 50012, N'Thẻ đã được quẹt trên chuyến xe này.', 1;

        IF dbo.fn_VeThangHopLe(@MaLoaiThe, @NgayHetHan, 'BUS', CAST(@ThoiDiem AS date)) = 1
            SET @SoTienDaTru = 0;
        ELSE
            SET @SoTienDaTru = dbo.fn_TinhGiaVe('BUS', 0);

        IF @SoTienDaTru IS NULL
            THROW 50021, N'Chưa cấu hình giá vé cho loại phương tiện này.', 1;
        IF @SoDuVi < @SoTienDaTru
            THROW 50009, N'Số dư ví không đủ.', 1;

        DECLARE @So bigint;
        SET @So = NEXT VALUE FOR dbo.seq_LuotQuetThe;
        SET @MaLuotQuet = dbo.fn_TaoMa('LQ', @So);

        INSERT INTO LuotQuetThe(MaLuotQuet, LoaiPhuongTien, MaTramQuetVao, ThoiDiemQuetVao,
                                MaTramQuetRa, ThoiDiemQuetRa, SoTienDaTru,
                                MaTheDienTu, MaTuyen, MaChuyen)
        VALUES (@MaLuotQuet, 'BUS', @MaTram, @ThoiDiem,
                NULL, NULL, @SoTienDaTru,
                @MaTheDienTu, @MaTuyen, @MaChuyen);

        UPDATE TheVeDienTu
        SET    SoDuVi = SoDuVi - @SoTienDaTru
        WHERE  MaTheDienTu = @MaTheDienTu;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* Taps card @MaTheDienTu in at metro station @MaTram. Nothing is charged
   yet: the fare depends on the exit station. Entry is refused when the card
   already has a journey that was not tapped out, or when the wallet cannot
   cover the minimum fare (cards with a valid metro pass excepted). */
CREATE PROCEDURE dbo.usp_QuetVaoMetro
    @MaTheDienTu varchar(20),
    @MaTram      varchar(10),
    @ThoiDiem    datetime = NULL,
    @MaLuotQuet  varchar(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @ThoiDiem = ISNULL(@ThoiDiem, GETDATE());

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @BiKhoa smallint, @SoDuVi numeric(12,0),
                @MaLoaiThe varchar(20), @NgayHetHan date;

        SELECT @BiKhoa     = BiKhoa,
               @SoDuVi     = SoDuVi,
               @MaLoaiThe  = MaLoaiThe,
               @NgayHetHan = NgayHetHan
        FROM   TheVeDienTu WITH (UPDLOCK, HOLDLOCK)
        WHERE  MaTheDienTu = @MaTheDienTu;

        IF @BiKhoa IS NULL
            THROW 50001, N'Thẻ không tồn tại.', 1;
        IF @BiKhoa = 1
            THROW 50002, N'Thẻ đã bị khóa.', 1;

        IF NOT EXISTS (SELECT 1 FROM Tram
                       WHERE MaTram = @MaTram AND LoaiPhuongTien = 'METRO')
            THROW 50013, N'Trạm không phải ga metro.', 1;

        IF EXISTS (SELECT 1 FROM LuotQuetThe
                   WHERE MaTheDienTu = @MaTheDienTu
                     AND LoaiPhuongTien = 'METRO' AND MaTramQuetRa IS NULL)
            THROW 50014, N'Thẻ đang có hành trình metro chưa quét ra.', 1;

        IF dbo.fn_VeThangHopLe(@MaLoaiThe, @NgayHetHan, 'METRO', CAST(@ThoiDiem AS date)) = 0
        BEGIN
            DECLARE @GiaToiThieu numeric(12,0);
            SET @GiaToiThieu = dbo.fn_TinhGiaVe('METRO', 0);

            IF @GiaToiThieu IS NULL
                THROW 50021, N'Chưa cấu hình giá vé cho loại phương tiện này.', 1;
            IF @SoDuVi < @GiaToiThieu
                THROW 50009, N'Số dư ví không đủ.', 1;
        END

        DECLARE @So bigint;
        SET @So = NEXT VALUE FOR dbo.seq_LuotQuetThe;
        SET @MaLuotQuet = dbo.fn_TaoMa('LQ', @So);

        INSERT INTO LuotQuetThe(MaLuotQuet, LoaiPhuongTien, MaTramQuetVao, ThoiDiemQuetVao,
                                MaTramQuetRa, ThoiDiemQuetRa, SoTienDaTru,
                                MaTheDienTu, MaTuyen, MaChuyen)
        VALUES (@MaLuotQuet, 'METRO', @MaTram, @ThoiDiem,
                NULL, NULL, 0,
                @MaTheDienTu, NULL, NULL);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* Taps card @MaTheDienTu out at metro station @MaTram and charges the fare
   of the open journey. The entry and exit stations must be on the same metro
   line; the fare grows with the number of stations between them. Whether
   the journey is covered by a pass is decided on the day of entry.
   When the wallet cannot cover the fare, the exit is refused and the
   journey stays open until the card is topped up. */
CREATE PROCEDURE dbo.usp_QuetRaMetro
    @MaTheDienTu varchar(20),
    @MaTram      varchar(10),
    @ThoiDiem    datetime = NULL,
    @MaLuotQuet  varchar(20)   OUTPUT,
    @SoTienDaTru numeric(12,0) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @ThoiDiem = ISNULL(@ThoiDiem, GETDATE());

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @BiKhoa smallint, @SoDuVi numeric(12,0),
                @MaLoaiThe varchar(20), @NgayHetHan date;

        SELECT @BiKhoa     = BiKhoa,
               @SoDuVi     = SoDuVi,
               @MaLoaiThe  = MaLoaiThe,
               @NgayHetHan = NgayHetHan
        FROM   TheVeDienTu WITH (UPDLOCK, HOLDLOCK)
        WHERE  MaTheDienTu = @MaTheDienTu;

        IF @BiKhoa IS NULL
            THROW 50001, N'Thẻ không tồn tại.', 1;
        IF @BiKhoa = 1
            THROW 50002, N'Thẻ đã bị khóa.', 1;

        IF NOT EXISTS (SELECT 1 FROM Tram
                       WHERE MaTram = @MaTram AND LoaiPhuongTien = 'METRO')
            THROW 50013, N'Trạm không phải ga metro.', 1;

        DECLARE @MaTramVao varchar(10), @ThoiDiemVao datetime;
        SET @MaLuotQuet = NULL;

        SELECT @MaLuotQuet  = MaLuotQuet,
               @MaTramVao   = MaTramQuetVao,
               @ThoiDiemVao = ThoiDiemQuetVao
        FROM   LuotQuetThe
        WHERE  MaTheDienTu = @MaTheDienTu
          AND  LoaiPhuongTien = 'METRO' AND MaTramQuetRa IS NULL;

        IF @MaLuotQuet IS NULL
            THROW 50015, N'Thẻ không có hành trình metro đang mở.', 1;
        IF @ThoiDiem <= @ThoiDiemVao
            THROW 50017, N'Thời điểm không hợp lệ.', 1;

        -- Metro line that serves both stations, and the number of stations
        -- travelled on it (the shortest one if both stations share several lines).
        DECLARE @MaTuyen varchar(10), @SoGa int;

        SELECT TOP 1
               @MaTuyen = vao.MaTuyen,
               @SoGa    = ABS(ra.ThuTuTram - vao.ThuTuTram)
        FROM   TuyenTram vao
               INNER JOIN TuyenTram ra ON ra.MaTuyen = vao.MaTuyen
               INNER JOIN Tuyen tu     ON tu.MaTuyen = vao.MaTuyen
        WHERE  vao.MaTram = @MaTramVao
          AND  ra.MaTram  = @MaTram
          AND  tu.LoaiPhuongTien = 'METRO'
        ORDER BY ABS(ra.ThuTuTram - vao.ThuTuTram);

        IF @MaTuyen IS NULL
            THROW 50016, N'Ga vào và ga ra không cùng một tuyến metro.', 1;

        IF dbo.fn_VeThangHopLe(@MaLoaiThe, @NgayHetHan, 'METRO', CAST(@ThoiDiemVao AS date)) = 1
            SET @SoTienDaTru = 0;
        ELSE
            SET @SoTienDaTru = dbo.fn_TinhGiaVe('METRO', @SoGa);

        IF @SoTienDaTru IS NULL
            THROW 50021, N'Chưa cấu hình giá vé cho loại phương tiện này.', 1;
        IF @SoDuVi < @SoTienDaTru
            THROW 50009, N'Số dư ví không đủ.', 1;

        UPDATE LuotQuetThe
        SET    MaTramQuetRa   = @MaTram,
               ThoiDiemQuetRa = @ThoiDiem,
               SoTienDaTru    = @SoTienDaTru,
               MaTuyen        = @MaTuyen
        WHERE  MaLuotQuet = @MaLuotQuet;

        UPDATE TheVeDienTu
        SET    SoDuVi = SoDuVi - @SoTienDaTru
        WHERE  MaTheDienTu = @MaTheDienTu;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
