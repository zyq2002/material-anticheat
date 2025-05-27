// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weighbridge_image_similarity_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$weighbridgeImageSimilarityServiceHash() =>
    r'4bd4c0b5dc3a7f8b8a3b2e5e6e8e9f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f';

/// See also [WeighbridgeImageSimilarityService].
@ProviderFor(WeighbridgeImageSimilarityService)
final weighbridgeImageSimilarityServiceProvider = AutoDisposeAsyncNotifierProvider<
    WeighbridgeImageSimilarityService, List<WeighbridgeImageSimilarityResult>>.internal(
  WeighbridgeImageSimilarityService.new,
  name: r'weighbridgeImageSimilarityServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$weighbridgeImageSimilarityServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$WeighbridgeImageSimilarityService
    = AutoDisposeAsyncNotifier<List<WeighbridgeImageSimilarityResult>>;

String _$weighbridgeSuspiciousImagesHash() =>
    r'4bd4c0b5dc3a7f8b8a3b2e5e6e8e9f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f';

/// See also [weighbridgeSuspiciousImages].
@ProviderFor(weighbridgeSuspiciousImages)
final weighbridgeSuspiciousImagesProvider = AutoDisposeProvider<AsyncValue<List<WeighbridgeImageSimilarityResult>>>.internal(
  weighbridgeSuspiciousImages,
  name: r'weighbridgeSuspiciousImagesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$weighbridgeSuspiciousImagesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WeighbridgeSuspiciousImagesRef = AutoDisposeProviderRef<AsyncValue<List<WeighbridgeImageSimilarityResult>>>; 