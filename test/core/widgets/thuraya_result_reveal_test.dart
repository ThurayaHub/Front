import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/widgets/thuraya_logo.dart';
import 'package:thuraya/core/widgets/thuraya_result_reveal.dart';

void main() {
  testWidgets(
    'data arriving early preserves the 450ms logo and 350ms entrance',
    (tester) async {
      final ready = ValueNotifier(false);
      addTearDown(ready.dispose);
      var revealed = 0;
      await tester.pumpWidget(_app(ready, onRevealed: () => revealed++));
      await tester.pump(const Duration(milliseconds: 100));
      ready.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 349));
      expect(_opacity(tester), 0);
      await tester.pump(const Duration(milliseconds: 176));
      expect(_opacity(tester), inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 175));
      expect(_opacity(tester), 1);
      // Status callbacks complete on a display frame, after the final fade.
      await tester.pump(const Duration(milliseconds: 16));
      expect(revealed, 1);
      await tester.pumpWidget(_app(ready, onRevealed: () => revealed++));
      await tester.pump();
      expect(revealed, 1);
      expect(find.byKey(const ValueKey('thuraya-reveal-logo')), findsNothing);
    },
  );

  testWidgets(
    'pending data holds the logo, then resumes the same result transition',
    (tester) async {
      final ready = ValueNotifier(false);
      addTearDown(ready.dispose);
      await tester.pumpWidget(_app(ready));
      await tester.pump(const Duration(milliseconds: 600));
      expect(_opacity(tester), 0);
      expect(find.byKey(const ValueKey('thuraya-reveal-logo')), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Confirmed result'), findsNothing);
      await tester.pump(const Duration(seconds: 4));
      expect(_opacity(tester), 0);
      ready.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 175));
      expect(_opacity(tester), inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 175));
      expect(_opacity(tester), 1);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Confirmed result'), findsOneWidget);
    },
  );

  testWidgets(
    'loading fits a short landscape viewport without clipping the logo',
    (tester) async {
      final ready = ValueNotifier(false);
      addTearDown(ready.dispose);
      await tester.pumpWidget(_app(ready, height: 180));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      final logo = tester.getRect(
        find.byKey(const ValueKey('thuraya-reveal-logo')),
      );
      final card = tester.getRect(find.byType(ThurayaResultReveal));
      expect(card.contains(logo.topLeft), isTrue);
      expect(card.contains(logo.bottomRight), isTrue);
      ready.value = true;
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'reduced motion waits for data without animating or revealing early',
    (tester) async {
      final ready = ValueNotifier(false);
      addTearDown(ready.dispose);
      await tester.pumpWidget(_app(ready, reduceMotion: true));
      expect(_opacity(tester), 0);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Confirmed result'), findsNothing);
      expect(find.byType(ThurayaLogo), findsOneWidget);
      ready.value = true;
      await tester.pump();
      expect(_opacity(tester), 1);
      expect(find.byKey(const ValueKey('thuraya-reveal-logo')), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    },
  );
}

double _opacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find.byKey(const ValueKey('thuraya-result-entrance')),
    )
    .opacity
    .value;

Widget _app(
  ValueNotifier<bool> ready, {
  bool reduceMotion = false,
  double height = 400,
  VoidCallback? onRevealed,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 360,
        height: height,
        child: ValueListenableBuilder<bool>(
          valueListenable: ready,
          builder: (context, isReady, _) => ThurayaResultReveal(
            isReady: isReady,
            loadingMessage: 'Choosing a restaurant',
            onRevealed: onRevealed,
            child: isReady ? const Text('Confirmed result') : null,
          ),
        ),
      ),
    ),
  ),
);
