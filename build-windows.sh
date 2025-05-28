#!/bin/bash

echo "🚀 开始构建 Flutter Windows 应用..."

# 检查是否安装了 Docker
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: 请先安装 Docker Desktop"
    echo "下载地址: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# 检查 Docker 是否运行
if ! docker info &> /dev/null; then
    echo "❌ 错误: Docker 未运行，请启动 Docker Desktop"
    exit 1
fi

# 创建输出目录
mkdir -p windows-build

echo "📦 构建 Docker 镜像..."
docker build -f Dockerfile.windows -t flutter-windows-builder .

echo "🔨 构建 Windows 应用..."
docker run --rm -v "$(pwd)/windows-build:/output" flutter-windows-builder

if [ -d "windows-build" ] && [ "$(ls -A windows-build)" ]; then
    echo "✅ 构建成功！"
    echo "📁 应用文件位于: $(pwd)/windows-build/"
    echo "🎯 主要文件:"
    ls -la windows-build/
    
    # 创建 ZIP 包
    echo "📦 创建压缩包..."
    cd windows-build
    zip -r ../物资anticheat-windows.zip ./*
    cd ..
    echo "✅ 压缩包已创建: 物资anticheat-windows.zip"
else
    echo "❌ 构建失败，请检查错误信息"
    exit 1
fi

echo "🎉 构建完成！" 