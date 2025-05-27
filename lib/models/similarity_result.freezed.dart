// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'similarity_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SimilarityResult _$SimilarityResultFromJson(Map<String, dynamic> json) {
  return _SimilarityResult.fromJson(json);
}

/// @nodoc
mixin _$SimilarityResult {
  String get image1Path => throw _privateConstructorUsedError;
  String get image2Path => throw _privateConstructorUsedError;
  double get similarity => throw _privateConstructorUsedError;
  bool get isDuplicate => throw _privateConstructorUsedError;
  DateTime get detectionTime => throw _privateConstructorUsedError;
  String? get image1RecordId => throw _privateConstructorUsedError;
  String? get image2RecordId => throw _privateConstructorUsedError;
  String? get imageType => throw _privateConstructorUsedError;

  /// Create a copy of SimilarityResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SimilarityResultCopyWith<SimilarityResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SimilarityResultCopyWith<$Res> {
  factory $SimilarityResultCopyWith(SimilarityResult value,
          $Res Function(SimilarityResult) then) =
      _$SimilarityResultCopyWithImpl<$Res, SimilarityResult>;
  @useResult
  $Res call(
      {String image1Path,
      String image2Path,
      double similarity,
      bool isDuplicate,
      DateTime detectionTime,
      String? image1RecordId,
      String? image2RecordId,
      String? imageType});
}

/// @nodoc
class _$SimilarityResultCopyWithImpl<$Res, $Val extends SimilarityResult>
    implements $SimilarityResultCopyWith<$Res> {
  _$SimilarityResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SimilarityResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? image1Path = null,
    Object? image2Path = null,
    Object? similarity = null,
    Object? isDuplicate = null,
    Object? detectionTime = null,
    Object? image1RecordId = freezed,
    Object? image2RecordId = freezed,
    Object? imageType = freezed,
  }) {
    return _then(_value.copyWith(
      image1Path: null == image1Path
          ? _value.image1Path
          : image1Path // ignore: cast_nullable_to_non_nullable
              as String,
      image2Path: null == image2Path
          ? _value.image2Path
          : image2Path // ignore: cast_nullable_to_non_nullable
              as String,
      similarity: null == similarity
          ? _value.similarity
          : similarity // ignore: cast_nullable_to_non_nullable
              as double,
      isDuplicate: null == isDuplicate
          ? _value.isDuplicate
          : isDuplicate // ignore: cast_nullable_to_non_nullable
              as bool,
      detectionTime: null == detectionTime
          ? _value.detectionTime
          : detectionTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      image1RecordId: freezed == image1RecordId
          ? _value.image1RecordId
          : image1RecordId // ignore: cast_nullable_to_non_nullable
              as String?,
      image2RecordId: freezed == image2RecordId
          ? _value.image2RecordId
          : image2RecordId // ignore: cast_nullable_to_non_nullable
              as String?,
      imageType: freezed == imageType
          ? _value.imageType
          : imageType // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SimilarityResultImplCopyWith<$Res>
    implements $SimilarityResultCopyWith<$Res> {
  factory _$$SimilarityResultImplCopyWith(_$SimilarityResultImpl value,
          $Res Function(_$SimilarityResultImpl) then) =
      __$$SimilarityResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String image1Path,
      String image2Path,
      double similarity,
      bool isDuplicate,
      DateTime detectionTime,
      String? image1RecordId,
      String? image2RecordId,
      String? imageType});
}

/// @nodoc
class __$$SimilarityResultImplCopyWithImpl<$Res>
    extends _$SimilarityResultCopyWithImpl<$Res, _$SimilarityResultImpl>
    implements _$$SimilarityResultImplCopyWith<$Res> {
  __$$SimilarityResultImplCopyWithImpl(_$SimilarityResultImpl _value,
      $Res Function(_$SimilarityResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of SimilarityResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? image1Path = null,
    Object? image2Path = null,
    Object? similarity = null,
    Object? isDuplicate = null,
    Object? detectionTime = null,
    Object? image1RecordId = freezed,
    Object? image2RecordId = freezed,
    Object? imageType = freezed,
  }) {
    return _then(_$SimilarityResultImpl(
      image1Path: null == image1Path
          ? _value.image1Path
          : image1Path // ignore: cast_nullable_to_non_nullable
              as String,
      image2Path: null == image2Path
          ? _value.image2Path
          : image2Path // ignore: cast_nullable_to_non_nullable
              as String,
      similarity: null == similarity
          ? _value.similarity
          : similarity // ignore: cast_nullable_to_non_nullable
              as double,
      isDuplicate: null == isDuplicate
          ? _value.isDuplicate
          : isDuplicate // ignore: cast_nullable_to_non_nullable
              as bool,
      detectionTime: null == detectionTime
          ? _value.detectionTime
          : detectionTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      image1RecordId: freezed == image1RecordId
          ? _value.image1RecordId
          : image1RecordId // ignore: cast_nullable_to_non_nullable
              as String?,
      image2RecordId: freezed == image2RecordId
          ? _value.image2RecordId
          : image2RecordId // ignore: cast_nullable_to_non_nullable
              as String?,
      imageType: freezed == imageType
          ? _value.imageType
          : imageType // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$SimilarityResultImpl implements _SimilarityResult {
  const _$SimilarityResultImpl(
      {required this.image1Path,
      required this.image2Path,
      required this.similarity,
      required this.isDuplicate,
      required this.detectionTime,
      this.image1RecordId,
      this.image2RecordId,
      this.imageType});

  factory _$SimilarityResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$SimilarityResultImplFromJson(json);

  @override
  final String image1Path;
  @override
  final String image2Path;
  @override
  final double similarity;
  @override
  final bool isDuplicate;
  @override
  final DateTime detectionTime;
  @override
  final String? image1RecordId;
  @override
  final String? image2RecordId;
  @override
  final String? imageType;

  @override
  String toString() {
    return 'SimilarityResult(image1Path: $image1Path, image2Path: $image2Path, similarity: $similarity, isDuplicate: $isDuplicate, detectionTime: $detectionTime, image1RecordId: $image1RecordId, image2RecordId: $image2RecordId, imageType: $imageType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SimilarityResultImpl &&
            (identical(other.image1Path, image1Path) ||
                other.image1Path == image1Path) &&
            (identical(other.image2Path, image2Path) ||
                other.image2Path == image2Path) &&
            (identical(other.similarity, similarity) ||
                other.similarity == similarity) &&
            (identical(other.isDuplicate, isDuplicate) ||
                other.isDuplicate == isDuplicate) &&
            (identical(other.detectionTime, detectionTime) ||
                other.detectionTime == detectionTime) &&
            (identical(other.image1RecordId, image1RecordId) ||
                other.image1RecordId == image1RecordId) &&
            (identical(other.image2RecordId, image2RecordId) ||
                other.image2RecordId == image2RecordId) &&
            (identical(other.imageType, imageType) ||
                other.imageType == imageType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, image1Path, image2Path,
      similarity, isDuplicate, detectionTime, image1RecordId, image2RecordId, imageType);

  /// Create a copy of SimilarityResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SimilarityResultImplCopyWith<_$SimilarityResultImpl> get copyWith =>
      __$$SimilarityResultImplCopyWithImpl<_$SimilarityResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SimilarityResultImplToJson(
      this,
    );
  }
}

abstract class _SimilarityResult implements SimilarityResult {
  const factory _SimilarityResult(
      {required final String image1Path,
      required final String image2Path,
      required final double similarity,
      required final bool isDuplicate,
      required final DateTime detectionTime,
      final String? image1RecordId,
      final String? image2RecordId,
      final String? imageType}) = _$SimilarityResultImpl;

  factory _SimilarityResult.fromJson(Map<String, dynamic> json) =
      _$SimilarityResultImpl.fromJson;

  @override
  String get image1Path;
  @override
  String get image2Path;
  @override
  double get similarity;
  @override
  bool get isDuplicate;
  @override
  DateTime get detectionTime;
  @override
  String? get image1RecordId;
  @override
  String? get image2RecordId;
  @override
  String? get imageType;

  /// Create a copy of SimilarityResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SimilarityResultImplCopyWith<_$SimilarityResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SimilarityGroup _$SimilarityGroupFromJson(Map<String, dynamic> json) {
  return _SimilarityGroup.fromJson(json);
}

/// @nodoc
mixin _$SimilarityGroup {
  String get date => throw _privateConstructorUsedError;
  String get imageType => throw _privateConstructorUsedError;
  List<SimilarityResult> get results => throw _privateConstructorUsedError;
  double get maxSimilarity => throw _privateConstructorUsedError;
  int get duplicateCount => throw _privateConstructorUsedError;

  /// Create a copy of SimilarityGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SimilarityGroupCopyWith<SimilarityGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SimilarityGroupCopyWith<$Res> {
  factory $SimilarityGroupCopyWith(SimilarityGroup value,
          $Res Function(SimilarityGroup) then) =
      _$SimilarityGroupCopyWithImpl<$Res, SimilarityGroup>;
  @useResult
  $Res call(
      {String date,
      String imageType,
      List<SimilarityResult> results,
      double maxSimilarity,
      int duplicateCount});
}

/// @nodoc
class _$SimilarityGroupCopyWithImpl<$Res, $Val extends SimilarityGroup>
    implements $SimilarityGroupCopyWith<$Res> {
  _$SimilarityGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SimilarityGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? imageType = null,
    Object? results = null,
    Object? maxSimilarity = null,
    Object? duplicateCount = null,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      imageType: null == imageType
          ? _value.imageType
          : imageType // ignore: cast_nullable_to_non_nullable
              as String,
      results: null == results
          ? _value.results
          : results // ignore: cast_nullable_to_non_nullable
              as List<SimilarityResult>,
      maxSimilarity: null == maxSimilarity
          ? _value.maxSimilarity
          : maxSimilarity // ignore: cast_nullable_to_non_nullable
              as double,
      duplicateCount: null == duplicateCount
          ? _value.duplicateCount
          : duplicateCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SimilarityGroupImplCopyWith<$Res>
    implements $SimilarityGroupCopyWith<$Res> {
  factory _$$SimilarityGroupImplCopyWith(_$SimilarityGroupImpl value,
          $Res Function(_$SimilarityGroupImpl) then) =
      __$$SimilarityGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String date,
      String imageType,
      List<SimilarityResult> results,
      double maxSimilarity,
      int duplicateCount});
}

/// @nodoc
class __$$SimilarityGroupImplCopyWithImpl<$Res>
    extends _$SimilarityGroupCopyWithImpl<$Res, _$SimilarityGroupImpl>
    implements _$$SimilarityGroupImplCopyWith<$Res> {
  __$$SimilarityGroupImplCopyWithImpl(
      _$SimilarityGroupImpl _value, $Res Function(_$SimilarityGroupImpl) _then)
      : super(_value, _then);

  /// Create a copy of SimilarityGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? imageType = null,
    Object? results = null,
    Object? maxSimilarity = null,
    Object? duplicateCount = null,
  }) {
    return _then(_$SimilarityGroupImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      imageType: null == imageType
          ? _value.imageType
          : imageType // ignore: cast_nullable_to_non_nullable
              as String,
      results: null == results
          ? _value._results
          : results // ignore: cast_nullable_to_non_nullable
              as List<SimilarityResult>,
      maxSimilarity: null == maxSimilarity
          ? _value.maxSimilarity
          : maxSimilarity // ignore: cast_nullable_to_non_nullable
              as double,
      duplicateCount: null == duplicateCount
          ? _value.duplicateCount
          : duplicateCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$SimilarityGroupImpl implements _SimilarityGroup {
  const _$SimilarityGroupImpl(
      {required this.date,
      required this.imageType,
      required final List<SimilarityResult> results,
      required this.maxSimilarity,
      required this.duplicateCount})
      : _results = results;

  factory _$SimilarityGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$SimilarityGroupImplFromJson(json);

  @override
  final String date;
  @override
  final String imageType;
  final List<SimilarityResult> _results;
  @override
  List<SimilarityResult> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  final double maxSimilarity;
  @override
  final int duplicateCount;

  @override
  String toString() {
    return 'SimilarityGroup(date: $date, imageType: $imageType, results: $results, maxSimilarity: $maxSimilarity, duplicateCount: $duplicateCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SimilarityGroupImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.imageType, imageType) ||
                other.imageType == imageType) &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            (identical(other.maxSimilarity, maxSimilarity) ||
                other.maxSimilarity == maxSimilarity) &&
            (identical(other.duplicateCount, duplicateCount) ||
                other.duplicateCount == duplicateCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      date,
      imageType,
      const DeepCollectionEquality().hash(_results),
      maxSimilarity,
      duplicateCount);

  /// Create a copy of SimilarityGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SimilarityGroupImplCopyWith<_$SimilarityGroupImpl> get copyWith =>
      __$$SimilarityGroupImplCopyWithImpl<_$SimilarityGroupImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SimilarityGroupImplToJson(
      this,
    );
  }
}

abstract class _SimilarityGroup implements SimilarityGroup {
  const factory _SimilarityGroup(
      {required final String date,
      required final String imageType,
      required final List<SimilarityResult> results,
      required final double maxSimilarity,
      required final int duplicateCount}) = _$SimilarityGroupImpl;

  factory _SimilarityGroup.fromJson(Map<String, dynamic> json) =
      _$SimilarityGroupImpl.fromJson;

  @override
  String get date;
  @override
  String get imageType;
  @override
  List<SimilarityResult> get results;
  @override
  double get maxSimilarity;
  @override
  int get duplicateCount;

  /// Create a copy of SimilarityGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SimilarityGroupImplCopyWith<_$SimilarityGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
} 