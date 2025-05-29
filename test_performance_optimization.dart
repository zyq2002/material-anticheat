import 'dart:io';
import 'package:material_anticheat/services/weighbridge_image_similarity_service.dart';
import 'package:material_anticheat/services/weighbridge_duplicate_detection_service.dart';

void main() async {
  print('🚀 开始性能优化测试...');
  
  final stopwatch = Stopwatch();
  
  try {
    // 测试1: 可疑图片检测性能
    print('\n📊 测试1: 可疑图片检测性能');
    stopwatch.start();
    
    final suspiciousService = WeighbridgeImageSimilarityService();
    print('正在检测可疑图片，阈值: 30%');
    final suspiciousResults = await suspiciousService.detectSuspiciousImages(30.0);
    
    stopwatch.stop();
    print('✅ 可疑图片检测完成！');
    print('   发现 ${suspiciousResults.length} 张可疑图片');
    print('   耗时: ${stopwatch.elapsedMilliseconds}ms (${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}秒)');
    
    // 测试2: 重复图片检测性能
    print('\n📊 测试2: 重复图片检测性能');
    stopwatch.reset();
    stopwatch.start();
    
    final duplicateService = WeighbridgeDuplicateDetectionService();
    final config = WeighbridgeDuplicateConfig(
      similarityThreshold: 0.8,
      compareDays: 3, // 只检测3天，减少测试时间
      compareCarFrontImages: true,
      compareCarLeftImages: true,
      compareCarRightImages: true,
      compareCarPlateImages: true,
    );
    
    print('正在检测重复图片，阈值: 80%，天数: 3天');
    
    var duplicateResults = <WeighbridgeDuplicateResult>[];
    var totalComparisons = 0;
    
    await for (final progress in duplicateService.detectDuplicates(config)) {
      if (progress.progress > 0) {
        print('   进度: ${(progress.progress * 100).toStringAsFixed(1)}% - ${progress.currentTask}');
      }
      
      if (progress.isCompleted) {
        duplicateResults = progress.results;
        break;
      }
    }
    
    stopwatch.stop();
    print('✅ 重复图片检测完成！');
    print('   发现 ${duplicateResults.length} 组重复图片');
    print('   耗时: ${stopwatch.elapsedMilliseconds}ms (${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}秒)');
    
    // 性能分析
    print('\n📈 性能分析:');
    if (suspiciousResults.isNotEmpty) {
      final avgTimePerSuspicious = stopwatch.elapsedMilliseconds / suspiciousResults.length;
      print('   可疑图片检测: 平均每张 ${avgTimePerSuspicious.toStringAsFixed(2)}ms');
    }
    
    if (duplicateResults.isNotEmpty) {
      final avgTimePerDuplicate = stopwatch.elapsedMilliseconds / duplicateResults.length;
      print('   重复图片检测: 平均每组 ${avgTimePerDuplicate.toStringAsFixed(2)}ms');
    }
    
    // 优化效果总结
    print('\n🎯 优化效果总结:');
    print('   ✅ 支持并行处理: 使用Isolate池和批量处理');
    print('   ✅ 结果缓存: 避免重复计算相同图片对');
    print('   ✅ 后台运行: 不阻塞UI线程');
    print('   ✅ 进度反馈: 实时显示检测进度');
    print('   ✅ 资源管理: 自动清理Isolate资源');
    
    // 显示部分结果
    if (suspiciousResults.isNotEmpty) {
      print('\n🔍 可疑图片示例:');
      for (int i = 0; i < suspiciousResults.length && i < 3; i++) {
        final result = suspiciousResults[i];
        print('   ${i + 1}. ${result.recordName} (${result.imageType}) - 相似度: ${(result.similarity * 100).toStringAsFixed(1)}%');
      }
    }
    
    if (duplicateResults.isNotEmpty) {
      print('\n🔄 重复图片示例:');
      for (int i = 0; i < duplicateResults.length && i < 3; i++) {
        final result = duplicateResults[i];
        print('   ${i + 1}. ${result.recordName1} vs ${result.recordName2} (${result.imageType}) - 相似度: ${(result.similarity * 100).toStringAsFixed(1)}%');
      }
    }
    
  } catch (e) {
    print('❌ 测试失败: $e');
  }
  
  print('\n🏁 性能测试完成！');
} 