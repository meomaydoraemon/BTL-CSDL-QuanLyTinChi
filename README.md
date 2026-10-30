# Hệ thống quản lý đăng ký tín chỉ

Bài tập lớn môn Cơ sở dữ liệu: CSDL SQL Server cho nghiệp vụ đăng ký tín chỉ (12 bảng, hàm đệ quy kiểm tra
tiên quyết, trigger, thủ tục có giao dịch và khóa chống tranh chấp, 18 test tự động) kèm giao diện web
Spring Boot + Thymeleaf gọi thẳng các thủ tục đó.

**Thành viên mới: đọc [HUONG_DAN_CAI_DAT.md](HUONG_DAN_CAI_DAT.md)** (cài từng bước, khoảng 30–45 phút).

## Cấu trúc

| Thư mục / file | Nội dung |
|---|---|
| [database/](database/README.md) | Script SQL chạy theo thứ tự 01 → 07, `chay_tat_ca.bat` chạy tất cả, ERD dạng dbml |
| [web/](web/README.md) | Ứng dụng web: trang sinh viên, giảng viên, phòng đào tạo; script khởi động / dừng / reset |
| `CAI_DAT_LAN_DAU.bat` | Build ứng dụng web và tạo 3 biểu tượng trên Desktop của máy đang dùng |
| `HUONG_DAN_CAI_DAT.md` | Hướng dẫn cài đặt cho thành viên mới |

## Chạy nhanh (máy đã cài đủ SQL Server Express, bật TCP/IP 1433, JDK 21)

```bat
cd database
chay_tat_ca.bat .\SQLEXPRESS
cd ..
CAI_DAT_LAN_DAU.bat
```

Sau đó nhấp đúp biểu tượng **Quản lý tín chỉ**. Tài khoản demo: `b25dccn001`, `gv006`, `admin`, mật khẩu `123456`.

Máy dùng instance / cổng khác mặc định: xem mục *Cấu hình riêng* trong [HUONG_DAN_CAI_DAT.md](HUONG_DAN_CAI_DAT.md).
