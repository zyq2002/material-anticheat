import 'package:freezed_annotation/freezed_annotation.dart';

part 'detection_result.freezed.dart';
part 'detection_result.g.dart';

// 相似度级别枚举
enum SimilarityLevel {
  @JsonValue('normal')
  normal,      // 0-35%: 正常
  @JsonValue('attention')
  attention,   // 35-50%: 需要关注  
  @JsonValue('suspicious')
  suspicious,  // 50-70%: 可疑
  @JsonValue('warning')
  warning,     // 70-85%: 警告
  @JsonValue('critical')
  critical,    // 85-100%: 严重
}

// 检测结果数据模型
@freezed
class DetectionResult with _$DetectionResult {
  const factory DetectionResult({
    required String id,
    required String detectionType, // 'duplicate' | 'suspicious'
    required DateTime detectionTime,
    required String imagePath1,
    required String imagePath2,
    required String recordName1,
    required String recordName2,
    required double similarity,
    required String imageType,
    required SimilarityLevel level,
    @Default('pending') String status, // 'pending' | 'reviewed' | 'confirmed' | 'dismissed'
    String? notes,
    String? reviewedBy,
    DateTime? reviewedAt,
  }) = _DetectionResult;

  factory DetectionResult.fromJson(Map<String, dynamic> json) =>
      _$DetectionResultFromJson(json);
}

// 检测会话记录
@freezed
class DetectionSession with _$DetectionSession {
  const factory DetectionSession({
    required String id,
    required DateTime startTime,
    DateTime? endTime,
    required String detectionType,
    required Map<String, dynamic> config,
    required int totalComparisons,
    required int foundIssues,
    required List<DetectionResult> results,
    @Default('completed') String status, // 'running' | 'completed' | 'failed'
  }) = _DetectionSession;

  factory DetectionSession.fromJson(Map<String, dynamic> json) =>
      _$DetectionSessionFromJson(json);
}

// 相似度标准工具类
class SimilarityStandards {
  static const Map<String, Map<SimilarityLevel, double>> standards = {
    // 车牌照片标准更严格
    '车牌照片': {
      SimilarityLevel.attention: 0.25,
      SimilarityLevel.suspicious: 0.40,
      SimilarityLevel.warning: 0.60,
      SimilarityLevel.critical: 0.80,
    },
    // 车身照片标准相对宽松
    '车前照片': {
      SimilarityLevel.attention: 0.35,
      SimilarityLevel.suspicious: 0.50,
      SimilarityLevel.warning: 0.70,
      SimilarityLevel.critical: 0.85,
    },
    '左侧照片': {
      SimilarityLevel.attention: 0.35,
      SimilarityLevel.suspicious: 0.50,
      SimilarityLevel.warning: 0.70,
      SimilarityLevel.critical: 0.85,
    },
    '右侧照片': {
      SimilarityLevel.attention: 0.35,
      SimilarityLevel.suspicious: 0.50,
      SimilarityLevel.warning: 0.70,
      SimilarityLevel.critical: 0.85,
    },
  };

  static SimilarityLevel getSimilarityLevel(String imageType, double similarity) {
    final typeStandards = standards[imageType] ?? standards['车前照片']!;
    
    if (similarity >= typeStandards[SimilarityLevel.critical]!) {
      return SimilarityLevel.critical;
    } else if (similarity >= typeStandards[SimilarityLevel.warning]!) {
      return SimilarityLevel.warning;
    } else if (similarity >= typeStandards[SimilarityLevel.suspicious]!) {
      return SimilarityLevel.suspicious;
    } else if (similarity >= typeStandards[SimilarityLevel.attention]!) {
      return SimilarityLevel.attention;
    } else {
      return SimilarityLevel.normal;
    }
  }

  static String getLevelName(SimilarityLevel level) {
    switch (level) {
      case SimilarityLevel.normal: return '正常';
      case SimilarityLevel.attention: return '关注';
      case SimilarityLevel.suspicious: return '可疑';
      case SimilarityLevel.warning: return '警告';
      case SimilarityLevel.critical: return '严重';
    }
  }

  static String getStatusName(String status) {
    switch (status) {
      case 'pending': return '待审核';
      case 'reviewed': return '已审核';
      case 'confirmed': return '确认问题';
      case 'dismissed': return '已忽略';
      default: return status;
    }
  }
} 