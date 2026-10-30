# =====================================================================
#  Tạo 3 shortcut ở 2 nơi của máy đang chạy, trỏ tới thư mục project hiện tại:
#   - Desktop
#   - Thư mục gốc project (QuanLyTinChi), để mở ngay trong thư mục
#  Shortcut lưu đường dẫn tuyệt đối của máy này, nên không đưa lên GitHub (.gitignore);
#  chuyển thư mục project đi chỗ khác thì chạy lại CAI_DAT_LAN_DAU.bat.
#  Chạy lại bao nhiêu lần cũng được: shortcut cũ bị ghi đè.
# =====================================================================
. (Join-Path $PSScriptRoot 'chung.ps1')

$ErrorActionPreference = 'Stop'
$desktop = [Environment]::GetFolderPath('Desktop')    # đúng cả khi Desktop nằm trong OneDrive
$ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$shell = New-Object -ComObject WScript.Shell

function New-Shortcut([string]$thuMuc, [string]$ten, [string]$script, [string]$icon, [string]$moTa) {
    # WScript.Shell không lưu được tên file có dấu tiếng Việt -> lưu tên tạm không dấu rồi đổi tên
    $tam = Join-Path $thuMuc ('qltc_tam_' + [guid]::NewGuid().ToString('N') + '.lnk')
    $lnk = $shell.CreateShortcut($tam)
    $lnk.TargetPath = $ps
    $lnk.Arguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + (Join-Path $Script:WebDir $script) + '"'
    $lnk.WorkingDirectory = $Script:WebDir
    $lnk.IconLocation = (Join-Path $Script:WebDir ('icons\' + $icon)) + ',0'
    $lnk.Description = $moTa
    $lnk.WindowStyle = 7    # thu nhỏ: không lóe cửa sổ PowerShell trước khi script tự ẩn
    $lnk.Save()
    Move-Item -LiteralPath $tam -Destination (Join-Path $thuMuc ($ten + '.lnk')) -Force
}

$noiTao = @(
    @{ Ten = 'Desktop'; Duong = $desktop },
    @{ Ten = 'Thư mục project'; Duong = $Script:RootDir }
)
foreach ($n in $noiTao) {
    New-Shortcut $n.Duong 'Quản lý tín chỉ'      'khoi_dong.ps1'     'quanlytinchi.ico' 'Mở ứng dụng Quản lý đăng ký tín chỉ'
    New-Shortcut $n.Duong 'Dừng Quản lý tín chỉ' 'dung_app.ps1'      'dung.ico'         'Tắt ứng dụng Quản lý tín chỉ đang chạy ngầm'
    New-Shortcut $n.Duong 'Reset dữ liệu demo'   'reset_du_lieu.ps1' 'reset.ico'        'Đưa CSDL QuanLyTinChi về dữ liệu mẫu ban đầu'
    Write-Host ('  [OK] 3 bieu tuong trong ' + $n.Duong)
}
