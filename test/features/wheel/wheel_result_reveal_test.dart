import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_theme.dart';
import 'package:thuraya/core/widgets/thuraya_logo.dart';
import 'package:thuraya/features/wheel/presentation/widgets/wheel_result_reveal.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final fonts = FontLoader('Tajawal')
      ..addFont(rootBundle.load('assets/fonts/Tajawal-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Tajawal-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Tajawal-Bold.ttf'));
    await fonts.load();
  });

  testWidgets(
    'actual logo precedes a 350ms result entrance and the result stays visible',
    (tester) async {
      _screen(tester, const Size(390, 844));
      await tester.pumpWidget(_app());
      // WheelPage preloads this exact asset before the existing spin. Match
      // that warm-cache path when rendering individual reveal frames here.
      await tester.runAsync(
        () => precacheImage(
          const AssetImage(AppAssets.thurayaLogo),
          tester.element(find.byKey(const ValueKey('open-reveal'))),
        ),
      );
      final originalShadows = debugDisableShadows;
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = originalShadows);
      await tester.tap(find.byKey(const ValueKey('open-reveal')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 225));

      expect(find.byKey(const ValueKey('wheel-reveal-logo')), findsOneWidget);
      expect(_resultOpacity(tester), 0);
      final logo = tester.widget<Image>(
        find.descendant(
          of: find.byKey(const ValueKey('wheel-reveal-logo')),
          matching: find.byType(Image),
        ),
      );
      expect((logo.image as AssetImage).assetName, AppAssets.thurayaLogo);
      await _capture(tester, 'logo');

      await tester.pump(const Duration(milliseconds: 225));
      expect(_resultOpacity(tester), 0);
      await tester.pump(const Duration(milliseconds: 175));
      expect(_resultOpacity(tester), inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 175));
      expect(_resultOpacity(tester), 1);
      expect(find.byKey(const ValueKey('wheel-reveal-logo')), findsNothing);
      expect(find.byType(ThurayaLogo), findsOneWidget);
      expect(find.text('مقهى ثريا'), findsOneWidget);
      await _capture(tester, 'result');
      debugDisableShadows = originalShadows;

      await tester.pump(const Duration(seconds: 15));
      expect(_resultOpacity(tester), 1);
      expect(find.byKey(const ValueKey('wheel-result')), findsOneWidget);
      // An inherited layout update must not replay the reveal.
      tester.view.physicalSize = const Size(420, 844);
      await tester.pump();
      expect(_resultOpacity(tester), 1);
      await tester.tap(find.byKey(const ValueKey('wheel-result-dismiss')));
      await tester.pumpAndSettle();
      expect(find.byType(WheelResultReveal), findsNothing);
    },
  );

  for (final navigation in [false, true]) {
    testWidgets(
      'reduced motion skips the reveal (${navigation ? 'accessible navigation' : 'disabled animations'})',
      (tester) async {
        await tester.pumpWidget(
          _app(
            disableAnimations: !navigation,
            accessibleNavigation: navigation,
          ),
        );
        await tester.tap(find.byKey(const ValueKey('open-reveal')));
        await tester.pump();
        expect(_resultOpacity(tester), 1);
        expect(find.byKey(const ValueKey('wheel-reveal-logo')), findsNothing);
        final entrance = tester.widget<SlideTransition>(
          find.descendant(
            of: find.byKey(const ValueKey('wheel-result-entrance')),
            matching: find.byType(SlideTransition),
          ),
        );
        expect(entrance.position.value, Offset.zero);
        expect(find.byType(ThurayaLogo), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('wheel-result-dismiss')));
        await tester.pumpAndSettle();
      },
    );
  }

  for (final locale in ['ar', 'en']) {
    testWidgets(
      'long names and large text remain readable on a small $locale screen',
      (tester) async {
        _screen(tester, const Size(320, 480));
        const name = 'Thuraya Restaurant & Specialty Coffee · مطعم ومقهى ثريا';
        await tester.pumpWidget(
          _app(
            locale: locale,
            result: name,
            textScale: 2,
            disableAnimations: true,
          ),
        );
        await tester.tap(find.byKey(const ValueKey('open-reveal')));
        await tester.pumpAndSettle();
        final result = find.byKey(const ValueKey('wheel-result-value'));
        expect(tester.widget<Text>(result).data, name);
        expect(tester.widget<Text>(result).maxLines, isNull);
        expect(
          Directionality.of(tester.element(result)),
          locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(tester.takeException(), isNull);
        final dismiss = find.byKey(const ValueKey('wheel-result-dismiss'));
        await tester.ensureVisible(dismiss);
        await tester.pumpAndSettle();
        await tester.tap(dismiss);
        await tester.pumpAndSettle();
        expect(find.byType(WheelResultReveal), findsNothing);
      },
    );
  }

  testWidgets('disposing during the reveal cancels its ticker cleanly', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byKey(const ValueKey('open-reveal')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}

double _resultOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(find.byKey(const ValueKey('wheel-result-entrance')))
    .opacity
    .value;

void _screen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app({
  String locale = 'ar',
  String result = 'مقهى ثريا',
  bool disableAnimations = false,
  bool accessibleNavigation = false,
  double textScale = 1,
}) => RepaintBoundary(
  key: const ValueKey('reveal-preview'),
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: Locale(locale),
    theme: AppTheme.light,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: disableAnimations,
        accessibleNavigation: accessibleNavigation,
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: TextButton(
            key: const ValueKey('open-reveal'),
            onPressed: () => showDialog<WheelResultAction>(
              context: context,
              animationStyle: AnimationStyle.noAnimation,
              barrierColor: AppColors.primary.withValues(alpha: 0.18),
              builder: (_) => WheelResultReveal(result: result),
            ),
            child: const Text(''),
          ),
        ),
      ),
    ),
  ),
);

// Optional real-font renders for visual review; normal test runs write no files.
Future<void> _capture(WidgetTester tester, String stage) async {
  if (!const bool.fromEnvironment('WRITE_WHEEL_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('reveal-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '.dart_tool/wheel_reveal_$stage.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
