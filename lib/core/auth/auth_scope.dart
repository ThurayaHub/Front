import 'package:flutter/widgets.dart';
import 'package:thuraya/core/auth/auth_session_controller.dart';

class AuthScope extends InheritedNotifier<AuthSessionController> {
  const AuthScope({
    super.key,
    required AuthSessionController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthSessionController watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No AuthScope found above this context.');
    return scope!.notifier!;
  }

  static AuthSessionController read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<AuthScope>();
    final scope = element?.widget as AuthScope?;
    assert(scope != null, 'No AuthScope found above this context.');
    return scope!.notifier!;
  }
}
