@echo off
chcp 65001 >nul
echo.
echo 🚀 准备上传物资anticheat到GitHub...
echo.

REM 检查是否在Git仓库中
if not exist ".git" (
    echo ❌ 当前目录不是Git仓库
    echo 请先运行: git init
    pause
    exit /b 1
)

REM 添加所有文件
echo 📁 添加文件到Git...
git add .

REM 提交
echo 💾 提交更改...
git commit -m "🎉 物资anticheat Windows构建优化

✨ 新增功能:
- 优化GitHub Actions Windows构建流程
- 添加便携版构建
- 增加版本信息生成
- 改进错误处理和调试信息
- 支持自动Release创建

🔧 技术改进:
- 添加Flutter缓存加速构建
- 集成代码分析和测试
- 优化构建产物打包
- 增加详细的构建日志

📝 文档更新:
- 完善Windows发布说明
- 添加使用指南和故障排除
- 创建简化README文件"

REM 检查远程仓库
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo.
    echo ⚠️  尚未设置远程仓库
    echo 请先设置GitHub仓库地址:
    echo git remote add origin https://github.com/用户名/仓库名.git
    echo.
    echo 或者如果已有仓库:
    echo git remote set-url origin https://github.com/用户名/仓库名.git
    echo.
    pause
    exit /b 1
)

REM 推送到GitHub
echo 📤 推送到GitHub...
git push -u origin main
if errorlevel 1 (
    echo 尝试推送到master分支...
    git push -u origin master
)

echo.
echo ✅ 上传完成!
echo.
echo 🎯 接下来可以:
echo 1. 访问GitHub仓库查看Actions构建状态
echo 2. 创建标签触发Release: git tag v1.0.0 && git push origin v1.0.0
echo 3. 或者在GitHub网站上手动触发workflow
echo.
echo 📋 GitHub Actions 会自动:
echo - 构建Windows应用
echo - 创建标准版和便携版
echo - 运行代码分析和测试
echo - 上传构建产物
echo - (可选) 创建Release
echo.
pause 