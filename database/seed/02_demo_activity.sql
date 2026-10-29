/* =====================================================================
   02_demo_activity.sql
   Demo card activity for 2026-10, created through the business
   procedures so that balances, transactions and scans stay consistent.
   Run once, right after 01_reference_data.sql.
   ===================================================================== */

USE QuanLyTheVeDienTu;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

SET NOCOUNT ON;

DECLARE @The1 varchar(20), @The2 varchar(20), @The3 varchar(20),
        @The4 varchar(20), @The5 varchar(20), @The6 varchar(20),
        @GD varchar(20), @GDNap5 varchar(20), @LQ varchar(20),
        @Tien numeric(12,0), @HetHan date;

/* HK001: stored-value card, rides the metro and the bus. */
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK001', @MaLoaiThe = 'VE_LUOT', @MaTheDienTu = @The1 OUTPUT;
EXEC dbo.usp_NapTien @MaTheDienTu = @The1, @SoTien = 200000, @PhuongThucThanhToan = 'MOMO',
     @ThoiDiem = '20261020 08:00', @MaGiaoDich = @GD OUTPUT;
EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @The1, @MaTram = 'M2A01', @ThoiDiem = '20261028 07:05', @MaLuotQuet = @LQ OUTPUT;
EXEC dbo.usp_QuetRaMetro  @MaTheDienTu = @The1, @MaTram = 'M2A09', @ThoiDiem = '20261028 07:27',
     @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @The1, @MaChuyen = 'CX20261028001', @MaTram = 'B003',
     @ThoiDiem = '20261028 06:20', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
-- Journey in progress: tapped in, not yet tapped out.
EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @The1, @MaTram = 'M301', @ThoiDiem = '20261029 07:40', @MaLuotQuet = @LQ OUTPUT;

/* HK002: monthly metro pass; pays for the bus from the wallet. */
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK002', @MaLoaiThe = 'THANG_METRO', @MaTheDienTu = @The2 OUTPUT;
EXEC dbo.usp_MuaGoiThang @MaTheDienTu = @The2, @PhuongThucThanhToan = 'VNPAY', @ThoiDiem = '20261001 09:00',
     @MaGiaoDich = @GD OUTPUT, @NgayHetHanMoi = @HetHan OUTPUT;
EXEC dbo.usp_NapTien @MaTheDienTu = @The2, @SoTien = 50000, @PhuongThucThanhToan = 'TIEN_MAT',
     @ThoiDiem = '20261001 09:05', @MaGiaoDich = @GD OUTPUT;
EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @The2, @MaTram = 'M308', @ThoiDiem = '20261028 08:00', @MaLuotQuet = @LQ OUTPUT;
EXEC dbo.usp_QuetRaMetro  @MaTheDienTu = @The2, @MaTram = 'M301', @ThoiDiem = '20261028 08:20',
     @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @The2, @MaChuyen = 'CX20261028002', @MaTram = 'B007',
     @ThoiDiem = '20261028 06:40', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;

/* HK003: combined bus + metro pass. */
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK003', @MaLoaiThe = 'LIEN_THONG', @MaTheDienTu = @The3 OUTPUT;
EXEC dbo.usp_MuaGoiThang @MaTheDienTu = @The3, @PhuongThucThanhToan = 'NGAN_HANG', @ThoiDiem = '20261015 10:00',
     @MaGiaoDich = @GD OUTPUT, @NgayHetHanMoi = @HetHan OUTPUT;
EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @The3, @MaChuyen = 'CX20261028001', @MaTram = 'B001',
     @ThoiDiem = '20261028 06:02', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @The3, @MaTram = 'M2A04', @ThoiDiem = '20261028 17:30', @MaLuotQuet = @LQ OUTPUT;
EXEC dbo.usp_QuetRaMetro  @MaTheDienTu = @The3, @MaTram = 'M2A12', @ThoiDiem = '20261028 17:55',
     @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;

/* HK004: monthly bus pass. */
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK004', @MaLoaiThe = 'THANG_BUS', @MaTheDienTu = @The4 OUTPUT;
EXEC dbo.usp_MuaGoiThang @MaTheDienTu = @The4, @PhuongThucThanhToan = 'TIEN_MAT', @ThoiDiem = '20261005 07:00',
     @MaGiaoDich = @GD OUTPUT, @NgayHetHanMoi = @HetHan OUTPUT;
EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @The4, @MaChuyen = 'CX20261028002', @MaTram = 'B008',
     @ThoiDiem = '20261028 06:45', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;

/* HK005: tops up twice, then gets the second top-up refunded. */
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK005', @MaLoaiThe = 'VE_LUOT', @MaTheDienTu = @The5 OUTPUT;
EXEC dbo.usp_NapTien @MaTheDienTu = @The5, @SoTien = 100000, @PhuongThucThanhToan = 'VNPAY',
     @ThoiDiem = '20261021 12:00', @MaGiaoDich = @GD OUTPUT;
EXEC dbo.usp_NapTien @MaTheDienTu = @The5, @SoTien = 50000, @PhuongThucThanhToan = 'MOMO',
     @ThoiDiem = '20261022 12:00', @MaGiaoDich = @GDNap5 OUTPUT;
EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @The5, @MaChuyen = 'CX20261028001', @MaTram = 'B004',
     @ThoiDiem = '20261028 06:35', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
EXEC dbo.usp_HoanTien @MaGiaoDichGoc = @GDNap5, @ThoiDiem = '20261028 15:00', @MaGiaoDich = @GD OUTPUT;

/* HK006: card reported lost and locked; the balance is kept. */
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK006', @MaLoaiThe = 'VE_LUOT', @MaTheDienTu = @The6 OUTPUT;
EXEC dbo.usp_NapTien @MaTheDienTu = @The6, @SoTien = 30000, @PhuongThucThanhToan = 'TIEN_MAT',
     @ThoiDiem = '20261025 18:00', @MaGiaoDich = @GD OUTPUT;
EXEC dbo.usp_KhoaThe @MaTheDienTu = @The6, @BiKhoa = 1;

/* The 2026-10-28 trips have finished. */
UPDATE ChuyenXe SET TrangThai = 'HOAN_THANH' WHERE NgayChay = '20261028';
GO
