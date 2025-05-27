import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class LogService extends StateNotifier<LogState> {
  static const int maxLogEntries = 1000; // 最大日志条数
  final Logger _logger = Logger();

  LogService() : super(const LogState(
    logs: [],
    autoScroll: true,
    showOnlyErrors: false,
  ));

  /// 添加信息日志
  void info(String message) {
    _addLog(LogLevel.info, message);
    _logger.i(message);
  }

  /// 添加警告日志
  void warning(String message) {
    _addLog(LogLevel.warning, message);
    _logger.w(message);
  }

  /// 添加错误日志
  void error(String message) {
    _addLog(LogLevel.error, message);
    _logger.e(message);
  }

  /// 添加调试日志
  void debug(String message) {
    _addLog(LogLevel.debug, message);
    _logger.d(message);
  }

  /// 添加成功日志
  void success(String message) {
    _addLog(LogLevel.success, message);
    _logger.i('✅ $message');
  }

  /// 内部添加日志方法
  void _addLog(LogLevel level, String message) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
    );

    // 新日志添加到末尾（时间顺序）
    final newLogs = [...state.logs, entry];
    
    // 限制日志条数，避免内存占用过多
    final limitedLogs = newLogs.length > maxLogEntries 
        ? newLogs.skip(newLogs.length - maxLogEntries).toList()
        : newLogs;
    
    state = state.copyWith(logs: limitedLogs);
  }

  /// 清空日志
  void clearLogs() {
    state = state.copyWith(logs: []);
  }

  /// 切换自动滚动
  void toggleAutoScroll() {
    state = state.copyWith(autoScroll: !state.autoScroll);
  }

  /// 切换仅显示错误日志
  void toggleShowOnlyErrors() {
    state = state.copyWith(showOnlyErrors: !state.showOnlyErrors);
  }

  /// 导出日志为文本
  String exportLogs() {
    return state.logs.map((entry) => entry.toFormattedString()).join('\n');
  }
}

// Provider
final logServiceProvider = StateNotifierProvider<LogService, LogState>((ref) {
  return LogService();
});

/// 日志状态类
class LogState {
  final List<LogEntry> logs;
  final bool autoScroll;
  final bool showOnlyErrors;

  const LogState({
    required this.logs,
    required this.autoScroll,
    required this.showOnlyErrors,
  });

  LogState copyWith({
    List<LogEntry>? logs,
    bool? autoScroll,
    bool? showOnlyErrors,
  }) {
    return LogState(
      logs: logs ?? this.logs,
      autoScroll: autoScroll ?? this.autoScroll,
      showOnlyErrors: showOnlyErrors ?? this.showOnlyErrors,
    );
  }

  /// 获取过滤后的日志
  List<LogEntry> get filteredLogs {
    if (showOnlyErrors) {
      return logs.where((log) => log.level == LogLevel.error).toList();
    }
    return logs;
  }
}

/// 日志级别枚举
enum LogLevel {
  debug,
  info,
  warning,
  error,
  success,
}

/// 日志条目类
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  /// 格式化输出
  String toFormattedString() {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    
    String levelStr;
    switch (level) {
      case LogLevel.debug:
        levelStr = '[DEBUG]';
        break;
      case LogLevel.info:
        levelStr = '[INFO] ';
        break;
      case LogLevel.warning:
        levelStr = '[WARN] ';
        break;
      case LogLevel.error:
        levelStr = '[ERROR]';
        break;
      case LogLevel.success:
        levelStr = '[OK]   ';
        break;
    }
    
    return '$timeStr $levelStr $message';
  }
} 