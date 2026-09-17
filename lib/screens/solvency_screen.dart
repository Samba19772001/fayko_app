import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Vérification de solvabilité (§3.7) : générer son propre code à
/// communiquer de vive voix, ou saisir le code d'un tiers pour consulter
/// son historique (montants/échéances/statuts uniquement — jamais
/// l'identité des autres prêteurs).
class SolvencyScreen extends StatefulWidget {
  const SolvencyScreen({super.key});

  @override
  State<SolvencyScreen> createState() => _SolvencyScreenState();
}

class _SolvencyScreenState extends State<SolvencyScreen> {
  final _api = ApiService();
  bool _ongletVerifier = true;

  static const _indigo = Color(0xFF1E3A5F);
  static const _gold = Color(0xFFB98B3E);
  static const _teal = Color(0xFF1F7A66);
  static const _plum = Color(0xFF6B4C8A);
  static const _rust = Color(0xFFA6402F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F7),
      appBar: AppBar(
        backgroundColor: _indigo,
        title: const Text('Solvabilité'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE2E6E8),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  Expanded(child: _tab('Vérifier quelqu\'un', true)),
                  Expanded(child: _tab('Mon code', false)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _ongletVerifier
                  ? _VerifierTab(api: _api)
                  : _MonCodeTab(api: _api),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, bool value) {
    final selected = _ongletVerifier == value;
    return GestureDetector(
      onTap: () => setState(() => _ongletVerifier = value),
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

// ---------- Onglet "Vérifier quelqu'un" ----------

class _VerifierTab extends StatefulWidget {
  final ApiService api;
  const _VerifierTab({required this.api});

  @override
  State<_VerifierTab> createState() => _VerifierTabState();
}

class _VerifierTabState extends State<_VerifierTab> {
  final _codeController = TextEditingController();
  bool _chargement = false;
  String? _erreur;
  Map<String, dynamic>? _resume;

  static const _indigo = Color(0xFF1E3A5F);
  static const _gold = Color(0xFFB98B3E);
  static const _teal = Color(0xFF1F7A66);
  static const _amber = Color(0xFFB8862B);
  static const _rust = Color(0xFFA6402F);
  static const _plum = Color(0xFF6B4C8A);

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final data = await widget.api.post('/solvabilite/verifier-code', {
        'code': _codeController.text.trim(),
      });
      setState(() => _resume = data);
    } on ApiException catch (e) {
      setState(() => _erreur = e.message);
    } catch (_) {
      setState(() => _erreur = "Impossible de contacter le serveur.");
    } finally {
      setState(() => _chargement = false);
    }
  }

  void _reinitialiser() {
    setState(() {
      _resume = null;
      _erreur = null;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_resume != null) {
      return _buildResultat();
    }

    return ListView(
      children: [
        const Text(
          "Demandez à la personne concernée de générer un code depuis son application, puis saisissez-le ici.",
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 24),
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
              style: const TextStyle(color: _rust, fontSize: 13),
            ),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _chargement ? null : _valider,
          style: ElevatedButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: const Color(0xFF3A2A0C),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _chargement
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Valider le code'),
        ),
        const SizedBox(height: 10),
        const Text(
          "Un code non utilisé expire automatiquement après 10 minutes.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: Colors.black38),
        ),
      ],
    );
  }

  Widget _buildResultat() {
    final r = _resume!;
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _plum.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            "Seuls les montants, échéances et statuts sont visibles. L'identité des autres prêteurs n'est jamais affichée.",
            style: TextStyle(color: _plum, fontSize: 11.5),
          ),
        ),
        _section('Contrats actifs', r['actifs'], _teal),
        _section('En retard', r['en_retard'], _amber),
        _section('Impayés', r['impayes'], _rust),
        _section('Soldés', r['soldes'], Colors.black45),
        _section('Litiges', r['litiges'], _plum),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _reinitialiser,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Vérifier un autre code'),
        ),
      ],
    );
  }

  Widget _section(String titre, dynamic items, Color couleur) {
    final liste = (items as List?) ?? [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              '${titre.toUpperCase()} (${liste.length})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (liste.isEmpty)
            const Text(
              'Aucun',
              style: TextStyle(color: Colors.black38, fontSize: 12.5),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD8DEE2)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: liste.map<Widget>((c) {
                  final montant = double.parse(c['montant'].toString()).toInt();
                  final echeance = c['date_echeance'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$montant FCFA',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          echeance,
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- Onglet "Mon code" ----------

class _MonCodeTab extends StatefulWidget {
  final ApiService api;
  const _MonCodeTab({required this.api});

  @override
  State<_MonCodeTab> createState() => _MonCodeTabState();
}

class _MonCodeTabState extends State<_MonCodeTab> {
  String? _code;
  DateTime? _expireA;
  List<dynamic>? _historique;
  String? _erreur;
  bool _chargement = false;

  static const _indigo = Color(0xFF1E3A5F);

  @override
  void initState() {
    super.initState();
    _chargerHistorique();
  }

  Future<void> _genererCode() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final data = await widget.api.post('/solvabilite/generer-code', {});
      setState(() {
        _code = data['code'];
        _expireA = DateTime.tryParse(data['expire_a'] ?? '');
      });
    } on ApiException catch (e) {
      setState(() => _erreur = e.message);
    } catch (_) {
      setState(() => _erreur = "Impossible de contacter le serveur.");
    } finally {
      setState(() => _chargement = false);
    }
  }

  Future<void> _chargerHistorique() async {
    try {
      final data = await widget.api.get('/solvabilite/historique');
      setState(() => _historique = data as List);
    } catch (_) {
      // Historique non bloquant : on ignore silencieusement l'échec.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text(
          "Communiquez ce code à un prêteur potentiel de vive voix.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 24),
        if (_code != null) ...[
          Text(
            _code!.replaceRange(3, 3, ' '),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 40,
              fontWeight: FontWeight.w600,
              color: _indigo,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Usage unique · Non transférable',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 20),
        ],
        if (_erreur != null) ...[
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
          const SizedBox(height: 16),
        ],
        ElevatedButton(
          onPressed: _chargement ? null : _genererCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: _indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _chargement
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _code == null ? 'Générer un code' : 'Générer un nouveau code',
                ),
        ),
        const SizedBox(height: 28),
        const Text(
          'QUI A CONSULTÉ MON PROFIL',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 10),
        if (_historique == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_historique!.isEmpty)
          const Text(
            'Aucune consultation pour le moment.',
            style: TextStyle(color: Colors.black38, fontSize: 12.5),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD8DEE2)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: _historique!.map<Widget>((h) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        h['consulte_par'] ?? 'Utilisateur Fayko',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      Text(
                        h['date']?.toString().substring(0, 16) ?? '',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
