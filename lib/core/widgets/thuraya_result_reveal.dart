import 'package:flutter/material.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/widgets/thuraya_logo.dart';

/// Shared Wheel/Choose reveal: 450ms logo, then a 350ms result entrance.
/// If data is pending, pause at the logo and resume when [isReady] becomes true.
/// Give each new request a new key; rebuilds keep the current reveal progress.
class ThurayaResultReveal extends StatefulWidget {
  const ThurayaResultReveal({
    super.key,
    required this.isReady,
    this.child,
    this.loadingMessage,
    this.onRevealed,
    this.logoKey = const ValueKey('thuraya-reveal-logo'),
    this.entranceKey = const ValueKey('thuraya-result-entrance'),
  }) : assert(!isReady || child != null);

  final bool isReady;
  final Widget? child;
  final String? loadingMessage;
  final VoidCallback? onRevealed;
  final Key logoKey;
  final Key entranceKey;

  static const duration = Duration(milliseconds: 800);
  static const logoDuration = Duration(milliseconds: 450);
  static const _pause = 0.5625;

  static ButtonStyle primaryActionStyle() => FilledButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    minimumSize: const Size.fromHeight(48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  static ButtonStyle secondaryActionStyle() => TextButton.styleFrom(
    foregroundColor: AppColors.textSecondary,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    minimumSize: const Size.fromHeight(48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  @override
  State<ThurayaResultReveal> createState() => _ThurayaResultRevealState();
}

class _ThurayaResultRevealState extends State<ThurayaResultReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ThurayaResultReveal.duration,
  )..addStatusListener(_onStatus);
  late final Animation<double> _surfaceOpacity = _controller.drive(
    CurveTween(curve: const Interval(0, 0.2, curve: Curves.easeOut)),
  );
  late final Animation<double> _logoEntrance = _controller.drive(
    CurveTween(
      curve: const Interval(
        0,
        ThurayaResultReveal._pause,
        curve: Curves.easeOutCubic,
      ),
    ),
  );
  late final Animation<double> _logoExit = _controller.drive(
    CurveTween(
      curve: const Interval(
        ThurayaResultReveal._pause,
        0.8125,
        curve: Curves.easeInOut,
      ),
    ),
  );
  late final Animation<double> _resultEntrance = _controller.drive(
    CurveTween(
      curve: const Interval(
        ThurayaResultReveal._pause,
        1,
        curve: Curves.easeOutCubic,
      ),
    ),
  );
  late final Animation<Offset> _resultSlide = _resultEntrance.drive(
    Tween(begin: const Offset(0, 0.035), end: Offset.zero),
  );
  bool _started = false;
  bool _notified = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (_reduceMotion) {
      _started = true;
      _controller.value = widget.isReady ? 1 : ThurayaResultReveal._pause;
    } else if (!_started) {
      _started = true;
      if (widget.isReady) {
        _controller.forward();
      } else {
        _controller.animateTo(
          ThurayaResultReveal._pause,
          duration: ThurayaResultReveal.logoDuration,
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant ThurayaResultReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReady && !oldWidget.isReady) {
      if (_reduceMotion) {
        _controller.value = 1;
      } else {
        // Continue from the current time, without restarting the logo phase.
        _controller.forward();
      }
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        _controller.value < 1 ||
        !widget.isReady ||
        _notified) {
      return;
    }
    _notified = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onRevealed?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _surfaceOpacity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000666),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _controller,
        child:
            widget.child ?? const SizedBox(width: double.infinity, height: 280),
        builder: (context, result) {
          final ready = widget.isReady && _controller.value >= 1;
          final waiting =
              !widget.isReady &&
              _controller.value >= ThurayaResultReveal._pause;
          final logoOpacity = _logoEntrance.value * (1 - _logoExit.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: IgnorePointer(
                    ignoring: !ready,
                    child: ExcludeFocus(
                      excluding: !ready,
                      child: ExcludeSemantics(
                        excluding: !ready,
                        child: FadeTransition(
                          key: widget.entranceKey,
                          opacity: _resultEntrance,
                          child: SlideTransition(
                            position: _resultSlide,
                            child: Semantics(liveRegion: true, child: result),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!ready && logoOpacity > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Opacity(
                        opacity: logoOpacity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: ExcludeSemantics(
                                  child: Transform.scale(
                                    scale: 0.96 + 0.04 * _logoEntrance.value,
                                    child: SizedBox.square(
                                      dimension: 144,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Transform.scale(
                                            scale:
                                                1 + 0.05 * _logoEntrance.value,
                                            child: Container(
                                              width: 138,
                                              height: 138,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppColors.secondary
                                                      .withValues(alpha: 0.18),
                                                  width: 0.75,
                                                ),
                                              ),
                                            ),
                                          ),
                                          ThurayaLogo(
                                            key: widget.logoKey,
                                            width: 108,
                                            height: 108,
                                            semanticLabel: null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (widget.loadingMessage != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  16,
                                  24,
                                  0,
                                ),
                                child: AnimatedOpacity(
                                  opacity: waiting ? 1 : 0,
                                  duration: _reduceMotion
                                      ? Duration.zero
                                      : const Duration(milliseconds: 150),
                                  child: ExcludeSemantics(
                                    excluding: !waiting,
                                    child: Semantics(
                                      liveRegion: true,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (waiting && !_reduceMotion)
                                            const SizedBox(
                                              width: 80,
                                              child: LinearProgressIndicator(
                                                minHeight: 2,
                                                color: AppColors.primary,
                                                backgroundColor:
                                                    AppColors.background,
                                              ),
                                            ),
                                          const SizedBox(height: 12),
                                          Text(
                                            widget.loadingMessage!,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: AppColors.textMuted,
                                                ),
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
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
