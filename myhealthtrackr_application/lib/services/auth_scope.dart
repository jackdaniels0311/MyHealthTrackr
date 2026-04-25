import 'package:flutter/widgets.dart';
import 'package:myhealthtrackr/services/auth_controller.dart';

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<AuthScope>();
    final scope = element?.widget as AuthScope?;
    assert(scope != null, 'AuthScope is missing from the widget tree.');
    return scope!.notifier!;
  }

  static AuthController watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope is missing from the widget tree.');
    return scope!.notifier!;
  }
}
