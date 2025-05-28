@echo off
echo 🚀 创建Windows应用分发包...

REM 创建分发目录
if exist "物资anticheat-Windows" rmdir /s /q "物资anticheat-Windows"
mkdir "物资anticheat-Windows"

REM 复制应用文件
xcopy "build\windows\x64\runner\Release\*" "物资anticheat-Windows\" /E /I /Y

REM 创建启动说明
echo 物资防作弊系统 - Windows版本 > "物资anticheat-Windows\README.txt"
echo. >> "物资anticheat-Windows\README.txt"
echo 运行方法：双击 material_anticheat.exe >> "物资anticheat-Windows\README.txt"
echo. >> "物资anticheat-Windows\README.txt"
echo 如果无法运行，请安装 Microsoft Visual C++ Redistributable >> "物资anticheat-Windows\README.txt"
echo 下载地址：https://aka.ms/vs/17/release/vc_redist.x64.exe >> "物资anticheat-Windows\README.txt"

REM 创建ZIP包
powershell Compress-Archive -Path "物资anticheat-Windows\*" -DestinationPath "物资anticheat-Windows.zip" -Force

echo ✅ 打包完成！
echo 📁 应用文件位于: 物资anticheat-Windows\ 目录
echo 📦 压缩包: 物资anticheat-Windows.zip
echo.
echo 🎯 分发说明：
echo 1. 将整个 物资anticheat-Windows 文件夹分发给用户
echo 2. 或者分发 物资anticheat-Windows.zip 压缩包
echo 3. 用户解压后双击 material_anticheat.exe 即可运行
echo.
pause 