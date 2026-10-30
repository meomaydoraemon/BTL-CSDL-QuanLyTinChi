# =====================================================================
#  Hàm dùng chung cho các script khởi động / dừng / reset.
#  Mọi đường dẫn tính từ vị trí thư mục này, không cố định theo máy nào.
# =====================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Script:WebDir  = Split-Path -Parent $PSScriptRoot           # ...\QuanLyTinChi\web
$Script:RootDir = Split-Path -Parent $Script:WebDir          # ...\QuanLyTinChi
$Script:JarFile = Join-Path $Script:WebDir 'target\quanlytinchi-web.jar'
$Script:PidFile = Join-Path $Script:WebDir 'logs\app.pid'
$Script:LogFile = Join-Path $Script:WebDir 'logs\app.log'
$Script:TieuDe  = 'Quản lý tín chỉ'

# Đọc cấu hình SQL Server giống ứng dụng Java: mặc định trong src\main\resources\application.properties,
# ghi đè bởi web\config\application.properties (file riêng của từng máy, không đưa lên git)
function Read-CauHinh {
    $kq = @{}
    foreach ($f in @((Join-Path $Script:WebDir 'src\main\resources\application.properties'),
                     (Join-Path $Script:WebDir 'config\application.properties'))) {
        if (-not (Test-Path $f)) { continue }
        foreach ($dong in Get-Content $f -Encoding UTF8) {
            if ($dong -match '^\s*([\w.\-]+)\s*=\s*(.*?)\s*$') { $kq[$Matches[1]] = $Matches[2] }
        }
    }
    return $kq
}
$Script:CauHinh  = Read-CauHinh
$Script:DbServer = if ($Script:CauHinh['qltc.db.server']) { $Script:CauHinh['qltc.db.server'] } else { 'localhost' }
$Script:DbPort   = if ($Script:CauHinh['qltc.db.port']) { [int]$Script:CauHinh['qltc.db.port'] } else { 1433 }
$Script:Instance = if ($Script:CauHinh['qltc.sql.instance']) { $Script:CauHinh['qltc.sql.instance'] } else { 'SQLEXPRESS' }
$Script:LaMayNay = $Script:DbServer -in @('localhost', '127.0.0.1', '.', $env:COMPUTERNAME)
$Script:LaBanMacDinh = $Script:Instance -eq 'MSSQLSERVER'
$Script:SqlService = if ($Script:LaBanMacDinh) { 'MSSQLSERVER' } else { 'MSSQL$' + $Script:Instance }
$Script:TenDichVu  = 'SQL Server (' + $Script:Instance + ')'
# Tham số -S cho sqlcmd: trên máy này dùng .\instance (không cần TCP/IP), máy khác dùng server,cổng
$Script:SqlcmdServer = if (-not $Script:LaMayNay) { $Script:DbServer + ',' + $Script:DbPort }
                       elseif ($Script:LaBanMacDinh) { '.' } else { '.\' + $Script:Instance }

function Show-ThongBao([string]$noiDung, [string]$loai = 'Information', [string]$nut = 'OK') {
    return [System.Windows.Forms.MessageBox]::Show($noiDung, $Script:TieuDe,
        [System.Windows.Forms.MessageBoxButtons]::$nut, [System.Windows.Forms.MessageBoxIcon]::$loai)
}

# Thông báo ngắn tự đóng sau vài giây (dùng cho thông tin, không phải lỗi)
function Show-ThongBaoNhanh([string]$noiDung, [int]$giay = 4) {
    (New-Object -ComObject WScript.Shell).Popup($noiDung, $giay, $Script:TieuDe, 64) | Out-Null
}

# Thử mở kết nối TCP tới máy:cổng trong thời gian ngắn
function Test-Cong([int]$cong, [int]$msCho = 400, [string]$may = '127.0.0.1') {
    if ($may -eq 'localhost' -or $may -eq '.') { $may = '127.0.0.1' }
    $c = New-Object System.Net.Sockets.TcpClient
    try {
        $kq = $c.BeginConnect($may, $cong, $null, $null)
        return ($kq.AsyncWaitHandle.WaitOne($msCho) -and $c.Connected)
    } catch { return $false } finally { $c.Close() }
}

# Kiểm tra SQL Server: dịch vụ đang chạy và cổng TCP mở (theo cấu hình qltc.*).
# Trả về $null nếu ổn, ngược lại trả về câu hướng dẫn tiếng Việt. Không tự đổi cấu hình.
function Get-LoiSqlServer {
    $sua = "`n`nMáy bạn dùng instance hoặc cổng khác? Sửa trong web\config\application.properties (xem file .example cùng thư mục)."
    if ($Script:LaMayNay) {
        $svc = Get-Service -Name $Script:SqlService -ErrorAction SilentlyContinue
        if (-not $svc) {
            return "Không tìm thấy dịch vụ " + $Script:TenDichVu + " trên máy này.`n`n" +
                   "Hãy cài SQL Server Express 2017 trở lên với tên instance SQLEXPRESS." + $sua
        }
        if ($svc.Status -ne 'Running') {
            return "Dịch vụ " + $Script:TenDichVu + " đang TẮT.`n`nCách bật:`n" +
                   "1. Nhấn Windows + R, gõ services.msc rồi Enter.`n" +
                   "2. Tìm dòng '" + $Script:TenDichVu + "', bấm chuột phải → Start.`n" +
                   "3. (Nên) chuột phải → Properties → Startup type: Automatic để lần sau tự bật.`n`n" +
                   "Sau đó bấm lại biểu tượng Quản lý tín chỉ."
        }
    }
    if (-not (Test-Cong $Script:DbPort 1500 $Script:DbServer)) {
        return $Script:TenDichVu + " chưa nhận kết nối TCP ở " + $Script:DbServer + ":" + $Script:DbPort +
               " nên ứng dụng không kết nối được.`n`nCách bật TCP/IP:`n" +
               "1. Mở SQL Server Configuration Manager.`n" +
               "2. SQL Server Network Configuration → Protocols for " + $Script:Instance + " → TCP/IP → Enable.`n" +
               "3. Chuột phải TCP/IP → Properties → tab IP Addresses → mục IPAll: xóa TCP Dynamic Ports, đặt TCP Port = " + $Script:DbPort + ".`n" +
               "4. SQL Server Services → chuột phải " + $Script:TenDichVu + " → Restart." + $sua
    }
    return $null
}

# CSDL QuanLyTinChi đã được tạo chưa (đăng nhập Windows Authentication)
function Test-CoCsdl {
    $cn = New-Object System.Data.SqlClient.SqlConnection ('Server=' + $Script:DbServer + ',' + $Script:DbPort + ';Database=master;Integrated Security=true;Connect Timeout=5')
    try {
        $cn.Open()
        $cmd = $cn.CreateCommand()
        $cmd.CommandText = "SELECT DB_ID(N'QuanLyTinChi')"
        return -not ($cmd.ExecuteScalar() -is [System.DBNull])
    } catch { return $true }   # không kiểm tra được (vd. dùng tài khoản SQL) thì để ứng dụng tự báo lỗi
    finally { $cn.Close() }
}

# Tìm thư mục JDK/JRE 21 trở lên: JAVA_HOME, PATH, thư mục .jdks của IntelliJ, các nơi cài phổ biến
function Find-JavaHome {
    $ungVien = New-Object System.Collections.Generic.List[string]
    if ($env:JAVA_HOME) { $ungVien.Add($env:JAVA_HOME) }
    $trenPath = Get-Command java.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($trenPath) { $ungVien.Add((Split-Path -Parent (Split-Path -Parent $trenPath.Source))) }
    $goc = @("$env:USERPROFILE\.jdks", "$env:ProgramFiles\Eclipse Adoptium", "$env:ProgramFiles\Java",
             "$env:ProgramFiles\Microsoft", "$env:ProgramFiles\Zulu", "$env:ProgramFiles\Amazon Corretto",
             "$env:ProgramFiles\BellSoft", "$env:LOCALAPPDATA\Programs\Eclipse Adoptium")
    foreach ($g in $goc) {
        if (Test-Path $g) {
            Get-ChildItem $g -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending |
                ForEach-Object { $ungVien.Add($_.FullName) }
        }
    }
    # ($home là biến có sẵn của PowerShell nên dùng tên $jh)
    foreach ($jh in $ungVien) {
        $java = Join-Path $jh 'bin\java.exe'
        if (-not (Test-Path $java)) { continue }
        $rel = Join-Path $jh 'release'
        $ban = if (Test-Path $rel) { (Select-String -Path $rel -Pattern '^JAVA_VERSION="(\d+)' | Select-Object -First 1).Matches.Groups[1].Value } else { $null }
        if ($ban -and [int]$ban -ge 21) { return $jh }
    }
    return $null
}

# Tiến trình ứng dụng đang chạy (theo PID đã lưu, hoặc tìm javaw chạy đúng file .jar)
function Get-TienTrinhApp {
    if (Test-Path $Script:PidFile) {
        $id = Get-Content $Script:PidFile -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($id) {
            $p = Get-Process -Id $id -ErrorAction SilentlyContinue
            if ($p -and $p.ProcessName -match '^javaw?$') { return $p }
        }
    }
    $ds = Get-CimInstance Win32_Process -Filter "Name='javaw.exe' OR Name='java.exe'" -ErrorAction SilentlyContinue |
          Where-Object { $_.CommandLine -like '*quanlytinchi-web.jar*' }
    if ($ds) { return Get-Process -Id ($ds | Select-Object -First 1).ProcessId -ErrorAction SilentlyContinue }
    return $null
}

# Cửa sổ nhỏ "Đang khởi động..." để người dùng biết đang chạy (app cần 10-20 giây)
function New-CuaSoCho([string]$noiDung) {
    $f = New-Object System.Windows.Forms.Form
    $f.FormBorderStyle = 'None'; $f.StartPosition = 'CenterScreen'; $f.TopMost = $true
    $f.Size = New-Object System.Drawing.Size 380, 110; $f.BackColor = [System.Drawing.ColorTranslator]::FromHtml('#C8102E')
    $f.ShowInTaskbar = $true; $f.Text = $Script:TieuDe
    $icon = Join-Path $Script:WebDir 'icons\quanlytinchi.ico'
    if (Test-Path $icon) { $f.Icon = New-Object System.Drawing.Icon $icon }
    $l = New-Object System.Windows.Forms.Label
    $l.Dock = 'Fill'; $l.TextAlign = 'MiddleCenter'; $l.ForeColor = 'White'
    $l.Font = New-Object System.Drawing.Font 'Segoe UI', 11
    $l.Text = $noiDung
    $f.Controls.Add($l)
    $f.Show(); [System.Windows.Forms.Application]::DoEvents()
    return $f
}
