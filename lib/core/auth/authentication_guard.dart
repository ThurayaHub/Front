import 'package:flutter/widgets.dart';
import 'package:thuraya/core/auth/auth_scope.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/core/routing/app_route_names.dart';

abstract final class AuthenticationGuard {
  static Future<T?> requireAuthentication<T>(
    BuildContext context,
    Future<T> Function() action,
  ) async {
    var promptedForLogin = false;
    final authController = AuthScope.read(context);

    if (!authController.isAuthenticated) {
      promptedForLogin = true;
      final loggedIn = await Navigator.of(
        context,
      ).pushNamed(AppRouteNames.login);
      if (loggedIn != true || !context.mounted) {
        return null;
      }
      if (!AuthScope.read(context).isAuthenticated) {
        return null;
      }
    }

    try {
      return await action();
    } on AuthenticationRequiredException {
      if (promptedForLogin || !context.mounted) {
        rethrow;
      }

      final loggedIn = await Navigator.of(
        context,
      ).pushNamed(AppRouteNames.login);
      if (loggedIn != true || !context.mounted) {
        return null;
      }
      if (!AuthScope.read(context).isAuthenticated) {
        return null;
      }
      return action();
    }
  }
}
