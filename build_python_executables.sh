#!/bin/bash

# 图片相似度检测Python脚本打包脚本
echo "🔧 开始打包Python脚本为独立可执行文件..."

# 确保在项目根目录
cd "$(dirname "$0")"

# 创建打包输出目录
mkdir -p bundled_python

echo "📦 打包过磅图片相似度脚本..."
pyinstaller --onefile \
    --distpath bundled_python \
    --workpath build/pyinstaller_work \
    --specpath build/pyinstaller_specs \
    --name weighbridge_image_similarity \
    --clean \
    python_scripts/weighbridge_image_similarity.py

echo "📦 打包SIFT相似度脚本..."
pyinstaller --onefile \
    --distpath bundled_python \
    --workpath build/pyinstaller_work \
    --specpath build/pyinstaller_specs \
    --name sift_similarity \
    --clean \
    python_scripts/sift_similarity.py

# 检查打包结果
if [ -f "bundled_python/weighbridge_image_similarity" ] && [ -f "bundled_python/sift_similarity" ]; then
    echo "✅ Python脚本打包成功！"
    echo "📁 可执行文件位置："
    echo "   - bundled_python/weighbridge_image_similarity"
    echo "   - bundled_python/sift_similarity"
    
    # 测试可执行文件
    echo "🧪 测试可执行文件..."
    echo "测试相同图片相似度（预期100%）："
    ./bundled_python/weighbridge_image_similarity \
        "./SIFTImageSimilarity-master/data/images/ironman2.jpg" \
        "./SIFTImageSimilarity-master/data/images/ironman2.jpg"
    
    echo "测试不同图片相似度（预期<100%）："
    ./bundled_python/weighbridge_image_similarity \
        "./SIFTImageSimilarity-master/data/images/ironman2.jpg" \
        "./SIFTImageSimilarity-master/data/images/ironman3.jpg"
        
    echo "🎉 所有测试完成！可执行文件可以独立运行，无需Python环境。"
else
    echo "❌ 打包失败，请检查错误信息。"
    exit 1
fi 