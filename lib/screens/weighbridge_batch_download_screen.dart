import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../services/weighbridge_crawler_service.dart';
import '../widgets/auth_input_card.dart';

class WeighbridgeBatchDownloadScreen extends HookConsumerWidget {
  const WeighbridgeBatchDownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authTokenController = useTextEditingController();
    final cookieController = useTextEditingController();
    final startDate = useState(DateTime.now().subtract(const Duration(days: 7)));
    final endDate = useState(DateTime.now());
    final delayBetweenDaysSeconds = useState(5);
    final delayBetweenImagesMs = useState(500);
    
    final crawlerState = ref.watch(weighbridgeCrawlerServiceProvider);

    // 初始化加载设置
    useEffect(() {
      Future.microtask(() async {
        final settings = await ref.read(weighbridgeCrawlerServiceProvider.notifier).loadSettings();
        authTokenController.text = settings['auth_token'] ?? '';
        cookieController.text = settings['cookie'] ?? '';
      });
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('过磅批量下载'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧配置面板
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 标题卡片
                      Card(
                        elevation: 2,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade600, Colors.blue.shade700],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.cloud_download,
                                size: 48,
                                color: Colors.white,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '过磅批量下载',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '批量下载多日过磅记录图片',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 认证输入
                      AuthInputCard(
                        controller: authTokenController,
                        cookieController: cookieController,
                        enabled: !crawlerState.isRunning,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 日期范围选择
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.date_range,
                                    color: crawlerState.isRunning ? Colors.grey : Colors.blue.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '日期范围选择',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: crawlerState.isRunning ? Colors.grey : Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // 开始日期
                              Row(
                                children: [
                                  const Text('开始日期: '),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: crawlerState.isRunning ? null : () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: startDate.value,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime.now(),
                                        );
                                        if (date != null) {
                                          startDate.value = date;
                                        }
                                      },
                                      child: Text(
                                        '${startDate.value.year}-${startDate.value.month.toString().padLeft(2, '0')}-${startDate.value.day.toString().padLeft(2, '0')}',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // 结束日期
                              Row(
                                children: [
                                  const Text('结束日期: '),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: crawlerState.isRunning ? null : () async {
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
                                      child: Text(
                                        '${endDate.value.year}-${endDate.value.month.toString().padLeft(2, '0')}-${endDate.value.day.toString().padLeft(2, '0')}',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Text(
                                '总天数: ${endDate.value.difference(startDate.value).inDays + 1} 天',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 下载参数设置
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.settings,
                                    color: crawlerState.isRunning ? Colors.grey : Colors.orange.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '下载参数设置',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: crawlerState.isRunning ? Colors.grey : Colors.orange.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // 天间休息时间
                              Row(
                                children: [
                                  const Text('天间休息时间: '),
                                  Expanded(
                                    child: Slider(
                                      value: delayBetweenDaysSeconds.value.toDouble(),
                                      min: 0,
                                      max: 30,
                                      divisions: 30,
                                      label: '${delayBetweenDaysSeconds.value}秒',
                                      onChanged: crawlerState.isRunning ? null : (value) {
                                        delayBetweenDaysSeconds.value = value.round();
                                      },
                                    ),
                                  ),
                                  Text('${delayBetweenDaysSeconds.value}秒'),
                                ],
                              ),
                              
                              // 图片间延迟
                              Row(
                                children: [
                                  const Text('图片间延迟: '),
                                  Expanded(
                                    child: Slider(
                                      value: delayBetweenImagesMs.value.toDouble(),
                                      min: 0,
                                      max: 2000,
                                      divisions: 40,
                                      label: '${delayBetweenImagesMs.value}ms',
                                      onChanged: crawlerState.isRunning ? null : (value) {
                                        delayBetweenImagesMs.value = value.round();
                                      },
                                    ),
                                  ),
                                  Text('${delayBetweenImagesMs.value}ms'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 控制按钮
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: crawlerState.isRunning ? null : () async {
                                    if (authTokenController.text.trim().isEmpty) {
                                      _showErrorDialog(context, '请输入 Authorization Token');
                                      return;
                                    }
                                    
                                    if (endDate.value.isBefore(startDate.value)) {
                                      _showErrorDialog(context, '结束日期不能早于开始日期');
                                      return;
                                    }
                                    
                                    await ref.read(weighbridgeCrawlerServiceProvider.notifier).batchDownloadImages(
                                      authToken: authTokenController.text.trim(),
                                      cookie: cookieController.text.trim(),
                                      startDate: startDate.value,
                                      endDate: endDate.value,
                                      delayBetweenDaysSeconds: delayBetweenDaysSeconds.value,
                                      delayBetweenImagesMs: delayBetweenImagesMs.value,
                                    );
                                  },
                                  icon: Icon(crawlerState.isRunning ? Icons.hourglass_empty : Icons.download),
                                  label: Text(crawlerState.isRunning ? '下载中...' : '开始批量下载'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: crawlerState.isRunning ? Colors.grey : Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              
                              if (crawlerState.isRunning) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ref.read(weighbridgeCrawlerServiceProvider.notifier).stopCrawler();
                                    },
                                    icon: const Icon(Icons.stop),
                                    label: const Text('停止下载'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
                flex: 3,
                child: Column(
                  children: [
                    // 批量下载进度显示
                    Expanded(
                      child: WeighbridgeBatchProgressCard(
                        state: crawlerState,
                        startDate: startDate.value,
                        endDate: endDate.value,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
}

// 批量下载进度显示卡片
class WeighbridgeBatchProgressCard extends StatelessWidget {
  final WeighbridgeCrawlerState state;
  final DateTime startDate;
  final DateTime endDate;

  const WeighbridgeBatchProgressCard({
    super.key,
    required this.state,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final totalDays = endDate.difference(startDate).inDays + 1;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  state.isRunning ? Icons.cloud_download : Icons.cloud_download_outlined,
                  color: state.isRunning ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text(
                  '批量下载进度',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 状态指示器
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: state.isRunning ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: state.isRunning ? Colors.blue.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Text(
                state.isRunning ? '下载中' : '待机',
                style: TextStyle(
                  color: state.isRunning ? Colors.blue : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 日期范围信息
            Text(
              '日期范围: ${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')} 至 ${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            
            Text(
              '总天数: $totalDays 天',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            
            const SizedBox(height: 16),
            
            // 当前任务
            Text(
              '当前任务: ${state.currentTask}',
              style: const TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 8),
            
            // 进度条
            LinearProgressIndicator(
              value: state.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                state.isRunning ? Colors.blue : Colors.grey,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 进度文本
            Text(
              '${(state.progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            
            const SizedBox(height: 16),
            
            // 统计信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('总记录', state.totalTasks.toString(), Colors.blue),
                _buildStatItem('已完成', state.completedTasks.toString(), Colors.green),
                _buildStatItem('失败', state.failedTasks.toString(), Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
} 