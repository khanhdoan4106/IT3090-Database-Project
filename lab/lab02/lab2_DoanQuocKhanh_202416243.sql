/* =========================================================
   BÀI THỰC HÀNH SỐ 2 
   Môn: Cơ sở dữ liệu – IT3090
   Họ tên: Đoàn Quốc Khánh   MSSV: 202416243
   ========================================================= */

USE QuanLyBongDa;
GO

/* =========================================================
   a. TRUY VẤN CƠ BẢN
   ========================================================= */

-- a1. Cho biết thông tin (mã cầu thủ, họ tên, số áo, vị trí, ngày sinh, địa chỉ) của tất cả các cầu thủ
SELECT MACT, HOTEN, SO, VITRI, NGAYSINH, DIACHI FROM CAUTHU

-- a2. Hiển thị thông tin tất cả các cầu thủ có số áo là 7 chơi ở vị trí Tiền vệ
SELECT * FROM CAUTHU  WHERE SO = 7 AND VITRI = N'Tiền vệ'

-- a3. Cho biết tên, ngày sinh, địa chỉ, điện thoại của tất cả các huấn luyện viên
SELECT TENHLV, NGAYSINH, DIACHI, DIENTHOAI FROM HUANLUYENVIEN

-- a4. Hiển thị thông tin tất cả các cầu thủ có quốc tịch Việt Nam thuộc câu lạc bộ Becamex Bình Dương
SELECT * FROM CAUTHU ct
JOIN QUOCGIA qg ON ct.MAQG = qg.MAQG
JOIN CAULACBO clb ON ct.MACLB = clb.MACLB
WHERE qg.TENQG = N'Việt Nam' AND clb.TENCLB = N'Becamex Bình Dương'

-- a5. Cho biết mã số, họ tên, ngày sinh, địa chỉ và vị trí của các cầu thủ thuộc đội bóng 'SHB Đà Nẵng'
--     có quốc tịch 'Bra-xin'
SELECT MACT, HOTEN, NGAYSINH, DIACHI, VITRI FROM CAUTHU ct
JOIN CAULACBO clb ON ct.MACLB = clb.MACLB
JOIN QUOCGIA qg ON ct.MAQG = qg.MAQG
WHERE clb.TENCLB = N'SHB Đà Nẵng' AND qg.TENQG = N'Bra-xin'

-- a6. Hiển thị thông tin tất cả các cầu thủ đang thi đấu trong câu lạc bộ có sân nhà là "Long An"
SELECT * FROM CAUTHU ct
JOIN CAULACBO clb ON ct.MACLB = clb.MACLB
JOIN SANVD svd ON clb.MASAN = svd.MASAN
WHERE svd.TENSAN = N'Long An'

-- a7. Cho biết kết quả (MATRAN, NGAYTD, TENSAN, TENCLB1, TENCLB2, KETQUA) các trận đấu vòng 2 của mùa bóng năm 2009
SELECT MATRAN, NGAYTD, TENSAN, clb1.TENCLB as TENCLB1, clb2.TENCLB as TENCLB2, KETQUA FROM TRANDAU td
JOIN SANVD svd ON td.MASAN = svd.MASAN
JOIN CAULACBO clb1 ON td.MACLB1 = clb1.MACLB
JOIN CAULACBO clb2 ON td.MACLB2 = clb2.MACLB
WHERE td.VONG = 2 AND td.NAM = 2009

-- a8. Cho biết mã huấn luyện viên, họ tên, ngày sinh, địa chỉ, vai trò và tên CLB đang làm việc
--     của các huấn luyện viên có quốc tịch "Việt Nam"
SELECT hlv.MAHLV , TENHLV, NGAYSINH, DIACHI, VAITRO, TENCLB FROM HUANLUYENVIEN hlv
JOIN HLV_CLB hc ON hlv.MAHLV = hc.MAHLV
JOIN CAULACBO clb ON hc.MACLB = clb.MACLB
JOIN QUOCGIA qg ON HLV.MAQG = qg.MAQG
WHERE TENQG = N'Việt Nam'

-- a9. Lấy tên 3 câu lạc bộ có điểm cao nhất sau vòng 3 năm 2009
SELECT TOP 3 clb.TENCLB FROM CAULACBO clb
JOIN BANGXH bxh ON bxh.MACLB = clb.MACLB
WHERE bxh.VONG = 3 AND bxh.NAM = 2009
ORDER BY bxh.DIEM DESC

-- a10. Cho biết mã huấn luyện viên, họ tên, ngày sinh, địa chỉ, vai trò và tên CLB đang làm việc
--      mà câu lạc bộ đó đóng ở tỉnh Bình Dương
SELECT hlv.MAHLV, hlv.TENHLV, hlv.NGAYSINH, hlv.DIACHI, hc.VAITRO , clb.TENCLB FROM HUANLUYENVIEN hlv
JOIN HLV_CLB hc ON hc.MAHLV = hlv.MAHLV
JOIN CAULACBO clb ON clb.MACLB = hc.MACLB
JOIN TINH t ON t.MATINH = clb.MATINH
WHERE t.TENTINH = N'Bình Dương'


/* =========================================================
   b. CÁC PHÉP TOÁN TRÊN NHÓM
   ========================================================= */

-- b1. Thống kê số lượng cầu thủ của mỗi câu lạc bộ
SELECT clb.MACLB, clb.TENCLB, COUNT(ct.MACT) AS SOLUONG_CAUTHU FROM CAULACBO clb
LEFT JOIN CAUTHU ct ON clb.MACLB = ct.MACLB
GROUP BY clb.MACLB, clb.TENCLB;

-- b2. Thống kê số lượng cầu thủ nước ngoài (có quốc tịch khác Việt Nam) của mỗi câu lạc bộ
SELECT clb.MACLB, clb.TENCLB, COUNT(ct.MACT) AS SOLUONG_CAUTHUNGOAI FROM CAULACBO clb
LEFT JOIN CAUTHU ct ON clb.MACLB = ct.MACLB AND ct.MAQG <> (SELECT MAQG FROM QUOCGIA WHERE TENQG = N'Việt Nam')
GROUP BY clb.MACLB, clb.TENCLB

-- b3. Cho biết mã câu lạc bộ, tên câu lạc bộ, tên sân vận động, địa chỉ và số lượng cầu thủ nước ngoài
--     (có quốc tịch khác Việt Nam) tương ứng của các câu lạc bộ có nhiều hơn 2 cầu thủ nước ngoài
SELECT clb.MACLB, clb.TENCLB, svd.TENSAN, svd.DIACHI, COUNT( ct.MACT) AS SOLUONG_CAUTHUNGOAI  FROM CAULACBO clb
JOIN SANVD svd ON svd.MASAN = clb.MASAN
JOIN CAUTHU ct ON ct.MACLB = clb.MACLB
WHERE ct.MAQG <> ( SELECT MAQG FROM QUOCGIA WHERE TENQG = N'Việt Nam')
GROUP BY clb.MACLB, clb.TENCLB, svd.TENSAN, svd.DIACHI
HAVING COUNT( ct.MACT) > 2

-- b4. Cho biết tên tỉnh, số lượng cầu thủ đang thi đấu ở vị trí tiền đạo trong các câu lạc bộ thuộc địa bàn tỉnh đó quản lý
SELECT t.TENTINH, COUNT( ct.MACT) AS SOLUONG_TIENDAO FROM TINH t
JOIN CAULACBO clb ON t.MATINH = clb.MATINH
LEFT JOIN CAUTHU ct ON clb.MACLB = ct.MACLB
AND ct.VITRI = N'Tiền đạo'
GROUP BY t.TENTINH

-- b5. Cho biết tên câu lạc bộ, tên tỉnh mà CLB đang đóng nằm ở vị trí cao nhất của bảng xếp hạng vòng 3, năm 2009
SELECT clb.TENCLB, t.TENTINH FROM BANGXH bxh
JOIN CAULACBO clb ON bxh.MACLB = clb.MACLB
JOIN TINH t ON t.MATINH = clb.MATINH
WHERE bxh.VONG = 3 AND bxh.NAM = 2009 AND bxh.HANG = 1


/* =========================================================
   c. CÁC TOÁN TỬ NÂNG CAO
   ========================================================= */

-- c1. Cho biết tên huấn luyện viên đang nắm giữ một vị trí trong một câu lạc bộ mà chưa có số điện thoại
SELECT hlv.TENHLV FROM HUANLUYENVIEN hlv
WHERE hlv.DIENTHOAI IS NULL AND EXISTS ( SELECT 1 FROM HLV_CLB hc WHERE hlv.MAHLV = hc.MAHLV)

-- c2. Liệt kê các huấn luyện viên thuộc quốc gia Việt Nam chưa làm công tác huấn luyện tại bất kỳ một câu lạc bộ nào
SELECT hlv.* FROM HUANLUYENVIEN hlv
JOIN QUOCGIA qg ON qg.MAQG = hlv.MAQG
WHERE qg.TENQG = N'Việt Nam' AND NOT EXISTS ( SELECT 1 FROM HLV_CLB hc WHERE hlv.MAHLV = hc.MAHLV)

-- c3. Liệt kê các cầu thủ đang thi đấu trong các câu lạc bộ có thứ hạng ở vòng 3 năm 2009 lớn hơn 6 hoặc nhỏ hơn 3
SELECT ct.* FROM CAUTHU ct
WHERE ct.MACLB IN ( SELECT MACLB FROM BANGXH WHERE VONG = 3 AND NAM = 2009 AND ( HANG < 3 OR HANG > 6))

-- c4. Cho biết danh sách các trận đấu (NGAYTD, TENSAN, TENCLB1, TENCLB2, KETQUA) của câu lạc bộ (CLB)
--     đang xếp hạng cao nhất tính đến hết vòng 3 năm 2009
SELECT td.NGAYTD, svd.TENSAN, clb1.TENCLB AS TENCLB1, clb2.TENCLB AS TENCLB2, td.KETQUA FROM TRANDAU td
JOIN SANVD svd ON td.MASAN  = svd.MASAN
JOIN CAULACBO clb1  ON td.MACLB1 = clb1.MACLB
JOIN CAULACBO clb2  ON td.MACLB2 = clb2.MACLB
WHERE EXISTS (SELECT 1 FROM BANGXH bxh WHERE bxh.VONG = 3 AND bxh.NAM = 2009 AND bxh.HANG = 1  AND bxh.MACLB IN (td.MACLB1, td.MACLB2));
