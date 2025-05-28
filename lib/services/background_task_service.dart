import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../models/detection_result.dart';
import 'detection_history_service.dart';
import 'weighbridge_duplicate_detection_service.dart';

final backgroundTaskServiceProvider = Provider<BackgroundTaskService>((ref) {
  return BackgroundTaskService(ref);
});

final backgroundTasksProvider = StateNotifierProvider<BackgroundTaskNotifier, List<BackgroundTask>>((ref) {
  return BackgroundTaskNotifier();
});

/// 后台任务类型
enum BackgroundTaskType {
  duplicateDetection,
  imageSimilarityCheck,
  batchProcessing,
}

/// 后台任务状态
enum BackgroundTaskStatus {
  pending,     // 等待中
  running,     // 运行中
  paused,      // 已暂停
  completed,   // 已完成
  cancelled,   // 已取消
  failed,      // 失败
}

/// 后台任务模型
class BackgroundTask {
  final String id;
  final String name;
  final BackgroundTaskType type;
  final BackgroundTaskStatus status;
  final double progress;
  final int totalItems;
  final int processedItems;
  final DateTime startTime;
  final DateTime? endTime;
  final String? error;
  final Map<String, dynamic> config;
  final List<DetectionResult> results;

  BackgroundTask({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.progress,
    required this.totalItems,
    required this.processedItems,
    required this.startTime,
    this.endTime,
    this.error,
    required this.config,
    required this.results,
  });

  BackgroundTask copyWith({
    String? id,
    String? name,
    BackgroundTaskType? type,
    BackgroundTaskStatus? status,
    double? progress,
    int? totalItems,
    int? processedItems,
    DateTime? startTime,
    DateTime? endTime,
    String? error,
    Map<String, dynamic>? config,
    List<DetectionResult>? results,
  }) {
    return BackgroundTask(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      totalItems: totalItems ?? this.totalItems,
      processedItems: processedItems ?? this.processedItems,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      error: error ?? this.error,
      config: config ?? this.config,
      results: results ?? this.results,
    );
  }

  String get statusText {
    switch (status) {
      case BackgroundTaskStatus.pending:
        return '等待中';
      case BackgroundTaskStatus.running:
        return '运行中';
      case BackgroundTaskStatus.paused:
        return '已暂停';
      case BackgroundTaskStatus.completed:
        return '已完成';
      case BackgroundTaskStatus.cancelled:
        return '已取消';
      case BackgroundTaskStatus.failed:
        return '失败';
    }
  }

  String get typeText {
    switch (type) {
      case BackgroundTaskType.duplicateDetection:
        return '重复检测';
      case BackgroundTaskType.imageSimilarityCheck:
        return '相似度检查';
      case BackgroundTaskType.batchProcessing:
        return '批量处理';
    }
  }

  Duration get elapsed {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  bool get isRunning => status == BackgroundTaskStatus.running;
  bool get isCompleted => status == BackgroundTaskStatus.completed;
  bool get isFailed => status == BackgroundTaskStatus.failed;
  bool get canPause => status == BackgroundTaskStatus.running;
  bool get canResume => status == BackgroundTaskStatus.paused;
  bool get canCancel => status == BackgroundTaskStatus.running || status == BackgroundTaskStatus.paused;
}

/// 后台任务状态管理
class BackgroundTaskNotifier extends StateNotifier<List<BackgroundTask>> {
  BackgroundTaskNotifier() : super([]);

  void addTask(BackgroundTask task) {
    state = [...state, task];
  }

  void updateTask(String taskId, BackgroundTask updatedTask) {
    state = state.map((task) => task.id == taskId ? updatedTask : task).toList();
  }

  void removeTask(String taskId) {
    state = state.where((task) => task.id != taskId).toList();
  }

  BackgroundTask? getTask(String taskId) {
    try {
      return state.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }

  List<BackgroundTask> getRunningTasks() {
    return state.where((task) => task.isRunning).toList();
  }

  List<BackgroundTask> getCompletedTasks() {
    return state.where((task) => task.isCompleted).toList();
  }
}

/// 后台任务服务
class BackgroundTaskService {
  final Ref _ref;
  final Logger _logger = Logger();
  final Map<String, Completer<void>> _taskCompleters = {};
  final Map<String, StreamController<double>> _progressControllers = {};

  BackgroundTaskService(this._ref);

  /// 创建并启动重复检测任务
  Future<String> startDuplicateDetectionTask({
    required String name,
    required String folderPath,
    required String detectionType,
    required Map<String, dynamic> config,
  }) async {
    final taskId = const Uuid().v4();
    final task = BackgroundTask(
      id: taskId,
      name: name,
      type: BackgroundTaskType.duplicateDetection,
      status: BackgroundTaskStatus.pending,
      progress: 0.0,
      totalItems: 0,
      processedItems: 0,
      startTime: DateTime.now(),
      config: {
        'folderPath': folderPath,
        'detectionType': detectionType,
        ...config,
      },
      results: [],
    );

    _ref.read(backgroundTasksProvider.notifier).addTask(task);
    _logger.i('创建后台检测任务: $taskId');

    // 启动后台检测
    _runDetectionTask(taskId);

    return taskId;
  }

  /// 运行检测任务
  Future<void> _runDetectionTask(String taskId) async {
    try {
      final taskNotifier = _ref.read(backgroundTasksProvider.notifier);
      var task = taskNotifier.getTask(taskId);
      if (task == null) return;

      // 更新任务状态为运行中
      task = task.copyWith(status: BackgroundTaskStatus.running);
      taskNotifier.updateTask(taskId, task);

      // 创建进度控制器
      final progressController = StreamController<double>.broadcast();
      _progressControllers[taskId] = progressController;

      // 创建完成器
      final completer = Completer<void>();
      _taskCompleters[taskId] = completer;

      // 监听进度更新
      progressController.stream.listen((progress) {
        final currentTask = taskNotifier.getTask(taskId);
        if (currentTask != null) {
          final updatedTask = currentTask.copyWith(
            progress: progress,
            processedItems: (currentTask.totalItems * progress).round(),
          );
          taskNotifier.updateTask(taskId, updatedTask);
        }
      });

      // 执行检测
      final results = <DetectionResult>[];

      // 这里可以在独立的计算任务中运行
      await _runInBackground(
        taskId: taskId,
        onProgress: (progress) => progressController.add(progress),
        onResult: (result) => results.add(result),
        task: () async {
          // 使用现有的检测服务执行检测
          // 注意：这里应该实现真正的后台检测逻辑
          
          // 模拟检测过程（实际应该调用真正的检测方法）
          await Future.delayed(const Duration(milliseconds: 100));
          
          // 这里应该调用实际的检测逻辑
          // 由于现有服务设计，我们需要重构以支持后台运行
          
          return results;
        },
      );

      // 保存检测结果到历史记录
      final session = DetectionSession(
        id: taskId,
        startTime: task.startTime,
        endTime: DateTime.now(),
        detectionType: task.config['detectionType'] as String,
        config: task.config,
        totalComparisons: results.length,
        foundIssues: results.where((r) => r.level != SimilarityLevel.normal).length,
        results: results,
      );

      await _ref.read(detectionHistoryServiceProvider).saveDetectionSession(session);

      // 更新任务状态为已完成
      final completedTask = task.copyWith(
        status: BackgroundTaskStatus.completed,
        progress: 1.0,
        endTime: DateTime.now(),
        results: results,
        totalItems: results.length,
        processedItems: results.length,
      );
      taskNotifier.updateTask(taskId, completedTask);

      completer.complete();
      _logger.i('后台检测任务完成: $taskId');

    } catch (e) {
      // 处理错误
      final taskNotifier = _ref.read(backgroundTasksProvider.notifier);
      final task = taskNotifier.getTask(taskId);
      if (task != null) {
        final failedTask = task.copyWith(
          status: BackgroundTaskStatus.failed,
          error: e.toString(),
          endTime: DateTime.now(),
        );
        taskNotifier.updateTask(taskId, failedTask);
      }
      
      final completer = _taskCompleters[taskId];
      completer?.completeError(e);
      
      _logger.e('后台检测任务失败: $taskId, 错误: $e');
    } finally {
      // 清理资源
      _progressControllers[taskId]?.close();
      _progressControllers.remove(taskId);
      _taskCompleters.remove(taskId);
    }
  }

  /// 在后台运行任务
  Future<T> _runInBackground<T>({
    required String taskId,
    required Function(double) onProgress,
    required Function(DetectionResult) onResult,
    required Future<T> Function() task,
  }) async {
    // 这里可以使用 Isolate 或 compute 来在真正的后台线程中运行
    // 为了简化，我们在当前线程中运行但不阻塞UI
    
    final result = await task();
    return result;
  }

  /// 暂停任务
  Future<void> pauseTask(String taskId) async {
    final taskNotifier = _ref.read(backgroundTasksProvider.notifier);
    final task = taskNotifier.getTask(taskId);
    if (task != null && task.canPause) {
      final pausedTask = task.copyWith(status: BackgroundTaskStatus.paused);
      taskNotifier.updateTask(taskId, pausedTask);
      _logger.i('暂停后台任务: $taskId');
    }
  }

  /// 恢复任务
  Future<void> resumeTask(String taskId) async {
    final taskNotifier = _ref.read(backgroundTasksProvider.notifier);
    final task = taskNotifier.getTask(taskId);
    if (task != null && task.canResume) {
      final runningTask = task.copyWith(status: BackgroundTaskStatus.running);
      taskNotifier.updateTask(taskId, runningTask);
      _logger.i('恢复后台任务: $taskId');
    }
  }

  /// 取消任务
  Future<void> cancelTask(String taskId) async {
    final taskNotifier = _ref.read(backgroundTasksProvider.notifier);
    final task = taskNotifier.getTask(taskId);
    if (task != null && task.canCancel) {
      final cancelledTask = task.copyWith(
        status: BackgroundTaskStatus.cancelled,
        endTime: DateTime.now(),
      );
      taskNotifier.updateTask(taskId, cancelledTask);

      // 取消运行中的任务
      final completer = _taskCompleters[taskId];
      completer?.complete();

      _logger.i('取消后台任务: $taskId');
    }
  }

  /// 删除任务
  Future<void> deleteTask(String taskId) async {
    await cancelTask(taskId);
    _ref.read(backgroundTasksProvider.notifier).removeTask(taskId);
    _logger.i('删除后台任务: $taskId');
  }

  /// 获取任务进度流
  Stream<double>? getTaskProgressStream(String taskId) {
    return _progressControllers[taskId]?.stream;
  }

  /// 等待任务完成
  Future<void> waitForTask(String taskId) async {
    final completer = _taskCompleters[taskId];
    if (completer != null) {
      await completer.future;
    }
  }

  /// 获取所有运行中的任务数量
  int getRunningTaskCount() {
    return _ref.read(backgroundTasksProvider).where((task) => task.isRunning).length;
  }

  /// 清理已完成的任务
  void clearCompletedTasks() {
    final taskNotifier = _ref.read(backgroundTasksProvider.notifier);
    final tasks = _ref.read(backgroundTasksProvider);
    
    for (final task in tasks) {
      if (task.isCompleted || task.isFailed) {
        taskNotifier.removeTask(task.id);
      }
    }
    
    _logger.i('清理已完成的后台任务');
  }

  /// 获取任务统计信息
  Map<String, int> getTaskStatistics() {
    final tasks = _ref.read(backgroundTasksProvider);
    
    return {
      'total': tasks.length,
      'running': tasks.where((t) => t.isRunning).length,
      'completed': tasks.where((t) => t.isCompleted).length,
      'failed': tasks.where((t) => t.isFailed).length,
      'pending': tasks.where((t) => t.status == BackgroundTaskStatus.pending).length,
      'paused': tasks.where((t) => t.status == BackgroundTaskStatus.paused).length,
    };
  }

  void dispose() {
    // 清理所有资源
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
    _taskCompleters.clear();
  }
} 