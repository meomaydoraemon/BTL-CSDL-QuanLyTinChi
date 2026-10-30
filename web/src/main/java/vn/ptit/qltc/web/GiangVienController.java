package vn.ptit.qltc.web;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.dao.DataAccessException;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import vn.ptit.qltc.security.TaiKhoanUser;

@Controller
@RequestMapping("/gv")
public class GiangVienController {

    private final JdbcTemplate jdbc;
    private final HocKyService hocKy;

    public GiangVienController(JdbcTemplate jdbc, HocKyService hocKy) {
        this.jdbc = jdbc;
        this.hocKy = hocKy;
    }

    @GetMapping("/lop")
    public String dsLop(@AuthenticationPrincipal TaiKhoanUser me,
                        @RequestParam(required = false) String hk, Model model) {
        String maHK = hk != null ? hocKy.chon(hk) : hocKyCoLop(me.getMaGV());
        List<Map<String, Object>> lop = jdbc.queryForList("""
                SELECT t.MaLHP, t.MaMH, t.TenMH, t.SiSoToiDa, t.SoSinhVien, t.SoCoDiem, t.TyLeDat,
                       t.DiemTrungBinh, v.LichHoc, v.Nhom
                FROM dbo.v_ThongKeLopHocPhan t
                JOIN dbo.v_LopHocPhanChiTiet v ON v.MaLHP = t.MaLHP
                WHERE t.MaGV = ? AND t.MaHK = ?
                ORDER BY t.MaMH, v.Nhom
                """, me.getMaGV(), maHK);

        model.addAttribute("menu", "gv-lop");
        model.addAttribute("dsHocKy", hocKy.danhSach());
        model.addAttribute("hk", hocKy.layHocKy(maHK));
        model.addAttribute("lop", lop);
        return "gv/lop";
    }

    /** Mặc định mở học kỳ gần nhất mà giảng viên còn lớp chưa chấm xong (hoặc có lớp). */
    private String hocKyCoLop(String maGV) {
        List<String> ds = jdbc.queryForList("""
                SELECT TOP (1) t.MaHK FROM dbo.v_ThongKeLopHocPhan t
                WHERE t.MaGV = ? AND t.SoSinhVien > 0
                ORDER BY CASE WHEN t.SoCoDiem < t.SoSinhVien THEN 0 ELSE 1 END, t.MaHK DESC
                """, String.class, maGV);
        return ds.isEmpty() ? hocKy.hocKyHienTai() : ds.get(0);
    }

    @GetMapping("/lop/{maLHP}")
    public String nhapDiem(@AuthenticationPrincipal TaiKhoanUser me, @PathVariable String maLHP, Model model) {
        List<Map<String, Object>> info = jdbc.queryForList("""
                SELECT v.*, mh.TyLeCC, mh.TyLeGK, mh.TyLeCK, hk.TenHK
                FROM dbo.v_LopHocPhanChiTiet v
                JOIN dbo.MonHoc mh ON mh.MaMH = v.MaMH
                JOIN dbo.HocKy hk  ON hk.MaHK = v.MaHK
                WHERE v.MaLHP = ? AND v.MaGV = ?
                """, maLHP, me.getMaGV());
        if (info.isEmpty()) {
            return "redirect:/gv/lop";
        }
        List<Map<String, Object>> sv = jdbc.queryForList("""
                SELECT sv.MaSV, sv.HoTen, kq.DiemCC, kq.DiemGK, kq.DiemCK, kq.DiemTK, kq.DiemChu
                FROM dbo.v_KetQuaHocTap kq
                JOIN dbo.SinhVien sv ON sv.MaSV = kq.MaSV
                WHERE kq.MaLHP = ?
                ORDER BY sv.MaSV
                """, maLHP);

        model.addAttribute("menu", "gv-lop");
        model.addAttribute("trang", "gv-nhap-diem");
        model.addAttribute("lop", info.get(0));
        model.addAttribute("sv", sv);
        model.addAttribute("soCoDiem", sv.stream().filter(r -> r.get("DiemTK") != null).count());
        return "gv/nhap-diem";
    }

    @PostMapping("/lop/{maLHP}/diem")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> luuDiem(@AuthenticationPrincipal TaiKhoanUser me,
                                                       @PathVariable String maLHP,
                                                       @RequestParam String maSV,
                                                       @RequestParam(required = false) BigDecimal cc,
                                                       @RequestParam(required = false) BigDecimal gk,
                                                       @RequestParam(required = false) BigDecimal ck) {
        Map<String, Object> kq = new HashMap<>();
        try {
            jdbc.update("EXEC dbo.sp_NhapDiem ?, ?, ?, ?, ?, ?", me.getMaGV(), maSV, maLHP, cc, gk, ck);
            Map<String, Object> moi = jdbc.queryForMap(
                    "SELECT DiemTK, DiemChu FROM dbo.v_KetQuaHocTap WHERE MaSV = ? AND MaLHP = ?", maSV, maLHP);
            kq.put("ok", true);
            kq.put("message", "Đã lưu điểm sinh viên " + maSV + ".");
            kq.put("diemTK", moi.get("DiemTK"));
            kq.put("diemChu", moi.get("DiemChu"));
        } catch (DataAccessException ex) {
            kq.put("ok", false);
            kq.put("message", SqlLoi.thongBao(ex));
        }
        return ResponseEntity.ok(kq);
    }
}
