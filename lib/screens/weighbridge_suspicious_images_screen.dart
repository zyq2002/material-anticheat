import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as path;

import '../models/weighbridge_suspicious_image_result.dart';
import '../services/weighbridge_image_similarity_service.dart';
import '../services/log_service.dart';

class WeighbridgeSuspiciousImagesScreen extends HookConsumerWidget {
  const WeighbridgeSuspiciousImagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threshold = useState(30.0);
    final sortBy = useState<SortBy>(SortBy.similarity);
    final filterType = useState<String?>(null);

    final suspiciousImagesAsync = ref.watch(
      weighbridgeSuspiciousImagesProvider(threshold.value),
    );

    final logService = ref.read(logServiceProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('过磅可疑图片检测'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置阈值',
            onPressed: () {
              _showThresholdDialog(context, threshold);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新检测',
            onPressed: () {
              logService.info('手动触发过磅可疑图片重新检测');
              ref.invalidate(weighbridgeSuspiciousImagesProvider(threshold.value));
            },
          ),
        ],
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
        child: Column(
          children: [
            // 检测状态和控制面板
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 检测状态
                  suspiciousImagesAsync.when(
                    data: (results) => _buildStatusIndicator(
                      context,
                      results,
                      threshold.value,
                    ),
                    loading: () => _buildLoadingIndicator(),
                    error: (error, stack) => _buildErrorIndicator(error),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 控制面板
                  suspiciousImagesAsync.maybeWhen(
                    data: (results) => results.isNotEmpty
                        ? _buildControlPanel(
                            context,
                            results,
                            sortBy,
                            filterType,
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            
            // 结果列表
            Expanded(
              child: suspiciousImagesAsync.when(
                data: (results) {
                  if (results.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  
                  // 应用筛选和排序
                  var filteredResults = results;
                  if (filterType.value != null) {
                    filteredResults = results
                        .where((r) => r.imageType == filterType.value)
                        .toList();
                  }
                  
                  _sortResults(filteredResults, sortBy.value);
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredResults.length,
                    itemBuilder: (context, index) {
                      final result = filteredResults[index];
                      return WeighbridgeSuspiciousImageCard(
                        result: result,
                        index: index + 1,
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在检测过磅可疑图片...'),
                    ],
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '检测失败: ${error.toString()}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(weighbridgeSuspiciousImagesProvider(threshold.value));
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
      ),
    );
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    List<WeighbridgeSuspiciousImageResult> results,
    double threshold,
  ) {
    final hasResults = results.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasResults ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasResults ? Colors.orange.withOpacity(0.3) : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasResults ? Icons.warning : Icons.verified,
            color: hasResults ? Colors.orange : Colors.green,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasResults 
                      ? '发现 ${results.length} 张可疑过磅图片'
                      : '未发现可疑过磅图片',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hasResults ? Colors.orange : Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '检测阈值: ${threshold.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (hasResults) ...[
                  const SizedBox(height: 4),
                  Text(
                    '建议人工核验这些图片的真实性',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '正在检测过磅可疑图片...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '正在分析今日过磅图片的相似度',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorIndicator(Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error,
            color: Colors.red,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '检测失败',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '错误信息: ${error.toString()}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified,
            size: 80,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            '未发现可疑过磅图片',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '今日的过磅图片看起来都很正常',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  '系统会自动检测相似度过高的过磅图片\n帮助识别可能的作弊行为',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(
    BuildContext context,
    List<WeighbridgeSuspiciousImageResult> results,
    ValueNotifier<SortBy> sortBy,
    ValueNotifier<String?> filterType,
  ) {
    // 获取所有图片类型
    final imageTypes = results.map((r) => r.imageType).toSet().toList();
    imageTypes.sort();

    return Row(
      children: [
        // 图片类型筛选
        Expanded(
          child: DropdownButtonFormField<String?>(
            value: filterType.value,
            decoration: const InputDecoration(
              labelText: '筛选图片类型',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('全部类型'),
              ),
              ...imageTypes.map((type) => DropdownMenuItem<String?>(
                value: type,
                child: Text(type),
              )),
            ],
            onChanged: (value) {
              filterType.value = value;
            },
          ),
        ),
        
        const SizedBox(width: 16),
        
        // 排序方式
        Expanded(
          child: DropdownButtonFormField<SortBy>(
            value: sortBy.value,
            decoration: const InputDecoration(
              labelText: '排序方式',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: SortBy.similarity,
                child: Text('按相似度'),
              ),
              DropdownMenuItem(
                value: SortBy.detectionTime,
                child: Text('按检测时间'),
              ),
              DropdownMenuItem(
                value: SortBy.imageType,
                child: Text('按图片类型'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                sortBy.value = value;
              }
            },
          ),
        ),
      ],
    );
  }

  void _sortResults(List<WeighbridgeSuspiciousImageResult> results, SortBy sortBy) {
    switch (sortBy) {
      case SortBy.similarity:
        results.sort((a, b) => b.similarity.compareTo(a.similarity));
        break;
      case SortBy.detectionTime:
        results.sort((a, b) => b.detectionTime.compareTo(a.detectionTime));
        break;
      case SortBy.imageType:
        results.sort((a, b) => a.imageType.compareTo(b.imageType));
        break;
    }
  }

  void _showThresholdDialog(BuildContext context, ValueNotifier<double> threshold) {
    final tempThreshold = ValueNotifier(threshold.value);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置相似度阈值'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('调整相似度阈值来改变检测敏感度:'),
            const SizedBox(height: 16),
            ValueListenableBuilder(
              valueListenable: tempThreshold,
              builder: (context, value, child) => Column(
                children: [
                  Text(
                    '${value.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Slider(
                    value: value,
                    min: 10,
                    max: 90,
                    divisions: 80,
                    label: '${value.toStringAsFixed(0)}%',
                    activeColor: Colors.orange,
                    onChanged: (newValue) {
                      tempThreshold.value = newValue;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '阈值越低，检测越严格\n阈值越高，检测越宽松',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              threshold.value = tempThreshold.value;
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class WeighbridgeSuspiciousImageCard extends StatelessWidget {
  final WeighbridgeSuspiciousImageResult result;
  final int index;

  const WeighbridgeSuspiciousImageCard({
    super.key,
    required this.result,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // 解析记录名称获取ID和车牌
    final parts = result.recordName.split('__');
    final reportId = parts.isNotEmpty ? parts[0].replaceFirst('WB', '') : '';
    final carNumber = parts.length > 1 ? parts[1] : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getSimilarityColor(result.similarity).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 可疑标识栏
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _getSimilarityColor(result.similarity),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '可疑记录 #$index',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '相似度: ${(result.similarity * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 主要内容行
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧记录信息
                  SizedBox(
                    width: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 过磅ID
                        Container(
                          width: 160,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getSimilarityColor(result.similarity).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _getSimilarityColor(result.similarity).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '过磅ID: $reportId',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getSimilarityColor(result.similarity),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // 车牌号码
                        Row(
                          children: [
                            const Icon(Icons.local_shipping, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              '车牌: $carNumber',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // 图片类型
                        Row(
                          children: [
                            const Icon(Icons.category, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              '类型: ${result.imageType}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // 检测时间
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '检测时间: ${_formatTime(result.detectionTime)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // 相似度等级
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getSimilarityColor(result.similarity).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _getSimilarityColor(result.similarity).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.analytics,
                                size: 16,
                                color: _getSimilarityColor(result.similarity),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_getSimilarityLabel(result.similarity)}风险',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getSimilarityColor(result.similarity),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // 右侧图片对比区域
                  Expanded(
                    child: _buildImageComparisonGrid(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建图片对比网格（2x1布局）
  Widget _buildImageComparisonGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, // 2列：可疑图片和匹配图片
      crossAxisSpacing: 16,
      mainAxisSpacing: 8,
      childAspectRatio: 1.2, // 稍微宽一点的比例
      children: [
        // 可疑图片
        _buildImageCard(
          '可疑图片',
          result.imagePath,
          result.recordName,
          true,
        ),
        // 匹配图片
        _buildImageCard(
          '匹配图片',
          result.matchImagePath,
          result.matchRecordName,
          false,
        ),
      ],
    );
  }

  /// 构建单个图片卡片
  Widget _buildImageCard(String title, String imagePath, String recordName, bool isSuspicious) {
    final file = File(imagePath);
    final fileName = path.basename(imagePath);
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSuspicious 
              ? _getSimilarityColor(result.similarity) 
              : Colors.grey.shade300,
          width: isSuspicious ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片标题
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSuspicious 
                  ? _getSimilarityColor(result.similarity).withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSuspicious 
                        ? _getSimilarityColor(result.similarity)
                        : Colors.grey.shade700,
                  ),
                ),
                if (isSuspicious) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.warning,
                    size: 12,
                    color: _getSimilarityColor(result.similarity),
                  ),
                ],
              ],
            ),
          ),
          
          // 图片内容
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
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
                  
                  // 文件名显示在底部
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

enum SortBy {
  similarity,
  detectionTime,
  imageType,
} 