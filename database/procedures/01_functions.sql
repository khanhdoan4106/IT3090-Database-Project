/* =====================================================================
   01_functions.sql
   Helper functions used by the business procedures.
   ===================================================================== */

USE QuanLyTheVeDienTu;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* Builds an identifier from a 2-letter prefix and a sequence number:
   dbo.fn_TaoMa('GD', 42) = 'GD0000000042'. */
CREATE FUNCTION dbo.fn_TaoMa(@TienTo char(2), @So bigint)
RETURNS varchar(20)
AS
BEGIN
    RETURN @TienTo + RIGHT('0000000000' + CAST(@So AS varchar(20)), 10);
END
GO

/* Returns 1 when a card of type @MaLoaiThe, with pass expiry @NgayHetHan,
   travels free on @LoaiPhuongTien on day @Ngay:
   THANG_BUS covers BUS, THANG_METRO covers METRO, LIEN_THONG covers both,
   and the pass must not have expired. VE_LUOT never travels free. */
CREATE FUNCTION dbo.fn_VeThangHopLe(
    @MaLoaiThe      varchar(20),
    @NgayHetHan     date,
    @LoaiPhuongTien varchar(10),
    @Ngay           date)
RETURNS bit
AS
BEGIN
    DECLARE @KetQua bit = 0;

    IF @NgayHetHan >= @Ngay
       AND (@MaLoaiThe = 'LIEN_THONG'
            OR (@MaLoaiThe = 'THANG_BUS'   AND @LoaiPhuongTien = 'BUS')
            OR (@MaLoaiThe = 'THANG_METRO' AND @LoaiPhuongTien = 'METRO'))
        SET @KetQua = 1;

    RETURN @KetQua;
END
GO

/* Fare of a ride on @LoaiPhuongTien that travels @SoGa stations:
   GiaCoBan + GiaMoiGa * @SoGa, capped at GiaToiDa.
   Returns NULL when no fare is configured for that transport type. */
CREATE FUNCTION dbo.fn_TinhGiaVe(@LoaiPhuongTien varchar(10), @SoGa int)
RETURNS numeric(12,0)
AS
BEGIN
    DECLARE @Gia numeric(12,0), @GiaToiDa numeric(12,0);

    SELECT @Gia = GiaCoBan + GiaMoiGa * @SoGa,
           @GiaToiDa = GiaToiDa
    FROM   GiaVe
    WHERE  LoaiPhuongTien = @LoaiPhuongTien;

    IF @GiaToiDa IS NOT NULL AND @Gia > @GiaToiDa
        SET @Gia = @GiaToiDa;

    RETURN @Gia;
END
GO
