import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/widgets/thuraya_star_badge.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('stays hidden when the restaurant has no Thuraya Star', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const ThurayaStarBadge(
          hasThurayaStar: false,
          variant: ThurayaStarBadgeVariant.full,
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.text('Thuraya Star'), findsNothing);
  });

  testWidgets('uses the branded image and localized label', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const ThurayaStarBadge(
          hasThurayaStar: true,
          size: 30,
          variant: ThurayaStarBadgeVariant.full,
        ),
      ),
    );
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, AppAssets.thurayaStar);
    expect(image.width, 30);
    expect(image.height, 30);
    expect(find.text('Thuraya Star'), findsOneWidget);
  });

  testWidgets('supports icon-only and optional interaction', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _testApp(
        ThurayaStarBadge(
          key: const ValueKey('star-award'),
          hasThurayaStar: true,
          showLabel: false,
          variant: ThurayaStarBadgeVariant.iconOnly,
          onTap: () => taps++,
        ),
      ),
    );

    expect(find.text('Thuraya Star'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('star-award')));
    expect(taps, 1);
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: Center(child: child)),
  );
}
