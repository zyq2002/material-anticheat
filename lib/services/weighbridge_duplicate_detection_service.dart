import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/detection_result.dart';
import '../services/detection_history_service.dart';
import 'log_service.dart';
import 'weighbridge_image_similarity_service.dart';

// part 'weighbridge_duplicate_detection_service.g.dart';

// 过磅重复检测配置
class WeighbridgeDuplicateConfig {
  final double similarityThreshold;
  final int compareDays;
  final bool compareCarFrontImages;
  final bool compareCarLeftImages;
  final bool compareCarRightImages;
  final bool compareCarPlateImages;

  const WeighbridgeDuplicateConfig({
    this.similarityThreshold = 0.8,
    this.compareDays = 7,
    this.compareCarFrontImages = true,
    this.compareCarLeftImages = true,
    this.compareCarRightImages = true,
    this.compareCarPlateImages = true,
  });

  WeighbridgeDuplicateConfig copyWith({
    double? similarityThreshold,
    int? compareDays,
    bool? compareCarFrontImages,
    bool? compareCarLeftImages,
    bool? compareCarRightImages,
    bool? compareCarPlateImages,
  }) {
    return WeighbridgeDuplicateConfig(
      similarityThreshold: similarityThreshold ?? this.similarityThreshold,
      compareDays: compareDays ?? this.compareDays,
      compareCarFrontImages: compareCarFrontImages ?? this.compareCarFrontImages,
      compareCarLeftImages: compareCarLeftImages ?? this.compareCarLeftImages,
      compareCarRightImages: compareCarRightImages ?? this.compareCarRightImages,
      compareCarPlateImages: compareCarPlateImages ?? this.compareCarPlateImages,
    );
  }

  bool hasAnyImageTypeSelected() {
    return compareCarFrontImages || compareCarLeftImages || compareCarRightImages || compareCarPlateImages;
  }

  @override
  String toString() {
    return 'WeighbridgeDuplicateConfig(threshold: ${(similarityThreshold * 100).toStringAsFixed(0)}%, days: $compareDays, types: [${_getSelectedTypes().join(', ')}])';
  }

  List<String> _getSelectedTypes() {
    final types = <String>[];
    if (compareCarFrontImages) types.add('车前');
    if (compareCarLeftImages) types.add('左侧');
    if (compareCarRightImages) types.add('右侧');
    if (compareCarPlateImages) types.add('车牌');
    return types;
  }
}

// 过磅重复检测结果
class WeighbridgeDuplicateResult {
  final String imagePath1;
  final String imagePath2;
  final String recordName1;
  final String recordName2;
  final double similarity;
  final String imageType;
  final DateTime detectionTime;

  const WeighbridgeDuplicateResult({
    required this.imagePath1,
    required this.imagePath2,
    required this.recordName1,
    required this.recordName2,
    required this.similarity,
    required this.imageType,
    required this.detectionTime,
  });
}

// 检测进度更新
class WeighbridgeDuplicateProgress {
  final String currentTask;
  final double progress;
  final List<WeighbridgeDuplicateResult> results;
  final bool isCompleted;

  const WeighbridgeDuplicateProgress({
    required this.currentTask,
    required this.progress,
    required this.results,
    this.isCompleted = false,
  });
}

class WeighbridgeDuplicateDetectionService {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  LogService? _logService;
  
  // 静态缓存，用于存储图片对比结果
  static final Map<String, double> _similarityCache = {};

  WeighbridgeDuplicateDetectionService() {
    // _logService will be set when needed
  }

  /// 执行过磅重复检测
  Stream<WeighbridgeDuplicateProgress> detectDuplicates(WeighbridgeDuplicateConfig config, [dynamic ref]) async* {
    DetectionHistoryService? historyService;
    
    if (ref != null) {
      try {
        _logService ??= ref.read(logServiceProvider.notifier);
        historyService = ref.read(detectionHistoryServiceProvider);
      } catch (e) {
        // Fallback if ref is not available
      }
    }

    // 创建检测会话
    final sessionId = const Uuid().v4();
    final startTime = DateTime.now();
    final detectionResults = <DetectionResult>[];
    
    try {
      _logger.i('开始过磅重复检测');
      _logService?.info('开始过磅重复检测，阈值: ${(config.similarityThreshold * 100).toStringAsFixed(0)}%，天数: ${config.compareDays}天');

      yield WeighbridgeDuplicateProgress(
        currentTask: '正在获取过磅图片...',
        progress: 0.0,
        results: [],
      );

      // 获取过磅图片路径
      final weighbridgeImagesPath = await _getWeighbridgeImagesPath();
      final imageGroups = await _loadImageGroups(weighbridgeImagesPath, config.compareDays);

      if (imageGroups.isEmpty) {
        _logService?.info('未找到过磅图片，检测结束');
        yield WeighbridgeDuplicateProgress(
          currentTask: '未找到过磅图片',
          progress: 1.0,
          results: [],
          isCompleted: true,
        );
        return;
      }

      _logger.i('找到 ${imageGroups.length} 个过磅记录');
      _logService?.info('找到 ${imageGroups.length} 个过磅记录，开始重复检测');

      yield WeighbridgeDuplicateProgress(
        currentTask: '正在准备图片对比...',
        progress: 0.1,
        results: [],
      );

      // 按图片类型分组
      final imagesByType = _groupImagesByType(imageGroups, config);
      final results = <WeighbridgeDuplicateResult>[];
      
      int totalComparisons = 0;
      int completedComparisons = 0;

      // 计算总对比数量
      for (final typeEntry in imagesByType.entries) {
        final images = typeEntry.value;
        totalComparisons += (images.length * (images.length - 1)) ~/ 2;
      }

      _logger.i('需要进行 $totalComparisons 次图片对比');
      _logService?.info('需要进行 $totalComparisons 次图片对比');

      // 对每种图片类型进行重复检测
      for (final typeEntry in imagesByType.entries) {
        final imageType = typeEntry.key;
        final images = typeEntry.value;

        if (images.length < 2) continue;

        yield WeighbridgeDuplicateProgress(
          currentTask: '正在检测 $imageType...',
          progress: 0.2 + (completedComparisons / totalComparisons) * 0.7,
          results: results,
        );

        _logger.i('开始检测 $imageType，共 ${images.length} 张图片');
        _logService?.info('开始检测 $imageType，共 ${images.length} 张图片');

        // 收集所有需要对比的图片对
        final comparisonTasks = <Future<WeighbridgeDuplicateResult?>>[];
        
        for (int i = 0; i < images.length - 1; i++) {
          for (int j = i + 1; j < images.length; j++) {
            final image1 = images[i];
            final image2 = images[j];

            // 避免同一记录内的图片对比
            if (image1.recordName == image2.recordName) {
              continue;
            }

            // 添加并行对比任务
            comparisonTasks.add(_compareImagesParallel(
              image1, 
              image2, 
              imageType, 
              config,
              detectionResults,
            ));
          }
        }

        _logger.i('$imageType 需要对比 ${comparisonTasks.length} 个图片对');

        // 使用批量并行处理，避免过多并发
        final batchSize = 8; // 增加批次大小以提高并行度
        int batchCompletedComparisons = 0;
        
        for (int i = 0; i < comparisonTasks.length; i += batchSize) {
          final batchEnd = (i + batchSize < comparisonTasks.length) 
              ? i + batchSize 
              : comparisonTasks.length;
          
          final batchTasks = comparisonTasks.sublist(i, batchEnd);
          
          yield WeighbridgeDuplicateProgress(
            currentTask: '正在对比第 ${batchCompletedComparisons + 1}-${batchCompletedComparisons + batchTasks.length}/$totalComparisons 组图片...',
            progress: 0.2 + ((completedComparisons + batchCompletedComparisons) / totalComparisons) * 0.7,
            results: results,
          );
          
          // 并行执行当前批次的任务
          final batchResults = await Future.wait(batchTasks);
          
          // 收集非null结果
          for (final result in batchResults) {
            if (result != null) {
              results.add(result);
            }
          }
          
          batchCompletedComparisons += batchTasks.length;
          
          // 减少暂停时间，提高处理速度
          await Future.delayed(const Duration(milliseconds: 25));
        }

        completedComparisons += comparisonTasks.length;

        _logger.i('$imageType 检测完成，发现 ${results.where((r) => r.imageType == imageType).length} 组重复');
        _logService?.info('$imageType 检测完成，发现 ${results.where((r) => r.imageType == imageType).length} 组重复');
      }

      // 按相似度降序排序
      results.sort((a, b) => b.similarity.compareTo(a.similarity));

      _logger.i('过磅重复检测完成，总计发现 ${results.length} 组重复图片');
      _logService?.success('过磅重复检测完成，总计发现 ${results.length} 组重复图片');

      // 保存检测会话
      if (historyService != null) {
        try {
          final session = DetectionSession(
            id: sessionId,
            startTime: startTime,
            endTime: DateTime.now(),
            detectionType: 'duplicate',
            config: {
              'similarityThreshold': config.similarityThreshold,
              'compareDays': config.compareDays,
              'compareCarFrontImages': config.compareCarFrontImages,
              'compareCarLeftImages': config.compareCarLeftImages,
              'compareCarRightImages': config.compareCarRightImages,
              'compareCarPlateImages': config.compareCarPlateImages,
            },
            totalComparisons: totalComparisons,
            foundIssues: results.length,
            results: detectionResults,
          );

          await historyService.saveDetectionSession(session);
          _logger.i('检测会话已保存: $sessionId');
          _logService?.info('检测会话已保存到历史记录');
        } catch (e) {
          _logger.e('保存检测会话失败: $e');
          _logService?.error('保存检测会话失败: $e');
        }
      }

      yield WeighbridgeDuplicateProgress(
        currentTask: '检测完成，发现 ${results.length} 组重复图片',
        progress: 1.0,
        results: results,
        isCompleted: true,
      );

    } catch (e) {
      _logger.e('过磅重复检测失败: $e');
      _logService?.error('过磅重复检测失败: $e');
      
      yield WeighbridgeDuplicateProgress(
        currentTask: '检测失败: $e',
        progress: 0.0,
        results: [],
        isCompleted: true,
      );
    }
  }

  /// 获取过磅图片路径
  Future<String> _getWeighbridgeImagesPath() async {
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString('weighbridge_save_path');
    
    if (customPath != null && customPath.isNotEmpty) {
      return path.join(customPath, 'weighbridge');
    } else {
      final currentDir = Directory.current.path;
      
      // 确保路径是绝对路径，不是根目录
      if (currentDir == '/' || currentDir.isEmpty) {
        // 如果当前目录是根目录，使用用户文档目录
        final safePath = path.join(Platform.environment['HOME'] ?? '/tmp', 'Downloads', 'material_anticheat', 'pic', 'weighbridge');
        return safePath;
      } else {
        // 使用相对于当前工作目录的路径
      return path.join(currentDir, 'pic', 'weighbridge');
      }
    }
  }

  /// 加载图片分组
  Future<Map<String, List<WeighbridgeImageFile>>> _loadImageGroups(
    String basePath, 
    int compareDays,
  ) async {
    final baseDir = Directory(basePath);
    if (!await baseDir.exists()) {
      return {};
    }

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: compareDays - 1));
    final imageGroups = <String, List<WeighbridgeImageFile>>{};

    await for (final dateEntity in baseDir.list(followLinks: false)) {
      if (dateEntity is Directory) {
        final dateName = path.basename(dateEntity.path);
        
        // 验证日期格式并检查是否在范围内
        final dateMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(dateName);
        if (dateMatch == null) continue;
        
        final date = DateTime(
          int.parse(dateMatch.group(1)!),
          int.parse(dateMatch.group(2)!),
          int.parse(dateMatch.group(3)!),
        );
        
        if (date.isBefore(startDate) || date.isAfter(now)) continue;

        // 遍历该日期下的过磅记录
        await for (final recordEntity in dateEntity.list(followLinks: false)) {
          if (recordEntity is Directory) {
            final recordName = path.basename(recordEntity.path);
            final images = <WeighbridgeImageFile>[];

            await for (final imageEntity in recordEntity.list(followLinks: false)) {
              if (imageEntity is File) {
                final extension = path.extension(imageEntity.path).toLowerCase();
                if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension)) {
                  images.add(WeighbridgeImageFile(
                    filePath: imageEntity.path,
                    recordName: recordName,
                    fileName: path.basename(imageEntity.path),
                  ));
                }
              }
            }

            if (images.isNotEmpty) {
              imageGroups[recordName] = images;
            }
          }
        }
      }
    }

    return imageGroups;
  }

  /// 按图片类型分组
  Map<String, List<WeighbridgeImageFile>> _groupImagesByType(
    Map<String, List<WeighbridgeImageFile>> imageGroups,
    WeighbridgeDuplicateConfig config,
  ) {
    final imagesByType = <String, List<WeighbridgeImageFile>>{};

    for (final recordImages in imageGroups.values) {
      for (final image in recordImages) {
        final fileName = image.fileName.toLowerCase();
        
        String? imageType;
        if (config.compareCarFrontImages && fileName.contains('车前照片')) {
          imageType = '车前照片';
        } else if (config.compareCarLeftImages && fileName.contains('左侧照片')) {
          imageType = '左侧照片';
        } else if (config.compareCarRightImages && fileName.contains('右侧照片')) {
          imageType = '右侧照片';
        } else if (config.compareCarPlateImages && fileName.contains('车牌照片')) {
          imageType = '车牌照片';
        }

        if (imageType != null) {
          imagesByType.putIfAbsent(imageType, () => []).add(image);
        }
      }
    }

    return imagesByType;
  }

  /// 对比两张图片的相似度（优化版本）
  Future<double> _compareImages(String imagePath1, String imagePath2) async {
    try {
      // 检查共享缓存 - 使用WeighbridgeImageSimilarityService的静态缓存
      final cacheKey = '${imagePath1}:${imagePath2}';
      final reverseCacheKey = '${imagePath2}:${imagePath1}';
      
      // 访问共享缓存
      final sharedCache = WeighbridgeImageSimilarityService.similarityCache;
      if (sharedCache.containsKey(cacheKey)) {
        return sharedCache[cacheKey]!;
      }
      if (sharedCache.containsKey(reverseCacheKey)) {
        return sharedCache[reverseCacheKey]!;
      }

      // 使用Process.run替代Process.start，提高性能
      ProcessResult result;
      
      // 优先使用打包的可执行文件
      String? executablePath;
      final possiblePaths = [
        path.join(Directory.current.path, 'bundled_python', 'weighbridge_image_similarity'),
        path.join(Directory.current.path, '..', 'Resources', 'bundled_python', 'weighbridge_image_similarity'),
        path.join(path.dirname(Platform.resolvedExecutable), '..', 'Resources', 'bundled_python', 'weighbridge_image_similarity'),
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
      
      if (executableFile != null) {
        result = await Process.run(
          executablePath!,
          [imagePath1, imagePath2],
          workingDirectory: Directory.current.path,
          environment: {
            'PATH': '/usr/local/bin:/usr/bin:/bin',
          },
        );
      } else {
        result = await Process.run(
          '/usr/bin/python3',
          [
            path.join(Directory.current.path, 'python_scripts', 'weighbridge_image_similarity.py'),
            imagePath1,
            imagePath2,
          ],
          workingDirectory: Directory.current.path,
          environment: {
            'PATH': '/usr/local/bin:/usr/bin:/bin',
            'PYTHONPATH': path.join(Directory.current.path, '.venv', 'lib', 'python3.9', 'site-packages'),
          },
        );
      }

      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        final similarity = double.tryParse(output) ?? 0.0;
        
        // 缓存结果到共享缓存
        _addToSharedCache(cacheKey, similarity);
        
        return similarity;
      } else {
        _logger.e('Python脚本执行失败: ${result.stderr}');
        return 0.0;
      }
    } catch (e) {
      _logger.e('执行图片对比时出错: $e');
      return 0.0;
    }
  }

  /// 添加到共享缓存
  void _addToSharedCache(String key, double value) {
    final sharedCache = WeighbridgeImageSimilarityService.similarityCache;
    const maxCacheSize = 10000;
    
    // 如果缓存已满，删除一些旧条目
    if (sharedCache.length >= maxCacheSize) {
      final keysToRemove = sharedCache.keys.take(maxCacheSize ~/ 4).toList();
      for (final keyToRemove in keysToRemove) {
        sharedCache.remove(keyToRemove);
      }
    }
    
    sharedCache[key] = value;
  }

  Future<WeighbridgeDuplicateResult?> _compareImagesParallel(
    WeighbridgeImageFile image1,
    WeighbridgeImageFile image2,
    String imageType,
    WeighbridgeDuplicateConfig config,
    List<DetectionResult> detectionResults,
  ) async {
    try {
      final similarity = await _compareImages(image1.filePath, image2.filePath);
      
      // 为每次比对添加详细的相似率日志输出
      final image1Name = path.basename(image1.filePath);
      final image2Name = path.basename(image2.filePath);
      _logger.d('图片对比: $image1Name vs $image2Name, 相似度: ${(similarity * 100).toStringAsFixed(2)}%');
      _logService?.debug('图片对比: $image1Name vs $image2Name, 相似度: ${(similarity * 100).toStringAsFixed(2)}%');
      
      // 创建检测结果记录
      final detectionResult = DetectionResult(
        id: const Uuid().v4(),
        detectionType: 'duplicate',
        detectionTime: DateTime.now(),
        imagePath1: image1.filePath,
        imagePath2: image2.filePath,
        recordName1: image1.recordName,
        recordName2: image2.recordName,
        similarity: similarity,
        imageType: imageType,
        level: SimilarityStandards.getSimilarityLevel(imageType, similarity),
      );
      detectionResults.add(detectionResult);
      
      if (similarity >= config.similarityThreshold) {
        final result = WeighbridgeDuplicateResult(
          imagePath1: image1.filePath,
          imagePath2: image2.filePath,
          recordName1: image1.recordName,
          recordName2: image2.recordName,
          similarity: similarity,
          imageType: imageType,
          detectionTime: DateTime.now(),
        );
        
        _logger.w('⚠️ 发现重复图片: ${image1.recordName} vs ${image2.recordName}, 相似度: ${(similarity * 100).toStringAsFixed(1)}%');
        _logService?.warning('⚠️ 发现重复过磅图片: ${image1.recordName} vs ${image2.recordName}, 相似度: ${(similarity * 100).toStringAsFixed(1)}%');
        return result;
      } else {
        _logger.i('✓ 图片对比正常: ${image1.recordName} vs ${image2.recordName}, 相似度: ${(similarity * 100).toStringAsFixed(1)}%');
        _logService?.info('✓ 图片对比正常: ${image1.recordName} vs ${image2.recordName}, 相似度: ${(similarity * 100).toStringAsFixed(1)}%');
        return null;
      }
    } catch (e) {
      _logger.e('对比图片时出错: ${image1.filePath} vs ${image2.filePath}, 错误: $e');
      _logService?.error('对比过磅图片时出错: $e');
      return null;
    }
  }
}

// 过磅图片文件信息
class WeighbridgeImageFile {
  final String filePath;
  final String recordName;
  final String fileName;

  const WeighbridgeImageFile({
    required this.filePath,
    required this.recordName,
    required this.fileName,
  });
}

// Provider for weighbridge duplicate detection service
final weighbridgeDuplicateDetectionServiceProvider = Provider<WeighbridgeDuplicateDetectionService>((ref) {
  return WeighbridgeDuplicateDetectionService();
}); 