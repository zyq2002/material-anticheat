import 'dart:async';
import 'dart:isolate';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import 'weighbridge_duplicate_detection_service.dart';
import 'weighbridge_image_similarity_service.dart';
import 'log_service.dart';

// Provider
final backgroundDetectionServiceProvider = Provider<BackgroundDetectionService>((ref) {
  return BackgroundDetectionService(ref);
});

// 后台检测任务类型
enum BackgroundDetectionType {
  suspicious,  // 可疑图片检测
  duplicate,   // 重复图片检测
}

// 后台检测状态
enum BackgroundDetectionStatus {
  pending,    // 等待中
  running,    // 运行中
  completed,  // 已完成
  failed,     // 失败
  cancelled,  // 已取消
}

// 后台检测任务
class BackgroundDetectionTask {
  final String id;
  final BackgroundDetectionType type;
  final Map<String, dynamic> config;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final BackgroundDetectionStatus status;
  final double progress;
  final String? currentTask;
  final dynamic result;
  final String? error;

  const BackgroundDetectionTask({
    required this.id,
    required this.type,
    required this.config,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.status = BackgroundDetectionStatus.pending,
    this.progress = 0.0,
    this.currentTask,
    this.result,
    this.error,
  });

  BackgroundDetectionTask copyWith({
    BackgroundDetectionStatus? status,
    double? progress,
    String? currentTask,
    dynamic result,
    String? error,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return BackgroundDetectionTask(
      id: id,
      type: type,
      config: config,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentTask: currentTask ?? this.currentTask,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

// 后台检测进度更新
class BackgroundDetectionProgress {
  final String taskId;
  final BackgroundDetectionStatus status;
  final double progress;
  final String? currentTask;
  final dynamic result;
  final String? error;

  const BackgroundDetectionProgress({
    required this.taskId,
    required this.status,
    required this.progress,
    this.currentTask,
    this.result,
    this.error,
  });
}

class BackgroundDetectionService extends StateNotifier<List<BackgroundDetectionTask>> {
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

  final Ref _ref;
  final Map<String, Isolate> _runningIsolates = {};
  final Map<String, StreamController<BackgroundDetectionProgress>> _progressControllers = {};

  BackgroundDetectionService(this._ref) : super([]);

  /// 启动可疑图片检测任务
  Future<String> startSuspiciousImageDetection(double threshold) async {
    final taskId = const Uuid().v4();
    
    final task = BackgroundDetectionTask(
      id: taskId,
      type: BackgroundDetectionType.suspicious,
      config: {'threshold': threshold},
      createdAt: DateTime.now(),
    );

    state = [...state, task];
    
    _logger.i('启动可疑图片检测任务: $taskId');
    
    // 在后台Isolate中运行检测
    _runDetectionInBackground(task);
    
    return taskId;
  }

  /// 启动重复图片检测任务
  Future<String> startDuplicateDetection(WeighbridgeDuplicateConfig config) async {
    final taskId = const Uuid().v4();
    
    final task = BackgroundDetectionTask(
      id: taskId,
      type: BackgroundDetectionType.duplicate,
      config: {
        'similarityThreshold': config.similarityThreshold,
        'compareDays': config.compareDays,
        'compareCarFrontImages': config.compareCarFrontImages,
        'compareCarLeftImages': config.compareCarLeftImages,
        'compareCarRightImages': config.compareCarRightImages,
        'compareCarPlateImages': config.compareCarPlateImages,
      },
      createdAt: DateTime.now(),
    );

    state = [...state, task];
    
    _logger.i('启动重复图片检测任务: $taskId');
    
    // 在后台Isolate中运行检测
    _runDetectionInBackground(task);
    
    return taskId;
  }

  /// 获取任务进度流
  Stream<BackgroundDetectionProgress> getTaskProgressStream(String taskId) {
    if (!_progressControllers.containsKey(taskId)) {
      _progressControllers[taskId] = StreamController<BackgroundDetectionProgress>.broadcast();
    }
    return _progressControllers[taskId]!.stream;
  }

  /// 取消任务
  Future<void> cancelTask(String taskId) async {
    final task = state.firstWhere((t) => t.id == taskId, orElse: () => throw Exception('任务不存在'));
    
    if (task.status == BackgroundDetectionStatus.running) {
      // 终止Isolate
      final isolate = _runningIsolates[taskId];
      if (isolate != null) {
        isolate.kill(priority: Isolate.immediate);
        _runningIsolates.remove(taskId);
      }
      
      // 更新任务状态
      _updateTaskStatus(taskId, BackgroundDetectionStatus.cancelled, completedAt: DateTime.now());
      
      _logger.i('任务已取消: $taskId');
    }
  }

  /// 清理已完成的任务
  void clearCompletedTasks() {
    state = state.where((task) => 
      task.status != BackgroundDetectionStatus.completed &&
      task.status != BackgroundDetectionStatus.failed &&
      task.status != BackgroundDetectionStatus.cancelled
    ).toList();
    
    _logger.i('已清理完成的任务');
  }

  /// 在后台Isolate中运行检测
  Future<void> _runDetectionInBackground(BackgroundDetectionTask task) async {
    try {
      // 更新任务状态为运行中
      _updateTaskStatus(task.id, BackgroundDetectionStatus.running, startedAt: DateTime.now());

      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(_detectionIsolateEntryPoint, {
        'sendPort': receivePort.sendPort,
        'task': {
          'id': task.id,
          'type': task.type.toString(),
          'config': task.config,
        },
      });

      _runningIsolates[task.id] = isolate;

      // 监听Isolate的进度更新
      receivePort.listen((message) {
        if (message is Map<String, dynamic>) {
          final taskId = message['taskId'] as String;
          final status = BackgroundDetectionStatus.values.firstWhere(
            (s) => s.toString() == message['status'],
            orElse: () => BackgroundDetectionStatus.running,
          );
          final progress = (message['progress'] as num?)?.toDouble() ?? 0.0;
          final currentTask = message['currentTask'] as String?;
          final result = message['result'];
          final error = message['error'] as String?;

          if (status == BackgroundDetectionStatus.completed) {
            _updateTaskStatus(
              taskId, 
              status, 
              progress: progress,
              currentTask: currentTask,
              result: result,
              completedAt: DateTime.now(),
            );
            _cleanupIsolate(taskId);
          } else if (status == BackgroundDetectionStatus.failed) {
            _updateTaskStatus(
              taskId, 
              status, 
              progress: progress,
              currentTask: currentTask,
              error: error,
              completedAt: DateTime.now(),
            );
            _cleanupIsolate(taskId);
          } else {
            _updateTaskStatus(
              taskId, 
              status, 
              progress: progress,
              currentTask: currentTask,
            );
          }

          // 发送进度更新到流
          final controller = _progressControllers[taskId];
          if (controller != null && !controller.isClosed) {
            controller.add(BackgroundDetectionProgress(
              taskId: taskId,
              status: status,
              progress: progress,
              currentTask: currentTask,
              result: result,
              error: error,
            ));
          }
        }
      });

    } catch (e) {
      _logger.e('启动后台检测任务失败: $e');
      _updateTaskStatus(
        task.id, 
        BackgroundDetectionStatus.failed, 
        error: e.toString(),
        completedAt: DateTime.now(),
      );
    }
  }

  /// Isolate入口点
  static void _detectionIsolateEntryPoint(Map<String, dynamic> params) async {
    final sendPort = params['sendPort'] as SendPort;
    final taskData = params['task'] as Map<String, dynamic>;
    final taskId = taskData['id'] as String;
    final taskType = taskData['type'] as String;
    final config = taskData['config'] as Map<String, dynamic>;

    try {
      if (taskType == BackgroundDetectionType.suspicious.toString()) {
        // 可疑图片检测
        final threshold = config['threshold'] as double;
        final service = WeighbridgeImageSimilarityService();
        
        sendPort.send({
          'taskId': taskId,
          'status': BackgroundDetectionStatus.running.toString(),
          'progress': 0.1,
          'currentTask': '正在检测可疑图片...',
        });

        final result = await service.detectSuspiciousImages(threshold);
        
        sendPort.send({
          'taskId': taskId,
          'status': BackgroundDetectionStatus.completed.toString(),
          'progress': 1.0,
          'currentTask': '检测完成',
          'result': result.map((r) => {
            'imagePath': r.imagePath,
            'recordName': r.recordName,
            'imageType': r.imageType,
            'similarity': r.similarity,
            'matchImagePath': r.matchImagePath,
            'matchRecordName': r.matchRecordName,
            'detectionTime': r.detectionTime.toIso8601String(),
          }).toList(),
        });

      } else if (taskType == BackgroundDetectionType.duplicate.toString()) {
        // 重复图片检测
        final duplicateConfig = WeighbridgeDuplicateConfig(
          similarityThreshold: config['similarityThreshold'] as double,
          compareDays: config['compareDays'] as int,
          compareCarFrontImages: config['compareCarFrontImages'] as bool,
          compareCarLeftImages: config['compareCarLeftImages'] as bool,
          compareCarRightImages: config['compareCarRightImages'] as bool,
          compareCarPlateImages: config['compareCarPlateImages'] as bool,
        );

        final service = WeighbridgeDuplicateDetectionService();
        
        await for (final progress in service.detectDuplicates(duplicateConfig)) {
          sendPort.send({
            'taskId': taskId,
            'status': progress.isCompleted 
                ? BackgroundDetectionStatus.completed.toString()
                : BackgroundDetectionStatus.running.toString(),
            'progress': progress.progress,
            'currentTask': progress.currentTask,
            'result': progress.isCompleted ? progress.results.map((r) => {
              'imagePath1': r.imagePath1,
              'imagePath2': r.imagePath2,
              'recordName1': r.recordName1,
              'recordName2': r.recordName2,
              'similarity': r.similarity,
              'imageType': r.imageType,
              'detectionTime': r.detectionTime.toIso8601String(),
            }).toList() : null,
          });

          if (progress.isCompleted) break;
        }
      }

    } catch (e) {
      sendPort.send({
        'taskId': taskId,
        'status': BackgroundDetectionStatus.failed.toString(),
        'progress': 0.0,
        'error': e.toString(),
      });
    }
  }

  /// 更新任务状态
  void _updateTaskStatus(
    String taskId,
    BackgroundDetectionStatus status, {
    double? progress,
    String? currentTask,
    dynamic result,
    String? error,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    final taskIndex = state.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final updatedTask = state[taskIndex].copyWith(
        status: status,
        progress: progress,
        currentTask: currentTask,
        result: result,
        error: error,
        startedAt: startedAt,
        completedAt: completedAt,
      );
      
      final newState = List<BackgroundDetectionTask>.from(state);
      newState[taskIndex] = updatedTask;
      state = newState;
    }
  }

  /// 清理Isolate资源
  void _cleanupIsolate(String taskId) {
    final isolate = _runningIsolates[taskId];
    if (isolate != null) {
      isolate.kill(priority: Isolate.immediate);
      _runningIsolates.remove(taskId);
    }
    
    // 延迟关闭进度控制器，确保最后的消息能够发送
    Timer(const Duration(seconds: 1), () {
      final controller = _progressControllers[taskId];
      if (controller != null && !controller.isClosed) {
        controller.close();
        _progressControllers.remove(taskId);
      }
    });
  }

  /// 获取任务统计信息
  Map<String, int> getTaskStats() {
    final stats = <String, int>{
      'total': state.length,
      'pending': 0,
      'running': 0,
      'completed': 0,
      'failed': 0,
      'cancelled': 0,
    };

    for (final task in state) {
      switch (task.status) {
        case BackgroundDetectionStatus.pending:
          stats['pending'] = stats['pending']! + 1;
          break;
        case BackgroundDetectionStatus.running:
          stats['running'] = stats['running']! + 1;
          break;
        case BackgroundDetectionStatus.completed:
          stats['completed'] = stats['completed']! + 1;
          break;
        case BackgroundDetectionStatus.failed:
          stats['failed'] = stats['failed']! + 1;
          break;
        case BackgroundDetectionStatus.cancelled:
          stats['cancelled'] = stats['cancelled']! + 1;
          break;
      }
    }

    return stats;
  }

  /// 清理所有资源
  @override
  void dispose() {
    // 终止所有运行中的Isolate
    for (final isolate in _runningIsolates.values) {
      isolate.kill(priority: Isolate.immediate);
    }
    _runningIsolates.clear();

    // 关闭所有进度控制器
    for (final controller in _progressControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _progressControllers.clear();

    super.dispose();
  }
} 