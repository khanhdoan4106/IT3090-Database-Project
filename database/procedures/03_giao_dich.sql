/* =====================================================================
   03_giao_dich.sql
   Money operations: top-up, monthly pass purchase, refund.

   Each procedure runs in one transaction: the transaction row and the
   card's balance or expiry change together or not at all. The card row is
   locked (UPDLOCK, HOLDLOCK) before it is read, so two operations on the
   same card are applied one after the other.
   Error codes are listed in docs/business-rules.md.
   ===================================================================== */

USE QuanLyTheVeDienTu;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* Adds @SoTien to the card's wallet, paid by @PhuongThucThanhToan. */
CREATE PROCEDURE dbo.usp_NapTien
    @MaTheDienTu         varchar(20),
    @SoTien              numeric(12,0),
    @PhuongThucThanhToan varchar(20),
    @ThoiDiem            datetime = NULL,
    @MaGiaoDich          varchar(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @ThoiDiem = ISNULL(@ThoiDiem, GETDATE());

    IF @SoTien IS NULL OR @SoTien <= 0
        THROW 50003, N'Số tiền phải lớn hơn 0.', 1;

    IF @PhuongThucThanhToan IS NULL
       OR @PhuongThucThanhToan NOT IN ('TIEN_MAT', 'VNPAY', 'MOMO', 'NGAN_HANG')
        THROW 50004, N'Phương thức thanh toán không hợp lệ.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @BiKhoa smallint;

        SELECT @BiKhoa = BiKhoa
        FROM   TheVeDienTu WITH (UPDLOCK, HOLDLOCK)
        WHERE  MaTheDienTu = @MaTheDienTu;

        IF @BiKhoa IS NULL
            THROW 50001, N'Thẻ không tồn tại.', 1;
        IF @BiKhoa = 1
            THROW 50002, N'Thẻ đã bị khóa.', 1;

        DECLARE @So bigint;
        SET @So = NEXT VALUE FOR dbo.seq_GiaoDich;
        SET @MaGiaoDich = dbo.fn_TaoMa('GD', @So);

        INSERT INTO GiaoDich(MaGiaoDich, LoaiGiaoDich, SoTien, ThoiDiemGiaoDich,
                             PhuongThucThanhToan, MaTheDienTu, MaGiaoDichGoc)
        VALUES (@MaGiaoDich, 'NAP_TIEN', @SoTien, @ThoiDiem,
                @PhuongThucThanhToan, @MaTheDienTu, NULL);

        UPDATE TheVeDienTu
        SET    SoDuVi = SoDuVi + @SoTien
        WHERE  MaTheDienTu = @MaTheDienTu;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* Buys one validity period of the card's pass product, paid by
   @PhuongThucThanhToan (not from the wallet). The price is the product's
   GiaBan less the passenger category's monthly-pass discount.
   A pass still valid is extended from the day after it expires;
   an expired pass, or a card without a pass, starts today. */
CREATE PROCEDURE dbo.usp_MuaGoiThang
    @MaTheDienTu         varchar(20),
    @PhuongThucThanhToan varchar(20),
    @ThoiDiem            datetime = NULL,
    @MaGiaoDich          varchar(20) OUTPUT,
    @NgayHetHanMoi       date        OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @ThoiDiem = ISNULL(@ThoiDiem, GETDATE());

    IF @PhuongThucThanhToan IS NULL
       OR @PhuongThucThanhToan NOT IN ('TIEN_MAT', 'VNPAY', 'MOMO', 'NGAN_HANG')
        THROW 50004, N'Phương thức thanh toán không hợp lệ.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @BiKhoa smallint, @NgayHetHan date,
                @GiaBan numeric(12,0), @SoNgayHieuLuc int, @PhanTramGiam int;

        SELECT @BiKhoa        = t.BiKhoa,
               @NgayHetHan    = t.NgayHetHan,
               @GiaBan        = l.GiaBan,
               @SoNgayHieuLuc = l.SoNgayHieuLuc,
               @PhanTramGiam  = u.PhanTramGiamGoiThang
        FROM   TheVeDienTu t WITH (UPDLOCK, HOLDLOCK)
               INNER JOIN LoaiThe l       ON l.MaLoaiThe    = t.MaLoaiThe
               INNER JOIN HanhKhach h     ON h.MaHanhKhach  = t.MaHanhKhach
               INNER JOIN UuDaiDoiTuong u ON u.NhomDoiTuong = h.NhomDoiTuong
        WHERE  t.MaTheDienTu = @MaTheDienTu;

        IF @BiKhoa IS NULL
            THROW 50001, N'Thẻ không tồn tại.', 1;
        IF @BiKhoa = 1
            THROW 50002, N'Thẻ đã bị khóa.', 1;
        IF @SoNgayHieuLuc IS NULL
            THROW 50005, N'Loại thẻ này không có gói tháng.', 1;

        DECLARE @Ngay date, @NgayBatDau date;
        SET @Ngay = CAST(@ThoiDiem AS date);
        SET @NgayBatDau = CASE WHEN @NgayHetHan >= @Ngay
                               THEN DATEADD(day, 1, @NgayHetHan)
                               ELSE @Ngay END;
        SET @NgayHetHanMoi = DATEADD(day, @SoNgayHieuLuc - 1, @NgayBatDau);

        DECLARE @So bigint;
        SET @So = NEXT VALUE FOR dbo.seq_GiaoDich;
        SET @MaGiaoDich = dbo.fn_TaoMa('GD', @So);

        INSERT INTO GiaoDich(MaGiaoDich, LoaiGiaoDich, SoTien, ThoiDiemGiaoDich,
                             PhuongThucThanhToan, MaTheDienTu, MaGiaoDichGoc)
        VALUES (@MaGiaoDich, 'MUA_GOI_THANG', dbo.fn_GiamGia(@GiaBan, @PhanTramGiam), @ThoiDiem,
                @PhuongThucThanhToan, @MaTheDienTu, NULL);

        UPDATE TheVeDienTu
        SET    NgayHetHan = @NgayHetHanMoi
        WHERE  MaTheDienTu = @MaTheDienTu;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* Refunds top-up @MaGiaoDichGoc in full, to the same payment method.
   Only top-ups can be refunded, each at most once, and only while the
   wallet still holds the amount. Locked cards can be refunded (e.g. a
   lost card). Monthly passes are not refundable. */
CREATE PROCEDURE dbo.usp_HoanTien
    @MaGiaoDichGoc varchar(20),
    @ThoiDiem      datetime = NULL,
    @MaGiaoDich    varchar(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @ThoiDiem = ISNULL(@ThoiDiem, GETDATE());

    DECLARE @MaTheDienTu varchar(20), @LoaiGiaoDich varchar(20),
            @SoTien numeric(12,0), @PhuongThucThanhToan varchar(20),
            @ThoiDiemGoc datetime;

    SELECT @MaTheDienTu         = MaTheDienTu,
           @LoaiGiaoDich        = LoaiGiaoDich,
           @SoTien              = SoTien,
           @PhuongThucThanhToan = PhuongThucThanhToan,
           @ThoiDiemGoc         = ThoiDiemGiaoDich
    FROM   GiaoDich
    WHERE  MaGiaoDich = @MaGiaoDichGoc;

    IF @MaTheDienTu IS NULL
        THROW 50006, N'Giao dịch gốc không tồn tại.', 1;
    IF @LoaiGiaoDich <> 'NAP_TIEN'
        THROW 50007, N'Chỉ hoàn tiền cho giao dịch nạp tiền.', 1;
    IF @ThoiDiem < @ThoiDiemGoc
        THROW 50017, N'Thời điểm không hợp lệ.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @SoDuVi numeric(12,0);

        SELECT @SoDuVi = SoDuVi
        FROM   TheVeDienTu WITH (UPDLOCK, HOLDLOCK)
        WHERE  MaTheDienTu = @MaTheDienTu;

        IF EXISTS (SELECT 1 FROM GiaoDich WHERE MaGiaoDichGoc = @MaGiaoDichGoc)
            THROW 50008, N'Giao dịch này đã được hoàn tiền.', 1;
        IF @SoDuVi < @SoTien
            THROW 50009, N'Số dư ví không đủ.', 1;

        DECLARE @So bigint;
        SET @So = NEXT VALUE FOR dbo.seq_GiaoDich;
        SET @MaGiaoDich = dbo.fn_TaoMa('GD', @So);

        INSERT INTO GiaoDich(MaGiaoDich, LoaiGiaoDich, SoTien, ThoiDiemGiaoDich,
                             PhuongThucThanhToan, MaTheDienTu, MaGiaoDichGoc)
        VALUES (@MaGiaoDich, 'HOAN_TIEN', @SoTien, @ThoiDiem,
                @PhuongThucThanhToan, @MaTheDienTu, @MaGiaoDichGoc);

        UPDATE TheVeDienTu
        SET    SoDuVi = SoDuVi - @SoTien
        WHERE  MaTheDienTu = @MaTheDienTu;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
