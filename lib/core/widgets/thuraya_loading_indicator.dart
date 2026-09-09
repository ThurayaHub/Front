import 'package:flutter/material.dart';
import 'package:thuraya/core/widgets/thuraya_logo.dart';

class ThurayaLoadingIndicator extends StatefulWidget {
  const ThurayaLoadingIndicator({
    super.key,
    this.size = 152,
    this.semanticLabel = 'جارٍ التحميل',
  }) : assert(size > 0);

  final double size;
  final String semanticLabel;

  @override
  State<ThurayaLoadingIndicator> createState() =>
      _ThurayaLoadingIndicatorState();
}

class _ThurayaLoadingIndicatorState extends State<ThurayaLoadingIndicator>
    with SingleTickerProviderStateMixin {
  static const Duration _animationDuration = Duration(milliseconds: 1800);

  late final AnimationController _controller;
  late final Animation<double> _breathingCurve;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  bool _animationsDisabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _breathingCurve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _opacity = Tween<double>(begin: 0.76, end: 1).animate(_breathingCurve);
    _scale = Tween<double>(begin: 0.965, end: 1).animate(_breathingCurve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (animationsDisabled == _animationsDisabled &&
        (_controller.isAnimating || animationsDisabled)) {
      return;
    }

    _animationsDisabled = animationsDisabled;
    if (_animationsDisabled) {
      _controller.stop();
      _controller.value = 1;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logo = SizedBox.square(
      dimension: widget.size,
      child: const ThurayaLogo(semanticLabel: null),
    );

    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      child: RepaintBoundary(
        child: _animationsDisabled
            ? logo
            : FadeTransition(
                opacity: _opacity,
                child: ScaleTransition(scale: _scale, child: logo),
              ),
      ),
    );
  }
}
