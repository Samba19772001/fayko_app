import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

/// Deux parcours distincts, basculables via un onglet :
///  - Connexion : téléphone + mot de passe.
///  - Inscription : téléphone → OTP → définition du mot de passe.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _modeConnexion = true;

  static const _indigo = Color(0xFF1E3A5F);
  static const _gold = Color(0xFFB98B3E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 50),
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
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E6E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      Expanded(child: _tab('Se connecter', true)),
                      Expanded(child: _tab('Créer un compte', false)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                if (_modeConnexion)
                  const _ConnexionForm()
                else
                  const _InscriptionForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool value) {
    final selected = _modeConnexion == value;
    return GestureDetector(
      onTap: () => setState(() => _modeConnexion = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected ? _indigo : Colors.black54,
          ),
        ),
      ),
    );
  }
}

// ---------- Formulaire de connexion ----------

class _ConnexionForm extends StatefulWidget {
  const _ConnexionForm();

  @override
  State<_ConnexionForm> createState() => _ConnexionFormState();
}

class _ConnexionFormState extends State<_ConnexionForm> {
  final _telephoneController = TextEditingController(text: '77');
  final _motDePasseController = TextEditingController();
  bool _motDePasseVisible = false;
  String? _erreur;

  static const _indigo = Color(0xFF1E3A5F);

  @override
  void dispose() {
    _telephoneController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    setState(() => _erreur = null);
    final auth = context.read<AuthProvider>();
    try {
      await auth.connexion(
        _telephoneController.text.trim(),
        _motDePasseController.text,
      );
      // AuthGate dans main.dart bascule automatiquement vers HomeScreen.
    } on ApiException catch (e) {
      setState(() => _erreur = e.message);
    } catch (_) {
      setState(() => _erreur = "Impossible de contacter le serveur.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        const SizedBox(height: 18),
        const Text(
          'Mot de passe',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _motDePasseController,
          obscureText: !_motDePasseVisible,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(
                _motDePasseVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _motDePasseVisible = !_motDePasseVisible),
            ),
          ),
        ),
        if (_erreur != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E4E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _erreur!,
              style: const TextStyle(color: Color(0xFFA6402F), fontSize: 13),
            ),
          ),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: auth.isLoading ? null : _connecter,
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
              : const Text('Se connecter'),
        ),
      ],
    );
  }
}

// ---------- Formulaire d'inscription (OTP puis mot de passe) ----------

class _InscriptionForm extends StatefulWidget {
  const _InscriptionForm();

  @override
  State<_InscriptionForm> createState() => _InscriptionFormState();
}

class _InscriptionFormState extends State<_InscriptionForm> {
  final _telephoneController = TextEditingController(text: '77');
  final _codeController = TextEditingController();
  final _motDePasseController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _codeEnvoye = false;
  bool _motDePasseVisible = false;
  String? _erreur;

  static const _indigo = Color(0xFF1E3A5F);

  @override
  void dispose() {
    _telephoneController.dispose();
    _codeController.dispose();
    _motDePasseController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _demanderCode() async {
    setState(() => _erreur = null);
    final auth = context.read<AuthProvider>();
    try {
      await auth.inscriptionDemanderCode(_telephoneController.text.trim());
      setState(() => _codeEnvoye = true);
    } on ApiException catch (e) {
      setState(() => _erreur = e.message);
    } catch (_) {
      setState(() => _erreur = "Impossible de contacter le serveur.");
    }
  }

  Future<void> _creerCompte() async {
    setState(() => _erreur = null);

    if (_motDePasseController.text.length < 6) {
      setState(
        () => _erreur = "Le mot de passe doit contenir au moins 6 caractères.",
      );
      return;
    }
    if (_motDePasseController.text != _confirmationController.text) {
      setState(() => _erreur = "Les mots de passe ne correspondent pas.");
      return;
    }

    final auth = context.read<AuthProvider>();
    try {
      await auth.inscriptionDefinirMotDePasse(
        _telephoneController.text.trim(),
        _codeController.text.trim(),
        _motDePasseController.text,
      );
      // AuthGate dans main.dart bascule automatiquement vers HomeScreen.
    } on ApiException catch (e) {
      setState(() => _erreur = e.message);
    } catch (_) {
      setState(() => _erreur = "Impossible de contacter le serveur.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!_codeEnvoye) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_erreur != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5E4E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _erreur!,
                style: const TextStyle(color: Color(0xFFA6402F), fontSize: 13),
              ),
            ),
          ],
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
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Entrez le code à 6 chiffres envoyé au ${_telephoneController.text.trim()}',
          style: const TextStyle(fontSize: 13.5, color: Colors.black54),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 10),
        const Text(
          'Choisir un mot de passe',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _motDePasseController,
          obscureText: !_motDePasseVisible,
          decoration: InputDecoration(
            hintText: '6 caractères minimum',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(
                _motDePasseVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _motDePasseVisible = !_motDePasseVisible),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Confirmer le mot de passe',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmationController,
          obscureText: !_motDePasseVisible,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_erreur != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E4E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _erreur!,
              style: const TextStyle(color: Color(0xFFA6402F), fontSize: 13),
            ),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: auth.isLoading ? null : _creerCompte,
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
              : const Text('Créer mon compte'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: auth.isLoading
              ? null
              : () => setState(() => _codeEnvoye = false),
          child: const Text('Changer de numéro'),
        ),
      ],
    );
  }
}
