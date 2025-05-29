#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
过磅图片相似度批量检测脚本（优化版本）
支持批量处理多个图片对，提高检测效率
"""

import sys
import os
import json
import cv2
import numpy as np
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import multiprocessing

def calculate_similarity_fast(image1_path, image2_path):
    """
    快速计算两张图片的相似度（优化版本）
    
    Args:
        image1_path: 第一张图片路径
        image2_path: 第二张图片路径
        
    Returns:
        float: 相似度分数 (0.0 - 1.0)
    """
    try:
        # 检查文件是否存在
        if not os.path.exists(image1_path) or not os.path.exists(image2_path):
            return 0.0
        
        # 读取图片
        img1 = cv2.imread(image1_path)
        img2 = cv2.imread(image2_path)
        
        if img1 is None or img2 is None:
            return 0.0
        
        # 转换为灰度图并调整尺寸（使用更小的尺寸提高速度）
        gray1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
        gray2 = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)
        
        # 使用较小的尺寸以提高处理速度
        height, width = 128, 128
        resized1 = cv2.resize(gray1, (width, height))
        resized2 = cv2.resize(gray2, (width, height))
        
        # 方法1: 结构相似性指数 (SSIM) - 主要方法
        try:
            from skimage.metrics import structural_similarity
            ssim_score = structural_similarity(resized1, resized2)
            ssim_score = max(0.0, min(1.0, (ssim_score + 1.0) / 2.0))
        except ImportError:
            ssim_score = 0.0
        
        # 方法2: 直方图相关性 - 快速方法
        hist1 = cv2.calcHist([resized1], [0], None, [64], [0, 256])  # 减少bin数量
        hist2 = cv2.calcHist([resized2], [0], None, [64], [0, 256])
        hist_corr = cv2.compareHist(hist1, hist2, cv2.HISTCMP_CORREL)
        hist_corr = max(0.0, min(1.0, hist_corr))
        
        # 方法3: ORB特征匹配 - 轻量级方法
        orb_similarity = 0.0
        try:
            orb = cv2.ORB_create(nfeatures=200)  # 减少特征点数量
            kp1, des1 = orb.detectAndCompute(resized1, None)
            kp2, des2 = orb.detectAndCompute(resized2, None)
            
            if des1 is not None and des2 is not None and len(des1) > 5 and len(des2) > 5:
                # 使用BFMatcher进行特征匹配
                bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
                matches = bf.match(des1, des2)
                
                if len(matches) > 0:
                    # 计算好的匹配数量
                    good_matches = [m for m in matches if m.distance < 40]  # 放宽匹配条件
                    orb_similarity = len(good_matches) / max(len(kp1), len(kp2))
                    orb_similarity = min(orb_similarity, 1.0)
        except Exception:
            orb_similarity = 0.0
        
        # 方法4: 模板匹配 - 快速方法
        template_similarity = 0.0
        try:
            template_result = cv2.matchTemplate(resized1, resized2, cv2.TM_CCOEFF_NORMED)
            template_similarity = np.max(template_result)
            template_similarity = max(0.0, min(1.0, template_similarity))
        except Exception:
            template_similarity = 0.0
        
        # 综合评分 (优化权重)
        weights = {
            'ssim': 0.5,      # 增加SSIM权重
            'hist': 0.25,     # 增加直方图权重
            'orb': 0.15,      # 减少ORB权重
            'template': 0.1   # 保持模板匹配权重
        }
        
        final_similarity = (
            ssim_score * weights['ssim'] +
            hist_corr * weights['hist'] +
            orb_similarity * weights['orb'] +
            template_similarity * weights['template']
        )
        
        return min(1.0, max(0.0, final_similarity))
        
    except Exception as e:
        print(f"计算相似度时出错: {e}", file=sys.stderr)
        return 0.0

def process_image_pair(pair_data):
    """
    处理单个图片对
    
    Args:
        pair_data: 包含图片路径的字典
        
    Returns:
        dict: 处理结果
    """
    image1_path = pair_data['image1']
    image2_path = pair_data['image2']
    
    try:
        similarity = calculate_similarity_fast(image1_path, image2_path)
        return {
            'image1': image1_path,
            'image2': image2_path,
            'similarity': similarity,
            'success': True
        }
    except Exception as e:
        return {
            'image1': image1_path,
            'image2': image2_path,
            'similarity': 0.0,
            'success': False,
            'error': str(e)
        }

def batch_process_images(image_pairs, max_workers=None):
    """
    批量处理图片对
    
    Args:
        image_pairs: 图片对列表
        max_workers: 最大工作线程数
        
    Returns:
        list: 处理结果列表
    """
    if max_workers is None:
        max_workers = min(multiprocessing.cpu_count(), 8)  # 限制最大线程数
    
    results = []
    
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # 提交所有任务
        future_to_pair = {
            executor.submit(process_image_pair, pair): pair 
            for pair in image_pairs
        }
        
        # 收集结果
        for future in as_completed(future_to_pair):
            try:
                result = future.result()
                results.append(result)
            except Exception as e:
                pair = future_to_pair[future]
                results.append({
                    'image1': pair['image1'],
                    'image2': pair['image2'],
                    'similarity': 0.0,
                    'success': False,
                    'error': str(e)
                })
    
    return results

def main():
    """
    主函数
    """
    if len(sys.argv) < 2:
        print("用法: python weighbridge_image_similarity_batch.py <json_input>")
        print("或者: python weighbridge_image_similarity_batch.py <image1> <image2>")
        sys.exit(1)
    
    if len(sys.argv) == 3:
        # 单个图片对比模式
        image1_path = sys.argv[1]
        image2_path = sys.argv[2]
        
        similarity = calculate_similarity_fast(image1_path, image2_path)
        print(similarity)
        
    else:
        # 批量处理模式
        try:
            input_data = json.loads(sys.argv[1])
            image_pairs = input_data.get('pairs', [])
            max_workers = input_data.get('max_workers', None)
            
            if not image_pairs:
                print(json.dumps({'error': '没有提供图片对'}))
                sys.exit(1)
            
            results = batch_process_images(image_pairs, max_workers)
            
            output = {
                'success': True,
                'total_pairs': len(image_pairs),
                'processed_pairs': len(results),
                'results': results
            }
            
            print(json.dumps(output))
            
        except json.JSONDecodeError as e:
            print(json.dumps({'error': f'JSON解析错误: {e}'}))
            sys.exit(1)
        except Exception as e:
            print(json.dumps({'error': f'处理错误: {e}'}))
            sys.exit(1)

if __name__ == '__main__':
    main() 