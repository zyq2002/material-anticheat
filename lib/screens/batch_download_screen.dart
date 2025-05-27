import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../services/crawler_service.dart';

class BatchDownloadScreen extends HookConsumerWidget {
  const BatchDownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authTokenController = useTextEditingController();
    final cookieController = useTextEditingController();
    final startDate = useState(DateTime.now().subtract(const Duration(days: 7)));
    final endDate = useState(DateTime.now());
    final delayBetweenDays = useState(5);
    final delayBetweenImages = useState(500);
    
    final crawlerState = ref.watch(crawlerServiceProvider);

    // 初始化加载设置
    useEffect(() {
      Future.microtask(() async {
        final settings = await ref.read(crawlerServiceProvider.notifier).loadSettings();
        authTokenController.text = settings['auth_token'] ?? '';
        cookieController.text = settings['cookie'] ?? '';
      });
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('批量下载'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧设置面板
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 认证信息
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '认证信息',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: authTokenController,
                              enabled: !crawlerState.isRunning,
                              decoration: const InputDecoration(
                                labelText: 'Authorization Token',
                                border: OutlineInputBorder(),
                                hintText: '输入认证令牌',
                              ),
                              maxLines: 3,
                              minLines: 1,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: cookieController,
                              enabled: !crawlerState.isRunning,
                              decoration: const InputDecoration(
                                labelText: 'Cookie (可选)',
                                border: OutlineInputBorder(),
                                hintText: '输入Cookie信息',
                              ),
                              maxLines: 3,
                              minLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 日期范围选择
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '日期范围',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: crawlerState.isRunning
                                        ? null
                                        : () async {
                                            final date = await showDatePicker(
                                              context: context,
                                              initialDate: startDate.value,
                                              firstDate: DateTime(2020),
                                              lastDate: DateTime.now(),
                                            );
                                            if (date != null) {
                                              startDate.value = date;
                                              // 确保开始日期不晚于结束日期
                                              if (date.isAfter(endDate.value)) {
                                                endDate.value = date;
                                              }
                                            }
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '开始日期',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('yyyy-MM-dd').format(startDate.value),
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: crawlerState.isRunning
                                        ? null
                                        : () async {
                                            final date = await showDatePicker(
                                              context: context,
                                              initialDate: endDate.value,
                                              firstDate: startDate.value,
                                              lastDate: DateTime.now(),
                                            );
                                            if (date != null) {
                                              endDate.value = date;
                                            }
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '结束日期',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('yyyy-MM-dd').format(endDate.value),
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '将下载 ${endDate.value.difference(startDate.value).inDays + 1} 天的数据',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 速度控制
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '速度控制',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('每天之间的休息时间: ${delayBetweenDays.value} 秒'),
                                Slider(
                                  value: delayBetweenDays.value.toDouble(),
                                  min: 0,
                                  max: 60,
                                  divisions: 12,
                                  label: '${delayBetweenDays.value}秒',
                                  onChanged: crawlerState.isRunning
                                      ? null
                                      : (value) {
                                          delayBetweenDays.value = value.round();
                                        },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('每张图片之间的延迟: ${delayBetweenImages.value} 毫秒'),
                                Slider(
                                  value: delayBetweenImages.value.toDouble(),
                                  min: 100,
                                  max: 2000,
                                  divisions: 19,
                                  label: '${delayBetweenImages.value}ms',
                                  onChanged: crawlerState.isRunning
                                      ? null
                                      : (value) {
                                          delayBetweenImages.value = value.round();
                                        },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '💡 速度建议',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '• 图片延迟: 500ms 适合大部分情况\n• 天数间隔: 5秒 可避免服务器压力\n• 如遇到频率限制，适当增加延迟',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 控制按钮
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed: crawlerState.isRunning
                                    ? null
                                    : () async {
                                        if (authTokenController.text.trim().isEmpty) {
                                          _showErrorDialog(context, '请输入 Authorization Token');
                                          return;
                                        }
                                        
                                        if (startDate.value.isAfter(endDate.value)) {
                                          _showErrorDialog(context, '开始日期不能晚于结束日期');
                                          return;
                                        }
                                        
                                        final confirmed = await _showConfirmDialog(
                                          context,
                                          startDate.value,
                                          endDate.value,
                                          delayBetweenDays.value,
                                          delayBetweenImages.value,
                                        );
                                        
                                        if (confirmed) {
                                          await ref.read(crawlerServiceProvider.notifier).batchDownloadImages(
                                            authToken: authTokenController.text.trim(),
                                            cookie: cookieController.text.trim(),
                                            startDate: startDate.value,
                                            endDate: endDate.value,
                                            delayBetweenDaysSeconds: delayBetweenDays.value,
                                            delayBetweenImagesMs: delayBetweenImages.value,
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                icon: const Icon(Icons.download),
                                label: const Text(
                                  '开始批量下载',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              if (crawlerState.isRunning) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    ref.read(crawlerServiceProvider.notifier).stopCrawler();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  icon: const Icon(Icons.stop),
                                  label: const Text(
                                    '停止下载',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // 右侧进度显示
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '下载进度',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (crawlerState.isRunning) ...[
                        LinearProgressIndicator(
                          value: crawlerState.progress,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(crawlerState.progress * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  crawlerState.isRunning 
                                      ? Icons.downloading 
                                      : Icons.info_outline,
                                  size: 16,
                                  color: crawlerState.isRunning 
                                      ? Colors.blue 
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '当前状态',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              crawlerState.currentTask.isEmpty 
                                  ? '等待开始...' 
                                  : crawlerState.currentTask,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${crawlerState.completedTasks}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const Text(
                                    '成功',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.error, color: Colors.red),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${crawlerState.failedTasks}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const Text(
                                    '失败',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(
    BuildContext context,
    DateTime startDate,
    DateTime endDate,
    int delayBetweenDays,
    int delayBetweenImages,
  ) async {
    final totalDays = endDate.difference(startDate).inDays + 1;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认批量下载'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📅 日期范围: ${DateFormat('yyyy-MM-dd').format(startDate)} 至 ${DateFormat('yyyy-MM-dd').format(endDate)}'),
            Text('📊 总天数: $totalDays 天'),
            Text('⏱️ 天数间隔: $delayBetweenDays 秒'),
            Text('🖼️ 图片延迟: $delayBetweenImages 毫秒'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '⚠️ 批量下载可能需要较长时间，请确保网络连接稳定。',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认下载'),
          ),
        ],
      ),
    ) ?? false;
  }
} 