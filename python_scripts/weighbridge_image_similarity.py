#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
过磅图片相似度检测脚本
用于检测两张过磅图片之间的相似度
"""

import sys
import os
import cv2
import numpy as np
from pathlib import Path

def calculate_similarity(image1_path, image2_path):
    """
    计算两张图片的相似度
    
    Args:
        image1_path: 第一张图片路径
        image2_path: 第二张图片路径
        
    Returns:
        float: 相似度分数 (0.0 - 1.0)
    """
    try:
        # 检查文件是否存在
        if not os.path.exists(image1_path):
            print(f"错误: 图片不存在 - {image1_path}", file=sys.stderr)
            return 0.0
            
        if not os.path.exists(image2_path):
            print(f"错误: 图片不存在 - {image2_path}", file=sys.stderr)
            return 0.0
        
        # 读取图片
        img1 = cv2.imread(image1_path)
        img2 = cv2.imread(image2_path)
        
        if img1 is None:
            print(f"错误: 无法读取图片 - {image1_path}", file=sys.stderr)
            return 0.0
            
        if img2 is None:
            print(f"错误: 无法读取图片 - {image2_path}", file=sys.stderr)
            return 0.0
        
        # 转换为灰度图
        gray1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
        gray2 = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)
        
        # 统一图片尺寸
        height, width = 256, 256
        resized1 = cv2.resize(gray1, (width, height))
        resized2 = cv2.resize(gray2, (width, height))
        
        # 方法1: 结构相似性指数 (SSIM)
        from skimage.metrics import structural_similarity
        ssim_score = structural_similarity(resized1, resized2)
        
        # 方法2: 直方图相关性
        hist1 = cv2.calcHist([resized1], [0], None, [256], [0, 256])
        hist2 = cv2.calcHist([resized2], [0], None, [256], [0, 256])
        hist_corr = cv2.compareHist(hist1, hist2, cv2.HISTCMP_CORREL)
        
        # 方法3: ORB特征匹配
        orb = cv2.ORB_create(nfeatures=500)
        kp1, des1 = orb.detectAndCompute(resized1, None)
        kp2, des2 = orb.detectAndCompute(resized2, None)
        
        orb_similarity = 0.0
        if des1 is not None and des2 is not None and len(des1) > 10 and len(des2) > 10:
            # 使用BFMatcher进行特征匹配
            bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
            matches = bf.match(des1, des2)
            
            if len(matches) > 0:
                # 计算好的匹配数量
                good_matches = [m for m in matches if m.distance < 30]
                orb_similarity = len(good_matches) / max(len(kp1), len(kp2))
                orb_similarity = min(orb_similarity, 1.0)  # 限制在1.0以内
        
        # 方法4: 模板匹配
        template_result = cv2.matchTemplate(resized1, resized2, cv2.TM_CCOEFF_NORMED)
        template_similarity = np.max(template_result)
        
        # 综合评分 (加权平均)
        # SSIM权重最高，因为它对图片结构变化最敏感
        weights = {
            'ssim': 0.4,
            'hist': 0.2, 
            'orb': 0.3,
            'template': 0.1
        }
        
        # 确保所有分数都在0-1范围内
        ssim_score = max(0.0, min(1.0, (ssim_score + 1.0) / 2.0))  # SSIM范围是-1到1，转换为0到1
        hist_corr = max(0.0, min(1.0, hist_corr))
        orb_similarity = max(0.0, min(1.0, orb_similarity))
        template_similarity = max(0.0, min(1.0, template_similarity))
        
        final_similarity = (
            ssim_score * weights['ssim'] +
            hist_corr * weights['hist'] +
            orb_similarity * weights['orb'] +
            template_similarity * weights['template']
        )
        
        # 打印调试信息到stderr
        print(f"调试信息:", file=sys.stderr)
        print(f"  SSIM: {ssim_score:.3f}", file=sys.stderr)
        print(f"  直方图相关性: {hist_corr:.3f}", file=sys.stderr)
        print(f"  ORB特征相似度: {orb_similarity:.3f}", file=sys.stderr)
        print(f"  模板匹配: {template_similarity:.3f}", file=sys.stderr)
        print(f"  综合相似度: {final_similarity:.3f}", file=sys.stderr)
        
        return final_similarity
        
    except ImportError as e:
        print(f"错误: 缺少必要的库 - {e}", file=sys.stderr)
        print("请确保安装了以下库: opencv-python, scikit-image, numpy", file=sys.stderr)
        return 0.0
    except Exception as e:
        print(f"错误: 计算相似度时发生异常 - {e}", file=sys.stderr)
        return 0.0

def main():
    """主函数"""
    if len(sys.argv) != 3:
        print("用法: python weighbridge_image_similarity.py <图片1路径> <图片2路径>", file=sys.stderr)
        sys.exit(1)
    
    image1_path = sys.argv[1]
    image2_path = sys.argv[2]
    
    # 计算相似度
    similarity = calculate_similarity(image1_path, image2_path)
    
    # 输出结果到stdout (Flutter会读取这个值)
    print(f"{similarity:.6f}")

if __name__ == "__main__":
    main() 