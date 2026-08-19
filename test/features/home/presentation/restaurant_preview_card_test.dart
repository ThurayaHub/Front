import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_preview_card.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('preview shows only available map DTO information and opens', (
    tester,
  ) async {
    var openCount = 0;

    await tester.pumpWidget(
      _testApp(
        RestaurantPreviewCard(
          restaurant: _restaurant,
          onTap: () => openCount++,
          onClose: () {},
        ),
      ),
    );

    expect(find.text(_restaurant.name), findsOneWidget);
    expect(find.text('Asian'), findsOneWidget);
    expect(find.text(r'$$'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('8 تقييم'), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('restaurant-preview-card')));
    await tester.pump();

    expect(openCount, 1);
  });

  testWidgets('preview close action dismisses the selected restaurant', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const _PreviewHarness()));

    expect(
      find.byKey(const ValueKey('restaurant-preview-card')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('restaurant-preview-close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('restaurant-preview-card')), findsNothing);
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: Center(child: SizedBox(width: 350, child: child)),
    ),
  );
}

class _PreviewHarness extends StatefulWidget {
  const _PreviewHarness();

  @override
  State<_PreviewHarness> createState() => _PreviewHarnessState();
}

class _PreviewHarnessState extends State<_PreviewHarness> {
  RestaurantMapMarker? _selectedRestaurant = _restaurant;

  @override
  Widget build(BuildContext context) {
    final selectedRestaurant = _selectedRestaurant;
    if (selectedRestaurant == null) {
      return const SizedBox.shrink();
    }

    return RestaurantPreviewCard(
      restaurant: selectedRestaurant,
      onTap: () {},
      onClose: () => setState(() => _selectedRestaurant = null),
    );
  }
}

const RestaurantMapMarker _restaurant = RestaurantMapMarker(
  id: 42,
  name: 'مطعم تجريبي باسم عربي طويل لاختبار المساحة',
  latitude: 24.7136,
  longitude: 46.6753,
  priceLevelId: 2,
  hasThurayaStar: true,
  userRatingAverage: 9,
  reviewCount: 8,
  mainPhotoUrl: null,
  primaryCategoryId: 2,
  primaryCategoryName: 'Asian',
);
