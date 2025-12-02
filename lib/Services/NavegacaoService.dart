import 'package:flutter/material.dart';

/// Classe Singleton para gerenciar a navegação sem BuildContext
class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    final currentState = navigatorKey.currentState;
    if (currentState == null) return Future.value(null);
    return currentState.pushNamed(routeName, arguments: arguments);
  }

  void goBack({Object? result}) {
    final currentState = navigatorKey.currentState;
    if (currentState != null && currentState.canPop()) {
      currentState.pop(result);
    }
  }

  Future<dynamic> navigateToAndRemoveAll(String routeName, {Object? arguments}) {
    final currentState = navigatorKey.currentState;
    if (currentState == null) return Future.value(null);

    return currentState.pushNamedAndRemoveUntil(
      routeName,
          (Route<dynamic> route) => false, // Remove tudo!
      arguments: arguments,
    );
  }
}
