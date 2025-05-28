#!/bin/bash

echo "🚀 开始构建macOS正式发布包..."

# 设置错误处理
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查Flutter环境
print_status "检查Flutter环境..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter未安装或不在PATH中"
    exit 1
fi

flutter --version
print_success "Flutter环境检查通过"

# 停止现有应用
print_status "停止现有Flutter应用..."
pkill -f "flutter.*run" || true
pkill -f "material_anticheat" || true
sleep 3

# 清理构建缓存
print_status "清理Flutter缓存..."
flutter clean
rm -rf build/
rm -rf .dart_tool/

# 重新获取依赖
print_status "获取Flutter依赖..."
flutter pub get

# 确保Python可执行文件存在并有执行权限
print_status "检查Python可执行文件..."
if [ ! -f "bundled_python/weighbridge_image_similarity" ]; then
    print_warning "过磅图片相似度检测可执行文件不存在，开始构建..."
    if [ -f "build_python_executables.sh" ]; then
        chmod +x build_python_executables.sh
        ./build_python_executables.sh
    else
        print_error "找不到构建脚本 build_python_executables.sh"
        exit 1
    fi
fi

if [ -f "bundled_python/weighbridge_image_similarity" ]; then
    chmod +x bundled_python/weighbridge_image_similarity
    print_success "过磅图片相似度检测可执行文件已准备"
else
    print_error "过磅图片相似度检测可执行文件构建失败"
    exit 1
fi

if [ -f "bundled_python/sift_similarity" ]; then
    chmod +x bundled_python/sift_similarity
    print_success "SIFT相似度检测可执行文件已准备"
else
    print_warning "SIFT相似度检测可执行文件不存在，但继续构建..."
fi

# 构建Release版本
print_status "构建macOS Release版本..."
flutter build macos --release

# 检查构建是否成功
if [ ! -d "build/macos/Build/Products/Release/material_anticheat.app" ]; then
    print_error "Flutter构建失败"
    exit 1
fi

print_success "Flutter应用构建成功"

# 创建发布目录
RELEASE_DIR="release-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RELEASE_DIR"
print_status "创建发布目录: $RELEASE_DIR"

# 复制应用到发布目录
print_status "复制应用文件..."
cp -R "build/macos/Build/Products/Release/material_anticheat.app" "$RELEASE_DIR/"

# 创建bundled_python目录并复制Python可执行文件
BUNDLE_RESOURCES="$RELEASE_DIR/material_anticheat.app/Contents/Resources"
mkdir -p "$BUNDLE_RESOURCES/bundled_python"

if [ -f "bundled_python/weighbridge_image_similarity" ]; then
    cp "bundled_python/weighbridge_image_similarity" "$BUNDLE_RESOURCES/bundled_python/"
    chmod +x "$BUNDLE_RESOURCES/bundled_python/weighbridge_image_similarity"
    print_success "已嵌入过磅图片相似度检测可执行文件"
fi

if [ -f "bundled_python/sift_similarity" ]; then
    cp "bundled_python/sift_similarity" "$BUNDLE_RESOURCES/bundled_python/"
    chmod +x "$BUNDLE_RESOURCES/bundled_python/sift_similarity"
    print_success "已嵌入SIFT相似度检测可执行文件"
fi

# 复制Python脚本作为备份
if [ -d "python_scripts" ]; then
    cp -R "python_scripts" "$BUNDLE_RESOURCES/"
    print_success "已嵌入Python脚本备份"
fi

# 创建启动脚本
print_status "创建启动脚本..."
cat > "$RELEASE_DIR/启动应用.sh" << 'EOF'
#!/bin/bash

echo "🚀 启动物资anticheat应用..."

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="$SCRIPT_DIR/material_anticheat.app"

# 检查应用是否存在
if [ ! -d "$APP_PATH" ]; then
    echo "❌ 应用不存在: $APP_PATH"
    exit 1
fi

# 设置可执行权限
chmod +x "$APP_PATH/Contents/Resources/bundled_python/"* 2>/dev/null || true

echo "✅ 启动应用..."
open "$APP_PATH"

echo "📋 应用已启动，如果遇到权限问题，请在系统偏好设置 > 安全性与隐私中允许运行"
EOF

chmod +x "$RELEASE_DIR/启动应用.sh"

# 创建使用说明
print_status "创建使用说明..."
cat > "$RELEASE_DIR/使用说明.md" << 'EOF'
# 物资anticheat macOS应用

## 安装和使用

### 方式1：直接运行
1. 双击 `material_anticheat.app` 启动应用
2. 如果系统提示"无法打开，因为它来自身份不明的开发者"：
   - 右键点击应用 > 打开
   - 在弹出的对话框中点击"打开"

### 方式2：使用启动脚本
1. 双击 `启动应用.sh`
2. 脚本会自动设置权限并启动应用

## 功能特点

✅ **完全独立**: 无需安装Python环境
✅ **图片查重**: 支持过磅图片重复检测
✅ **相似度分析**: 使用SIFT算法进行图片相似度分析
✅ **详细日志**: 每次比对都有相似率输出
✅ **智能检测**: 优先使用内置可执行文件，确保性能

## 故障排除

### 如果应用无法启动：
1. 检查系统权限设置
2. 使用终端运行：`./启动应用.sh`
3. 查看详细错误信息

### 如果图片检测失败：
1. 应用会自动尝试多种检测方式
2. 查看应用内的日志信息
3. 确保图片文件路径正确

## 技术信息

- **构建时间**: $(date)
- **Flutter版本**: $(flutter --version | head -1)
- **支持系统**: macOS 10.15+
- **架构**: 通用应用（Intel + Apple Silicon）

## 联系支持

如需技术支持，请查看应用内的帮助文档或联系开发团队。
EOF

# 创建ZIP包
print_status "创建ZIP包..."
ZIP_NAME="物资anticheat-macOS-$(date +%Y%m%d_%H%M%S).zip"
(cd "$RELEASE_DIR" && zip -r "../$ZIP_NAME" .)

# 输出信息
print_success "✅ macOS应用包构建完成！"
echo ""
echo "📁 发布文件位置:"
echo "   - 应用包目录: $RELEASE_DIR/"
echo "   - ZIP包: $ZIP_NAME"
echo ""
echo "🚀 测试方法:"
echo "   1. 进入发布目录: cd $RELEASE_DIR"
echo "   2. 启动应用: ./启动应用.sh"
echo "   或者直接双击: material_anticheat.app"
echo ""
echo "📋 应用包大小:"
du -sh "$RELEASE_DIR"
du -sh "$ZIP_NAME"
echo ""
echo "✅ 构建完成，可以开始测试了！" 