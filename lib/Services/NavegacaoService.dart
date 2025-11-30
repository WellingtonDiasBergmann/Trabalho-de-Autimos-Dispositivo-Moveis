import 'package:flutter/material.dart';

/// Classe Singleton para gerenciar a navegação sem BuildContext
class NavigationService {
  // 🔑 Chave do Navigator — deve ser usada em MaterialApp
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // 🔒 Singleton
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  /// 🚀 Navega para uma rota nomeada
  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    final currentState = navigatorKey.currentState;
    if (currentState == null) return Future.value(null);
    return currentState.pushNamed(routeName, arguments: arguments);
  }

  /// ⬅️ Voltar para a rota anterior
  void goBack({Object? result}) {
    final currentState = navigatorKey.currentState;
    if (currentState != null && currentState.canPop()) {
      currentState.pop(result);
    }
  }

  /// 🚫 Apaga TODAS as rotas anteriores e vai para uma nova
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
