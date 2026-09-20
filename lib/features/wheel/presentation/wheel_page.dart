import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:thuraya/core/auth/authentication_guard.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/thuraya_bottom_navigation_bar.dart';
import 'package:thuraya/features/wheel/models/wheel_models.dart';
import 'package:thuraya/features/wheel/presentation/widgets/dynamic_wheel.dart';
import 'package:thuraya/features/wheel/presentation/wheel_controller.dart';
import 'package:thuraya/features/wheel/services/wheel_service.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class WheelPage extends StatefulWidget {
  const WheelPage({super.key, this.gateway});

  final WheelGateway? gateway;

  @override
  State<WheelPage> createState() => _WheelPageState();
}

class _WheelPageState extends State<WheelPage>
    with SingleTickerProviderStateMixin {
  final _optionController = TextEditingController();
  final _scrollController = ScrollController();

  late final WheelController _wheelController;
  late final AnimationController _spinController;
  Animation<double>? _rotationAnimation;
  double _rotation = 0;
  String? _selectedOption;
  String? _validationMessage;
  bool _initialized = false;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _wheelController = WheelController(gateway: widget.gateway)
      ..addListener(_handleWheelChanged);
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeWheel();
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _wheelController
      ..removeListener(_handleWheelChanged)
      ..dispose();
    _optionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleWheelChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initializeWheel() async {
    try {
      await AuthenticationGuard.requireAuthentication<void>(
        context,
        _wheelController.initialize,
      );
    } catch (_) {
      // The controller and the shared authentication flow expose retry UI.
    }
  }

  Future<void> _retryInitialization() async {
    await _initializeWheel();
  }

  Future<void> _removeOption(WheelOptionDto option) async {
    if (_isSpinning || _wheelController.isMutating) return;

    bool? removed;
    try {
      removed = await AuthenticationGuard.requireAuthentication<bool>(
        context,
        () => _wheelController.removeOption(option.id),
      );
    } catch (_) {
      return;
    }
    if (!mounted || removed != true) return;
    setState(() {
      _selectedOption = null;
      _validationMessage = null;
    });
  }

  Future<void> _addOption() async {
    if (_isSpinning || _wheelController.isMutating) return;

    final localizations = AppLocalizations.of(context);
    final option = _optionController.text.trim();
    if (option.isEmpty) {
      setState(() => _validationMessage = localizations.enterWheelOption);
      return;
    }

    final isDuplicate = _wheelController.activeOptions.any(
      (existing) => existing.text.toLowerCase() == option.toLowerCase(),
    );
    if (isDuplicate) {
      setState(() => _validationMessage = localizations.duplicateWheelOption);
      return;
    }

    bool? added;
    try {
      added = await AuthenticationGuard.requireAuthentication<bool>(
        context,
        () => _wheelController.addOption(option),
      );
    } catch (_) {
      return;
    }
    if (!mounted || added != true) return;
    setState(() {
      _optionController.clear();
      _selectedOption = null;
      _validationMessage = null;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _spin() async {
    if (_isSpinning || _wheelController.isMutating) return;

    final localizations = AppLocalizations.of(context);
    final options = _wheelController.activeOptions;
    if (options.length < 2) {
      setState(() {
        _validationMessage = localizations.minimumWheelOptions;
        _selectedOption = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSpinning = true;
      _selectedOption = null;
      _validationMessage = null;
    });
    WheelSpinSelection? selection;
    try {
      selection =
          await AuthenticationGuard.requireAuthentication<WheelSpinSelection?>(
            context,
            _wheelController.spin,
          );
    } catch (_) {
      if (mounted) setState(() => _isSpinning = false);
      return;
    }
    if (!mounted) return;
    if (selection == null) {
      setState(() => _isSpinning = false);
      return;
    }
    final resolvedSelection = selection;

    final winnerIndex = resolvedSelection.optionIndex;
    final sweep = math.pi * 2 / options.length;
    final desiredRotation = _normalizeAngle(-(winnerIndex + 0.5) * sweep);
    final currentRotation = _normalizeAngle(_rotation);
    final alignmentRotation = _normalizeAngle(
      desiredRotation - currentRotation,
    );
    final endRotation = _rotation + 6 * math.pi * 2 + alignmentRotation;

    setState(() {
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
      _selectedOption = resolvedSelection.result.selectedOption.text;
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

  String _errorMessage(AppLocalizations localizations) {
    return switch (_wheelController.error) {
      WheelErrorKind.badRequest => localizations.wheelBadRequestError,
      WheelErrorKind.forbidden => localizations.wheelForbiddenError,
      WheelErrorKind.notFound => localizations.wheelNotFoundError,
      WheelErrorKind.invalidResponse => localizations.wheelInvalidResponseError,
      _ => localizations.wheelNetworkError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final options = _wheelController.activeOptions;
    final controlsEnabled =
        _wheelController.status == WheelLoadStatus.ready &&
        !_isSpinning &&
        !_wheelController.isMutating;

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
                enabled: controlsEnabled,
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
                    onPressed: controlsEnabled ? _addOption : null,
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
              if (_wheelController.status == WheelLoadStatus.loading) ...[
                const SizedBox(height: AppSpacing.sm),
                const LinearProgressIndicator(
                  key: ValueKey('wheel-loading'),
                  color: AppColors.primary,
                ),
              ],
              if (_wheelController.status == WheelLoadStatus.error) ...[
                const SizedBox(height: AppSpacing.sm),
                _WheelError(
                  message: _errorMessage(localizations),
                  retryLabel: localizations.retry,
                  onRetry: _retryInitialization,
                ),
              ] else if (_wheelController.error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _WheelError(
                  message: _errorMessage(localizations),
                  retryLabel: null,
                  onRetry: null,
                ),
              ],
              if (options.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  key: const ValueKey('wheel-options'),
                  alignment: WrapAlignment.start,
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final option in options)
                      InputChip(
                        key: ValueKey('wheel-option-${option.id}'),
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 132),
                          child: Text(
                            option.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        labelStyle: AppTextStyles.detailsAwardTitle,
                        backgroundColor: AppColors.panel,
                        side: const BorderSide(color: AppColors.panelBorder),
                        shape: const StadiumBorder(),
                        visualDensity: VisualDensity.compact,
                        deleteIcon: const Icon(Icons.close_rounded, size: 18),
                        deleteButtonTooltipMessage:
                            localizations.removeWheelOption,
                        onDeleted: controlsEnabled
                            ? () => _removeOption(option)
                            : null,
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
              if (options.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Text(
                    localizations.wheelEmptyState,
                    key: const ValueKey('wheel-empty-state'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wheelSize = math.min(320.0, constraints.maxWidth);
                    return Center(
                      child: AnimatedBuilder(
                        animation: _spinController,
                        builder: (context, child) => DynamicWheel(
                          options: options
                              .map((option) => option.text)
                              .toList(growable: false),
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
                    onPressed: controlsEnabled ? _spin : null,
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

class _WheelError extends StatelessWidget {
  const _WheelError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('wheel-error'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.detailsCaption.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (retryLabel != null && onRetry != null) ...[
          const SizedBox(width: AppSpacing.xs),
          TextButton(onPressed: onRetry, child: Text(retryLabel!)),
        ],
      ],
    );
  }
}
