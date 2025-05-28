#!/bin/bash

echo "🚀 创建 macOS 应用分发包..."

# 检查构建文件是否存在
if [ ! -d "build/macos/Build/Products/Release/material_anticheat.app" ]; then
    echo "❌ 错误: 应用未构建，请先运行 flutter build macos --release"
    exit 1
fi

# 创建分发目录
rm -rf "物资anticheat-macOS"
mkdir -p "物资anticheat-macOS"

# 复制应用文件
echo "📦 复制应用文件..."
cp -R "build/macos/Build/Products/Release/material_anticheat.app" "物资anticheat-macOS/"

# 创建安装说明
cat > "物资anticheat-macOS/安装说明.txt" << EOF
物资防作弊系统 - macOS版本

安装说明：
1. 将 material_anticheat.app 拖拽到 Applications（应用程序）文件夹
2. 双击运行应用

如果遇到"无法打开，因为无法验证开发者"的提示：
1. 右键点击应用，选择"打开"
2. 在弹出的对话框中点击"打开"
3. 或者在系统偏好设置 > 安全性与隐私 > 通用 中允许运行

如果遇到权限问题：
1. 打开终端（Terminal）
2. 运行以下命令去除隔离属性：
   xattr -cr /Applications/material_anticheat.app

系统要求：
- macOS 10.15 或更高版本
- 支持 Apple Silicon (M1/M2/M3) 和 Intel 处理器

技术支持：
如有问题请联系开发团队
EOF

# 创建 DMG 镜像文件（如果安装了 create-dmg）
if command -v create-dmg &> /dev/null; then
    echo "📦 创建 DMG 镜像文件..."
    create-dmg \
        --volname "物资防作弊系统" \
        --window-pos 200 120 \
        --window-size 800 600 \
        --icon-size 100 \
        --app-drop-link 600 185 \
        "物资anticheat-macOS.dmg" \
        "物资anticheat-macOS/"
    
    if [ $? -eq 0 ]; then
        echo "✅ DMG 文件创建成功: 物资anticheat-macOS.dmg"
    else
        echo "⚠️  DMG 创建失败，使用 ZIP 压缩包代替"
    fi
fi

# 创建 ZIP 压缩包
echo "📦 创建 ZIP 压缩包..."
zip -r "物资anticheat-macOS.zip" "物资anticheat-macOS/"

# 显示应用信息
echo "📊 应用信息:"
ls -lh "物资anticheat-macOS/material_anticheat.app"
echo ""

# 显示分发文件
echo "✅ 构建完成！"
echo ""
echo "📁 分发文件："
echo "   📂 物资anticheat-macOS/ - 应用文件夹"
echo "   📦 物资anticheat-macOS.zip - 压缩包"
if [ -f "物资anticheat-macOS.dmg" ]; then
    echo "   💿 物资anticheat-macOS.dmg - 安装镜像"
fi
echo ""

echo "🎯 分发说明："
echo "1. 发送 ZIP 文件给用户，用户解压后将 .app 文件拖到应用程序文件夹"
echo "2. 或发送 DMG 文件（如果已创建），用户双击挂载后拖拽安装"
echo "3. 首次运行可能需要在安全设置中允许运行未签名应用"
echo ""

# 测试应用是否可以运行
echo "🧪 测试应用启动..."
if open "物资anticheat-macOS/material_anticheat.app" --args --test 2>/dev/null; then
    echo "✅ 应用可以正常启动"
else
    echo "⚠️  应用启动测试失败，请检查依赖"
fi

echo "🎉 打包完成！" 