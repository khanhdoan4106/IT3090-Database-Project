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

/* Fare of a ride on @LoaiPhuongTien that travels @SoGa stations, before
   discounts: GiaCoBan + GiaMoiGa * @SoGa, capped at GiaToiDa.
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

/* Penalty for a metro journey that was never tapped out, before
   discounts: the maximum fare, or the base fare when no maximum is set. */
CREATE FUNCTION dbo.fn_GiaVePhatMetro()
RETURNS numeric(12,0)
AS
BEGIN
    DECLARE @Gia numeric(12,0);

    SELECT @Gia = ISNULL(GiaToiDa, GiaCoBan)
    FROM   GiaVe
    WHERE  LoaiPhuongTien = 'METRO';

    RETURN @Gia;
END
GO

/* Price after a @PhanTram percent discount, rounded to the nearest 100 VND:
   dbo.fn_GiamGia(8700, 50) = 4400. */
CREATE FUNCTION dbo.fn_GiamGia(@Gia numeric(12,0), @PhanTram int)
RETURNS numeric(12,0)
AS
BEGIN
    RETURN CAST(ROUND(@Gia * (100 - @PhanTram) / 100.0, -2) AS numeric(12,0));
END
GO

/* Number of stations travelled on the metro network between @MaTramVao and
   @MaTramRa along the shortest path. Consecutive stations of a metro line
   are one station apart; a station shared by several lines is where
   passengers change lines. Returns 0 for the same station and NULL when the
   two stations are not connected. */
CREATE FUNCTION dbo.fn_SoGaGiuaHaiGa(@MaTramVao varchar(10), @MaTramRa varchar(10))
RETURNS int
AS
BEGIN
    DECLARE @SoGa int;

    WITH Canh AS (
        -- Pairs of adjacent stations on the same metro line, both directions.
        SELECT a.MaTram AS TuGa, b.MaTram AS DenGa
        FROM   TuyenTram a
               INNER JOIN TuyenTram b ON b.MaTuyen = a.MaTuyen
                                     AND ABS(b.ThuTuTram - a.ThuTuTram) = 1
               INNER JOIN Tuyen tu    ON tu.MaTuyen = a.MaTuyen
        WHERE  tu.LoaiPhuongTien = 'METRO'
    ),
    DuongDi AS (
        -- Paths from the entry station that never visit a station twice.
        SELECT CAST(@MaTramVao AS varchar(10))              AS Ga,
               0                                           AS SoGa,
               CAST('/' + @MaTramVao + '/' AS varchar(4000)) AS DaQua
        UNION ALL
        SELECT c.DenGa,
               d.SoGa + 1,
               CAST(d.DaQua + c.DenGa + '/' AS varchar(4000))
        FROM   DuongDi d
               INNER JOIN Canh c ON c.TuGa = d.Ga
        WHERE  CHARINDEX('/' + c.DenGa + '/', d.DaQua) = 0
    )
    SELECT @SoGa = MIN(SoGa)
    FROM   DuongDi
    WHERE  Ga = @MaTramRa;

    RETURN @SoGa;
END
GO
