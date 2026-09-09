import 'package:flutter/material.dart';
import 'package:thuraya/app.dart';
import 'package:thuraya/core/auth/auth_session_controller.dart';
import 'package:thuraya/core/network/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authController = AuthSessionController.instance;
  ApiClient.defaultAuthorizationDelegate = authController;
  final sessionRestoration = authController.restoreSession();
  runApp(ThurayaApp(authController: authController));
  await sessionRestoration;
}
