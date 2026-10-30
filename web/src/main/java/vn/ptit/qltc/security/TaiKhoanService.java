package vn.ptit.qltc.security;

import java.util.List;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsPasswordService;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

/**
 * Đọc tài khoản từ bảng TaiKhoan. Mật khẩu mẫu lưu dạng {noop}123456;
 * Spring Security gọi updatePassword() để nâng cấp sang {bcrypt} ngay lần đăng nhập đầu.
 */
@Service
public class TaiKhoanService implements UserDetailsService, UserDetailsPasswordService {

    private final JdbcTemplate jdbc;

    public TaiKhoanService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public UserDetails loadUserByUsername(String tenDangNhap) {
        List<TaiKhoanUser> ds = jdbc.query("""
                SELECT tk.TenDangNhap, tk.MatKhauHash, tk.VaiTro, tk.MaSV, tk.MaGV,
                       COALESCE(sv.HoTen, gv.HoTen, N'Phòng Đào tạo') AS HoTen
                FROM dbo.TaiKhoan tk
                LEFT JOIN dbo.SinhVien sv  ON sv.MaSV = tk.MaSV
                LEFT JOIN dbo.GiangVien gv ON gv.MaGV = tk.MaGV
                WHERE tk.TenDangNhap = ?
                """,
                (rs, i) -> new TaiKhoanUser(rs.getString("TenDangNhap"), rs.getString("MatKhauHash"),
                        rs.getString("VaiTro"), rs.getString("MaSV"), rs.getString("MaGV"),
                        rs.getString("HoTen")),
                tenDangNhap.trim().toLowerCase());
        if (ds.isEmpty()) {
            throw new UsernameNotFoundException("Không tìm thấy tài khoản " + tenDangNhap);
        }
        return ds.get(0);
    }

    @Override
    public UserDetails updatePassword(UserDetails user, String matKhauMoi) {
        jdbc.update("UPDATE dbo.TaiKhoan SET MatKhauHash = ? WHERE TenDangNhap = ?",
                matKhauMoi, user.getUsername());
        TaiKhoanUser u = (TaiKhoanUser) user;
        return new TaiKhoanUser(u.getUsername(), matKhauMoi, u.getVaiTro(),
                u.getMaSV(), u.getMaGV(), u.getHoTen());
    }
}
