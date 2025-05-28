// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_annotation_target, unnecessary_question_mark

part of 'favorite_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FavoriteItem _$FavoriteItemFromJson(Map<String, dynamic> json) {
  return _FavoriteItem.fromJson(json);
}

/// @nodoc
mixin _$FavoriteItem {
  String get id => throw _privateConstructorUsedError;
  FavoriteType get type => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get imagePath => throw _privateConstructorUsedError;
  String? get date => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FavoriteItemCopyWith<FavoriteItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FavoriteItemCopyWith<$Res> {
  factory $FavoriteItemCopyWith(
          FavoriteItem value, $Res Function(FavoriteItem) then) =
      _$FavoriteItemCopyWithImpl<$Res, FavoriteItem>;
  @useResult
  $Res call(
      {String id,
      FavoriteType type,
      String name,
      DateTime createdAt,
      String? description,
      String? imagePath,
      String? date});
}

/// @nodoc
class _$FavoriteItemCopyWithImpl<$Res, $Val extends FavoriteItem>
    implements $FavoriteItemCopyWith<$Res> {
  _$FavoriteItemCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? name = null,
    Object? createdAt = null,
    Object? description = freezed,
    Object? imagePath = freezed,
    Object? date = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id ? _value.id : id as String,
      type: null == type ? _value.type : type as FavoriteType,
      name: null == name ? _value.name : name as String,
      createdAt: null == createdAt ? _value.createdAt : createdAt as DateTime,
      description: freezed == description ? _value.description : description as String?,
      imagePath: freezed == imagePath ? _value.imagePath : imagePath as String?,
      date: freezed == date ? _value.date : date as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FavoriteItemImplCopyWith<$Res>
    implements $FavoriteItemCopyWith<$Res> {
  factory _$$FavoriteItemImplCopyWith(
          _$FavoriteItemImpl value, $Res Function(_$FavoriteItemImpl) then) =
      __$$FavoriteItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      FavoriteType type,
      String name,
      DateTime createdAt,
      String? description,
      String? imagePath,
      String? date});
}

/// @nodoc
class __$$FavoriteItemImplCopyWithImpl<$Res>
    extends _$FavoriteItemCopyWithImpl<$Res, _$FavoriteItemImpl>
    implements _$$FavoriteItemImplCopyWith<$Res> {
  __$$FavoriteItemImplCopyWithImpl(
      _$FavoriteItemImpl _value, $Res Function(_$FavoriteItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? name = null,
    Object? createdAt = null,
    Object? description = freezed,
    Object? imagePath = freezed,
    Object? date = freezed,
  }) {
    return _then(_$FavoriteItemImpl(
      id: null == id ? _value.id : id as String,
      type: null == type ? _value.type : type as FavoriteType,
      name: null == name ? _value.name : name as String,
      createdAt: null == createdAt ? _value.createdAt : createdAt as DateTime,
      description: freezed == description ? _value.description : description as String?,
      imagePath: freezed == imagePath ? _value.imagePath : imagePath as String?,
      date: freezed == date ? _value.date : date as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FavoriteItemImpl implements _FavoriteItem {
  const _$FavoriteItemImpl(
      {required this.id,
      required this.type,
      required this.name,
      required this.createdAt,
      this.description,
      this.imagePath,
      this.date});

  factory _$FavoriteItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$FavoriteItemImplFromJson(json);

  @override
  final String id;
  @override
  final FavoriteType type;
  @override
  final String name;
  @override
  final DateTime createdAt;
  @override
  final String? description;
  @override
  final String? imagePath;
  @override
  final String? date;

  @override
  String toString() {
    return 'FavoriteItem(id: $id, type: $type, name: $name, createdAt: $createdAt, description: $description, imagePath: $imagePath, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FavoriteItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath) &&
            (identical(other.date, date) || other.date == date));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, type, name, createdAt, description, imagePath, date);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FavoriteItemImplCopyWith<_$FavoriteItemImpl> get copyWith =>
      __$$FavoriteItemImplCopyWithImpl<_$FavoriteItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FavoriteItemImplToJson(this);
  }
}

abstract class _FavoriteItem implements FavoriteItem {
  const factory _FavoriteItem(
      {required final String id,
      required final FavoriteType type,
      required final String name,
      required final DateTime createdAt,
      final String? description,
      final String? imagePath,
      final String? date}) = _$FavoriteItemImpl;

  factory _FavoriteItem.fromJson(Map<String, dynamic> json) =
      _$FavoriteItemImpl.fromJson;

  @override
  String get id;
  @override
  FavoriteType get type;
  @override
  String get name;
  @override
  DateTime get createdAt;
  @override
  String? get description;
  @override
  String? get imagePath;
  @override
  String? get date;
  @override
  @JsonKey(ignore: true)
  _$$FavoriteItemImplCopyWith<_$FavoriteItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
} 