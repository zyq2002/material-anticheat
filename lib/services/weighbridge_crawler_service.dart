import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../models/weighbridge_info.dart';
import 'api_service.dart';
import 'log_service.dart';

part 'weighbridge_crawler_service.g.dart';

class WeighbridgeCrawlerState {
  final bool isRunning;
  final int totalTasks;
  final int completedTasks;
  final int failedTasks;
  final double progress;
  final String currentTask;
  final String authToken;
  final String cookie;
  final WeighbridgeRetrySettings retrySettings;

  const WeighbridgeCrawlerState({
    this.isRunning = false,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.failedTasks = 0,
    this.progress = 0.0,
    this.currentTask = '准备就绪',
    this.authToken = '',
    this.cookie = '',
    this.retrySettings = const WeighbridgeRetrySettings(),
  });

  WeighbridgeCrawlerState copyWith({
    bool? isRunning,
    int? totalTasks,
    int? completedTasks,
    int? failedTasks,
    double? progress,
    String? currentTask,
    String? authToken,
    String? cookie,
    WeighbridgeRetrySettings? retrySettings,
  }) {
    return WeighbridgeCrawlerState(
      isRunning: isRunning ?? this.isRunning,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      failedTasks: failedTasks ?? this.failedTasks,
      progress: progress ?? this.progress,
      currentTask: currentTask ?? this.currentTask,
      authToken: authToken ?? this.authToken,
      cookie: cookie ?? this.cookie,
      retrySettings: retrySettings ?? this.retrySettings,
    );
  }
}

class WeighbridgeRetrySettings {
  final int maxRetries;
  final Duration retryDelay;
  final int delayBetweenImagesMs;

  const WeighbridgeRetrySettings({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.delayBetweenImagesMs = 100,
  });

  WeighbridgeRetrySettings copyWith({
    int? maxRetries,
    Duration? retryDelay,
    int? delayBetweenImagesMs,
  }) {
    return WeighbridgeRetrySettings(
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      delayBetweenImagesMs: delayBetweenImagesMs ?? this.delayBetweenImagesMs,
    );
  }
}

@riverpod
class WeighbridgeCrawlerService extends _$WeighbridgeCrawlerService {
  Timer? _timer;
  bool _isRunning = false;
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

  @override
  WeighbridgeCrawlerState build() {
    _logService = ref.read(logServiceProvider.notifier);
    return const WeighbridgeCrawlerState();
  }

  /// 加载设置
  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'auth_token': prefs.getString('weighbridge_auth_token') ?? '',
      'cookie': prefs.getString('weighbridge_cookie') ?? '',
      'interval_minutes': prefs.getInt('weighbridge_interval_minutes') ?? 30,
      'save_path': prefs.getString('weighbridge_save_path') ?? '',
      'max_retries': prefs.getInt('weighbridge_max_retries') ?? 3,
      'retry_delay_seconds': prefs.getInt('weighbridge_retry_delay_seconds') ?? 2,
      'delay_between_images_ms': prefs.getInt('weighbridge_delay_between_images_ms') ?? 100,
    };
  }

  /// 保存设置
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (settings['auth_token'] != null) {
      await prefs.setString('weighbridge_auth_token', settings['auth_token']);
    }
    if (settings['cookie'] != null) {
      await prefs.setString('weighbridge_cookie', settings['cookie']);
    }
    if (settings['interval_minutes'] != null) {
      await prefs.setInt('weighbridge_interval_minutes', settings['interval_minutes']);
    }
    if (settings['save_path'] != null) {
      await prefs.setString('weighbridge_save_path', settings['save_path']);
    }
    if (settings['max_retries'] != null) {
      await prefs.setInt('weighbridge_max_retries', settings['max_retries']);
    }
    if (settings['retry_delay_seconds'] != null) {
      await prefs.setInt('weighbridge_retry_delay_seconds', settings['retry_delay_seconds']);
    }
    if (settings['delay_between_images_ms'] != null) {
      await prefs.setInt('weighbridge_delay_between_images_ms', settings['delay_between_images_ms']);
    }
  }

  /// 设置保存路径
  void setSavePath(String path) {
    saveSettings({'save_path': path});
  }

  /// 设置重试配置
  void setRetrySettings(WeighbridgeRetrySettings settings) {
    state = state.copyWith(retrySettings: settings);
    
    saveSettings({
      'max_retries': settings.maxRetries,
      'retry_delay_seconds': settings.retryDelay.inSeconds,
      'delay_between_images_ms': settings.delayBetweenImagesMs,
    });
  }

  /// 启动过磅爬虫
  Future<void> startCrawler({
    required String authToken,
    required String cookie,
    required DateTime selectedDate,
    required int intervalMinutes,
  }) async {
    if (_isRunning) {
      _logger.w('过磅爬虫已经在运行中');
      return;
    }

    _isRunning = true;
    state = state.copyWith(
      isRunning: true,
      authToken: authToken,
      cookie: cookie,
      currentTask: '正在启动过磅爬虫...',
    );

    // 保存设置
    await saveSettings({
      'auth_token': authToken,
      'cookie': cookie,
      'interval_minutes': intervalMinutes,
    });

    // 设置API认证信息
    final apiService = ref.read(apiServiceProvider);
    apiService.setFullAuthInfo(authToken, cookie);

    _logger.i('过磅爬虫已启动，间隔: $intervalMinutes分钟');
    _logService?.info('过磅爬虫已启动，间隔: $intervalMinutes分钟');

    // 立即执行一次爬取
    await _performCrawling(selectedDate);

    // 设置定时器
    _timer = Timer.periodic(Duration(minutes: intervalMinutes), (timer) async {
      if (_isRunning) {
        await _performCrawling(selectedDate);
      }
    });
  }

  /// 停止过磅爬虫
  void stopCrawler() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    state = state.copyWith(
      isRunning: false,
      currentTask: '已停止',
    );
    _logger.i('过磅爬虫已停止');
    _logService?.info('过磅爬虫已停止');
  }

  /// 批量下载过磅图片
  Future<void> batchDownloadImages({
    required String authToken,
    required String cookie,
    required DateTime startDate,
    required DateTime endDate,
    int delayBetweenDaysSeconds = 5,
    int delayBetweenImagesMs = 500,
  }) async {
    if (_isRunning) {
      _logger.w('过磅爬虫已在运行中');
      return;
    }

    _isRunning = true;
    state = state.copyWith(isRunning: true);

    try {
      // 设置API认证信息
      final apiService = ref.read(apiServiceProvider);
      apiService.setFullAuthInfo(authToken, cookie);

      // 计算日期范围
      final totalDays = endDate.difference(startDate).inDays + 1;
      int processedDays = 0;
      int totalSuccessful = 0;
      int totalFailed = 0;

             _logger.i('开始批量下载过磅图片，日期范围: $startDate 至 $endDate，总计 $totalDays 天');
       _logService?.info('开始批量下载过磅图片，日期范围: ${_formatDate(startDate)} 至 ${_formatDate(endDate)}，总计 $totalDays 天');

      DateTime currentDate = startDate;
      
      while (currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
        processedDays++;
        final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);
        
        state = state.copyWith(
          currentTask: '正在处理第 $processedDays/$totalDays 天: $dateStr',
          progress: processedDays / totalDays,
        );

        _logger.i('开始处理日期: $dateStr ($processedDays/$totalDays)');
        _logService?.info('开始处理日期: $dateStr ($processedDays/$totalDays)');

        try {
          final result = await _performSingleDayCrawling(
            currentDate, 
            delayBetweenImagesMs,
          );
          
          totalSuccessful += result['successful'] as int;
          totalFailed += result['failed'] as int;

          _logger.i('日期 $dateStr 处理完成: 成功 ${result['successful']}，失败 ${result['failed']}');
          _logService?.success('日期 $dateStr 处理完成: 成功 ${result['successful']}，失败 ${result['failed']}');

          // 如果不是最后一天，休息指定时间
          if (processedDays < totalDays && delayBetweenDaysSeconds > 0) {
            state = state.copyWith(
              currentTask: '$dateStr 处理完成，休息 $delayBetweenDaysSeconds 秒...',
            );
            _logService?.info('休息 $delayBetweenDaysSeconds 秒后继续处理下一天...');
            await Future.delayed(Duration(seconds: delayBetweenDaysSeconds));
          }

        } catch (e) {
          _logger.e('处理日期 $dateStr 时出错: $e');
          _logService?.error('处理日期 $dateStr 时出错: $e');
          state = state.copyWith(
            currentTask: '处理 $dateStr 时出错: $e',
          );
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }

      state = state.copyWith(
        currentTask: '批量下载完成! 总计成功: $totalSuccessful, 失败: $totalFailed',
        progress: 1.0,
        completedTasks: totalSuccessful,
        failedTasks: totalFailed,
      );

      _logger.i('过磅批量下载完成 - 总计成功: $totalSuccessful, 失败: $totalFailed');
      _logService?.success('过磅批量下载完成 - 总计成功: $totalSuccessful, 失败: $totalFailed');

    } catch (e) {
      _logger.e('过磅批量下载过程出错: $e');
      _logService?.error('过磅批量下载过程出错: $e');
      state = state.copyWith(
        currentTask: '批量下载错误: $e',
      );
    } finally {
      _isRunning = false;
      state = state.copyWith(isRunning: false);
    }
  }

  /// 处理单天的过磅爬取任务
  Future<Map<String, int>> _performSingleDayCrawling(
    DateTime date, 
    int delayBetweenImagesMs,
  ) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final beginTime = '$dateStr 00:00:00';
    final endTime = '$dateStr 23:59:59';

    // 获取过磅记录列表
    final apiService = ref.read(apiServiceProvider);
    final weighbridgeList = await apiService.getWeighbridgeList(
      beginTime: beginTime,
      endTime: endTime,
    );

    if (weighbridgeList.isEmpty) {
      _logger.i('$dateStr 当天没有过磅记录');
      _logService?.info('$dateStr 当天没有过磅记录');
      return {'successful': 0, 'failed': 0};
    }

    _logger.i('$dateStr 获取到 ${weighbridgeList.length} 个过磅记录');
    _logService?.info('$dateStr 获取到 ${weighbridgeList.length} 个过磅记录');

    // 获取保存路径
    final saveBasePath = await _getSaveBasePath();
    final dateFolderPath = path.join(saveBasePath, 'weighbridge', dateStr);

    int successful = 0;
    int failed = 0;

    // 处理每个过磅记录
    for (int i = 0; i < weighbridgeList.length; i++) {
      final weighbridgeInfo = weighbridgeList[i];
      
      try {
        _logger.d('开始处理过磅记录 ${i + 1}/${weighbridgeList.length}: ${weighbridgeInfo.reportInfoId}');
        
        await _downloadWeighbridgeImages(
          weighbridgeInfo: weighbridgeInfo,
          baseSavePath: dateFolderPath,
          delayBetweenImagesMs: delayBetweenImagesMs,
        );

        successful++;
        _logService?.success('过磅记录 ${weighbridgeInfo.reportInfoId} 处理完成 (${i + 1}/${weighbridgeList.length})');
        
      } catch (e) {
        failed++;
        _logger.e('过磅记录 ${weighbridgeInfo.reportInfoId} 处理失败: $e');
        _logService?.error('过磅记录 ${weighbridgeInfo.reportInfoId} 处理失败: $e');
      }
    }

    return {'successful': successful, 'failed': failed};
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 执行过磅爬取任务
  Future<void> _performCrawling(DateTime selectedDate) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final beginTime = '$dateStr 00:00:00';
      final endTime = '$dateStr 23:59:59';

      state = state.copyWith(
        currentTask: '获取过磅数据列表...',
        progress: 0.0,
        completedTasks: 0,
        failedTasks: 0,
      );

      // 获取过磅记录列表
      final apiService = ref.read(apiServiceProvider);
      final weighbridgeList = await apiService.getWeighbridgeList(
        beginTime: beginTime,
        endTime: endTime,
      );

      if (weighbridgeList.isEmpty) {
        _logger.i('$dateStr 当天没有过磅记录');
        _logService?.info('$dateStr 当天没有过磅记录');
        state = state.copyWith(
          currentTask: '$dateStr 当天没有过磅记录',
          totalTasks: 0,
        );
        return;
      }

      state = state.copyWith(
        totalTasks: weighbridgeList.length,
        currentTask: '开始下载 ${weighbridgeList.length} 个过磅记录的图片...',
      );

      // 获取保存路径
      final saveBasePath = await _getSaveBasePath();
      final dateFolderPath = path.join(saveBasePath, 'weighbridge', dateStr);

      int completed = 0;
      int failed = 0;

      // 处理每个过磅记录
      for (final weighbridgeInfo in weighbridgeList) {
        try {
          state = state.copyWith(
            currentTask: '下载过磅记录 ${weighbridgeInfo.onlyNumber} 的图片...',
          );

          await _downloadWeighbridgeImages(
            weighbridgeInfo: weighbridgeInfo,
            baseSavePath: dateFolderPath,
            delayBetweenImagesMs: state.retrySettings.delayBetweenImagesMs,
          );

          completed++;
          _logService?.success('过磅记录 ${weighbridgeInfo.onlyNumber} 图片下载完成');
          
        } catch (e) {
          failed++;
          _logger.e('下载过磅记录 ${weighbridgeInfo.onlyNumber} 的图片失败: $e');
          _logService?.error('过磅记录 ${weighbridgeInfo.onlyNumber} 图片下载失败: $e');
        }

        // 更新进度
        final progress = (completed + failed) / weighbridgeList.length;
        state = state.copyWith(
          progress: progress,
          completedTasks: completed,
          failedTasks: failed,
          currentTask: completed + failed < weighbridgeList.length 
              ? '正在处理过磅记录 ${completed + failed + 1}/${weighbridgeList.length}...' 
              : '处理完成',
        );
      }

      final summary = '过磅爬取完成: 总计 ${weighbridgeList.length} 个记录，成功 $completed 个，失败 $failed 个';
      _logger.i(summary);
      _logService?.info(summary);
      
      state = state.copyWith(
        currentTask: summary,
      );

    } catch (e) {
      _logger.e('过磅爬取过程中出错: $e');
      _logService?.error('过磅爬取失败: $e');
      state = state.copyWith(
        currentTask: '爬取失败: ${e.toString()}',
      );
    }
  }

  /// 下载单个过磅记录的图片
  Future<void> _downloadWeighbridgeImages({
    required WeighbridgeInfo weighbridgeInfo,
    required String baseSavePath,
    required int delayBetweenImagesMs,
  }) async {
    try {
      // 使用 reportInfoId 创建过磅记录文件夹
      final cleanMaterialName = _sanitizeFileName(weighbridgeInfo.materialName);
      final cleanCarNumber = _sanitizeFileName(weighbridgeInfo.carNumber);
      final folderName = 'WB${weighbridgeInfo.reportInfoId}_${cleanMaterialName}_$cleanCarNumber';
      final recordFolderPath = path.join(baseSavePath, folderName);
      final recordFolder = Directory(recordFolderPath);
      if (!await recordFolder.exists()) {
        await recordFolder.create(recursive: true);
        _logger.i('创建过磅记录文件夹: $folderName');
        _logService?.info('创建过磅记录文件夹: $folderName');
      }

      // 保存过磅记录信息到JSON文件
      await _saveWeighbridgeRecordInfo(weighbridgeInfo, recordFolderPath);

      // 获取所有图片
      final allImages = weighbridgeInfo.getAllImages();
      int imageCount = 0;
      int downloadedCount = 0;

      final apiService = ref.read(apiServiceProvider);

      _logger.i('开始下载过磅记录 ${weighbridgeInfo.reportInfoId} 的 ${allImages.length} 张图片');
      _logService?.info('开始下载过磅记录 ${weighbridgeInfo.reportInfoId} 的 ${allImages.length} 张图片');

      // 下载每张图片
      for (final imageInfo in allImages) {
        imageCount++;
        final cleanSupplierName = _sanitizeFileName(weighbridgeInfo.supplyName);
        final fileName = '${imageCount}_${imageInfo.fileName}_$cleanSupplierName.jpg';
        final filePath = path.join(recordFolderPath, fileName);

        try {
          await apiService.downloadImage(
            url: imageInfo.url,
            savePath: filePath,
            maxRetries: state.retrySettings.maxRetries,
            retryDelay: state.retrySettings.retryDelay,
          );
          downloadedCount++;
          _logger.d('过磅图片下载成功: $fileName');
          _logService?.success('过磅图片下载成功: $fileName ($downloadedCount/${allImages.length})');
        } catch (e) {
          _logger.e('过磅图片下载失败: $fileName -> $e');
          _logService?.error('过磅图片下载失败: $fileName -> $e');
        }

        // 添加延迟
        if (delayBetweenImagesMs > 0) {
          await Future.delayed(Duration(milliseconds: delayBetweenImagesMs));
        }
      }

      _logger.i('过磅记录 ${weighbridgeInfo.reportInfoId} 图片下载完成: 成功 $downloadedCount/${allImages.length} 张');
      _logService?.success('过磅记录 ${weighbridgeInfo.reportInfoId} 图片下载完成: 成功 $downloadedCount/${allImages.length} 张');
      
    } catch (e) {
      _logger.e('下载过磅记录 ${weighbridgeInfo.reportInfoId} 的图片时出错: $e');
      _logService?.error('下载过磅记录 ${weighbridgeInfo.reportInfoId} 的图片时出错: $e');
      rethrow;
    }
  }

  /// 保存过磅记录信息到JSON文件
  Future<void> _saveWeighbridgeRecordInfo(WeighbridgeInfo weighbridgeInfo, String recordFolderPath) async {
    try {
      final recordInfoFile = File(path.join(recordFolderPath, 'record_info.json'));
      
      // 创建包含关键信息的JSON数据
      final recordData = {
        'reportInfoId': weighbridgeInfo.reportInfoId,
        'projectName': weighbridgeInfo.projectName,
        'weighbridgeName': weighbridgeInfo.weighbridgeName,
        'materialName': weighbridgeInfo.materialName,
        'model': weighbridgeInfo.model,
        'carNumber': weighbridgeInfo.carNumber,
        'onlyNumber': weighbridgeInfo.onlyNumber,
        'supplyName': weighbridgeInfo.supplyName,
        'createTime': weighbridgeInfo.createTime,
        'weightMTime': weighbridgeInfo.weightMTime,
        'weightPTime': weighbridgeInfo.weightPTime,
        'userLocation': weighbridgeInfo.userLocation,
        'amount': weighbridgeInfo.amount,
        'weightM': weighbridgeInfo.weightM,
        'weightP': weighbridgeInfo.weightP,
        'weightJ': weighbridgeInfo.weightJ,
      };
      
      await recordInfoFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(recordData),
      );
      
      _logger.d('过磅记录信息已保存: record_info.json');
    } catch (e) {
      _logger.e('保存过磅记录信息失败: $e');
      // 不抛出异常，因为这不应该阻止图片下载
    }
  }

  /// 获取保存基础路径
  Future<String> _getSaveBasePath() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString('weighbridge_save_path');
    
    if (savedPath == null || savedPath.isEmpty) {
      // 如果没有保存的路径，使用更安全的默认路径
      final currentDir = Directory.current.path;
      
      // 确保路径是绝对路径，不是根目录
      if (currentDir == '/' || currentDir.isEmpty) {
        // 如果当前目录是根目录，使用用户文档目录
        savedPath = path.join(Platform.environment['HOME'] ?? '/tmp', 'Downloads', 'material_anticheat', 'pic');
      } else {
        // 使用相对于当前工作目录的路径
        savedPath = path.join(currentDir, 'pic');
      }
      
      // 确保目录存在
      final saveDir = Directory(savedPath);
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }
      
      // 保存到SharedPreferences中
      await prefs.setString('weighbridge_save_path', savedPath);
      _logger.i('设置默认保存路径: $savedPath');
    }
    
    return savedPath;
  }

  /// 选择保存路径
  Future<String?> selectSavePath() async {
    // 暂时使用默认路径，因为file_picker在当前实现中有问题
    final currentDir = Directory.current.path;
    String defaultPath;
    
    // 确保路径是绝对路径，不是根目录
    if (currentDir == '/' || currentDir.isEmpty) {
      // 如果当前目录是根目录，使用用户文档目录
      defaultPath = path.join(Platform.environment['HOME'] ?? '/tmp', 'Downloads', 'material_anticheat', 'pic');
    } else {
      // 使用相对于当前工作目录的路径
      defaultPath = path.join(currentDir, 'pic');
    }
    
    // 确保目录存在
    final saveDir = Directory(defaultPath);
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    
    await saveSettings({'save_path': defaultPath});
    _logger.i('过磅保存路径已更新: $defaultPath');
    _logService?.info('过磅保存路径已更新: $defaultPath');
    return defaultPath;
  }

  /// 清理文件名中的非法字符
  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }
} 