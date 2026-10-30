# Giao diện web - Quản lý đăng ký tín chỉ

Spring Boot 3 + Thymeleaf + Bootstrap 5 + Bootstrap Icons + Chart.js, font Be Vietnam Pro.
Mọi nghiệp vụ gọi thẳng thủ tục / view / hàm trong CSDL `QuanLyTinChi` (không viết lại logic ở Java).

## Yêu cầu trên máy

- **SQL Server Express** (2017 trở lên, instance `SQLEXPRESS`) kèm `sqlcmd`, đã **bật TCP/IP cổng 1433**:
  SQL Server Configuration Manager → Protocols for SQLEXPRESS → TCP/IP = Enabled; tab IP Addresses,
  mục IPAll: xóa TCP Dynamic Ports, đặt TCP Port = 1433 → Restart dịch vụ SQL Server (SQLEXPRESS).
- **JDK 21** (ví dụ Eclipse Temurin 21). **Không cần cài Maven**: Maven Wrapper (`mvnw.cmd`) tự tải về.
- Internet ở lần cài đầu tiên (tải Maven và thư viện).

Đăng nhập SQL Server bằng Windows Authentication nhờ file `lib\mssql-jdbc_auth-12.8.1.x64.dll`.
File này **không có trong git**: Maven tự tải từ Maven Central vào `web\lib` mỗi lần build (`CAI_DAT_LAN_DAU.bat`).

## Đổi máy chủ / cổng / instance SQL Server

Mặc định: `localhost`, cổng `1433`, instance `SQLEXPRESS` (khai báo trong `src\main\resources\application.properties`,
**không sửa file đó**). Máy khác mặc định thì chép file mẫu rồi sửa:

```bat
copy web\config\application.properties.example web\config\application.properties
notepad web\config\application.properties
```

| Khóa | Ý nghĩa | Mặc định |
|---|---|---|
| `qltc.db.server` | Máy chủ SQL Server | `localhost` |
| `qltc.db.port` | Cổng TCP | `1433` |
| `qltc.sql.instance` | Tên instance, dùng để kiểm tra dịch vụ và cho nút Reset (`sqlcmd -S .\<instance>`) | `SQLEXPRESS` |
| `spring.datasource.url / username / password` | Dùng tài khoản SQL (`sa`) thay Windows Authentication | (không dùng) |

`web\config\application.properties` nằm trong `.gitignore`, nên không lộ mật khẩu hay cấu hình riêng lên repo.
Spring Boot tự đọc file này (thư mục `config` cạnh nơi chạy ứng dụng), các script PowerShell cũng đọc cùng file.
Sửa xong: Dừng rồi mở lại ứng dụng, không cần build lại.

## Cài đặt lần đầu (mỗi máy làm 1 lần, sau khi tải project từ GitHub)

Nhấp đúp **`CAI_DAT_LAN_DAU.bat`** ở thư mục gốc `QuanLyTinChi`. File này:

1. Tự tìm JDK 21 trên máy (JAVA_HOME, PATH, `%USERPROFILE%\.jdks`, `Program Files\...`).
2. Build ứng dụng thành `web\target\quanlytinchi-web.jar`.
3. Tạo 3 biểu tượng ở **2 nơi**: trên **Desktop** và ngay trong **thư mục `QuanLyTinChi`**
   (cạnh file `CAI_DAT_LAN_DAU.bat`), trỏ tới **đúng thư mục project trên máy đó**:

| Biểu tượng | Tác dụng |
|---|---|
| **Quản lý tín chỉ** | Mở ứng dụng: chạy ngầm (không có cửa sổ cmd), chờ sẵn sàng rồi tự mở http://localhost:8080 trên trình duyệt mặc định. Nếu app đang chạy thì chỉ mở trình duyệt. **Không đụng tới dữ liệu.** |
| **Dừng Quản lý tín chỉ** | Tắt ứng dụng đang chạy ngầm. |
| **Reset dữ liệu demo** | Hỏi xác nhận, rồi chạy `database\chay_tat_ca.bat .\SQLEXPRESS`: xóa và tạo lại CSDL với dữ liệu mẫu, chạy 18 test. Dùng trước buổi bảo vệ. |

Máy mới chưa có CSDL: bấm **Reset dữ liệu demo** trước, rồi mới bấm **Quản lý tín chỉ**.

Sau khi `git pull` có code mới: chạy lại `CAI_DAT_LAN_DAU.bat` để build lại (shortcut cũ được ghi đè, không bị trùng).

Các biểu tượng chứa đường dẫn riêng của từng máy nên **không đưa lên GitHub** (đã có trong `.gitignore`).
Đổi tên / chuyển thư mục project sang chỗ khác thì biểu tượng cũ sẽ hỏng: chạy lại `CAI_DAT_LAN_DAU.bat`.

> Không nhấp đúp trực tiếp file `.ps1` (Windows sẽ mở bằng Notepad), và `web\chay_web.bat` chỉ dành cho
> lúc sửa code (mở cửa sổ cmd, đóng cmd là app tắt). Dùng 3 biểu tượng ở trên.

## Khi biểu tượng báo lỗi

Biểu tượng chính kiểm tra trước và báo bằng hộp thoại tiếng Việt, **không tự đổi cấu hình máy**:

- Dịch vụ SQL Server (SQLEXPRESS) đang tắt → hướng dẫn bật trong `services.msc`.
- SQL Server chạy nhưng chưa bật TCP/IP 1433 → hướng dẫn bật trong Configuration Manager.
- Chưa có CSDL `QuanLyTinChi` → nhắc bấm Reset dữ liệu demo.
- Chưa build / không có Java 21 → nhắc chạy `CAI_DAT_LAN_DAU.bat` / cài JDK 21.
- Ứng dụng khởi động lỗi → hiện vài dòng lỗi cuối, log đầy đủ ở `web\logs\app.log`.

## Chạy ở chế độ lập trình

```
web\chay_web.bat
```

Chạy bằng Maven với profile `dev`: giao diện đọc thẳng từ `src/main/resources`, sửa HTML/CSS chỉ cần F5
(sửa Java thì phải chạy lại). Nhớ bấm **Dừng Quản lý tín chỉ** trước, vì cả hai đều dùng cổng 8080.

## Tài khoản demo

Mở http://localhost:8080 . Mật khẩu mọi tài khoản: `123456` (tự chuyển sang bcrypt ở lần đăng nhập đầu).

| Tài khoản | Trang |
|---|---|
| `b25dccn001` | Đăng ký học phần, thời khóa biểu, bảng điểm |
| `gv006` | Lớp giảng dạy, nhập điểm lớp `INT1340-20261-01` |
| `admin` | Tổng quan (4 thẻ số liệu + 2 biểu đồ), lớp học phần, thời gian đăng ký |

## Thủ tục / view được dùng

| Trang | Đối tượng CSDL |
|---|---|
| Đăng ký học phần | `sp_DSLopCoTheDangKy`, `sp_DangKyHocPhan`, `sp_HuyDangKy`, `fn_SoTinChiDaDangKy` |
| Thời khóa biểu | `sp_ThoiKhoaBieu` |
| Bảng điểm | `v_KetQuaHocTap`, `v_GPATichLuy`, `v_XepHangGPA`, `v_SinhVienNoMon`, `fn_GPAHocKy` |
| Nhập điểm | `sp_NhapDiem` (trigger `trg_DangKy_TinhDiemTK` tự tính điểm tổng kết) |
| Tổng quan | `v_LopHocPhanChiTiet`, `v_ThongKeLopHocPhan`, `v_KetQuaHocTap` |
| Lớp học phần (mở lớp, xếp lịch) | `sp_TaoLopHocPhan`, `sp_ThemLichHoc`, trigger `trg_LichHoc_KiemTraTrung` |
| Học kỳ | `sp_CapNhatThoiGianDangKy` |

Thông báo lỗi trên toast là nguyên văn thông báo `THROW 500xx` của thủ tục / trigger.

Mỗi trang có nút **Xem SQL** cạnh tiêu đề: liệt kê các thủ tục, view, hàm, trigger trang đó dùng
kèm 1 dòng giải thích. Danh sách nằm trong `src/main/java/vn/ptit/qltc/web/SqlInfo.java`.
