#!/bin/bash

echo "设置 Python 环境用于图像相似度检测..."

# 检查 Python 是否已安装
if ! command -v python3 &> /dev/null; then
    echo "错误: 未找到 Python3，请先安装 Python3"
    exit 1
fi

echo "Python3 版本:"
python3 --version

# 创建 python_scripts 目录
mkdir -p python_scripts

# 安装依赖包
echo "安装 Python 依赖包..."
pip3 install -r python_scripts/requirements.txt

# 给 Python 脚本添加执行权限
chmod +x python_scripts/sift_similarity.py

echo "Python 环境设置完成！"
echo ""
echo "测试 SIFT 脚本..."

# 测试脚本是否可以正常运行
if python3 python_scripts/sift_similarity.py --help 2>/dev/null; then
    echo "SIFT 脚本测试成功！"
else
    echo "注意：SIFT 脚本可能需要两个图片路径作为参数"
fi

echo ""
echo "安装完成！现在可以使用重复图片检测功能了。" 