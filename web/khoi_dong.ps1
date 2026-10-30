# =====================================================================
#  Khởi động ứng dụng Quản lý tín chỉ (shortcut "Quản lý tín chỉ" trên Desktop)
#  - App đang chạy: chỉ mở trình duyệt, không chạy thêm bản nữa
#  - Chưa chạy: kiểm tra SQL Server, chạy file .jar ẩn (javaw), chờ cổng 8080 rồi mở trình duyệt
#  - KHÔNG reset CSDL: dữ liệu được giữ nguyên giữa các lần mở
# =====================================================================
. (Join-Path $PSScriptRoot 'scripts\chung.ps1')

$Url = 'http://localhost:8080'

function Wait-SanSang($tienTrinh) {
    $cho = New-CuaSoCho "Đang khởi động Quản lý tín chỉ...`nTrình duyệt sẽ tự mở khi sẵn sàng."
    try {
        $hetHan = (Get-Date).AddSeconds(120)
        while ((Get-Date) -lt $hetHan) {
            if (Test-Cong 8080) { return $true }
            if ($tienTrinh -and $tienTrinh.HasExited) { return $false }
            for ($i = 0; $i -lt 5; $i++) { Start-Sleep -Milliseconds 100; [System.Windows.Forms.Application]::DoEvents() }
        }
        return $false
    } finally { $cho.Close() }
}

function Show-LoiKhoiDong {
    $cuoiLog = if (Test-Path $Script:LogFile) {
        (Get-Content $Script:LogFile -Tail 400 -Encoding UTF8 | Where-Object { $_ -match 'ERROR|Exception|Caused by' } | Select-Object -Last 4) -join "`n"
    } else { '' }
    Show-ThongBao ("Ứng dụng không khởi động được.`n`n" + $cuoiLog + "`n`nXem chi tiết trong: " + $Script:LogFile) 'Error' | Out-Null
}

# 1. App đã chạy và sẵn sàng -> chỉ mở trình duyệt
if (Test-Cong 8080) { Start-Process $Url; exit 0 }

# 2. App đang trong lúc khởi động (người dùng bấm 2 lần liên tiếp) -> chờ, không chạy thêm
$dangChay = Get-TienTrinhApp
if ($dangChay) {
    if (Wait-SanSang $dangChay) { Start-Process $Url } else { Show-LoiKhoiDong }
    exit 0
}

# 3. Kiểm tra SQL Server và CSDL
$loi = Get-LoiSqlServer
if ($loi) { Show-ThongBao $loi 'Warning' | Out-Null; exit 1 }
if (-not (Test-CoCsdl)) {
    Show-ThongBao ("Máy này chưa có CSDL QuanLyTinChi.`n`n" +
        "Bấm biểu tượng 'Reset dữ liệu demo' trên Desktop để tạo CSDL và dữ liệu mẫu, sau đó mở lại.") 'Warning' | Out-Null
    exit 1
}

# 4. File .jar và Java
# DLL đăng nhập Windows được Maven tự tải vào web\lib lúc build (không có trong git)
if (-not (Test-Path $Script:JarFile) -or -not (Test-Path (Join-Path $Script:WebDir 'lib\mssql-jdbc_auth-*.dll'))) {
    Show-ThongBao ("Chưa có file ứng dụng:`n" + $Script:JarFile + "`n`n" +
        "Hãy chạy CAI_DAT_LAN_DAU.bat trong thư mục " + $Script:RootDir + " để build.") 'Warning' | Out-Null
    exit 1
}
$javaHome = Find-JavaHome
if (-not $javaHome) {
    Show-ThongBao ("Không tìm thấy Java 21 trở lên trên máy này.`n`n" +
        "Hãy cài JDK 21 (ví dụ Eclipse Temurin 21 tại adoptium.net), rồi mở lại.") 'Warning' | Out-Null
    exit 1
}

# 5. Chạy ẩn bằng javaw.exe (không có cửa sổ cmd), lưu PID để nút Dừng tìm được
New-Item -ItemType Directory -Force (Split-Path $Script:PidFile) | Out-Null
$javaw = Join-Path $javaHome 'bin\javaw.exe'
$thamSo = '-Dfile.encoding=UTF-8 "-Djava.library.path=' + (Join-Path $Script:WebDir 'lib') + '" -jar "' + $Script:JarFile + '"'
$p = Start-Process -FilePath $javaw -ArgumentList $thamSo -WorkingDirectory $Script:WebDir -WindowStyle Hidden -PassThru
Set-Content -Path $Script:PidFile -Value $p.Id

# 6. Chờ cổng 8080 rồi mở trình duyệt mặc định
if (Wait-SanSang $p) {
    Start-Process $Url
} else {
    if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
    Remove-Item $Script:PidFile -ErrorAction SilentlyContinue
    Show-LoiKhoiDong
    exit 1
}
