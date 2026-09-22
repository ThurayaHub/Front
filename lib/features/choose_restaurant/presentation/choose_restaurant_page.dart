import 'package:flutter/material.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/network/api_config.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/thuraya_bottom_navigation_bar.dart';
import 'package:thuraya/core/widgets/thuraya_loading_indicator.dart';
import 'package:thuraya/core/widgets/thuraya_star_badge.dart';
import 'package:thuraya/features/choose_restaurant/models/choose_restaurant_dto.dart';
import 'package:thuraya/features/choose_restaurant/models/restaurant_lookup.dart';
import 'package:thuraya/features/choose_restaurant/presentation/choose_restaurant_arabic_labels.dart';
import 'package:thuraya/features/choose_restaurant/presentation/choose_restaurant_controller.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class ChooseRestaurantPage extends StatefulWidget {
  const ChooseRestaurantPage({super.key, this.controller});

  final ChooseRestaurantController? controller;

  @override
  State<ChooseRestaurantPage> createState() => _ChooseRestaurantPageState();
}

class _ChooseRestaurantPageState extends State<ChooseRestaurantPage> {
  late final ChooseRestaurantController _controller;
  late final bool _ownsController;
  final _neighborhoodSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? ChooseRestaurantController();
    _controller.addListener(_refresh);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    if (_ownsController) _controller.dispose();
    _neighborhoodSearchController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _goBack() {
    FocusScope.of(context).unfocus();
    if (_controller.recommendationStatus != RecommendationStatus.idle) {
      _controller.changeSelections();
    } else if (_controller.step > 0) {
      _controller.previousStep();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const ValueKey('choose-restaurant-page'),
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      bottomNavigationBar: const ThurayaBottomNavigationBar(
        selectedTab: ThurayaNavigationTab.chooseRestaurant,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ChooseHeader(title: l10n.chooseRestaurant, onBack: _goBack),
            Expanded(child: _buildBody(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return switch (_controller.lookupStatus) {
      ChooseLookupStatus.idle ||
      ChooseLookupStatus.loading => const _CenteredStatus(
        key: ValueKey('choose-lookups-loading'),
        loading: true,
      ),
      ChooseLookupStatus.error => _CenteredStatus(
        key: const ValueKey('choose-lookups-error'),
        icon: Icons.cloud_off_rounded,
        message: l10n.chooseLookupError,
        actionLabel: l10n.retry,
        onAction: _controller.initialize,
      ),
      ChooseLookupStatus.ready => _buildReadyBody(l10n),
    };
  }

  Widget _buildReadyBody(AppLocalizations l10n) {
    final status = _controller.recommendationStatus;
    if (status == RecommendationStatus.loading) {
      return _RecommendationLoading(message: l10n.chooseLoading);
    }
    if (status == RecommendationStatus.noMatch) {
      return _RecommendationMessage(
        key: const ValueKey('choose-no-match'),
        icon: Icons.travel_explore_rounded,
        title: l10n.noMatchTitle,
        subtitle: l10n.noMatchSubtitle,
        primaryLabel: l10n.editSelections,
        onPrimary: _controller.changeSelections,
        secondaryLabel: l10n.chooseAnother,
        onSecondary: _controller.requestRecommendation,
      );
    }
    if (status == RecommendationStatus.error) {
      return _RecommendationMessage(
        key: const ValueKey('choose-request-error'),
        icon: Icons.sentiment_dissatisfied_rounded,
        title: l10n.chooseRequestError,
        primaryLabel: l10n.retry,
        onPrimary: _controller.requestRecommendation,
        secondaryLabel: l10n.changeSelections,
        onSecondary: _controller.changeSelections,
      );
    }
    if (status == RecommendationStatus.success &&
        _controller.recommendation != null) {
      return _RecommendationResult(
        recommendation: _controller.recommendation!,
        onViewRestaurant: _openRestaurant,
        onChooseAnother: _controller.requestRecommendation,
        onChangeSelections: _controller.changeSelections,
      );
    }

    return Column(
      children: [
        _ProgressHeader(step: _controller.step, l10n: l10n),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(.06, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: switch (_controller.step) {
              0 => _PriceStep(
                key: const ValueKey('choose-price-step'),
                priceLevels: _controller.priceLevels,
                selectedIds: _controller.selectedPriceLevelIds,
                onToggle: _controller.togglePriceLevel,
              ),
              1 => _CategoryStep(
                key: const ValueKey('choose-category-step'),
                categories: _controller.categories,
                allSelected: _controller.allCategoriesSelected,
                selectedIds: _controller.selectedCategoryIds,
                onAllCategories: _controller.useAllCategories,
                onToggle: _controller.toggleCategory,
              ),
              _ => _NeighborhoodStep(
                key: const ValueKey('choose-neighborhood-step'),
                searchController: _neighborhoodSearchController,
                neighborhoods: _controller.filteredNeighborhoods,
                allNeighborhoods: _controller.neighborhoods,
                allNeighborhoodsSelected:
                    _controller.selectedNeighborhoodIds.isEmpty,
                selectedIds: _controller.selectedNeighborhoodIds,
                onSearchChanged: _controller.updateNeighborhoodQuery,
                onAllNeighborhoods: _controller.useAllNeighborhoods,
                onToggle: _controller.toggleNeighborhood,
              ),
            },
          ),
        ),
        _StepAction(
          isLastStep: _controller.step == 2,
          enabled: _controller.canContinue,
          onPressed: _controller.step == 2
              ? _controller.requestRecommendation
              : _controller.nextStep,
        ),
      ],
    );
  }

  void _openRestaurant() {
    final recommendation = _controller.recommendation;
    if (recommendation == null) return;
    Navigator.of(context).pushNamed(
      AppRouteNames.restaurantDetails,
      arguments: recommendation.details ?? recommendation.selection.id,
    );
  }
}

class _ChooseHeader extends StatelessWidget {
  const _ChooseHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
        ),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('choose-back'),
              tooltip: AppLocalizations.of(context).back,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.primary,
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.cardTitle.copyWith(
                  color: AppColors.primary,
                  fontSize: 21,
                ),
              ),
            ),
            const SizedBox.square(dimension: 48),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step, required this.l10n});

  final int step;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          Text(
            '${step + 1} ${l10n.chooseStepOf} 3',
            key: const ValueKey('choose-step-progress'),
            style: AppTextStyles.detailsCaption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  height: 5,
                  margin: EdgeInsetsDirectional.only(
                    end: index == 2 ? 0 : AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: index <= step
                        ? AppColors.primary
                        : AppColors.panelBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepHeading extends StatelessWidget {
  const _StepHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.start,
          style: AppTextStyles.screenTitle.copyWith(
            color: AppColors.textPrimary,
            fontSize: 26,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          subtitle,
          textAlign: TextAlign.start,
          style: AppTextStyles.screenSubtitle.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _PriceStep extends StatelessWidget {
  const _PriceStep({
    super.key,
    required this.priceLevels,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<RestaurantLookupItemDto> priceLevels;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.screen,
      ),
      child: Column(
        children: [
          _StepHeading(
            title: l10n.choosePriceTitle,
            subtitle: l10n.choosePriceSubtitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: GridView.builder(
              key: const ValueKey('choose-price-grid'),
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.25,
              ),
              itemCount: priceLevels.length,
              itemBuilder: (context, index) {
                final item = priceLevels[index];
                return _PriceCard(
                  key: ValueKey('choose-price-${item.id}'),
                  item: item,
                  selected: selectedIds.contains(item.id),
                  onTap: () => onToggle(item.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final RestaurantLookupItemDto item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableSurface(
      selected: selected,
      semanticLabel: ChooseRestaurantArabicLabels.priceName(item.name),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              ChooseRestaurantArabicLabels.priceSymbol(item.name),
              style: AppTextStyles.screenTitle.copyWith(
                color: selected ? AppColors.onPrimary : AppColors.primary,
                fontSize: 28,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            ChooseRestaurantArabicLabels.priceName(item.name),
            style: AppTextStyles.cardTitle.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryStep extends StatelessWidget {
  const _CategoryStep({
    super.key,
    required this.categories,
    required this.allSelected,
    required this.selectedIds,
    required this.onAllCategories,
    required this.onToggle,
  });

  final List<RestaurantLookupItemDto> categories;
  final bool allSelected;
  final Set<int> selectedIds;
  final VoidCallback onAllCategories;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.screen,
      ),
      child: Column(
        children: [
          _StepHeading(
            title: l10n.chooseCategoryTitle,
            subtitle: l10n.chooseCategorySubtitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: GridView.builder(
              key: const ValueKey('choose-category-grid'),
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.45,
              ),
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _SelectableSurface(
                    key: const ValueKey('choose-category-all'),
                    selected: allSelected,
                    semanticLabel: l10n.allCuisines,
                    onTap: onAllCategories,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu_rounded,
                          size: 30,
                          color: allSelected
                              ? AppColors.onPrimary
                              : AppColors.primary,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.allCuisines,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: allSelected
                                ? AppColors.onPrimary
                                : AppColors.textPrimary,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final item = categories[index - 1];
                final selected = selectedIds.contains(item.id);
                return _SelectableSurface(
                  key: ValueKey('choose-category-${item.id}'),
                  selected: selected,
                  semanticLabel: ChooseRestaurantArabicLabels.categoryName(
                    item.name,
                  ),
                  onTap: () => onToggle(item.id),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        ChooseRestaurantArabicLabels.categoryIcon(item.name),
                        size: 30,
                        color: selected
                            ? AppColors.onPrimary
                            : AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        ChooseRestaurantArabicLabels.categoryName(item.name),
                        style: AppTextStyles.cardTitle.copyWith(
                          color: selected
                              ? AppColors.onPrimary
                              : AppColors.textPrimary,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableSurface extends StatelessWidget {
  const _SelectableSurface({
    super.key,
    required this.selected,
    required this.semanticLabel,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.panelBorder,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x24000666),
                    blurRadius: 18,
                    offset: Offset(0, 7),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Center(child: child),
                if (selected)
                  const PositionedDirectional(
                    top: AppSpacing.sm,
                    end: AppSpacing.sm,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: AppColors.onPrimary,
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

class _NeighborhoodStep extends StatelessWidget {
  const _NeighborhoodStep({
    super.key,
    required this.searchController,
    required this.neighborhoods,
    required this.allNeighborhoods,
    required this.allNeighborhoodsSelected,
    required this.selectedIds,
    required this.onSearchChanged,
    required this.onAllNeighborhoods,
    required this.onToggle,
  });

  final TextEditingController searchController;
  final List<NeighborhoodLookupDto> neighborhoods;
  final List<NeighborhoodLookupDto> allNeighborhoods;
  final bool allNeighborhoodsSelected;
  final Set<int> selectedIds;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAllNeighborhoods;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.screen,
      ),
      child: Column(
        children: [
          _StepHeading(
            title: l10n.chooseNeighborhoodTitle,
            subtitle: l10n.chooseNeighborhoodSubtitle,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const ValueKey('choose-neighborhood-search'),
            controller: searchController,
            onChanged: onSearchChanged,
            textAlign: TextAlign.start,
            textInputAction: TextInputAction.search,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText: l10n.searchNeighborhood,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.panelBorder),
              ),
            ),
          ),
          if (selectedIds.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.selectedNeighborhoods,
                style: AppTextStyles.detailsCaption.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 38,
              child: ListView.separated(
                key: const ValueKey('choose-selected-neighborhoods'),
                scrollDirection: Axis.horizontal,
                itemCount: selectedIds.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final id = selectedIds.elementAt(index);
                  final neighborhood = neighborhoodsForId(id);
                  return InputChip(
                    label: Text(neighborhood?.nameAr ?? ''),
                    onDeleted: () => onToggle(id),
                    deleteIcon: const Icon(Icons.close_rounded, size: 16),
                    backgroundColor: const Color(0xFFECECF7),
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    labelStyle: AppTextStyles.detailsCaption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.separated(
              key: const ValueKey('choose-neighborhood-list'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              itemCount: neighborhoods.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _NeighborhoodTile(
                    key: const ValueKey('choose-all-neighborhoods'),
                    title: l10n.allNeighborhoods,
                    subtitle: l10n.allNeighborhoodsHint,
                    selected: allNeighborhoodsSelected,
                    icon: Icons.public_rounded,
                    onTap: onAllNeighborhoods,
                  );
                }
                final neighborhood = neighborhoods[index - 1];
                return _NeighborhoodTile(
                  key: ValueKey('choose-neighborhood-${neighborhood.id}'),
                  title: neighborhood.nameAr,
                  subtitle: neighborhood.cityAr,
                  selected: selectedIds.contains(neighborhood.id),
                  icon: Icons.location_on_outlined,
                  onTap: () => onToggle(neighborhood.id),
                );
              },
            ),
          ),
          if (neighborhoods.isEmpty && searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                l10n.noNeighborhoodResults,
                style: AppTextStyles.screenSubtitle,
              ),
            ),
        ],
      ),
    );
  }

  NeighborhoodLookupDto? neighborhoodsForId(int id) {
    for (final neighborhood in allNeighborhoods) {
      if (neighborhood.id == id) return neighborhood;
    }
    return null;
  }
}

class _NeighborhoodTile extends StatelessWidget {
  const _NeighborhoodTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: selected ? const Color(0xFFEDEDF7) : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.panelBorder,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.panel,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 21,
                    color: selected ? AppColors.onPrimary : AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.detailsAwardTitle.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.detailsCaption,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    key: ValueKey(selected),
                    color: selected ? AppColors.primary : AppColors.panelBorder,
                    size: 23,
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

class _StepAction extends StatelessWidget {
  const _StepAction({
    required this.isLastStep,
    required this.enabled,
    required this.onPressed,
  });

  final bool isLastStep;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          _PrimaryButton(
            key: const ValueKey('choose-step-action'),
            label: isLastStep ? l10n.chooseRestaurant : l10n.next,
            icon: isLastStep
                ? Icons.auto_awesome_rounded
                : Icons.arrow_forward_rounded,
            onPressed: enabled ? onPressed : null,
          ),
          if (!enabled) ...[
            const SizedBox(height: 6),
            Text(
              l10n.selectionRequired,
              style: AppTextStyles.detailsCaption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecommendationLoading extends StatelessWidget {
  const _RecommendationLoading({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('choose-recommendation-loading'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ThurayaLoadingIndicator(size: 112),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationResult extends StatelessWidget {
  const _RecommendationResult({
    required this.recommendation,
    required this.onViewRestaurant,
    required this.onChooseAnother,
    required this.onChangeSelections,
  });

  final ChooseRestaurantRecommendation recommendation;
  final VoidCallback onViewRestaurant;
  final VoidCallback onChooseAnother;
  final VoidCallback onChangeSelections;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = _RecommendationViewData.fromRecommendation(recommendation);
    return SingleChildScrollView(
      key: const ValueKey('choose-recommendation-result'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.recommendationTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 25,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.recommendedRestaurant,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000666),
                  blurRadius: 26,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 218,
                  child: _RecommendationImage(source: data.image),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        data.name,
                        key: const ValueKey('choose-result-name'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 23),
                      ),
                      if (data.hasThurayaStar) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: ThurayaStarBadge(
                            key: const ValueKey(
                              'choose-recommendation-thuraya-star',
                            ),
                            hasThurayaStar: true,
                            size: 22,
                            variant: ThurayaStarBadgeVariant.compact,
                          ),
                        ),
                      ],
                      if (data.metadata.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          data.metadata,
                          style: AppTextStyles.homeCategory.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      if (data.description.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          data.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.screenSubtitle.copyWith(
                            height: 1.55,
                          ),
                        ),
                      ],
                      if (data.thurayaRating != null ||
                          data.userRating != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        const Divider(height: 1, color: AppColors.panelBorder),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.lg,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (data.thurayaRating case final rating?)
                              _RatingValue(
                                rating: rating,
                                color: AppColors.primary,
                              ),
                            if (data.userRating case final rating?)
                              _RatingValue(
                                rating: rating,
                                count: data.reviewCount,
                                color: AppColors.secondary,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PrimaryButton(
            key: const ValueKey('choose-view-restaurant'),
            label: l10n.viewRestaurant,
            icon: Icons.restaurant_menu_rounded,
            onPressed: onViewRestaurant,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const ValueKey('choose-another'),
            onPressed: onChooseAnother,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.chooseAnother),
            style: _secondaryButtonStyle(),
          ),
          TextButton(
            key: const ValueKey('choose-change-selections'),
            onPressed: onChangeSelections,
            child: Text(l10n.changeSelections),
          ),
        ],
      ),
    );
  }
}

class _RatingValue extends StatelessWidget {
  const _RatingValue({required this.rating, required this.color, this.count});

  final double rating;
  final Color color;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 22, color: color),
          const SizedBox(width: 4),
          Text(
            _formatRating(rating),
            style: AppTextStyles.homeRating.copyWith(
              color: color == AppColors.primary
                  ? AppColors.primary
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 4),
            Text('($count)', style: AppTextStyles.detailsCaption),
          ],
        ],
      ),
    );
  }
}

class _RecommendationImage extends StatelessWidget {
  const _RecommendationImage({required this.source});

  final String? source;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      AppAssets.restaurantDetailsCover,
      key: const ValueKey('choose-result-image-fallback'),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
    final value = source?.trim();
    if (value == null || value.isEmpty) return fallback;
    final url = _absoluteMediaUrl(value);
    return Image.network(
      url,
      key: const ValueKey('choose-result-image'),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : Stack(
              fit: StackFit.expand,
              children: [
                fallback,
                const ColoredBox(
                  color: Color(0x66FFFFFF),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RecommendationMessage extends StatelessWidget {
  const _RecommendationMessage({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: Color(0xFFEDEDF7),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 38),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.screenSubtitle,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _PrimaryButton(label: primaryLabel, onPressed: onPrimary),
            const SizedBox(height: AppSpacing.xs),
            TextButton(onPressed: onSecondary, child: Text(secondaryLabel)),
          ],
        ),
      ),
    );
  }
}

class _CenteredStatus extends StatelessWidget {
  const _CenteredStatus({
    super.key,
    this.loading = false,
    this.icon,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final bool loading;
  final IconData? icon;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const CircularProgressIndicator(color: AppColors.primary)
            else
              Icon(icon, color: AppColors.primary, size: 42),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.screenSubtitle,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.panelBorder,
          disabledForegroundColor: AppColors.textMuted,
          elevation: onPressed == null ? 0 : 3,
          shadowColor: const Color(0x33000666),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: AppTextStyles.cardTitle.copyWith(fontSize: 17),
        ),
      ),
    );
  }
}

ButtonStyle _secondaryButtonStyle() {
  return OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.primary),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    textStyle: AppTextStyles.detailsAwardTitle.copyWith(
      fontWeight: FontWeight.w700,
    ),
  );
}

class _RecommendationViewData {
  const _RecommendationViewData({
    required this.name,
    required this.description,
    required this.metadata,
    required this.image,
    required this.hasThurayaStar,
    required this.thurayaRating,
    required this.userRating,
    required this.reviewCount,
  });

  factory _RecommendationViewData.fromRecommendation(
    ChooseRestaurantRecommendation recommendation,
  ) {
    final selection = recommendation.selection;
    final details = recommendation.details;
    final categories = (details?.categories ?? selection.categories)
        .map(
          (category) =>
              ChooseRestaurantArabicLabels.categoryName(category.name),
        )
        .toSet()
        .join('، ');
    final neighborhood =
        details?.localizedNeighborhood('ar').trim().isNotEmpty == true
        ? details!.localizedNeighborhood('ar').trim()
        : selection.localizedNeighborhood('ar').trim();
    final priceName = ChooseRestaurantArabicLabels.priceName(
      details?.priceLevelName ?? selection.priceLevelName ?? '',
    );
    final photos = details?.photos ?? const <RestaurantPhotoDto>[];
    final coverPhotos = photos.where((photo) => photo.isCoverPhoto);
    final photo = photos.isEmpty
        ? selection.mainPhotoUrl
        : (coverPhotos.isNotEmpty ? coverPhotos.first : photos.first).url;
    final thurayaValue = details?.thurayaReviewSummary.averageRating;
    final thurayaCount = details?.thurayaReviewSummary.totalReviews ?? 0;
    final userValue =
        details?.reviewSummary.userRatingAverage ?? selection.userRatingAverage;
    final reviewCount =
        details?.reviewSummary.reviewCount ?? selection.reviewCount;

    return _RecommendationViewData(
      name: details?.localizedName('ar').trim().isNotEmpty == true
          ? details!.localizedName('ar').trim()
          : selection.localizedName('ar').trim(),
      description: details?.localizedDescription('ar').trim().isNotEmpty == true
          ? details!.localizedDescription('ar').trim()
          : selection.localizedDescription('ar').trim(),
      metadata: [
        categories,
        neighborhood,
        priceName,
      ].where((value) => value.isNotEmpty).join(' • '),
      image: photo,
      hasThurayaStar:
          details?.hasThurayaStar ?? selection.hasThurayaStar,
      thurayaRating: thurayaValue == null || thurayaCount <= 0
          ? null
          : (thurayaValue / 2).clamp(0, 5).toDouble(),
      userRating: userValue == null || reviewCount <= 0
          ? null
          : userValue.clamp(0, 5).toDouble(),
      reviewCount: reviewCount,
    );
  }

  final String name;
  final String description;
  final String metadata;
  final String? image;
  final bool hasThurayaStar;
  final double? thurayaRating;
  final double? userRating;
  final int reviewCount;
}

String _absoluteMediaUrl(String value) {
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  final normalized = value.startsWith('/') ? value.substring(1) : value;
  final base = ApiConfig.baseUrl.endsWith('/')
      ? Uri.parse(ApiConfig.baseUrl)
      : Uri.parse('${ApiConfig.baseUrl}/');
  return base.resolve(normalized).toString();
}

String _formatRating(double rating) => rating == rating.roundToDouble()
    ? rating.toStringAsFixed(0)
    : rating.toStringAsFixed(1);
