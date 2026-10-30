/* =====================================================================
   File 07: Kịch bản kiểm thử (test case) cho thủ tục và trigger
   Chạy cả file (F5), xem kết quả ở tab Messages: mỗi dòng [ĐẠT] / [SAI].
   Script tự mở thời gian đăng ký kỳ 20262 trong lúc test rồi trả lại như cũ,
   và tự xóa các đăng ký tạo ra trong lúc test -> chạy lại bao nhiêu lần cũng được.
   ===================================================================== */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE QuanLyTinChi;
GO

SET NOCOUNT ON;

DECLARE @Dat INT = 0, @Tong INT = 0;
DECLARE @BatDau DATETIME = GETDATE();
DECLARE @MoCu DATETIME, @DongCu DATETIME, @TCCu TINYINT;
DECLARE @SiSoTruoc SMALLINT, @SiSoSau SMALLINT;
DECLARE @SV VARCHAR(12), @CCCu DECIMAL(4,2), @GKCu DECIMAL(4,2), @CKCu DECIMAL(4,2);
DECLARE @DiemTK DECIMAL(4,2), @DiemChu VARCHAR(2);

/* ------------------------------- CHUẨN BỊ ------------------------------ */
SELECT @MoCu = NgayMoDK, @DongCu = NgayDongDK, @TCCu = SoTCToiDa
FROM dbo.HocKy WHERE MaHK = '20262';

UPDATE dbo.HocKy
SET NgayMoDK = DATEADD(DAY, -1, GETDATE()), NgayDongDK = DATEADD(DAY, 30, GETDATE())
WHERE MaHK = '20262';

-- Dọn dữ liệu còn sót nếu lần chạy trước bị dừng giữa chừng
DELETE dk
FROM dbo.DangKy dk
JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
WHERE l.MaHK = '20262'
  AND dk.MaSV IN ('B25DCCN001', 'B25DCCN002', 'B25DCCN003', 'B25DCCN004', 'B24DCCN001');

PRINT N'================ KIỂM THỬ ĐĂNG KÝ HỌC PHẦN ================';

/* T01: đăng ký hợp lệ -> thành công, sĩ số tăng 1 */
SET @Tong += 1;
SELECT @SiSoTruoc = SiSoHienTai FROM dbo.LopHocPhan WHERE MaLHP = 'INT1313-20262-01';
BEGIN TRY
    EXEC dbo.sp_DangKyHocPhan 'B25DCCN001', 'INT1313-20262-01';
    SELECT @SiSoSau = SiSoHienTai FROM dbo.LopHocPhan WHERE MaLHP = 'INT1313-20262-01';
    IF @SiSoSau = @SiSoTruoc + 1
       AND EXISTS (SELECT 1 FROM dbo.NhatKyDangKy WHERE MaSV = 'B25DCCN001'
                   AND MaLHP = 'INT1313-20262-01' AND HanhDong = N'DANG_KY' AND ThoiGian >= @BatDau)
    BEGIN
        SET @Dat += 1;
        PRINT N' [ĐẠT] T01 Đăng ký hợp lệ: thành công, sĩ số ' + CAST(@SiSoTruoc AS NVARCHAR(5))
            + N' -> ' + CAST(@SiSoSau AS NVARCHAR(5)) + N', có ghi nhật ký';
    END
    ELSE PRINT N' [SAI] T01 Đăng ký được nhưng sĩ số / nhật ký không đúng';
END TRY
BEGIN CATCH
    PRINT N' [SAI] T01 Lẽ ra thành công nhưng lỗi: ' + ERROR_MESSAGE();
END CATCH

/* T02: đăng ký cùng môn ở nhóm khác -> bị chặn (bước 2) */
SET @Tong += 1;
BEGIN TRY
    EXEC dbo.sp_DangKyHocPhan 'B25DCCN001', 'INT1313-20262-02';
    PRINT N' [SAI] T02 Lẽ ra phải bị chặn (trùng môn)';
END TRY
BEGIN CATCH
    SET @Dat += 1;
    PRINT N' [ĐẠT] T02 Trùng môn bị chặn: ' + ERROR_MESSAGE();
END CATCH

/* T03: lớp trùng lịch (Thứ 2 tiết 1-3) -> bị chặn (bước 5) */
SET @Tong += 1;
BEGIN TRY
    EXEC dbo.sp_DangKyHocPhan 'B25DCCN001', 'INT1323-20262-03';
    PRINT N' [SAI] T03 Lẽ ra phải bị chặn (trùng lịch)';
END TRY
BEGIN CATCH
    SET @Dat += 1;
    PRINT N' [ĐẠT] T03 Trùng lịch bị chặn: ' + ERROR_MESSAGE();
END CATCH

/* T04: lớp khác của cùng môn KTMT, không trùng lịch -> thành công */
SET @Tong += 1;
BEGIN TRY
    EXEC dbo.sp_DangKyHocPhan 'B25DCCN001', 'INT1323-20262-01';
    SET @Dat += 1;
    PRINT N' [ĐẠT] T04 Đăng ký lớp không trùng lịch: thành công';
END TRY
BEGIN CATCH
    PRINT N' [SAI] T04 Lẽ ra thành công nhưng lỗi: ' + ERROR_MESSAGE();
END CATCH

/* T05: lớp đã đầy (3/3) -> bị chặn (bước 7) */
SET @Tong += 1;
BEGIN TRY
    EXEC dbo.sp_DangKyHocPhan 'B25DCCN004', 'INT1323-20262-04';
    PRINT N' [SAI] T05 Lẽ ra phải bị chặn (lớp đầy)';
END TRY
BEGIN CATCH
    SET @Dat += 1;
    PRINT N' [ĐẠT] T05 Lớp đầy bị chặn: ' + ERROR_MESSAGE();
END CATCH

/* T06: chưa đạt tiên quyết TRỰC TIẾP (trượt INT1306) -> bị chặn (bước 4) */
SET @Tong += 1;
BEGIN TRY
    EXEC dbo.sp_DangKyHocPhan 'B25DCCN002', 'INT1313-20262-01';
    PRINT N' [SAI] T06 Lẽ ra phải bị chặn (tiên quyết trực tiếp)';
END TRY
BEGIN CATCH
    SET @Dat += 1;
    PRINT N' [ĐẠT] T06 Thiếu tiên quyết trực tiếp: ' + ERROR_MESSAGE();
END CATCH

/* T07: chưa đạt tiên quyết GIÁN TIẾP (trượt INT1155, cấp 2) -> bị chặn nhờ đệ quy */
SET @Tong += 1;
BEGIN TRY
    EXEC dbo.sp_DangKyHocPhan 'B25DCCN003', 'INT1313-20262-02';
    PRINT N' [SAI] T07 Lẽ ra phải bị chặn (tiên quyết gián tiếp)';
END TRY
BEGIN CATCH
    SET @Dat += 1;
    PRINT N' [ĐẠT] T07 Thiếu tiên quyết gián tiếp: ' + ERROR_MESSAGE();
END CATCH

/* T08: môn đã đạt -> bị chặn (bước 3) */
SET @Tong += 1;
BEGIN TRY
    EXEC dbo.sp_DangKyHocPhan 'B24DCCN001', 'INT1313-20262-03';
    PRINT N' [SAI] T08 Lẽ ra phải bị chặn (đã đạt môn)';
END TRY
BEGIN CATCH
    SET @Dat += 1;
    PRINT N' [ĐẠT] T08 Môn đã đạt bị chặn: ' + ERROR_MESSAGE();
END CATCH

/* T09: lớp của học kỳ đã hết hạn đăng ký -> bị chặn (bước 1) */
SET @Tong += 1;
BEGIN TRY
    EXEC dbo.sp_DangKyHocPhan 'B25DCCN001', 'INT1319-20261-01';
    PRINT N' [SAI] T09 Lẽ ra phải bị chặn (ngoài thời gian)';
END TRY
BEGIN CATCH
    SET @Dat += 1;
    PRINT N' [ĐẠT] T09 Ngoài thời gian bị chặn: ' + ERROR_MESSAGE();
END CATCH

/* T10: vượt số tín chỉ tối đa (tạm hạ mức tối đa xuống 6 TC) -> bị chặn (bước 6) */
SET @Tong += 1;
UPDATE dbo.HocKy SET SoTCToiDa = 6 WHERE MaHK = '20262';
BEGIN TRY
    EXEC dbo.sp_DangKyHocPhan 'B25DCCN001', 'INT1336-20262-01';
    PRINT N' [SAI] T10 Lẽ ra phải bị chặn (vượt tín chỉ)';
END TRY
BEGIN CATCH
    SET @Dat += 1;
    PRINT N' [ĐẠT] T10 Vượt tín chỉ bị chặn: ' + ERROR_MESSAGE();
END CATCH
UPDATE dbo.HocKy SET SoTCToiDa = @TCCu WHERE MaHK = '20262';

PRINT N'================ KIỂM THỬ HỦY ĐĂNG KÝ ================';

/* T11: hủy lớp đã đăng ký -> thành công, sĩ số giảm 1, có nhật ký HUY */
SET @Tong += 1;
SELECT @SiSoTruoc = SiSoHienTai FROM dbo.LopHocPhan WHERE MaLHP = 'INT1323-20262-01';
BEGIN TRY
    EXEC dbo.sp_HuyDangKy 'B25DCCN001', 'INT1323-20262-01';
    SELECT @SiSoSau = SiSoHienTai FROM dbo.LopHocPhan WHERE MaLHP = 'INT1323-20262-01';
    IF @SiSoSau = @SiSoTruoc - 1
       AND EXISTS (SELECT 1 FROM dbo.NhatKyDangKy WHERE MaSV = 'B25DCCN001'
                   AND MaLHP = 'INT1323-20262-01' AND HanhDong = N'HUY' AND ThoiGian >= @BatDau)
    BEGIN
        SET @Dat += 1;
        PRINT N' [ĐẠT] T11 Hủy đăng ký: sĩ số ' + CAST(@SiSoTruoc AS NVARCHAR(5))
            + N' -> ' + CAST(@SiSoSau AS NVARCHAR(5)) + N', có ghi nhật ký';
    END
    ELSE PRINT N' [SAI] T11 Hủy được nhưng sĩ số / nhật ký không đúng';
END TRY
BEGIN CATCH
    PRINT N' [SAI] T11 Lẽ ra thành công nhưng lỗi: ' + ERROR_MESSAGE();
END CATCH

/* T12: hủy lớp chưa đăng ký -> báo lỗi */
SET @Tong += 1;
BEGIN TRY
    EXEC dbo.sp_HuyDangKy 'B25DCCN001', 'INT1323-20262-01';
    PRINT N' [SAI] T12 Lẽ ra phải báo lỗi';
END TRY
BEGIN CATCH
    SET @Dat += 1;
    PRINT N' [ĐẠT] T12 Hủy lớp chưa đăng ký bị chặn: ' + ERROR_MESSAGE();
END CATCH

PRINT N'================ KIỂM THỬ NHẬP ĐIỂM ================';

-- Chọn 1 sinh viên đang học INT1340-20261-01 (chưa có điểm cuối kỳ), lưu điểm cũ
SELECT TOP (1) @SV = MaSV, @CCCu = DiemCC, @GKCu = DiemGK, @CKCu = DiemCK
FROM dbo.DangKy WHERE MaLHP = 'INT1340-20261-01' ORDER BY MaSV;

/* T13: giảng viên phụ trách nhập điểm -> trigger tự tính DiemTK
        Tỷ lệ 10/30/60: 9*0.1 + 8*0.3 + 7*0.6 = 7.5 -> điểm chữ B */
SET @Tong += 1;
BEGIN TRY
    EXEC dbo.sp_NhapDiem 'GV006', @SV, 'INT1340-20261-01', 9, 8, 7;
    SELECT @DiemTK = DiemTK, @DiemChu = DiemChu
    FROM dbo.v_KetQuaHocTap WHERE MaSV = @SV AND MaLHP = 'INT1340-20261-01';
    IF @DiemTK = 7.5 AND @DiemChu = 'B'
    BEGIN
        SET @Dat += 1;
        PRINT N' [ĐẠT] T13 Nhập điểm: DiemTK tự tính = ' + CAST(@DiemTK AS NVARCHAR(10))
            + N', điểm chữ ' + @DiemChu;
    END
    ELSE PRINT N' [SAI] T13 DiemTK = ' + ISNULL(CAST(@DiemTK AS NVARCHAR(10)), N'NULL') + N' (kỳ vọng 7.5)';
END TRY
BEGIN CATCH
    PRINT N' [SAI] T13 Lẽ ra thành công nhưng lỗi: ' + ERROR_MESSAGE();
END CATCH
-- Trả lại điểm cũ (trigger tự tính lại DiemTK = NULL)
UPDATE dbo.DangKy SET DiemCC = @CCCu, DiemGK = @GKCu, DiemCK = @CKCu
WHERE MaSV = @SV AND MaLHP = 'INT1340-20261-01';

/* T14: giảng viên KHÔNG phụ trách lớp -> bị chặn */
SET @Tong += 1;
BEGIN TRY
    EXEC dbo.sp_NhapDiem 'GV001', @SV, 'INT1340-20261-01', 9, 8, 7;
    PRINT N' [SAI] T14 Lẽ ra phải bị chặn';
END TRY
BEGIN CATCH
    SET @Dat += 1;
    PRINT N' [ĐẠT] T14 Sai giảng viên bị chặn: ' + ERROR_MESSAGE();
END CATCH

/* T15: điểm ngoài khoảng 0-10 -> bị chặn */
SET @Tong += 1;
BEGIN TRY
    EXEC dbo.sp_NhapDiem 'GV006', @SV, 'INT1340-20261-01', 11, 8, 7;
    PRINT N' [SAI] T15 Lẽ ra phải bị chặn';
END TRY
BEGIN CATCH
    SET @Dat += 1;
    PRINT N' [ĐẠT] T15 Điểm không hợp lệ bị chặn: ' + ERROR_MESSAGE();
END CATCH

PRINT N'================ KIỂM THỬ TRIGGER XẾP LỊCH / TIÊN QUYẾT ================';

/* T16: xếp lịch trùng phòng A2-301 Thứ 2 tiết 1-3 -> trigger chặn */
SET @Tong += 1;
BEGIN TRY
    EXEC dbo.sp_ThemLichHoc 'INT1336-20262-01', 2, 1, 3, 'A2-301';
    PRINT N' [SAI] T16 Lẽ ra phải bị chặn (trùng phòng)';
END TRY
BEGIN CATCH
    SET @Dat += 1;
    PRINT N' [ĐẠT] T16 Trùng phòng bị chặn: ' + ERROR_MESSAGE();
END CATCH

/* T17: giảng viên GV001 bị xếp 2 lớp cùng lúc (Thứ 2 tiết 2-3) -> trigger chặn */
SET @Tong += 1;
BEGIN TRY
    EXEC dbo.sp_ThemLichHoc 'INT1313-20262-02', 2, 2, 2, 'B1-101';
    PRINT N' [SAI] T17 Lẽ ra phải bị chặn (trùng giảng viên)';
END TRY
BEGIN CATCH
    SET @Dat += 1;
    PRINT N' [ĐẠT] T17 Trùng giảng viên bị chặn: ' + ERROR_MESSAGE();
END CATCH

/* T18: tạo vòng lặp tiên quyết INT1154 cần INT1313 (trong khi INT1313 gián tiếp cần INT1154) */
SET @Tong += 1;
BEGIN TRY
    INSERT INTO dbo.MonTienQuyet (MaMH, MaMHTienQuyet) VALUES ('INT1154', 'INT1313');
    PRINT N' [SAI] T18 Lẽ ra phải bị chặn (vòng lặp)';
END TRY
BEGIN CATCH
    SET @Dat += 1;
    PRINT N' [ĐẠT] T18 Vòng lặp tiên quyết bị chặn: ' + ERROR_MESSAGE();
END CATCH

/* ------------------------------- DỌN DẸP ------------------------------- */
DELETE dk
FROM dbo.DangKy dk
JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
WHERE l.MaHK = '20262'
  AND dk.MaSV IN ('B25DCCN001', 'B25DCCN002', 'B25DCCN003', 'B25DCCN004', 'B24DCCN001');

DELETE FROM dbo.NhatKyDangKy
WHERE ThoiGian >= @BatDau
  AND MaSV IN ('B25DCCN001', 'B25DCCN002', 'B25DCCN003', 'B25DCCN004', 'B24DCCN001');

UPDATE dbo.HocKy SET NgayMoDK = @MoCu, NgayDongDK = @DongCu, SoTCToiDa = @TCCu
WHERE MaHK = '20262';

PRINT N'';
PRINT N'KẾT QUẢ: ' + CAST(@Dat AS NVARCHAR(3)) + N'/' + CAST(@Tong AS NVARCHAR(3)) + N' test đạt.';
GO

/* =====================================================================
   DEMO TRANH CHẤP (2 người cùng giành chỗ cuối) - làm bằng tay khi bảo vệ
   1. Chạy trước để lớp INT1336-20262-03 chỉ còn đúng 1 chỗ:
        UPDATE dbo.LopHocPhan SET SiSoToiDa = SiSoHienTai + 1 WHERE MaLHP = 'INT1336-20262-03';
   2. Mở 2 cửa sổ query trong SSMS:
        Cửa sổ 1:  BEGIN TRAN;
                   EXEC dbo.sp_DangKyHocPhan 'B25DCCN010', 'INT1336-20262-03';
                   -- chưa COMMIT, khóa vẫn đang giữ
        Cửa sổ 2:  EXEC dbo.sp_DangKyHocPhan 'B25DCCN011', 'INT1336-20262-03';
                   -- cửa sổ này phải CHỜ vì dòng lớp học phần đang bị khóa
        Cửa sổ 1:  COMMIT;
        -> Cửa sổ 2 chạy tiếp và nhận lỗi "Lớp đã đủ sĩ số." => không bị lố sĩ số.
   3. Trả lại như cũ:
        EXEC dbo.sp_HuyDangKy 'B25DCCN010', 'INT1336-20262-03';
        UPDATE dbo.LopHocPhan SET SiSoToiDa = 60 WHERE MaLHP = 'INT1336-20262-03';
   ===================================================================== */
