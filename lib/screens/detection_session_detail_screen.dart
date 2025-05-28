import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/detection_result.dart';
import '../services/detection_history_service.dart';

class DetectionSessionDetailScreen extends HookConsumerWidget {
  final DetectionSession session;

  const DetectionSessionDetailScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyService = ref.read(detectionHistoryServiceProvider);
    final filteredResults = useState(session.results);
    final selectedLevel = useState<SimilarityLevel?>(null);
    final selectedStatus = useState<String?>(null);

    // 筛选结果
    void filterResults() {
      var filtered = session.results;

      if (selectedLevel.value != null) {
        filtered = filtered.where((r) => r.level == selectedLevel.value).toList();
      }

      if (selectedStatus.value != null) {
        filtered = filtered.where((r) => r.status == selectedStatus.value).toList();
      }

      filteredResults.value = filtered;
    }

    // 监听筛选条件变化
    useEffect(() {
      filterResults();
      return null;
    }, [selectedLevel.value, selectedStatus.value]);

    return Scaffold(
      appBar: AppBar(
        title: Text('检测详情 - ${session.detectionType == "duplicate" ? "重复检测" : "可疑检测"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _exportSession(context, historyService),
            tooltip: '导出报告',
          ),
        ],
      ),
      body: Column(
        children: [
          // 会话信息
          _buildSessionInfo(context),
          
          // 筛选器
          _buildFilters(context, selectedLevel, selectedStatus),

          const Divider(height: 1),

          // 结果列表
          Expanded(
            child: filteredResults.value.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredResults.value.length,
                    itemBuilder: (context, index) {
                      final result = filteredResults.value[index];
                      return DetectionResultCard(
                        result: result,
                        onStatusUpdate: (status, notes) =>
                            _updateResultStatus(context, historyService, result.id, status, notes),
                        onImageTap: (imagePath) => _showImageDetail(context, imagePath),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfo(BuildContext context) {
    final duration = session.endTime != null
        ? session.endTime!.difference(session.startTime)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                session.detectionType == 'duplicate'
                    ? Icons.content_copy
                    : Icons.search,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '检测会话 ${session.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '${session.detectionType == "duplicate" ? "重复检测" : "可疑检测"}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 统计信息
          Row(
            children: [
              _buildInfoChip('总对比数', '${session.totalComparisons}', Colors.blue),
              const SizedBox(width: 8),
              _buildInfoChip('发现问题', '${session.foundIssues}', 
                  session.foundIssues > 0 ? Colors.orange : Colors.green),
              const SizedBox(width: 8),
              _buildInfoChip('状态', session.status, Colors.purple),
            ],
          ),

          const SizedBox(height: 12),

          // 时间信息
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.play_arrow, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '开始时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startTime)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              if (session.endTime != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.stop, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '结束时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(session.endTime!)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
              if (duration != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '用时: ${_formatDuration(duration)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    ValueNotifier<SimilarityLevel?> selectedLevel,
    ValueNotifier<String?> selectedStatus,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('筛选条件:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          // 风险级别筛选
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('全部级别'),
                selected: selectedLevel.value == null,
                onSelected: (selected) {
                  selectedLevel.value = selected ? null : selectedLevel.value;
                },
              ),
              ...SimilarityLevel.values.map((level) =>
                FilterChip(
                  label: Text(SimilarityStandards.getLevelName(level)),
                  selected: selectedLevel.value == level,
                  onSelected: (selected) {
                    selectedLevel.value = selected ? level : null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 状态筛选
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('全部状态'),
                selected: selectedStatus.value == null,
                onSelected: (selected) {
                  selectedStatus.value = selected ? null : selectedStatus.value;
                },
              ),
              ...['pending', 'reviewed', 'confirmed', 'dismissed'].map((status) =>
                FilterChip(
                  label: Text(SimilarityStandards.getStatusName(status)),
                  selected: selectedStatus.value == status,
                  onSelected: (selected) {
                    selectedStatus.value = selected ? status : null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '没有符合条件的结果',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            '尝试调整筛选条件',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}小时${duration.inMinutes.remainder(60)}分钟';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分钟${duration.inSeconds.remainder(60)}秒';
    } else {
      return '${duration.inSeconds}秒';
    }
  }

  Future<void> _updateResultStatus(
    BuildContext context,
    DetectionHistoryService historyService,
    String resultId,
    String status,
    String? notes,
  ) async {
    try {
      await historyService.updateResultStatus(session.id, resultId, status, notes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('状态已更新为: ${SimilarityStandards.getStatusName(status)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新状态失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportSession(
    BuildContext context,
    DetectionHistoryService historyService,
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

  void _showImageDetail(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('图片详情'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 500, maxWidth: 600),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 48, color: Colors.red),
                          SizedBox(height: 16),
                          Text('无法加载图片'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                imagePath.split('/').last,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetectionResultCard extends StatelessWidget {
  final DetectionResult result;
  final Function(String status, String? notes) onStatusUpdate;
  final Function(String imagePath) onImageTap;

  const DetectionResultCard({
    super.key,
    required this.result,
    required this.onStatusUpdate,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部信息
            Row(
              children: [
                _buildLevelIndicator(result.level),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '相似度: ${(result.similarity * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '图片类型: ${result.imageType}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (status) => _showStatusUpdateDialog(context, status),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'reviewed',
                      child: Text('标记为已审核'),
                    ),
                    const PopupMenuItem(
                      value: 'confirmed',
                      child: Text('确认为问题'),
                    ),
                    const PopupMenuItem(
                      value: 'dismissed',
                      child: Text('忽略此结果'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 记录信息
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('记录 A', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(result.recordName1),
                    ],
                  ),
                ),
                const Icon(Icons.compare_arrows, color: Colors.grey),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('记录 B', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(result.recordName2),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 图片对比
            Row(
              children: [
                Expanded(child: _buildImageCard(context, result.imagePath1, '图片 A')),
                const SizedBox(width: 16),
                Expanded(child: _buildImageCard(context, result.imagePath2, '图片 B')),
              ],
            ),

            const SizedBox(height: 16),

            // 状态和时间信息
            Row(
              children: [
                _buildStatusChip(result.status),
                const Spacer(),
                Text(
                  DateFormat('MM-dd HH:mm').format(result.detectionTime),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),

            // 备注
            if (result.notes != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '备注: ${result.notes}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLevelIndicator(SimilarityLevel level) {
    Color color;
    IconData icon;

    switch (level) {
      case SimilarityLevel.critical:
        color = Colors.red;
        icon = Icons.dangerous;
        break;
      case SimilarityLevel.warning:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case SimilarityLevel.suspicious:
        color = Colors.yellow[700]!;
        icon = Icons.help;
        break;
      case SimilarityLevel.attention:
        color = Colors.blue;
        icon = Icons.info;
        break;
      case SimilarityLevel.normal:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            SimilarityStandards.getLevelName(level),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'confirmed':
        color = Colors.red;
        break;
      case 'reviewed':
        color = Colors.green;
        break;
      case 'dismissed':
        color = Colors.grey;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        SimilarityStandards.getStatusName(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildImageCard(BuildContext context, String imagePath, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => onImageTap(imagePath),
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        Text(
                          '加载失败',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          imagePath.split('/').last,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showStatusUpdateDialog(BuildContext context, String status) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('更新状态为: ${SimilarityStandards.getStatusName(status)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('确认要将此结果的状态更新为"${SimilarityStandards.getStatusName(status)}"吗？'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: '备注 (可选)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onStatusUpdate(status, notesController.text.isNotEmpty ? notesController.text : null);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
} 