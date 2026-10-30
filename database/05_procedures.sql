/* =====================================================================
   File 05: Thủ tục lưu trữ (stored procedure)

   Nghiệp vụ sinh viên
     P1. sp_DangKyHocPhan        : đăng ký lớp học phần (7 bước kiểm tra)
     P2. sp_HuyDangKy            : hủy đăng ký
     P3. sp_DSLopCoTheDangKy     : danh sách lớp kèm lý do không đăng ký được
     P4. sp_ThoiKhoaBieu         : thời khóa biểu của sinh viên trong học kỳ
     P5. sp_BangDiemSinhVien     : bảng điểm + GPA từng kỳ
   Nghiệp vụ giảng viên
     P6. sp_NhapDiem             : nhập / sửa điểm thành phần
   Nghiệp vụ phòng đào tạo
     P7. sp_TaoLopHocPhan        : mở lớp học phần mới (tự sinh mã lớp)
     P8. sp_ThemLichHoc          : xếp lịch cho lớp (trigger kiểm tra trùng)
     P9. sp_CapNhatThoiGianDangKy: đổi thời gian mở / đóng đăng ký

   Quy ước mã lỗi: 500xx, thông báo tiếng Việt để ứng dụng hiển thị trực tiếp.
   ===================================================================== */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE QuanLyTinChi;
GO

/* ---------------------------------------------------------------------
   P1. ĐĂNG KÝ HỌC PHẦN
   Toàn bộ chạy trong 1 giao dịch (transaction). Thứ tự kiểm tra:
     Bước 0. Sinh viên và lớp học phần tồn tại (đồng thời KHÓA 2 dòng này)
     Bước 1. Đang trong thời gian đăng ký của học kỳ
     Bước 2. Chưa đăng ký môn này trong học kỳ (ở bất kỳ nhóm nào)
     Bước 3. Chưa đạt môn này ở các kỳ trước
     Bước 4. Đã đạt toàn bộ môn tiên quyết (đệ quy, cả gián tiếp)
     Bước 5. Không trùng lịch với các lớp đã đăng ký trong kỳ
     Bước 6. Không vượt số tín chỉ tối đa của học kỳ
     Bước 7. Lớp còn chỗ
   Xử lý tranh chấp: khóa UPDLOCK + HOLDLOCK trên dòng LopHocPhan làm các
   giao dịch cùng giành 1 lớp phải xếp hàng, nên không thể "lố" sĩ số.
   Khóa dòng SinhVien để 1 sinh viên mở 2 tab đăng ký cùng lúc cũng không
   vượt được giới hạn tín chỉ.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_DangKyHocPhan
    @MaSV  VARCHAR(12),
    @MaLHP VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;     -- có lỗi là hủy toàn bộ giao dịch

    DECLARE @MaMH VARCHAR(10), @MaHK VARCHAR(10), @SoTC INT,
            @SiSoHienTai SMALLINT, @SiSoToiDa SMALLINT,
            @NgayMoDK DATETIME, @NgayDongDK DATETIME, @SoTCToiDa INT,
            @TongTC INT, @LopDaDK VARCHAR(20), @DSThieu NVARCHAR(1000),
            @Msg NVARCHAR(2048);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Bước 0a: sinh viên tồn tại (khóa dòng sinh viên)
        IF NOT EXISTS (SELECT 1 FROM dbo.SinhVien WITH (UPDLOCK, HOLDLOCK) WHERE MaSV = @MaSV)
            THROW 50001, N'Sinh viên không tồn tại.', 1;

        -- Bước 0b: lớp học phần tồn tại (khóa dòng lớp học phần)
        SELECT @MaMH        = l.MaMH,
               @MaHK        = l.MaHK,
               @SiSoHienTai = l.SiSoHienTai,
               @SiSoToiDa   = l.SiSoToiDa,
               @SoTC        = mh.SoTinChi,
               @NgayMoDK    = hk.NgayMoDK,
               @NgayDongDK  = hk.NgayDongDK,
               @SoTCToiDa   = hk.SoTCToiDa
        FROM dbo.LopHocPhan l WITH (UPDLOCK, HOLDLOCK)
        JOIN dbo.MonHoc mh ON mh.MaMH = l.MaMH
        JOIN dbo.HocKy hk  ON hk.MaHK = l.MaHK
        WHERE l.MaLHP = @MaLHP;

        IF @MaMH IS NULL
            THROW 50002, N'Lớp học phần không tồn tại.', 1;

        -- Bước 1: thời gian đăng ký
        IF GETDATE() < @NgayMoDK OR GETDATE() > @NgayDongDK
        BEGIN
            SET @Msg = N'Ngoài thời gian đăng ký học kỳ ' + @MaHK + N' (từ '
                     + FORMAT(@NgayMoDK, 'dd/MM/yyyy HH:mm') + N' đến '
                     + FORMAT(@NgayDongDK, 'dd/MM/yyyy HH:mm') + N').';
            THROW 50003, @Msg, 1;
        END

        -- Bước 2: chưa đăng ký môn này trong kỳ
        SELECT TOP (1) @LopDaDK = dk.MaLHP
        FROM dbo.DangKy dk
        JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
        WHERE dk.MaSV = @MaSV AND l.MaHK = @MaHK AND l.MaMH = @MaMH;

        IF @LopDaDK IS NOT NULL
        BEGIN
            SET @Msg = N'Bạn đã đăng ký môn ' + @MaMH + N' ở lớp ' + @LopDaDK + N'.';
            THROW 50004, @Msg, 1;
        END

        -- Bước 3: chưa đạt môn này trước đó
        IF EXISTS (SELECT 1
                   FROM dbo.DangKy dk
                   JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
                   WHERE dk.MaSV = @MaSV AND l.MaMH = @MaMH AND dk.DiemTK >= 4.0)
        BEGIN
            SET @Msg = N'Bạn đã đạt môn ' + @MaMH + N', không cần đăng ký lại.';
            THROW 50005, @Msg, 1;
        END

        -- Bước 4: tiên quyết (dùng hàm đệ quy fn_DSTienQuyetChuaDat)
        SELECT @DSThieu = STRING_AGG(CAST(MaMH AS NVARCHAR(10)) + N' - ' + TenMH, N', ')
        FROM dbo.fn_DSTienQuyetChuaDat(@MaSV, @MaMH);

        IF @DSThieu IS NOT NULL
        BEGIN
            SET @Msg = N'Chưa đạt môn tiên quyết: ' + @DSThieu + N'.';
            THROW 50006, @Msg, 1;
        END

        -- Bước 5: trùng lịch với lớp đã đăng ký trong cùng học kỳ
        SET @Msg = NULL;
        SELECT TOP (1)
               @Msg = N'Trùng lịch với lớp ' + cu.MaLHP + N' ('
                    + CASE WHEN cu.Thu = 8 THEN N'Chủ nhật' ELSE N'Thứ ' + CAST(cu.Thu AS NVARCHAR(1)) END
                    + N', tiết ' + CAST(cu.TietBatDau AS NVARCHAR(2)) + N'-'
                    + CAST(cu.TietBatDau + cu.SoTiet - 1 AS NVARCHAR(2)) + N').'
        FROM dbo.LichHoc moi
        JOIN dbo.LichHoc cu      ON cu.Thu = moi.Thu
                                AND cu.TietBatDau <= moi.TietBatDau + moi.SoTiet - 1
                                AND moi.TietBatDau <= cu.TietBatDau + cu.SoTiet - 1
        JOIN dbo.DangKy dk       ON dk.MaLHP = cu.MaLHP AND dk.MaSV = @MaSV
        JOIN dbo.LopHocPhan lcu  ON lcu.MaLHP = cu.MaLHP AND lcu.MaHK = @MaHK
        WHERE moi.MaLHP = @MaLHP;

        IF @Msg IS NOT NULL
            THROW 50007, @Msg, 1;

        -- Bước 6: số tín chỉ tối đa
        SET @TongTC = dbo.fn_SoTinChiDaDangKy(@MaSV, @MaHK);

        IF @TongTC + @SoTC > @SoTCToiDa
        BEGIN
            SET @Msg = N'Vượt số tín chỉ tối đa: đã đăng ký ' + CAST(@TongTC AS NVARCHAR(3))
                     + N' TC, thêm ' + CAST(@SoTC AS NVARCHAR(3)) + N' TC sẽ vượt mức '
                     + CAST(@SoTCToiDa AS NVARCHAR(3)) + N' TC.';
            THROW 50008, @Msg, 1;
        END

        -- Bước 7: sĩ số
        IF @SiSoHienTai >= @SiSoToiDa
            THROW 50009, N'Lớp đã đủ sĩ số.', 1;

        -- Hợp lệ: thêm đăng ký (trigger trg_DangKy_Insert tăng sĩ số, ghi nhật ký)
        INSERT INTO dbo.DangKy (MaSV, MaLHP) VALUES (@MaSV, @MaLHP);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;      -- ném lại lỗi để ứng dụng nhận được thông báo
    END CATCH
END
GO

/* ---------------------------------------------------------------------
   P2. HỦY ĐĂNG KÝ
   Chỉ hủy được khi: đã đăng ký, còn trong thời gian đăng ký, chưa có điểm.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_HuyDangKy
    @MaSV  VARCHAR(12),
    @MaLHP VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NgayMoDK DATETIME, @NgayDongDK DATETIME, @CoDiem BIT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @NgayMoDK  = hk.NgayMoDK,
               @NgayDongDK = hk.NgayDongDK,
               @CoDiem    = CASE WHEN dk.DiemCC IS NULL AND dk.DiemGK IS NULL
                                  AND dk.DiemCK IS NULL THEN 0 ELSE 1 END
        FROM dbo.DangKy dk WITH (UPDLOCK, HOLDLOCK)
        JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
        JOIN dbo.HocKy hk     ON hk.MaHK = l.MaHK
        WHERE dk.MaSV = @MaSV AND dk.MaLHP = @MaLHP;

        IF @NgayMoDK IS NULL
            THROW 50011, N'Bạn chưa đăng ký lớp học phần này.', 1;

        IF GETDATE() < @NgayMoDK OR GETDATE() > @NgayDongDK
            THROW 50012, N'Đã hết thời gian đăng ký, không thể hủy.', 1;

        IF @CoDiem = 1
            THROW 50013, N'Lớp đã có điểm, không thể hủy.', 1;

        -- Trigger trg_DangKy_Delete giảm sĩ số, ghi nhật ký
        DELETE FROM dbo.DangKy WHERE MaSV = @MaSV AND MaLHP = @MaLHP;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* ---------------------------------------------------------------------
   P3. DANH SÁCH LỚP MỞ TRONG KỲ, KÈM TRẠNG THÁI ĐĂNG KÝ CỦA SINH VIÊN
   LyDoKhongTheDangKy = NULL nghĩa là đăng ký được.
   (Kiểm tra giống sp_DangKyHocPhan nhưng chỉ để HIỂN THỊ; khi bấm đăng ký,
    sp_DangKyHocPhan vẫn kiểm tra lại trong giao dịch.)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_DSLopCoTheDangKy
    @MaSV VARCHAR(12),
    @MaHK VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TongTC INT = dbo.fn_SoTinChiDaDangKy(@MaSV, @MaHK);
    DECLARE @SoTCToiDa INT = (SELECT SoTCToiDa FROM dbo.HocKy WHERE MaHK = @MaHK);

    SELECT v.MaLHP, v.MaMH, v.TenMH, v.SoTinChi, v.Nhom, v.TenGV,
           v.SiSoHienTai, v.SiSoToiDa, v.ChoTrong, v.LichHoc,
           CAST(CASE WHEN dk.MaLHP IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS DaDangKy,
           CASE
               WHEN dk.MaLHP IS NOT NULL THEN NULL
               WHEN EXISTS (SELECT 1 FROM dbo.DangKy d2
                            JOIN dbo.LopHocPhan l2 ON l2.MaLHP = d2.MaLHP
                            WHERE d2.MaSV = @MaSV AND l2.MaMH = v.MaMH AND d2.DiemTK >= 4.0)
                    THEN N'Đã đạt môn này'
               WHEN EXISTS (SELECT 1 FROM dbo.DangKy d2
                            JOIN dbo.LopHocPhan l2 ON l2.MaLHP = d2.MaLHP
                            WHERE d2.MaSV = @MaSV AND l2.MaMH = v.MaMH AND l2.MaHK = @MaHK)
                    THEN N'Đã đăng ký môn này ở nhóm khác'
               WHEN EXISTS (SELECT 1 FROM dbo.fn_DSTienQuyetChuaDat(@MaSV, v.MaMH))
                    THEN N'Chưa đạt môn tiên quyết'
               WHEN EXISTS (SELECT 1
                            FROM dbo.LichHoc moi
                            JOIN dbo.LichHoc cu     ON cu.Thu = moi.Thu
                                                   AND cu.TietBatDau <= moi.TietBatDau + moi.SoTiet - 1
                                                   AND moi.TietBatDau <= cu.TietBatDau + cu.SoTiet - 1
                            JOIN dbo.DangKy d2      ON d2.MaLHP = cu.MaLHP AND d2.MaSV = @MaSV
                            JOIN dbo.LopHocPhan l2  ON l2.MaLHP = cu.MaLHP AND l2.MaHK = @MaHK
                            WHERE moi.MaLHP = v.MaLHP)
                    THEN N'Trùng lịch'
               WHEN @TongTC + v.SoTinChi > @SoTCToiDa THEN N'Vượt số tín chỉ tối đa'
               WHEN v.ChoTrong <= 0 THEN N'Lớp đã đầy'
               ELSE NULL
           END AS LyDoKhongTheDangKy
    FROM dbo.v_LopHocPhanChiTiet v
    LEFT JOIN dbo.DangKy dk ON dk.MaLHP = v.MaLHP AND dk.MaSV = @MaSV
    WHERE v.MaHK = @MaHK
    ORDER BY v.MaMH, v.Nhom;
END
GO

/* ---------------------------------------------------------------------
   P4. THỜI KHÓA BIỂU CỦA SINH VIÊN TRONG HỌC KỲ
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_ThoiKhoaBieu
    @MaSV VARCHAR(12),
    @MaHK VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT lh.Thu, lh.TietBatDau, lh.TietBatDau + lh.SoTiet - 1 AS TietKetThuc,
           lh.Phong, l.MaLHP, l.MaMH, mh.TenMH, gv.HoTen AS TenGV
    FROM dbo.DangKy dk
    JOIN dbo.LopHocPhan l  ON l.MaLHP = dk.MaLHP
    JOIN dbo.MonHoc mh     ON mh.MaMH = l.MaMH
    JOIN dbo.GiangVien gv  ON gv.MaGV = l.MaGV
    JOIN dbo.LichHoc lh    ON lh.MaLHP = l.MaLHP
    WHERE dk.MaSV = @MaSV AND l.MaHK = @MaHK
    ORDER BY lh.Thu, lh.TietBatDau;
END
GO

/* ---------------------------------------------------------------------
   P5. BẢNG ĐIỂM SINH VIÊN
   Trả về 3 tập kết quả: (1) từng môn, (2) GPA từng học kỳ, (3) GPA tích lũy
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_BangDiemSinhVien
    @MaSV VARCHAR(12)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT MaHK, MaMH, TenMH, SoTinChi, DiemCC, DiemGK, DiemCK, DiemTK,
           DiemChu, DiemHe4, KetQua
    FROM dbo.v_KetQuaHocTap
    WHERE MaSV = @MaSV
    ORDER BY MaHK, MaMH;

    SELECT hk.MaHK, hk.TenHK,
           dbo.fn_SoTinChiDaDangKy(@MaSV, hk.MaHK) AS SoTCDangKy,
           dbo.fn_GPAHocKy(@MaSV, hk.MaHK)         AS GPAHocKy
    FROM dbo.HocKy hk
    WHERE EXISTS (SELECT 1 FROM dbo.DangKy dk
                  JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
                  WHERE dk.MaSV = @MaSV AND l.MaHK = hk.MaHK)
    ORDER BY hk.MaHK;

    SELECT MaSV, HoTen, SoTCTichLuy, GPATichLuy, XepLoai
    FROM dbo.v_GPATichLuy
    WHERE MaSV = @MaSV;
END
GO

/* ---------------------------------------------------------------------
   P6. NHẬP ĐIỂM (giảng viên)
   Chỉ giảng viên phụ trách lớp mới được nhập. Truyền NULL = chưa có điểm đó.
   Trigger trg_DangKy_TinhDiemTK tự tính DiemTK.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_NhapDiem
    @MaGV   VARCHAR(10),
    @MaSV   VARCHAR(12),
    @MaLHP  VARCHAR(20),
    @DiemCC DECIMAL(4,2),
    @DiemGK DECIMAL(4,2),
    @DiemCK DECIMAL(4,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.LopHocPhan WHERE MaLHP = @MaLHP AND MaGV = @MaGV)
            THROW 50021, N'Bạn không phụ trách lớp học phần này.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.DangKy WHERE MaLHP = @MaLHP AND MaSV = @MaSV)
            THROW 50022, N'Sinh viên không có trong lớp học phần này.', 1;

        IF @DiemCC NOT BETWEEN 0 AND 10 OR @DiemGK NOT BETWEEN 0 AND 10
           OR @DiemCK NOT BETWEEN 0 AND 10
            THROW 50023, N'Điểm phải nằm trong khoảng 0 đến 10.', 1;

        UPDATE dbo.DangKy
        SET DiemCC = @DiemCC, DiemGK = @DiemGK, DiemCK = @DiemCK
        WHERE MaLHP = @MaLHP AND MaSV = @MaSV;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* ---------------------------------------------------------------------
   P7. MỞ LỚP HỌC PHẦN MỚI (phòng đào tạo)
   Tự đánh số nhóm tiếp theo và sinh mã lớp dạng MaMH-MaHK-NN.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_TaoLopHocPhan
    @MaMH      VARCHAR(10),
    @MaHK      VARCHAR(10),
    @MaGV      VARCHAR(10),
    @SiSoToiDa SMALLINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Nhom TINYINT, @MaLHP VARCHAR(20);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Khóa phạm vi (môn, học kỳ) để 2 người tạo lớp cùng lúc không trùng số nhóm
        SELECT @Nhom = ISNULL(MAX(Nhom), 0) + 1
        FROM dbo.LopHocPhan WITH (UPDLOCK, HOLDLOCK)
        WHERE MaMH = @MaMH AND MaHK = @MaHK;

        SET @MaLHP = @MaMH + '-' + @MaHK + '-' + RIGHT('0' + CAST(@Nhom AS VARCHAR(2)), 2);

        INSERT INTO dbo.LopHocPhan (MaLHP, MaMH, MaHK, MaGV, Nhom, SiSoToiDa)
        VALUES (@MaLHP, @MaMH, @MaHK, @MaGV, @Nhom, @SiSoToiDa);

        COMMIT TRANSACTION;

        SELECT @MaLHP AS MaLHP;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* ---------------------------------------------------------------------
   P8. XẾP LỊCH HỌC CHO LỚP (trigger trg_LichHoc_KiemTraTrung chặn trùng)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_ThemLichHoc
    @MaLHP      VARCHAR(20),
    @Thu        TINYINT,
    @TietBatDau TINYINT,
    @SoTiet     TINYINT,
    @Phong      VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.LopHocPhan WHERE MaLHP = @MaLHP)
        THROW 50031, N'Lớp học phần không tồn tại.', 1;

    INSERT INTO dbo.LichHoc (MaLHP, Thu, TietBatDau, SoTiet, Phong)
    VALUES (@MaLHP, @Thu, @TietBatDau, @SoTiet, @Phong);
END
GO

/* ---------------------------------------------------------------------
   P9. CẬP NHẬT THỜI GIAN ĐĂNG KÝ (phòng đào tạo)
   VD mở đăng ký kỳ 20262 trong 30 ngày tới:
     DECLARE @Mo DATETIME = GETDATE(), @Dong DATETIME = DATEADD(DAY, 30, GETDATE());
     EXEC dbo.sp_CapNhatThoiGianDangKy '20262', @Mo, @Dong;
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_CapNhatThoiGianDangKy
    @MaHK       VARCHAR(10),
    @NgayMoDK   DATETIME,
    @NgayDongDK DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.HocKy WHERE MaHK = @MaHK)
        THROW 50032, N'Học kỳ không tồn tại.', 1;

    IF @NgayDongDK <= @NgayMoDK
        THROW 50033, N'Thời gian đóng phải sau thời gian mở đăng ký.', 1;

    UPDATE dbo.HocKy
    SET NgayMoDK = @NgayMoDK, NgayDongDK = @NgayDongDK
    WHERE MaHK = @MaHK;
END
GO

PRINT N'Đã tạo 9 thủ tục.';
GO
