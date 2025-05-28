import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/detection_result.dart';

final detectionHistoryServiceProvider = Provider<DetectionHistoryService>((ref) {
  return DetectionHistoryService();
});

class DetectionHistoryService {
  static const String _historyKey = 'detection_history';
  static const int _maxHistoryCount = 100; // 最多保留100次检测记录
  
  final Logger _logger = Logger();

  /// 保存检测会话
  Future<void> saveDetectionSession(DetectionSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getDetectionHistory();
      
      // 检查是否已存在相同ID的会话，如果存在则更新
      final existingIndex = history.indexWhere((s) => s.id == session.id);
      if (existingIndex != -1) {
        history[existingIndex] = session;
        _logger.i('更新检测会话: ${session.id}');
      } else {
        history.add(session);
        _logger.i('保存新检测会话: ${session.id}');
      }
      
      // 按时间倒序排序（最新的在前面）
      history.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      // 只保留最近的检测记录
      if (history.length > _maxHistoryCount) {
        history.removeRange(_maxHistoryCount, history.length);
        _logger.i('清理历史记录，保留最近 $_maxHistoryCount 条');
      }
      
      final json = jsonEncode(history.map((s) => s.toJson()).toList());
      await prefs.setString(_historyKey, json);
      
      _logger.i('检测历史保存成功，当前共 ${history.length} 条记录');
      
    } catch (e) {
      _logger.e('保存检测历史失败: $e');
      rethrow;
    }
  }

  /// 获取检测历史
  Future<List<DetectionSession>> getDetectionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> historyList = jsonDecode(historyJson);
      final sessions = historyList
          .map((json) => DetectionSession.fromJson(json))
          .toList();
      
      // 按时间倒序排序
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      return sessions;
      
    } catch (e) {
      _logger.e('获取检测历史失败: $e');
      return [];
    }
  }

  /// 根据类型筛选检测历史
  Future<List<DetectionSession>> getDetectionHistoryByType(String detectionType) async {
    final allHistory = await getDetectionHistory();
    return allHistory.where((session) => session.detectionType == detectionType).toList();
  }

  /// 根据日期范围筛选检测历史
  Future<List<DetectionSession>> getDetectionHistoryByDateRange(
    DateTime startDate, 
    DateTime endDate,
  ) async {
    final allHistory = await getDetectionHistory();
    return allHistory.where((session) {
      final sessionDate = session.startTime;
      return sessionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             sessionDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// 获取单个检测会话
  Future<DetectionSession?> getDetectionSession(String sessionId) async {
    final history = await getDetectionHistory();
    try {
      return history.firstWhere((session) => session.id == sessionId);
    } catch (e) {
      return null;
    }
  }

  /// 更新检测结果状态
  Future<void> updateResultStatus(
    String sessionId, 
    String resultId, 
    String status, 
    String? notes,
  ) async {
    try {
      final history = await getDetectionHistory();
      final sessionIndex = history.indexWhere((s) => s.id == sessionId);
      
      if (sessionIndex != -1) {
        final session = history[sessionIndex];
        final updatedResults = session.results.map((r) {
          if (r.id == resultId) {
            return r.copyWith(
              status: status,
              notes: notes,
              reviewedAt: DateTime.now(),
            );
          }
          return r;
        }).toList();
        
        final updatedSession = session.copyWith(results: updatedResults);
        history[sessionIndex] = updatedSession;
        
        final prefs = await SharedPreferences.getInstance();
        final json = jsonEncode(history.map((s) => s.toJson()).toList());
        await prefs.setString(_historyKey, json);
        
        _logger.i('更新检测结果状态: $resultId -> $status');
      }
    } catch (e) {
      _logger.e('更新检测结果状态失败: $e');
      rethrow;
    }
  }

  /// 删除检测会话
  Future<void> deleteDetectionSession(String sessionId) async {
    try {
      final history = await getDetectionHistory();
      history.removeWhere((session) => session.id == sessionId);
      
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(history.map((s) => s.toJson()).toList());
      await prefs.setString(_historyKey, json);
      
      _logger.i('删除检测会话: $sessionId');
    } catch (e) {
      _logger.e('删除检测会话失败: $e');
      rethrow;
    }
  }

  /// 清空所有检测历史
  Future<void> clearAllHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      _logger.i('清空所有检测历史');
    } catch (e) {
      _logger.e('清空检测历史失败: $e');
      rethrow;
    }
  }

  /// 导出单个检测会话报告
  Future<String> exportDetectionReport(DetectionSession session) async {
    try {
      final buffer = StringBuffer();
      
      // CSV格式导出
      buffer.writeln('检测时间,检测类型,图片类型,记录1,记录2,相似度,风险级别,状态,备注');
      
      for (final result in session.results) {
        buffer.writeln([
          DateFormat('yyyy-MM-dd HH:mm:ss').format(result.detectionTime),
          result.detectionType == 'duplicate' ? '重复检测' : '可疑检测',
          result.imageType,
          result.recordName1,
          result.recordName2,
          '${(result.similarity * 100).toStringAsFixed(1)}%',
          SimilarityStandards.getLevelName(result.level),
          SimilarityStandards.getStatusName(result.status),
          result.notes ?? '',
        ].map((field) => '"${field.toString().replaceAll('"', '""')}"').join(','));
      }
      
      return buffer.toString();
    } catch (e) {
      _logger.e('导出检测报告失败: $e');
      rethrow;
    }
  }

  /// 导出所有检测历史
  Future<String> exportAllDetectionHistory() async {
    try {
      final history = await getDetectionHistory();
      final buffer = StringBuffer();
      
      // CSV格式导出
      buffer.writeln('会话ID,开始时间,结束时间,检测类型,总对比数,发现问题数,状态');
      
      for (final session in history) {
        buffer.writeln([
          session.id,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startTime),
          session.endTime != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(session.endTime!) : '',
          session.detectionType == 'duplicate' ? '重复检测' : '可疑检测',
          session.totalComparisons.toString(),
          session.foundIssues.toString(),
          session.status,
        ].map((field) => '"${field.toString().replaceAll('"', '""')}"').join(','));
      }
      
      // 添加详细结果
      buffer.writeln();
      buffer.writeln('详细检测结果:');
      buffer.writeln('会话ID,检测时间,检测类型,图片类型,记录1,记录2,相似度,风险级别,状态,备注');
      
      for (final session in history) {
        for (final result in session.results) {
          buffer.writeln([
            session.id,
            DateFormat('yyyy-MM-dd HH:mm:ss').format(result.detectionTime),
            result.detectionType == 'duplicate' ? '重复检测' : '可疑检测',
            result.imageType,
            result.recordName1,
            result.recordName2,
            '${(result.similarity * 100).toStringAsFixed(1)}%',
            SimilarityStandards.getLevelName(result.level),
            SimilarityStandards.getStatusName(result.status),
            result.notes ?? '',
          ].map((field) => '"${field.toString().replaceAll('"', '""')}"').join(','));
        }
      }
      
      return buffer.toString();
    } catch (e) {
      _logger.e('导出所有检测历史失败: $e');
      rethrow;
    }
  }

  /// 复制报告到剪贴板
  Future<void> copyReportToClipboard(String csvContent) async {
    try {
      await Clipboard.setData(ClipboardData(text: csvContent));
      _logger.i('检测报告已复制到剪贴板');
    } catch (e) {
      _logger.e('复制到剪贴板失败: $e');
      rethrow;
    }
  }

  /// 获取统计信息
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final history = await getDetectionHistory();
      
      final totalSessions = history.length;
      final totalResults = history.fold<int>(0, (int sum, session) => sum + session.results.length);
      
      final duplicateSessions = history.where((s) => s.detectionType == 'duplicate').length;
      final suspiciousSessions = history.where((s) => s.detectionType == 'suspicious').length;
      
      final levelCounts = <SimilarityLevel, int>{};
      final statusCounts = <String, int>{};
      
      for (final session in history) {
        for (final result in session.results) {
          levelCounts[result.level] = (levelCounts[result.level] ?? 0) + 1;
          statusCounts[result.status] = (statusCounts[result.status] ?? 0) + 1;
        }
      }
      
      return {
        'totalSessions': totalSessions,
        'totalResults': totalResults,
        'duplicateSessions': duplicateSessions,
        'suspiciousSessions': suspiciousSessions,
        'levelCounts': levelCounts,
        'statusCounts': statusCounts,
        'lastDetectionTime': history.isNotEmpty ? history.first.startTime.toIso8601String() : null,
      };
    } catch (e) {
      _logger.e('获取统计信息失败: $e');
      return {};
    }
  }
} 