#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SIFT 图像相似度计算脚本
基于 OpenCV 的 SIFT 算法计算两张图片的相似度
"""

import sys
import cv2
import numpy as np
from pathlib import Path

def calculate_sift_similarity(image_path1, image_path2, ratio_threshold=0.7):
    """
    使用 SIFT 算法计算两张图片的相似度
    
    Args:
        image_path1: 第一张图片路径
        image_path2: 第二张图片路径
        ratio_threshold: 特征匹配比率阈值
        
    Returns:
        float: 相似度 (0-100)
    """
    try:
        # 读取图片
        img1 = cv2.imread(str(image_path1), cv2.IMREAD_GRAYSCALE)
        img2 = cv2.imread(str(image_path2), cv2.IMREAD_GRAYSCALE)
        
        if img1 is None or img2 is None:
            print(f"无法读取图片: {image_path1} 或 {image_path2}", file=sys.stderr)
            return 0.0
        
        # 创建 SIFT 检测器
        sift = cv2.SIFT_create()
        
        # 检测关键点和描述符
        kp1, des1 = sift.detectAndCompute(img1, None)
        kp2, des2 = sift.detectAndCompute(img2, None)
        
        if des1 is None or des2 is None:
            return 0.0
        
        # 使用 FLANN 匹配器
        FLANN_INDEX_KDTREE = 1
        index_params = dict(algorithm=FLANN_INDEX_KDTREE, trees=5)
        search_params = dict(checks=50)
        flann = cv2.FlannBasedMatcher(index_params, search_params)
        
        # 匹配特征点
        matches = flann.knnMatch(des1, des2, k=2)
        
        # 使用 Lowe's ratio test 筛选好的匹配
        good_matches = []
        for match_pair in matches:
            if len(match_pair) == 2:
                m, n = match_pair
                if m.distance < ratio_threshold * n.distance:
                    good_matches.append(m)
        
        # 计算相似度
        if len(kp1) == 0 or len(kp2) == 0:
            return 0.0
            
        # 相似度 = 好的匹配数量 / 平均关键点数量 * 100
        avg_keypoints = (len(kp1) + len(kp2)) / 2
        similarity = (len(good_matches) / avg_keypoints) * 100 if avg_keypoints > 0 else 0.0
        
        # 限制相似度在 0-100 之间
        return min(100.0, max(0.0, similarity))
        
    except Exception as e:
        print(f"计算相似度时出错: {e}", file=sys.stderr)
        return 0.0

def calculate_histogram_similarity(image_path1, image_path2):
    """
    使用直方图计算图片相似度（作为 SIFT 的补充）
    
    Args:
        image_path1: 第一张图片路径
        image_path2: 第二张图片路径
        
    Returns:
        float: 相似度 (0-100)
    """
    try:
        img1 = cv2.imread(str(image_path1))
        img2 = cv2.imread(str(image_path2))
        
        if img1 is None or img2 is None:
            return 0.0
        
        # 计算直方图
        hist1 = cv2.calcHist([img1], [0, 1, 2], None, [50, 50, 50], [0, 256, 0, 256, 0, 256])
        hist2 = cv2.calcHist([img2], [0, 1, 2], None, [50, 50, 50], [0, 256, 0, 256, 0, 256])
        
        # 使用相关性计算相似度
        similarity = cv2.compareHist(hist1, hist2, cv2.HISTCMP_CORREL) * 100
        
        return max(0.0, similarity)
        
    except Exception as e:
        print(f"计算直方图相似度时出错: {e}", file=sys.stderr)
        return 0.0

def calculate_combined_similarity(image_path1, image_path2):
    """
    综合 SIFT 和直方图计算相似度
    
    Args:
        image_path1: 第一张图片路径
        image_path2: 第二张图片路径
        
    Returns:
        float: 综合相似度 (0-100)
    """
    sift_sim = calculate_sift_similarity(image_path1, image_path2)
    hist_sim = calculate_histogram_similarity(image_path1, image_path2)
    
    # 权重组合：SIFT 70%，直方图 30%
    combined_sim = sift_sim * 0.7 + hist_sim * 0.3
    
    return combined_sim

def main():
    """主函数"""
    if len(sys.argv) != 3:
        print("用法: python sift_similarity.py <image1_path> <image2_path>", file=sys.stderr)
        sys.exit(1)
    
    image_path1 = Path(sys.argv[1])
    image_path2 = Path(sys.argv[2])
    
    if not image_path1.exists():
        print(f"图片不存在: {image_path1}", file=sys.stderr)
        sys.exit(1)
    
    if not image_path2.exists():
        print(f"图片不存在: {image_path2}", file=sys.stderr)
        sys.exit(1)
    
    # 计算相似度
    similarity = calculate_combined_similarity(image_path1, image_path2)
    
    # 输出结果（只输出数字，供 Dart 解析）
    print(f"{similarity:.2f}")

if __name__ == "__main__":
    main() 