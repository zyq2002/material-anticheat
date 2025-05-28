import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_item.freezed.dart';
part 'favorite_item.g.dart';

@freezed
class FavoriteItem with _$FavoriteItem {
  const factory FavoriteItem({
    required String id,
    required FavoriteType type,
    required String name, // ID号或车牌号
    required DateTime createdAt,
    String? description,
    String? imagePath,
    String? date, // 对应的日期
  }) = _FavoriteItem;

  factory FavoriteItem.fromJson(Map<String, dynamic> json) =>
      _$FavoriteItemFromJson(json);
}

enum FavoriteType {
  @JsonValue('id')
  id,
  @JsonValue('license_plate')
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