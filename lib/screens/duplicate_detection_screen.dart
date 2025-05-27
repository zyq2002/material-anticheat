import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/duplicate_detection_config.dart';
import '../models/similarity_result.dart';
import '../services/image_similarity_service.dart';
import '../widgets/similarity_result_card.dart';

class DuplicateDetectionScreen extends HookConsumerWidget {
  const DuplicateDetectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = useState(const DuplicateDetectionConfig());
    final isDetecting = useState(false);
    final detectionResults = useState<List<SimilarityResult>>([]);
    final progress = useState<DetectionProgress?>(null);
    final errorMessage = useState<String?>(null);

    final imageSimilarityService = ref.watch(imageSimilarityServiceProvider);

    Future<void> startDetection() async {
      if (isDetecting.value) return;

      isDetecting.value = true;
      errorMessage.value = null;
      detectionResults.value = [];
      
      try {
        final results = await imageSimilarityService.detectDuplicateImages(
          config: config.value,
        );
        
        detectionResults.value = results;
        
        if (results.isEmpty) {
          errorMessage.value = '未发现重复图片';
        }
      } catch (e) {
        errorMessage.value = '检测失败: $e';
      } finally {
        isDetecting.value = false;
        progress.value = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('重复图片检测'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // 配置面板
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '检测配置',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // 相似度阈值
                  Row(
                    children: [
                      const Text('相似度阈值: '),
                      Expanded(
                        child: Slider(
                          value: config.value.threshold,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          label: '${(config.value.threshold * 100).toInt()}%',
                          onChanged: (value) {
                            config.value = config.value.copyWith(threshold: value);
                          },
                        ),
                      ),
                      Text('${(config.value.threshold * 100).toInt()}%'),
                    ],
                  ),
                  
                  // 对比天数
                  Row(
                    children: [
                      const Text('对比天数: '),
                      Expanded(
                        child: Slider(
                          value: config.value.compareDays.toDouble(),
                          min: 1,
                          max: 30,
                          divisions: 29,
                          label: '${config.value.compareDays}天',
                          onChanged: (value) {
                            config.value = config.value.copyWith(
                              compareDays: value.round(),
                            );
                          },
                        ),
                      ),
                      Text('${config.value.compareDays}天'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 图片类型选择
                  Text(
                    '对比图片类型',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  
                  CheckboxListTile(
                    title: const Text('验收照片1'),
                    value: config.value.comparePhotos1,
                    onChanged: (value) {
                      config.value = config.value.copyWith(
                        comparePhotos1: value ?? false,
                      );
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('验收照片2'),
                    value: config.value.comparePhotos2,
                    onChanged: (value) {
                      config.value = config.value.copyWith(
                        comparePhotos2: value ?? false,
                      );
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('验收照片3'),
                    value: config.value.comparePhotos3,
                    onChanged: (value) {
                      config.value = config.value.copyWith(
                        comparePhotos3: value ?? false,
                      );
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('送货单'),
                    value: config.value.compareDeliveryNotes,
                    onChanged: (value) {
                      config.value = config.value.copyWith(
                        compareDeliveryNotes: value ?? false,
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 开始检测按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isDetecting.value ? null : startDetection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: isDetecting.value
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('正在检测...'),
                              ],
                            )
                          : const Text('开始检测'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 进度显示
          if (progress.value != null)
            LinearProgressIndicator(
              value: progress.value!.total > 0
                  ? progress.value!.current / progress.value!.total
                  : null,
            ),
          
          // 错误信息
          if (errorMessage.value != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: SelectableText.rich(
                TextSpan(
                  text: errorMessage.value!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            ),
          
          // 结果列表
          if (detectionResults.value.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '检测结果 (${detectionResults.value.length} 组重复图片)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: detectionResults.value.length,
                      itemBuilder: (context, index) {
                        final result = detectionResults.value[index];
                        return SimilarityResultCard(
                          result: result,
                          onTap: () => _showImageComparison(context, result),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showImageComparison(BuildContext context, SimilarityResult result) {
    showDialog(
      context: context,
      builder: (context) => ImageComparisonDialog(result: result),
    );
  }
}

class ImageComparisonDialog extends StatelessWidget {
  final SimilarityResult result;

  const ImageComparisonDialog({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '图片对比',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              '相似度: ${(result.similarity).toStringAsFixed(2)}%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: result.similarity >= 80 ? Colors.red : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '图片 1',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(result.image1Path),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Text('无法加载图片'),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.image1Path.split('/').last,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '图片 2',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(result.image2Path),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Text('无法加载图片'),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.image2Path.split('/').last,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              '检测时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(result.detectionTime)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
} 