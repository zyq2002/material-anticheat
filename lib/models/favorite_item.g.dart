// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FavoriteItemImpl _$$FavoriteItemImplFromJson(Map<String, dynamic> json) =>
    _$FavoriteItemImpl(
      id: json['id'] as String,
      type: $enumDecode(_$FavoriteTypeEnumMap, json['type']),
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
      imagePath: json['imagePath'] as String?,
      date: json['date'] as String?,
    );

Map<String, dynamic> _$$FavoriteItemImplToJson(_$FavoriteItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$FavoriteTypeEnumMap[instance.type]!,
      'name': instance.name,
      'createdAt': instance.createdAt.toIso8601String(),
      'description': instance.description,
      'imagePath': instance.imagePath,
      'date': instance.date,
    };

const _$FavoriteTypeEnumMap = {
  FavoriteType.id: 'id',
  FavoriteType.licensePlate: 'license_plate',
}; 