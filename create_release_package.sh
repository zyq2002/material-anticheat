#!/bin/bash

# 物资anticheat应用发布包创建脚本
echo "🚀 开始创建发布包..."

# 确保在项目根目录
cd "$(dirname "$0")"

# 设置版本信息
VERSION=$(date +"%Y%m%d_%H%M%S")
PACKAGE_NAME="物资anticheat_v${VERSION}"

echo "📦 版本: $VERSION"
echo "📁 包名: $PACKAGE_NAME"

# 1. 打包Python可执行文件
echo "🔧 步骤1: 打包Python脚本..."
if [ ! -f "bundled_python/weighbridge_image_similarity" ] || [ ! -f "bundled_python/sift_similarity" ]; then
    echo "   正在打包Python脚本..."
    ./build_python_executables.sh
    if [ $? -ne 0 ]; then
        echo "❌ Python脚本打包失败"
        exit 1
    fi
else
    echo "   ✅ Python可执行文件已存在"
fi

# 2. 构建Flutter应用
echo "🔧 步骤2: 构建Flutter应用..."
echo "   正在清理..."
flutter clean

echo "   正在获取依赖..."
flutter pub get

echo "   正在构建macOS应用..."
flutter build macos --release

if [ ! -d "build/macos/Build/Products/Release/material_anticheat.app" ]; then
    echo "❌ Flutter应用构建失败"
    exit 1
fi

# 3. 创建发布包目录
echo "🔧 步骤3: 创建发布包..."
RELEASE_DIR="releases/$PACKAGE_NAME"
mkdir -p "$RELEASE_DIR"

# 4. 复制应用文件
echo "   复制应用文件..."
cp -R "build/macos/Build/Products/Release/material_anticheat.app" "$RELEASE_DIR/"

# 5. 复制Python可执行文件到应用内部
echo "   复制Python可执行文件..."
mkdir -p "$RELEASE_DIR/material_anticheat.app/Contents/Resources/bundled_python"
cp bundled_python/weighbridge_image_similarity "$RELEASE_DIR/material_anticheat.app/Contents/Resources/bundled_python/"
cp bundled_python/sift_similarity "$RELEASE_DIR/material_anticheat.app/Contents/Resources/bundled_python/"

# 6. 复制Python脚本（备用）
echo "   复制Python脚本（备用）..."
mkdir -p "$RELEASE_DIR/material_anticheat.app/Contents/Resources/python_scripts"
cp python_scripts/*.py "$RELEASE_DIR/material_anticheat.app/Contents/Resources/python_scripts/"

# 7. 复制文档
echo "   复制文档文件..."
cp README.md "$RELEASE_DIR/"
cp BUILD_INSTRUCTIONS.md "$RELEASE_DIR/"
cp RELEASE_SUMMARY.md "$RELEASE_DIR/"
cp 图片查重功能测试报告.md "$RELEASE_DIR/"

# 8. 创建启动脚本
echo "   创建启动脚本..."
cat > "$RELEASE_DIR/启动应用.command" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
open material_anticheat.app
EOF
chmod +x "$RELEASE_DIR/启动应用.command"

# 9. 创建安装说明
echo "   创建安装说明..."
cat > "$RELEASE_DIR/安装说明.txt" << 'EOF'
物资anticheat 安装说明
=====================

本应用已包含所有必要的组件，无需额外安装Python环境。

安装步骤：
1. 将整个文件夹复制到您想要的位置
2. 双击"启动应用.command"或直接双击"material_anticheat.app"启动应用

功能特性：
✅ 图片查重功能（内置独立可执行文件）
✅ 过磅数据采集
✅ 重复检测
✅ 可疑图片识别
✅ 完整日志系统

如果遇到问题：
- 确保应用文件夹完整
- 检查系统安全设置是否允许运行第三方应用
- 查看应用内的日志信息

技术支持：
- 查看README.md了解详细使用说明
- 查看图片查重功能测试报告.md了解功能详情
EOF

# 10. 创建压缩包
echo "🔧 步骤4: 创建压缩包..."
cd releases
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" > /dev/null 2>&1
cd ..

# 11. 生成发布信息
echo "   生成发布信息..."
cat > "releases/${PACKAGE_NAME}/发布信息.txt" << EOF
发布信息
========

版本: $VERSION
构建时间: $(date)
平台: macOS (arm64/x64)

包含组件:
- Flutter应用 (material_anticheat.app)
- Python图片处理可执行文件 (无需Python环境)
- 完整文档和说明

文件大小:
- 应用包: $(du -sh "$RELEASE_DIR" | cut -f1)
- 压缩包: $(du -sh "releases/${PACKAGE_NAME}.zip" | cut -f1)

安装要求:
- macOS 10.14 或更高版本
- 约 150MB 磁盘空间

特性:
✅ 独立运行，无需Python环境
✅ 完整的图片查重功能
✅ 详细的相似率日志输出
✅ 用户友好的界面
EOF

# 12. 完成
echo ""
echo "🎉 发布包创建完成！"
echo ""
echo "📁 发布目录: releases/$PACKAGE_NAME"
echo "📦 压缩包: releases/${PACKAGE_NAME}.zip"
echo "📊 包大小: $(du -sh "releases/${PACKAGE_NAME}" | cut -f1)"
echo "🗜️  压缩包大小: $(du -sh "releases/${PACKAGE_NAME}.zip" | cut -f1)"
echo ""
echo "✅ 可以直接发布给用户使用，无需安装Python环境！"
echo ""
echo "🔧 发布包包含："
echo "   - macOS应用程序"
echo "   - 内置Python图片处理可执行文件"
echo "   - 完整文档和安装说明"
echo "   - 一键启动脚本" 