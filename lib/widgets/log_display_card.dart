import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/log_service.dart';

class LogDisplayCard extends ConsumerStatefulWidget {
  const LogDisplayCard({super.key});

  @override
  ConsumerState<LogDisplayCard> createState() => _LogDisplayCardState();
}

class _LogDisplayCardState extends ConsumerState<LogDisplayCard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 添加初始日志
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(logServiceProvider.notifier).info('应用已启动');
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final logState = ref.watch(logServiceProvider);
    final logService = ref.read(logServiceProvider.notifier);
    final filteredLogs = logState.filteredLogs;

    // 当日志更新时且开启自动滚动时，自动滚动到底部
    ref.listen(logServiceProvider, (previous, next) {
      if (next.autoScroll && 
          next.filteredLogs.isNotEmpty && 
          (previous?.filteredLogs.length ?? 0) < next.filteredLogs.length) {
        _scrollToBottom();
      }
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.terminal, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '运行日志',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error,
                            size: 16,
                            color: logState.showOnlyErrors 
                                ? Colors.red 
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '错误',
                            style: TextStyle(
                              fontSize: 12,
                              color: logState.showOnlyErrors 
                                  ? Colors.red 
                                  : Colors.grey,
                              fontWeight: logState.showOnlyErrors 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 自动滚动开关
                Tooltip(
                  message: logState.autoScroll ? '暂停自动滚动' : '开启自动滚动',
                  child: InkWell(
                    onTap: () => logService.toggleAutoScroll(),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        logState.autoScroll 
                            ? Icons.pause_circle_filled 
                            : Icons.play_circle_filled,
                        size: 20,
                        color: logState.autoScroll 
                            ? Colors.blue 
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                  icon: const Icon(Icons.clear_all),
                  tooltip: '清空日志',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey[50],
                ),
                child: filteredLogs.isEmpty
                    ? Center(
                        child: Text(
                          logState.showOnlyErrors ? '暂无错误日志' : '暂无日志',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          return _buildLogItem(log);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(LogEntry log) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Text(
            '${log.timestamp.hour.toString().padLeft(2, '0')}:'
            '${log.timestamp.minute.toString().padLeft(2, '0')}:'
            '${log.timestamp.second.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              log.message,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
} 