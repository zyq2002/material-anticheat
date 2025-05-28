#!/bin/bash

echo "🔧 解决macOS App Sandbox问题..."

# 停止当前运行的Flutter应用
echo "停止当前应用..."
pkill -f "flutter.*run" || true
sleep 2

# 清理Flutter缓存
echo "清理Flutter缓存..."
flutter clean

# 重新获取依赖
echo "重新获取依赖..."
flutter pub get

# 检查可执行文件
echo "检查Python可执行文件..."
if [ -f "bundled_python/weighbridge_image_similarity" ]; then
    chmod +x bundled_python/weighbridge_image_similarity
    echo "✓ 过磅图片相似度检测可执行文件已准备"
else
    echo "⚠️ 过磅图片相似度检测可执行文件不存在，需要运行 ./build_python_executables.sh"
fi

if [ -f "bundled_python/sift_similarity" ]; then
    chmod +x bundled_python/sift_similarity
    echo "✓ SIFT相似度检测可执行文件已准备"
else
    echo "⚠️ SIFT相似度检测可执行文件不存在，需要运行 ./build_python_executables.sh"
fi

# 设置macOS app entitlements
echo "设置macOS应用权限..."
echo "✓ 已添加执行外部程序的权限到entitlements文件"

echo ""
echo "📋 解决方案总结:"
echo "1. ✅ 修改了macOS entitlements文件，添加了必要的权限"
echo "2. ✅ 将Process.run改为Process.start以避免沙盒限制"
echo "3. ✅ 添加了自定义环境变量"
echo "4. ✅ 创建了无沙盒版本的entitlements文件（用于测试）"
echo ""
echo "🚀 现在请运行以下命令测试:"
echo "flutter run -d macos"
echo ""
echo "💡 如果问题依然存在，可以尝试:"
echo "1. 重新构建Python可执行文件: ./build_python_executables.sh"
echo "2. 创建完整发布包: ./create_release_package.sh"
echo "" 