import 'package:flutter/material.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/features/choose_restaurant/presentation/choose_restaurant_arabic_labels.dart';
import 'package:thuraya/features/home/models/restaurant_search_filters.dart';
import 'package:thuraya/features/home/presentation/restaurant_search_controller.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class RestaurantFilterSheet extends StatefulWidget {
  const RestaurantFilterSheet({
    super.key,
    required this.controller,
    required this.initialFilters,
  });

  final RestaurantSearchController controller;
  final RestaurantSearchFilters initialFilters;

  @override
  State<RestaurantFilterSheet> createState() => _RestaurantFilterSheetState();
}

class _RestaurantFilterSheetState extends State<RestaurantFilterSheet> {
  late final TextEditingController _searchController;
  late Set<int> _priceLevelIds;
  late Set<int> _categoryIds;
  int? _minimumUserRating;
  late bool _hasThurayaRating;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFilters;
    _searchController = TextEditingController(text: initial.searchText);
    _priceLevelIds = {...initial.priceLevelIds};
    _categoryIds = {...initial.categoryIds};
    _minimumUserRating = initial.minimumUserRating;
    _hasThurayaRating = initial.hasThurayaRating;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _searchController.clear();
      _priceLevelIds = {};
      _categoryIds = {};
      _minimumUserRating = null;
      _hasThurayaRating = false;
    });
  }

  RestaurantSearchFilters get _filters => RestaurantSearchFilters(
    searchText: _searchController.text,
    priceLevelIds: _priceLevelIds,
    categoryIds: _categoryIds,
    minimumUserRating: _minimumUserRating,
    hasThurayaRating: _hasThurayaRating,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: bottomInset > 0 ? 0.98 : 0.9,
        child: Material(
          key: const ValueKey('restaurant-filter-sheet'),
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inputHint,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.screen,
                    AppSpacing.sm,
                    AppSpacing.screen,
                    AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.searchFiltersTitle,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      TextButton(
                        key: const ValueKey('filter-clear-all'),
                        onPressed: _clear,
                        child: Text(l10n.clearAll),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey('restaurant-filter-scroll'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.screen,
                      0,
                      AppSpacing.screen,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          key: const ValueKey('filter-search-input'),
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) =>
                              Navigator.of(context).pop(_filters),
                          decoration: InputDecoration(
                            hintText: l10n.searchRestaurant,
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () =>
                                        setState(_searchController.clear),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AnimatedBuilder(
                          animation: widget.controller,
                          builder: (context, _) => _LookupFilters(
                            controller: widget.controller,
                            priceLevelIds: _priceLevelIds,
                            categoryIds: _categoryIds,
                            onPriceChanged: (id, selected) => setState(() {
                              selected
                                  ? _priceLevelIds.add(id)
                                  : _priceLevelIds.remove(id);
                            }),
                            onCategoryChanged: (id, selected) => setState(() {
                              selected
                                  ? _categoryIds.add(id)
                                  : _categoryIds.remove(id);
                            }),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionTitle(
                          title: l10n.ratingFilter,
                          subtitle: l10n.minimumRatingHint,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (var rating = 1; rating <= 5; rating++)
                              ChoiceChip(
                                key: ValueKey('filter-rating-$rating'),
                                selected: _minimumUserRating == rating,
                                showCheckmark: false,
                                selectedColor: AppColors.secondary.withValues(
                                  alpha: 0.2,
                                ),
                                side: BorderSide(
                                  color: _minimumUserRating == rating
                                      ? AppColors.secondary
                                      : AppColors.panelBorder,
                                ),
                                backgroundColor: AppColors.surface,
                                avatar: const Icon(
                                  Icons.star_rounded,
                                  color: AppColors.secondary,
                                  size: 18,
                                ),
                                label: Text(rating == 5 ? '5' : '$rating+'),
                                onSelected: (selected) => setState(() {
                                  _minimumUserRating = selected ? rating : null;
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Semantics(
                          button: true,
                          toggled: _hasThurayaRating,
                          label: l10n.hasThurayaRatingFilter,
                          child: Material(
                            color: _hasThurayaRating
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: _hasThurayaRating
                                    ? AppColors.primary
                                    : AppColors.panelBorder,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: const ValueKey('filter-thuraya-rating'),
                              onTap: () => setState(
                                () => _hasThurayaRating = !_hasThurayaRating,
                              ),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.star_rounded,
                                        color: Colors.white,
                                        size: 21,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        l10n.hasThurayaRatingFilter,
                                        style: AppTextStyles.homeCardTitle
                                            .copyWith(
                                              color: AppColors.primary,
                                              fontSize: 16,
                                            ),
                                      ),
                                    ),
                                    _ToggleIndicator(
                                      selected: _hasThurayaRating,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.screen,
                    AppSpacing.sm,
                    AppSpacing.screen,
                    AppSpacing.md,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(color: AppColors.panelBorder),
                    ),
                  ),
                  child: FilledButton(
                    key: const ValueKey('filter-show-results'),
                    onPressed: () => Navigator.of(context).pop(_filters),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(l10n.showResults),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LookupFilters extends StatelessWidget {
  const _LookupFilters({
    required this.controller,
    required this.priceLevelIds,
    required this.categoryIds,
    required this.onPriceChanged,
    required this.onCategoryChanged,
  });

  final RestaurantSearchController controller;
  final Set<int> priceLevelIds;
  final Set<int> categoryIds;
  final void Function(int id, bool selected) onPriceChanged;
  final void Function(int id, bool selected) onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (controller.isLoadingLookups && controller.priceLevels.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (controller.hasLookupError && controller.priceLevels.isEmpty) {
      return _InlineLookupError(onRetry: controller.loadLookups);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title: l10n.priceFilter),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final price in controller.priceLevels)
              FilterChip(
                key: ValueKey('filter-price-${price.id}'),
                selected: priceLevelIds.contains(price.id),
                showCheckmark: false,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: priceLevelIds.contains(price.id)
                      ? AppColors.primary
                      : AppColors.panelBorder,
                ),
                label: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    ChooseRestaurantArabicLabels.priceSymbol(price.name),
                    style: TextStyle(
                      color: priceLevelIds.contains(price.id)
                          ? Colors.white
                          : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                onSelected: (selected) => onPriceChanged(price.id, selected),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle(title: l10n.categoryFilter),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final category in controller.categories)
              FilterChip(
                key: ValueKey('filter-category-${category.id}'),
                selected: categoryIds.contains(category.id),
                showCheckmark: false,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: categoryIds.contains(category.id)
                      ? AppColors.primary
                      : AppColors.panelBorder,
                ),
                avatar: Icon(
                  ChooseRestaurantArabicLabels.categoryIcon(category.name),
                  size: 18,
                  color: categoryIds.contains(category.id)
                      ? Colors.white
                      : AppColors.primary,
                ),
                label: Text(
                  ChooseRestaurantArabicLabels.categoryName(category.name),
                  style: TextStyle(
                    color: categoryIds.contains(category.id)
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
                onSelected: (selected) =>
                    onCategoryChanged(category.id, selected),
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: AppTextStyles.homeCardTitle),
        if (subtitle != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              subtitle!,
              style: AppTextStyles.cardMetadata,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _InlineLookupError extends StatelessWidget {
  const _InlineLookupError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l10n.filterOptionsError)),
          TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}

class _ToggleIndicator extends StatelessWidget {
  const _ToggleIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 46,
      height: 28,
      padding: const EdgeInsets.all(3),
      alignment: selected
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.inputHint,
        borderRadius: BorderRadius.circular(99),
      ),
      child: const SizedBox.square(
        dimension: 22,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
