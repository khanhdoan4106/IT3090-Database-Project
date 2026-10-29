/* =====================================================================
   02_the.sql
   Card management: issue a card, lock or unlock a card.
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
   cannot be topped up, buy a pass or be scanned; its balance is kept. */
CREATE PROCEDURE dbo.usp_KhoaThe
    @MaTheDienTu varchar(20),
    @BiKhoa      smallint
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @BiKhoa IS NULL OR @BiKhoa NOT IN (0, 1)
        THROW 50022, N'Trạng thái khóa không hợp lệ (chỉ nhận 0 hoặc 1).', 1;

    UPDATE TheVeDienTu
    SET    BiKhoa = @BiKhoa
    WHERE  MaTheDienTu = @MaTheDienTu;

    IF @@ROWCOUNT = 0
        THROW 50001, N'Thẻ không tồn tại.', 1;
END
GO
