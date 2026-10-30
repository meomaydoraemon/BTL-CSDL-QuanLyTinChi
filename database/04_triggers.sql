/* =====================================================================
   File 04: Trigger
   T1. trg_DangKy_Insert         : tăng sĩ số + ghi nhật ký khi đăng ký
   T2. trg_DangKy_Delete         : giảm sĩ số + ghi nhật ký khi hủy
   T3. trg_DangKy_TinhDiemTK     : tự tính điểm tổng kết khi nhập điểm
   T4. trg_LichHoc_KiemTraTrung  : chặn xếp lịch trùng phòng / trùng giảng viên
   T5. trg_MonTienQuyet_ChongVongLap : chặn tạo vòng lặp tiên quyết (A cần B, B cần A)

   Lưu ý: trigger trong SQL Server chạy MỘT LẦN cho cả câu lệnh, nên luôn
   xử lý trên toàn bộ bảng ảo inserted / deleted (có thể nhiều dòng).
   ===================================================================== */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE QuanLyTinChi;
GO

/* ---------------------------------------------------------------------
   T1. Sau khi đăng ký: tăng SiSoHienTai và ghi nhật ký
   Nếu sĩ số vượt tối đa, ràng buộc CK_LopHocPhan_SiSo sẽ báo lỗi
   và toàn bộ giao dịch bị hủy.
   --------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER dbo.trg_DangKy_Insert
ON dbo.DangKy
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE l
    SET SiSoHienTai = l.SiSoHienTai + i.SoLuong
    FROM dbo.LopHocPhan l
    JOIN (SELECT MaLHP, COUNT(*) AS SoLuong FROM inserted GROUP BY MaLHP) i
         ON i.MaLHP = l.MaLHP;

    INSERT INTO dbo.NhatKyDangKy (MaSV, MaLHP, HanhDong)
    SELECT MaSV, MaLHP, N'DANG_KY' FROM inserted;
END
GO

/* ---------------------------------------------------------------------
   T2. Sau khi hủy đăng ký: giảm SiSoHienTai và ghi nhật ký
   --------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER dbo.trg_DangKy_Delete
ON dbo.DangKy
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE l
    SET SiSoHienTai = l.SiSoHienTai - d.SoLuong
    FROM dbo.LopHocPhan l
    JOIN (SELECT MaLHP, COUNT(*) AS SoLuong FROM deleted GROUP BY MaLHP) d
         ON d.MaLHP = l.MaLHP;

    INSERT INTO dbo.NhatKyDangKy (MaSV, MaLHP, HanhDong)
    SELECT MaSV, MaLHP, N'HUY' FROM deleted;
END
GO

/* ---------------------------------------------------------------------
   T3. Tự tính điểm tổng kết theo tỷ lệ của môn học
   DiemTK = (CC * TyLeCC + GK * TyLeGK + CK * TyLeCK) / 100, làm tròn 1 chữ số
   Thiếu bất kỳ điểm thành phần nào thì DiemTK = NULL.
   (Lệnh UPDATE bên trong không kích hoạt lại chính trigger này vì
    tùy chọn RECURSIVE_TRIGGERS của CSDL mặc định là OFF.)
   --------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER dbo.trg_DangKy_TinhDiemTK
ON dbo.DangKy
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ chạy khi có thay đổi ở cột điểm thành phần
    IF NOT (UPDATE(DiemCC) OR UPDATE(DiemGK) OR UPDATE(DiemCK))
        RETURN;

    UPDATE dk
    SET DiemTK = CASE
                     WHEN dk.DiemCC IS NULL OR dk.DiemGK IS NULL OR dk.DiemCK IS NULL THEN NULL
                     ELSE ROUND((dk.DiemCC * mh.TyLeCC
                               + dk.DiemGK * mh.TyLeGK
                               + dk.DiemCK * mh.TyLeCK) / 100.0, 1)
                 END
    FROM dbo.DangKy dk
    JOIN inserted i       ON i.MaSV = dk.MaSV AND i.MaLHP = dk.MaLHP
    JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
    JOIN dbo.MonHoc mh    ON mh.MaMH = l.MaMH;
END
GO

/* ---------------------------------------------------------------------
   T4. Kiểm tra trùng lịch khi xếp lịch học (cùng học kỳ, cùng thứ, giao tiết)
   Hai ca [a1, a2] và [b1, b2] giao nhau khi: a1 <= b2 AND b1 <= a2
   - Trùng phòng: 2 lớp khác nhau dùng cùng 1 phòng
   - Trùng giảng viên: 1 giảng viên dạy 2 ca cùng lúc
   --------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER dbo.trg_LichHoc_KiemTraTrung
ON dbo.LichHoc
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Msg NVARCHAR(500);

    -- Trùng phòng
    SELECT TOP (1)
           @Msg = N'Trùng phòng ' + i.Phong + N': lớp ' + k.MaLHP
                + N' đã dùng phòng này vào thời gian đó.'
    FROM inserted i
    JOIN dbo.LopHocPhan li ON li.MaLHP = i.MaLHP
    JOIN dbo.LichHoc k     ON k.MaLich <> i.MaLich
                          AND k.Thu = i.Thu
                          AND k.Phong = i.Phong
                          AND k.TietBatDau <= i.TietBatDau + i.SoTiet - 1
                          AND i.TietBatDau <= k.TietBatDau + k.SoTiet - 1
    JOIN dbo.LopHocPhan lk ON lk.MaLHP = k.MaLHP AND lk.MaHK = li.MaHK;

    IF @Msg IS NOT NULL
        THROW 50040, @Msg, 1;

    -- Trùng giảng viên
    SELECT TOP (1)
           @Msg = N'Giảng viên ' + li.MaGV + N' đã có lịch dạy lớp ' + k.MaLHP
                + N' vào thời gian đó.'
    FROM inserted i
    JOIN dbo.LopHocPhan li ON li.MaLHP = i.MaLHP
    JOIN dbo.LichHoc k     ON k.MaLich <> i.MaLich
                          AND k.Thu = i.Thu
                          AND k.TietBatDau <= i.TietBatDau + i.SoTiet - 1
                          AND i.TietBatDau <= k.TietBatDau + k.SoTiet - 1
    JOIN dbo.LopHocPhan lk ON lk.MaLHP = k.MaLHP
                          AND lk.MaHK = li.MaHK
                          AND lk.MaGV = li.MaGV;

    IF @Msg IS NOT NULL
        THROW 50041, @Msg, 1;
END
GO

/* ---------------------------------------------------------------------
   T5. Chống vòng lặp tiên quyết
   Khi thêm "A cần B", đi ngược chuỗi tiên quyết của B; nếu gặp lại A thì
   có vòng lặp (VD: A cần B, B cần C, C cần A) -> không ai học được -> chặn.
   --------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER dbo.trg_MonTienQuyet_ChongVongLap
ON dbo.MonTienQuyet
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SoVong INT;

    WITH Chuoi AS (
        SELECT i.MaMH AS Goc, i.MaMHTienQuyet AS MonHienTai, 1 AS CapDo
        FROM inserted i

        UNION ALL

        SELECT c.Goc, tq.MaMHTienQuyet, c.CapDo + 1
        FROM Chuoi c
        JOIN dbo.MonTienQuyet tq ON tq.MaMH = c.MonHienTai
        WHERE c.CapDo < 50
    )
    SELECT @SoVong = COUNT(*) FROM Chuoi WHERE MonHienTai = Goc;

    IF @SoVong > 0
        THROW 50050, N'Không thể thêm: quan hệ tiên quyết này tạo thành vòng lặp.', 1;
END
GO

PRINT N'Đã tạo 5 trigger.';
GO
