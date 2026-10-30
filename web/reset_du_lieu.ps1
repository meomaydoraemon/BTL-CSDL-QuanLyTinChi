# =====================================================================
#  Reset dữ liệu demo (shortcut "Reset dữ liệu demo")
#  Hỏi xác nhận, rồi chạy database\chay_tat_ca.bat <server theo cấu hình, mặc định .\SQLEXPRESS>: tạo lại CSDL
#  QuanLyTinChi với dữ liệu mẫu ban đầu, chạy 18 test. Cửa sổ cmd hiện ra để xem kết quả.
# =====================================================================
. (Join-Path $PSScriptRoot 'scripts\chung.ps1')

$traLoi = Show-ThongBao ("Đưa CSDL QuanLyTinChi về dữ liệu mẫu ban đầu?`n`n" +
    "Mọi thay đổi đã làm (đăng ký, điểm, lớp mới mở, lịch học...) sẽ bị XÓA.`n" +
    "Mật khẩu mọi tài khoản trở lại 123456.") 'Warning' 'YesNo'
if ($traLoi -ne 'Yes') { exit 0 }

$loi = Get-LoiSqlServer
# Script SQL chạy bằng sqlcmd nên không cần TCP/IP, chỉ cần dịch vụ đang chạy
if ($loi -and -not $loi.Contains('TCP/IP')) { Show-ThongBao $loi 'Warning' | Out-Null; exit 1 }

$bat = Join-Path $Script:RootDir 'database\chay_tat_ca.bat'
$p = Start-Process -FilePath 'cmd.exe' -ArgumentList ('/c ""' + $bat + '" ' + $Script:SqlcmdServer + '"') `
        -WorkingDirectory (Split-Path $bat) -Wait -PassThru
if ($p.ExitCode -eq 0) {
    Show-ThongBao ("Đã reset dữ liệu demo.`n`nNếu ứng dụng đang mở, hãy đăng nhập lại.") | Out-Null
} else {
    Show-ThongBao 'Reset chưa thành công, xem thông báo lỗi trong cửa sổ vừa chạy.' 'Error' | Out-Null
}
