import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/similarity_result.dart';

class SimilarityResultCard extends StatelessWidget {
  final SimilarityResult result;
  final VoidCallback? onTap;

  const SimilarityResultCard({
    super.key,
    required this.result,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final similarity = result.similarity;
    final isHighSimilarity = similarity >= 80;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '重复图片检测',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isHighSimilarity ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${similarity.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 图片预览行
              Row(
                children: [
                  // 第一张图片
                  Expanded(
                    child: _buildImagePreview(
                      context,
                      result.image1Path,
                      '图片 1',
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 相似度指示器
                  Column(
                    children: [
                      Icon(
                        Icons.compare_arrows,
                        color: isHighSimilarity ? Colors.red : Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${similarity.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isHighSimilarity ? Colors.red : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 第二张图片
                  Expanded(
                    child: _buildImagePreview(
                      context,
                      result.image2Path,
                      '图片 2',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 详细信息
              _buildInfoRow(
                context,
                '检测时间',
                DateFormat('yyyy-MM-dd HH:mm:ss').format(result.detectionTime),
              ),
              
              if (result.imageType != null)
                _buildInfoRow(context, '图片类型', result.imageType!),
              
              if (result.image1RecordId != null && result.image2RecordId != null)
                _buildInfoRow(
                  context,
                  '验收记录',
                  '${result.image1RecordId} ↔ ${result.image2RecordId}',
                ),
              
              const SizedBox(height: 8),
              
              // 底部操作提示
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isHighSimilarity ? '高度相似' : '中度相似',
                    style: TextStyle(
                      fontSize: 12,
                      color: isHighSimilarity ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '点击查看详情',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context, String imagePath, String label) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 32,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getFileName(imagePath),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }
} 