/* =====================================================================
   01_test_business_rules.sql
   Tests for the business procedures. Each test records PASS or FAIL in
   #KetQua; the result table and a summary are shown at the end.

   Run on a freshly built database (schema + procedures + seed): the tests
   create their own cards and change data, so rebuild before re-running.
   Card activity takes place on 2026-10-29, matching the seeded bus trips.
   Passengers HK002, HK003 and HK006 are standard (no discount); HK001 is a
   student and HK004 a senior (see UuDaiDoiTuong in the seed data).
   ===================================================================== */

USE QuanLyTheVeDienTu;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#KetQua') IS NOT NULL DROP TABLE #KetQua;
CREATE TABLE #KetQua(
    STT     int IDENTITY(1,1),
    TenTest nvarchar(200),
    KetQua  varchar(4),
    ChiTiet nvarchar(400)
);

DECLARE @TheA varchar(20), @TheB varchar(20), @TheC varchar(20), @TheD varchar(20),
        @TheE varchar(20), @TheF varchar(20), @TheG varchar(20), @TheH varchar(20),
        @TheI varchar(20), @TheJ varchar(20), @TheK varchar(20), @TheL varchar(20),
        @TheL2 varchar(20), @TheM varchar(20), @TheD2 varchar(20), @MaChuyen varchar(20),
        @GD varchar(20), @GDNapA varchar(20), @GDNapG varchar(20), @GDNapH varchar(20),
        @GDGoiD varchar(20), @GDHoan varchar(20), @LQ varchar(20),
        @Tien numeric(12,0), @SoDu numeric(12,0), @HetHan date,
        @Dem int, @Loi int, @ThongBao nvarchar(400);

/* =====================================================================
   1. Card management
   ===================================================================== */

-- T01 Issue a card
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK002', @MaLoaiThe = 'VE_LUOT', @MaTheDienTu = @TheA OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @Dem = COUNT(*) FROM TheVeDienTu
WHERE  MaTheDienTu = @TheA AND SoDuVi = 0 AND BiKhoa = 0 AND NgayHetHan IS NULL;
INSERT INTO #KetQua VALUES (N'T01 Phát hành thẻ: số dư 0, chưa khóa, chưa có hạn',
    CASE WHEN @Loi IS NULL AND @Dem = 1 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@ThongBao, @TheA));

-- T02 Issue to an unknown passenger
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK999', @MaLoaiThe = 'VE_LUOT', @MaTheDienTu = @GD OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T02 Phát hành thẻ cho hành khách không tồn tại -> 50018',
    CASE WHEN @Loi = 50018 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T03 Issue an unknown card type
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK002', @MaLoaiThe = 'VE_NAM', @MaTheDienTu = @GD OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T03 Phát hành loại thẻ không tồn tại -> 50019',
    CASE WHEN @Loi = 50019 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

/* =====================================================================
   2. Top-up
   ===================================================================== */

-- T04 Top up 100,000
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_NapTien @MaTheDienTu = @TheA, @SoTien = 100000, @PhuongThucThanhToan = 'TIEN_MAT',
         @ThoiDiem = '20261029 05:30', @MaGiaoDich = @GDNapA OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheA;
SELECT @Dem = COUNT(*) FROM GiaoDich
WHERE  MaGiaoDich = @GDNapA AND LoaiGiaoDich = 'NAP_TIEN' AND SoTien = 100000 AND MaTheDienTu = @TheA;
INSERT INTO #KetQua VALUES (N'T04 Nạp 100.000: số dư 100.000 và có giao dịch NAP_TIEN',
    CASE WHEN @Loi IS NULL AND @SoDu = 100000 AND @Dem = 1 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Số dư: ', @SoDu, N'; lỗi: ', @Loi));

-- T05 Top up 0
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_NapTien @MaTheDienTu = @TheA, @SoTien = 0, @PhuongThucThanhToan = 'TIEN_MAT',
         @ThoiDiem = '20261029 05:31', @MaGiaoDich = @GD OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T05 Nạp số tiền 0 -> 50003',
    CASE WHEN @Loi = 50003 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T06 Top up with an unknown payment method
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_NapTien @MaTheDienTu = @TheA, @SoTien = 10000, @PhuongThucThanhToan = 'BITCOIN',
         @ThoiDiem = '20261029 05:32', @MaGiaoDich = @GD OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T06 Nạp bằng phương thức không hợp lệ -> 50004',
    CASE WHEN @Loi = 50004 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T07 Top up an unknown card
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_NapTien @MaTheDienTu = 'TH9999999999', @SoTien = 10000, @PhuongThucThanhToan = 'MOMO',
         @ThoiDiem = '20261029 05:33', @MaGiaoDich = @GD OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T07 Nạp vào thẻ không tồn tại -> 50001',
    CASE WHEN @Loi = 50001 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

/* =====================================================================
   3. Bus scans (trip CX20261029001 runs route B32 on 2026-10-29)
   ===================================================================== */

-- T08 Board a bus with the wallet: 7,000 charged
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @TheA, @MaChuyen = 'CX20261029001', @MaTram = 'B002',
         @ThoiDiem = '20261029 06:15', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheA;
SELECT @Dem = COUNT(*) FROM LuotQuetThe
WHERE  MaLuotQuet = @LQ AND MaTuyen = 'B32' AND SoTienDaTru = 7000;
INSERT INTO #KetQua VALUES (N'T08 Quẹt thẻ xe buýt bằng ví: trừ 7.000',
    CASE WHEN @Loi IS NULL AND @Tien = 7000 AND @SoDu = 93000 AND @Dem = 1 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Số dư: ', @SoDu, N'; lỗi: ', @Loi));

-- T09 Scan the same card again on the same trip
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @TheA, @MaChuyen = 'CX20261029001', @MaTram = 'B003',
         @ThoiDiem = '20261029 06:25', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheA;
INSERT INTO #KetQua VALUES (N'T09 Quẹt lại trên cùng chuyến -> 50012, không trừ tiền',
    CASE WHEN @Loi = 50012 AND @SoDu = 93000 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Lỗi: ', @Loi, N'; số dư: ', @SoDu));

-- T10 Trip that has not started
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @TheA, @MaChuyen = 'CX20261029002', @MaTram = 'B004',
         @ThoiDiem = '20261029 06:30', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T10 Quẹt trên chuyến chưa chạy -> 50010',
    CASE WHEN @Loi = 50010 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T11 Stop not on the trip's route (B001 is not on route B09)
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @TheA, @MaChuyen = 'CX20261029003', @MaTram = 'B001',
         @ThoiDiem = '20261029 06:40', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T11 Quẹt tại trạm không thuộc tuyến -> 50011',
    CASE WHEN @Loi = 50011 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T12 Scan on a day the trip does not run
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @TheA, @MaChuyen = 'CX20261029003', @MaTram = 'B007',
         @ThoiDiem = '20261030 06:40', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T12 Quẹt khác ngày chạy của chuyến -> 50010',
    CASE WHEN @Loi = 50010 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T13 Empty wallet: refused, nothing recorded
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK003', @MaLoaiThe = 'VE_LUOT', @MaTheDienTu = @TheB OUTPUT;
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @TheB, @MaChuyen = 'CX20261029001', @MaTram = 'B004',
         @ThoiDiem = '20261029 06:45', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
SELECT @Dem = COUNT(*) FROM LuotQuetThe WHERE MaTheDienTu = @TheB;
INSERT INTO #KetQua VALUES (N'T13 Ví không đủ tiền khi lên xe buýt -> 50009, không ghi lượt quẹt',
    CASE WHEN @Loi = 50009 AND @Dem = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Lỗi: ', @Loi, N'; số lượt: ', @Dem));

/* =====================================================================
   4. Metro (line M2A: Cát Linh = 1 ... Yên Nghĩa = 12)
   ===================================================================== */

-- T14 Tap in: journey opened, nothing charged
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @TheA, @MaTram = 'M2A01',
         @ThoiDiem = '20261029 08:00', @MaLuotQuet = @LQ OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheA;
SELECT @Dem = COUNT(*) FROM LuotQuetThe
WHERE  MaLuotQuet = @LQ AND TrangThai = 'DANG_DI' AND SoTienDaTru = 0;
INSERT INTO #KetQua VALUES (N'T14 Quét vào ga metro: mở hành trình, chưa trừ tiền',
    CASE WHEN @Loi IS NULL AND @Dem = 1 AND @SoDu = 93000 THEN 'PASS' ELSE 'FAIL' END,
    ISNULL(@ThongBao, @LQ));

-- T15 Tap in again while the journey is open
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @TheA, @MaTram = 'M2A02',
         @ThoiDiem = '20261029 08:02', @MaLuotQuet = @GD OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T15 Quét vào lần hai khi chưa quét ra -> 50014',
    CASE WHEN @Loi = 50014 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T16 Tap out 8 stations later: 8,000 + 8 x 700 = 13,600
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetRaMetro @MaTheDienTu = @TheA, @MaTram = 'M2A09',
         @ThoiDiem = '20261029 08:20', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheA;
SELECT @Dem = COUNT(*) FROM LuotQuetThe
WHERE  MaLuotQuet = @LQ AND MaTramQuetRa = 'M2A09' AND MaTuyen = 'M2A' AND SoTienDaTru = 13600;
INSERT INTO #KetQua VALUES (N'T16 Quét ra sau 8 ga: trừ 13.600',
    CASE WHEN @Loi IS NULL AND @Tien = 13600 AND @SoDu = 79400 AND @Dem = 1 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Tiền: ', @Tien, N'; số dư: ', @SoDu, N'; lỗi: ', @Loi));

-- T17 Tap out with no open journey
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetRaMetro @MaTheDienTu = @TheA, @MaTram = 'M2A09',
         @ThoiDiem = '20261029 08:25', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T17 Quét ra khi không có hành trình đang mở -> 50015',
    CASE WHEN @Loi = 50015 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T18 End-to-end journey: 8,000 + 11 x 700 = 15,700, capped at 15,000
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @TheA, @MaTram = 'M2A01',
         @ThoiDiem = '20261029 09:00', @MaLuotQuet = @LQ OUTPUT;
    EXEC dbo.usp_QuetRaMetro @MaTheDienTu = @TheA, @MaTram = 'M2A12',
         @ThoiDiem = '20261029 09:30', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheA;
INSERT INTO #KetQua VALUES (N'T18 Đi hết tuyến: giá vé chạm trần 15.000',
    CASE WHEN @Loi IS NULL AND @Tien = 15000 AND @SoDu = 64400 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Tiền: ', @Tien, N'; số dư: ', @SoDu, N'; lỗi: ', @Loi));

-- T19 Exit on another line is refused; the journey stays open
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @TheA, @MaTram = 'M2A01',
         @ThoiDiem = '20261029 10:00', @MaLuotQuet = @LQ OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
BEGIN TRY
    EXEC dbo.usp_QuetRaMetro @MaTheDienTu = @TheA, @MaTram = 'M301',
         @ThoiDiem = '20261029 10:20', @MaLuotQuet = @GD OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
SELECT @Dem = COUNT(*) FROM LuotQuetThe WHERE MaLuotQuet = @LQ AND TrangThai = 'DANG_DI';
INSERT INTO #KetQua VALUES (N'T19 Quét ra ở ga thuộc tuyến khác -> 50016, hành trình vẫn mở',
    CASE WHEN @Loi = 50016 AND @Dem = 1 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T20 Exit at the entry station: minimum fare 8,000
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetRaMetro @MaTheDienTu = @TheA, @MaTram = 'M2A01',
         @ThoiDiem = '20261029 10:25', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheA;
INSERT INTO #KetQua VALUES (N'T20 Quét ra tại chính ga vào: trừ giá tối thiểu 8.000',
    CASE WHEN @Loi IS NULL AND @Tien = 8000 AND @SoDu = 56400 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Tiền: ', @Tien, N'; số dư: ', @SoDu, N'; lỗi: ', @Loi));

-- T21 Tap in at a bus stop
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @TheA, @MaTram = 'B001',
         @ThoiDiem = '20261029 10:40', @MaLuotQuet = @LQ OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T21 Quét vào metro tại trạm xe buýt -> 50013',
    CASE WHEN @Loi = 50013 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T22 Exit time earlier than entry time
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @TheA, @MaTram = 'M2A03',
         @ThoiDiem = '20261029 11:00', @MaLuotQuet = @LQ OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
BEGIN TRY
    EXEC dbo.usp_QuetRaMetro @MaTheDienTu = @TheA, @MaTram = 'M2A04',
         @ThoiDiem = '20261029 10:59', @MaLuotQuet = @GD OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T22 Thời điểm quét ra trước thời điểm quét vào -> 50017',
    CASE WHEN @Loi = 50017 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));
-- Close that journey normally: 1 station, 8,700
EXEC dbo.usp_QuetRaMetro @MaTheDienTu = @TheA, @MaTram = 'M2A04',
     @ThoiDiem = '20261029 11:10', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;

-- T23 Tap in with a wallet below the minimum fare
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @TheB, @MaTram = 'M2A01',
         @ThoiDiem = '20261029 11:20', @MaLuotQuet = @LQ OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T23 Quét vào metro khi ví dưới giá tối thiểu -> 50009',
    CASE WHEN @Loi = 50009 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T24 Fare above the balance at exit: refused, journey kept open, balance unchanged
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK006', @MaLoaiThe = 'VE_LUOT', @MaTheDienTu = @TheC OUTPUT;
EXEC dbo.usp_NapTien @MaTheDienTu = @TheC, @SoTien = 10000, @PhuongThucThanhToan = 'MOMO',
     @ThoiDiem = '20261029 11:30', @MaGiaoDich = @GD OUTPUT;
EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @TheC, @MaTram = 'M2A01',
     @ThoiDiem = '20261029 11:35', @MaLuotQuet = @LQ OUTPUT;
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetRaMetro @MaTheDienTu = @TheC, @MaTram = 'M2A12',
         @ThoiDiem = '20261029 12:05', @MaLuotQuet = @GD OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheC;
SELECT @Dem = COUNT(*) FROM LuotQuetThe WHERE MaLuotQuet = @LQ AND TrangThai = 'DANG_DI';
INSERT INTO #KetQua VALUES (N'T24 Không đủ tiền khi quét ra -> 50009, hành trình vẫn mở',
    CASE WHEN @Loi = 50009 AND @SoDu = 10000 AND @Dem = 1 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Lỗi: ', @Loi, N'; số dư: ', @SoDu));

/* =====================================================================
   5. Monthly passes
   ===================================================================== */

-- T25 Stored-value card has no pass
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_MuaGoiThang @MaTheDienTu = @TheA, @PhuongThucThanhToan = 'MOMO',
         @ThoiDiem = '20261029 12:00', @MaGiaoDich = @GD OUTPUT, @NgayHetHanMoi = @HetHan OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T25 Mua gói tháng cho thẻ trả trước -> 50005',
    CASE WHEN @Loi = 50005 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T26 Buy a metro pass on 2026-10-29: valid until 2026-11-27 (30 days)
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK003', @MaLoaiThe = 'THANG_METRO', @MaTheDienTu = @TheD OUTPUT;
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_MuaGoiThang @MaTheDienTu = @TheD, @PhuongThucThanhToan = 'VNPAY',
         @ThoiDiem = '20261029 12:10', @MaGiaoDich = @GDGoiD OUTPUT, @NgayHetHanMoi = @HetHan OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @Dem = COUNT(*) FROM GiaoDich
WHERE  MaGiaoDich = @GDGoiD AND LoaiGiaoDich = 'MUA_GOI_THANG' AND SoTien = 200000;
INSERT INTO #KetQua VALUES (N'T26 Mua vé tháng metro: hạn đến 2026-11-27, thu 200.000',
    CASE WHEN @Loi IS NULL AND @HetHan = '20261127' AND @Dem = 1 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Hạn: ', @HetHan, N'; lỗi: ', @Loi));

-- T27 Renew while still valid: extends from 2026-11-28 to 2026-12-27
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_MuaGoiThang @MaTheDienTu = @TheD, @PhuongThucThanhToan = 'VNPAY',
         @ThoiDiem = '20261029 12:15', @MaGiaoDich = @GD OUTPUT, @NgayHetHanMoi = @HetHan OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
INSERT INTO #KetQua VALUES (N'T27 Gia hạn khi còn hạn: nối tiếp đến 2026-12-27',
    CASE WHEN @Loi IS NULL AND @HetHan = '20261227' THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Hạn: ', @HetHan, N'; lỗi: ', @Loi));

-- T28 Metro pass rides the metro free, even with an empty wallet
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @TheD, @MaTram = 'M301',
         @ThoiDiem = '20261029 12:30', @MaLuotQuet = @LQ OUTPUT;
    EXEC dbo.usp_QuetRaMetro @MaTheDienTu = @TheD, @MaTram = 'M308',
         @ThoiDiem = '20261029 12:50', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
INSERT INTO #KetQua VALUES (N'T28 Vé tháng metro đi metro: không trừ tiền',
    CASE WHEN @Loi IS NULL AND @Tien = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Tiền: ', @Tien, N'; lỗi: ', @Loi));

-- T29 Metro pass does not cover the bus
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @TheD, @MaChuyen = 'CX20261029003', @MaTram = 'B007',
         @ThoiDiem = '20261029 13:00', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T29 Vé tháng metro đi xe buýt, ví rỗng -> 50009',
    CASE WHEN @Loi = 50009 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T30 Combined pass rides the bus free
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK005', @MaLoaiThe = 'LIEN_THONG', @MaTheDienTu = @TheE OUTPUT;
EXEC dbo.usp_MuaGoiThang @MaTheDienTu = @TheE, @PhuongThucThanhToan = 'TIEN_MAT',
     @ThoiDiem = '20261029 05:00', @MaGiaoDich = @GD OUTPUT, @NgayHetHanMoi = @HetHan OUTPUT;
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @TheE, @MaChuyen = 'CX20261029003', @MaTram = 'B008',
         @ThoiDiem = '20261029 06:50', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
INSERT INTO #KetQua VALUES (N'T30 Vé liên thông đi xe buýt: không trừ tiền',
    CASE WHEN @Loi IS NULL AND @Tien = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Tiền: ', @Tien, N'; lỗi: ', @Loi));

-- T31 Expired bus pass falls back to the wallet
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK006', @MaLoaiThe = 'THANG_BUS', @MaTheDienTu = @TheF OUTPUT;
EXEC dbo.usp_MuaGoiThang @MaTheDienTu = @TheF, @PhuongThucThanhToan = 'TIEN_MAT',
     @ThoiDiem = '20260901 08:00', @MaGiaoDich = @GD OUTPUT, @NgayHetHanMoi = @HetHan OUTPUT;
EXEC dbo.usp_NapTien @MaTheDienTu = @TheF, @SoTien = 20000, @PhuongThucThanhToan = 'TIEN_MAT',
     @ThoiDiem = '20261029 05:00', @MaGiaoDich = @GD OUTPUT;
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @TheF, @MaChuyen = 'CX20261029001', @MaTram = 'B004',
         @ThoiDiem = '20261029 06:55', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
INSERT INTO #KetQua VALUES (N'T31 Vé tháng xe buýt hết hạn (2026-09-30): trừ 7.000 từ ví',
    CASE WHEN @Loi IS NULL AND @HetHan = '20260930' AND @Tien = 7000 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Hạn: ', @HetHan, N'; tiền: ', @Tien, N'; lỗi: ', @Loi));

/* =====================================================================
   6. Locked cards
   ===================================================================== */

-- T32 A locked card cannot be topped up or scanned; unlocking restores it
EXEC dbo.usp_KhoaThe @MaTheDienTu = @TheB, @BiKhoa = 1;
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_NapTien @MaTheDienTu = @TheB, @SoTien = 10000, @PhuongThucThanhToan = 'MOMO',
         @ThoiDiem = '20261029 13:10', @MaGiaoDich = @GD OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T32 Nạp tiền vào thẻ bị khóa -> 50002',
    CASE WHEN @Loi = 50002 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @TheB, @MaChuyen = 'CX20261029001', @MaTram = 'B005',
         @ThoiDiem = '20261029 07:00', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T33 Quẹt thẻ bị khóa -> 50002',
    CASE WHEN @Loi = 50002 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_KhoaThe @MaTheDienTu = @TheB, @BiKhoa = 0;
    EXEC dbo.usp_NapTien @MaTheDienTu = @TheB, @SoTien = 10000, @PhuongThucThanhToan = 'MOMO',
         @ThoiDiem = '20261029 13:15', @MaGiaoDich = @GD OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheB;
INSERT INTO #KetQua VALUES (N'T34 Mở khóa rồi nạp tiền: thành công',
    CASE WHEN @Loi IS NULL AND @SoDu = 10000 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Số dư: ', @SoDu, N'; lỗi: ', @Loi));

SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_KhoaThe @MaTheDienTu = @TheB, @BiKhoa = 2;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T35 Trạng thái khóa không hợp lệ -> 50022',
    CASE WHEN @Loi = 50022 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

/* =====================================================================
   7. Refunds
   ===================================================================== */

-- T36 Refund a top-up: linked refund row, wallet reduced
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK001', @MaLoaiThe = 'VE_LUOT', @MaTheDienTu = @TheG OUTPUT;
EXEC dbo.usp_NapTien @MaTheDienTu = @TheG, @SoTien = 60000, @PhuongThucThanhToan = 'NGAN_HANG',
     @ThoiDiem = '20261029 14:00', @MaGiaoDich = @GDNapG OUTPUT;
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_HoanTien @MaGiaoDichGoc = @GDNapG, @ThoiDiem = '20261029 14:30', @MaGiaoDich = @GDHoan OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheG;
SELECT @Dem = COUNT(*) FROM GiaoDich
WHERE  MaGiaoDich = @GDHoan AND LoaiGiaoDich = 'HOAN_TIEN' AND MaGiaoDichGoc = @GDNapG
  AND  SoTien = 60000 AND PhuongThucThanhToan = 'NGAN_HANG';
INSERT INTO #KetQua VALUES (N'T36 Hoàn tiền nạp: có giao dịch HOAN_TIEN gắn giao dịch gốc, ví về 0',
    CASE WHEN @Loi IS NULL AND @SoDu = 0 AND @Dem = 1 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Số dư: ', @SoDu, N'; lỗi: ', @Loi));

-- T37 Refund the same top-up twice
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_HoanTien @MaGiaoDichGoc = @GDNapG, @ThoiDiem = '20261029 14:35', @MaGiaoDich = @GD OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T37 Hoàn tiền hai lần cho một giao dịch -> 50008',
    CASE WHEN @Loi = 50008 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T38 Refund after the money was spent
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_HoanTien @MaGiaoDichGoc = @GDNapA, @ThoiDiem = '20261029 14:40', @MaGiaoDich = @GD OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T38 Hoàn tiền khi ví không còn đủ số tiền đã nạp -> 50009',
    CASE WHEN @Loi = 50009 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T39 A monthly pass purchase is not refundable
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_HoanTien @MaGiaoDichGoc = @GDGoiD, @ThoiDiem = '20261029 14:45', @MaGiaoDich = @GD OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T39 Hoàn tiền giao dịch mua gói tháng -> 50007',
    CASE WHEN @Loi = 50007 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T40 Unknown original transaction
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_HoanTien @MaGiaoDichGoc = 'GD9999999999', @ThoiDiem = '20261029 14:50', @MaGiaoDich = @GD OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T40 Hoàn tiền giao dịch không tồn tại -> 50006',
    CASE WHEN @Loi = 50006 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T41 A locked (lost) card can still be refunded
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK001', @MaLoaiThe = 'VE_LUOT', @MaTheDienTu = @TheH OUTPUT;
EXEC dbo.usp_NapTien @MaTheDienTu = @TheH, @SoTien = 40000, @PhuongThucThanhToan = 'MOMO',
     @ThoiDiem = '20261029 15:00', @MaGiaoDich = @GDNapH OUTPUT;
EXEC dbo.usp_KhoaThe @MaTheDienTu = @TheH, @BiKhoa = 1;
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_HoanTien @MaGiaoDichGoc = @GDNapH, @ThoiDiem = '20261029 15:10', @MaGiaoDich = @GD OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheH;
INSERT INTO #KetQua VALUES (N'T41 Hoàn tiền cho thẻ đã khóa (mất thẻ): thành công',
    CASE WHEN @Loi IS NULL AND @SoDu = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Số dư: ', @SoDu, N'; lỗi: ', @Loi));

/* =====================================================================
   8. Data integrity
   ===================================================================== */

-- T42 A timetable entry on a metro route is refused when inserted
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    INSERT INTO LichChay(MaLich, ChieuDi, GioXuatBen, NgayTrongTuan, MaTuyen)
    VALUES ('LTEST', 'LUOT_DI', '15:00', 'HANG_NGAY', 'M2A');
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
SELECT @Dem = COUNT(*) FROM LichChay WHERE MaLich = 'LTEST';
INSERT INTO #KetQua VALUES (N'T42 Thêm lịch chạy vào tuyến metro -> 50020, không lưu',
    CASE WHEN @Loi = 50020 AND @Dem = 0 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

/* =====================================================================
   9. Discounts by passenger category
      HSSV: 50% on monthly passes; NGUOI_CAO_TUOI: 50% on rides and passes
   ===================================================================== */

-- T43 Student monthly bus pass: 140,000 - 50% = 70,000
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK001', @MaLoaiThe = 'THANG_BUS', @MaTheDienTu = @TheI OUTPUT;
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_MuaGoiThang @MaTheDienTu = @TheI, @PhuongThucThanhToan = 'MOMO',
         @ThoiDiem = '20261029 07:00', @MaGiaoDich = @GD OUTPUT, @NgayHetHanMoi = @HetHan OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @Tien = SoTien FROM GiaoDich WHERE MaGiaoDich = @GD;
INSERT INTO #KetQua VALUES (N'T43 Sinh viên mua vé tháng xe buýt: giảm 50% còn 70.000',
    CASE WHEN @Loi IS NULL AND @Tien = 70000 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Tiền: ', @Tien, N'; lỗi: ', @Loi));

-- T44 Senior bus ride: 7,000 - 50% = 3,500
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK004', @MaLoaiThe = 'VE_LUOT', @MaTheDienTu = @TheJ OUTPUT;
EXEC dbo.usp_NapTien @MaTheDienTu = @TheJ, @SoTien = 50000, @PhuongThucThanhToan = 'TIEN_MAT',
     @ThoiDiem = '20261029 06:00', @MaGiaoDich = @GD OUTPUT;
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @TheJ, @MaChuyen = 'CX20261029001', @MaTram = 'B005',
         @ThoiDiem = '20261029 07:10', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheJ;
INSERT INTO #KetQua VALUES (N'T44 Người cao tuổi đi xe buýt: giảm 50% còn 3.500',
    CASE WHEN @Loi IS NULL AND @Tien = 3500 AND @SoDu = 46500 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Tiền: ', @Tien, N'; số dư: ', @SoDu, N'; lỗi: ', @Loi));

-- T45 Senior metro ride over 8 stations: 13,600 - 50% = 6,800
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @TheJ, @MaTram = 'M2A01',
         @ThoiDiem = '20261029 13:00', @MaLuotQuet = @LQ OUTPUT;
    EXEC dbo.usp_QuetRaMetro @MaTheDienTu = @TheJ, @MaTram = 'M2A09',
         @ThoiDiem = '20261029 13:20', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheJ;
INSERT INTO #KetQua VALUES (N'T45 Người cao tuổi đi metro 8 ga: giảm 50% còn 6.800',
    CASE WHEN @Loi IS NULL AND @Tien = 6800 AND @SoDu = 39700 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Tiền: ', @Tien, N'; số dư: ', @SoDu, N'; lỗi: ', @Loi));

/* =====================================================================
   10. Changing metro lines
       Test line MX links line 3 and line 2A: Cầu Giấy (M308) - MXA - Cát Linh (M2A01)
   ===================================================================== */

INSERT INTO Tuyen(MaTuyen, TenTuyen, LoaiPhuongTien) VALUES ('MX', N'Tuyến thử nghiệm nối tuyến 3 và 2A', 'METRO');
INSERT INTO Tram(MaTram, TenTram, LoaiPhuongTien) VALUES ('MXA', N'Ga thử nghiệm', 'METRO');
INSERT INTO TuyenTram(MaTuyen, MaTram, ThuTuTram) VALUES ('MX', 'M308', 1), ('MX', 'MXA', 2), ('MX', 'M2A01', 3);

-- T46 Đại học Quốc gia (line 3) -> Láng... Thái Hà (line 2A): 6 stations, 8,000 + 6 x 700 = 12,200
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @TheA, @MaTram = 'M306',
         @ThoiDiem = '20261029 15:30', @MaLuotQuet = @LQ OUTPUT;
    EXEC dbo.usp_QuetRaMetro @MaTheDienTu = @TheA, @MaTram = 'M2A03',
         @ThoiDiem = '20261029 15:55', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheA;
SELECT @Dem = COUNT(*) FROM LuotQuetThe WHERE MaLuotQuet = @LQ AND MaTuyen IS NULL AND TrangThai = 'HOAN_THANH';
INSERT INTO #KetQua VALUES (N'T46 Chuyển tuyến 3 -> 2A: 6 ga, trừ 12.200, không gắn một tuyến',
    CASE WHEN @Loi IS NULL AND @Tien = 12200 AND @SoDu = 35500 AND @Dem = 1 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Tiền: ', @Tien, N'; số dư: ', @SoDu, N'; lỗi: ', @Loi));

-- T47 Station not connected to the network
INSERT INTO Tram(MaTram, TenTram, LoaiPhuongTien) VALUES ('MISO', N'Ga chưa nối mạng', 'METRO');
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @TheA, @MaTram = 'MISO',
         @ThoiDiem = '20261029 16:00', @MaLuotQuet = @LQ OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
BEGIN TRY
    EXEC dbo.usp_QuetRaMetro @MaTheDienTu = @TheA, @MaTram = 'M2A01',
         @ThoiDiem = '20261029 16:10', @MaLuotQuet = @GD OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T47 Ga vào và ga ra không nối với nhau -> 50016',
    CASE WHEN @Loi = 50016 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

/* =====================================================================
   11. Metro journeys that were never tapped out
       Penalty = maximum fare 15,000, less discount, at most the balance
   ===================================================================== */

-- T48 Staff closes the open journey: penalty 15,000
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_DongHanhTrinhMetro @MaTheDienTu = @TheA, @MaLuotQuet = @LQ OUTPUT, @SoTienPhat = @Tien OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheA;
SELECT @Dem = COUNT(*) FROM LuotQuetThe
WHERE  MaLuotQuet = @LQ AND TrangThai = 'KHONG_QUET_RA' AND SoTienDaTru = 15000 AND MaTramQuetRa IS NULL;
INSERT INTO #KetQua VALUES (N'T48 Nhân viên đóng hành trình chưa quét ra: phạt 15.000',
    CASE WHEN @Loi IS NULL AND @Tien = 15000 AND @SoDu = 20500 AND @Dem = 1 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Tiền: ', @Tien, N'; số dư: ', @SoDu, N'; lỗi: ', @Loi));

-- T49 Nothing left to close
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_DongHanhTrinhMetro @MaTheDienTu = @TheA, @MaLuotQuet = @LQ OUTPUT, @SoTienPhat = @Tien OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T49 Đóng hành trình khi không có hành trình đang mở -> 50015',
    CASE WHEN @Loi = 50015 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T50 Yesterday's open journey is closed with a penalty at the next tap-in
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK002', @MaLoaiThe = 'VE_LUOT', @MaTheDienTu = @TheK OUTPUT;
EXEC dbo.usp_NapTien @MaTheDienTu = @TheK, @SoTien = 30000, @PhuongThucThanhToan = 'MOMO',
     @ThoiDiem = '20261028 20:00', @MaGiaoDich = @GD OUTPUT;
EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @TheK, @MaTram = 'M2A05',
     @ThoiDiem = '20261028 21:00', @MaLuotQuet = @LQ OUTPUT;
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @TheK, @MaTram = 'M2A06',
         @ThoiDiem = '20261029 07:00', @MaLuotQuet = @GD OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheK;
SELECT @Dem = COUNT(*) FROM LuotQuetThe
WHERE  (MaLuotQuet = @LQ AND TrangThai = 'KHONG_QUET_RA' AND SoTienDaTru = 15000)
   OR  (MaLuotQuet = @GD AND TrangThai = 'DANG_DI');
INSERT INTO #KetQua VALUES (N'T50 Quét vào hôm sau: hành trình hôm trước bị phạt 15.000, mở hành trình mới',
    CASE WHEN @Loi IS NULL AND @SoDu = 15000 AND @Dem = 2 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Số dư: ', @SoDu, N'; lỗi: ', ISNULL(@ThongBao, CAST(@Loi AS nvarchar(10)))));

-- T51 Nightly job closes every journey tapped in before 2026-10-30:
--     the seeded HK001 journey, @TheC (T24) and @TheK (T50)
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_DongHanhTrinhQuaHan @TruocNgay = '20261030', @SoHanhTrinh = @Dem OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
INSERT INTO #KetQua VALUES (N'T51 Đóng hành trình quá hạn hằng đêm: đóng 3 hành trình, không còn hành trình mở',
    CASE WHEN @Loi IS NULL AND @Dem = 3
              AND NOT EXISTS (SELECT 1 FROM LuotQuetThe
                              WHERE TrangThai = 'DANG_DI' AND ThoiDiemQuetVao < '20261030')
         THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Số hành trình: ', @Dem, N'; lỗi: ', ISNULL(@ThongBao, CAST(@Loi AS nvarchar(10)))));

-- T52 The penalty never exceeds the balance (@TheC held 10,000)
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheC;
SELECT @Dem = COUNT(*) FROM LuotQuetThe
WHERE  MaTheDienTu = @TheC AND TrangThai = 'KHONG_QUET_RA' AND SoTienDaTru = 10000;
INSERT INTO #KetQua VALUES (N'T52 Tiền phạt không vượt quá số dư: phạt 10.000, ví về 0',
    CASE WHEN @SoDu = 0 AND @Dem = 1 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Số dư: ', @SoDu));

/* =====================================================================
   12. Card replacement
   ===================================================================== */

-- T53 Replace a card: balance moves, old card locked, transfer recorded
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK002', @MaLoaiThe = 'VE_LUOT', @MaTheDienTu = @TheL OUTPUT;
EXEC dbo.usp_NapTien @MaTheDienTu = @TheL, @SoTien = 50000, @PhuongThucThanhToan = 'VNPAY',
     @ThoiDiem = '20261029 16:30', @MaGiaoDich = @GD OUTPUT;
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_DoiThe @MaTheCu = @TheL, @ThoiDiem = '20261029 17:00', @MaTheMoi = @TheL2 OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @Dem = COUNT(*)
FROM   TheVeDienTu moi
       INNER JOIN TheVeDienTu cu ON cu.MaTheDienTu = moi.MaTheCu
WHERE  moi.MaTheDienTu = @TheL2 AND moi.SoDuVi = 50000 AND moi.BiKhoa = 0
  AND  moi.MaLoaiThe = 'VE_LUOT' AND moi.MaHanhKhach = 'HK002'
  AND  cu.MaTheDienTu = @TheL AND cu.SoDuVi = 0 AND cu.BiKhoa = 1;
SELECT @SoDu = COUNT(*)
FROM   GiaoDich di
       INNER JOIN GiaoDich den ON den.MaGiaoDichGoc = di.MaGiaoDich
WHERE  di.LoaiGiaoDich = 'CHUYEN_DI'   AND di.MaTheDienTu = @TheL   AND di.SoTien = 50000
  AND  den.LoaiGiaoDich = 'CHUYEN_DEN' AND den.MaTheDienTu = @TheL2 AND den.SoTien = 50000;
INSERT INTO #KetQua VALUES (N'T53 Đổi thẻ: chuyển 50.000 sang thẻ mới, khóa thẻ cũ, ghi cặp giao dịch chuyển',
    CASE WHEN @Loi IS NULL AND @Dem = 1 AND @SoDu = 1 THEN 'PASS' ELSE 'FAIL' END,
    ISNULL(@ThongBao, @TheL2));

-- T54 Replace the same card twice
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_DoiThe @MaTheCu = @TheL, @ThoiDiem = '20261029 17:05', @MaTheMoi = @GD OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T54 Đổi thẻ đã được đổi -> 50024',
    CASE WHEN @Loi = 50024 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T55 A replaced card cannot be unlocked
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_KhoaThe @MaTheDienTu = @TheL, @BiKhoa = 0;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T55 Mở khóa thẻ đã được thay -> 50024',
    CASE WHEN @Loi = 50024 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T56 A card with a journey in progress cannot be replaced
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK003', @MaLoaiThe = 'VE_LUOT', @MaTheDienTu = @TheM OUTPUT;
EXEC dbo.usp_NapTien @MaTheDienTu = @TheM, @SoTien = 20000, @PhuongThucThanhToan = 'MOMO',
     @ThoiDiem = '20261029 16:40', @MaGiaoDich = @GD OUTPUT;
EXEC dbo.usp_QuetVaoMetro @MaTheDienTu = @TheM, @MaTram = 'M2A01',
     @ThoiDiem = '20261029 17:00', @MaLuotQuet = @LQ OUTPUT;
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_DoiThe @MaTheCu = @TheM, @ThoiDiem = '20261029 17:10', @MaTheMoi = @GD OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T56 Đổi thẻ đang có hành trình metro -> 50023',
    CASE WHEN @Loi = 50023 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));
EXEC dbo.usp_DongHanhTrinhMetro @MaTheDienTu = @TheM, @MaLuotQuet = @LQ OUTPUT, @SoTienPhat = @Tien OUTPUT;

-- T57 Replacing a pass card keeps the pass; an empty wallet records no transfer
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_DoiThe @MaTheCu = @TheD, @ThoiDiem = '20261029 17:20', @MaTheMoi = @TheD2 OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @HetHan = NgayHetHan FROM TheVeDienTu WHERE MaTheDienTu = @TheD2;
SELECT @Dem = COUNT(*) FROM GiaoDich
WHERE  MaTheDienTu IN (@TheD, @TheD2) AND LoaiGiaoDich IN ('CHUYEN_DI', 'CHUYEN_DEN');
INSERT INTO #KetQua VALUES (N'T57 Đổi thẻ vé tháng: giữ hạn 2026-12-27, ví rỗng không ghi giao dịch chuyển',
    CASE WHEN @Loi IS NULL AND @HetHan = '20261227' AND @Dem = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Hạn: ', @HetHan, N'; lỗi: ', @Loi));

-- T58 The new card rides; T59 the old card is refused
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @TheL2, @MaChuyen = 'CX20261029001', @MaTram = 'B006',
         @ThoiDiem = '20261029 18:00', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @SoDu = SoDuVi FROM TheVeDienTu WHERE MaTheDienTu = @TheL2;
INSERT INTO #KetQua VALUES (N'T58 Thẻ mới đi xe buýt: trừ 7.000 từ số dư đã chuyển',
    CASE WHEN @Loi IS NULL AND @Tien = 7000 AND @SoDu = 43000 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(N'Số dư: ', @SoDu, N'; lỗi: ', @Loi));

SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @TheL, @MaChuyen = 'CX20261029003', @MaTram = 'B007',
         @ThoiDiem = '20261029 18:05', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T59 Thẻ cũ đã thay -> 50002',
    CASE WHEN @Loi = 50002 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

/* =====================================================================
   13. Bus operations (2026-10-31 is a Saturday)
   ===================================================================== */

-- T60 Create a trip from the timetable
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_TaoChuyenXe @MaLich = 'L32V0700', @NgayChay = '20261031', @MaXe = 'XB02',
         @MaTaiXe = 'NV02', @MaPhuXe = 'NV05', @MaChuyen = @MaChuyen OUTPUT;
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @Dem = COUNT(*) FROM ChuyenXe WHERE MaChuyen = 'CX20261031L32V0700' AND TrangThai = 'CHUA_CHAY';
INSERT INTO #KetQua VALUES (N'T60 Tạo chuyến từ lịch chạy: CX20261031L32V0700, chưa chạy',
    CASE WHEN @Loi IS NULL AND @MaChuyen = 'CX20261031L32V0700' AND @Dem = 1 THEN 'PASS' ELSE 'FAIL' END,
    ISNULL(@ThongBao, @MaChuyen));

-- T61 Same timetable entry twice on one day
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_TaoChuyenXe @MaLich = 'L32V0700', @NgayChay = '20261031', @MaXe = 'XB01',
         @MaTaiXe = 'NV01', @MaPhuXe = 'NV04', @MaChuyen = @MaChuyen OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T61 Tạo trùng chuyến trong ngày -> 50031',
    CASE WHEN @Loi = 50031 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T62 Weekday timetable on a Saturday
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_TaoChuyenXe @MaLich = 'L09D0630', @NgayChay = '20261031', @MaXe = 'XB03',
         @MaTaiXe = 'NV03', @MaPhuXe = 'NV06', @MaChuyen = @MaChuyen OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T62 Lịch ngày thường tạo chuyến vào thứ Bảy -> 50027',
    CASE WHEN @Loi = 50027 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T63 Bus under maintenance
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_TaoChuyenXe @MaLich = 'L32D0600', @NgayChay = '20261101', @MaXe = 'XB04',
         @MaTaiXe = 'NV01', @MaPhuXe = 'NV04', @MaChuyen = @MaChuyen OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T63 Tạo chuyến với xe đang bảo trì -> 50028',
    CASE WHEN @Loi = 50028 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T64 An attendant assigned as the driver
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_TaoChuyenXe @MaLich = 'L32D0600', @NgayChay = '20261101', @MaXe = 'XB01',
         @MaTaiXe = 'NV04', @MaPhuXe = 'NV05', @MaChuyen = @MaChuyen OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T64 Phân công phụ xe làm tài xế -> 50029',
    CASE WHEN @Loi = 50029 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T65 Unknown timetable entry
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_TaoChuyenXe @MaLich = 'LXXX', @NgayChay = '20261101', @MaXe = 'XB01',
         @MaTaiXe = 'NV01', @MaPhuXe = 'NV04', @MaChuyen = @MaChuyen OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T65 Tạo chuyến từ lịch chạy không tồn tại -> 50026',
    CASE WHEN @Loi = 50026 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T66 A trip that has not started cannot be completed
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_CapNhatTrangThaiChuyen @MaChuyen = 'CX20261031L32V0700', @TrangThaiMoi = 'HOAN_THANH';
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T66 Chuyển chuyến chưa chạy sang hoàn thành -> 50030',
    CASE WHEN @Loi = 50030 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T67 Depart, then arrive
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_CapNhatTrangThaiChuyen @MaChuyen = 'CX20261031L32V0700', @TrangThaiMoi = 'DANG_CHAY';
    EXEC dbo.usp_CapNhatTrangThaiChuyen @MaChuyen = 'CX20261031L32V0700', @TrangThaiMoi = 'HOAN_THANH';
END TRY BEGIN CATCH SELECT @Loi = ERROR_NUMBER(), @ThongBao = ERROR_MESSAGE(); END CATCH;
SELECT @Dem = COUNT(*) FROM ChuyenXe WHERE MaChuyen = 'CX20261031L32V0700' AND TrangThai = 'HOAN_THANH';
INSERT INTO #KetQua VALUES (N'T67 Xuất bến rồi hoàn thành chuyến',
    CASE WHEN @Loi IS NULL AND @Dem = 1 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@ThongBao, N''));

/* =====================================================================
   14. Reports
   ===================================================================== */

-- T68 Rides on route B32 on 2026-10-29: T08, T31, T44, T58
SELECT @Dem = SoLuotDi FROM dbo.v_LuotDiTheoTuyen WHERE Ngay = '20261029' AND MaTuyen = 'B32';
INSERT INTO #KetQua VALUES (N'T68 Báo cáo lượt đi theo tuyến: B32 ngày 2026-10-29 có 4 lượt',
    CASE WHEN @Dem = 4 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Số lượt: ', @Dem));

-- T69 Penalties on 2026-10-29 (by day of entry): T48, T51 (3 journeys), T56 = 70,000
SELECT @Tien = TienPhat,
       @SoDu = DoanhThu - (TienBanGoiThang + TienVe + TienPhat)
FROM   dbo.v_DoanhThuTheoNgay WHERE Ngay = '20261029';
INSERT INTO #KetQua VALUES (N'T69 Báo cáo doanh thu ngày 2026-10-29: tiền phạt 70.000, doanh thu cộng đúng',
    CASE WHEN @Tien = 70000 AND @SoDu = 0 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Tiền phạt: ', @Tien));

-- T70 Card status shows the replacement
SELECT @Dem = COUNT(*) FROM dbo.v_TinhTrangThe
WHERE  MaTheDienTu = @TheL AND MaTheThayThe = @TheL2 AND BiKhoa = 1 AND SoDuVi = 0;
INSERT INTO #KetQua VALUES (N'T70 Báo cáo tình trạng thẻ: thẻ cũ chỉ tới thẻ thay thế',
    CASE WHEN @Dem = 1 THEN 'PASS' ELSE 'FAIL' END, N'');

-- T71 Every wallet balance matches its history
SELECT @Dem = COUNT(*) FROM dbo.v_DoiSoatSoDu WHERE ChenhLech <> 0;
INSERT INTO #KetQua VALUES (N'T71 Đối soát: số dư mọi thẻ khớp lịch sử nạp, hoàn, chuyển, trừ',
    CASE WHEN @Dem = 0 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Số thẻ lệch: ', @Dem));

/* =====================================================================
   Results
   ===================================================================== */

SELECT STT, TenTest, KetQua, ChiTiet FROM #KetQua ORDER BY STT;

SELECT COUNT(*)                                        AS TongSoTest,
       SUM(CASE WHEN KetQua = 'PASS' THEN 1 ELSE 0 END) AS SoPass,
       SUM(CASE WHEN KetQua = 'FAIL' THEN 1 ELSE 0 END) AS SoFail
FROM   #KetQua;
GO
