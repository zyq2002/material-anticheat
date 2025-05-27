import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:intl/intl.dart';

import 'api_service.dart';
import 'log_service.dart';
import '../models/material_check_detail.dart';

part 'crawler_service.g.dart';

@riverpod
class CrawlerService extends _$CrawlerService {
  final Logger _logger = Logger();
  Timer? _timer;
  bool _isRunning = false;

  // 日志服务实例
  LogService? _logService;

  @override
  CrawlerState build() {
    // 初始化日志服务
    _logService = ref.read(logServiceProvider.notifier);
    
    return const CrawlerState(
      isRunning: false,
      progress: 0.0,
      currentTask: '',
      totalTasks: 0,
      completedTasks: 0,
      failedTasks: 0,
      retrySettings: RetrySettings(),
    );
  }

  /// 启动爬虫
  Future<void> startCrawler({
    required String authToken,
    String? cookie,
    required DateTime selectedDate,
    required int intervalMinutes,
  }) async {
    if (_isRunning) {
      _logger.w('爬虫已在运行中');
      return;
    }

    _isRunning = true;
    state = state.copyWith(isRunning: true);

    // 设置API认证信息
    final apiService = ref.read(apiServiceProvider);
    _logger.d('🔐 开始设置认证信息:');
    _logger.d('  - authToken长度: ${authToken.length}');
    _logger.d('  - cookie是否提供: ${cookie != null && cookie.isNotEmpty}');
    _logger.d('  - cookie长度: ${cookie?.length ?? 0}');
    
    if (cookie != null && cookie.isNotEmpty) {
      _logger.d('🔑 使用完整认证模式 (Token + Cookie)');
      apiService.setFullAuthInfo(authToken, cookie);
    } else {
      _logger.d('🔑 使用Token认证模式');
      apiService.setAuthToken(authToken);
    }

    // 保存设置
    await _saveSettings(authToken, cookie, intervalMinutes);

    // 立即执行一次
    await _performCrawling(selectedDate);

    // 设置定时器
    _timer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => _performCrawling(selectedDate),
    );

    _logger.i('爬虫已启动，间隔: $intervalMinutes分钟');
    _logService?.success('爬虫已启动，间隔: $intervalMinutes分钟');
  }

  /// 批量下载多天的图片
  Future<void> batchDownloadImages({
    required String authToken,
    String? cookie,
    required DateTime startDate,
    required DateTime endDate,
    int delayBetweenDaysSeconds = 5,  // 每天之间的休息时间
    int delayBetweenImagesMs = 500,  // 每张图片之间的延迟
  }) async {
    if (_isRunning) {
      _logger.w('爬虫已在运行中');
      return;
    }

    _isRunning = true;
    state = state.copyWith(isRunning: true);

    try {
      // 设置API认证信息
      final apiService = ref.read(apiServiceProvider);
      if (cookie != null && cookie.isNotEmpty) {
        apiService.setFullAuthInfo(authToken, cookie);
      } else {
        apiService.setAuthToken(authToken);
      }

      // 计算日期范围
      final totalDays = endDate.difference(startDate).inDays + 1;
      int processedDays = 0;
      int totalSuccessful = 0;
      int totalFailed = 0;

      DateTime currentDate = startDate;
      
      while (currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
        processedDays++;
        final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);
        
        state = state.copyWith(
          currentTask: '正在处理第 $processedDays/$totalDays 天: $dateStr',
          progress: processedDays / totalDays,
        );

        try {
          final result = await _performSingleDayCrawling(
            currentDate, 
            delayBetweenImagesMs,
          );
          
          totalSuccessful += result['successful'] as int;
          totalFailed += result['failed'] as int;

          // 如果不是最后一天，休息指定时间
          if (processedDays < totalDays && delayBetweenDaysSeconds > 0) {
            state = state.copyWith(
              currentTask: '$dateStr 处理完成，休息 $delayBetweenDaysSeconds 秒...',
            );
            await Future.delayed(Duration(seconds: delayBetweenDaysSeconds));
          }

        } catch (e) {
          _logger.e('处理日期 $dateStr 时出错: $e');
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

      _logger.i('批量下载完成 - 成功: $totalSuccessful, 失败: $totalFailed');

    } catch (e) {
      _logger.e('批量下载过程出错: $e');
      state = state.copyWith(
        currentTask: '批量下载错误: $e',
      );
    } finally {
      _isRunning = false;
      state = state.copyWith(isRunning: false);
    }
  }

  /// 处理单天的爬取任务
  Future<Map<String, int>> _performSingleDayCrawling(
    DateTime date, 
    int delayBetweenImagesMs,
  ) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final beginTime = '$dateStr 00:00:00';
    final endTime = '$dateStr 23:59:59';

    // 获取验收记录列表
    final apiService = ref.read(apiServiceProvider);
    final flowList = await apiService.getFlowList(
      beginTime: beginTime,
      endTime: endTime,
    );

    if (flowList.isEmpty) {
      _logger.i('$dateStr 当天没有验收记录');
      return {'successful': 0, 'failed': 0};
    }

    // 获取保存路径
    final saveBasePath = await _getSaveBasePath();
    final dateFolderPath = path.join(saveBasePath, 'images', dateStr);

    int completed = 0;
    int failed = 0;

    // 处理每个验收记录
    for (int i = 0; i < flowList.length; i++) {
      final flowInfo = flowList[i];
      
      try {
        await _downloadImagesForFlow(
          flowInfo, 
          dateFolderPath, 
          delayBetweenImagesMs,
        );
        completed++;
        
      } catch (e) {
        _logger.e('下载验收记录 ${flowInfo.code} 的图片失败: $e');
        failed++;
      }
    }

    _logger.i('$dateStr - 成功: $completed, 失败: $failed');
    return {'successful': completed, 'failed': failed};
  }

  /// 停止爬虫
  void stopCrawler() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    state = state.copyWith(
      isRunning: false,
      currentTask: '已停止',
    );
    _logger.i('爬虫已停止');
  }

  /// 执行爬取任务
  Future<void> _performCrawling(DateTime selectedDate) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final beginTime = '$dateStr 00:00:00';
      final endTime = '$dateStr 23:59:59';

      state = state.copyWith(
        currentTask: '获取数据列表...',
        progress: 0.0,
        completedTasks: 0,
        failedTasks: 0,
      );

      // 获取验收记录列表
      final apiService = ref.read(apiServiceProvider);
      final flowList = await apiService.getFlowList(
        beginTime: beginTime,
        endTime: endTime,
      );

      if (flowList.isEmpty) {
        _logger.i('$dateStr 当天没有验收记录');
        state = state.copyWith(
          currentTask: '$dateStr 当天没有验收记录',
          totalTasks: 0,
        );
        return;
      }

      state = state.copyWith(
        totalTasks: flowList.length,
        currentTask: '开始下载 ${flowList.length} 个验收记录的图片...',
      );

      // 获取保存路径
      final saveBasePath = await _getSaveBasePath();
      final dateFolderPath = path.join(saveBasePath, 'images', dateStr);

      int completed = 0;
      int failed = 0;

      // 处理每个验收记录
      for (int i = 0; i < flowList.length; i++) {
        final flowInfo = flowList[i];
        
        try {
          state = state.copyWith(
            currentTask: '下载验收记录 ${flowInfo.code} 的图片 (${i + 1}/${flowList.length})',
            progress: (i + 1) / flowList.length,
          );

          await _downloadImagesForFlow(flowInfo, dateFolderPath, 500);
          completed++;
          
          state = state.copyWith(
            completedTasks: completed,
          );
          
        } catch (e) {
          _logger.e('下载验收记录 ${flowInfo.code} 的图片失败: $e');
          failed++;
          
          state = state.copyWith(
            failedTasks: failed,
          );
        }
      }

      state = state.copyWith(
        currentTask: '图片下载完成! 成功: $completed, 失败: $failed',
      );

      _logger.i('图片下载完成 - 成功: $completed, 失败: $failed');

    } catch (e) {
      _logger.e('图片下载过程出错: $e');
      state = state.copyWith(
        currentTask: '错误: $e',
      );
    }
  }

  /// 清理文件名，去除不允许的字符
  String _sanitizeFileName(String fileName) {
    // 去除或替换文件名中不允许的字符
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') // Windows不允许的字符
        .replaceAll(RegExp(r'[\x00-\x1f]'), '_') // 控制字符
        .replaceAll(RegExp(r'\s+'), '_') // 多个空格替换为下划线
        .replaceAll(RegExp(r'_+'), '_') // 多个下划线合并为一个
        .replaceAll(RegExp(r'^_+|_+$'), ''); // 去除开头和结尾的下划线
  }

  /// 下载单个验收记录的所有图片
  Future<void> _downloadImagesForFlow(
    FlowInfo flowInfo, 
    String baseSavePath, 
    int delayBetweenImagesMs,
  ) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final detail = await apiService.getMaterialCheckDetail(
        incomeCheckId: flowInfo.dataId,
      );

      // 检查响应是否有效
      if (detail.data == null) {
        _logger.w('验收记录 ${flowInfo.code} 响应为空，跳过图片下载');
        return;
      }

      // 创建验收记录文件夹，使用更有意义的名称
      final cleanMaterialNames = _sanitizeFileName(flowInfo.materialNames);
      final folderName = '${flowInfo.code}_$cleanMaterialNames';
      final recordFolderPath = path.join(baseSavePath, folderName);
      final recordFolder = Directory(recordFolderPath);
      if (!await recordFolder.exists()) {
        await recordFolder.create(recursive: true);
      }

      int imageCount = 0;

      // 下载每个材料的图片
      for (final material in detail.data!.materialRespList) {
        // 下载送货单照片
        if (material.deliveryImg != null && material.deliveryImg!.isNotEmpty) {
          imageCount++;
          final cleanSupplierName = _sanitizeFileName(material.supplierName);
          final cleanCarNo = _sanitizeFileName(material.carNo);
          final deliveryImgName = '${imageCount}_送货单_${cleanSupplierName}_$cleanCarNo.jpg';
          final deliveryImgPath = path.join(recordFolderPath, deliveryImgName);
          
          await apiService.downloadImage(
            url: material.deliveryImg!,
            savePath: deliveryImgPath,
            maxRetries: state.retrySettings.maxRetries,
            retryDelay: state.retrySettings.retryDelay,
          );
          _logService?.success('送货单下载成功: $deliveryImgName');

          // 添加延迟
          if (delayBetweenImagesMs > 0) {
            await Future.delayed(Duration(milliseconds: delayBetweenImagesMs));
          }
        }

        // 下载验收照片
        for (int i = 0; i < material.files.length; i++) {
          imageCount++;
          final fileInfo = material.files[i];
          final extension = path.extension(fileInfo.fileName).isNotEmpty 
              ? path.extension(fileInfo.fileName) 
              : '.jpg';
          final cleanMaterialName = _sanitizeFileName(material.name);
          final fileName = '${imageCount}_验收照片${i + 1}_$cleanMaterialName$extension';
          final filePath = path.join(recordFolderPath, fileName);

          await apiService.downloadImage(
            url: fileInfo.fileUrl,
            savePath: filePath,
            maxRetries: state.retrySettings.maxRetries,
            retryDelay: state.retrySettings.retryDelay,
          );
          _logService?.success('验收照片下载成功: $fileName');

          // 添加延迟
          if (delayBetweenImagesMs > 0) {
            await Future.delayed(Duration(milliseconds: delayBetweenImagesMs));
          }
        }
      }

      _logger.d('验收记录 ${flowInfo.code} 的 $imageCount 张图片下载完成');
      
    } catch (e) {
      _logger.e('下载验收记录 ${flowInfo.code} 的图片时出错: $e');
      rethrow;
    }
  }

  /// 获取保存基础路径
  Future<String> _getSaveBasePath() async {
    // 清除可能存储的错误路径
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString('save_path');
    
    // 如果自定义路径包含 "/Volumes/Macintosh HD"，则清除它
    if (customPath != null && customPath.contains('/Volumes/Macintosh HD')) {
      _logger.w('发现错误的保存路径格式，正在清除: $customPath');
      await prefs.remove('save_path');
    }
    
    // 使用当前工作目录下的 pic 文件夹（相对路径）
    const defaultPath = 'pic';
    
    try {
      // 确保目录存在
      final picDir = Directory(defaultPath);
      if (!await picDir.exists()) {
        await picDir.create(recursive: true);
      }
      
      // 获取绝对路径用于日志
      final absolutePath = picDir.absolute.path;
      _logger.i('使用应用根目录下的pic文件夹作为保存路径: $absolutePath');
      
      return defaultPath;
    } catch (e) {
      _logger.e('创建pic目录失败: $e');
      
      // 备用方案：使用用户文档目录
      try {
        final documentsDir = await getApplicationDocumentsDirectory();
        final fallbackPath = path.join(documentsDir.path, 'MaterialAntiCheat', 'pic');
        final fallbackDir = Directory(fallbackPath);
        await fallbackDir.create(recursive: true);
        _logger.i('使用备用路径: $fallbackPath');
        return fallbackPath;
      } catch (e2) {
        _logger.e('备用路径也失败: $e2');
        rethrow;
      }
    }
  }

  /// 保存设置
  Future<void> _saveSettings(String authToken, String? cookie, int intervalMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', authToken);
    if (cookie != null) {
      await prefs.setString('cookie', cookie);
    }
    await prefs.setInt('interval_minutes', intervalMinutes);
  }

  /// 加载设置
  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'auth_token': prefs.getString('auth_token') ?? '',
      'cookie': prefs.getString('cookie') ?? '',
      'interval_minutes': prefs.getInt('interval_minutes') ?? 30,
      'save_path': prefs.getString('save_path') ?? '',
    };
  }

  /// 设置保存路径
  Future<void> setSavePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('save_path', path);
  }

  /// 更新重试设置
  void updateRetrySettings(RetrySettings settings) {
    state = state.copyWith(retrySettings: settings);
    _logService?.info('重试设置已更新: 最大重试${settings.maxRetries}次, 延迟${settings.retryDelay.inSeconds}秒');
  }

  /// 手动重试失败的任务
  Future<void> retryFailedTasks() async {
    if (_isRunning) {
      _logService?.warning('爬虫正在运行中，无法执行手动重试');
      return;
    }

    _logService?.info('开始手动重试失败的任务...');
    // 这里可以实现重试逻辑
    // 目前先记录日志
  }

  void dispose() {
    stopCrawler();
  }
}

class RetrySettings {
  final int maxRetries;
  final Duration retryDelay;
  final bool enableAutoRetry;

  const RetrySettings({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.enableAutoRetry = true,
  });

  RetrySettings copyWith({
    int? maxRetries,
    Duration? retryDelay,
    bool? enableAutoRetry,
  }) {
    return RetrySettings(
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      enableAutoRetry: enableAutoRetry ?? this.enableAutoRetry,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetrySettings &&
          runtimeType == other.runtimeType &&
          maxRetries == other.maxRetries &&
          retryDelay == other.retryDelay &&
          enableAutoRetry == other.enableAutoRetry;

  @override
  int get hashCode =>
      maxRetries.hashCode ^ retryDelay.hashCode ^ enableAutoRetry.hashCode;
}

class CrawlerState {
  final bool isRunning;
  final double progress;
  final String currentTask;
  final int totalTasks;
  final int completedTasks;
  final int failedTasks;
  final RetrySettings retrySettings;

  const CrawlerState({
    required this.isRunning,
    required this.progress,
    required this.currentTask,
    required this.totalTasks,
    required this.completedTasks,
    required this.failedTasks,
    required this.retrySettings,
  });

  CrawlerState copyWith({
    bool? isRunning,
    double? progress,
    String? currentTask,
    int? totalTasks,
    int? completedTasks,
    int? failedTasks,
    RetrySettings? retrySettings,
  }) {
    return CrawlerState(
      isRunning: isRunning ?? this.isRunning,
      progress: progress ?? this.progress,
      currentTask: currentTask ?? this.currentTask,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      failedTasks: failedTasks ?? this.failedTasks,
      retrySettings: retrySettings ?? this.retrySettings,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrawlerState &&
          runtimeType == other.runtimeType &&
          isRunning == other.isRunning &&
          progress == other.progress &&
          currentTask == other.currentTask &&
          totalTasks == other.totalTasks &&
          completedTasks == other.completedTasks &&
          failedTasks == other.failedTasks &&
          retrySettings == other.retrySettings;

  @override
  int get hashCode =>
      isRunning.hashCode ^
      progress.hashCode ^
      currentTask.hashCode ^
      totalTasks.hashCode ^
      completedTasks.hashCode ^
      failedTasks.hashCode ^
      retrySettings.hashCode;
} 