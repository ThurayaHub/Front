import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/routing/app_router.dart';
import 'package:thuraya/core/theme/app_theme.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class ThurayaApp extends StatelessWidget {
  const ThurayaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      initialRoute: AppRouteNames.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
