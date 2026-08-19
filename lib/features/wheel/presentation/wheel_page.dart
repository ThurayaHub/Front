import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/thuraya_bottom_navigation_bar.dart';
import 'package:thuraya/features/wheel/presentation/widgets/dynamic_wheel.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class WheelPage extends StatefulWidget {
  const WheelPage({super.key});

  @override
  State<WheelPage> createState() => _WheelPageState();
}

class _WheelPageState extends State<WheelPage>
    with SingleTickerProviderStateMixin {
  final _optionController = TextEditingController();
  final _scrollController = ScrollController();
  final _random = math.Random();
  final List<String> _options = [];

  late final AnimationController _spinController;
  Animation<double>? _rotationAnimation;
  double _rotation = 0;
  String? _selectedOption;
  String? _validationMessage;
  bool _initialOptionsLoaded = false;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialOptionsLoaded) return;

    final localizations = AppLocalizations.of(context);
    _options.addAll([
      localizations.wheelOptionBurger,
      localizations.wheelOptionPizza,
      localizations.wheelOptionSushi,
      localizations.wheelOptionCoffee,
    ]);
    _initialOptionsLoaded = true;
  }

  @override
  void dispose() {
    _spinController.dispose();
    _optionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addOption() {
    if (_isSpinning) return;

    final localizations = AppLocalizations.of(context);
    final option = _optionController.text.trim();
    if (option.isEmpty) {
      setState(() => _validationMessage = localizations.enterWheelOption);
      return;
    }

    final isDuplicate = _options.any(
      (existing) => existing.toLowerCase() == option.toLowerCase(),
    );
    if (isDuplicate) {
      setState(() => _validationMessage = localizations.duplicateWheelOption);
      return;
    }

    setState(() {
      _options.add(option);
      _optionController.clear();
      _selectedOption = null;
      _validationMessage = null;
    });
    FocusScope.of(context).unfocus();
  }

  void _removeOption(int index) {
    if (_isSpinning) return;

    setState(() {
      _options.removeAt(index);
      _selectedOption = null;
      _validationMessage = null;
    });
  }

  Future<void> _spin() async {
    if (_isSpinning) return;

    final localizations = AppLocalizations.of(context);
    if (_options.length < 2) {
      setState(() {
        _validationMessage = localizations.minimumWheelOptions;
        _selectedOption = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    final winnerIndex = _random.nextInt(_options.length);
    final sweep = math.pi * 2 / _options.length;
    final desiredRotation = _normalizeAngle(-(winnerIndex + 0.5) * sweep);
    final currentRotation = _normalizeAngle(_rotation);
    final alignmentRotation = _normalizeAngle(
      desiredRotation - currentRotation,
    );
    final endRotation =
        _rotation + (5 + _random.nextInt(3)) * math.pi * 2 + alignmentRotation;

    setState(() {
      _isSpinning = true;
      _selectedOption = null;
      _validationMessage = null;
      _rotationAnimation = Tween<double>(begin: _rotation, end: endRotation)
          .animate(
            CurvedAnimation(
              parent: _spinController,
              curve: Curves.easeOutCubic,
            ),
          );
    });

    await _spinController.forward(from: 0);
    if (!mounted) return;

    setState(() {
      _rotation = endRotation;
      _selectedOption = _options[winnerIndex];
      _isSpinning = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  double _normalizeAngle(double angle) {
    final fullTurn = math.pi * 2;
    return (angle % fullTurn + fullTurn) % fullTurn;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      bottomNavigationBar: const ThurayaBottomNavigationBar(
        selectedTab: ThurayaNavigationTab.wheel,
      ),
      body: SafeArea(
        key: const ValueKey('wheel-page'),
        bottom: false,
        child: SingleChildScrollView(
          key: const ValueKey('wheel-scroll-view'),
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizations.wheelHeroTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                localizations.wheelHeroSubtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.wheelSubtitle,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                key: const ValueKey('wheel-option-input'),
                controller: _optionController,
                enabled: !_isSpinning,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.right,
                maxLength: 40,
                onSubmitted: (_) => _addOption(),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: localizations.addWheelOption,
                  hintStyle: AppTextStyles.screenSubtitle.copyWith(
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  suffixIcon: IconButton(
                    key: const ValueKey('wheel-add-option'),
                    tooltip: localizations.addWheelOption,
                    onPressed: _isSpinning ? null : _addOption,
                    icon: const Icon(Icons.add_rounded),
                    color: AppColors.primary,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    borderSide: const BorderSide(color: AppColors.panelBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              if (_options.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  key: const ValueKey('wheel-options'),
                  alignment: WrapAlignment.start,
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (var index = 0; index < _options.length; index++)
                      InputChip(
                        key: ValueKey('wheel-option-$index'),
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 132),
                          child: Text(
                            _options[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        labelStyle: AppTextStyles.detailsAwardTitle,
                        deleteIcon: Icon(
                          Icons.close_rounded,
                          key: ValueKey('wheel-remove-$index'),
                          size: 16,
                        ),
                        deleteIconColor: AppColors.textSecondary,
                        onDeleted: _isSpinning
                            ? null
                            : () => _removeOption(index),
                        backgroundColor: AppColors.panel,
                        side: const BorderSide(color: AppColors.panelBorder),
                        shape: const StadiumBorder(),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              if (_validationMessage != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _validationMessage!,
                  key: const ValueKey('wheel-validation-message'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.detailsCaption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wheelSize = math.min(320.0, constraints.maxWidth);
                  return Center(
                    child: AnimatedBuilder(
                      animation: _spinController,
                      builder: (context, child) => DynamicWheel(
                        options: List.unmodifiable(_options),
                        rotation: _rotationAnimation?.value ?? _rotation,
                        size: wheelSize,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: SizedBox(
                  width: 280,
                  height: 48,
                  child: FilledButton.icon(
                    key: const ValueKey('wheel-spin-button'),
                    onPressed: _isSpinning ? null : _spin,
                    icon: _isSpinning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      localizations.spinWheel,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      disabledForegroundColor: AppColors.onPrimary,
                      elevation: 4,
                      shadowColor: const Color(0x331A237E),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ),
              if (_selectedOption != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  key: const ValueKey('wheel-result'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(AppSpacing.lg),
                    border: Border.all(color: AppColors.panelBorder),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000666),
                        offset: Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        localizations.yourWheelChoice,
                        style: AppTextStyles.detailsAwardTitle,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        _selectedOption!,
                        key: const ValueKey('wheel-result-value'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
