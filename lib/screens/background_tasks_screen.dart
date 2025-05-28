import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../services/background_task_service.dart';

class BackgroundTasksScreen extends HookConsumerWidget {
  const BackgroundTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(backgroundTasksProvider);
    final backgroundService = ref.read(backgroundTaskServiceProvider);
    final tabController = useTabController(initialLength: 3);

    // 分类任务
    final runningTasks = tasks.where((task) => task.isRunning || task.status == BackgroundTaskStatus.pending || task.status == BackgroundTaskStatus.paused).toList();
    final completedTasks = tasks.where((task) => task.isCompleted).toList();
    final failedTasks = tasks.where((task) => task.isFailed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('后台任务管理'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        bottom: TabBar(
          controller: tabController,
          labelColor: Colors.blue[600],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue[600],
          tabs: [
            Tab(
              text: '进行中 (${runningTasks.length})',
              icon: const Icon(Icons.play_circle_outline),
            ),
            Tab(
              text: '已完成 (${completedTasks.length})',
              icon: const Icon(Icons.check_circle_outline),
            ),
            Tab(
              text: '失败 (${failedTasks.length})',
              icon: const Icon(Icons.error_outline),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => _showClearDialog(context, backgroundService),
            tooltip: '清理已完成任务',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(backgroundTasksProvider),
            tooltip: '刷新',
          ),
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _buildTaskList(context, ref, runningTasks, true),
          _buildTaskList(context, ref, completedTasks, false),
          _buildTaskList(context, ref, failedTasks, false),
        ],
      ),
      floatingActionButton: _buildStatsFAB(context, backgroundService),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    WidgetRef ref,
    List<BackgroundTask> tasks,
    bool isActive,
  ) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.work_outline : Icons.assignment_turned_in,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? '暂无运行中的任务' : '暂无任务记录',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildTaskCard(context, ref, tasks[index]);
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, BackgroundTask task) {
    final backgroundService = ref.read(backgroundTaskServiceProvider);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(task),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${task.typeText} • ${task.statusText}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTaskActions(context, backgroundService, task),
              ],
            ),
            
            if (task.isRunning || task.status == BackgroundTaskStatus.paused) ...[
              const SizedBox(height: 16),
              _buildProgressIndicator(task),
            ],
            
            const SizedBox(height: 12),
            _buildTaskDetails(task),
            
            if (task.error != null) ...[
              const SizedBox(height: 12),
              _buildErrorDisplay(task.error!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BackgroundTask task) {
    Color color;
    IconData icon;
    
    switch (task.status) {
      case BackgroundTaskStatus.pending:
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case BackgroundTaskStatus.running:
        color = Colors.blue;
        icon = Icons.play_circle_filled;
        break;
      case BackgroundTaskStatus.paused:
        color = Colors.amber;
        icon = Icons.pause_circle_filled;
        break;
      case BackgroundTaskStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case BackgroundTaskStatus.cancelled:
        color = Colors.grey;
        icon = Icons.cancel;
        break;
      case BackgroundTaskStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildTaskActions(BuildContext context, BackgroundTaskService service, BackgroundTask task) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'pause':
            await service.pauseTask(task.id);
            break;
          case 'resume':
            await service.resumeTask(task.id);
            break;
          case 'cancel':
            await service.cancelTask(task.id);
            break;
          case 'delete':
            await service.deleteTask(task.id);
            break;
          case 'details':
            _showTaskDetails(context, task);
            break;
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        
        if (task.canPause) {
          items.add(const PopupMenuItem(
            value: 'pause',
            child: ListTile(
              leading: Icon(Icons.pause),
              title: Text('暂停'),
              dense: true,
            ),
          ));
        }
        
        if (task.canResume) {
          items.add(const PopupMenuItem(
            value: 'resume',
            child: ListTile(
              leading: Icon(Icons.play_arrow),
              title: Text('继续'),
              dense: true,
            ),
          ));
        }
        
        if (task.canCancel) {
          items.add(const PopupMenuItem(
            value: 'cancel',
            child: ListTile(
              leading: Icon(Icons.stop),
              title: Text('取消'),
              dense: true,
            ),
          ));
        }
        
        items.addAll([
          const PopupMenuItem(
            value: 'details',
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('详情'),
              dense: true,
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('删除'),
              dense: true,
            ),
          ),
        ]);
        
        return items;
      },
    );
  }

  Widget _buildProgressIndicator(BackgroundTask task) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '进度: ${(task.progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              '${task.processedItems}/${task.totalItems}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: task.progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            task.status == BackgroundTaskStatus.paused 
              ? Colors.amber 
              : Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskDetails(BackgroundTask task) {
    final formatter = DateFormat('MM-dd HH:mm:ss');
    
    return Column(
      children: [
        _buildDetailRow('开始时间', formatter.format(task.startTime)),
        if (task.endTime != null)
          _buildDetailRow('结束时间', formatter.format(task.endTime!)),
        _buildDetailRow('耗时', _formatDuration(task.elapsed)),
        if (task.results.isNotEmpty)
          _buildDetailRow('检测结果', '${task.results.length} 个对比结果'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsFAB(BuildContext context, BackgroundTaskService service) {
    return FloatingActionButton.extended(
      onPressed: () => _showStatistics(context, service),
      icon: const Icon(Icons.analytics_outlined),
      label: const Text('统计'),
      backgroundColor: Colors.blue[600],
    );
  }

  void _showTaskDetails(BuildContext context, BackgroundTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('任务ID', task.id),
              _buildDetailRow('类型', task.typeText),
              _buildDetailRow('状态', task.statusText),
              _buildDetailRow('进度', '${(task.progress * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 16),
              const Text('配置信息:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...task.config.entries.map((e) => 
                _buildDetailRow(e.key, e.value.toString())
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showStatistics(BuildContext context, BackgroundTaskService service) {
    final stats = service.getTaskStatistics();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('任务统计'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatItem('总任务数', stats['total'].toString(), Colors.blue),
            _buildStatItem('运行中', stats['running'].toString(), Colors.green),
            _buildStatItem('已完成', stats['completed'].toString(), Colors.blue),
            _buildStatItem('失败', stats['failed'].toString(), Colors.red),
            _buildStatItem('等待中', stats['pending'].toString(), Colors.orange),
            _buildStatItem('已暂停', stats['paused'].toString(), Colors.amber),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, BackgroundTaskService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理已完成任务'),
        content: const Text('确定要清理所有已完成和失败的任务吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              service.clearCompletedTasks();
              Navigator.of(context).pop();
            },
            child: const Text('清理'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}时${minutes}分${seconds}秒';
    } else if (minutes > 0) {
      return '${minutes}分${seconds}秒';
    } else {
      return '${seconds}秒';
    }
  }
} 