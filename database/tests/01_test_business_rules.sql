/* =====================================================================
   01_test_business_rules.sql
   Tests for the business procedures. Each test records PASS or FAIL in
   #KetQua; the result table and a summary are shown at the end.

   Run on a freshly built database (schema + procedures + seed): the tests
   create their own cards and change data, so rebuild before re-running.
   All tests take place on 2026-10-29, matching the seeded bus trips.
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
WHERE  MaLuotQuet = @LQ AND MaTramQuetRa IS NULL AND SoTienDaTru = 0;
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
SELECT @Dem = COUNT(*) FROM LuotQuetThe WHERE MaLuotQuet = @LQ AND MaTramQuetRa IS NULL;
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
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK004', @MaLoaiThe = 'VE_LUOT', @MaTheDienTu = @TheC OUTPUT;
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
SELECT @Dem = COUNT(*) FROM LuotQuetThe WHERE MaLuotQuet = @LQ AND MaTramQuetRa IS NULL;
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
EXEC dbo.usp_PhatHanhThe @MaHanhKhach = 'HK004', @MaLoaiThe = 'THANG_METRO', @MaTheDienTu = @TheD OUTPUT;
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

-- T42 A bus trip scheduled on a metro route is refused at scan time
INSERT INTO LichChay(MaLich, ChieuDi, GioXuatBen, NgayTrongTuan, MaTuyen)
VALUES ('LTEST', 'LUOT_DI', '15:00', 'HANG_NGAY', 'M2A');
INSERT INTO ChuyenXe(MaChuyen, NgayChay, TrangThai, MaLich, MaXe, MaTaiXe, MaPhuXe)
VALUES ('CXTEST', '20261029', 'DANG_CHAY', 'LTEST', 'XB02', 'NV02', 'NV05');
SELECT @Loi = NULL, @ThongBao = NULL;
BEGIN TRY
    EXEC dbo.usp_QuetTheXeBuyt @MaTheDienTu = @TheF, @MaChuyen = 'CXTEST', @MaTram = 'M2A01',
         @ThoiDiem = '20261029 15:05', @MaLuotQuet = @LQ OUTPUT, @SoTienDaTru = @Tien OUTPUT;
END TRY BEGIN CATCH SET @Loi = ERROR_NUMBER(); END CATCH;
INSERT INTO #KetQua VALUES (N'T42 Chuyến xe gắn với tuyến metro -> 50020',
    CASE WHEN @Loi = 50020 THEN 'PASS' ELSE 'FAIL' END, CONCAT(N'Lỗi: ', @Loi));

-- T43 Every wallet balance equals top-ups - refunds - fares charged
SELECT @Dem = COUNT(*)
FROM   TheVeDienTu t
WHERE  t.SoDuVi <>
         ISNULL((SELECT SUM(SoTien) FROM GiaoDich g
                 WHERE g.MaTheDienTu = t.MaTheDienTu AND g.LoaiGiaoDich = 'NAP_TIEN'), 0)
       - ISNULL((SELECT SUM(SoTien) FROM GiaoDich g
                 WHERE g.MaTheDienTu = t.MaTheDienTu AND g.LoaiGiaoDich = 'HOAN_TIEN'), 0)
       - ISNULL((SELECT SUM(SoTienDaTru) FROM LuotQuetThe q
                 WHERE q.MaTheDienTu = t.MaTheDienTu), 0);
INSERT INTO #KetQua VALUES (N'T43 Số dư mọi thẻ khớp lịch sử nạp - hoàn - trừ',
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
