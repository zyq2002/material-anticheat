import 'package:freezed_annotation/freezed_annotation.dart';

part 'similarity_result.freezed.dart';
part 'similarity_result.g.dart';

@freezed
class SimilarityResult with _$SimilarityResult {
  const factory SimilarityResult({
    required String image1Path,
    required String image2Path,
    required double similarity,
    required bool isDuplicate,
    required DateTime detectionTime,
    String? image1RecordId,
    String? image2RecordId,
    String? imageType,
  }) = _SimilarityResult;

  factory SimilarityResult.fromJson(Map<String, dynamic> json) =>
      _$SimilarityResultFromJson(json);
}

@freezed
class SimilarityGroup with _$SimilarityGroup {
  const factory SimilarityGroup({
    required String date,
    required String imageType,
    required List<SimilarityResult> results,
    required double maxSimilarity,
    required int duplicateCount,
  }) = _SimilarityGroup;

  factory SimilarityGroup.fromJson(Map<String, dynamic> json) =>
      _$SimilarityGroupFromJson(json);
} 