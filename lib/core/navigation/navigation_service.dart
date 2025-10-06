import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  BuildContext? get context => navigatorKey.currentContext;

  Future<T?> pushNamed<T>(String routeName, {Object? extra}) {
    return context!.pushNamed(routeName, extra: extra);
  }

  void pop<T>([T? result]) {
    context!.pop(result);
  }

  Future<dynamic> pushReplacementNamed<T>(
    String routeName, {
    Object? extra,
  }) async {
    return context!.pushReplacementNamed(routeName, extra: extra);
  }

  void goNamed(String routeName, {Object? extra}) {
    context!.goNamed(routeName, extra: extra);
  }
}
