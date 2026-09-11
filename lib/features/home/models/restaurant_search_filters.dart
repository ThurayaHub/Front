import 'package:thuraya/features/home/models/supported_map_region.dart';

class RestaurantSearchFilters {
  RestaurantSearchFilters({
    this.searchText = '',
    Set<int> priceLevelIds = const {},
    Set<int> categoryIds = const {},
    this.minimumUserRating,
    this.hasThurayaRating = false,
  }) : priceLevelIds = Set.unmodifiable(priceLevelIds),
       categoryIds = Set.unmodifiable(categoryIds);

  final String searchText;
  final Set<int> priceLevelIds;
  final Set<int> categoryIds;
  final int? minimumUserRating;
  final bool hasThurayaRating;

  bool get hasSearchText => searchText.trim().isNotEmpty;

  bool get hasFilters =>
      priceLevelIds.isNotEmpty ||
      categoryIds.isNotEmpty ||
      minimumUserRating != null ||
      hasThurayaRating;

  bool get isActive => hasSearchText || hasFilters;

  int get activeFilterCount =>
      priceLevelIds.length +
      categoryIds.length +
      (minimumUserRating == null ? 0 : 1) +
      (hasThurayaRating ? 1 : 0);

  RestaurantSearchFilters copyWith({
    String? searchText,
    Set<int>? priceLevelIds,
    Set<int>? categoryIds,
    Object? minimumUserRating = _unchanged,
    bool? hasThurayaRating,
  }) {
    return RestaurantSearchFilters(
      searchText: searchText ?? this.searchText,
      priceLevelIds: priceLevelIds ?? this.priceLevelIds,
      categoryIds: categoryIds ?? this.categoryIds,
      minimumUserRating: identical(minimumUserRating, _unchanged)
          ? this.minimumUserRating
          : minimumUserRating as int?,
      hasThurayaRating: hasThurayaRating ?? this.hasThurayaRating,
    );
  }

  Map<String, Object?> toJson(SupportedMapBounds bounds, {int limit = 500}) {
    final prices = priceLevelIds.toList()..sort();
    final categories = categoryIds.toList()..sort();
    return {
      'searchText': searchText.trim().isEmpty ? null : searchText.trim(),
      'priceLevelIds': prices,
      'categoryIds': categories,
      'minimumUserRating': minimumUserRating,
      'hasThurayaRating': hasThurayaRating,
      'north': bounds.northeastLatitude,
      'south': bounds.southwestLatitude,
      'east': bounds.northeastLongitude,
      'west': bounds.southwestLongitude,
      'limit': limit,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is RestaurantSearchFilters &&
        other.searchText.trim() == searchText.trim() &&
        _setEquals(other.priceLevelIds, priceLevelIds) &&
        _setEquals(other.categoryIds, categoryIds) &&
        other.minimumUserRating == minimumUserRating &&
        other.hasThurayaRating == hasThurayaRating;
  }

  @override
  int get hashCode => Object.hash(
    searchText.trim(),
    Object.hashAll(priceLevelIds.toList()..sort()),
    Object.hashAll(categoryIds.toList()..sort()),
    minimumUserRating,
    hasThurayaRating,
  );
}

const Object _unchanged = Object();

bool _setEquals(Set<int> left, Set<int> right) {
  return left.length == right.length && left.containsAll(right);
}
