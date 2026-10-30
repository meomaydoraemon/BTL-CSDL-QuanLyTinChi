/* =====================================================================
   File 02: Dữ liệu mẫu
   - 4 khoa, 10 giảng viên, 18 môn học (mã môn chỉ mang tính minh họa)
   - 6 học kỳ: 20241 -> 20262 (20262 đang mở đăng ký)
   - 300 sinh viên (2 khóa B24, B25), khoảng 3.600 lượt đăng ký có điểm
   - Tài khoản demo: mật khẩu đều là 123456

   LƯU Ý: chạy file này NGAY SAU 01_schema.sql, TRƯỚC 04_triggers.sql.
   Vì chưa có trigger nên cuối file sẽ tự tính DiemTK và SiSoHienTai.
   ===================================================================== */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE QuanLyTinChi;
GO

-- Chặn chạy nhầm khi trigger đã tồn tại (sẽ bị đếm sĩ số 2 lần)
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = N'trg_DangKy_Insert')
BEGIN
    RAISERROR(N'Trigger đã tồn tại. Hãy chạy lại từ file 01_schema.sql.', 16, 1);
    SET NOEXEC ON;
END
GO

SET NOCOUNT ON;

/* ---------------------------------------------------------------------
   1. KHOA, GIẢNG VIÊN
   --------------------------------------------------------------------- */
INSERT INTO dbo.Khoa (MaKhoa, TenKhoa) VALUES
('CNTT1', N'Công nghệ thông tin 1'),
('ATTT',  N'An toàn thông tin'),
('VT1',   N'Viễn thông 1'),
('CB',    N'Khoa học cơ bản');

INSERT INTO dbo.GiangVien (MaGV, HoTen, HocVi, Email, MaKhoa) VALUES
('GV001', N'Nguyễn Văn Hải',    N'TS',     'gv001@ptit.edu.vn', 'CNTT1'),
('GV002', N'Trần Thị Thu Hà',   N'ThS',    'gv002@ptit.edu.vn', 'CNTT1'),
('GV003', N'Lê Minh Tuấn',      N'TS',     'gv003@ptit.edu.vn', 'CNTT1'),
('GV004', N'Phạm Quang Huy',    N'ThS',    'gv004@ptit.edu.vn', 'CNTT1'),
('GV005', N'Hoàng Thị Lan',     N'PGS.TS', 'gv005@ptit.edu.vn', 'CNTT1'),
('GV006', N'Vũ Đức Thắng',      N'TS',     'gv006@ptit.edu.vn', 'CNTT1'),
('GV007', N'Đặng Ngọc Mai',     N'ThS',    'gv007@ptit.edu.vn', 'ATTT'),
('GV008', N'Bùi Văn Long',      N'TS',     'gv008@ptit.edu.vn', 'VT1'),
('GV009', N'Đỗ Thị Hương',      N'TS',     'gv009@ptit.edu.vn', 'CB'),
('GV010', N'Ngô Thanh Sơn',     N'ThS',    'gv010@ptit.edu.vn', 'CB');

/* ---------------------------------------------------------------------
   2. MÔN HỌC VÀ MÔN TIÊN QUYẾT
   --------------------------------------------------------------------- */
INSERT INTO dbo.MonHoc (MaMH, TenMH, SoTinChi, MaKhoa, TyLeCC, TyLeGK, TyLeCK) VALUES
('BAS1203', N'Giải tích 1',                               3, 'CB',    10, 20, 70),
('BAS1204', N'Giải tích 2',                               3, 'CB',    10, 20, 70),
('BAS1201', N'Đại số',                                    3, 'CB',    10, 20, 70),
('BAS1226', N'Xác suất thống kê',                         2, 'CB',    10, 20, 70),
('INT1154', N'Tin học cơ sở 1',                           2, 'CNTT1', 10, 30, 60),
('INT1155', N'Tin học cơ sở 2',                           2, 'CNTT1', 10, 30, 60),
('INT1358', N'Toán rời rạc 1',                            3, 'CNTT1', 10, 30, 60),
('INT1332', N'Lập trình hướng đối tượng',                 3, 'CNTT1', 10, 30, 60),
('INT1306', N'Cấu trúc dữ liệu và giải thuật',            3, 'CNTT1', 10, 20, 70),
('INT1313', N'Cơ sở dữ liệu',                             3, 'CNTT1', 10, 30, 60),
('INT1323', N'Kiến trúc máy tính',                        3, 'CNTT1', 10, 30, 60),
('INT1336', N'Mạng máy tính',                             3, 'VT1',   10, 30, 60),
('INT1434', N'Lập trình Web',                             3, 'CNTT1', 10, 40, 50),
('INT1319', N'Hệ điều hành',                              3, 'CNTT1', 10, 30, 60),
('INT1340', N'Nhập môn công nghệ phần mềm',               3, 'CNTT1', 10, 30, 60),
('INT1342', N'Phân tích và thiết kế hệ thống thông tin',  3, 'CNTT1', 10, 30, 60),
('INT1341', N'Nhập môn trí tuệ nhân tạo',                 3, 'CNTT1', 10, 30, 60),
('INT1449', N'Phát triển ứng dụng cho thiết bị di động',  3, 'ATTT',  10, 40, 50);

-- Chuỗi tiên quyết dài nhất: INT1449 <- INT1434 <- INT1313 <- INT1306 <- INT1155 <- INT1154
INSERT INTO dbo.MonTienQuyet (MaMH, MaMHTienQuyet) VALUES
('BAS1204', 'BAS1203'),
('BAS1226', 'BAS1203'),
('INT1155', 'INT1154'),
('INT1332', 'INT1155'),
('INT1306', 'INT1155'),
('INT1306', 'INT1358'),
('INT1313', 'INT1306'),
('INT1319', 'INT1323'),
('INT1434', 'INT1332'),
('INT1434', 'INT1313'),
('INT1340', 'INT1332'),
('INT1342', 'INT1313'),
('INT1341', 'INT1306'),
('INT1341', 'BAS1226'),
('INT1449', 'INT1434');

/* ---------------------------------------------------------------------
   3. THANG ĐIỂM (thang tín chỉ - nhóm cần đối chiếu lại quy chế PTIT)
   --------------------------------------------------------------------- */
INSERT INTO dbo.ThangDiem (DiemChu, DiemTu, DiemDen, DiemHe4) VALUES
('A+', 9.0, 10.0, 4.0),
('A',  8.5,  8.9, 3.7),
('B+', 8.0,  8.4, 3.5),
('B',  7.0,  7.9, 3.0),
('C+', 6.5,  6.9, 2.5),
('C',  5.5,  6.4, 2.0),
('D+', 5.0,  5.4, 1.5),
('D',  4.0,  4.9, 1.0),
('F',  0.0,  3.9, 0.0);

/* ---------------------------------------------------------------------
   4. HỌC KỲ
   20262 mở đăng ký từ 15/10/2026 đến 10/01/2027 để demo.
   Nếu demo ngoài khoảng này: EXEC sp_CapNhatThoiGianDangKy (file 05).
   --------------------------------------------------------------------- */
INSERT INTO dbo.HocKy (MaHK, TenHK, NgayBatDau, NgayKetThuc, NgayMoDK, NgayDongDK, SoTCToiDa) VALUES
('20241', N'Học kỳ 1 năm học 2024-2025', '2024-08-26', '2024-12-31', '2024-07-15 08:00', '2024-08-20 23:59', 25),
('20242', N'Học kỳ 2 năm học 2024-2025', '2025-01-13', '2025-05-31', '2024-12-15 08:00', '2025-01-08 23:59', 25),
('20251', N'Học kỳ 1 năm học 2025-2026', '2025-08-25', '2025-12-31', '2025-07-15 08:00', '2025-08-20 23:59', 25),
('20252', N'Học kỳ 2 năm học 2025-2026', '2026-01-12', '2026-05-31', '2025-12-15 08:00', '2026-01-07 23:59', 25),
('20261', N'Học kỳ 1 năm học 2026-2027', '2026-08-24', '2026-12-31', '2026-07-15 08:00', '2026-08-19 23:59', 25),
('20262', N'Học kỳ 2 năm học 2026-2027', '2027-01-18', '2027-05-31', '2026-10-15 08:00', '2027-01-10 23:59', 25);

/* ---------------------------------------------------------------------
   5. SINH VIÊN: sinh tự động 300 sinh viên
   B24DCCN001..100, B24DCAT001..050, B25DCCN001..100, B25DCAT001..050
   --------------------------------------------------------------------- */
DECLARE @Ho TABLE (i INT PRIMARY KEY, v NVARCHAR(20));
INSERT INTO @Ho VALUES (0,N'Nguyễn'),(1,N'Trần'),(2,N'Lê'),(3,N'Phạm'),(4,N'Hoàng'),
                       (5,N'Vũ'),(6,N'Đặng'),(7,N'Bùi'),(8,N'Đỗ'),(9,N'Ngô');

-- gt = 0: Nam, gt = 1: Nữ
DECLARE @Dem TABLE (gt INT, i INT, v NVARCHAR(20), PRIMARY KEY (gt, i));
INSERT INTO @Dem VALUES (0,0,N'Văn'),(0,1,N'Minh'),(0,2,N'Đức'),(0,3,N'Quang'),(0,4,N'Hoàng'),
                        (1,0,N'Thị'),(1,1,N'Thu'),(1,2,N'Ngọc'),(1,3,N'Thanh'),(1,4,N'Minh');

DECLARE @Ten TABLE (gt INT, i INT, v NVARCHAR(20), PRIMARY KEY (gt, i));
INSERT INTO @Ten VALUES (0,0,N'An'),(0,1,N'Bình'),(0,2,N'Dũng'),(0,3,N'Hùng'),(0,4,N'Long'),
                        (0,5,N'Nam'),(0,6,N'Phong'),(0,7,N'Quân'),(0,8,N'Tuấn'),(0,9,N'Sơn'),
                        (1,0,N'Anh'),(1,1,N'Hà'),(1,2,N'Lan'),(1,3,N'Linh'),(1,4,N'Mai'),
                        (1,5,N'Trang'),(1,6,N'Vy'),(1,7,N'Yến'),(1,8,N'Hương'),(1,9,N'Ngân');

;WITH So AS (
    SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
),
Lop AS (
    SELECT * FROM (VALUES
        ('B24', 'DCCN', 'CNTT1', '2024-2029', 100, 2006, 0),
        ('B24', 'DCAT', 'ATTT',  '2024-2029',  50, 2006, 3),
        ('B25', 'DCCN', 'CNTT1', '2025-2030', 100, 2007, 5),
        ('B25', 'DCAT', 'ATTT',  '2025-2030',  50, 2007, 8)
    ) AS t(KhoaHoc, Nganh, MaKhoa, NienKhoa, SoLuong, NamSinh, Lech)
),
Nguon AS (
    SELECT l.*, s.n, (s.n + l.Lech) % 2 AS gt
    FROM Lop l
    JOIN So s ON s.n <= l.SoLuong
)
INSERT INTO dbo.SinhVien (MaSV, HoTen, NgaySinh, GioiTinh, Email, MaKhoa, NienKhoa)
SELECT
    x.KhoaHoc + x.Nganh + RIGHT('000' + CAST(x.n AS VARCHAR(3)), 3),
    h.v + N' ' + d.v + N' ' + t.v,
    DATEADD(DAY, (x.n * 37 + x.Lech * 11) % 365, DATEFROMPARTS(x.NamSinh, 1, 1)),
    CASE x.gt WHEN 0 THEN N'Nam' ELSE N'Nữ' END,
    LOWER(x.KhoaHoc + x.Nganh + RIGHT('000' + CAST(x.n AS VARCHAR(3)), 3)) + '@stu.ptit.edu.vn',
    x.MaKhoa,
    x.NienKhoa
FROM Nguon x
JOIN @Ho  h ON h.i = (x.n * 3 + x.Lech) % 10
JOIN @Dem d ON d.gt = x.gt AND d.i = (x.n * 7 + x.Lech) % 5
JOIN @Ten t ON t.gt = x.gt AND t.i = (x.n * 13 + x.Lech) % 10;

/* ---------------------------------------------------------------------
   6. KẾ HOẠCH HỌC TẬP CÁC KỲ ĐÃ QUA (dùng để sinh lớp và điểm)
   --------------------------------------------------------------------- */
IF OBJECT_ID('tempdb..#KeHoach') IS NOT NULL DROP TABLE #KeHoach;
CREATE TABLE #KeHoach (KhoaHoc CHAR(3), MaHK VARCHAR(10), MaMH VARCHAR(10));
INSERT INTO #KeHoach VALUES
-- Khóa B24
('B24','20241','INT1154'),('B24','20241','BAS1203'),('B24','20241','BAS1201'),
('B24','20242','INT1155'),('B24','20242','INT1358'),('B24','20242','BAS1204'),
('B24','20251','INT1332'),('B24','20251','INT1306'),('B24','20251','BAS1226'),
('B24','20252','INT1313'),('B24','20252','INT1323'),('B24','20252','INT1336'),
('B24','20261','INT1434'),('B24','20261','INT1319'),('B24','20261','INT1340'),
-- Khóa B25
('B25','20251','INT1154'),('B25','20251','BAS1203'),('B25','20251','BAS1201'),
('B25','20252','INT1155'),('B25','20252','INT1358'),('B25','20252','BAS1204'),
('B25','20261','INT1332'),('B25','20261','INT1306'),('B25','20261','BAS1226');

-- Giảng viên phụ trách mặc định của từng môn
IF OBJECT_ID('tempdb..#GVMon') IS NOT NULL DROP TABLE #GVMon;
CREATE TABLE #GVMon (MaMH VARCHAR(10) PRIMARY KEY, MaGV VARCHAR(10));
INSERT INTO #GVMon VALUES
('BAS1203','GV009'),('BAS1204','GV009'),('BAS1201','GV010'),('BAS1226','GV010'),
('INT1154','GV002'),('INT1155','GV002'),('INT1358','GV003'),('INT1332','GV004'),
('INT1306','GV001'),('INT1313','GV001'),('INT1323','GV003'),('INT1336','GV008'),
('INT1434','GV004'),('INT1319','GV005'),('INT1340','GV006'),('INT1342','GV005'),
('INT1341','GV006'),('INT1449','GV007');

-- Lớp học phần các kỳ đã qua: mỗi môn 3 nhóm, mỗi nhóm tối đa 60 SV
INSERT INTO dbo.LopHocPhan (MaLHP, MaMH, MaHK, MaGV, Nhom, SiSoToiDa)
SELECT k.MaMH + '-' + k.MaHK + '-0' + CAST(g.Nhom AS VARCHAR(1)),
       k.MaMH, k.MaHK, gm.MaGV, g.Nhom, 60
FROM (SELECT DISTINCT MaHK, MaMH FROM #KeHoach) k
CROSS JOIN (VALUES (1), (2), (3)) g(Nhom)
JOIN #GVMon gm ON gm.MaMH = k.MaMH;

-- Lịch học các kỳ đã qua: mỗi lớp 1 buổi/tuần, mỗi lớp một ca riêng nên không trùng
;WITH L AS (
    SELECT MaLHP, ROW_NUMBER() OVER (PARTITION BY MaHK ORDER BY MaLHP) - 1 AS k
    FROM dbo.LopHocPhan
)
INSERT INTO dbo.LichHoc (MaLHP, Thu, TietBatDau, SoTiet, Phong)
SELECT MaLHP, 2 + k % 6, 1 + (k / 6) * 3, 3, 'A1-' + CAST(101 + k AS VARCHAR(3))
FROM L;

/* ---------------------------------------------------------------------
   7. ĐĂNG KÝ VÀ ĐIỂM CÁC KỲ ĐÃ QUA
   Mỗi SV có "năng lực" ngẫu nhiên, điểm dao động quanh năng lực đó.
   Số ngẫu nhiên được lưu trước vào bảng tạm để công thức tính ổn định.
   --------------------------------------------------------------------- */
IF OBJECT_ID('tempdb..#NangLuc') IS NOT NULL DROP TABLE #NangLuc;
SELECT MaSV, CAST(4.5 + (ABS(CHECKSUM(NEWID())) % 46) / 10.0 AS DECIMAL(4,2)) AS NL
INTO #NangLuc
FROM dbo.SinhVien;

IF OBJECT_ID('tempdb..#DK') IS NOT NULL DROP TABLE #DK;
SELECT sv.MaSV,
       k.MaHK,
       k.MaMH,
       k.MaMH + '-' + k.MaHK + '-0' + CAST((sv.rn - 1) % 3 + 1 AS VARCHAR(1)) AS MaLHP,
       nl.NL,
       ABS(CHECKSUM(NEWID())) % 1000 AS r1,
       ABS(CHECKSUM(NEWID())) % 1000 AS r2,
       ABS(CHECKSUM(NEWID())) % 1000 AS r3,
       ABS(CHECKSUM(NEWID())) % 28800 AS r4      -- số phút lệch so với giờ mở đăng ký
INTO #DK
FROM (
    SELECT MaSV, LEFT(MaSV, 3) AS KhoaHoc,
           ROW_NUMBER() OVER (PARTITION BY LEFT(MaSV, 3) ORDER BY MaSV) AS rn
    FROM dbo.SinhVien
) sv
JOIN #KeHoach k ON k.KhoaHoc = sv.KhoaHoc
JOIN #NangLuc nl ON nl.MaSV = sv.MaSV;

INSERT INTO dbo.DangKy (MaSV, MaLHP, NgayDangKy, DiemCC, DiemGK, DiemCK)
SELECT d.MaSV,
       d.MaLHP,
       DATEADD(MINUTE, d.r4, hk.NgayMoDK),
       CAST(ROUND(CASE WHEN x.cc > 10 THEN 10 WHEN x.cc < 0 THEN 0 ELSE x.cc END, 1) AS DECIMAL(4,2)),
       CAST(ROUND(CASE WHEN x.gk > 10 THEN 10 WHEN x.gk < 0 THEN 0 ELSE x.gk END, 1) AS DECIMAL(4,2)),
       -- Môn đang học dở ở kỳ 20261: chưa có điểm cuối kỳ (để demo giảng viên nhập điểm)
       CASE WHEN d.MaHK = '20261' AND d.MaMH IN ('INT1319', 'INT1340', 'BAS1226') THEN NULL
            ELSE CAST(ROUND(CASE WHEN x.ck > 10 THEN 10 WHEN x.ck < 0 THEN 0 ELSE x.ck END, 1) AS DECIMAL(4,2))
       END
FROM #DK d
JOIN dbo.HocKy hk ON hk.MaHK = d.MaHK
CROSS APPLY (
    SELECT d.NL + 1.0 + d.r1 / 500.0 - 0.5 AS cc,     -- chuyên cần thường cao
           d.NL + d.r2 / 333.0 - 1.5       AS gk,
           d.NL + d.r3 / 250.0 - 2.5       AS ck      -- cuối kỳ dao động mạnh nhất
) x;

/* ---------------------------------------------------------------------
   8. SINH VIÊN MẪU ĐỂ DEMO / TEST (điểm cố định, không ngẫu nhiên)
   B25DCCN001, B25DCCN004, B24DCCN001: học tốt, qua hết các môn
   B25DCCN002: trượt Cấu trúc dữ liệu (INT1306) -> bị chặn đăng ký CSDL (tiên quyết trực tiếp)
   B25DCCN003: trượt Tin học cơ sở 2 (INT1155) -> bị chặn đăng ký CSDL (tiên quyết gián tiếp, đệ quy)
   --------------------------------------------------------------------- */
UPDATE dbo.DangKy
SET DiemCC = 10, DiemGK = 9,
    DiemCK = CASE WHEN DiemCK IS NULL THEN NULL ELSE 9 END
WHERE MaSV IN ('B25DCCN001', 'B25DCCN002', 'B25DCCN003', 'B25DCCN004', 'B24DCCN001');

UPDATE dbo.DangKy SET DiemGK = 3, DiemCK = 2
WHERE MaSV = 'B25DCCN002' AND MaLHP LIKE 'INT1306-%';

UPDATE dbo.DangKy SET DiemGK = 2, DiemCK = 3
WHERE MaSV = 'B25DCCN003' AND MaLHP LIKE 'INT1155-%';

-- Tính điểm tổng kết (công thức giống hệt trigger trg_DangKy_TinhDiemTK)
UPDATE dk
SET DiemTK = CASE
                 WHEN dk.DiemCC IS NULL OR dk.DiemGK IS NULL OR dk.DiemCK IS NULL THEN NULL
                 ELSE ROUND((dk.DiemCC * mh.TyLeCC + dk.DiemGK * mh.TyLeGK + dk.DiemCK * mh.TyLeCK) / 100.0, 1)
             END
FROM dbo.DangKy dk
JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
JOIN dbo.MonHoc mh    ON mh.MaMH = l.MaMH;

/* ---------------------------------------------------------------------
   9. HỌC KỲ 20262 (ĐANG MỞ ĐĂNG KÝ) - lớp và lịch được thiết kế thủ công
   B25 học: INT1313 (CSDL), INT1323 (KTMT), INT1336 (Mạng)
   B24 học: INT1342 (PTTK), INT1341 (TTNT), INT1449 (Di động)
   Cố ý: INT1323-20262-03 học Thứ 2 tiết 1-3, TRÙNG với INT1313-20262-01 -> demo trùng lịch
   Cố ý: INT1323-20262-04 chỉ có 3 chỗ và đã đầy -> demo lớp đầy
   --------------------------------------------------------------------- */
INSERT INTO dbo.LopHocPhan (MaLHP, MaMH, MaHK, MaGV, Nhom, SiSoToiDa) VALUES
('INT1313-20262-01', 'INT1313', '20262', 'GV001', 1, 60),
('INT1313-20262-02', 'INT1313', '20262', 'GV001', 2, 60),
('INT1313-20262-03', 'INT1313', '20262', 'GV002', 3, 60),
('INT1323-20262-01', 'INT1323', '20262', 'GV003', 1, 60),
('INT1323-20262-02', 'INT1323', '20262', 'GV003', 2, 60),
('INT1323-20262-03', 'INT1323', '20262', 'GV003', 3, 60),
('INT1323-20262-04', 'INT1323', '20262', 'GV003', 4, 3),
('INT1336-20262-01', 'INT1336', '20262', 'GV008', 1, 60),
('INT1336-20262-02', 'INT1336', '20262', 'GV008', 2, 60),
('INT1336-20262-03', 'INT1336', '20262', 'GV008', 3, 60),
('INT1342-20262-01', 'INT1342', '20262', 'GV005', 1, 60),
('INT1342-20262-02', 'INT1342', '20262', 'GV005', 2, 60),
('INT1342-20262-03', 'INT1342', '20262', 'GV005', 3, 60),
('INT1341-20262-01', 'INT1341', '20262', 'GV006', 1, 60),
('INT1341-20262-02', 'INT1341', '20262', 'GV006', 2, 60),
('INT1341-20262-03', 'INT1341', '20262', 'GV006', 3, 60),
('INT1449-20262-01', 'INT1449', '20262', 'GV007', 1, 60),
('INT1449-20262-02', 'INT1449', '20262', 'GV007', 2, 60),
('INT1449-20262-03', 'INT1449', '20262', 'GV007', 3, 60);

INSERT INTO dbo.LichHoc (MaLHP, Thu, TietBatDau, SoTiet, Phong) VALUES
-- Cơ sở dữ liệu: 2 buổi/tuần
('INT1313-20262-01', 2, 1, 3, 'A2-301'), ('INT1313-20262-01', 6, 7, 3, 'A2-301'),
('INT1313-20262-02', 3, 1, 3, 'A2-301'), ('INT1313-20262-02', 7, 7, 3, 'A2-301'),
('INT1313-20262-03', 4, 1, 3, 'A2-301'), ('INT1313-20262-03', 5, 10, 3, 'A2-301'),
-- Kiến trúc máy tính
('INT1323-20262-01', 2, 4, 3, 'A2-302'),
('INT1323-20262-02', 3, 4, 3, 'A2-302'),
('INT1323-20262-03', 2, 1, 3, 'A2-303'),
('INT1323-20262-04', 5, 7, 3, 'A2-304'),
-- Mạng máy tính
('INT1336-20262-01', 5, 1, 3, 'A3-201'),
('INT1336-20262-02', 6, 1, 3, 'A3-201'),
('INT1336-20262-03', 7, 1, 3, 'A3-201'),
-- Phân tích thiết kế HTTT
('INT1342-20262-01', 2, 7, 3, 'A3-202'),
('INT1342-20262-02', 3, 7, 3, 'A3-202'),
('INT1342-20262-03', 4, 7, 3, 'A3-202'),
-- Trí tuệ nhân tạo
('INT1341-20262-01', 5, 4, 3, 'A3-203'),
('INT1341-20262-02', 6, 4, 3, 'A3-203'),
('INT1341-20262-03', 7, 4, 3, 'A3-203'),
-- Phát triển ứng dụng di động
('INT1449-20262-01', 2, 10, 3, 'A3-204'),
('INT1449-20262-02', 3, 10, 3, 'A3-204'),
('INT1449-20262-03', 4, 10, 3, 'A3-204');

-- 3 sinh viên (B25DCCN098..100) đã chiếm hết chỗ lớp INT1323-20262-04
INSERT INTO dbo.DangKy (MaSV, MaLHP, NgayDangKy) VALUES
('B25DCCN098', 'INT1323-20262-04', '2026-10-15 08:01'),
('B25DCCN099', 'INT1323-20262-04', '2026-10-15 08:02'),
('B25DCCN100', 'INT1323-20262-04', '2026-10-15 08:03');

/* ---------------------------------------------------------------------
   10. CẬP NHẬT SĨ SỐ HIỆN TẠI (vì chưa có trigger)
   --------------------------------------------------------------------- */
UPDATE l
SET SiSoHienTai = ISNULL(x.SoLuong, 0)
FROM dbo.LopHocPhan l
LEFT JOIN (SELECT MaLHP, COUNT(*) AS SoLuong FROM dbo.DangKy GROUP BY MaLHP) x
       ON x.MaLHP = l.MaLHP;

/* ---------------------------------------------------------------------
   11. TÀI KHOẢN (mật khẩu demo: 123456)
   Tiền tố {noop} nghĩa là chưa mã hóa. Ứng dụng web (Spring Security) tự
   nâng cấp sang {bcrypt} ngay lần đăng nhập đầu tiên của mỗi tài khoản.
   --------------------------------------------------------------------- */
INSERT INTO dbo.TaiKhoan (TenDangNhap, MatKhauHash, VaiTro, MaSV, MaGV)
SELECT LOWER(MaSV), '{noop}123456', 'SV', MaSV, NULL FROM dbo.SinhVien;

INSERT INTO dbo.TaiKhoan (TenDangNhap, MatKhauHash, VaiTro, MaSV, MaGV)
SELECT LOWER(MaGV), '{noop}123456', 'GV', NULL, MaGV FROM dbo.GiangVien;

INSERT INTO dbo.TaiKhoan (TenDangNhap, MatKhauHash, VaiTro, MaSV, MaGV)
VALUES ('admin', '{noop}123456', 'PDT', NULL, NULL);

DROP TABLE #KeHoach;
DROP TABLE #GVMon;
DROP TABLE #NangLuc;
DROP TABLE #DK;

-- Tóm tắt dữ liệu đã nạp
SELECT N'SinhVien' AS Bang, COUNT(*) AS SoDong FROM dbo.SinhVien
UNION ALL SELECT N'GiangVien',  COUNT(*) FROM dbo.GiangVien
UNION ALL SELECT N'MonHoc',     COUNT(*) FROM dbo.MonHoc
UNION ALL SELECT N'LopHocPhan', COUNT(*) FROM dbo.LopHocPhan
UNION ALL SELECT N'LichHoc',    COUNT(*) FROM dbo.LichHoc
UNION ALL SELECT N'DangKy',     COUNT(*) FROM dbo.DangKy
UNION ALL SELECT N'TaiKhoan',   COUNT(*) FROM dbo.TaiKhoan;
GO

SET NOEXEC OFF;
GO
