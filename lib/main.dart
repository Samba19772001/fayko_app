import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FaykoApp());
}

class FaykoApp extends StatelessWidget {
  const FaykoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..chargerSessionExistante(),
      child: MaterialApp(
        title: 'Fayko',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF1E3A5F),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Décide quel écran afficher au démarrage : connexion si personne n'est
/// authentifié, accueil sinon.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isAuthenticated) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}