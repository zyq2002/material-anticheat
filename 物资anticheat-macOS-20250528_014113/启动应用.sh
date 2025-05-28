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
