/* =====================================================================
   BÀI TẬP LỚN CƠ SỞ DỮ LIỆU - HỆ THỐNG QUẢN LÝ ĐĂNG KÝ TÍN CHỈ
   File 01: Tạo cơ sở dữ liệu, các bảng, ràng buộc và chỉ mục
   Yêu cầu: SQL Server 2017 trở lên (dùng STRING_AGG, CREATE OR ALTER)
   ===================================================================== */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE master;
GO

-- Xóa CSDL cũ nếu đã tồn tại để có thể chạy lại script từ đầu
IF DB_ID(N'QuanLyTinChi') IS NOT NULL
BEGIN
    ALTER DATABASE QuanLyTinChi SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QuanLyTinChi;
END
GO

CREATE DATABASE QuanLyTinChi;
GO

USE QuanLyTinChi;
GO

/* ---------------------------------------------------------------------
   NHÓM 1: DANH MỤC
   --------------------------------------------------------------------- */

-- Bảng Khoa
CREATE TABLE dbo.Khoa (
    MaKhoa   VARCHAR(10)   NOT NULL,
    TenKhoa  NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_Khoa PRIMARY KEY (MaKhoa),
    CONSTRAINT UQ_Khoa_TenKhoa UNIQUE (TenKhoa)
);
GO

-- Bảng Sinh viên
CREATE TABLE dbo.SinhVien (
    MaSV      VARCHAR(12)   NOT NULL,
    HoTen     NVARCHAR(100) NOT NULL,
    NgaySinh  DATE          NOT NULL,
    GioiTinh  NVARCHAR(3)   NOT NULL,
    Email     VARCHAR(100)  NOT NULL,
    MaKhoa    VARCHAR(10)   NOT NULL,
    NienKhoa  VARCHAR(10)   NOT NULL,      -- VD: 2025-2030
    CONSTRAINT PK_SinhVien PRIMARY KEY (MaSV),
    CONSTRAINT UQ_SinhVien_Email UNIQUE (Email),
    CONSTRAINT FK_SinhVien_Khoa FOREIGN KEY (MaKhoa) REFERENCES dbo.Khoa(MaKhoa),
    CONSTRAINT CK_SinhVien_GioiTinh CHECK (GioiTinh IN (N'Nam', N'Nữ')),
    CONSTRAINT CK_SinhVien_Email CHECK (Email LIKE '%_@_%._%')
);
GO

-- Bảng Giảng viên
CREATE TABLE dbo.GiangVien (
    MaGV    VARCHAR(10)   NOT NULL,
    HoTen   NVARCHAR(100) NOT NULL,
    HocVi   NVARCHAR(20)  NOT NULL,
    Email   VARCHAR(100)  NOT NULL,
    MaKhoa  VARCHAR(10)   NOT NULL,
    CONSTRAINT PK_GiangVien PRIMARY KEY (MaGV),
    CONSTRAINT UQ_GiangVien_Email UNIQUE (Email),
    CONSTRAINT FK_GiangVien_Khoa FOREIGN KEY (MaKhoa) REFERENCES dbo.Khoa(MaKhoa),
    CONSTRAINT CK_GiangVien_HocVi CHECK (HocVi IN (N'ThS', N'TS', N'PGS.TS', N'GS.TS'))
);
GO

-- Bảng Môn học: mỗi môn có tỷ lệ điểm thành phần riêng
CREATE TABLE dbo.MonHoc (
    MaMH      VARCHAR(10)   NOT NULL,
    TenMH     NVARCHAR(150) NOT NULL,
    SoTinChi  TINYINT       NOT NULL,
    MaKhoa    VARCHAR(10)   NOT NULL,
    TyLeCC    TINYINT       NOT NULL CONSTRAINT DF_MonHoc_TyLeCC DEFAULT 10,
    TyLeGK    TINYINT       NOT NULL CONSTRAINT DF_MonHoc_TyLeGK DEFAULT 30,
    TyLeCK    TINYINT       NOT NULL CONSTRAINT DF_MonHoc_TyLeCK DEFAULT 60,
    CONSTRAINT PK_MonHoc PRIMARY KEY (MaMH),
    CONSTRAINT FK_MonHoc_Khoa FOREIGN KEY (MaKhoa) REFERENCES dbo.Khoa(MaKhoa),
    CONSTRAINT CK_MonHoc_SoTinChi CHECK (SoTinChi BETWEEN 1 AND 6),
    CONSTRAINT CK_MonHoc_TongTyLe CHECK (TyLeCC + TyLeGK + TyLeCK = 100)
);
GO

-- Bảng Môn tiên quyết: quan hệ đệ quy (môn học - môn học)
CREATE TABLE dbo.MonTienQuyet (
    MaMH           VARCHAR(10) NOT NULL,   -- môn cần học
    MaMHTienQuyet  VARCHAR(10) NOT NULL,   -- môn phải đạt trước
    CONSTRAINT PK_MonTienQuyet PRIMARY KEY (MaMH, MaMHTienQuyet),
    CONSTRAINT FK_MonTienQuyet_MonHoc FOREIGN KEY (MaMH) REFERENCES dbo.MonHoc(MaMH),
    CONSTRAINT FK_MonTienQuyet_MonTQ  FOREIGN KEY (MaMHTienQuyet) REFERENCES dbo.MonHoc(MaMH),
    CONSTRAINT CK_MonTienQuyet_KhacNhau CHECK (MaMH <> MaMHTienQuyet)
);
GO

/* ---------------------------------------------------------------------
   NHÓM 2: TỔ CHỨC HỌC KỲ
   --------------------------------------------------------------------- */

-- Bảng Học kỳ: chứa luôn thời gian mở/đóng đăng ký và số tín chỉ tối đa
CREATE TABLE dbo.HocKy (
    MaHK         VARCHAR(10)  NOT NULL,    -- VD: 20261 = HK1 năm học 2026-2027
    TenHK        NVARCHAR(50) NOT NULL,
    NgayBatDau   DATE         NOT NULL,
    NgayKetThuc  DATE         NOT NULL,
    NgayMoDK     DATETIME     NOT NULL,
    NgayDongDK   DATETIME     NOT NULL,
    SoTCToiDa    TINYINT      NOT NULL CONSTRAINT DF_HocKy_SoTCToiDa DEFAULT 25,
    CONSTRAINT PK_HocKy PRIMARY KEY (MaHK),
    CONSTRAINT CK_HocKy_NgayHoc CHECK (NgayKetThuc > NgayBatDau),
    CONSTRAINT CK_HocKy_NgayDK  CHECK (NgayDongDK > NgayMoDK),
    CONSTRAINT CK_HocKy_SoTCToiDa CHECK (SoTCToiDa BETWEEN 1 AND 40)
);
GO

-- Bảng Lớp học phần: một môn mở nhiều nhóm trong một học kỳ
CREATE TABLE dbo.LopHocPhan (
    MaLHP        VARCHAR(20) NOT NULL,     -- VD: INT1313-20262-01
    MaMH         VARCHAR(10) NOT NULL,
    MaHK         VARCHAR(10) NOT NULL,
    MaGV         VARCHAR(10) NOT NULL,
    Nhom         TINYINT     NOT NULL,
    SiSoToiDa    SMALLINT    NOT NULL,
    SiSoHienTai  SMALLINT    NOT NULL CONSTRAINT DF_LopHocPhan_SiSoHienTai DEFAULT 0,
    CONSTRAINT PK_LopHocPhan PRIMARY KEY (MaLHP),
    CONSTRAINT FK_LopHocPhan_MonHoc    FOREIGN KEY (MaMH) REFERENCES dbo.MonHoc(MaMH),
    CONSTRAINT FK_LopHocPhan_HocKy     FOREIGN KEY (MaHK) REFERENCES dbo.HocKy(MaHK),
    CONSTRAINT FK_LopHocPhan_GiangVien FOREIGN KEY (MaGV) REFERENCES dbo.GiangVien(MaGV),
    CONSTRAINT UQ_LopHocPhan_Mon_HK_Nhom UNIQUE (MaMH, MaHK, Nhom),
    CONSTRAINT CK_LopHocPhan_SiSoToiDa CHECK (SiSoToiDa > 0),
    -- Ràng buộc "chốt chặn cuối": sĩ số không bao giờ vượt tối đa
    CONSTRAINT CK_LopHocPhan_SiSo CHECK (SiSoHienTai BETWEEN 0 AND SiSoToiDa)
);
GO

-- Bảng Lịch học: một lớp có thể học nhiều buổi mỗi tuần
CREATE TABLE dbo.LichHoc (
    MaLich      INT IDENTITY(1,1) NOT NULL,
    MaLHP       VARCHAR(20) NOT NULL,
    Thu         TINYINT     NOT NULL,      -- 2..7, 8 = Chủ nhật
    TietBatDau  TINYINT     NOT NULL,      -- 1..12
    SoTiet      TINYINT     NOT NULL,
    Phong       VARCHAR(20) NOT NULL,
    CONSTRAINT PK_LichHoc PRIMARY KEY (MaLich),
    CONSTRAINT FK_LichHoc_LopHocPhan FOREIGN KEY (MaLHP) REFERENCES dbo.LopHocPhan(MaLHP)
        ON DELETE CASCADE,
    CONSTRAINT CK_LichHoc_Thu CHECK (Thu BETWEEN 2 AND 8),
    CONSTRAINT CK_LichHoc_Tiet CHECK (TietBatDau BETWEEN 1 AND 12 AND SoTiet >= 1
                                      AND TietBatDau + SoTiet - 1 <= 12)
);
GO

/* ---------------------------------------------------------------------
   NHÓM 3: NGHIỆP VỤ CHÍNH
   --------------------------------------------------------------------- */

-- Bảng Đăng ký: mỗi dòng là 1 sinh viên trong 1 lớp học phần, kèm điểm
-- DiemTK là thuộc tính dẫn xuất, do trigger tự tính (phi chuẩn hóa có chủ đích)
CREATE TABLE dbo.DangKy (
    MaSV        VARCHAR(12)  NOT NULL,
    MaLHP       VARCHAR(20)  NOT NULL,
    NgayDangKy  DATETIME     NOT NULL CONSTRAINT DF_DangKy_NgayDangKy DEFAULT GETDATE(),
    DiemCC      DECIMAL(4,2) NULL,
    DiemGK      DECIMAL(4,2) NULL,
    DiemCK      DECIMAL(4,2) NULL,
    DiemTK      DECIMAL(4,2) NULL,
    CONSTRAINT PK_DangKy PRIMARY KEY (MaSV, MaLHP),
    CONSTRAINT FK_DangKy_SinhVien   FOREIGN KEY (MaSV)  REFERENCES dbo.SinhVien(MaSV),
    CONSTRAINT FK_DangKy_LopHocPhan FOREIGN KEY (MaLHP) REFERENCES dbo.LopHocPhan(MaLHP),
    CONSTRAINT CK_DangKy_DiemCC CHECK (DiemCC BETWEEN 0 AND 10),
    CONSTRAINT CK_DangKy_DiemGK CHECK (DiemGK BETWEEN 0 AND 10),
    CONSTRAINT CK_DangKy_DiemCK CHECK (DiemCK BETWEEN 0 AND 10),
    CONSTRAINT CK_DangKy_DiemTK CHECK (DiemTK BETWEEN 0 AND 10)
);
GO

-- Bảng Thang điểm: tra cứu điểm chữ và điểm hệ 4 từ điểm tổng kết
-- Không lưu DiemChu trong DangKy vì DiemTK -> DiemChu là phụ thuộc bắc cầu (vi phạm 3NF)
CREATE TABLE dbo.ThangDiem (
    DiemChu  VARCHAR(2)   NOT NULL,
    DiemTu   DECIMAL(4,2) NOT NULL,
    DiemDen  DECIMAL(4,2) NOT NULL,
    DiemHe4  DECIMAL(3,2) NOT NULL,
    CONSTRAINT PK_ThangDiem PRIMARY KEY (DiemChu),
    CONSTRAINT CK_ThangDiem_Khoang CHECK (DiemTu <= DiemDen AND DiemTu >= 0 AND DiemDen <= 10),
    CONSTRAINT CK_ThangDiem_He4 CHECK (DiemHe4 BETWEEN 0 AND 4)
);
GO

/* ---------------------------------------------------------------------
   NHÓM 4: HỆ THỐNG
   --------------------------------------------------------------------- */

-- Bảng Tài khoản đăng nhập (3 vai trò: SV, GV, PDT = phòng đào tạo)
CREATE TABLE dbo.TaiKhoan (
    TenDangNhap  VARCHAR(50)  NOT NULL,
    MatKhauHash  VARCHAR(100) NOT NULL,
    VaiTro       VARCHAR(10)  NOT NULL,
    MaSV         VARCHAR(12)  NULL,
    MaGV         VARCHAR(10)  NULL,
    CONSTRAINT PK_TaiKhoan PRIMARY KEY (TenDangNhap),
    CONSTRAINT FK_TaiKhoan_SinhVien  FOREIGN KEY (MaSV) REFERENCES dbo.SinhVien(MaSV),
    CONSTRAINT FK_TaiKhoan_GiangVien FOREIGN KEY (MaGV) REFERENCES dbo.GiangVien(MaGV),
    CONSTRAINT CK_TaiKhoan_VaiTro CHECK (
           (VaiTro = 'SV'  AND MaSV IS NOT NULL AND MaGV IS NULL)
        OR (VaiTro = 'GV'  AND MaGV IS NOT NULL AND MaSV IS NULL)
        OR (VaiTro = 'PDT' AND MaSV IS NULL     AND MaGV IS NULL))
);
GO

-- Mỗi sinh viên / giảng viên chỉ có tối đa 1 tài khoản.
-- Dùng UNIQUE có lọc (filtered index) vì ràng buộc UNIQUE thường của SQL Server
-- chỉ cho phép đúng 1 giá trị NULL, trong khi cột này có nhiều NULL.
CREATE UNIQUE INDEX UX_TaiKhoan_MaSV ON dbo.TaiKhoan(MaSV) WHERE MaSV IS NOT NULL;
CREATE UNIQUE INDEX UX_TaiKhoan_MaGV ON dbo.TaiKhoan(MaGV) WHERE MaGV IS NOT NULL;
GO

-- Bảng Nhật ký đăng ký: trigger tự ghi mỗi lần đăng ký / hủy.
-- Không đặt khóa ngoại để giữ được lịch sử kể cả khi dữ liệu gốc bị xóa.
CREATE TABLE dbo.NhatKyDangKy (
    MaNK      BIGINT IDENTITY(1,1) NOT NULL,
    MaSV      VARCHAR(12)  NOT NULL,
    MaLHP     VARCHAR(20)  NOT NULL,
    HanhDong  NVARCHAR(10) NOT NULL,
    ThoiGian  DATETIME     NOT NULL CONSTRAINT DF_NhatKy_ThoiGian DEFAULT GETDATE(),
    CONSTRAINT PK_NhatKyDangKy PRIMARY KEY (MaNK),
    CONSTRAINT CK_NhatKy_HanhDong CHECK (HanhDong IN (N'DANG_KY', N'HUY'))
);
GO

/* ---------------------------------------------------------------------
   CHỈ MỤC (INDEX) cho các truy vấn hay dùng
   --------------------------------------------------------------------- */

-- Xem danh sách sinh viên của 1 lớp, thống kê điểm theo lớp
CREATE INDEX IX_DangKy_MaLHP ON dbo.DangKy(MaLHP) INCLUDE (DiemTK);

-- Tìm các lớp học phần của 1 học kỳ / 1 môn
CREATE INDEX IX_LopHocPhan_MaHK_MaMH ON dbo.LopHocPhan(MaHK, MaMH);
CREATE INDEX IX_LopHocPhan_MaGV ON dbo.LopHocPhan(MaGV);

-- Kiểm tra trùng lịch: tìm theo lớp và theo thứ/tiết
CREATE INDEX IX_LichHoc_MaLHP ON dbo.LichHoc(MaLHP);
CREATE INDEX IX_LichHoc_Thu_Tiet ON dbo.LichHoc(Thu, TietBatDau) INCLUDE (SoTiet, Phong, MaLHP);

-- Tra cứu sinh viên theo khoa, nhật ký theo sinh viên
CREATE INDEX IX_SinhVien_MaKhoa ON dbo.SinhVien(MaKhoa);
CREATE INDEX IX_NhatKy_MaSV ON dbo.NhatKyDangKy(MaSV, ThoiGian);
GO

PRINT N'Đã tạo xong CSDL QuanLyTinChi (12 bảng).';
GO
