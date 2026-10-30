/* =====================================================================
   File 06: Bộ truy vấn mẫu (từ cơ bản đến nâng cao) để trình bày trong báo cáo
   Mỗi câu ghi rõ: yêu cầu nghiệp vụ + kỹ thuật SQL sử dụng.
   Chạy từng câu (bôi đen rồi F5) để xem kết quả.
   ===================================================================== */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE QuanLyTinChi;
GO

/* =========================== MỨC 1: CƠ BẢN =========================== */

-- Q1. Danh sách môn học từ 3 tín chỉ trở lên, sắp xếp theo tên
--     Kỹ thuật: SELECT, WHERE, ORDER BY
SELECT MaMH, TenMH, SoTinChi
FROM dbo.MonHoc
WHERE SoTinChi >= 3
ORDER BY TenMH;

-- Q2. Sinh viên nữ khóa 2025 có họ Nguyễn
--     Kỹ thuật: LIKE, AND
SELECT MaSV, HoTen, NgaySinh, Email
FROM dbo.SinhVien
WHERE GioiTinh = N'Nữ' AND NienKhoa = '2025-2030' AND HoTen LIKE N'Nguyễn %';

-- Q3. Số sinh viên theo từng khoa và khóa
--     Kỹ thuật: GROUP BY nhiều cột, COUNT
SELECT MaKhoa, NienKhoa, COUNT(*) AS SoSinhVien
FROM dbo.SinhVien
GROUP BY MaKhoa, NienKhoa
ORDER BY NienKhoa, MaKhoa;

/* =========================== MỨC 2: KẾT NỐI ========================== */

-- Q4. Các lớp học phần đang mở đăng ký kỳ 20262: tên môn, giảng viên, chỗ trống
--     Kỹ thuật: INNER JOIN 3 bảng
SELECT l.MaLHP, mh.TenMH, mh.SoTinChi, gv.HoTen AS GiangVien,
       l.SiSoHienTai, l.SiSoToiDa, l.SiSoToiDa - l.SiSoHienTai AS ChoTrong
FROM dbo.LopHocPhan l
JOIN dbo.MonHoc mh    ON mh.MaMH = l.MaMH
JOIN dbo.GiangVien gv ON gv.MaGV = l.MaGV
WHERE l.MaHK = '20262'
ORDER BY l.MaLHP;

-- Q5. Giảng viên chưa được phân công dạy lớp nào trong kỳ 20262
--     Kỹ thuật: LEFT JOIN + IS NULL
SELECT gv.MaGV, gv.HoTen, gv.MaKhoa
FROM dbo.GiangVien gv
LEFT JOIN dbo.LopHocPhan l ON l.MaGV = gv.MaGV AND l.MaHK = '20262'
WHERE l.MaLHP IS NULL;

-- Q6. Danh sách môn kèm các môn tiên quyết trực tiếp
--     Kỹ thuật: SELF JOIN (bảng MonHoc nối với chính nó qua MonTienQuyet)
SELECT m.MaMH, m.TenMH, tq.MaMH AS MaTienQuyet, tq.TenMH AS TenTienQuyet
FROM dbo.MonTienQuyet x
JOIN dbo.MonHoc m  ON m.MaMH = x.MaMH
JOIN dbo.MonHoc tq ON tq.MaMH = x.MaMHTienQuyet
ORDER BY m.MaMH;

/* ========================= MỨC 3: GOM NHÓM =========================== */

-- Q7. Môn có tỷ lệ trượt trên 10% trong kỳ 20252
--     Kỹ thuật: GROUP BY + HAVING + biểu thức điều kiện
SELECT l.MaMH, mh.TenMH,
       COUNT(*) AS SoSV,
       SUM(CASE WHEN dk.DiemTK < 4 THEN 1 ELSE 0 END) AS SoTruot,
       CAST(100.0 * SUM(CASE WHEN dk.DiemTK < 4 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS TyLeTruot
FROM dbo.DangKy dk
JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
JOIN dbo.MonHoc mh    ON mh.MaMH = l.MaMH
WHERE l.MaHK = '20252' AND dk.DiemTK IS NOT NULL
GROUP BY l.MaMH, mh.TenMH
HAVING SUM(CASE WHEN dk.DiemTK < 4 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) > 0.10
ORDER BY TyLeTruot DESC;

-- Q8. Điểm trung bình, cao nhất, thấp nhất của từng giảng viên (theo các lớp đã chấm)
--     Kỹ thuật: hàm gộp AVG, MAX, MIN
SELECT gv.MaGV, gv.HoTen,
       COUNT(DISTINCT l.MaLHP) AS SoLop,
       CAST(AVG(dk.DiemTK) AS DECIMAL(4,2)) AS DiemTB,
       MAX(dk.DiemTK) AS CaoNhat,
       MIN(dk.DiemTK) AS ThapNhat
FROM dbo.GiangVien gv
JOIN dbo.LopHocPhan l ON l.MaGV = gv.MaGV
JOIN dbo.DangKy dk    ON dk.MaLHP = l.MaLHP
WHERE dk.DiemTK IS NOT NULL
GROUP BY gv.MaGV, gv.HoTen
ORDER BY DiemTB DESC;

/* ========================= MỨC 4: TRUY VẤN CON ======================= */

-- Q9. Sinh viên có điểm Cơ sở dữ liệu cao hơn điểm trung bình của môn đó
--     Kỹ thuật: truy vấn con vô hướng (scalar subquery)
SELECT dk.MaSV, sv.HoTen, dk.DiemTK
FROM dbo.DangKy dk
JOIN dbo.SinhVien sv  ON sv.MaSV = dk.MaSV
JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
WHERE l.MaMH = 'INT1313'
  AND dk.DiemTK > (SELECT AVG(d2.DiemTK)
                   FROM dbo.DangKy d2
                   JOIN dbo.LopHocPhan l2 ON l2.MaLHP = d2.MaLHP
                   WHERE l2.MaMH = 'INT1313')
ORDER BY dk.DiemTK DESC;

-- Q10. Sinh viên khóa B24 CHƯA đăng ký lớp nào trong kỳ 20262
--      Kỹ thuật: NOT EXISTS (truy vấn con tương quan)
SELECT sv.MaSV, sv.HoTen
FROM dbo.SinhVien sv
WHERE sv.NienKhoa = '2024-2029'
  AND NOT EXISTS (SELECT 1 FROM dbo.DangKy dk
                  JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
                  WHERE dk.MaSV = sv.MaSV AND l.MaHK = '20262');

-- Q11. Sinh viên đã đạt TẤT CẢ các môn của học kỳ 20241 mà mình học
--      Kỹ thuật: phép chia quan hệ bằng NOT EXISTS lồng nhau
SELECT sv.MaSV, sv.HoTen
FROM dbo.SinhVien sv
WHERE EXISTS (SELECT 1 FROM dbo.DangKy dk JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
              WHERE dk.MaSV = sv.MaSV AND l.MaHK = '20241')
  AND NOT EXISTS (SELECT 1 FROM dbo.DangKy dk JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
                  WHERE dk.MaSV = sv.MaSV AND l.MaHK = '20241'
                    AND (dk.DiemTK IS NULL OR dk.DiemTK < 4));

-- Q12. Môn học có mở lớp trong kỳ 20262 nhưng KHÔNG có trong kỳ 20252
--      Kỹ thuật: phép toán tập hợp EXCEPT
SELECT MaMH FROM dbo.LopHocPhan WHERE MaHK = '20262'
EXCEPT
SELECT MaMH FROM dbo.LopHocPhan WHERE MaHK = '20252';

/* =================== MỨC 5: CTE VÀ ĐỆ QUY ============================ */

-- Q13. Toàn bộ cây tiên quyết của môn Phát triển ứng dụng di động (INT1449)
--      Kỹ thuật: CTE đệ quy, hiển thị cấp độ và đường đi
WITH Cay AS (
    SELECT MaMH, MaMHTienQuyet, 1 AS CapDo,
           CAST(MaMH + ' <- ' + MaMHTienQuyet AS VARCHAR(500)) AS DuongDi
    FROM dbo.MonTienQuyet
    WHERE MaMH = 'INT1449'
    UNION ALL
    SELECT tq.MaMH, tq.MaMHTienQuyet, c.CapDo + 1,
           CAST(c.DuongDi + ' <- ' + tq.MaMHTienQuyet AS VARCHAR(500))
    FROM dbo.MonTienQuyet tq
    JOIN Cay c ON tq.MaMH = c.MaMHTienQuyet
)
SELECT c.CapDo, c.MaMHTienQuyet, mh.TenMH, c.DuongDi
FROM Cay c
JOIN dbo.MonHoc mh ON mh.MaMH = c.MaMHTienQuyet
ORDER BY c.CapDo, c.MaMHTienQuyet;

-- Q14. Các môn tiên quyết sinh viên B25DCCN003 còn thiếu để học CSDL (INT1313)
--      Kỹ thuật: gọi hàm bảng đệ quy fn_DSTienQuyetChuaDat
SELECT * FROM dbo.fn_DSTienQuyetChuaDat('B25DCCN003', 'INT1313');

/* =================== MỨC 6: HÀM CỬA SỔ (WINDOW) ===================== */

-- Q15. Top 3 sinh viên điểm cao nhất của mỗi lớp CSDL kỳ 20252
--      Kỹ thuật: DENSE_RANK() OVER (PARTITION BY ...)
WITH XepHang AS (
    SELECT dk.MaLHP, dk.MaSV, sv.HoTen, dk.DiemTK,
           DENSE_RANK() OVER (PARTITION BY dk.MaLHP ORDER BY dk.DiemTK DESC) AS Hang
    FROM dbo.DangKy dk
    JOIN dbo.SinhVien sv ON sv.MaSV = dk.MaSV
    WHERE dk.MaLHP LIKE 'INT1313-20252-%'
)
SELECT * FROM XepHang WHERE Hang <= 3 ORDER BY MaLHP, Hang;

-- Q16. GPA từng kỳ của sinh viên B24DCCN002 và mức tăng/giảm so với kỳ trước
--      Kỹ thuật: LAG() + hàm vô hướng tự định nghĩa
WITH GPAKy AS (
    SELECT hk.MaHK, dbo.fn_GPAHocKy('B24DCCN002', hk.MaHK) AS GPA
    FROM dbo.HocKy hk
)
SELECT MaHK, GPA,
       GPA - LAG(GPA) OVER (ORDER BY MaHK) AS ThayDoi
FROM GPAKy
WHERE GPA IS NOT NULL
ORDER BY MaHK;

-- Q17. Số tín chỉ tích lũy cộng dồn qua các kỳ của sinh viên B24DCCN001
--      Kỹ thuật: SUM() OVER (ORDER BY ... ROWS UNBOUNDED PRECEDING)
SELECT MaHK,
       SUM(CASE WHEN DiemTK >= 4 THEN SoTinChi ELSE 0 END) AS TCDatTrongKy,
       SUM(SUM(CASE WHEN DiemTK >= 4 THEN SoTinChi ELSE 0 END))
           OVER (ORDER BY MaHK ROWS UNBOUNDED PRECEDING) AS TCCongDon
FROM dbo.v_KetQuaHocTap
WHERE MaSV = 'B24DCCN001'
GROUP BY MaHK
ORDER BY MaHK;

-- Q18. Top 10 GPA tích lũy toàn trường kèm xếp loại
--      Kỹ thuật: truy vấn trên view
SELECT TOP (10) MaSV, HoTen, NienKhoa, SoTCTichLuy, GPATichLuy, XepLoai, HangTrongKhoaHoc
FROM dbo.v_XepHangGPA
ORDER BY GPATichLuy DESC;

/* =================== MỨC 7: PIVOT VÀ BÁO CÁO ======================= */

-- Q19. Phân bố điểm chữ của từng môn trong kỳ 20252 (dạng bảng ngang)
--      Kỹ thuật: PIVOT
SELECT MaMH, [A+], [A], [B+], [B], [C+], [C], [D+], [D], [F]
FROM (
    SELECT MaMH, DiemChu
    FROM dbo.v_KetQuaHocTap
    WHERE MaHK = '20252' AND DiemChu IS NOT NULL
) src
PIVOT (COUNT(DiemChu) FOR DiemChu IN ([A+], [A], [B+], [B], [C+], [C], [D+], [D], [F])) p
ORDER BY MaMH;

-- Q20. Danh sách sinh viên bị cảnh báo: GPA tích lũy dưới 2.0 hoặc đang nợ từ 2 môn
--      Kỹ thuật: kết hợp nhiều view, UNION
SELECT MaSV, HoTen, N'GPA tích lũy dưới 2.0' AS LyDo
FROM dbo.v_GPATichLuy
WHERE GPATichLuy < 2.0
UNION
SELECT MaSV, HoTen, N'Nợ từ 2 môn trở lên'
FROM dbo.v_SinhVienNoMon
GROUP BY MaSV, HoTen
HAVING COUNT(*) >= 2
ORDER BY MaSV;

/* =================== MỨC 8: CHỈ MỤC VÀ HIỆU NĂNG ===================== */

-- Q21. So sánh có / không có chỉ mục IX_DangKy_MaLHP
--      Cách làm: bấm Ctrl + M (Include Actual Execution Plan) rồi chạy cả khối.
--      Xem tab Messages: số "logical reads" khi có index sẽ ít hơn nhiều.
SET STATISTICS IO ON;

-- (a) Có chỉ mục: Index Seek
SELECT COUNT(*), AVG(DiemTK) FROM dbo.DangKy WHERE MaLHP = 'INT1313-20252-01';

-- (b) Ép không dùng chỉ mục: Clustered Index Scan (đọc toàn bảng)
SELECT COUNT(*), AVG(DiemTK) FROM dbo.DangKy WITH (INDEX(0)) WHERE MaLHP = 'INT1313-20252-01';

SET STATISTICS IO OFF;
GO
