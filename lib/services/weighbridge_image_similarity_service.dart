import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import 'log_service.dart';
import '../models/weighbridge_suspicious_image_result.dart';

// part 'weighbridge_image_similarity_service.g.dart';

class WeighbridgeImageInfo {
  final String filePath;
  final String fileName;
  final String recordName;
  final DateTime dateTime;

  const WeighbridgeImageInfo({
    required this.filePath,
    required this.fileName,
    required this.recordName,
    required this.dateTime,
  });
}

class WeighbridgeImageSimilarityService {
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
  
  // Isolate池相关
  static const int _isolatePoolSize = 4; // 使用4个Isolate进行并行处理
  final List<Isolate?> _isolatePool = List.filled(_isolatePoolSize, null);
  final List<SendPort?> _sendPorts = List.filled(_isolatePoolSize, null);
  final List<bool> _isolateReady = List.filled(_isolatePoolSize, false);
  int _currentIsolateIndex = 0;
  bool _poolInitialized = false;

  // 智能缓存 - 使用静态变量确保全局共享
  static final Map<String, double> _similarityCache = <String, double>{};
  static const int _maxCacheSize = 10000; // 最大缓存条目数

  // 添加公共方法来访问缓存
  static Map<String, double> get similarityCache => _similarityCache;
  
  // 添加到缓存的公共方法
  static void addToCache(String key, double value) {
    // 如果缓存已满，删除一些旧条目
    if (_similarityCache.length >= _maxCacheSize) {
      final keysToRemove = _similarityCache.keys.take(_maxCacheSize ~/ 4).toList();
      for (final keyToRemove in keysToRemove) {
        _similarityCache.remove(keyToRemove);
      }
    }
    
    _similarityCache[key] = value;
  }

  WeighbridgeImageSimilarityService() {
    _initializeIsolatePool();
  }

  /// 初始化Isolate池
  Future<void> _initializeIsolatePool() async {
    if (_poolInitialized) return;

    _logger.i('正在初始化Isolate池，大小: $_isolatePoolSize');

    final futures = <Future<void>>[];
    for (int i = 0; i < _isolatePoolSize; i++) {
      futures.add(_initializeIsolate(i));
    }

    await Future.wait(futures);
    _poolInitialized = true;
    _logger.i('Isolate池初始化完成');
  }

  /// 初始化单个Isolate
  Future<void> _initializeIsolate(int index) async {
    try {
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(_isolateEntryPoint, receivePort.sendPort);
      
      _isolatePool[index] = isolate;
      
      // 等待Isolate发送SendPort
      final sendPort = await receivePort.first as SendPort;
      _sendPorts[index] = sendPort;
      _isolateReady[index] = true;
      
      _logger.d('Isolate $index 初始化完成');
    } catch (e) {
      _logger.e('初始化Isolate $index 失败: $e');
      _isolateReady[index] = false;
    }
  }

  /// Isolate入口点
  static void _isolateEntryPoint(SendPort mainSendPort) async {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    await for (final message in receivePort) {
      if (message is Map<String, dynamic>) {
        final imagePath1 = message['imagePath1'] as String;
        final imagePath2 = message['imagePath2'] as String;
        final responsePort = message['responsePort'] as SendPort;

        try {
          final similarity = await _compareImagesInIsolate(imagePath1, imagePath2);
          responsePort.send({
            'success': true,
            'similarity': similarity,
          });
        } catch (e) {
          responsePort.send({
            'success': false,
            'error': e.toString(),
          });
        }
      }
    }
  }

  /// 在Isolate中对比图片
  static Future<double> _compareImagesInIsolate(String imagePath1, String imagePath2) async {
    try {
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
        return double.tryParse(output) ?? 0.0;
      } else {
        throw Exception('Python脚本执行失败: ${result.stderr}');
      }
    } catch (e) {
      throw Exception('执行图片对比时出错: $e');
    }
  }

  /// 检测可疑过磅图片（优化版本，支持并行处理）
  Future<List<WeighbridgeSuspiciousImageResult>> detectSuspiciousImages(double threshold) async {
    try {
      _logger.i('开始过磅可疑图片检测，阈值: ${threshold.toStringAsFixed(0)}%');

      // 获取今日过磅图片
      final todayImages = await _getTodayWeighbridgeImages();
      
      if (todayImages.isEmpty) {
        return [];
      }

      _logger.i('找到今日过磅图片 ${todayImages.length} 张');

      // 按图片类型分组
      final imagesByType = <String, List<WeighbridgeImageInfo>>{};
      for (final image in todayImages) {
        final type = _getImageType(image.fileName);
        if (type != null) {
          imagesByType.putIfAbsent(type, () => []).add(image);
        }
      }

      // 收集所有需要对比的图片对
      final comparisonTasks = <Future<WeighbridgeSuspiciousImageResult?>>[];
      
      for (final typeEntry in imagesByType.entries) {
        final imageType = typeEntry.key;
        final images = typeEntry.value;
        
        if (images.length < 2) continue;

        _logger.i('准备检测 $imageType，共 ${images.length} 张');

        // 生成所有图片对的对比任务
        for (int i = 0; i < images.length - 1; i++) {
          for (int j = i + 1; j < images.length; j++) {
            final image1 = images[i];
            final image2 = images[j];

            // 避免同一记录内的图片对比
            if (image1.recordName == image2.recordName) continue;

            // 添加并行对比任务
            comparisonTasks.add(_compareImagesParallel(
              image1, 
              image2, 
              imageType, 
              threshold / 100.0,
            ));
          }
        }
      }

      _logger.i('总计需要对比 ${comparisonTasks.length} 个图片对');

      // 使用批量并行处理，避免过多并发
      final batchSize = 6; // 每批处理6个对比任务，与Isolate池大小匹配
      final allResults = <WeighbridgeSuspiciousImageResult>[];
      
      for (int i = 0; i < comparisonTasks.length; i += batchSize) {
        final batchEnd = (i + batchSize < comparisonTasks.length) 
            ? i + batchSize 
            : comparisonTasks.length;
        
        final batchTasks = comparisonTasks.sublist(i, batchEnd);
        
        _logger.i('正在处理第 ${(i ~/ batchSize) + 1} 批，共 ${batchTasks.length} 个对比任务');
        
        // 并行执行当前批次的任务
        final batchResults = await Future.wait(batchTasks);
        
        // 收集非null结果
        for (final result in batchResults) {
          if (result != null) {
            allResults.add(result);
          }
        }
        
        // 短暂暂停，避免过度占用系统资源
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // 去除重复并按相似度降序排序
      final uniqueResults = <String, WeighbridgeSuspiciousImageResult>{};
      for (final result in allResults) {
        final key = result.imagePath;
        if (!uniqueResults.containsKey(key) || 
            result.similarity > uniqueResults[key]!.similarity) {
          uniqueResults[key] = result;
        }
      }

      final finalResults = uniqueResults.values.toList();
      finalResults.sort((a, b) => b.similarity.compareTo(a.similarity));

      _logger.i('过磅可疑图片检测完成，发现 ${finalResults.length} 张可疑图片');

      return finalResults;

    } catch (e) {
      _logger.e('过磅可疑图片检测失败: $e');
      return [];
    }
  }

  /// 并行对比两张图片（优化版本）
  Future<WeighbridgeSuspiciousImageResult?> _compareImagesParallel(
    WeighbridgeImageInfo image1,
    WeighbridgeImageInfo image2,
    String imageType,
    double threshold,
  ) async {
    try {
      // 检查智能缓存
      final cacheKey = '${image1.filePath}:${image2.filePath}';
      final reverseCacheKey = '${image2.filePath}:${image1.filePath}';
      
      double? similarity = _similarityCache[cacheKey] ?? _similarityCache[reverseCacheKey];
      
      if (similarity == null) {
        similarity = await _compareImagesWithIsolate(image1.filePath, image2.filePath);
        
        // 智能缓存管理
        WeighbridgeImageSimilarityService.addToCache(cacheKey, similarity);
      }
      
      // 详细日志
      final image1Name = path.basename(image1.filePath);
      final image2Name = path.basename(image2.filePath);
      _logger.d('图片对比: $image1Name vs $image2Name, 相似度: ${(similarity * 100).toStringAsFixed(2)}%');
      
      if (similarity >= threshold) {
        _logger.w('⚠️ 发现可疑过磅图片: ${image1.recordName} vs ${image2.recordName}, 相似度: ${(similarity * 100).toStringAsFixed(1)}%');
        
        return WeighbridgeSuspiciousImageResult(
          imagePath: image1.filePath,
          recordName: image1.recordName,
          imageType: imageType,
          similarity: similarity,
          matchImagePath: image2.filePath,
          matchRecordName: image2.recordName,
          detectionTime: DateTime.now(),
        );
      } else {
        _logger.i('✓ 图片对比正常: ${image1.recordName} vs ${image2.recordName}, 相似度: ${(similarity * 100).toStringAsFixed(1)}%');
        return null;
      }
    } catch (e) {
      _logger.e('❌ 对比过磅图片时出错: ${image1.filePath} vs ${image2.filePath}, 错误: $e');
      return null;
    }
  }

  /// 使用Isolate对比图片（优化版本）
  Future<double> _compareImagesWithIsolate(String imagePath1, String imagePath2) async {
    await _initializeIsolatePool();
    
    // 轮询选择可用的Isolate
    int isolateIndex = _currentIsolateIndex;
    _currentIsolateIndex = (_currentIsolateIndex + 1) % _isolatePoolSize;
    
    // 寻找可用的Isolate
    int attempts = 0;
    while (!_isolateReady[isolateIndex] && attempts < _isolatePoolSize) {
      isolateIndex = (isolateIndex + 1) % _isolatePoolSize;
      attempts++;
    }
    
    final sendPort = _sendPorts[isolateIndex];
    if (sendPort == null || !_isolateReady[isolateIndex]) {
      // 如果没有可用的Isolate，回退到主线程处理
      _logger.w('没有可用的Isolate，回退到主线程处理');
      return _compareImagesInIsolate(imagePath1, imagePath2);
    }

    final responsePort = ReceivePort();
    
    sendPort.send({
      'imagePath1': imagePath1,
      'imagePath2': imagePath2,
      'responsePort': responsePort.sendPort,
    });

    final response = await responsePort.first as Map<String, dynamic>;
    
    if (response['success'] == true) {
      return response['similarity'] as double;
    } else {
      throw Exception(response['error']);
    }
  }

  /// 获取今日过磅图片
  Future<List<WeighbridgeImageInfo>> _getTodayWeighbridgeImages() async {
    final images = <WeighbridgeImageInfo>[];
    
    try {
      final today = DateTime.now();
      final todayStr = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final weighbridgeDir = Directory('pic/weighbridge/$todayStr');
      
      if (!await weighbridgeDir.exists()) {
        _logger.w('今日过磅图片目录不存在: ${weighbridgeDir.path}');
        return images;
      }

      await for (final entity in weighbridgeDir.list()) {
        if (entity is Directory) {
          final recordName = path.basename(entity.path);
          
          await for (final file in entity.list()) {
            if (file is File && _isImageFile(file.path)) {
              images.add(WeighbridgeImageInfo(
                filePath: file.path,
                fileName: path.basename(file.path),
                recordName: recordName,
                dateTime: today,
              ));
            }
          }
        }
      }
      
      _logger.i('找到今日过磅图片 ${images.length} 张');
      
    } catch (e) {
      _logger.e('获取今日过磅图片失败: $e');
    }
    
    return images;
  }

  /// 判断是否为图片文件
  bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.bmp', '.gif', '.webp'].contains(extension);
  }

  /// 根据文件名获取图片类型
  String? _getImageType(String fileName) {
    final lowerFileName = fileName.toLowerCase();
    
    if (lowerFileName.contains('车前照片')) {
      return '车前照片';
    } else if (lowerFileName.contains('左侧照片')) {
      return '左侧照片';
    } else if (lowerFileName.contains('右侧照片')) {
      return '右侧照片';
    } else if (lowerFileName.contains('车牌照片')) {
      return '车牌照片';
    }
    
    return null;
  }

  /// 清理资源
  Future<void> dispose() async {
    _logger.i('正在清理Isolate池资源');
    
    for (int i = 0; i < _isolatePoolSize; i++) {
      final isolate = _isolatePool[i];
      if (isolate != null) {
        isolate.kill(priority: Isolate.immediate);
        _isolatePool[i] = null;
        _sendPorts[i] = null;
        _isolateReady[i] = false;
      }
    }
    
    _poolInitialized = false;
    _logger.i('Isolate池资源清理完成');
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _similarityCache.length,
      'maxCacheSize': _maxCacheSize,
      'cacheHitRate': _similarityCache.length > 0 ? 
          (_similarityCache.length / (_similarityCache.length + 1000)).toStringAsFixed(2) : '0.00',
    };
  }

  /// 清理缓存
  void clearCache() {
    _similarityCache.clear();
    _logger.i('相似度缓存已清理');
  }
}

/// Provider for suspicious weighbridge images
final weighbridgeSuspiciousImagesProvider = FutureProvider.family<List<WeighbridgeSuspiciousImageResult>, double>((ref, threshold) async {
  final service = WeighbridgeImageSimilarityService();
  return service.detectSuspiciousImages(threshold);
}); 