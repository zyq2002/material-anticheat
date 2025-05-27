import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../services/crawler_service.dart';
import '../widgets/auth_input_card.dart';
import '../widgets/date_selector_card.dart';
import '../widgets/interval_setting_card.dart';
import '../widgets/save_path_card.dart';
import '../widgets/retry_settings_card.dart';
import '../widgets/api_settings_card.dart';
import '../widgets/control_buttons_card.dart';
import '../widgets/progress_display_card.dart';
import '../widgets/log_display_card.dart';
import 'batch_download_screen.dart';
import 'image_gallery_screen.dart';
import 'duplicate_detection_screen.dart';
import 'suspicious_images_screen.dart';

class MainScreen extends HookConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authTokenController = useTextEditingController();
    final cookieController = useTextEditingController();
    final selectedDate = useState(DateTime.now());
    final intervalMinutes = useState(30);
    final savePath = useState('');
    
    final crawlerState = ref.watch(crawlerServiceProvider);

    // 初始化加载设置
    useEffect(() {
      Future.microtask(() async {
        final settings = await ref.read(crawlerServiceProvider.notifier).loadSettings();
        authTokenController.text = settings['auth_token'] ?? '';
        cookieController.text = settings['cookie'] ?? '';
        intervalMinutes.value = settings['interval_minutes'] ?? 30;
        savePath.value = settings['save_path'] ?? '';
      });
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('物资验收反作弊工具'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'batch_download':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BatchDownloadScreen(),
                    ),
                  );
                  break;
                case 'image_gallery':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImageGalleryScreen(),
                    ),
                  );
                  break;
                case 'duplicate_detection':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DuplicateDetectionScreen(),
                    ),
                  );
                  break;
                case 'suspicious_images':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SuspiciousImagesScreen(),
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
                  subtitle: Text('下载多天的图片'),
                ),
              ),
              const PopupMenuItem(
                value: 'image_gallery',
                child: ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('图片库'),
                  subtitle: Text('查看已下载的图片'),
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate_detection',
                child: ListTile(
                  leading: Icon(Icons.find_in_page),
                  title: Text('重复检测'),
                  subtitle: Text('检测重复的车辆图片'),
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
      body: Padding(
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
                        ref.read(crawlerServiceProvider.notifier).setSavePath(path);
                      },
                      enabled: !crawlerState.isRunning,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 重试设置
                    RetrySettingsCard(
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
                        
                        await ref.read(crawlerServiceProvider.notifier).startCrawler(
                          authToken: authTokenController.text.trim(),
                          cookie: cookieController.text.trim(),
                          selectedDate: selectedDate.value,
                          intervalMinutes: intervalMinutes.value,
                        );
                      },
                      onStop: () {
                        ref.read(crawlerServiceProvider.notifier).stopCrawler();
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // 右侧状态显示
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // 进度显示
                  ProgressDisplayCard(
                    state: crawlerState,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 日志显示
                  const Expanded(
                    child: LogDisplayCard(),
                  ),
                ],
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
} 