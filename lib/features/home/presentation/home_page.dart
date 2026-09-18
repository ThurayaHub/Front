import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/thuraya_bottom_navigation_bar.dart';
import 'package:thuraya/features/choose_restaurant/presentation/choose_restaurant_arabic_labels.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/models/restaurant_search_filters.dart';
import 'package:thuraya/features/home/presentation/restaurant_search_controller.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_filter_sheet.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_search_result_card.dart';
import 'package:thuraya/features/home/presentation/widgets/thuraya_map.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.controller});

  final RestaurantSearchController? controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Duration _suggestionDebounceDuration = Duration(
    milliseconds: 300,
  );

  late final RestaurantSearchController _controller;
  late final bool _ownsController;
  late final TextEditingController _searchController;
  Timer? _suggestionDebounce;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? RestaurantSearchController();
    _searchController = TextEditingController(
      text: _controller.filters.searchText,
    );
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    _searchController.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _submitSearch() async {
    _suggestionDebounce?.cancel();
    _controller.clearSuggestions();
    FocusScope.of(context).unfocus();
    await _controller.applyFilters(
      _controller.filters.copyWith(searchText: _searchController.text),
    );
  }

  Future<void> _openFilters() async {
    _suggestionDebounce?.cancel();
    _controller.clearSuggestions();
    FocusScope.of(context).unfocus();
    final filters = await showModalBottomSheet<RestaurantSearchFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (context) => RestaurantFilterSheet(
        controller: _controller,
        initialFilters: _controller.filters.copyWith(
          searchText: _searchController.text,
        ),
      ),
    );
    if (filters == null || !mounted) return;
    _searchController.text = filters.searchText;
    await _controller.applyFilters(filters);
  }

  Future<void> _clearAll() async {
    _suggestionDebounce?.cancel();
    _controller.clearSuggestions();
    _searchController.clear();
    await _controller.clearAll();
  }

  void _onSearchChanged(String value) {
    _suggestionDebounce?.cancel();
    if (value.trim().isEmpty) {
      _controller.clearSuggestions();
      return;
    }
    _suggestionDebounce = Timer(_suggestionDebounceDuration, () {
      if (!mounted) return;
      unawaited(_controller.loadSuggestions(value));
    });
  }

  void _onSearchFocusChanged(bool focused) {
    if (_isSearchFocused != focused) {
      setState(() => _isSearchFocused = focused);
    }
    if (focused && _searchController.text.trim().isNotEmpty) {
      _onSearchChanged(_searchController.text);
    } else if (!focused) {
      _suggestionDebounce?.cancel();
    }
  }

  Future<void> _selectSuggestion(RestaurantMapMarker suggestion) async {
    _suggestionDebounce?.cancel();
    final languageCode = Localizations.localeOf(context).languageCode;
    final name = suggestion.localizedName(languageCode);
    _searchController.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
    _controller.clearSuggestions();
    FocusScope.of(context).unfocus();
    await _controller.applyFilters(
      _controller.filters.copyWith(searchText: name),
    );
  }

  Future<void> _clearSearchText() async {
    _suggestionDebounce?.cancel();
    _controller.clearSuggestions();
    _searchController.clear();
    await _controller.applyFilters(
      _controller.filters.copyWith(searchText: ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.panel,
      bottomNavigationBar: const ThurayaBottomNavigationBar(
        selectedTab: ThurayaNavigationTab.home,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final hasActiveCriteria = _controller.filters.isActive;
          final controlsBottom = hasActiveCriteria ? 202.0 : 156.0;
          final showSuggestions =
              _isSearchFocused &&
              _searchController.text.trim().isNotEmpty &&
              (_controller.isLoadingSuggestions ||
                  _controller.suggestions.isNotEmpty);
          return Stack(
            key: const ValueKey('home-page'),
            fit: StackFit.expand,
            children: [
              IndexedStack(
                index: _controller.resultsView.index,
                children: [
                  ThurayaMap(
                    padding: EdgeInsets.only(top: controlsBottom, bottom: 90),
                    restaurants: _controller.results,
                    onViewportChanged: _controller.loadViewport,
                    fitRestaurants: _controller.shouldFitSearchResults,
                  ),
                  _RestaurantResultsList(
                    controller: _controller,
                    topPadding: controlsBottom + 8,
                  ),
                ],
              ),
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.screen,
                      AppSpacing.screen,
                      AppSpacing.screen,
                      0,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HomeSearchBar(
                            controller: _searchController,
                            onSearch: _submitSearch,
                            onChanged: _onSearchChanged,
                            onFocusChanged: _onSearchFocusChanged,
                            onClearText: _clearSearchText,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              _ResultCountPill(
                                count: _controller.results.length,
                              ),
                              const Spacer(),
                              _ResultsViewSwitch(controller: _controller),
                            ],
                          ),
                          if (hasActiveCriteria) ...[
                            const SizedBox(height: AppSpacing.xs),
                            _ActiveFilterStrip(
                              controller: _controller,
                              onClearAll: _clearAll,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_controller.isLoading)
                PositionedDirectional(
                  top: MediaQuery.paddingOf(context).top + controlsBottom - 3,
                  start: AppSpacing.screen,
                  end: AppSpacing.screen,
                  child: const ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                    child: LinearProgressIndicator(
                      key: ValueKey('restaurant-search-loading'),
                      minHeight: 3,
                      color: AppColors.primary,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              if (!_controller.isLoading &&
                  _controller.results.isEmpty &&
                  !_controller.hasSearchError)
                _EmptyResultsOverlay(
                  topPadding: controlsBottom,
                  showClear: _controller.filters.isActive,
                  onClear: _clearAll,
                ),
              if (_controller.hasSearchError && _controller.results.isEmpty)
                _SearchErrorOverlay(
                  topPadding: controlsBottom,
                  onRetry: () => _controller.search(force: true),
                ),
              if (_controller.hasSearchError && _controller.results.isNotEmpty)
                PositionedDirectional(
                  top: MediaQuery.paddingOf(context).top + controlsBottom + 6,
                  start: AppSpacing.screen,
                  end: AppSpacing.screen,
                  child: _CompactErrorBanner(
                    onRetry: () => _controller.search(force: true),
                  ),
                ),
              if (showSuggestions)
                PositionedDirectional(
                  top:
                      MediaQuery.paddingOf(context).top +
                      AppSpacing.screen +
                      72,
                  start: AppSpacing.screen,
                  end: AppSpacing.screen,
                  child: _RestaurantSuggestionDropdown(
                    suggestions: _controller.suggestions,
                    isLoading: _controller.isLoadingSuggestions,
                    onSelected: _selectSuggestion,
                  ),
                ),
              PositionedDirectional(
                top: MediaQuery.paddingOf(context).top + AppSpacing.screen + 9,
                end: AppSpacing.screen + 10,
                child: _HomeFilterButton(
                  activeFilterCount: _controller.filters.activeFilterCount,
                  onTap: _openFilters,
                ),
              ),
              PositionedDirectional(
                top: MediaQuery.paddingOf(context).top + AppSpacing.screen + 9,
                start: AppSpacing.screen + 8,
                child: _HomeSearchSubmitButton(onTap: _submitSearch),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeSearchBar extends StatefulWidget {
  const _HomeSearchBar({
    required this.controller,
    required this.onSearch,
    required this.onChanged,
    required this.onFocusChanged,
    required this.onClearText,
  });

  final TextEditingController controller;
  final Future<void> Function() onSearch;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onFocusChanged;
  final Future<void> Function() onClearText;

  @override
  State<_HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<_HomeSearchBar> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant _HomeSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  void _onTextChanged() => setState(() {});

  void _onFocusChanged() => widget.onFocusChanged(_focusNode.hasFocus);

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(9999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          key: const ValueKey('home-search-bar'),
          height: 66,
          padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 10, 0),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: AppColors.inputHint.withValues(alpha: 0.3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x141A237E),
                offset: Offset(0, 4),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox.square(dimension: 48),
              Expanded(
                child: TextField(
                  key: const ValueKey('home-search-input'),
                  controller: widget.controller,
                  focusNode: _focusNode,
                  textAlign: TextAlign.start,
                  textInputAction: TextInputAction.search,
                  onChanged: widget.onChanged,
                  onSubmitted: (_) => widget.onSearch(),
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  style: AppTextStyles.homeSearchHint.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: localizations.searchRestaurant,
                    hintStyle: AppTextStyles.homeSearchHint,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ),
              if (widget.controller.text.isNotEmpty)
                IconButton(
                  key: const ValueKey('home-search-clear'),
                  tooltip: localizations.clearAll,
                  onPressed: widget.onClearText,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              const SizedBox.square(dimension: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeFilterButton extends StatelessWidget {
  const _HomeFilterButton({
    required this.activeFilterCount,
    required this.onTap,
  });

  final int activeFilterCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: localizations.filterRestaurants,
      child: GestureDetector(
        key: const ValueKey('home-filter'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: 48,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              SvgPicture.asset(
                AppAssets.homeFilter,
                width: 20,
                height: 15,
                colorFilter: ColorFilter.mode(
                  activeFilterCount > 0
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
              if (activeFilterCount > 0)
                PositionedDirectional(
                  top: 0,
                  end: -2,
                  child: Container(
                    key: const ValueKey('home-filter-badge'),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$activeFilterCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeSearchSubmitButton extends StatelessWidget {
  const _HomeSearchSubmitButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).searchRestaurant,
      child: GestureDetector(
        key: const ValueKey('home-search-submit'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: SvgPicture.asset(
              AppAssets.homeSearch,
              width: 30,
              height: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _RestaurantSuggestionDropdown extends StatelessWidget {
  const _RestaurantSuggestionDropdown({
    required this.suggestions,
    required this.isLoading,
    required this.onSelected,
  });

  final List<RestaurantMapMarker> suggestions;
  final bool isLoading;
  final ValueChanged<RestaurantMapMarker> onSelected;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return Material(
      key: const ValueKey('restaurant-suggestion-dropdown'),
      color: AppColors.surface,
      elevation: 8,
      shadowColor: AppColors.shadow.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const LinearProgressIndicator(
              key: ValueKey('restaurant-suggestions-loading'),
              minHeight: 2,
              color: AppColors.primary,
              backgroundColor: Colors.transparent,
            ),
          if (suggestions.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                key: const ValueKey('restaurant-suggestion-list'),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                itemCount: suggestions.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  indent: 56,
                  endIndent: AppSpacing.md,
                  color: AppColors.panelBorder,
                ),
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  final neighborhood = suggestion.localizedNeighborhood(
                    languageCode,
                  );
                  return ListTile(
                    key: ValueKey('restaurant-suggestion-${suggestion.id}'),
                    dense: true,
                    leading: Icon(
                      suggestion.placeType == RestaurantMapPlaceType.cafe
                          ? Icons.local_cafe_outlined
                          : Icons.restaurant_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      suggestion.localizedName(languageCode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: neighborhood.isEmpty
                        ? null
                        : Text(
                            neighborhood,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardMetadata.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                    trailing: const Icon(
                      Icons.north_west_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    onTap: () => onSelected(suggestion),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultCountPill extends StatelessWidget {
  const _ResultCountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return _GlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Text(
        AppLocalizations.of(context).restaurantResultsCount(count),
        key: const ValueKey('restaurant-result-count'),
        style: AppTextStyles.cardMetadata.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ResultsViewSwitch extends StatelessWidget {
  const _ResultsViewSwitch({required this.controller});

  final RestaurantSearchController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _GlassPill(
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewOption(
            key: const ValueKey('results-map-view'),
            label: l10n.mapView,
            icon: Icons.map_outlined,
            selected: controller.resultsView == RestaurantResultsView.map,
            onTap: () => controller.setResultsView(RestaurantResultsView.map),
          ),
          _ViewOption(
            key: const ValueKey('results-list-view'),
            label: l10n.listView,
            icon: Icons.view_agenda_outlined,
            selected: controller.resultsView == RestaurantResultsView.list,
            onTap: () => controller.setResultsView(RestaurantResultsView.list),
          ),
        ],
      ),
    );
  }
}

class _ViewOption extends StatelessWidget {
  const _ViewOption({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.panelBorder),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _ActiveFilterStrip extends StatelessWidget {
  const _ActiveFilterStrip({
    required this.controller,
    required this.onClearAll,
  });

  final RestaurantSearchController controller;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final filters = controller.filters;
    return SizedBox(
      height: 38,
      child: ListView(
        key: const ValueKey('active-filter-strip'),
        scrollDirection: Axis.horizontal,
        children: [
          if (filters.hasSearchText)
            _ActiveChip(
              label: '“${filters.searchText.trim()}”',
              onDeleted: () =>
                  controller.applyFilters(filters.copyWith(searchText: '')),
            ),
          for (final id in filters.priceLevelIds)
            _ActiveChip(
              label: ChooseRestaurantArabicLabels.priceSymbol(
                controller.priceLevelById(id)?.name ?? '',
              ),
              ltr: true,
              onDeleted: () => controller.applyFilters(
                filters.copyWith(
                  priceLevelIds: {...filters.priceLevelIds}..remove(id),
                ),
              ),
            ),
          for (final id in filters.categoryIds)
            _ActiveChip(
              label: ChooseRestaurantArabicLabels.categoryName(
                controller.categoryById(id)?.name ?? '',
              ),
              onDeleted: () => controller.applyFilters(
                filters.copyWith(
                  categoryIds: {...filters.categoryIds}..remove(id),
                ),
              ),
            ),
          if (filters.minimumUserRating != null)
            _ActiveChip(
              label:
                  '★ ${filters.minimumUserRating}${filters.minimumUserRating == 5 ? '' : '+'}',
              onDeleted: () => controller.applyFilters(
                filters.copyWith(minimumUserRating: null),
              ),
            ),
          if (filters.hasThurayaRating)
            _ActiveChip(
              label: '★ ${AppLocalizations.of(context).hasThurayaRatingFilter}',
              onDeleted: () => controller.applyFilters(
                filters.copyWith(hasThurayaRating: false),
              ),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: TextButton(
              key: const ValueKey('active-filters-clear-all'),
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(AppLocalizations.of(context).clearAll),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({
    required this.label,
    required this.onDeleted,
    this.ltr = false,
  });

  final String label;
  final VoidCallback onDeleted;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: InputChip(
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        side: const BorderSide(color: AppColors.panelBorder),
        deleteIconColor: AppColors.textMuted,
        deleteIcon: const Icon(Icons.close_rounded, size: 16),
        label: Directionality(
          textDirection: ltr ? TextDirection.ltr : Directionality.of(context),
          child: Text(label, style: AppTextStyles.cardMetadata),
        ),
        onDeleted: onDeleted,
      ),
    );
  }
}

class _RestaurantResultsList extends StatelessWidget {
  const _RestaurantResultsList({
    required this.controller,
    required this.topPadding,
  });

  final RestaurantSearchController controller;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.panel,
      child: ListView.separated(
        key: const ValueKey('restaurant-results-list'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsetsDirectional.fromSTEB(
          AppSpacing.screen,
          MediaQuery.paddingOf(context).top + topPadding,
          AppSpacing.screen,
          116,
        ),
        itemCount: controller.results.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final restaurant = controller.results[index];
          return RestaurantSearchResultCard(
            restaurant: restaurant,
            onTap: () => Navigator.of(context).pushNamed(
              AppRouteNames.restaurantDetails,
              arguments: restaurant.id,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyResultsOverlay extends StatelessWidget {
  const _EmptyResultsOverlay({
    required this.topPadding,
    required this.showClear,
    required this.onClear,
  });

  final double topPadding;
  final bool showClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _CenteredStatusCard(
      topPadding: topPadding,
      icon: Icons.search_off_rounded,
      title: l10n.noSearchResultsTitle,
      subtitle: l10n.noSearchResultsSubtitle,
      actionLabel: showClear ? l10n.clearFilters : null,
      onAction: showClear ? onClear : null,
    );
  }
}

class _SearchErrorOverlay extends StatelessWidget {
  const _SearchErrorOverlay({required this.topPadding, required this.onRetry});

  final double topPadding;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _CenteredStatusCard(
      topPadding: topPadding,
      icon: Icons.wifi_off_rounded,
      title: l10n.searchResultsError,
      subtitle: l10n.noSearchResultsSubtitle,
      actionLabel: l10n.retry,
      onAction: onRetry,
    );
  }
}

class _CenteredStatusCard extends StatelessWidget {
  const _CenteredStatusCard({
    required this.topPadding,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final double topPadding;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: MediaQuery.paddingOf(context).top + topPadding + AppSpacing.md,
      start: AppSpacing.screen,
      end: AppSpacing.screen,
      bottom: 100,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Color(0x171A237E), blurRadius: 24),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 34),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.homeCardTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.homeCategory,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactErrorBanner extends StatelessWidget {
  const _CompactErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 8, 6),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 19),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.searchResultsError,
                style: AppTextStyles.cardMetadata,
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}
