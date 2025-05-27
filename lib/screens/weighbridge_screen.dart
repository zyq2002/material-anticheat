import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../services/weighbridge_crawler_service.dart';
import '../widgets/auth_input_card.dart';
import '../widgets/date_selector_card.dart';
import '../widgets/interval_setting_card.dart';
import '../widgets/save_path_card.dart';
import '../widgets/api_settings_card.dart';
import '../widgets/control_buttons_card.dart';
import '../widgets/log_display_card.dart';
import 'weighbridge_batch_download_screen.dart';
import 'weighbridge_image_gallery_screen.dart';
import 'weighbridge_duplicate_detection_screen.dart';
import 'weighbridge_suspicious_images_screen.dart';

class WeighbridgeScreen extends HookConsumerWidget {
  const WeighbridgeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authTokenController = useTextEditingController();
    final cookieController = useTextEditingController();
    final selectedDate = useState(DateTime.now());
    final intervalMinutes = useState(30);
    final savePath = useState('');
    
    final crawlerState = ref.watch(weighbridgeCrawlerServiceProvider);

    // 初始化加载设置
    useEffect(() {
      Future.microtask(() async {
        final settings = await ref.read(weighbridgeCrawlerServiceProvider.notifier).loadSettings();
        authTokenController.text = settings['auth_token'] ?? '';
        cookieController.text = settings['cookie'] ?? '';
        intervalMinutes.value = settings['interval_minutes'] ?? 30;
        savePath.value = settings['save_path'] ?? '';
      });
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('过磅记录反作弊工具'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'batch_download':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeighbridgeBatchDownloadScreen(),
                    ),
                  );
                  break;
                case 'image_gallery':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeighbridgeImageGalleryScreen(),
                    ),
                  );
                  break;
                case 'duplicate_detection':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeighbridgeDuplicateDetectionScreen(),
                    ),
                  );
                  break;
                case 'suspicious_images':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeighbridgeSuspiciousImagesScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'batch_download',
                child: ListTile(
                  leading: Icon(Icons.download_for_offline),
                  title: Text('批量下载'),
                  subtitle: Text('下载多天的过磅图片'),
                ),
              ),
              const PopupMenuItem(
                value: 'image_gallery',
                child: ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('图片库'),
                  subtitle: Text('查看已下载的过磅图片'),
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate_detection',
                child: ListTile(
                  leading: Icon(Icons.content_copy),
                  title: Text('重复检测'),
                  subtitle: Text('检测重复的过磅图片'),
                ),
              ),
              const PopupMenuItem(
                value: 'suspicious_images',
                child: ListTile(
                  leading: Icon(Icons.security),
                  title: Text('可疑图片检测'),
                  subtitle: Text('检测相似度过高的图片'),
                ),
              ),
            ],
          ),
        ],
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
              // 左侧控制面板
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 页面标题卡片
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
                                Icons.scale,
                                size: 48,
                                color: Colors.white,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '过磅记录爬虫',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '自动爬取过磅记录和车辆照片',
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
                      
                      // Authorization Token 输入
                      AuthInputCard(
                        controller: authTokenController,
                        cookieController: cookieController,
                        enabled: !crawlerState.isRunning,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 日期选择
                      DateSelectorCard(
                        selectedDate: selectedDate.value,
                        onDateChanged: (date) => selectedDate.value = date,
                        enabled: !crawlerState.isRunning,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 爬虫间隔设置
                      IntervalSettingCard(
                        intervalMinutes: intervalMinutes.value,
                        onChanged: (value) => intervalMinutes.value = value,
                        enabled: !crawlerState.isRunning,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 保存路径设置
                      SavePathCard(
                        savePath: savePath.value,
                        onPathChanged: (path) {
                          savePath.value = path;
                          ref.read(weighbridgeCrawlerServiceProvider.notifier).setSavePath(path);
                        },
                        enabled: !crawlerState.isRunning,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 重试设置
                      WeighbridgeRetrySettingsCard(
                        enabled: !crawlerState.isRunning,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // API设置
                      ApiSettingsCard(
                        enabled: !crawlerState.isRunning,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 控制按钮
                      ControlButtonsCard(
                        isRunning: crawlerState.isRunning,
                        onStart: () async {
                          if (authTokenController.text.trim().isEmpty) {
                            _showErrorDialog(context, '请输入 Authorization Token');
                            return;
                          }
                          
                          await ref.read(weighbridgeCrawlerServiceProvider.notifier).startCrawler(
                            authToken: authTokenController.text.trim(),
                            cookie: cookieController.text.trim(),
                            selectedDate: selectedDate.value,
                            intervalMinutes: intervalMinutes.value,
                          );
                        },
                        onStop: () {
                          ref.read(weighbridgeCrawlerServiceProvider.notifier).stopCrawler();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 右侧状态显示区域
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // 进度显示
                    Expanded(
                      flex: 1,
                      child: WeighbridgeProgressDisplayCard(
                        state: crawlerState,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 日志显示
                    const Expanded(
                      flex: 2,
                      child: LogDisplayCard(),
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

// 过磅进度显示卡片
class WeighbridgeProgressDisplayCard extends StatelessWidget {
  final WeighbridgeCrawlerState state;

  const WeighbridgeProgressDisplayCard({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  state.isRunning ? Icons.scale : Icons.scale_outlined,
                  color: state.isRunning ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text(
                  '过磅爬取进度',
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
                state.isRunning ? '运行中' : '已停止',
                style: TextStyle(
                  color: state.isRunning ? Colors.blue : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                _buildStatItem('总任务', state.totalTasks.toString(), Colors.blue),
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

// 过磅重试设置卡片
class WeighbridgeRetrySettingsCard extends ConsumerWidget {
  final bool enabled;

  const WeighbridgeRetrySettingsCard({
    super.key,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crawlerState = ref.watch(weighbridgeCrawlerServiceProvider);
    final retrySettings = crawlerState.retrySettings;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.refresh,
                  color: enabled ? Colors.orange.shade600 : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  '过磅重试设置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: enabled ? Colors.orange.shade600 : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 最大重试次数
            Row(
              children: [
                const Text('最大重试次数: '),
                Expanded(
                  child: Slider(
                    value: retrySettings.maxRetries.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${retrySettings.maxRetries}次',
                    onChanged: enabled ? (value) {
                      final newSettings = retrySettings.copyWith(
                        maxRetries: value.round(),
                      );
                      ref.read(weighbridgeCrawlerServiceProvider.notifier)
                          .setRetrySettings(newSettings);
                    } : null,
                  ),
                ),
                Text('${retrySettings.maxRetries}次'),
              ],
            ),
            
            // 重试间隔
            Row(
              children: [
                const Text('重试间隔: '),
                Expanded(
                  child: Slider(
                    value: retrySettings.retryDelay.inSeconds.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${retrySettings.retryDelay.inSeconds}秒',
                    onChanged: enabled ? (value) {
                      final newSettings = retrySettings.copyWith(
                        retryDelay: Duration(seconds: value.round()),
                      );
                      ref.read(weighbridgeCrawlerServiceProvider.notifier)
                          .setRetrySettings(newSettings);
                    } : null,
                  ),
                ),
                Text('${retrySettings.retryDelay.inSeconds}秒'),
              ],
            ),
            
            // 图片间延迟
            Row(
              children: [
                const Text('图片间延迟: '),
                Expanded(
                  child: Slider(
                    value: retrySettings.delayBetweenImagesMs.toDouble(),
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    label: '${retrySettings.delayBetweenImagesMs}ms',
                    onChanged: enabled ? (value) {
                      final newSettings = retrySettings.copyWith(
                        delayBetweenImagesMs: value.round(),
                      );
                      ref.read(weighbridgeCrawlerServiceProvider.notifier)
                          .setRetrySettings(newSettings);
                    } : null,
                  ),
                ),
                Text('${retrySettings.delayBetweenImagesMs}ms'),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 