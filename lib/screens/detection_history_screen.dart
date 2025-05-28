import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/detection_result.dart';
import '../services/detection_history_service.dart';
import 'detection_session_detail_screen.dart';

class DetectionHistoryScreen extends HookConsumerWidget {
  const DetectionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyService = ref.read(detectionHistoryServiceProvider);
    final sessionHistory = useState<List<DetectionSession>>([]);
    final filteredHistory = useState<List<DetectionSession>>([]);
    final isLoading = useState(true);
    final selectedType = useState<String?>(null);
    final searchController = useTextEditingController();

    // 加载历史数据
    useEffect(() {
      Future.microtask(() async {
        try {
          final history = await historyService.getDetectionHistory();
          sessionHistory.value = history;
          filteredHistory.value = history;
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('加载历史记录失败: $e'), backgroundColor: Colors.red),
            );
          }
        } finally {
          isLoading.value = false;
        }
      });
      return null;
    }, []);

    // 筛选历史记录
    void filterHistory() {
      var filtered = sessionHistory.value;

      // 按类型筛选
      if (selectedType.value != null) {
        filtered = filtered.where((session) => session.detectionType == selectedType.value).toList();
      }

      // 按搜索关键词筛选
      final searchText = searchController.text.toLowerCase();
      if (searchText.isNotEmpty) {
        filtered = filtered.where((session) {
          return session.id.toLowerCase().contains(searchText) ||
                 session.detectionType.toLowerCase().contains(searchText) ||
                 session.results.any((result) =>
                     result.recordName1.toLowerCase().contains(searchText) ||
                     result.recordName2.toLowerCase().contains(searchText));
        }).toList();
      }

      filteredHistory.value = filtered;
    }

    // 监听筛选条件变化
    useEffect(() {
      filterHistory();
      return null;
    }, [selectedType.value]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('检测历史记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => _showStatistics(context, historyService),
            tooltip: '统计信息',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _exportAllReports(context, historyService),
            tooltip: '导出全部',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'clear_all') {
                await _confirmClearAll(context, historyService, () async {
                  final history = await historyService.getDetectionHistory();
                  sessionHistory.value = history;
                  filteredHistory.value = history;
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('清空全部'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选栏
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // 搜索框
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: '搜索会话ID或记录名称...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => filterHistory(),
                ),
                const SizedBox(height: 12),
                
                // 类型筛选
                Row(
                  children: [
                    const Text('检测类型: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('全部'),
                            selected: selectedType.value == null,
                            onSelected: (selected) {
                              selectedType.value = selected ? null : selectedType.value;
                            },
                          ),
                          FilterChip(
                            label: const Text('重复检测'),
                            selected: selectedType.value == 'duplicate',
                            onSelected: (selected) {
                              selectedType.value = selected ? 'duplicate' : null;
                            },
                          ),
                          FilterChip(
                            label: const Text('可疑检测'),
                            selected: selectedType.value == 'suspicious',
                            onSelected: (selected) {
                              selectedType.value = selected ? 'suspicious' : null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 历史记录列表
          Expanded(
            child: isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : filteredHistory.value.isEmpty
                    ? _buildEmptyState(sessionHistory.value.isEmpty)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredHistory.value.length,
                        itemBuilder: (context, index) {
                          final session = filteredHistory.value[index];
                          return DetectionSessionCard(
                            session: session,
                            onTap: () => _viewSessionDetails(context, session),
                            onExport: () => _exportSession(context, historyService, session),
                            onDelete: () => _deleteSession(context, historyService, session.id, () async {
                              final history = await historyService.getDetectionHistory();
                              sessionHistory.value = history;
                              filterHistory();
                            }),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isCompletelyEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCompletelyEmpty ? Icons.history : Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isCompletelyEmpty ? '暂无检测记录' : '没有符合条件的记录',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            isCompletelyEmpty ? '执行图片相似度检测后，历史记录会显示在这里' : '尝试调整筛选条件',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _viewSessionDetails(BuildContext context, DetectionSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetectionSessionDetailScreen(session: session),
      ),
    );
  }

  Future<void> _exportSession(
    BuildContext context,
    DetectionHistoryService historyService,
    DetectionSession session,
  ) async {
    try {
      final csvContent = await historyService.exportDetectionReport(session);
      await historyService.copyReportToClipboard(csvContent);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('检测报告已复制到剪贴板'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportAllReports(
    BuildContext context,
    DetectionHistoryService historyService,
  ) async {
    try {
      final csvContent = await historyService.exportAllDetectionHistory();
      await historyService.copyReportToClipboard(csvContent);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('全部检测历史已复制到剪贴板'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSession(
    BuildContext context,
    DetectionHistoryService historyService,
    String sessionId,
    VoidCallback onDeleted,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个检测会话吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await historyService.deleteDetectionSession(sessionId);
        onDeleted();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('检测会话已删除'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    DetectionHistoryService historyService,
    VoidCallback onCleared,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有检测历史吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await historyService.clearAllHistory();
        onCleared();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('所有检测历史已清空'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('清空失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showStatistics(
    BuildContext context,
    DetectionHistoryService historyService,
  ) async {
    try {
      final stats = await historyService.getStatistics();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('统计信息'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatItem('总检测会话数', '${stats['totalSessions'] ?? 0}'),
                  _buildStatItem('总检测结果数', '${stats['totalResults'] ?? 0}'),
                  _buildStatItem('重复检测会话', '${stats['duplicateSessions'] ?? 0}'),
                  _buildStatItem('可疑检测会话', '${stats['suspiciousSessions'] ?? 0}'),
                  
                  if (stats['levelCounts'] != null) ...[
                    const SizedBox(height: 16),
                    const Text('风险级别分布:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...((stats['levelCounts'] as Map<SimilarityLevel, int>)).entries.map(
                      (entry) => _buildStatItem(
                        SimilarityStandards.getLevelName(entry.key),
                        '${entry.value}',
                      ),
                    ),
                  ],
                  
                  if (stats['lastDetectionTime'] != null) ...[
                    const SizedBox(height: 16),
                    _buildStatItem(
                      '最近检测时间',
                      DateFormat('yyyy-MM-dd HH:mm').format(
                        DateTime.parse(stats['lastDetectionTime']),
                      ),
                    ),
                  ],
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取统计信息失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class DetectionSessionCard extends StatelessWidget {
  final DetectionSession session;
  final VoidCallback onTap;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const DetectionSessionCard({
    super.key,
    required this.session,
    required this.onTap,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final criticalCount = session.results
        .where((r) => r.level == SimilarityLevel.critical)
        .length;
    final warningCount = session.results
        .where((r) => r.level == SimilarityLevel.warning)
        .length;
    final suspiciousCount = session.results
        .where((r) => r.level == SimilarityLevel.suspicious)
        .length;

    final hasHighRisk = criticalCount > 0 || warningCount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部信息
              Row(
                children: [
                  Icon(
                    session.detectionType == 'duplicate'
                        ? Icons.content_copy
                        : Icons.search,
                    color: hasHighRisk ? Colors.red : Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${session.detectionType == "duplicate" ? "重复检测" : "可疑检测"} - ${DateFormat("MM-dd HH:mm").format(session.startTime)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'ID: ${session.id}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'export':
                          onExport();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.file_download),
                            SizedBox(width: 8),
                            Text('导出'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 统计信息
              Row(
                children: [
                  _buildStatChip(
                    '对比: ${session.totalComparisons}',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    '问题: ${session.foundIssues}',
                    session.foundIssues > 0 ? Colors.orange : Colors.green,
                  ),
                ],
              ),

              // 风险级别统计
              if (hasHighRisk || suspiciousCount > 0) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (criticalCount > 0)
                      _buildStatChip('严重: $criticalCount', Colors.red),
                    if (warningCount > 0)
                      _buildStatChip('警告: $warningCount', Colors.orange),
                    if (suspiciousCount > 0)
                      _buildStatChip('可疑: $suspiciousCount', Colors.yellow[700]!),
                  ],
                ),
              ],

              const SizedBox(height: 8),

              // 时间信息
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '开始: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startTime)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),

              if (session.endTime != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer_off, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '结束: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(session.endTime!)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 