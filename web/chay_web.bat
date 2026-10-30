@echo off
REM ============================================================
REM  Chay ung dung o che do LAP TRINH (profile dev): sua HTML/CSS chi can F5.
REM  Nguoi dung binh thuong: bam bieu tuong "Quan ly tin chi" tren Desktop.
REM  Can: JDK 21, SQL Server bat TCP/IP cong 1433, da co CSDL QuanLyTinChi
REM ============================================================
chcp 65001 >nul
cd /d "%~dp0"
if not defined JAVA_HOME for /f "usebackq delims=" %%j in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ". '%~dp0scripts\chung.ps1'; Find-JavaHome"`) do set "JAVA_HOME=%%j"
call "%~dp0mvnw.cmd" -q spring-boot:run
