# =====================================================================
#  Dừng ứng dụng Quản lý tín chỉ đang chạy ngầm (shortcut "Dừng Quản lý tín chỉ")
# =====================================================================
. (Join-Path $PSScriptRoot 'scripts\chung.ps1')

$p = Get-TienTrinhApp
if (-not $p) {
    Remove-Item $Script:PidFile -ErrorAction SilentlyContinue
    Show-ThongBaoNhanh 'Ứng dụng Quản lý tín chỉ hiện không chạy.'
    exit 0
}

Stop-Process -Id $p.Id -Force
$p.WaitForExit(10000) | Out-Null
Remove-Item $Script:PidFile -ErrorAction SilentlyContinue
Show-ThongBaoNhanh 'Đã dừng ứng dụng Quản lý tín chỉ.'
