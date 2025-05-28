import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../models/similarity_result.dart';
import '../models/duplicate_detection_config.dart';

// Provider for the image similarity service
final imageSimilarityServiceProvider = Provider<ImageSimilarityService>((ref) {
  return ImageSimilarityService();
});

// Provider for suspicious images detection results
final suspiciousImagesProvider = FutureProvider.autoDispose.family<List<SimilarityResult>, double>((ref, threshold) async {
  final service = ref.read(imageSimilarityServiceProvider);
  return service.detectSuspiciousImagesForToday(threshold: threshold);
});

// Provider for all suspicious images with custom date range
final suspiciousImagesWithDateRangeProvider = FutureProvider.autoDispose.family<List<SimilarityResult>, SuspiciousImageQuery>((ref, query) async {
  final service = ref.read(imageSimilarityServiceProvider);
  final config = DuplicateDetectionConfig(
    threshold: query.threshold,
    compareDays: query.includeDateRange ? 30 : 1, // 如果需要日期范围则检测30天，否则只检测1天
  );
  return service.detectDuplicateImages(config: config);
});

class SuspiciousImageQuery {
  final double threshold;
  final bool includeDateRange;

  const SuspiciousImageQuery({
    required this.threshold,
    this.includeDateRange = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SuspiciousImageQuery &&
        other.threshold == threshold &&
        other.includeDateRange == includeDateRange;
  }

  @override
  int get hashCode {
    return threshold.hashCode ^
        includeDateRange.hashCode;
  }
}

class ImageSimilarityService {
  static const String _pythonScriptPath = 'python_scripts/sift_similarity.py';
  static const String _venvPythonPath = '.venv/bin/python';
  
  /// 检测今日可疑图片
  Future<List<SimilarityResult>> detectSuspiciousImagesForToday({
    required double threshold,
  }) async {
    final config = DuplicateDetectionConfig(
      threshold: threshold,
      compareDays: 1, // 只检测今天
    );
    
    return detectDuplicateImages(config: config);
  }

  /// 检测指定日期范围内的重复图片
  Future<List<SimilarityResult>> detectDuplicateImages({
    required DuplicateDetectionConfig config,
  }) async {
    final results = <SimilarityResult>[];
    
    try {
      // 获取指定日期范围内的图片
      final imageGroups = await _getImageGroups(config);
      
      for (final dateKey in imageGroups.keys) {
        final dayGroups = imageGroups[dateKey]!;
        
        // 在同一天内不同验收记录之间进行对比
        final recordIds = dayGroups.keys.toList();
        
        for (int i = 0; i < recordIds.length; i++) {
          for (int j = i + 1; j < recordIds.length; j++) {
            final group1 = dayGroups[recordIds[i]]!;
            final group2 = dayGroups[recordIds[j]]!;
            
            // 对比同一位置的图片
            final similarities = await _compareImageGroups(
              group1, 
              group2, 
              config.threshold,
              recordIds[i],
              recordIds[j],
            );
            
            results.addAll(similarities);
          }
        }
      }
      
      // 按相似度降序排序
      results.sort((a, b) => b.similarity.compareTo(a.similarity));
      
    } catch (e) {
      debugPrint('检测重复图片时出错: $e');
    }
    
    return results;
  }
  
  /// 获取图片分组
  Future<Map<String, Map<String, List<File>>>> _getImageGroups(
    DuplicateDetectionConfig config,
  ) async {
    final imageGroups = <String, Map<String, List<File>>>{};
    
    // 尝试多个可能的图片目录路径
    final possiblePaths = [
      'pic/images/images',
      'pic/images',
    ];
    
    Directory? baseDir;
    for (final path in possiblePaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        baseDir = dir;
        break;
      }
    }
    
    if (baseDir == null) {
      throw Exception('图片目录不存在，尝试的路径: ${possiblePaths.join(', ')}');
    }
    
    final targetDates = _getTargetDates(config);
    
    for (final date in targetDates) {
      final dateDir = Directory(path.join(baseDir.path, date));
      if (!await dateDir.exists()) continue;
      
      final dayGroups = <String, List<File>>{};
      
      await for (final entity in dateDir.list()) {
        if (entity is Directory) {
          final recordName = path.basename(entity.path);
          final recordId = recordName.split('_')[0]; // 提取记录ID如 RKD20250519040
          
          final imageFiles = <File>[];
          await for (final file in entity.list()) {
            if (file is File && _isImageFile(file.path)) {
              imageFiles.add(file);
            }
          }
          
          if (imageFiles.isNotEmpty) {
            dayGroups[recordId] = imageFiles;
          }
        }
      }
      
      if (dayGroups.isNotEmpty) {
        imageGroups[date] = dayGroups;
      }
    }
    
    return imageGroups;
  }
  
  /// 对比两组图片
  Future<List<SimilarityResult>> _compareImageGroups(
    List<File> group1,
    List<File> group2,
    double threshold,
    String recordId1,
    String recordId2,
  ) async {
    final results = <SimilarityResult>[];
    
    // 按照图片类型进行分组对比
    final group1ByType = _groupImagesByType(group1);
    final group2ByType = _groupImagesByType(group2);
    
    for (final type in group1ByType.keys) {
      if (group2ByType.containsKey(type)) {
        final typeResults = await _compareSameTypeImages(
          group1ByType[type]!,
          group2ByType[type]!,
          threshold,
          recordId1,
          recordId2,
          type,
        );
        results.addAll(typeResults);
      }
    }
    
    return results;
  }
  
  /// 按图片类型分组
  Map<String, List<File>> _groupImagesByType(List<File> images) {
    final grouped = <String, List<File>>{};
    
    for (final image in images) {
      final filename = path.basename(image.path);
      String type = '其他';
      
      if (filename.contains('验收照片1')) {
        type = '验收照片1';
      } else if (filename.contains('验收照片2')) {
        type = '验收照片2';
      } else if (filename.contains('验收照片3')) {
        type = '验收照片3';
      } else if (filename.contains('验收照片4')) {
        type = '验收照片4';
      } else if (filename.contains('验收照片5')) {
        type = '验收照片5';
      } else if (filename.contains('验收照片6')) {
        type = '验收照片6';
      } else if (filename.contains('验收照片7')) {
        type = '验收照片7';
      } else if (filename.contains('送货单')) {
        type = '送货单';
      }
      
      grouped.putIfAbsent(type, () => []).add(image);
    }
    
    return grouped;
  }
  
  /// 对比同类型图片
  Future<List<SimilarityResult>> _compareSameTypeImages(
    List<File> images1,
    List<File> images2,
    double threshold,
    String recordId1,
    String recordId2,
    String imageType,
  ) async {
    final results = <SimilarityResult>[];
    
    for (final img1 in images1) {
      for (final img2 in images2) {
        final similarity = await _calculateSimilarity(img1, img2);
        
        // 为每次比对添加详细的相似率日志输出
        final img1Name = path.basename(img1.path);
        final img2Name = path.basename(img2.path);
        debugPrint('图片对比: $img1Name vs $img2Name, 相似度: ${similarity.toStringAsFixed(2)}%');
        
        if (similarity >= threshold) {
          results.add(SimilarityResult(
            image1Path: img1.path,
            image2Path: img2.path,
            similarity: similarity,
            isDuplicate: true,
            detectionTime: DateTime.now(),
            image1RecordId: recordId1,
            image2RecordId: recordId2,
            imageType: imageType,
          ));
          debugPrint('⚠️ 发现重复图片: $recordId1 vs $recordId2, 相似度: ${similarity.toStringAsFixed(1)}%');
        } else {
          debugPrint('✓ 图片对比正常: $recordId1 vs $recordId2, 相似度: ${similarity.toStringAsFixed(1)}%');
        }
      }
    }
    
    return results;
  }
  
  /// 使用 SIFT 算法计算两张图片的相似度
  Future<double> _calculateSimilarity(File image1, File image2) async {
    try {
      // 优先使用打包的可执行文件，如果不存在则使用Python脚本
      String? executablePath;
      
      // 检查多个可能的路径
      final possiblePaths = [
        // 开发环境路径
        path.join(Directory.current.path, 'bundled_python', 'sift_similarity'),
        // macOS应用包内路径
        path.join(Directory.current.path, '..', 'Resources', 'bundled_python', 'sift_similarity'),
        // 备用路径
        path.join(path.dirname(Platform.resolvedExecutable), '..', 'Resources', 'bundled_python', 'sift_similarity'),
      ];
      
      File? executableFile;
      for (final testPath in possiblePaths) {
        final file = File(testPath);
        if (await file.exists()) {
          executablePath = testPath;
          executableFile = file;
          break;
        }
      }
      
      ProcessResult result;
      
      if (executableFile != null) {
        // 使用打包的可执行文件（推荐，无需Python环境）
        final process = await Process.start(
          executablePath!,
          [image1.path, image2.path],
          workingDirectory: Directory.current.path,
          environment: {
            'PATH': '/usr/local/bin:/usr/bin:/bin',
          },
        );
        
        final stdout = await process.stdout.transform(const SystemEncoding().decoder).join();
        final stderr = await process.stderr.transform(const SystemEncoding().decoder).join();
        final exitCode = await process.exitCode;
        
        result = ProcessResult(process.pid, exitCode, stdout, stderr);
      } else {
        // 回退到系统Python（需要用户安装Python和依赖）
        final process = await Process.start(
          '/usr/bin/python3',
          [
            _pythonScriptPath,
            image1.path,
            image2.path,
          ],
          workingDirectory: Directory.current.path,
          environment: {
            'PATH': '/usr/local/bin:/usr/bin:/bin',
            'PYTHONPATH': path.join(Directory.current.path, '.venv', 'lib', 'python3.9', 'site-packages'),
          },
        );
        
        final stdout = await process.stdout.transform(const SystemEncoding().decoder).join();
        final stderr = await process.stderr.transform(const SystemEncoding().decoder).join();
        final exitCode = await process.exitCode;
        
        result = ProcessResult(process.pid, exitCode, stdout, stderr);
      }
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        return double.tryParse(output) ?? 0.0;
      } else {
        debugPrint('SIFT 计算错误: ${result.stderr}');
        return 0.0;
      }
    } catch (e) {
      debugPrint('调用 Python 脚本失败: $e');
      return 0.0;
    }
  }
  
  /// 获取目标日期列表
  List<String> _getTargetDates(DuplicateDetectionConfig config) {
    final dates = <String>[];
    final now = DateTime.now();
    
    // 使用compareDays参数
    for (int i = 0; i < config.compareDays; i++) {
      final date = now.subtract(Duration(days: i));
      dates.add(_formatDate(date));
    }
    
    return dates;
  }
  
  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// 判断是否为图片文件
  bool _isImageFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.bmp', '.gif'].contains(ext);
  }
} 