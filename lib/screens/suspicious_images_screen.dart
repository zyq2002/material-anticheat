import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as path;
import '../models/similarity_result.dart';
import '../services/image_similarity_service.dart';

class SuspiciousImagesScreen extends HookConsumerWidget {
  const SuspiciousImagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threshold = useState(30.0); // 默认相似度阈值30%
    final selectedFilter = useState('全部'); // 图片类型筛选
    final sortBy = useState('相似度'); // 排序方式

    // 获取可疑图片
    final suspiciousImagesAsync = ref.watch(
      suspiciousImagesProvider(threshold.value),
    );

    // 图片类型筛选选项
    final filterOptions = [
      '全部',
      '验收照片1',
      '验收照片2', 
      '验收照片3',
      '验收照片4',
      '验收照片5',
      '验收照片6',
      '验收照片7',
      '送货单',
      '其他',
    ];

    // 排序选项
    final sortOptions = ['相似度', '检测时间', '图片类型'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('可疑图片检测'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新检测',
            onPressed: () {
              ref.invalidate(suspiciousImagesProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () => _showSettingsDialog(context, threshold),
          ),
        ],
      ),
      body: Column(
        children: [
          // 控制面板
          _buildControlPanel(
            threshold: threshold,
            selectedFilter: selectedFilter,
            sortBy: sortBy,
            filterOptions: filterOptions,
            sortOptions: sortOptions,
            onThresholdChanged: (value) {
              threshold.value = value;
            },
          ),
          
          // 检测结果
          Expanded(
            child: suspiciousImagesAsync.when(
              data: (results) {
                // 应用筛选
                final filteredResults = _filterResults(results, selectedFilter.value);
                
                // 应用排序
                final sortedResults = _sortResults(filteredResults, sortBy.value);
                
                if (sortedResults.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified, size: 64, color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          '未发现可疑图片',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '在当前阈值下，所有图片均通过检测',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return _buildResultsList(sortedResults);
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('正在检测可疑图片...'),
                    SizedBox(height: 8),
                    Text(
                      '请稍候，这可能需要一些时间',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      '检测失败',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SelectableText.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: '错误信息: '),
                          TextSpan(
                            text: error.toString(),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(suspiciousImagesProvider);
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel({
    required ValueNotifier<double> threshold,
    required ValueNotifier<String> selectedFilter,
    required ValueNotifier<String> sortBy,
    required List<String> filterOptions,
    required List<String> sortOptions,
    required Function(double) onThresholdChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 阈值设置
          Row(
            children: [
              const Icon(Icons.tune, size: 20),
              const SizedBox(width: 8),
              const Text('相似度阈值: '),
              Expanded(
                child: Slider(
                  value: threshold.value,
                  min: 1.0,
                  max: 100.0,
                  divisions: 99,
                  label: '${threshold.value.round()}%',
                  onChanged: onThresholdChanged,
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '${threshold.value.round()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 筛选和排序
          Row(
            children: [
              // 类型筛选
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 8),
              const Text('类型: '),
              DropdownButton<String>(
                value: selectedFilter.value,
                onChanged: (value) {
                  if (value != null) {
                    selectedFilter.value = value;
                  }
                },
                items: filterOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
              ),
              
              const SizedBox(width: 24),
              
              // 排序方式
              const Icon(Icons.sort, size: 20),
              const SizedBox(width: 8),
              const Text('排序: '),
              DropdownButton<String>(
                value: sortBy.value,
                onChanged: (value) {
                  if (value != null) {
                    sortBy.value = value;
                  }
                },
                items: sortOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<SimilarityResult> results) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(SimilarityResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 相似度指示器
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getSimilarityColor(result.similarity),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '相似度: ${result.similarity.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  result.imageType ?? '未知类型',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 记录信息
            Row(
              children: [
                _buildRecordInfo('记录A', result.image1RecordId ?? '未知'),
                const SizedBox(width: 16),
                const Icon(Icons.compare_arrows, color: Colors.grey),
                const SizedBox(width: 16),
                _buildRecordInfo('记录B', result.image2RecordId ?? '未知'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 图片对比
            Row(
              children: [
                Expanded(
                  child: _buildImagePreview(
                    result.image1Path,
                    '图片A',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImagePreview(
                    result.image2Path,
                    '图片B',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.zoom_in),
                  label: const Text('详细对比'),
                  onPressed: () => _showDetailedComparison(result),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.folder_open),
                  label: const Text('打开目录'),
                  onPressed: () => _openImageDirectory(result.image1Path),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordInfo(String label, String recordId) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              recordId,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(String imagePath, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.grey),
                        SizedBox(height: 4),
                        Text(
                          '图片加载失败',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          path.basename(imagePath),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _getSimilarityColor(double similarity) {
    if (similarity >= 80) return Colors.red;
    if (similarity >= 60) return Colors.orange;
    if (similarity >= 40) return Colors.amber;
    return Colors.blue;
  }

  List<SimilarityResult> _filterResults(List<SimilarityResult> results, String filter) {
    if (filter == '全部') return results;
    return results.where((result) => result.imageType == filter).toList();
  }

  List<SimilarityResult> _sortResults(List<SimilarityResult> results, String sortBy) {
    final sorted = List<SimilarityResult>.from(results);
    switch (sortBy) {
      case '相似度':
        sorted.sort((a, b) => b.similarity.compareTo(a.similarity));
        break;
      case '检测时间':
        sorted.sort((a, b) => b.detectionTime.compareTo(a.detectionTime));
        break;
      case '图片类型':
        sorted.sort((a, b) => (a.imageType ?? '').compareTo(b.imageType ?? ''));
        break;
    }
    return sorted;
  }

  void _showSettingsDialog(BuildContext context, ValueNotifier<double> threshold) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('检测设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('相似度阈值设置'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  Slider(
                    value: threshold.value,
                    min: 1.0,
                    max: 100.0,
                    divisions: 99,
                    label: '${threshold.value.round()}%',
                    onChanged: (value) {
                      setState(() {
                        threshold.value = value;
                      });
                    },
                  ),
                  Text('当前阈值: ${threshold.value.round()}%'),
                  const SizedBox(height: 16),
                  const Text(
                    '说明:\n• 阈值越低，检测越严格\n• 建议设置在20-50%之间\n• 过低可能产生误报，过高可能漏检',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDetailedComparison(SimilarityResult result) {
    // TODO: 实现详细对比功能
    // 可以显示更大的图片、更多的相似度信息等
  }

  void _openImageDirectory(String imagePath) {
    // TODO: 实现打开图片所在目录的功能
    // 在macOS上可以使用Process.run('open', [directory])
  }
} 