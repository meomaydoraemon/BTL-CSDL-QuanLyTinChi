package vn.ptit.qltc.web;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import org.springframework.dao.DataAccessException;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/pdt")
public class PhongDaoTaoController {

    private final JdbcTemplate jdbc;
    private final HocKyService hocKy;

    public PhongDaoTaoController(JdbcTemplate jdbc, HocKyService hocKy) {
        this.jdbc = jdbc;
        this.hocKy = hocKy;
    }

    @GetMapping("/dashboard")
    public String dashboard(@RequestParam(required = false) String hk, Model model) {
        String maHK = hocKy.chon(hk);

        Map<String, Object> so = jdbc.queryForMap("""
                SELECT (SELECT COUNT(*) FROM dbo.SinhVien) AS TongSV,
                       (SELECT COUNT(*) FROM dbo.LopHocPhan WHERE MaHK = ?) AS SoLop,
                       (SELECT COUNT(*) FROM dbo.DangKy dk JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
                        WHERE l.MaHK = ?) AS LuotDK,
                       (SELECT COUNT(*) FROM dbo.LopHocPhan WHERE MaHK = ? AND SiSoHienTai >= SiSoToiDa) AS SoLopDay,
                       (SELECT COUNT(DISTINCT dk.MaSV) FROM dbo.DangKy dk JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
                        WHERE l.MaHK = ?) AS SoSVDaDK
                """, maHK, maHK, maHK, maHK);
        int soLop = ((Number) so.get("SoLop")).intValue();
        int soLopDay = ((Number) so.get("SoLopDay")).intValue();

        // Biểu đồ 1: phân bố điểm chữ toàn trường (thứ tự A+ -> F)
        List<Map<String, Object>> diemChu = jdbc.queryForList("""
                SELECT td.DiemChu, COUNT(kq.MaSV) AS SoLuong
                FROM dbo.ThangDiem td
                LEFT JOIN dbo.v_KetQuaHocTap kq ON kq.DiemChu = td.DiemChu
                GROUP BY td.DiemChu, td.DiemTu
                ORDER BY td.DiemTu DESC
                """);
        // Biểu đồ 2: tỷ lệ đạt theo môn (mọi học kỳ đã có điểm)
        List<Map<String, Object>> tyLeDat = jdbc.queryForList("""
                SELECT t.MaMH, t.TenMH,
                       CAST(100.0 * SUM(t.SoDat) / NULLIF(SUM(t.SoCoDiem), 0) AS DECIMAL(5,1)) AS TyLeDat
                FROM dbo.v_ThongKeLopHocPhan t
                GROUP BY t.MaMH, t.TenMH
                HAVING SUM(t.SoCoDiem) > 0
                ORDER BY TyLeDat
                """);
        // Các lớp sắp đầy trong kỳ
        List<Map<String, Object>> lopNong = jdbc.queryForList("""
                SELECT TOP (6) MaLHP, TenMH, TenGV, SiSoHienTai, SiSoToiDa,
                       CAST(100.0 * SiSoHienTai / SiSoToiDa AS INT) AS PhanTram
                FROM dbo.v_LopHocPhanChiTiet
                WHERE MaHK = ?
                ORDER BY 1.0 * SiSoHienTai / SiSoToiDa DESC, MaLHP
                """, maHK);

        model.addAttribute("menu", "dashboard");
        model.addAttribute("dsHocKy", hocKy.danhSach());
        model.addAttribute("hk", hocKy.layHocKy(maHK));
        model.addAttribute("so", so);
        model.addAttribute("tyLeLopDay", soLop == 0 ? 0 : Math.round(soLopDay * 1000.0 / soLop) / 10.0);
        model.addAttribute("diemChu", diemChu);
        model.addAttribute("tyLeDat", tyLeDat);
        model.addAttribute("lopNong", lopNong);
        return "pdt/dashboard";
    }

    @GetMapping("/lop")
    public String dsLop(@RequestParam(required = false) String hk, Model model) {
        String maHK = hocKy.chon(hk);
        List<Map<String, Object>> lop = jdbc.queryForList("""
                SELECT v.MaLHP, v.MaMH, v.TenMH, v.SoTinChi, v.Nhom, v.TenGV, v.SiSoHienTai, v.SiSoToiDa,
                       v.ChoTrong, v.LichHoc, t.SoCoDiem, t.TyLeDat, t.DiemTrungBinh
                FROM dbo.v_LopHocPhanChiTiet v
                JOIN dbo.v_ThongKeLopHocPhan t ON t.MaLHP = v.MaLHP
                WHERE v.MaHK = ?
                ORDER BY v.MaMH, v.Nhom
                """, maHK);
        model.addAttribute("menu", "pdt-lop");
        model.addAttribute("dsHocKy", hocKy.danhSach());
        model.addAttribute("hk", hocKy.layHocKy(maHK));
        model.addAttribute("lop", lop);
        model.addAttribute("dsMon", jdbc.queryForList("SELECT MaMH, TenMH, SoTinChi FROM dbo.MonHoc ORDER BY TenMH"));
        model.addAttribute("dsGV", jdbc.queryForList("SELECT MaGV, HoTen, HocVi FROM dbo.GiangVien ORDER BY MaGV"));
        return "pdt/lop";
    }

    /** Mở lớp mới: sp_TaoLopHocPhan tự đánh số nhóm và trả về mã lớp vừa tạo. */
    @PostMapping("/lop/mo")
    @ResponseBody
    public Map<String, Object> moLop(@RequestParam String maMH, @RequestParam String maHK,
                                     @RequestParam String maGV, @RequestParam int siSoToiDa) {
        if (siSoToiDa < 1 || siSoToiDa > 500) {
            return Map.of("ok", false, "message", "Sĩ số tối đa phải từ 1 đến 500.");
        }
        try {
            String maLHP = jdbc.queryForObject("EXEC dbo.sp_TaoLopHocPhan ?, ?, ?, ?", String.class,
                    maMH, maHK, maGV, siSoToiDa);
            return Map.of("ok", true, "message", "Đã mở lớp " + maLHP + ". Hãy xếp lịch học cho lớp.", "maLHP", maLHP);
        } catch (DataAccessException ex) {
            return Map.of("ok", false, "message", SqlLoi.thongBao(ex));
        }
    }

    /** Xếp 1 buổi học: trigger trg_LichHoc_KiemTraTrung chặn trùng phòng / trùng giảng viên. */
    @PostMapping("/lop/lich")
    @ResponseBody
    public Map<String, Object> xepLich(@RequestParam String maLHP, @RequestParam int thu,
                                       @RequestParam int tietBatDau, @RequestParam int soTiet,
                                       @RequestParam String phong) {
        // Kiểm tra trước để báo lỗi tiếng Việt thay cho thông báo CHECK constraint
        if (thu < 2 || thu > 8 || tietBatDau < 1 || soTiet < 1 || tietBatDau + soTiet - 1 > 12) {
            return Map.of("ok", false, "message", "Thứ phải từ 2 đến Chủ nhật, buổi học phải nằm trong tiết 1–12.");
        }
        if (phong.isBlank()) {
            return Map.of("ok", false, "message", "Vui lòng nhập phòng học.");
        }
        try {
            jdbc.update("EXEC dbo.sp_ThemLichHoc ?, ?, ?, ?, ?", maLHP, thu, tietBatDau, soTiet, phong.trim().toUpperCase());
            return Map.of("ok", true, "message", "Đã xếp lịch cho lớp " + maLHP + ".");
        } catch (DataAccessException ex) {
            return Map.of("ok", false, "message", SqlLoi.thongBao(ex));
        }
    }

    @GetMapping("/hoc-ky")
    public String dsHocKy(Model model) {
        model.addAttribute("menu", "pdt-hk");
        model.addAttribute("dsHocKy", hocKy.danhSach());
        return "pdt/hoc-ky";
    }

    @PostMapping("/hoc-ky")
    public String capNhatThoiGian(@RequestParam String maHK,
                                  @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime moDK,
                                  @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime dongDK,
                                  RedirectAttributes ra) {
        try {
            jdbc.update("EXEC dbo.sp_CapNhatThoiGianDangKy ?, ?, ?", maHK, moDK, dongDK);
            ra.addFlashAttribute("toastOk", "Đã cập nhật thời gian đăng ký học kỳ " + maHK + ".");
        } catch (DataAccessException ex) {
            ra.addFlashAttribute("toastLoi", SqlLoi.thongBao(ex));
        }
        return "redirect:/pdt/hoc-ky";
    }
}
