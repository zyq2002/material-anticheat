import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import '../models/record_status.dart';

// 记录状态服务Provider
final recordStatusServiceProvider = StateNotifierProvider<RecordStatusService, List<RecordStatusItem>>((ref) {
  return RecordStatusService();
});

class RecordStatusService extends StateNotifier<List<RecordStatusItem>> {
  static const String _recordStatusKey = 'record_status';
  
  RecordStatusService() : super([]) {
    _loadRecordStatus();
  }

  /// 从本地存储加载记录状态列表
  Future<void> _loadRecordStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = prefs.getString(_recordStatusKey);
      if (statusJson != null) {
        final List<dynamic> statusList = jsonDecode(statusJson);
        final recordStatusItems = statusList
            .map((json) => RecordStatusItem.fromJson(json))
            .toList();
        
        // 按过磅ID排序
        _sortRecordStatusByWeighbridgeId(recordStatusItems);
        state = recordStatusItems;
      }
    } catch (e) {
      debugPrint('加载记录状态列表失败: $e');
    }
  }

  /// 按过磅ID排序记录状态列表
  void _sortRecordStatusByWeighbridgeId(List<RecordStatusItem> items) {
    items.sort((a, b) {
      try {
        final aId = int.tryParse(a.weighbridgeId) ?? 0;
        final bId = int.tryParse(b.weighbridgeId) ?? 0;
        return bId.compareTo(aId); // 降序，大的ID在前
      } catch (e) {
        // 如果解析失败，按字符串排序
        return b.weighbridgeId.compareTo(a.weighbridgeId);
      }
    });
  }

  /// 保存记录状态列表到本地存储
  Future<void> _saveRecordStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = jsonEncode(
        state.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_recordStatusKey, statusJson);
    } catch (e) {
      debugPrint('保存记录状态列表失败: $e');
    }
  }

  /// 设置记录状态
  Future<void> setRecordStatus({
    required String recordName,
    required String weighbridgeId,
    required RecordStatusType status,
    String? description,
    String? date,
    List<File>? allImages,
  }) async {
    // 如果有图片，复制图片到标记目录
    String? copiedImagePath;
    List<String>? copiedImagePaths;
    
    if (allImages != null && allImages.isNotEmpty) {
      copiedImagePaths = await _copyAllImagesForRecord(allImages, weighbridgeId);
      copiedImagePath = copiedImagePaths.isNotEmpty ? copiedImagePaths.first : null;
    }

    // 检查是否已存在该记录的状态
    final existingIndex = state.indexWhere(
      (item) => item.recordName == recordName || item.weighbridgeId == weighbridgeId
    );

    if (existingIndex != -1) {
      // 更新现有状态
      final updatedItem = state[existingIndex].copyWith(
        status: status,
        description: description,
        date: date,
        imagePath: copiedImagePath ?? state[existingIndex].imagePath,
        allImagePaths: copiedImagePaths ?? state[existingIndex].allImagePaths,
      );
      
      final updatedList = [...state];
      updatedList[existingIndex] = updatedItem;
      
      _sortRecordStatusByWeighbridgeId(updatedList);
      state = updatedList;
    } else {
      // 添加新状态
      final newItem = RecordStatusItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        recordName: recordName,
        weighbridgeId: weighbridgeId,
        status: status,
        createdAt: DateTime.now(),
        description: description,
        date: date,
        imagePath: copiedImagePath,
        allImagePaths: copiedImagePaths,
      );

      final updatedList = [...state, newItem];
      _sortRecordStatusByWeighbridgeId(updatedList);
      state = updatedList;
    }

    await _saveRecordStatus();
  }

  /// 移除记录状态
  Future<void> removeRecordStatus(String recordName) async {
    final updatedList = state.where(
      (item) => item.recordName != recordName
    ).toList();
    state = updatedList;
    await _saveRecordStatus();
  }

  /// 获取记录状态
  RecordStatusItem? getRecordStatus(String recordName) {
    try {
      return state.firstWhere((item) => item.recordName == recordName);
    } catch (e) {
      return null;
    }
  }

  /// 获取指定状态的记录列表
  List<RecordStatusItem> getRecordsByStatus(RecordStatusType status) {
    return state.where((item) => item.status == status).toList();
  }

  /// 获取可疑记录列表
  List<RecordStatusItem> getSuspiciousRecords() {
    return getRecordsByStatus(RecordStatusType.suspicious);
  }

  /// 获取正常记录列表
  List<RecordStatusItem> getNormalRecords() {
    return getRecordsByStatus(RecordStatusType.normal);
  }

  /// 检查记录是否被标记为某种状态
  bool isRecordMarked(String recordName, RecordStatusType status) {
    final item = getRecordStatus(recordName);
    return item?.status == status;
  }

  /// 检查记录是否被标记为可疑
  bool isSuspicious(String recordName) {
    return isRecordMarked(recordName, RecordStatusType.suspicious);
  }

  /// 检查记录是否被标记为正常
  bool isNormal(String recordName) {
    return isRecordMarked(recordName, RecordStatusType.normal);
  }

  /// 清除所有记录状态
  Future<void> clearAllStatus() async {
    state = [];
    await _saveRecordStatus();
  }

  /// 导出记录状态为CSV
  Future<String> exportStatusToCsv() async {
    final buffer = StringBuffer();
    buffer.writeln('过磅ID,记录名称,状态,描述,标记时间,关联日期');
    
    for (final item in state) {
      final weighbridgeId = item.weighbridgeId;
      final recordName = item.recordName;
      final status = item.status.displayName;
      final description = item.description ?? '';
      final createdAt = '${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')} ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}';
      final date = item.date ?? '';
      
      buffer.writeln('"$weighbridgeId","$recordName","$status","$description","$createdAt","$date"');
    }
    
    return buffer.toString();
  }

  /// 为记录状态复制所有图片
  Future<List<String>> _copyAllImagesForRecord(List<File> sourceImages, String weighbridgeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('weighbridge_save_path');
      
      String recordStatusPath;
      if (customPath != null && customPath.isNotEmpty) {
        recordStatusPath = path.join(customPath, 'record_status', weighbridgeId);
      } else {
        final currentDir = Directory.current.path;
        
        // 确保路径是绝对路径，不是根目录
        if (currentDir == '/' || currentDir.isEmpty) {
          recordStatusPath = path.join(Platform.environment['HOME'] ?? '/tmp', 'Downloads', 'material_anticheat', 'pic', 'record_status', weighbridgeId);
        } else {
          recordStatusPath = path.join(currentDir, 'pic', 'record_status', weighbridgeId);
        }
      }

      final recordStatusDir = Directory(recordStatusPath);
      if (!await recordStatusDir.exists()) {
        await recordStatusDir.create(recursive: true);
      }

      final copiedPaths = <String>[];
      
      // 如果有源图片，尝试复制record_info.json文件
      if (sourceImages.isNotEmpty) {
        try {
          final sourceDir = Directory(path.dirname(sourceImages.first.path));
          final sourceRecordInfoFile = File(path.join(sourceDir.path, 'record_info.json'));
          
          if (await sourceRecordInfoFile.exists()) {
            final targetRecordInfoFile = File(path.join(recordStatusPath, 'record_info.json'));
            if (!await targetRecordInfoFile.exists()) {
              await sourceRecordInfoFile.copy(targetRecordInfoFile.path);
              debugPrint('复制过磅记录信息文件: ${targetRecordInfoFile.path}');
            }
          }
        } catch (e) {
          debugPrint('复制record_info.json失败: $e');
        }
      }
      
      for (final sourceImage in sourceImages) {
        try {
          if (await sourceImage.exists()) {
            final fileName = path.basename(sourceImage.path);
            final targetPath = path.join(recordStatusPath, fileName);
            
            // 如果目标文件不存在则复制
            final targetFile = File(targetPath);
            if (!await targetFile.exists()) {
              await sourceImage.copy(targetPath);
              copiedPaths.add(targetPath);
            } else {
              copiedPaths.add(targetPath);
            }
          }
        } catch (e) {
          debugPrint('复制图片 ${sourceImage.path} 失败: $e');
        }
      }

      return copiedPaths;
    } catch (e) {
      debugPrint('为记录状态复制所有图片失败: $e');
      return [];
    }
  }
} 