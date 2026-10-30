package vn.ptit.qltc.web;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.dao.DataAccessException;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import vn.ptit.qltc.security.TaiKhoanUser;

@Controller
@RequestMapping("/sv")
public class SinhVienController {

    private final JdbcTemplate jdbc;
    private final HocKyService hocKy;

    public SinhVienController(JdbcTemplate jdbc, HocKyService hocKy) {
        this.jdbc = jdbc;
        this.hocKy = hocKy;
    }

    /* ------------------------- ĐĂNG KÝ HỌC PHẦN ------------------------- */

    @GetMapping("/dang-ky")
    public String dangKy(@AuthenticationPrincipal TaiKhoanUser me,
                         @RequestParam(required = false) String hk, Model model) {
        String maHK = hocKy.chon(hk);
        Map<String, Object> hkInfo = hocKy.layHocKy(maHK);

        // Danh sách lớp + lý do không đăng ký được, lấy từ thủ tục sp_DSLopCoTheDangKy
        List<Map<String, Object>> lop = new ArrayList<>();
        for (Map<String, Object> r : jdbc.queryForList("EXEC dbo.sp_DSLopCoTheDangKy ?, ?", me.getMaSV(), maHK)) {
            Map<String, Object> row = new LinkedHashMap<>(r);
            row.put("TrangThai", trangThai(row));
            lop.add(row);
        }

        Integer daDangKy = jdbc.queryForObject("SELECT dbo.fn_SoTinChiDaDangKy(?, ?)", Integer.class, me.getMaSV(), maHK);
        int toiDa = ((Number) hkInfo.get("SoTCToiDa")).intValue();

        model.addAttribute("menu", "dang-ky");
        model.addAttribute("dsHocKy", hocKy.danhSach());
        model.addAttribute("hk", hkInfo);
        model.addAttribute("lop", lop);
        model.addAttribute("tcDaDangKy", daDangKy);
        model.addAttribute("tcToiDa", toiDa);
        model.addAttribute("phanTram", Math.min(100, daDangKy * 100 / Math.max(1, toiDa)));
        model.addAttribute("soLopDaDangKy", lop.stream().filter(r -> "DA_DK".equals(r.get("TrangThai"))).count());
        return "sv/dang-ky";
    }

    /** Phân loại để tô màu tag: xanh = được, xám = đầy / không cần, cam = vướng điều kiện. */
    private static String trangThai(Map<String, Object> r) {
        if (Boolean.TRUE.equals(r.get("DaDangKy"))) {
            return "DA_DK";
        }
        String lyDo = (String) r.get("LyDoKhongTheDangKy");
        if (lyDo == null) {
            return "DUOC";
        }
        return switch (lyDo) {
            case "Lớp đã đầy", "Đã đạt môn này", "Đã đăng ký môn này ở nhóm khác" -> "XAM";
            default -> "CAM";   // Trùng lịch, chưa đạt tiên quyết, vượt tín chỉ
        };
    }

    @PostMapping("/dang-ky")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> thucHienDangKy(@AuthenticationPrincipal TaiKhoanUser me,
                                                              @RequestParam String maLHP) {
        try {
            jdbc.update("EXEC dbo.sp_DangKyHocPhan ?, ?", me.getMaSV(), maLHP);
            return ResponseEntity.ok(Map.of("ok", true, "message", "Đã đăng ký lớp " + maLHP + "."));
        } catch (DataAccessException ex) {
            return ResponseEntity.ok(Map.of("ok", false, "message", SqlLoi.thongBao(ex)));
        }
    }

    @PostMapping("/huy")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> huyDangKy(@AuthenticationPrincipal TaiKhoanUser me,
                                                         @RequestParam String maLHP) {
        try {
            jdbc.update("EXEC dbo.sp_HuyDangKy ?, ?", me.getMaSV(), maLHP);
            return ResponseEntity.ok(Map.of("ok", true, "message", "Đã hủy đăng ký lớp " + maLHP + "."));
        } catch (DataAccessException ex) {
            return ResponseEntity.ok(Map.of("ok", false, "message", SqlLoi.thongBao(ex)));
        }
    }

    /* --------------------------- THỜI KHÓA BIỂU --------------------------- */

    @GetMapping("/thoi-khoa-bieu")
    public String thoiKhoaBieu(@AuthenticationPrincipal TaiKhoanUser me,
                               @RequestParam(required = false) String hk, Model model) {
        String maHK = hocKy.chon(hk);
        List<Map<String, Object>> buoi = jdbc.queryForList("EXEC dbo.sp_ThoiKhoaBieu ?, ?", me.getMaSV(), maHK);

        // Mỗi môn một màu nhạt cố định (theo thứ tự xuất hiện)
        Map<String, Integer> mauTheoMon = new LinkedHashMap<>();
        for (Map<String, Object> b : buoi) {
            mauTheoMon.putIfAbsent((String) b.get("MaMH"), mauTheoMon.size() % 8);
            b.put("Mau", mauTheoMon.get((String) b.get("MaMH")));
        }

        model.addAttribute("menu", "tkb");
        model.addAttribute("dsHocKy", hocKy.danhSach());
        model.addAttribute("hk", hocKy.layHocKy(maHK));
        model.addAttribute("buoi", buoi);
        model.addAttribute("soMon", mauTheoMon.size());
        return "sv/thoi-khoa-bieu";
    }

    /* ------------------------------ BẢNG ĐIỂM ----------------------------- */

    @GetMapping("/bang-diem")
    public String bangDiem(@AuthenticationPrincipal TaiKhoanUser me, Model model) {
        // Cùng dữ liệu với sp_BangDiemSinhVien, truy vấn trực tiếp các view để nhóm theo học kỳ
        List<Map<String, Object>> mon = jdbc.queryForList("""
                SELECT kq.MaHK, kq.MaLHP, kq.MaMH, kq.TenMH, kq.SoTinChi, kq.DiemCC, kq.DiemGK, kq.DiemCK,
                       kq.DiemTK, kq.DiemChu, kq.DiemHe4, kq.KetQua
                FROM dbo.v_KetQuaHocTap kq
                WHERE kq.MaSV = ?
                ORDER BY kq.MaHK DESC, kq.MaMH
                """, me.getMaSV());
        List<Map<String, Object>> hocKyCuaSV = jdbc.queryForList("""
                SELECT hk.MaHK, hk.TenHK,
                       dbo.fn_SoTinChiDaDangKy(?, hk.MaHK) AS SoTC,
                       dbo.fn_GPAHocKy(?, hk.MaHK)         AS GPA
                FROM dbo.HocKy hk
                WHERE EXISTS (SELECT 1 FROM dbo.DangKy dk JOIN dbo.LopHocPhan l ON l.MaLHP = dk.MaLHP
                              WHERE dk.MaSV = ? AND l.MaHK = hk.MaHK)
                ORDER BY hk.MaHK DESC
                """, me.getMaSV(), me.getMaSV(), me.getMaSV());
        for (Map<String, Object> h : hocKyCuaSV) {
            h.put("Mon", mon.stream().filter(m -> h.get("MaHK").equals(m.get("MaHK"))).toList());
        }
        Map<String, Object> tichLuy = jdbc.queryForMap("""
                SELECT SoTCTichLuy, GPATichLuy, XepLoai FROM dbo.v_GPATichLuy WHERE MaSV = ?
                """, me.getMaSV());
        Map<String, Object> hang = jdbc.queryForList("""
                SELECT HangTrongKhoaHoc, (SELECT COUNT(*) FROM dbo.v_XepHangGPA x WHERE x.NienKhoa = v.NienKhoa) AS TongSo
                FROM dbo.v_XepHangGPA v WHERE MaSV = ?
                """, me.getMaSV()).stream().findFirst().orElse(null);
        long soMonNo = jdbc.queryForObject("SELECT COUNT(*) FROM dbo.v_SinhVienNoMon WHERE MaSV = ?", Long.class, me.getMaSV());

        model.addAttribute("menu", "bang-diem");
        model.addAttribute("dsHK", hocKyCuaSV);
        model.addAttribute("tichLuy", tichLuy);
        model.addAttribute("hang", hang);
        model.addAttribute("soMonNo", soMonNo);
        return "sv/bang-diem";
    }
}
