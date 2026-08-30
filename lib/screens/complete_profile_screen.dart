import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

/// Formulaire pour renseigner nom, prénom et CNI (§3.2). Ne couvre pas
/// l'upload des photos recto/verso — juste les champs texte.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _cniController = TextEditingController();
  String? _erreur;

  static const _indigo = Color(0xFF1E3A5F);

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nomController.text = user?.nom ?? '';
    _prenomController.text = user?.prenom ?? '';
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _cniController.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _erreur = null);
    final auth = context.read<AuthProvider>();
    try {
      await auth.completerProfil(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        numeroCni: _cniController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informations enregistrées.')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _erreur = e.message);
    } catch (_) {
      setState(() => _erreur = "Impossible de contacter le serveur.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F7),
      appBar: AppBar(
        backgroundColor: _indigo,
        title: const Text('Mes informations'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('Prénom'),
              TextFormField(
                controller: _prenomController,
                decoration: _decoration('Moussa'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 18),
              _label('Nom'),
              TextFormField(
                controller: _nomController,
                decoration: _decoration('Diop'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 18),
              _label('Numéro de CNI'),
              TextFormField(
                controller: _cniController,
                decoration: _decoration('1 234 5678 9012'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 8),
              const Text(
                "Ce numéro sera chiffré et ne sera jamais affiché en clair. La vérification complète de votre identité (photos CNI) se fait séparément.",
                style: TextStyle(color: Colors.black45, fontSize: 12),
              ),
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.isLoading ? null : _enregistrer,
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
                    : const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    ),
  );

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}
