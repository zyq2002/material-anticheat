import 'package:flutter/material.dart';

class FavoriteItem {
  final String id;
  final FavoriteType type;
  final String name; // ID号或车牌号
  final DateTime createdAt;
  final String? description;
  final String? imagePath;
  final String? date; // 对应的日期
  final String? licensePlate; // 添加车牌信息字段
  final String? materialName; // 添加物资信息字段

  const FavoriteItem({
    required this.id,
    required this.type,
    required this.name,
    required this.createdAt,
    this.description,
    this.imagePath,
    this.date,
    this.licensePlate,
    this.materialName,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] as String,
      type: FavoriteType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FavoriteType.id,
      ),
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
      imagePath: json['imagePath'] as String?,
      date: json['date'] as String?,
      licensePlate: json['licensePlate'] as String?,
      materialName: json['materialName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'imagePath': imagePath,
      'date': date,
      'licensePlate': licensePlate,
      'materialName': materialName,
    };
  }
}

enum FavoriteType {
  id,
  licensePlate,
}

extension FavoriteTypeExtension on FavoriteType {
  String get displayName {
    switch (this) {
      case FavoriteType.id:
        return 'ID';
      case FavoriteType.licensePlate:
        return '车牌';
    }
  }

  IconData get icon {
    switch (this) {
      case FavoriteType.id:
        return Icons.perm_identity;
      case FavoriteType.licensePlate:
        return Icons.directions_car;
    }
  }
} 