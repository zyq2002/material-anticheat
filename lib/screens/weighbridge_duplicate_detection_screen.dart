import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/weighbridge_duplicate_detection_service.dart';
import '../services/log_service.dart';

class WeighbridgeDuplicateDetectionScreen extends HookConsumerWidget {
  const WeighbridgeDuplicateDetectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = useState(WeighbridgeDuplicateConfig());
    final results = useState<List<WeighbridgeDuplicateResult>>([]);
    final isRunning = useState(false);
    final currentTask = useState('准备就绪');
    final progress = useState(0.0);

    final logService = ref.read(logServiceProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('过磅重复检测'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.shade50,
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
                        elevation: 4,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange.shade600, Colors.orange.shade800],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.content_copy,
                                size: 48,
                                color: Colors.white,
                              ),
                              SizedBox(height: 12),
                              Text(
                                '过磅重复检测',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '检测相同车辆的重复过磅照片',
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
                      
                      // 检测参数配置
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
                                    color: isRunning.value ? Colors.grey : Colors.orange.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '检测参数',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isRunning.value ? Colors.grey : Colors.orange.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // 相似度阈值
                              Row(
                                children: [
                                  const Text('相似度阈值: '),
                                  Expanded(
                                    child: Slider(
                                      value: config.value.similarityThreshold,
                                      min: 0.1,
                                      max: 1.0,
                                      divisions: 90,
                                      label: '${(config.value.similarityThreshold * 100).toStringAsFixed(0)}%',
                                      onChanged: isRunning.value ? null : (value) {
                                        config.value = config.value.copyWith(
                                          similarityThreshold: value,
                                        );
                                      },
                                      activeColor: Colors.orange,
                                    ),
                                  ),
                                  Text('${(config.value.similarityThreshold * 100).toStringAsFixed(0)}%'),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
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
                                      onChanged: isRunning.value ? null : (value) {
                                        config.value = config.value.copyWith(
                                          compareDays: value.round(),
                                        );
                                      },
                                      activeColor: Colors.orange,
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
                                title: const Text('车前照片'),
                                value: config.value.compareCarFrontImages,
                                onChanged: isRunning.value ? null : (value) {
                                  config.value = config.value.copyWith(
                                    compareCarFrontImages: value ?? false,
                                  );
                                },
                                activeColor: Colors.orange,
                              ),
                              CheckboxListTile(
                                title: const Text('左侧照片'),
                                value: config.value.compareCarLeftImages,
                                onChanged: isRunning.value ? null : (value) {
                                  config.value = config.value.copyWith(
                                    compareCarLeftImages: value ?? false,
                                  );
                                },
                                activeColor: Colors.orange,
                              ),
                              CheckboxListTile(
                                title: const Text('右侧照片'),
                                value: config.value.compareCarRightImages,
                                onChanged: isRunning.value ? null : (value) {
                                  config.value = config.value.copyWith(
                                    compareCarRightImages: value ?? false,
                                  );
                                },
                                activeColor: Colors.orange,
                              ),
                              CheckboxListTile(
                                title: const Text('车牌照片'),
                                value: config.value.compareCarPlateImages,
                                onChanged: isRunning.value ? null : (value) {
                                  config.value = config.value.copyWith(
                                    compareCarPlateImages: value ?? false,
                                  );
                                },
                                activeColor: Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 开始检测按钮
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
                                  onPressed: isRunning.value ? null : () async {
                                    // 验证配置
                                    if (!config.value.hasAnyImageTypeSelected()) {
                                      _showErrorDialog(context, '请至少选择一种图片类型进行对比');
                                      return;
                                    }
                                    
                                    isRunning.value = true;
                                    currentTask.value = '正在初始化检测...';
                                    progress.value = 0.0;
                                    results.value = [];
                                    
                                    try {
                                      logService.info('开始过磅重复检测，参数: ${config.value.toString()}');
                                      
                                      final detectionService = ref.read(weighbridgeDuplicateDetectionServiceProvider);
                                      
                                      // 使用Stream监听进度
                                      await for (final update in detectionService.detectDuplicates(config.value, ref)) {
                                        currentTask.value = update.currentTask;
                                        progress.value = update.progress;
                                        
                                        if (update.isCompleted) {
                                          results.value = update.results;
                                          logService.success('过磅重复检测完成，发现 ${update.results.length} 组重复图片');
                                          break;
                                        }
                                      }
                                      
                                    } catch (e) {
                                      logService.error('过磅重复检测失败: $e');
                                      currentTask.value = '检测失败: $e';
                                    } finally {
                                      isRunning.value = false;
                                    }
                                  },
                                  icon: Icon(isRunning.value ? Icons.hourglass_empty : Icons.search),
                                  label: Text(isRunning.value ? '检测中...' : '开始检测'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isRunning.value ? Colors.grey : Colors.orange.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              
                              if (isRunning.value) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // 停止检测
                                      isRunning.value = false;
                                      currentTask.value = '检测已停止';
                                      logService.info('用户停止过磅重复检测');
                                    },
                                    icon: const Icon(Icons.stop),
                                    label: const Text('停止检测'),
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
              
              // 右侧结果显示
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // 进度显示
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
                                  isRunning.value ? Icons.search : Icons.check_circle_outline,
                                  color: isRunning.value ? Colors.orange : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '检测进度',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            Text(
                              '当前任务: ${currentTask.value}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            LinearProgressIndicator(
                              value: progress.value,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isRunning.value ? Colors.orange : Colors.green,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              '${(progress.value * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 检测结果
                    Expanded(
                      child: Card(
                        elevation: 2,
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.content_copy, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    '重复检测结果 (${results.value.length} 组)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            Expanded(
                              child: results.value.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isRunning.value 
                                                ? Icons.search 
                                                : Icons.check_circle_outline,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            isRunning.value 
                                                ? '正在检测中...' 
                                                : '暂无重复图片',
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: results.value.length,
                                      itemBuilder: (context, index) {
                                        final result = results.value[index];
                                        return WeighbridgeDuplicateResultCard(
                                          result: result,
                                          index: index + 1,
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
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

class WeighbridgeDuplicateResultCard extends StatelessWidget {
  final WeighbridgeDuplicateResult result;
  final int index;

  const WeighbridgeDuplicateResultCard({
    super.key,
    required this.result,
    required this.index,
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '相似度: ${(result.similarity * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '图片类型: ${result.imageType}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // 相似度指示器
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSimilarityColor(result.similarity).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getSimilarityColor(result.similarity).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _getSimilarityLabel(result.similarity),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getSimilarityColor(result.similarity),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 图片对比
            Row(
              children: [
                // 第一张图片
                Expanded(
                  child: _buildImageInfo(
                    context,
                    result.imagePath1,
                    '过磅记录 1',
                    result.recordName1,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 相似度连接线
                Column(
                  children: [
                    Icon(
                      Icons.compare_arrows,
                      color: _getSimilarityColor(result.similarity),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(result.similarity * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getSimilarityColor(result.similarity),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // 第二张图片
                Expanded(
                  child: _buildImageInfo(
                    context,
                    result.imagePath2,
                    '过磅记录 2',
                    result.recordName2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageInfo(BuildContext context, String imagePath, String title, String recordName) {
    final file = File(imagePath);
    final fileName = path.basename(imagePath);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: file.existsSync()
                ? Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          recordName,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 4),
        
        Text(
          fileName,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _getSimilarityColor(double similarity) {
    if (similarity >= 0.9) return Colors.red;
    if (similarity >= 0.7) return Colors.orange;
    if (similarity >= 0.5) return Colors.yellow.shade700;
    return Colors.green;
  }

  String _getSimilarityLabel(double similarity) {
    if (similarity >= 0.9) return '极高';
    if (similarity >= 0.7) return '高';
    if (similarity >= 0.5) return '中';
    return '低';
  }
} 