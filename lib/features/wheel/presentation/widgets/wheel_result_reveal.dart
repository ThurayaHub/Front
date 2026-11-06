import 'package:flutter/material.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/thuraya_logo.dart';
import 'package:thuraya/core/widgets/thuraya_result_reveal.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

enum WheelResultAction { dismiss, spinAgain }

/// Wheel-specific content and actions; animation is shared with Choose.
class WheelResultReveal extends StatefulWidget {
  const WheelResultReveal({super.key, required this.result});
  final String result;
  static const duration = ThurayaResultReveal.duration;

  @override
  State<WheelResultReveal> createState() => _WheelResultRevealState();
}

class _WheelResultRevealState extends State<WheelResultReveal> {
  bool _closing = false;
  bool _revealed = false;

  void _finish(WheelResultAction action) {
    if (_closing || !_revealed) return;
    _closing = true;
    Navigator.of(context).pop(action);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      key: const ValueKey('wheel-result-reveal'),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 400),
      child: ThurayaResultReveal(
        isReady: true,
        logoKey: const ValueKey('wheel-reveal-logo'),
        entranceKey: const ValueKey('wheel-result-entrance'),
        onRevealed: () => _revealed = true,
        child: Column(
          key: const ValueKey('wheel-result'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: ThurayaLogo(width: 44, height: 44, semanticLabel: null),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.yourWheelChoice,
              textAlign: TextAlign.center,
              style: AppTextStyles.screenSubtitle.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.result,
              key: const ValueKey('wheel-result-value'),
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitle.copyWith(
                fontSize: 28,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              key: const ValueKey('wheel-result-spin-again'),
              onPressed: () => _finish(WheelResultAction.spinAgain),
              style: ThurayaResultReveal.primaryActionStyle(),
              child: Text(l10n.wheelSpinAgain, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('wheel-result-dismiss'),
              onPressed: () => _finish(WheelResultAction.dismiss),
              style: ThurayaResultReveal.secondaryActionStyle(),
              child: Text(l10n.wheelDismissResult),
            ),
          ],
        ),
      ),
    );
  }
}
