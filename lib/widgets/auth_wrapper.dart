import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';

/// Widget que controla o fluxo de autenticação
/// Mostra LoginScreen se não autenticado, HomeScreen se autenticado
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    debugPrint(
      '🔍 AuthWrapper - isLoading: ${authProvider.isLoading}, isAuthenticated: ${authProvider.isAuthenticated}',
    );

    // Mostra loading enquanto verifica autenticação
    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Mostra tela apropriada baseado no estado de autenticação
    return authProvider.isAuthenticated
        ? const HomeScreen()
        : const LoginScreen();
  }
}
