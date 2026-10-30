package vn.ptit.qltc.web;

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Component;

/**
 * Danh sách đối tượng SQL mà mỗi trang dùng, hiện trong hộp thoại "Xem SQL".
 * Khóa là tên trang (biến "trang" hoặc "menu" trong model). Template gọi: ${@sqlInfo.cho(...)}
 */
@Component("sqlInfo")
public class SqlInfo {

    public record DoiTuong(String ten, String loai, String moTa) {
        /** Lớp màu của tag loại đối tượng. */
        public String mau() {
            return switch (loai) {
                case "Thủ tục" -> "tag-bad";
                case "Hàm"     -> "tag-info";
                case "View"    -> "tag-ok";
                case "Trigger" -> "tag-warn";
                default        -> "tag-gray";
            };
        }
    }

    private static DoiTuong sp(String ten, String moTa)  { return new DoiTuong(ten, "Thủ tục", moTa); }
    private static DoiTuong fn(String ten, String moTa)  { return new DoiTuong(ten, "Hàm", moTa); }
    private static DoiTuong v(String ten, String moTa)   { return new DoiTuong(ten, "View", moTa); }
    private static DoiTuong trg(String ten, String moTa) { return new DoiTuong(ten, "Trigger", moTa); }
    private static DoiTuong bang(String ten, String moTa) { return new DoiTuong(ten, "Bảng", moTa); }

    private static final Map<String, List<DoiTuong>> THEO_TRANG = Map.of(
        "login", List.of(
            bang("TaiKhoan", "đọc tài khoản theo tên đăng nhập; mật khẩu {noop} tự nâng cấp lên {bcrypt} ở lần đăng nhập đầu"),
            new DoiTuong("UX_TaiKhoan_MaSV / UX_TaiKhoan_MaGV", "Chỉ mục", "filtered unique index: mỗi sinh viên / giảng viên chỉ có 1 tài khoản"),
            new DoiTuong("CK_TaiKhoan_VaiTro", "Ràng buộc", "ràng buộc CHECK: vai trò SV phải có MaSV, GV phải có MaGV, PDT không có cả hai")),

        "dang-ky", List.of(
            sp("sp_DSLopCoTheDangKy", "danh sách lớp trong kỳ kèm lý do không đăng ký được (đầy, trùng lịch, thiếu tiên quyết...)"),
            sp("sp_DangKyHocPhan", "đăng ký, kiểm tra 7 điều kiện trong 1 transaction, khóa UPDLOCK chống lố sĩ số"),
            sp("sp_HuyDangKy", "hủy đăng ký khi còn trong thời gian đăng ký và lớp chưa có điểm"),
            fn("fn_SoTinChiDaDangKy", "tổng tín chỉ đã đăng ký trong kỳ, dùng cho thanh tiến độ X/25 tín chỉ"),
            fn("fn_DSTienQuyetChuaDat", "CTE đệ quy tìm môn tiên quyết chưa đạt, bắt được cả tiên quyết gián tiếp"),
            v("v_LopHocPhanChiTiet", "thông tin lớp, giảng viên, chỗ trống và lịch học ghép thành chuỗi bằng STRING_AGG"),
            trg("trg_DangKy_Insert", "tự tăng sĩ số lớp và ghi nhật ký DANG_KY khi đăng ký"),
            trg("trg_DangKy_Delete", "tự giảm sĩ số lớp và ghi nhật ký HUY khi hủy")),

        "tkb", List.of(
            sp("sp_ThoiKhoaBieu", "các buổi học của sinh viên trong kỳ (Thứ, tiết, phòng, giảng viên) để vẽ lưới tuần")),

        "bang-diem", List.of(
            v("v_KetQuaHocTap", "mỗi lượt học kèm điểm chữ và điểm hệ 4 tra từ bảng ThangDiem (không lưu, đảm bảo 3NF)"),
            v("v_GPATichLuy", "GPA tích lũy hệ 4, môn học lại chỉ lấy lần điểm cao nhất (ROW_NUMBER)"),
            v("v_XepHangGPA", "xếp hạng GPA trong khóa bằng hàm cửa sổ RANK()"),
            v("v_SinhVienNoMon", "các môn có điểm cao nhất vẫn dưới 4.0, để đếm số môn còn nợ"),
            fn("fn_GPAHocKy", "GPA từng học kỳ, trung bình có trọng số theo số tín chỉ"),
            fn("fn_SoTinChiDaDangKy", "số tín chỉ đã học trong từng kỳ"),
            fn("fn_XepLoaiHocLuc", "đổi GPA sang xếp loại Xuất sắc / Giỏi / Khá / Trung bình / Yếu")),

        "gv-lop", List.of(
            v("v_ThongKeLopHocPhan", "số sinh viên, số đã có điểm, tỷ lệ đạt và điểm trung bình của từng lớp"),
            v("v_LopHocPhanChiTiet", "lịch học của lớp ghép thành chuỗi")),

        "gv-nhap-diem", List.of(
            sp("sp_NhapDiem", "chỉ giảng viên phụ trách mới được nhập, điểm phải trong khoảng 0–10"),
            trg("trg_DangKy_TinhDiemTK", "tự tính điểm tổng kết theo tỷ lệ CC/GK/CK riêng của từng môn"),
            v("v_KetQuaHocTap", "lấy điểm tổng kết và điểm chữ sau khi lưu"),
            v("v_LopHocPhanChiTiet", "thông tin lớp và lịch học ở đầu trang")),

        "dashboard", List.of(
            v("v_KetQuaHocTap", "đếm số lượt theo điểm chữ cho biểu đồ phân bố điểm"),
            bang("ThangDiem", "thứ tự và khoảng điểm của các điểm chữ A+ → F"),
            v("v_ThongKeLopHocPhan", "gộp theo môn để tính tỷ lệ đạt cho biểu đồ thanh ngang"),
            v("v_LopHocPhanChiTiet", "các lớp có tỷ lệ sĩ số cao nhất trong kỳ")),

        "pdt-lop", List.of(
            sp("sp_TaoLopHocPhan", "mở lớp mới, tự đánh số nhóm và sinh mã lớp, khóa UPDLOCK chống trùng số nhóm"),
            sp("sp_ThemLichHoc", "thêm 1 buổi học (thứ, tiết bắt đầu, số tiết, phòng) cho lớp"),
            trg("trg_LichHoc_KiemTraTrung", "chặn xếp lịch trùng phòng hoặc trùng giảng viên trong cùng học kỳ"),
            v("v_LopHocPhanChiTiet", "danh sách lớp kèm giảng viên, chỗ trống và lịch học"),
            v("v_ThongKeLopHocPhan", "tỷ lệ đạt của từng lớp")),

        "pdt-hk", List.of(
            sp("sp_CapNhatThoiGianDangKy", "đổi thời gian mở / đóng đăng ký, kiểm tra thời gian đóng phải sau thời gian mở"),
            new DoiTuong("CK_HocKy_NgayDK", "Ràng buộc", "ràng buộc CHECK chốt chặn cuối: NgayDongDK > NgayMoDK"))
    );

    public List<DoiTuong> cho(String trang) {
        return trang == null ? List.of() : THEO_TRANG.getOrDefault(trang, List.of());
    }
}
