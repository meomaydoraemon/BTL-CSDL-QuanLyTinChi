# Hướng dẫn cài đặt cho thành viên mới

Làm lần lượt từ bước 1 đến bước 7. Mỗi máy chỉ cần làm **một lần**, khoảng 30–45 phút (phần lớn là chờ tải).
Mọi lệnh bên dưới gõ trong **cmd** (nhấn `Windows + R`, gõ `cmd`, Enter), không phải PowerShell.

| Bước | Việc cần làm | Kiểm tra xong chưa |
|---|---|---|
| 1 | Cài SQL Server Express | Có dịch vụ `SQL Server (SQLEXPRESS)` |
| 2 | Cài SSMS và sqlcmd | Lệnh `sqlcmd -?` chạy được |
| 3 | Bật TCP/IP cổng 1433 | Lệnh kiểm tra cổng ra `TcpTestSucceeded : True` |
| 4 | Cài JDK 21 | Lệnh `java -version` ra 21 |
| 5 | Tải project (clone) | Có thư mục `QuanLyTinChi` |
| 6 | Tạo CSDL | Dòng cuối `KẾT QUẢ: 18/18 test đạt.` |
| 7 | Cài và chạy web | Trình duyệt mở trang đăng nhập |

---

## Bước 1. Cài SQL Server Express

1. Tìm "SQL Server Express download" trên Google, vào trang của Microsoft, bấm **Download now** ở ô
   **Express** (bản 2019, 2022 hay 2025 đều được).
2. Chạy file vừa tải. Cửa sổ đầu tiên hỏi kiểu cài đặt, có 3 ô lớn **Basic / Custom / Download Media**:
   chọn **Basic**.
3. Bấm **Accept** ở màn hình điều khoản, giữ nguyên thư mục cài đặt, bấm **Install**. Chờ 5–10 phút.
4. Cài xong, màn hình hiện dòng chữ **"Installation has completed successfully!"** kèm các thông tin
   như `INSTANCE NAME: SQLEXPRESS` và `CONNECTION STRING: Server=localhost\SQLEXPRESS;...`.
   Ghi lại **INSTANCE NAME** (thường là `SQLEXPRESS`). Bấm **Close**.

> Máy đã cài sẵn SQL Server bản **Developer / Standard** (instance mặc định `MSSQLSERVER`) cũng dùng được,
> nhưng phải sửa cấu hình ở mục [Cấu hình riêng](#cấu-hình-riêng-khi-máy-khác-mặc-định) cuối trang.

## Bước 2. Cài SSMS và kiểm tra sqlcmd

**SSMS** (SQL Server Management Studio) dùng để xem bảng, chạy câu lệnh bằng giao diện:

1. Tìm "Download SSMS", tải bản mới nhất từ trang Microsoft, cài với tùy chọn mặc định.
2. Mở SSMS. Ở hộp **Connect to Server**: *Server type* = `Database Engine`, *Server name* = `localhost\SQLEXPRESS`,
   *Authentication* = `Windows Authentication`, đánh dấu ô **Trust server certificate**, bấm **Connect**.
   Bên trái hiện cây thư mục có mục **Databases** là kết nối thành công.

**sqlcmd** là công cụ dòng lệnh mà các script của nhóm dùng. Mở cmd mới và gõ:

```bat
sqlcmd -?
```

Nếu ra bảng hướng dẫn tham số (dòng đầu có chữ `Microsoft (R) SQL Server Command Line Tool`) là đã có.
Nếu báo `'sqlcmd' is not recognized`: tìm "sqlcmd utility download" trên trang Microsoft Learn, cài bản
**ODBC sqlcmd** (gói *Microsoft Command Line Utilities for SQL Server*, cài kèm *ODBC Driver 18*), rồi mở **cmd mới** thử lại.

## Bước 3. Bật TCP/IP cổng 1433 (bắt buộc cho web)

SQL Server Express mặc định **tắt** TCP/IP. sqlcmd và SSMS vẫn chạy được, nhưng ứng dụng web (Java) thì không kết nối được.

1. Mở **SQL Server Configuration Manager**: nhấn `Windows + R` rồi gõ một trong các lệnh sau, tùy phiên bản
   (gõ thử lần lượt, cái nào mở được là đúng):
   - SQL Server 2025: `SQLServerManager17.msc`
   - SQL Server 2022: `SQLServerManager16.msc`
   - SQL Server 2019: `SQLServerManager15.msc`

   Không mở được: chuột phải nút Start → **Computer Management** → mở rộng **Services and Applications** → **SQL Server Configuration Manager**.
2. Cửa sổ chia 2 cột. Cột trái, mở rộng **SQL Server Network Configuration** → bấm **Protocols for SQLEXPRESS**.
   Cột phải hiện 3 dòng: *Shared Memory* (Enabled), *Named Pipes* (Disabled), **TCP/IP (Disabled)**.
3. Chuột phải **TCP/IP** → **Enable**. Hiện cảnh báo *"Any changes made will be saved; however, they will not take effect until the service is stopped and restarted"* → **OK**.
4. Chuột phải **TCP/IP** lần nữa → **Properties** → chọn tab **IP Addresses**. Đây là danh sách dài các mục
   IP1, IP2, ... Kéo xuống **cuối cùng**, tới mục **IPAll** có 2 ô:
   - **TCP Dynamic Ports**: đang có số (vd. `49712`) → **xóa trắng** ô này.
   - **TCP Port**: đang trống → gõ `1433`.

   Bấm **OK**.
5. Cột trái, bấm **SQL Server Services**. Cột phải có dòng **SQL Server (SQLEXPRESS)** trạng thái *Running* →
   chuột phải → **Restart**. Chờ vài giây đến khi trạng thái lại là *Running*.
6. Kiểm tra cổng đã mở (lệnh này chạy được trong cmd):

```bat
powershell -Command "Test-NetConnection localhost -Port 1433"
```

Dòng cuối phải là `TcpTestSucceeded : True`.

## Bước 4. Cài JDK 21

1. Vào https://adoptium.net, chọn **Temurin 21 (LTS)**, hệ điều hành **Windows x64**, tải file **.msi**.
2. Chạy file .msi. Ở màn hình **Custom Setup** có danh sách tính năng với biểu tượng ổ đĩa:
   bấm vào mục **Set JAVA_HOME variable** → chọn **"Will be installed on local hard drive"**
   (mặc định đang có dấu X đỏ). Bấm Next → Install.
3. Mở **cmd mới** và kiểm tra:

```bat
java -version
```

Phải thấy `openjdk version "21...."`. (Máy đã có JDK 21 qua IntelliJ ở `%USERPROFILE%\.jdks` thì không cần cài nữa, script tự tìm được.)

**Không cần cài Maven**: project có Maven Wrapper (`web\mvnw.cmd`), lần build đầu sẽ tự tải.

## Bước 5. Tải project về

Cần quyền truy cập repo private (nhờ trưởng nhóm mời qua GitHub, nhận lời mời trong email).

Có **Git** (tải ở https://git-scm.com):

```bat
cd /d D:\
git clone https://github.com/<ten-tai-khoan>/<ten-repo>.git QuanLyTinChi
cd QuanLyTinChi
```

Không dùng Git: trên trang repo bấm nút xanh **Code** → **Download ZIP**, giải nén ra một thư mục, rồi `cd` vào đó.

Nên để ở đường dẫn ngắn, không có dấu tiếng Việt (vd. `D:\QuanLyTinChi`). Đường dẫn có dấu cách vẫn chạy được.

## Bước 6. Tạo CSDL

```bat
cd database
chay_tat_ca.bat .\SQLEXPRESS
```

Script tạo CSDL `QuanLyTinChi` (12 bảng, dữ liệu mẫu, hàm, view, trigger, thủ tục) rồi chạy 18 test.
Dòng cuối phải là:

```
KẾT QUẢ: 18/18 test đạt.
```

Bấm phím bất kỳ để đóng. Sau đó quay lại thư mục gốc:

```bat
cd ..
```

## Bước 7. Cài và chạy web

```bat
CAI_DAT_LAN_DAU.bat
```

(Hoặc nhấp đúp file `CAI_DAT_LAN_DAU.bat` trong thư mục `QuanLyTinChi`.) Lần đầu mất vài phút để tải thư viện.
Thấy dòng `XONG.` là được. File này tạo **3 biểu tượng** trên Desktop và ngay trong thư mục `QuanLyTinChi`:

| Biểu tượng | Dùng để |
|---|---|
| **Quản lý tín chỉ** (mũ tốt nghiệp đỏ) | Mở ứng dụng. Chờ khoảng 15 giây, trình duyệt tự mở trang đăng nhập |
| **Dừng Quản lý tín chỉ** (xám) | Tắt ứng dụng đang chạy ngầm |
| **Reset dữ liệu demo** (cam) | Xóa mọi thay đổi, đưa CSDL về dữ liệu mẫu (giống bước 6) |

Đăng nhập thử, mật khẩu mọi tài khoản là `123456`:

| Tài khoản | Vai trò |
|---|---|
| `b25dccn001` | Sinh viên |
| `gv006` | Giảng viên |
| `admin` | Phòng đào tạo |

**Sau mỗi lần `git pull` có code web mới**: chạy lại `CAI_DAT_LAN_DAU.bat` để build lại.

---

## Cấu hình riêng (khi máy khác mặc định)

Mặc định ứng dụng kết nối `localhost`, cổng `1433`, instance `SQLEXPRESS`, đăng nhập Windows Authentication.
Máy khác mặc định thì **không sửa code**, mà tạo file cấu hình riêng (file này không đưa lên git):

```bat
copy web\config\application.properties.example web\config\application.properties
notepad web\config\application.properties
```

Trong Notepad, bỏ dấu `#` ở đầu dòng cần đổi, ví dụ:

| Trường hợp | Dòng cần sửa |
|---|---|
| Cài bản Developer/Standard (instance mặc định) | `qltc.sql.instance=MSSQLSERVER` |
| Đặt TCP Port khác 1433 ở bước 3 | `qltc.db.port=1434` (số cổng đã đặt) |
| Muốn đăng nhập bằng tài khoản `sa` | bỏ `#` 3 dòng `spring.datasource.url / username / password` |

Lưu file, bấm **Dừng Quản lý tín chỉ** rồi mở lại **Quản lý tín chỉ**. Không cần build lại.
Bước 6 cũng đổi theo, vd. instance mặc định: `chay_tat_ca.bat .` (dấu chấm).

## Gặp lỗi

| Hiện tượng | Cách xử lý |
|---|---|
| `chay_tat_ca.bat` báo `SSL Provider: The certificate chain was issued by an authority that is not trusted` | Đã xử lý sẵn bằng cờ `-C` trong script. Nếu vẫn gặp, sqlcmd quá cũ: cài lại sqlcmd (bước 2) |
| `chay_tat_ca.bat` báo `Login timeout expired` / không kết nối được | Sai tên instance hoặc dịch vụ đang tắt. Xem lại INSTANCE NAME ở bước 1, kiểm tra dịch vụ trong `services.msc` |
| Biểu tượng báo *"chưa nhận kết nối TCP"* | Chưa làm bước 3, hoặc quên Restart dịch vụ |
| Biểu tượng báo *"Dịch vụ SQL Server (SQLEXPRESS) đang TẮT"* | `Windows + R` → `services.msc` → chuột phải **SQL Server (SQLEXPRESS)** → **Start** |
| Biểu tượng báo *"chưa có CSDL QuanLyTinChi"* | Làm bước 6, hoặc bấm **Reset dữ liệu demo** |
| `CAI_DAT_LAN_DAU.bat` báo không tìm thấy JDK 21 | Làm bước 4, mở **cmd mới** rồi chạy lại |
| `CAI_DAT_LAN_DAU.bat` báo build thất bại | Kiểm tra Internet (lần đầu phải tải Maven và thư viện) rồi chạy lại |
| Trình duyệt báo `localhost refused to connect` | Ứng dụng chưa chạy hoặc đã bị dừng: bấm **Quản lý tín chỉ** |
| Đăng nhập được nhưng trang báo lỗi kết nối CSDL | Xem file `web\logs\app.log`, gửi vài dòng có chữ `ERROR` lên nhóm |
