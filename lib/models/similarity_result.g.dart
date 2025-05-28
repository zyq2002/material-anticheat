// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'similarity_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SimilarityResultImpl _$$SimilarityResultImplFromJson(
        Map<String, dynamic> json) =>
    _$SimilarityResultImpl(
      image1Path: json['image1Path'] as String,
      image2Path: json['image2Path'] as String,
      similarity: (json['similarity'] as num).toDouble(),
      isDuplicate: json['isDuplicate'] as bool,
      detectionTime: DateTime.parse(json['detectionTime'] as String),
      image1RecordId: json['image1RecordId'] as String?,
      image2RecordId: json['image2RecordId'] as String?,
      imageType: json['imageType'] as String?,
    );

Map<String, dynamic> _$$SimilarityResultImplToJson(
        _$SimilarityResultImpl instance) =>
    <String, dynamic>{
      'image1Path': instance.image1Path,
      'image2Path': instance.image2Path,
      'similarity': instance.similarity,
      'isDuplicate': instance.isDuplicate,
      'detectionTime': instance.detectionTime.toIso8601String(),
      'image1RecordId': instance.image1RecordId,
      'image2RecordId': instance.image2RecordId,
      'imageType': instance.imageType,
    };

_$SimilarityGroupImpl _$$SimilarityGroupImplFromJson(
        Map<String, dynamic> json) =>
    _$SimilarityGroupImpl(
      date: json['date'] as String,
      imageType: json['imageType'] as String,
      results: (json['results'] as List<dynamic>)
          .map((e) => SimilarityResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      maxSimilarity: (json['maxSimilarity'] as num).toDouble(),
      duplicateCount: (json['duplicateCount'] as num).toInt(),
    );

Map<String, dynamic> _$$SimilarityGroupImplToJson(
        _$SimilarityGroupImpl instance) =>
    <String, dynamic>{
      'date': instance.date,
      'imageType': instance.imageType,
      'results': instance.results.map((e) => e.toJson()).toList(),
      'maxSimilarity': instance.maxSimilarity,
      'duplicateCount': instance.duplicateCount,
    }; 