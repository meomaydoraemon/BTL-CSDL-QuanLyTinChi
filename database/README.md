# CSDL Quản lý đăng ký tín chỉ

Yêu cầu: **SQL Server 2017 trở lên** (khuyến nghị 2019/2022, bản Express cũng được) và **SSMS**.

## Các file

| File | Nội dung |
|---|---|
| `00_ERD.dbml` | Code sơ đồ ERD, dán vào https://dbdiagram.io để xem và xuất ảnh |
| `01_schema.sql` | Tạo CSDL `QuanLyTinChi`: 12 bảng, ràng buộc PK/FK/CHECK/UNIQUE, chỉ mục |
| `02_seed_data.sql` | Dữ liệu mẫu: 300 SV, 10 GV, 18 môn, 6 học kỳ, khoảng 3.600 lượt đăng ký có điểm |
| `03_functions_views.sql` | 4 hàm (có hàm đệ quy kiểm tra tiên quyết) và 7 view (GPA, xếp hạng, thống kê) |
| `04_triggers.sql` | 5 trigger: sĩ số, nhật ký, tính điểm, chống trùng lịch, chống vòng lặp tiên quyết |
| `05_procedures.sql` | 9 thủ tục: đăng ký (7 bước kiểm tra), hủy, nhập điểm, thời khóa biểu, bảng điểm... |
| `06_queries.sql` | 21 truy vấn mẫu từ cơ bản đến nâng cao, có ghi kỹ thuật dùng |
| `07_tests.sql` | 18 test case tự động, in kết quả [ĐẠT]/[SAI] |
| `chay_tat_ca.bat` | Chạy toàn bộ các file trên theo đúng thứ tự |

**Bắt buộc chạy theo thứ tự 01 → 07.** File 01 xóa và tạo lại CSDL, nên muốn làm lại từ đầu chỉ cần chạy lại từ 01.

## Cách 1: chạy bằng cmd

```
cd duong-dan\QuanLyTinChi\database
chay_tat_ca.bat
```

Nếu cài SQL Server Express:

```
chay_tat_ca.bat .\SQLEXPRESS
```

Cuối cùng phải thấy dòng `KẾT QUẢ: 18/18 test đạt.`

## Cách 2: chạy bằng SSMS

Mở lần lượt từng file 01 → 07, mỗi file bấm **F5**. Xem kết quả test ở tab **Messages**.

## Dữ liệu demo

Mật khẩu tất cả tài khoản: **123456**

| Tài khoản | Vai trò | Dùng để demo |
|---|---|---|
| `admin` | Phòng đào tạo | Mở lớp, xếp lịch, đổi thời gian đăng ký, thống kê |
| `gv006` | Giảng viên | Nhập điểm lớp `INT1340-20261-01` (chưa có điểm cuối kỳ) |
| `b25dccn001` | Sinh viên giỏi | Đăng ký thành công; thử lớp `INT1323-20262-03` để thấy **trùng lịch** |
| `b25dccn002` | Trượt CTDL | Đăng ký CSDL bị chặn: **thiếu tiên quyết trực tiếp** |
| `b25dccn003` | Trượt Tin học cơ sở 2 | Đăng ký CSDL bị chặn: **thiếu tiên quyết gián tiếp** (đệ quy) |
| `b25dccn004` | Sinh viên giỏi | Đăng ký `INT1323-20262-04` bị chặn: **lớp đầy** |
| `b24dccn001` | Sinh viên giỏi | Đăng ký lại CSDL bị chặn: **đã đạt môn** |

Học kỳ **20262** mở đăng ký từ 15/10/2026 đến 10/01/2027. Nếu demo ngoài khoảng này:

```sql
DECLARE @Mo DATETIME = GETDATE(), @Dong DATETIME = DATEADD(DAY, 30, GETDATE());
EXEC dbo.sp_CapNhatThoiGianDangKy '20262', @Mo, @Dong;
```

Mã môn học trong dữ liệu mẫu chỉ mang tính minh họa. Thang điểm chữ trong bảng `ThangDiem` cần đối chiếu lại với quy chế hiện hành của PTIT.

## Những điểm nên trình bày khi bảo vệ

1. **Chuẩn hóa 3NF**: điểm chữ không lưu trong `DangKy` mà tra cứu qua `ThangDiem`, vì `DiemTK → DiemChu` là phụ thuộc bắc cầu.
2. **Phi chuẩn hóa có chủ đích**: `DiemTK` và `SiSoHienTai` là dữ liệu dẫn xuất nhưng vẫn lưu để truy vấn nhanh; trigger giữ chúng luôn đúng.
3. **Kiểm tra tiên quyết đệ quy** bằng CTE trong `fn_DSTienQuyetChuaDat`, bắt được cả môn tiên quyết gián tiếp.
4. **Giao dịch và khóa** trong `sp_DangKyHocPhan`: `UPDLOCK, HOLDLOCK` chống hai người cùng giành chỗ cuối (cuối file 07 có hướng dẫn demo bằng 2 cửa sổ SSMS).
5. **Ràng buộc CHECK làm chốt chặn cuối**: `SiSoHienTai <= SiSoToiDa`, tổng tỷ lệ điểm = 100.
6. **Filtered unique index** trên `TaiKhoan.MaSV`: ràng buộc UNIQUE thường chỉ cho phép 1 giá trị NULL.
7. **Chỉ mục**: truy vấn Q21 trong file 06 so sánh số lần đọc trang khi có và không có index.
