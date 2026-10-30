@echo off
REM ====================================================================
REM  CAI DAT LAN DAU - chay 1 lan tren moi may sau khi tai project ve
REM   1. Tim JDK 21 tren may
REM   2. Build ung dung web thanh file web\target\quanlytinchi-web.jar
REM      (Maven Wrapper tu tai Maven, khong can cai Maven)
REM   3. Tao 3 shortcut tren Desktop, tro toi dung thu muc hien tai cua may nay
REM  Chay lai bat cu luc nao (vd. sau khi git pull) de build lai va cap nhat shortcut.
REM ====================================================================
chcp 65001 >nul
setlocal
set "ROOT=%~dp0"
set "WEB=%ROOT%web"

echo.
echo ===== [1/3] Tim Java 21 =====
for /f "usebackq delims=" %%j in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ". '%WEB%\scripts\chung.ps1'; Find-JavaHome"`) do set "JAVA_HOME=%%j"
if not defined JAVA_HOME goto :khongJava
if not exist "%JAVA_HOME%\bin\javac.exe" goto :khongJava
echo   JAVA_HOME = %JAVA_HOME%

echo.
echo ===== [2/3] Build ung dung (lan dau mat vai phut de tai thu vien) =====
call "%WEB%\mvnw.cmd" -q -B -DskipTests -f "%WEB%\pom.xml" package
if errorlevel 1 goto :loiBuild
if not exist "%WEB%\target\quanlytinchi-web.jar" goto :loiBuild
echo   [OK] web\target\quanlytinchi-web.jar

echo.
echo ===== [3/3] Tao shortcut tren Desktop va trong thu muc nay =====
powershell -NoProfile -ExecutionPolicy Bypass -File "%WEB%\scripts\tao_shortcut.ps1"
if errorlevel 1 goto :loiShortcut

echo.
echo ====================================================================
echo  XONG. Tren Desktop VA trong thu muc QuanLyTinChi co 3 bieu tuong:
echo    - Quan ly tin chi       : mo ung dung (chay ngam, tu mo trinh duyet)
echo    - Dung Quan ly tin chi  : tat ung dung
echo    - Reset du lieu demo    : tao lai CSDL va du lieu mau
echo.
echo  May moi chua co CSDL? Bam "Reset du lieu demo" truoc, roi mo ung dung.
echo  Can: SQL Server Express (instance SQLEXPRESS) bat TCP/IP cong 1433.
echo ====================================================================
pause
exit /b 0

:khongJava
echo.
echo  [LOI] Khong tim thay JDK 21 tro len.
echo  Hay cai JDK 21 (vd. Eclipse Temurin 21 tai https://adoptium.net) roi chay lai file nay.
pause
exit /b 1

:loiBuild
echo.
echo  [LOI] Build that bai - xem thong bao phia tren (can Internet o lan build dau).
pause
exit /b 1

:loiShortcut
echo.
echo  [LOI] Khong tao duoc shortcut tren Desktop.
pause
exit /b 1
