import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/widgets/thuraya_loading_indicator.dart';
import 'package:thuraya/core/widgets/thuraya_logo.dart';
import 'package:thuraya/features/startup/presentation/thuraya_startup_screen.dart';

void main() {
  testWidgets('ThurayaLogo uses the shared official branding asset', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ThurayaLogo(width: 120))),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, AppAssets.thurayaLogo);
    expect(image.fit, BoxFit.contain);
    expect(image.width, 120);
  });

  testWidgets('loading indicator uses subtle fade and scale transitions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ThurayaLoadingIndicator())),
    );

    final indicator = find.byType(ThurayaLoadingIndicator);
    final fadeTransition = find.descendant(
      of: indicator,
      matching: find.byType(FadeTransition),
    );
    final scaleTransition = find.descendant(
      of: indicator,
      matching: find.byType(ScaleTransition),
    );

    expect(fadeTransition, findsOneWidget);
    expect(scaleTransition, findsOneWidget);
    expect(find.byType(ThurayaLogo), findsOneWidget);

    final initialScale = tester
        .widget<ScaleTransition>(scaleTransition)
        .scale
        .value;
    await tester.pump(const Duration(milliseconds: 900));
    final animatedScale = tester
        .widget<ScaleTransition>(scaleTransition)
        .scale
        .value;

    expect(animatedScale, greaterThan(initialScale));
  });

  testWidgets('loading indicator respects reduced-motion preferences', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: ThurayaLoadingIndicator()),
        ),
      ),
    );

    final indicator = find.byType(ThurayaLoadingIndicator);
    expect(find.byType(ThurayaLogo), findsOneWidget);
    expect(
      find.descendant(of: indicator, matching: find.byType(FadeTransition)),
      findsNothing,
    );
    expect(
      find.descendant(of: indicator, matching: find.byType(ScaleTransition)),
      findsNothing,
    );
  });

  testWidgets('startup screen uses the branded full-page presentation', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ThurayaStartupScreen()));

    final scaffold = tester.widget<Scaffold>(
      find.byKey(const ValueKey('thuraya-startup-screen')),
    );
    expect(scaffold.backgroundColor, AppColors.background);
    expect(find.byType(ThurayaLoadingIndicator), findsOneWidget);
  });
}
