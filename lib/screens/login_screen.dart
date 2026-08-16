import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

/// Écran de connexion en deux étapes (§3.1) : numéro de téléphone, puis
/// code OTP reçu par SMS.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _telephoneController = TextEditingController(text: '77');
  final _codeController = TextEditingController();

  bool _codeEnvoye = false;
  String? _erreur;

  static const _indigo = Color(0xFF1E3A5F);
  static const _gold = Color(0xFFB98B3E);

  @override
  void dispose() {
    _telephoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _demanderCode() async {
    setState(() => _erreur = null);
    final auth = context.read<AuthProvider>();
    try {
      await auth.demanderCode(_telephoneController.text.trim());
      setState(() => _codeEnvoye = true);
    } on ApiException catch (e) {
      setState(() => _erreur = e.message);
    } catch (_) {
      setState(
        () => _erreur =
            "Impossible de contacter le serveur. Vérifiez votre connexion.",
      );
    }
  }

  Future<void> _verifierCode() async {
    setState(() => _erreur = null);
    final auth = context.read<AuthProvider>();
    try {
      await auth.verifierCode(
        _telephoneController.text.trim(),
        _codeController.text.trim(),
      );
      // Pas de navigation manuelle nécessaire : AuthGate dans main.dart
      // bascule automatiquement vers HomeScreen dès que isAuthenticated
      // devient vrai, grâce à notifyListeners().
    } on ApiException catch (e) {
      setState(() => _erreur = e.message);
    } catch (_) {
      setState(
        () => _erreur =
            "Impossible de contacter le serveur. Vérifiez votre connexion.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Center(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: _indigo,
                      fontFamily: 'serif',
                    ),
                    children: [
                      TextSpan(text: 'Fayko'),
                      TextSpan(
                        text: '.',
                        style: TextStyle(color: _gold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Formalisez vos prêts entre particuliers en contrats numériques opposables, en toute confiance.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              if (!_codeEnvoye)
                ..._buildEtapeTelephone(auth)
              else
                ..._buildEtapeCode(auth),
              if (_erreur != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E4E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _erreur!,
                    style: const TextStyle(
                      color: Color(0xFFA6402F),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEtapeTelephone(AuthProvider auth) {
    return [
      const Text(
        'Numéro de téléphone',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: _telephoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          hintText: '77 000 00 00',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: auth.isLoading ? null : _demanderCode,
        style: ElevatedButton.styleFrom(
          backgroundColor: _indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: auth.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Recevoir un code par SMS'),
      ),
    ];
  }

  List<Widget> _buildEtapeCode(AuthProvider auth) {
    return [
      Text(
        'Entrez le code à 6 chiffres envoyé au ${_telephoneController.text.trim()}',
        style: const TextStyle(fontSize: 13.5, color: Colors.black54),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          letterSpacing: 8,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: auth.isLoading ? null : _verifierCode,
        style: ElevatedButton.styleFrom(
          backgroundColor: _indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: auth.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Valider et continuer'),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: auth.isLoading
            ? null
            : () => setState(() => _codeEnvoye = false),
        child: const Text('Changer de numéro'),
      ),
    ];
  }
}
