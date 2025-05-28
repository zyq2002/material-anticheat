import 'dart:io';
import 'package:material_anticheat/services/weighbridge_image_similarity_service.dart';

void main() async {
  print('开始测试图片查重功能...');
  
  final service = WeighbridgeImageSimilarityService();
  
  try {
    // 测试可疑图片检测，使用30%的阈值
    print('正在检测可疑图片，阈值: 30%');
    final results = await service.detectSuspiciousImages(30.0);
    
    print('检测完成！');
    print('发现 ${results.length} 张可疑图片');
    
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      print('');
      print('可疑图片 ${i + 1}:');
      print('  图片路径: ${result.imagePath}');
      print('  记录名称: ${result.recordName}');
      print('  图片类型: ${result.imageType}');
      print('  相似度: ${(result.similarity * 100).toStringAsFixed(1)}%');
      print('  匹配图片: ${result.matchImagePath}');
      print('  匹配记录: ${result.matchRecordName}');
    }
    
  } catch (e) {
    print('测试失败: $e');
  }
  
  print('\n测试完成！');
} 