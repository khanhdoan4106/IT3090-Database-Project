/* =====================================================================
   04_quet_the.sql
   Card scans: boarding a bus, entering and leaving the metro, and closing
   metro journeys that were never tapped out.

   Fare rule: a card with a valid pass for the transport type rides free;
   otherwise the fare from GiaVe, less the passenger category's per-ride
   discount, is taken from the wallet, and the scan is refused when the
   wallet cannot cover it.
   Each procedure runs in one transaction with the card row locked, so the
   scan record and the balance always change together.
   Error codes are listed in docs/business-rules.md.
   ===================================================================== */

USE QuanLyTheVeDienTu;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* Internal: closes metro journey @MaLuotQuet, which was never tapped out,
   with a penalty fare: the maximum metro fare less the per-ride discount,
   nothing when a valid metro pass covered the day of entry, and never more
   than the wallet holds. Must be called inside a transaction that has
   already locked the journey's card. */
CREATE PROCEDURE dbo.usp_PhatHanhTrinhChuaQuetRa
    @MaLuotQuet varchar(20),
    @SoTienPhat numeric(12,0) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @@TRANCOUNT = 0
        THROW 50033, N'Thủ tục phải được gọi bên trong một giao dịch.', 1;

    DECLARE @MaTheDienTu varchar(20), @ThoiDiemVao datetime, @TrangThai varchar(20);

    SELECT @MaTheDienTu = MaTheDienTu,
           @ThoiDiemVao = ThoiDiemQuetVao,
           @TrangThai   = TrangThai
    FROM   LuotQuetThe
    WHERE  MaLuotQuet = @MaLuotQuet;

    IF @TrangThai IS NULL OR @TrangThai <> 'DANG_DI'
        THROW 50015, N'Thẻ không có hành trình metro đang mở.', 1;

    DECLARE @SoDuVi numeric(12,0), @MaLoaiThe varchar(20),
            @NgayHetHan date, @PhanTramGiam int;

    SELECT @SoDuVi       = t.SoDuVi,
           @MaLoaiThe    = t.MaLoaiThe,
           @NgayHetHan   = t.NgayHetHan,
           @PhanTramGiam = u.PhanTramGiamVeLuot
    FROM   TheVeDienTu t
           INNER JOIN HanhKhach h     ON h.MaHanhKhach  = t.MaHanhKhach
           INNER JOIN UuDaiDoiTuong u ON u.NhomDoiTuong = h.NhomDoiTuong
    WHERE  t.MaTheDienTu = @MaTheDienTu;

    IF dbo.fn_VeThangHopLe(@MaLoaiThe, @NgayHetHan, 'METRO', CAST(@ThoiDiemVao AS date)) = 1
        SET @SoTienPhat = 0;
    ELSE
        SET @SoTienPhat = dbo.fn_GiamGia(dbo.fn_GiaVePhatMetro(), @PhanTramGiam);

    IF @SoTienPhat IS NULL
        THROW 50021, N'Chưa cấu hình giá vé cho loại phương tiện này.', 1;
    IF @SoTienPhat > @SoDuVi
        SET @SoTienPhat = @SoDuVi;

    UPDATE LuotQuetThe
    SET    TrangThai   = 'KHONG_QUET_RA',
           SoTienDaTru = @SoTienPhat
    WHERE  MaLuotQuet = @MaLuotQuet;

    UPDATE TheVeDienTu
    SET    SoDuVi = SoDuVi - @SoTienPhat
    WHERE  MaTheDienTu = @MaTheDienTu;
END
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
                @MaLoaiThe varchar(20), @NgayHetHan date, @PhanTramGiam int;

        SELECT @BiKhoa       = t.BiKhoa,
               @SoDuVi       = t.SoDuVi,
               @MaLoaiThe    = t.MaLoaiThe,
               @NgayHetHan   = t.NgayHetHan,
               @PhanTramGiam = u.PhanTramGiamVeLuot
        FROM   TheVeDienTu t WITH (UPDLOCK, HOLDLOCK)
               INNER JOIN HanhKhach h     ON h.MaHanhKhach  = t.MaHanhKhach
               INNER JOIN UuDaiDoiTuong u ON u.NhomDoiTuong = h.NhomDoiTuong
        WHERE  t.MaTheDienTu = @MaTheDienTu;

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
            SET @SoTienDaTru = dbo.fn_GiamGia(dbo.fn_TinhGiaVe('BUS', 0), @PhanTramGiam);

        IF @SoTienDaTru IS NULL
            THROW 50021, N'Chưa cấu hình giá vé cho loại phương tiện này.', 1;
        IF @SoDuVi < @SoTienDaTru
            THROW 50009, N'Số dư ví không đủ.', 1;

        DECLARE @So bigint;
        SET @So = NEXT VALUE FOR dbo.seq_LuotQuetThe;
        SET @MaLuotQuet = dbo.fn_TaoMa('LQ', @So);

        INSERT INTO LuotQuetThe(MaLuotQuet, LoaiPhuongTien, MaTramQuetVao, ThoiDiemQuetVao,
                                MaTramQuetRa, ThoiDiemQuetRa, SoTienDaTru,
                                MaTheDienTu, MaTuyen, MaChuyen, TrangThai)
        VALUES (@MaLuotQuet, 'BUS', @MaTram, @ThoiDiem,
                NULL, NULL, @SoTienDaTru,
                @MaTheDienTu, @MaTuyen, @MaChuyen, 'HOAN_THANH');

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
   yet: the fare depends on the exit station.
   A journey still in progress from an earlier day was abandoned: it is first
   closed with a penalty fare (usp_PhatHanhTrinhChuaQuetRa). A journey in
   progress from the same day refuses the entry. Without a valid metro pass,
   the wallet must cover the minimum fare after discount. */
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
                @MaLoaiThe varchar(20), @NgayHetHan date, @PhanTramGiam int;

        SELECT @BiKhoa       = t.BiKhoa,
               @SoDuVi       = t.SoDuVi,
               @MaLoaiThe    = t.MaLoaiThe,
               @NgayHetHan   = t.NgayHetHan,
               @PhanTramGiam = u.PhanTramGiamVeLuot
        FROM   TheVeDienTu t WITH (UPDLOCK, HOLDLOCK)
               INNER JOIN HanhKhach h     ON h.MaHanhKhach  = t.MaHanhKhach
               INNER JOIN UuDaiDoiTuong u ON u.NhomDoiTuong = h.NhomDoiTuong
        WHERE  t.MaTheDienTu = @MaTheDienTu;

        IF @BiKhoa IS NULL
            THROW 50001, N'Thẻ không tồn tại.', 1;
        IF @BiKhoa = 1
            THROW 50002, N'Thẻ đã bị khóa.', 1;

        IF NOT EXISTS (SELECT 1 FROM Tram
                       WHERE MaTram = @MaTram AND LoaiPhuongTien = 'METRO')
            THROW 50013, N'Trạm không phải ga metro.', 1;

        DECLARE @MaLuotDangDi varchar(20), @ThoiDiemVaoTruoc datetime;

        SELECT @MaLuotDangDi     = MaLuotQuet,
               @ThoiDiemVaoTruoc = ThoiDiemQuetVao
        FROM   LuotQuetThe
        WHERE  MaTheDienTu = @MaTheDienTu AND TrangThai = 'DANG_DI';

        IF @MaLuotDangDi IS NOT NULL
        BEGIN
            IF CAST(@ThoiDiemVaoTruoc AS date) >= CAST(@ThoiDiem AS date)
                THROW 50014, N'Thẻ đang có hành trình metro chưa quét ra.', 1;

            DECLARE @SoTienPhat numeric(12,0);
            EXEC dbo.usp_PhatHanhTrinhChuaQuetRa @MaLuotQuet = @MaLuotDangDi,
                                                 @SoTienPhat = @SoTienPhat OUTPUT;

            SELECT @SoDuVi = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @MaTheDienTu;
        END

        IF dbo.fn_VeThangHopLe(@MaLoaiThe, @NgayHetHan, 'METRO', CAST(@ThoiDiem AS date)) = 0
        BEGIN
            DECLARE @GiaToiThieu numeric(12,0);
            SET @GiaToiThieu = dbo.fn_GiamGia(dbo.fn_TinhGiaVe('METRO', 0), @PhanTramGiam);

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
                                MaTheDienTu, MaTuyen, MaChuyen, TrangThai)
        VALUES (@MaLuotQuet, 'METRO', @MaTram, @ThoiDiem,
                NULL, NULL, 0,
                @MaTheDienTu, NULL, NULL, 'DANG_DI');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* Taps card @MaTheDienTu out at metro station @MaTram and charges the fare
   of the journey in progress. The fare grows with the number of stations on
   the shortest path through the metro network, changing lines where they
   share a station (dbo.fn_SoGaGiuaHaiGa). The journey is recorded on its line
   when one line serves both stations, and without a line (MaTuyen NULL) when
   the passenger changed lines. Whether a pass covers the journey is decided
   on the day of entry. When the wallet cannot cover the fare, the exit is
   refused and the journey stays open until the card is topped up. */
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
                @MaLoaiThe varchar(20), @NgayHetHan date, @PhanTramGiam int;

        SELECT @BiKhoa       = t.BiKhoa,
               @SoDuVi       = t.SoDuVi,
               @MaLoaiThe    = t.MaLoaiThe,
               @NgayHetHan   = t.NgayHetHan,
               @PhanTramGiam = u.PhanTramGiamVeLuot
        FROM   TheVeDienTu t WITH (UPDLOCK, HOLDLOCK)
               INNER JOIN HanhKhach h     ON h.MaHanhKhach  = t.MaHanhKhach
               INNER JOIN UuDaiDoiTuong u ON u.NhomDoiTuong = h.NhomDoiTuong
        WHERE  t.MaTheDienTu = @MaTheDienTu;

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
        WHERE  MaTheDienTu = @MaTheDienTu AND TrangThai = 'DANG_DI';

        IF @MaLuotQuet IS NULL
            THROW 50015, N'Thẻ không có hành trình metro đang mở.', 1;
        IF @ThoiDiem <= @ThoiDiemVao
            THROW 50017, N'Thời điểm không hợp lệ.', 1;

        DECLARE @SoGa int;
        SET @SoGa = dbo.fn_SoGaGiuaHaiGa(@MaTramVao, @MaTram);

        IF @SoGa IS NULL
            THROW 50016, N'Không có đường đi giữa ga vào và ga ra trên mạng metro.', 1;

        -- The line of the journey, when a single line serves both stations.
        DECLARE @MaTuyen varchar(10);

        SELECT TOP 1 @MaTuyen = vao.MaTuyen
        FROM   TuyenTram vao
               INNER JOIN TuyenTram ra ON ra.MaTuyen = vao.MaTuyen
               INNER JOIN Tuyen tu     ON tu.MaTuyen = vao.MaTuyen
        WHERE  vao.MaTram = @MaTramVao
          AND  ra.MaTram  = @MaTram
          AND  tu.LoaiPhuongTien = 'METRO'
        ORDER BY ABS(ra.ThuTuTram - vao.ThuTuTram);

        IF dbo.fn_VeThangHopLe(@MaLoaiThe, @NgayHetHan, 'METRO', CAST(@ThoiDiemVao AS date)) = 1
            SET @SoTienDaTru = 0;
        ELSE
            SET @SoTienDaTru = dbo.fn_GiamGia(dbo.fn_TinhGiaVe('METRO', @SoGa), @PhanTramGiam);

        IF @SoTienDaTru IS NULL
            THROW 50021, N'Chưa cấu hình giá vé cho loại phương tiện này.', 1;
        IF @SoDuVi < @SoTienDaTru
            THROW 50009, N'Số dư ví không đủ.', 1;

        UPDATE LuotQuetThe
        SET    MaTramQuetRa   = @MaTram,
               ThoiDiemQuetRa = @ThoiDiem,
               SoTienDaTru    = @SoTienDaTru,
               MaTuyen        = @MaTuyen,
               TrangThai      = 'HOAN_THANH'
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

/* Staff action: closes the metro journey in progress on card @MaTheDienTu
   with a penalty fare, e.g. when the card is lost during the journey or
   before the card is replaced. Works on locked cards. */
CREATE PROCEDURE dbo.usp_DongHanhTrinhMetro
    @MaTheDienTu varchar(20),
    @MaLuotQuet  varchar(20)   OUTPUT,
    @SoTienPhat  numeric(12,0) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @BiKhoa smallint;

        SELECT @BiKhoa = BiKhoa
        FROM   TheVeDienTu WITH (UPDLOCK, HOLDLOCK)
        WHERE  MaTheDienTu = @MaTheDienTu;

        IF @BiKhoa IS NULL
            THROW 50001, N'Thẻ không tồn tại.', 1;

        SET @MaLuotQuet = NULL;

        SELECT @MaLuotQuet = MaLuotQuet
        FROM   LuotQuetThe
        WHERE  MaTheDienTu = @MaTheDienTu AND TrangThai = 'DANG_DI';

        IF @MaLuotQuet IS NULL
            THROW 50015, N'Thẻ không có hành trình metro đang mở.', 1;

        EXEC dbo.usp_PhatHanhTrinhChuaQuetRa @MaLuotQuet = @MaLuotQuet,
                                             @SoTienPhat = @SoTienPhat OUTPUT;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* Nightly job: closes, with a penalty fare, every metro journey tapped in
   before day @TruocNgay (default: today) that was never tapped out.
   Each journey is closed in its own transaction; @SoHanhTrinh returns how
   many were closed. */
CREATE PROCEDURE dbo.usp_DongHanhTrinhQuaHan
    @TruocNgay   date = NULL,
    @SoHanhTrinh int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @TruocNgay = ISNULL(@TruocNgay, CAST(GETDATE() AS date));
    SET @SoHanhTrinh = 0;

    DECLARE @MaLuotQuet varchar(20), @MaTheDienTu varchar(20),
            @SoDuVi numeric(12,0), @SoTienPhat numeric(12,0);

    WHILE 1 = 1
    BEGIN
        SELECT TOP 1
               @MaLuotQuet  = MaLuotQuet,
               @MaTheDienTu = MaTheDienTu
        FROM   LuotQuetThe
        WHERE  TrangThai = 'DANG_DI' AND ThoiDiemQuetVao < @TruocNgay
        ORDER BY ThoiDiemQuetVao;

        IF @@ROWCOUNT = 0 BREAK;

        BEGIN TRY
            BEGIN TRANSACTION;

            SELECT @SoDuVi = SoDuVi
            FROM   TheVeDienTu WITH (UPDLOCK, HOLDLOCK)
            WHERE  MaTheDienTu = @MaTheDienTu;

            -- Re-check under the lock: the passenger may have just tapped out.
            IF EXISTS (SELECT 1 FROM LuotQuetThe
                       WHERE MaLuotQuet = @MaLuotQuet AND TrangThai = 'DANG_DI')
            BEGIN
                EXEC dbo.usp_PhatHanhTrinhChuaQuetRa @MaLuotQuet = @MaLuotQuet,
                                                     @SoTienPhat = @SoTienPhat OUTPUT;
                SET @SoHanhTrinh = @SoHanhTrinh + 1;
            END

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH
    END
END
GO
