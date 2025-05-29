import 'package:flutter/material.dart';

/// 记录状态类型
enum RecordStatusType {
  normal,    // 正常
  suspicious, // 可疑
}

extension RecordStatusTypeExtension on RecordStatusType {
  /// 显示名称
  String get displayName {
    switch (this) {
      case RecordStatusType.normal:
        return '正常';
      case RecordStatusType.suspicious:
        return '可疑';
    }
  }

  /// 图标
  IconData get icon {
    switch (this) {
      case RecordStatusType.normal:
        return Icons.check_circle;
      case RecordStatusType.suspicious:
        return Icons.warning;
    }
  }

  /// 颜色
  Color get color {
    switch (this) {
      case RecordStatusType.normal:
        return Colors.green;
      case RecordStatusType.suspicious:
        return Colors.red;
    }
  }

  /// 背景颜色
  Color get backgroundColor {
    switch (this) {
      case RecordStatusType.normal:
        return Colors.green.withOpacity(0.1);
      case RecordStatusType.suspicious:
        return Colors.red.withOpacity(0.1);
    }
  }

  /// 边框颜色
  Color get borderColor {
    switch (this) {
      case RecordStatusType.normal:
        return Colors.green.withOpacity(0.3);
      case RecordStatusType.suspicious:
        return Colors.red.withOpacity(0.3);
    }
  }
}

/// 记录状态项目
class RecordStatusItem {
  final String id;
  final String recordName; // 过磅记录名称，如 "WB123_材料名_车牌号"
  final String weighbridgeId; // 过磅ID
  final RecordStatusType status;
  final DateTime createdAt;
  final String? description;
  final String? date; // 对应的日期
  final String? imagePath; // 图片路径（第一张图片）
  final List<String>? allImagePaths; // 所有图片路径

  const RecordStatusItem({
    required this.id,
    required this.recordName,
    required this.weighbridgeId,
    required this.status,
    required this.createdAt,
    this.description,
    this.date,
    this.imagePath,
    this.allImagePaths,
  });

  factory RecordStatusItem.fromJson(Map<String, dynamic> json) {
    return RecordStatusItem(
      id: json['id'] as String,
      recordName: json['recordName'] as String,
      weighbridgeId: json['weighbridgeId'] as String,
      status: RecordStatusType.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RecordStatusType.normal,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
      date: json['date'] as String?,
      imagePath: json['imagePath'] as String?,
      allImagePaths: (json['allImagePaths'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recordName': recordName,
      'weighbridgeId': weighbridgeId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'date': date,
      'imagePath': imagePath,
      'allImagePaths': allImagePaths,
    };
  }

  RecordStatusItem copyWith({
    String? id,
    String? recordName,
    String? weighbridgeId,
    RecordStatusType? status,
    DateTime? createdAt,
    String? description,
    String? date,
    String? imagePath,
    List<String>? allImagePaths,
  }) {
    return RecordStatusItem(
      id: id ?? this.id,
      recordName: recordName ?? this.recordName,
      weighbridgeId: weighbridgeId ?? this.weighbridgeId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
      allImagePaths: allImagePaths ?? this.allImagePaths,
    );
  }
} 