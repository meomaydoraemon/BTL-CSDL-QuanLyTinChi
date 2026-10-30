package vn.ptit.qltc.web;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.ControllerAdvice;

import vn.ptit.qltc.security.TaiKhoanUser;

@Controller
public class HomeController {

    @GetMapping("/login")
    public String login() {
        return "login";
    }

    /** Sau khi đăng nhập, đưa mỗi vai trò về trang chính của mình. */
    @GetMapping("/")
    public String trangChu(@AuthenticationPrincipal TaiKhoanUser user) {
        return switch (user.getVaiTro()) {
            case "SV" -> "redirect:/sv/dang-ky";
            case "GV" -> "redirect:/gv/lop";
            default   -> "redirect:/pdt/dashboard";
        };
    }

    /** Đưa người dùng đang đăng nhập vào mọi trang (thanh trên cùng dùng). */
    @ControllerAdvice
    static class NguoiDungAdvice {
        @ModelAttribute("me")
        public TaiKhoanUser me(@AuthenticationPrincipal TaiKhoanUser user) {
            return user;
        }
    }
}
