/* =====================================================================
   File 03: Hàm (function) và khung nhìn (view)
   ===================================================================== */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE QuanLyTinChi;
GO

/* =====================================================================
   PHẦN A. HÀM
   ===================================================================== */

/* ---------------------------------------------------------------------
   A1. fn_DSTienQuyetChuaDat(@MaSV, @MaMH)
   Trả về các môn tiên quyết (cả trực tiếp và gián tiếp) mà sinh viên CHƯA ĐẠT.
   Dùng CTE đệ quy để đi hết "cây tiên quyết" của môn.

   Ví dụ cây của INT1313 (CSDL):
       INT1313 <- INT1306 (cấp 1) <- INT1155 (cấp 2) <- INT1154 (cấp 3)
                                  <- INT1358 (cấp 2)
   Kết quả rỗng = đủ điều kiện tiên quyết.
   --------------------------------------------------------------------- */
CREATE OR ALTER FUNCTION dbo.fn_DSTienQuyetChuaDat (@MaSV VARCHAR(12), @MaMH VARCHAR(10))
RETURNS TABLE
AS
RETURN
    WITH CayTienQuyet AS (
        -- Phần neo: các môn tiên quyết trực tiếp
        SELECT tq.MaMHTienQuyet, 1 AS CapDo
        FROM dbo.MonTienQuyet tq
        WHERE tq.MaMH = @MaMH

        UNION ALL

        -- Phần đệ quy: tiên quyết của tiên quyết
        SELECT tq.MaMHTienQuyet, c.CapDo + 1
        FROM dbo.MonTienQuyet tq
        JOIN CayTienQuyet c ON tq.MaMH = c.MaMHTienQuyet
        WHERE c.CapDo < 20          -- chốt an toàn, tránh lặp vô hạn
    )
    SELECT c.MaMHTienQuyet AS MaMH,
           mh.TenMH,
           MIN(c.CapDo) AS CapDo
    FROM CayTienQuyet c
    JOIN dbo.MonHoc mh ON mh.MaMH = c.MaMHTienQuyet
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.DangKy dk
        JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
        WHERE dk.MaSV = @MaSV
          AND l.MaMH = c.MaMHTienQuyet
          AND dk.DiemTK >= 4.0               -- đạt khi điểm tổng kết >= 4.0
    )
    GROUP BY c.MaMHTienQuyet, mh.TenMH;
GO

/* ---------------------------------------------------------------------
   A2. fn_SoTinChiDaDangKy(@MaSV, @MaHK): tổng tín chỉ SV đã đăng ký trong kỳ
   --------------------------------------------------------------------- */
CREATE OR ALTER FUNCTION dbo.fn_SoTinChiDaDangKy (@MaSV VARCHAR(12), @MaHK VARCHAR(10))
RETURNS INT
AS
BEGIN
    DECLARE @Tong INT;

    SELECT @Tong = ISNULL(SUM(mh.SoTinChi), 0)
    FROM dbo.DangKy dk
    JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
    JOIN dbo.MonHoc mh    ON mh.MaMH = l.MaMH
    WHERE dk.MaSV = @MaSV AND l.MaHK = @MaHK;

    RETURN @Tong;
END
GO

/* ---------------------------------------------------------------------
   A3. fn_GPAHocKy(@MaSV, @MaHK): điểm trung bình học kỳ (thang 4)
   Trung bình có trọng số theo số tín chỉ, tính trên các môn đã có điểm.
   --------------------------------------------------------------------- */
CREATE OR ALTER FUNCTION dbo.fn_GPAHocKy (@MaSV VARCHAR(12), @MaHK VARCHAR(10))
RETURNS DECIMAL(3,2)
AS
BEGIN
    DECLARE @GPA DECIMAL(3,2);

    SELECT @GPA = CAST(SUM(td.DiemHe4 * mh.SoTinChi) / SUM(mh.SoTinChi) AS DECIMAL(3,2))
    FROM dbo.DangKy dk
    JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
    JOIN dbo.MonHoc mh    ON mh.MaMH = l.MaMH
    JOIN dbo.ThangDiem td ON dk.DiemTK BETWEEN td.DiemTu AND td.DiemDen
    WHERE dk.MaSV = @MaSV AND l.MaHK = @MaHK;

    RETURN @GPA;
END
GO

/* ---------------------------------------------------------------------
   A4. fn_XepLoaiHocLuc(@GPA): xếp loại theo điểm trung bình tích lũy hệ 4
   --------------------------------------------------------------------- */
CREATE OR ALTER FUNCTION dbo.fn_XepLoaiHocLuc (@GPA DECIMAL(3,2))
RETURNS NVARCHAR(20)
AS
BEGIN
    RETURN CASE
        WHEN @GPA IS NULL THEN N'Chưa xếp loại'
        WHEN @GPA >= 3.6  THEN N'Xuất sắc'
        WHEN @GPA >= 3.2  THEN N'Giỏi'
        WHEN @GPA >= 2.5  THEN N'Khá'
        WHEN @GPA >= 2.0  THEN N'Trung bình'
        ELSE N'Yếu'
    END;
END
GO

/* =====================================================================
   PHẦN B. KHUNG NHÌN
   ===================================================================== */

/* ---------------------------------------------------------------------
   B1. v_KetQuaHocTap: mỗi lượt học của sinh viên kèm điểm chữ, điểm hệ 4
   Điểm chữ được TRA CỨU từ bảng ThangDiem, không lưu trực tiếp (đảm bảo 3NF)
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.v_KetQuaHocTap
AS
SELECT dk.MaSV,
       l.MaHK,
       l.MaLHP,
       l.MaMH,
       mh.TenMH,
       mh.SoTinChi,
       dk.DiemCC,
       dk.DiemGK,
       dk.DiemCK,
       dk.DiemTK,
       td.DiemChu,
       td.DiemHe4,
       CASE
           WHEN dk.DiemTK IS NULL THEN N'Chưa có điểm'
           WHEN dk.DiemTK >= 4.0  THEN N'Đạt'
           ELSE N'Không đạt'
       END AS KetQua
FROM dbo.DangKy dk
JOIN dbo.LopHocPhan l     ON l.MaLHP = dk.MaLHP
JOIN dbo.MonHoc mh        ON mh.MaMH = l.MaMH
LEFT JOIN dbo.ThangDiem td ON dk.DiemTK BETWEEN td.DiemTu AND td.DiemDen;
GO

/* ---------------------------------------------------------------------
   B2. v_GPATichLuy: điểm trung bình tích lũy hệ 4 của từng sinh viên
   - Môn học nhiều lần: lấy lần có điểm cao nhất (ROW_NUMBER)
   - Chỉ tính các môn đã đạt (tín chỉ tích lũy)
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.v_GPATichLuy
AS
WITH LanTotNhat AS (
    SELECT MaSV, MaMH, SoTinChi, DiemTK, DiemHe4,
           ROW_NUMBER() OVER (PARTITION BY MaSV, MaMH ORDER BY DiemTK DESC) AS rn
    FROM dbo.v_KetQuaHocTap
    WHERE DiemTK IS NOT NULL
),
TongHop AS (
    SELECT MaSV,
           SUM(CASE WHEN DiemTK >= 4.0 THEN SoTinChi ELSE 0 END)           AS SoTCTichLuy,
           SUM(CASE WHEN DiemTK >= 4.0 THEN DiemHe4 * SoTinChi ELSE 0 END) AS TongDiemHe4
    FROM LanTotNhat
    WHERE rn = 1
    GROUP BY MaSV
)
SELECT sv.MaSV,
       sv.HoTen,
       sv.MaKhoa,
       sv.NienKhoa,
       ISNULL(th.SoTCTichLuy, 0) AS SoTCTichLuy,
       CAST(th.TongDiemHe4 / NULLIF(th.SoTCTichLuy, 0) AS DECIMAL(3,2)) AS GPATichLuy,
       dbo.fn_XepLoaiHocLuc(CAST(th.TongDiemHe4 / NULLIF(th.SoTCTichLuy, 0) AS DECIMAL(3,2))) AS XepLoai
FROM dbo.SinhVien sv
LEFT JOIN TongHop th ON th.MaSV = sv.MaSV;
GO

/* ---------------------------------------------------------------------
   B3. v_XepHangGPA: xếp hạng GPA trong từng khóa (hàm cửa sổ RANK)
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.v_XepHangGPA
AS
SELECT MaSV, HoTen, MaKhoa, NienKhoa, SoTCTichLuy, GPATichLuy, XepLoai,
       RANK() OVER (PARTITION BY NienKhoa ORDER BY GPATichLuy DESC)         AS HangTrongKhoaHoc,
       RANK() OVER (PARTITION BY NienKhoa, MaKhoa ORDER BY GPATichLuy DESC) AS HangTrongKhoa
FROM dbo.v_GPATichLuy
WHERE GPATichLuy IS NOT NULL;
GO

/* ---------------------------------------------------------------------
   B4. v_LopHocPhanChiTiet: thông tin đầy đủ của lớp học phần, lịch học dạng chữ
   VD lịch: "Thứ 2, tiết 1-3, phòng A2-301; Thứ 6, tiết 7-9, phòng A2-301"
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.v_LopHocPhanChiTiet
AS
SELECT l.MaLHP,
       l.MaMH,
       mh.TenMH,
       mh.SoTinChi,
       l.MaHK,
       l.Nhom,
       l.MaGV,
       gv.HoTen AS TenGV,
       l.SiSoToiDa,
       l.SiSoHienTai,
       l.SiSoToiDa - l.SiSoHienTai AS ChoTrong,
       lich.LichHoc
FROM dbo.LopHocPhan l
JOIN dbo.MonHoc mh    ON mh.MaMH = l.MaMH
JOIN dbo.GiangVien gv ON gv.MaGV = l.MaGV
OUTER APPLY (
    SELECT STRING_AGG(
               CAST(CASE WHEN lh.Thu = 8 THEN N'Chủ nhật'
                         ELSE N'Thứ ' + CAST(lh.Thu AS NVARCHAR(1)) END
                    + N', tiết ' + CAST(lh.TietBatDau AS NVARCHAR(2))
                    + N'-' + CAST(lh.TietBatDau + lh.SoTiet - 1 AS NVARCHAR(2))
                    + N', phòng ' + CAST(lh.Phong AS NVARCHAR(20)) AS NVARCHAR(200)),
               N'; ') WITHIN GROUP (ORDER BY lh.Thu, lh.TietBatDau) AS LichHoc
    FROM dbo.LichHoc lh
    WHERE lh.MaLHP = l.MaLHP
) lich;
GO

/* ---------------------------------------------------------------------
   B5. v_ThongKeLopHocPhan: số SV, tỷ lệ đạt, điểm trung bình của từng lớp
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.v_ThongKeLopHocPhan
AS
SELECT l.MaLHP,
       l.MaHK,
       l.MaMH,
       mh.TenMH,
       l.MaGV,
       l.SiSoToiDa,
       COUNT(dk.MaSV)                                     AS SoSinhVien,
       COUNT(dk.DiemTK)                                   AS SoCoDiem,
       SUM(CASE WHEN dk.DiemTK >= 4.0 THEN 1 ELSE 0 END)  AS SoDat,
       CAST(100.0 * SUM(CASE WHEN dk.DiemTK >= 4.0 THEN 1 ELSE 0 END)
            / NULLIF(COUNT(dk.DiemTK), 0) AS DECIMAL(5,2)) AS TyLeDat,
       CAST(AVG(dk.DiemTK) AS DECIMAL(4,2))               AS DiemTrungBinh
FROM dbo.LopHocPhan l
JOIN dbo.MonHoc mh     ON mh.MaMH = l.MaMH
LEFT JOIN dbo.DangKy dk ON dk.MaLHP = l.MaLHP
GROUP BY l.MaLHP, l.MaHK, l.MaMH, mh.TenMH, l.MaGV, l.SiSoToiDa;
GO

/* ---------------------------------------------------------------------
   B6. v_PhanBoDiemChu: số lượng từng loại điểm chữ theo môn và học kỳ
   (dạng bảng ngang - dùng để vẽ biểu đồ)
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.v_PhanBoDiemChu
AS
SELECT MaHK, MaMH, TenMH,
       SUM(CASE WHEN DiemChu = 'A+' THEN 1 ELSE 0 END) AS [A+],
       SUM(CASE WHEN DiemChu = 'A'  THEN 1 ELSE 0 END) AS [A],
       SUM(CASE WHEN DiemChu = 'B+' THEN 1 ELSE 0 END) AS [B+],
       SUM(CASE WHEN DiemChu = 'B'  THEN 1 ELSE 0 END) AS [B],
       SUM(CASE WHEN DiemChu = 'C+' THEN 1 ELSE 0 END) AS [C+],
       SUM(CASE WHEN DiemChu = 'C'  THEN 1 ELSE 0 END) AS [C],
       SUM(CASE WHEN DiemChu = 'D+' THEN 1 ELSE 0 END) AS [D+],
       SUM(CASE WHEN DiemChu = 'D'  THEN 1 ELSE 0 END) AS [D],
       SUM(CASE WHEN DiemChu = 'F'  THEN 1 ELSE 0 END) AS [F],
       COUNT(*) AS TongSo
FROM dbo.v_KetQuaHocTap
WHERE DiemChu IS NOT NULL
GROUP BY MaHK, MaMH, TenMH;
GO

/* ---------------------------------------------------------------------
   B7. v_SinhVienNoMon: sinh viên có môn chưa đạt (kể cả sau khi học lại)
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.v_SinhVienNoMon
AS
WITH LanTotNhat AS (
    SELECT MaSV, MaMH, TenMH, SoTinChi, DiemTK, MaHK,
           ROW_NUMBER() OVER (PARTITION BY MaSV, MaMH ORDER BY DiemTK DESC) AS rn
    FROM dbo.v_KetQuaHocTap
    WHERE DiemTK IS NOT NULL
)
SELECT sv.MaSV, sv.HoTen, sv.NienKhoa, t.MaMH, t.TenMH, t.SoTinChi,
       t.DiemTK AS DiemCaoNhat, t.MaHK AS HocKyGanNhat
FROM LanTotNhat t
JOIN dbo.SinhVien sv ON sv.MaSV = t.MaSV
WHERE t.rn = 1 AND t.DiemTK < 4.0;
GO

PRINT N'Đã tạo 4 hàm và 7 view.';
GO
