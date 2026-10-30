@echo off
REM ============================================================
REM  Chay toan bo script CSDL theo dung thu tu
REM  Cach dung (trong cmd, dang o thu muc database):
REM     chay_tat_ca.bat                   -> server localhost
REM     chay_tat_ca.bat .\SQLEXPRESS      -> SQL Server Express
REM  Dang nhap bang Windows Authentication (-E)
REM ============================================================
chcp 65001 >nul
set SERVER=%~1
if "%SERVER%"=="" set SERVER=localhost
echo Server: %SERVER%
for %%f in (01_schema.sql 02_seed_data.sql 03_functions_views.sql 04_triggers.sql 05_procedures.sql) do (
    echo.
    echo ===== %%f =====
    sqlcmd -S %SERVER% -E -C -I -b -f 65001 -i %%f
    if errorlevel 1 (
        echo.
        echo LOI khi chay %%f - xem thong bao phia tren.
        pause
        exit /b 1
    )
)
echo.
echo ===== 07_tests.sql =====
sqlcmd -S %SERVER% -E -C -I -f 65001 -i 07_tests.sql
echo.
echo Xong. Mo SSMS, chon CSDL QuanLyTinChi de xem.
pause
