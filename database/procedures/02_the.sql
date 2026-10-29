/* =====================================================================
   02_the.sql
   Card management: issue, lock or unlock, and replace a card.
   Error codes are listed in docs/business-rules.md.
   ===================================================================== */

USE QuanLyTheVeDienTu;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* Issues a new card of type @MaLoaiThe to passenger @MaHanhKhach.
   The card starts with a zero balance and no pass; a pass is added with
   usp_MuaGoiThang. */
CREATE PROCEDURE dbo.usp_PhatHanhThe
    @MaHanhKhach varchar(10),
    @MaLoaiThe   varchar(20),
    @MaTheDienTu varchar(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM HanhKhach WHERE MaHanhKhach = @MaHanhKhach)
        THROW 50018, N'Hành khách không tồn tại.', 1;

    IF NOT EXISTS (SELECT 1 FROM LoaiThe WHERE MaLoaiThe = @MaLoaiThe)
        THROW 50019, N'Loại thẻ không tồn tại.', 1;

    DECLARE @So bigint;
    SET @So = NEXT VALUE FOR dbo.seq_TheVeDienTu;
    SET @MaTheDienTu = dbo.fn_TaoMa('TH', @So);

    INSERT INTO TheVeDienTu(MaTheDienTu, SoDuVi, NgayHetHan, BiKhoa, MaLoaiThe, MaHanhKhach)
    VALUES (@MaTheDienTu, 0, NULL, 0, @MaLoaiThe, @MaHanhKhach);
END
GO

/* Locks (@BiKhoa = 1) or unlocks (@BiKhoa = 0) a card. A locked card
   cannot be topped up, buy a pass or be scanned; its balance is kept.
   A card that has been replaced stays locked for good. */
CREATE PROCEDURE dbo.usp_KhoaThe
    @MaTheDienTu varchar(20),
    @BiKhoa      smallint
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @BiKhoa IS NULL OR @BiKhoa NOT IN (0, 1)
        THROW 50022, N'Trạng thái khóa không hợp lệ (chỉ nhận 0 hoặc 1).', 1;

    IF NOT EXISTS (SELECT 1 FROM TheVeDienTu WHERE MaTheDienTu = @MaTheDienTu)
        THROW 50001, N'Thẻ không tồn tại.', 1;

    IF @BiKhoa = 0 AND EXISTS (SELECT 1 FROM TheVeDienTu WHERE MaTheCu = @MaTheDienTu)
        THROW 50024, N'Thẻ đã được thay bằng thẻ khác.', 1;

    UPDATE TheVeDienTu
    SET    BiKhoa = @BiKhoa
    WHERE  MaTheDienTu = @MaTheDienTu;
END
GO

/* Replaces a lost or damaged card @MaTheCu with a new card of the same type
   for the same passenger. The wallet balance and the pass expiry date move to
   the new card; the old card is locked for good. A non-zero balance is
   recorded as a pair of transactions (CHUYEN_DI on the old card, CHUYEN_DEN
   on the new one) so that both cards' histories still match their balances.
   A card with a metro journey in progress must have it closed first
   (usp_DongHanhTrinhMetro). */
CREATE PROCEDURE dbo.usp_DoiThe
    @MaTheCu     varchar(20),
    @ThoiDiem    datetime = NULL,
    @MaTheMoi    varchar(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @ThoiDiem = ISNULL(@ThoiDiem, GETDATE());

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @SoDuVi numeric(12,0), @NgayHetHan date,
                @MaLoaiThe varchar(20), @MaHanhKhach varchar(10);

        SELECT @SoDuVi      = SoDuVi,
               @NgayHetHan  = NgayHetHan,
               @MaLoaiThe   = MaLoaiThe,
               @MaHanhKhach = MaHanhKhach
        FROM   TheVeDienTu WITH (UPDLOCK, HOLDLOCK)
        WHERE  MaTheDienTu = @MaTheCu;

        IF @MaHanhKhach IS NULL
            THROW 50001, N'Thẻ không tồn tại.', 1;
        IF EXISTS (SELECT 1 FROM TheVeDienTu WHERE MaTheCu = @MaTheCu)
            THROW 50024, N'Thẻ đã được thay bằng thẻ khác.', 1;
        IF EXISTS (SELECT 1 FROM LuotQuetThe
                   WHERE MaTheDienTu = @MaTheCu AND TrangThai = 'DANG_DI')
            THROW 50023, N'Thẻ còn hành trình metro chưa kết thúc.', 1;

        DECLARE @So bigint;
        SET @So = NEXT VALUE FOR dbo.seq_TheVeDienTu;
        SET @MaTheMoi = dbo.fn_TaoMa('TH', @So);

        INSERT INTO TheVeDienTu(MaTheDienTu, SoDuVi, NgayHetHan, BiKhoa,
                                MaLoaiThe, MaHanhKhach, MaTheCu)
        VALUES (@MaTheMoi, @SoDuVi, @NgayHetHan, 0,
                @MaLoaiThe, @MaHanhKhach, @MaTheCu);

        IF @SoDuVi > 0
        BEGIN
            DECLARE @MaChuyenDi varchar(20), @MaChuyenDen varchar(20);

            SET @So = NEXT VALUE FOR dbo.seq_GiaoDich;
            SET @MaChuyenDi = dbo.fn_TaoMa('GD', @So);
            SET @So = NEXT VALUE FOR dbo.seq_GiaoDich;
            SET @MaChuyenDen = dbo.fn_TaoMa('GD', @So);

            INSERT INTO GiaoDich(MaGiaoDich, LoaiGiaoDich, SoTien, ThoiDiemGiaoDich,
                                 PhuongThucThanhToan, MaTheDienTu, MaGiaoDichGoc)
            VALUES (@MaChuyenDi, 'CHUYEN_DI', @SoDuVi, @ThoiDiem, NULL, @MaTheCu, NULL);

            INSERT INTO GiaoDich(MaGiaoDich, LoaiGiaoDich, SoTien, ThoiDiemGiaoDich,
                                 PhuongThucThanhToan, MaTheDienTu, MaGiaoDichGoc)
            VALUES (@MaChuyenDen, 'CHUYEN_DEN', @SoDuVi, @ThoiDiem, NULL, @MaTheMoi, @MaChuyenDi);
        END

        UPDATE TheVeDienTu
        SET    SoDuVi = 0,
               BiKhoa = 1
        WHERE  MaTheDienTu = @MaTheCu;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
