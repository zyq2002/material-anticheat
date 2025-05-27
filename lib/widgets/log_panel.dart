import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/log_service.dart';

class LogPanel extends ConsumerWidget {
  const LogPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logState = ref.watch(logServiceProvider);
    final logService = ref.read(logServiceProvider.notifier);
    final filteredLogs = logState.filteredLogs;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 16),
                const SizedBox(width: 8),
                const Text(
                  '运行日志',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                // 仅显示错误日志开关
                Tooltip(
                  message: '仅显示错误日志',
                  child: InkWell(
                    onTap: () => logService.toggleShowOnlyErrors(),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.error,
                        size: 14,
                        color: logState.showOnlyErrors 
                            ? Colors.red 
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // 自动滚动开关
                Tooltip(
                  message: logState.autoScroll ? '暂停自动滚动' : '开启自动滚动',
                  child: InkWell(
                    onTap: () => logService.toggleAutoScroll(),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        logState.autoScroll 
                            ? Icons.pause_circle_filled 
                            : Icons.play_circle_filled,
                        size: 14,
                        color: logState.autoScroll 
                            ? Colors.blue 
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${filteredLogs.length} 条',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => logService.clearLogs(),
                  icon: const Icon(Icons.clear_all, size: 16),
                  tooltip: '清空日志',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ),
          // 日志内容
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Text(
                      logState.showOnlyErrors ? '暂无错误日志' : '暂无日志',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      return _LogItem(log: log);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final LogEntry log;

  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    Color textColor;
    IconData icon;

    switch (log.level) {
      case LogLevel.success:
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case LogLevel.error:
        textColor = Colors.red.shade700;
        icon = Icons.error;
        break;
      case LogLevel.warning:
        textColor = Colors.orange.shade700;
        icon = Icons.warning;
        break;
      case LogLevel.info:
        textColor = Colors.blue.shade700;
        icon = Icons.info;
        break;
      case LogLevel.debug:
        textColor = Colors.grey.shade600;
        icon = Icons.bug_report;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 8),
          Text(
            '${log.timestamp.hour.toString().padLeft(2, '0')}:'
            '${log.timestamp.minute.toString().padLeft(2, '0')}:'
            '${log.timestamp.second.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              log.message,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
} 