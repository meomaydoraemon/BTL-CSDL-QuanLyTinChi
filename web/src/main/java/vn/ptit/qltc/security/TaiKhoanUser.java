package vn.ptit.qltc.security;

import java.util.Collection;
import java.util.List;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

/** Người dùng đang đăng nhập, lấy từ bảng TaiKhoan. */
public class TaiKhoanUser implements UserDetails {

    private final String tenDangNhap;
    private final String matKhauHash;
    private final String vaiTro;      // SV, GV, PDT
    private final String maSV;
    private final String maGV;
    private final String hoTen;

    public TaiKhoanUser(String tenDangNhap, String matKhauHash, String vaiTro,
                        String maSV, String maGV, String hoTen) {
        this.tenDangNhap = tenDangNhap;
        this.matKhauHash = matKhauHash;
        this.vaiTro = vaiTro;
        this.maSV = maSV;
        this.maGV = maGV;
        this.hoTen = hoTen;
    }

    public String getVaiTro() { return vaiTro; }
    public String getMaSV()   { return maSV; }
    public String getMaGV()   { return maGV; }
    public String getHoTen()  { return hoTen; }

    public String getTenVaiTro() {
        return switch (vaiTro) {
            case "SV" -> "Sinh viên";
            case "GV" -> "Giảng viên";
            default   -> "Phòng đào tạo";
        };
    }

    /** Chữ cái đầu của tên (VD: "Nguyễn Văn An" -> "A") để làm avatar. */
    public String getChuCaiDau() {
        if ("PDT".equals(vaiTro)) {
            return "P";
        }
        String[] tu = hoTen.trim().split("\\s+");
        return tu[tu.length - 1].substring(0, 1).toUpperCase();
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + vaiTro));
    }

    @Override public String getPassword() { return matKhauHash; }
    @Override public String getUsername() { return tenDangNhap; }
}
