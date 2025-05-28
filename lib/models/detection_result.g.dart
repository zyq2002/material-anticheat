// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detection_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DetectionResultImpl _$$DetectionResultImplFromJson(
        Map<String, dynamic> json) =>
    _$DetectionResultImpl(
      id: json['id'] as String,
      detectionType: json['detectionType'] as String,
      detectionTime: DateTime.parse(json['detectionTime'] as String),
      imagePath1: json['imagePath1'] as String,
      imagePath2: json['imagePath2'] as String,
      recordName1: json['recordName1'] as String,
      recordName2: json['recordName2'] as String,
      similarity: (json['similarity'] as num).toDouble(),
      imageType: json['imageType'] as String,
      level: $enumDecode(_$SimilarityLevelEnumMap, json['level']),
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
    );

Map<String, dynamic> _$$DetectionResultImplToJson(
        _$DetectionResultImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'detectionType': instance.detectionType,
      'detectionTime': instance.detectionTime.toIso8601String(),
      'imagePath1': instance.imagePath1,
      'imagePath2': instance.imagePath2,
      'recordName1': instance.recordName1,
      'recordName2': instance.recordName2,
      'similarity': instance.similarity,
      'imageType': instance.imageType,
      'level': _$SimilarityLevelEnumMap[instance.level]!,
      'status': instance.status,
      'notes': instance.notes,
      'reviewedBy': instance.reviewedBy,
      'reviewedAt': instance.reviewedAt?.toIso8601String(),
    };

const _$SimilarityLevelEnumMap = {
  SimilarityLevel.normal: 'normal',
  SimilarityLevel.attention: 'attention',
  SimilarityLevel.suspicious: 'suspicious',
  SimilarityLevel.warning: 'warning',
  SimilarityLevel.critical: 'critical',
};

_$DetectionSessionImpl _$$DetectionSessionImplFromJson(
        Map<String, dynamic> json) =>
    _$DetectionSessionImpl(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      detectionType: json['detectionType'] as String,
      config: json['config'] as Map<String, dynamic>,
      totalComparisons: (json['totalComparisons'] as num).toInt(),
      foundIssues: (json['foundIssues'] as num).toInt(),
      results: (json['results'] as List<dynamic>)
          .map((e) => DetectionResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String? ?? 'completed',
    );

Map<String, dynamic> _$$DetectionSessionImplToJson(
        _$DetectionSessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'detectionType': instance.detectionType,
      'config': instance.config,
      'totalComparisons': instance.totalComparisons,
      'foundIssues': instance.foundIssues,
      'results': instance.results.map((e) => e.toJson()).toList(),
      'status': instance.status,
    };

$enumDecode<T>(Map<T, dynamic> enumValues, dynamic source) {
  return enumValues.entries
      .singleWhere((e) => e.value == source)
      .key;
} 