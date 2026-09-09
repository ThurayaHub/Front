import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/core/theme/app_theme.dart';
import 'package:thuraya/features/restaurant_reviews/presentation/create_restaurant_review_sheet.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('requires a whole-star rating and a non-empty comment', (
    tester,
  ) async {
    int? submittedStars;
    String? submittedComment;
    await tester.pumpWidget(
      _testApp((stars, comment) async {
        submittedStars = stars;
        submittedComment = comment;
      }),
    );

    final submit = find.byKey(const ValueKey('review-submit-button'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('review-star-4')));
    await tester.pump();
    expect(find.text('جيد جداً'), findsOneWidget);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('review-comment-field')),
      '  تجربة جميلة  ',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(submittedStars, 4);
    expect(submittedComment, '  تجربة جميلة  ');
  });

  testWidgets('keeps form state and shows a friendly duplicate error', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp((_, _) async {
        throw const ApiException('raw server error', statusCode: 409);
      }),
    );

    await tester.tap(find.byKey(const ValueKey('review-star-5')));
    await tester.enterText(
      find.byKey(const ValueKey('review-comment-field')),
      'مطعم رائع',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('review-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('سبق أن أضفت مراجعة لهذا المطعم.'), findsOneWidget);
    expect(find.text('raw server error'), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('review-comment-field')))
          .controller
          ?.text,
      'مطعم رائع',
    );
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
  });
}

Widget _testApp(SubmitRestaurantReview onSubmit) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: AppTheme.light,
    home: Scaffold(
      body: CreateRestaurantReviewSheet(
        restaurantName: 'مائدة الرياض',
        onSubmit: onSubmit,
      ),
    ),
  );
}
