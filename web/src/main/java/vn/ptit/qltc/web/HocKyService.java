package vn.ptit.qltc.web;

import java.util.List;
import java.util.Map;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class HocKyService {

    private final JdbcTemplate jdbc;

    public HocKyService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String, Object>> danhSach() {
        return jdbc.queryForList("""
                SELECT MaHK, TenHK, NgayBatDau, NgayKetThuc, NgayMoDK, NgayDongDK, SoTCToiDa,
                       CAST(CASE WHEN GETDATE() BETWEEN NgayMoDK AND NgayDongDK THEN 1 ELSE 0 END AS BIT) AS DangMo
                FROM dbo.HocKy ORDER BY MaHK DESC
                """);
    }

    public Map<String, Object> layHocKy(String maHK) {
        return danhSach().stream().filter(h -> maHK.equals(h.get("MaHK"))).findFirst().orElse(null);
    }

    /** Học kỳ đang mở đăng ký; nếu không có thì lấy học kỳ mới nhất. */
    public String hocKyHienTai() {
        List<String> dangMo = jdbc.queryForList("""
                SELECT TOP (1) MaHK FROM dbo.HocKy
                WHERE GETDATE() BETWEEN NgayMoDK AND NgayDongDK ORDER BY MaHK DESC
                """, String.class);
        if (!dangMo.isEmpty()) {
            return dangMo.get(0);
        }
        return jdbc.queryForObject("SELECT MAX(MaHK) FROM dbo.HocKy", String.class);
    }

    /** Chọn học kỳ từ tham số URL, hợp lệ thì dùng, không thì lấy học kỳ hiện tại. */
    public String chon(String maHK) {
        if (maHK != null && layHocKy(maHK) != null) {
            return maHK;
        }
        return hocKyHienTai();
    }
}
