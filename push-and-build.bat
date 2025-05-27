@echo off
chcp 65001 >nul
echo ==========================================
echo 物资anticheat GitHub 推送和构建脚本
echo ==========================================

REM 替换下面的URL为你的GitHub仓库地址
set REPO_URL=https://github.com/你的用户名/物资anticheat.git

echo 请先将脚本中的 REPO_URL 替换为你的实际GitHub仓库地址
echo 然后运行此脚本
echo.

set /p confirm=确认已替换仓库地址并继续推送? (y/N): 
if /i not "%confirm%"=="y" (
    echo 已取消推送
    pause
    exit /b
)

echo.
echo 1. 添加远程仓库...
git remote add origin "%REPO_URL%"

echo.
echo 2. 验证远程仓库...
git remote -v

echo.
echo 3. 推送代码到远程仓库...
git push -u origin main

if %ERRORLEVEL% neq 0 (
    echo 推送失败！请检查：
    echo 1. 网络连接
    echo 2. GitHub仓库地址是否正确
    echo 3. 是否有推送权限
    pause
    exit /b 1
)

echo.
echo 4. 推送完成!
echo.
echo ==========================================
echo 构建状态查看说明：
echo ==========================================
echo 1. 访问你的GitHub仓库
echo 2. 点击 'Actions' 标签页
echo 3. 查看 'Build Windows Only' 工作流
echo 4. 等待构建完成（大约5-10分钟）
echo 5. 下载构建产物 'windows-build-only'
echo.
echo 构建产物将包含:
echo - 物资anticheat-windows-x64.zip
echo - 解压后即可直接运行
echo ==========================================
echo.
echo 提示：构建过程中如果遇到问题，请检查GitHub Actions日志
pause 