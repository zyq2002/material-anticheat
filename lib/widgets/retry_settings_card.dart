import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/crawler_service.dart';

class RetrySettingsCard extends ConsumerWidget {
  final bool enabled;

  const RetrySettingsCard({
    super.key,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crawlerState = ref.watch(crawlerServiceProvider);
    final retrySettings = crawlerState.retrySettings;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.refresh, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  '重试设置',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: retrySettings.enableAutoRetry,
                  onChanged: enabled ? (value) {
                    final newSettings = retrySettings.copyWith(
                      enableAutoRetry: value,
                    );
                    ref.read(crawlerServiceProvider.notifier)
                        .updateRetrySettings(newSettings);
                  } : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 最大重试次数
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('最大重试次数:'),
                ),
                Expanded(
                  flex: 3,
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
                      ref.read(crawlerServiceProvider.notifier)
                          .updateRetrySettings(newSettings);
                    } : null,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${retrySettings.maxRetries}次',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            
            // 重试延迟
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('重试延迟:'),
                ),
                Expanded(
                  flex: 3,
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
                      ref.read(crawlerServiceProvider.notifier)
                          .updateRetrySettings(newSettings);
                    } : null,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${retrySettings.retryDelay.inSeconds}秒',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // 手动重试按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: enabled && crawlerState.failedTasks > 0 ? () {
                  ref.read(crawlerServiceProvider.notifier).retryFailedTasks();
                } : null,
                icon: const Icon(Icons.replay),
                label: Text('手动重试失败任务 (${crawlerState.failedTasks})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 说明文字
            Text(
              '• 自动重试：下载失败时自动重试\n'
              '• 最大重试次数：每张图片的最大重试次数\n'
              '• 重试延迟：每次重试之间的等待时间',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}