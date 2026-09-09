import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:thuraya/core/auth/auth_scope.dart';
import 'package:thuraya/core/auth/auth_session_controller.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/routing/app_router.dart';
import 'package:thuraya/core/theme/app_theme.dart';
import 'package:thuraya/features/startup/presentation/thuraya_startup_screen.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class ThurayaApp extends StatelessWidget {
  const ThurayaApp({super.key, this.authController});

  final AuthSessionController? authController;

  @override
  Widget build(BuildContext context) {
    final controller = authController ?? AuthSessionController.instance;
    return AuthScope(
      controller: controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: AppTheme.light,
        locale: const Locale('ar'),
        initialRoute: AppRouteNames.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
        builder: (context, child) {
          final auth = AuthScope.watch(context);
          return auth.isRestoring
              ? const ThurayaStartupScreen()
              : child ?? const SizedBox.shrink();
        },
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
