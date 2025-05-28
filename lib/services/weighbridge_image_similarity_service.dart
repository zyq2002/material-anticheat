import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import 'log_service.dart';

// part 'weighbridge_image_similarity_service.g.dart';

// 过磅可疑图片结果
class WeighbridgeSuspiciousImageResult {
  final String imagePath;
  final String recordName;
  final String imageType;
  final double similarity;
  final String matchImagePath;
  final String matchRecordName;
  final DateTime detectionTime;

  const WeighbridgeSuspiciousImageResult({
    required this.imagePath,
    required this.recordName,
    required this.imageType,
    required this.similarity,
    required this.matchImagePath,
    required this.matchRecordName,
    required this.detectionTime,
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

  WeighbridgeImageSimilarityService() {
    // _logService will be set when needed
  }

  /// 检测可疑过磅图片
  Future<List<WeighbridgeSuspiciousImageResult>> detectSuspiciousImages(double threshold) async {
    try {
      _logger.i('开始过磅可疑图片检测，阈值: ${(threshold).toStringAsFixed(0)}%');

      // 获取今日过磅图片
      final todayImages = await _getTodayWeighbridgeImages();
      
      if (todayImages.isEmpty) {
        return [];
      }

      _logger.i('找到今日过磅图片 ${todayImages.length} 张');

      final suspiciousResults = <WeighbridgeSuspiciousImageResult>[];
      
      // 按图片类型分组
      final imagesByType = <String, List<WeighbridgeImageInfo>>{};
      for (final image in todayImages) {
        final type = _getImageType(image.fileName);
        if (type != null) {
          imagesByType.putIfAbsent(type, () => []).add(image);
        }
      }

      // 对每种类型的图片进行检测
      for (final typeEntry in imagesByType.entries) {
        final imageType = typeEntry.key;
        final images = typeEntry.value;
        
        if (images.length < 2) continue;

        _logger.i('开始检测 $imageType，共 ${images.length} 张');

        // 两两对比
        for (int i = 0; i < images.length - 1; i++) {
          for (int j = i + 1; j < images.length; j++) {
            final image1 = images[i];
            final image2 = images[j];

            // 避免同一记录内的图片对比
            if (image1.recordName == image2.recordName) continue;

            try {
              final similarity = await _compareImages(image1.filePath, image2.filePath);
              
              // 为每次比对添加详细的相似率日志输出
              final image1Name = path.basename(image1.filePath);
              final image2Name = path.basename(image2.filePath);
              _logger.d('图片对比: $image1Name vs $image2Name, 相似度: ${(similarity * 100).toStringAsFixed(2)}%');
              
              if (similarity >= threshold / 100.0) {
                // 添加两个可疑结果
                suspiciousResults.add(WeighbridgeSuspiciousImageResult(
                  imagePath: image1.filePath,
                  recordName: image1.recordName,
                  imageType: imageType,
                  similarity: similarity,
                  matchImagePath: image2.filePath,
                  matchRecordName: image2.recordName,
                  detectionTime: DateTime.now(),
                ));

                suspiciousResults.add(WeighbridgeSuspiciousImageResult(
                  imagePath: image2.filePath,
                  recordName: image2.recordName,
                  imageType: imageType,
                  similarity: similarity,
                  matchImagePath: image1.filePath,
                  matchRecordName: image1.recordName,
                  detectionTime: DateTime.now(),
                ));

                _logger.w('⚠️ 发现可疑过磅图片: ${image1.recordName} vs ${image2.recordName}, 相似度: ${(similarity * 100).toStringAsFixed(1)}%');
              } else {
                _logger.i('✓ 图片对比正常: ${image1.recordName} vs ${image2.recordName}, 相似度: ${(similarity * 100).toStringAsFixed(1)}%');
              }
            } catch (e) {
              _logger.e('❌ 对比过磅图片时出错: ${image1.filePath} vs ${image2.filePath}, 错误: $e');
            }
          }
        }
      }

      // 去除重复并按相似度降序排序
      final uniqueResults = <String, WeighbridgeSuspiciousImageResult>{};
      for (final result in suspiciousResults) {
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

  /// 获取今日过磅图片
  Future<List<WeighbridgeImageInfo>> _getTodayWeighbridgeImages() async {
    final weighbridgeImagesPath = await _getWeighbridgeImagesPath();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final todayDir = Directory(path.join(weighbridgeImagesPath, todayStr));
    if (!await todayDir.exists()) {
      return [];
    }

    final images = <WeighbridgeImageInfo>[];

    await for (final recordEntity in todayDir.list(followLinks: false)) {
      if (recordEntity is Directory) {
        final recordName = path.basename(recordEntity.path);

        await for (final imageEntity in recordEntity.list(followLinks: false)) {
          if (imageEntity is File) {
            final extension = path.extension(imageEntity.path).toLowerCase();
            if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension)) {
              images.add(WeighbridgeImageInfo(
                filePath: imageEntity.path,
                fileName: path.basename(imageEntity.path),
                recordName: recordName,
              ));
            }
          }
        }
      }
    }

    return images;
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

  /// 获取图片类型
  String? _getImageType(String fileName) {
    final name = fileName.toLowerCase();
    if (name.contains('车前照片')) return '车前照片';
    if (name.contains('左侧照片')) return '左侧照片';
    if (name.contains('右侧照片')) return '右侧照片';
    if (name.contains('车牌照片')) return '车牌照片';
    return null;
  }

  /// 对比两张图片的相似度
  Future<double> _compareImages(String imagePath1, String imagePath2) async {
    try {
      // 优先使用打包的可执行文件，如果不存在则使用Python脚本
      String? executablePath;
      
      // 检查多个可能的路径
      final possiblePaths = [
        // 开发环境路径
        path.join(Directory.current.path, 'bundled_python', 'weighbridge_image_similarity'),
        // macOS应用包内路径
        path.join(Directory.current.path, '..', 'Resources', 'bundled_python', 'weighbridge_image_similarity'),
        // 备用路径
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
      
      ProcessResult result;
      
      if (executableFile != null) {
        // 使用打包的可执行文件（推荐，无需Python环境）
        final process = await Process.start(
          executablePath!,
          [imagePath1, imagePath2],
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
        
        final stdout = await process.stdout.transform(const SystemEncoding().decoder).join();
        final stderr = await process.stderr.transform(const SystemEncoding().decoder).join();
        final exitCode = await process.exitCode;
        
        result = ProcessResult(process.pid, exitCode, stdout, stderr);
      }

      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        return double.tryParse(output) ?? 0.0;
      } else {
        _logger.e('Python脚本执行失败: ${result.stderr}');
        return 0.0;
      }
    } catch (e) {
      _logger.e('执行图片对比时出错: $e');
      return 0.0;
    }
  }
}

// 过磅图片信息
class WeighbridgeImageInfo {
  final String filePath;
  final String fileName;
  final String recordName;

  const WeighbridgeImageInfo({
    required this.filePath,
    required this.fileName,
    required this.recordName,
  });
}

/// Provider for suspicious weighbridge images
final weighbridgeSuspiciousImagesProvider = FutureProvider.family<List<WeighbridgeSuspiciousImageResult>, double>((ref, threshold) async {
  final service = WeighbridgeImageSimilarityService();
  return service.detectSuspiciousImages(threshold);
}); 