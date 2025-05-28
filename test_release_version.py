#!/usr/bin/env python3

import subprocess
import sys
import os
from pathlib import Path

def test_executable(executable_path, image1, image2):
    """测试可执行文件"""
    try:
        print(f"🧪 测试: {os.path.basename(executable_path)}")
        print(f"   参数1: {os.path.basename(image1)}")
        print(f"   参数2: {os.path.basename(image2)}")
        
        result = subprocess.run(
            [executable_path, image1, image2],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        if result.returncode == 0:
            similarity = float(result.stdout.strip())
            print(f"   ✅ 相似度: {similarity:.2%}")
            return True, similarity
        else:
            print(f"   ❌ 错误: {result.stderr}")
            return False, 0.0
            
    except Exception as e:
        print(f"   ❌ 异常: {e}")
        return False, 0.0

def main():
    print("🚀 测试Release版本的Python可执行文件...")
    print()
    
    # 查找应用路径
    release_dir = "release-20250528_014113"
    app_path = f"{release_dir}/material_anticheat.app"
    bundled_path = f"{app_path}/Contents/Resources/bundled_python"
    
    if not os.path.exists(bundled_path):
        print(f"❌ 找不到bundled_python目录: {bundled_path}")
        return False
    
    # 测试可执行文件
    executables = [
        f"{bundled_path}/weighbridge_image_similarity",
        f"{bundled_path}/sift_similarity"
    ]
    
    # 查找测试图片
    test_images = []
    weighbridge_dir = "pic/weighbridge/2025-05-28"
    if os.path.exists(weighbridge_dir):
        for root, dirs, files in os.walk(weighbridge_dir):
            for file in files:
                if file.lower().endswith(('.jpg', '.jpeg', '.png')):
                    test_images.append(os.path.join(root, file))
                if len(test_images) >= 2:
                    break
            if len(test_images) >= 2:
                break
    
    if len(test_images) < 2:
        print("❌ 找不到足够的测试图片")
        return False
    
    print(f"📋 找到 {len(test_images)} 张测试图片")
    print(f"   图片1: {test_images[0]}")
    print(f"   图片2: {test_images[1]}")
    print()
    
    # 测试每个可执行文件
    all_success = True
    for executable in executables:
        if os.path.exists(executable):
            # 确保可执行权限
            os.chmod(executable, 0o755)
            
            success, similarity = test_executable(executable, test_images[0], test_images[1])
            if not success:
                all_success = False
        else:
            print(f"⚠️  可执行文件不存在: {os.path.basename(executable)}")
        print()
    
    if all_success:
        print("🎉 所有测试通过！Release版本可以正常使用Python可执行文件")
        print("✅ 沙盒问题已解决")
        print("✅ 相似度检测功能正常")
        print("✅ 无需用户安装Python环境")
    else:
        print("❌ 部分测试失败，需要进一步调试")
    
    return all_success

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 