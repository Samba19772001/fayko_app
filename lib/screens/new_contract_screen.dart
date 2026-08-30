import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'contract_detail_screen.dart';

/// Formulaire de création de contrat (§3.3). Envoie la demande au
/// prêteur connecté vers l'autre partie identifiée par son numéro.
class NewContractScreen extends StatefulWidget {
  const NewContractScreen({super.key});

  @override
  State<NewContractScreen> createState() => _NewContractScreenState();
}

class _NewContractScreenState extends State<NewContractScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _telephoneController = TextEditingController();
  final _montantController = TextEditingController();
  final _tauxController = TextEditingController();
  final _garantiesController = TextEditingController();

  DateTime? _dateRemise;
  DateTime? _dateEcheance;
  String _modeRemboursement = 'mobile_money';
  bool _envoiEnCours = false;
  String? _erreur;

  static const _indigo = Color(0xFF1E3A5F);

  @override
  void dispose() {
    _telephoneController.dispose();
    _montantController.dispose();
    _tauxController.dispose();
    _garantiesController.dispose();
    super.dispose();
  }

  Future<void> _choisirDate({required bool estRemise}) async {
    final maintenant = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: maintenant,
      firstDate: estRemise
          ? maintenant.subtract(const Duration(days: 30))
          : maintenant,
      lastDate: maintenant.add(const Duration(days: 365 * 3)),
    );
    if (date == null) return;
    setState(() {
      if (estRemise) {
        _dateRemise = date;
      } else {
        _dateEcheance = date;
      }
    });
  }

  String _formaterDate(DateTime? date) {
    if (date == null) return 'Choisir une date';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _envoyerDemande() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateRemise == null || _dateEcheance == null) {
      setState(() => _erreur = "Merci de renseigner les deux dates.");
      return;
    }
    if (!_dateEcheance!.isAfter(_dateRemise!)) {
      setState(
        () => _erreur = "L'échéance doit être postérieure à la date de remise.",
      );
      return;
    }

    setState(() {
      _envoiEnCours = true;
      _erreur = null;
    });

    try {
      final data = await _api.post('/contrats', {
        'telephone_autre_partie': _telephoneController.text.trim(),
        'montant': double.parse(_montantController.text.trim()),
        'date_remise_fonds': _dateRemise!.toIso8601String().split('T').first,
        'date_echeance': _dateEcheance!.toIso8601String().split('T').first,
        if (_tauxController.text.trim().isNotEmpty)
          'taux_interet': double.parse(_tauxController.text.trim()),
        if (_garantiesController.text.trim().isNotEmpty)
          'garanties': _garantiesController.text.trim(),
        'mode_remboursement': _modeRemboursement,
      });

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ContractDetailScreen(contratId: data['id']),
        ),
      );
      Navigator.of(context).pop(data);
    } on ApiException catch (e) {
      setState(() => _erreur = e.message);
    } catch (_) {
      setState(() => _erreur = "Impossible de contacter le serveur.");
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F7),
      appBar: AppBar(
        backgroundColor: _indigo,
        title: const Text('Nouveau contrat'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('Numéro de téléphone de l\'autre partie'),
              TextFormField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                decoration: _decoration('77 000 00 00'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 18),
              _label('Montant prêté (FCFA)'),
              TextFormField(
                controller: _montantController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decoration('60000'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ requis';
                  if (double.tryParse(v.trim()) == null)
                    return 'Montant invalide';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _dateField(
                      label: 'Date de remise',
                      date: _dateRemise,
                      onTap: () => _choisirDate(estRemise: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dateField(
                      label: 'Échéance',
                      date: _dateEcheance,
                      onTap: () => _choisirDate(estRemise: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _label('Taux d\'intérêt (optionnel)'),
              TextFormField(
                controller: _tauxController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decoration('0'),
              ),
              const SizedBox(height: 18),
              _label('Garanties (optionnel)'),
              TextFormField(
                controller: _garantiesController,
                maxLines: 3,
                decoration: _decoration(
                  'Ex. dépôt d\'un objet de valeur, caution d\'un tiers…',
                ),
              ),
              const SizedBox(height: 18),
              _label('Mode de remboursement'),
              const SizedBox(height: 4),
              _radioMode('mobile_money', 'Mobile money'),
              _radioMode('especes', 'Espèces'),
              _radioMode('virement', 'Virement bancaire'),
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
                onPressed: _envoiEnCours ? null : _envoyerDemande,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _envoiEnCours
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Envoyer la demande'),
              ),
              const SizedBox(height: 20),
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

  Widget _dateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formaterDate(date),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _radioMode(String value, String label) {
    final selected = _modeRemboursement == value;
    return InkWell(
      onTap: () => setState(() => _modeRemboursement = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? _indigo : Colors.grey.shade400,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected ? const Color(0xFFEEF2F6) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected ? _indigo : Colors.grey,
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
