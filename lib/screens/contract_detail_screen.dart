import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contrat.dart';
import '../models/remboursement.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ContractDetailScreen extends StatefulWidget {
  final int contratId;

  const ContractDetailScreen({super.key, required this.contratId});

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  final _api = ApiService();
  final _deviceFingerprint = 'flutter-web-${Random().nextInt(999999)}';

  Contrat? _contrat;
  String? _erreur;
  bool _signatureEnCours = false;
  bool _paiementEnCours = false;
  bool _actionRemboursementEnCours = false;
  String _operateurChoisi = 'wave';

  static const _indigo = Color(0xFF1E3A5F);
  static const _gold = Color(0xFFB98B3E);
  static const _teal = Color(0xFF1F7A66);
  static const _amber = Color(0xFFB8862B);
  static const _rust = Color(0xFFA6402F);
  static const _plum = Color(0xFF6B4C8A);

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);
    try {
      final data = await _api.get('/contrats/${widget.contratId}');
      setState(() => _contrat = Contrat.fromJson(data));
    } on ApiException catch (e) {
      setState(() => _erreur = e.message);
    } catch (_) {
      setState(() => _erreur = "Impossible de charger ce contrat.");
    }
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: _rust),
    );
  }

  // ---------- Signature (§3.5) ----------

  Future<void> _lancerSignature() async {
    try {
      await _api.post('/contrats/${widget.contratId}/signature/demander-code', {});
      if (!mounted) return;
      _ouvrirFeuilleOtp();
    } on ApiException catch (e) {
      _afficherErreur(e.message);
    } catch (_) {
      _afficherErreur("Impossible de contacter le serveur.");
    }
  }

  void _ouvrirFeuilleOtp() {
    final codeController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 22, right: 22, top: 22,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 28,
          ),
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  const Text('Confirmez votre signature', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Un code vous a été envoyé par SMS.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _signatureEnCours
                        ? null
                        : () async {
                            setSheetState(() => _signatureEnCours = true);
                            final ok = await _confirmerSignature(codeController.text.trim());
                            if (!mounted) return;
                            setSheetState(() => _signatureEnCours = false);
                            if (ok) {
                              Navigator.of(sheetContext).pop();
                              _ouvrirSceau();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: const Color(0xFF3A2A0C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _signatureEnCours
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Valider et signer'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<bool> _confirmerSignature(String code) async {
    try {
      await _api.post('/contrats/${widget.contratId}/signature', {
        'code': code,
        'device_fingerprint': _deviceFingerprint,
      });
      return true;
    } on ApiException catch (e) {
      _afficherErreur(e.message);
      return false;
    } catch (_) {
      _afficherErreur("Impossible de contacter le serveur.");
      return false;
    }
  }

  void _ouvrirSceau() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) => Transform.scale(scale: value, child: child),
                  child: Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _gold, width: 2.5)),
                    child: Center(
                      child: Container(
                        width: 64, height: 64,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF5F0E4)),
                        child: const Icon(Icons.check, color: _indigo, size: 30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Signature enregistrée', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text(
                  "L'intégrité et l'horodatage du document sont garantis.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _charger();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _indigo,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Continuer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- Paiement des frais (§3.4) ----------

  void _ouvrirFeuillePaiement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.only(left: 22, right: 22, top: 22, bottom: 28),
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              Widget operateurCard(String value, String emoji, String label) {
                final selected = _operateurChoisi == value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setSheetState(() => _operateurChoisi = value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: selected ? _gold : Colors.grey.shade300, width: selected ? 1.5 : 1),
                        borderRadius: BorderRadius.circular(13),
                        color: selected ? const Color(0xFFFBF4E7) : Colors.transparent,
                      ),
                      child: Column(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 6),
                          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7F7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD8DEE2)),
                    ),
                    child: const Column(
                      children: [
                        Text('MONTANT À PAYER', style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        SizedBox(height: 6),
                        Text('500 FCFA', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: _indigo)),
                        SizedBox(height: 4),
                        Text('Génération et archivage juridique du contrat', style: TextStyle(fontSize: 11.5, color: Colors.black45)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("CHOISIR UN OPÉRATEUR", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      operateurCard('wave', '🟦', 'Wave'),
                      operateurCard('orange_money', '🟧', 'Orange Money'),
                      operateurCard('free_money', '🟥', 'Free Money'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _paiementEnCours
                        ? null
                        : () async {
                            setSheetState(() => _paiementEnCours = true);
                            final ok = await _confirmerPaiement();
                            if (!mounted) return;
                            setSheetState(() => _paiementEnCours = false);
                            if (ok) {
                              Navigator.of(sheetContext).pop();
                              _charger();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _paiementEnCours
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Payer 500 FCFA'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Le contrat n'est archivé qu'une fois le paiement confirmé.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.black38),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<bool> _confirmerPaiement() async {
    try {
      await _api.post('/contrats/${widget.contratId}/paiement', {
        'operateur': _operateurChoisi,
      });
      return true;
    } on ApiException catch (e) {
      _afficherErreur(e.message);
      return false;
    } catch (_) {
      _afficherErreur("Impossible de contacter le serveur.");
      return false;
    }
  }

  // ---------- Remboursements (§3.6) ----------

  void _ouvrirDialogueDeclaration() {
    final montantController = TextEditingController();
    final referenceController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Déclarer un remboursement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "L'autre partie devra confirmer ce montant pour qu'il soit pris en compte.",
                style: TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: montantController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Montant (FCFA)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: referenceController,
                decoration: InputDecoration(
                  labelText: 'Référence de transaction',
                  hintText: 'Ex. identifiant Wave, référence virement…',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Requise : elle sert de preuve en cas de litige.",
                style: TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final montant = double.tryParse(montantController.text.trim());
                if (montant == null || montant <= 0) {
                  _afficherErreur('Montant invalide.');
                  return;
                }
                if (referenceController.text.trim().isEmpty) {
                  _afficherErreur('La référence de transaction est requise.');
                  return;
                }
                Navigator.of(dialogContext).pop();
                await _declarerRemboursement(montant, referenceController.text.trim());
              },
              style: ElevatedButton.styleFrom(backgroundColor: _indigo, foregroundColor: Colors.white),
              child: const Text('Déclarer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _declarerRemboursement(double montant, String reference) async {
    setState(() => _actionRemboursementEnCours = true);
    try {
      await _api.post('/contrats/${widget.contratId}/remboursements', {
        'montant': montant,
        'reference_transaction': reference,
      });
      await _charger();
    } on ApiException catch (e) {
      _afficherErreur(e.message);
    } catch (_) {
      _afficherErreur("Impossible de contacter le serveur.");
    } finally {
      if (mounted) setState(() => _actionRemboursementEnCours = false);
    }
  }

  Future<void> _confirmerRemboursement(int id) async {
    setState(() => _actionRemboursementEnCours = true);
    try {
      await _api.post('/remboursements/$id/confirmer', {});
      await _charger();
    } on ApiException catch (e) {
      _afficherErreur(e.message);
    } catch (_) {
      _afficherErreur("Impossible de contacter le serveur.");
    } finally {
      if (mounted) setState(() => _actionRemboursementEnCours = false);
    }
  }

  Future<void> _contesterRemboursement(int id) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Contester ce remboursement ?'),
        content: const Text('Le contrat passera au statut "Litige".'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Contester', style: TextStyle(color: _rust)),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    setState(() => _actionRemboursementEnCours = true);
    try {
      await _api.post('/remboursements/$id/contester', {});
      await _charger();
    } on ApiException catch (e) {
      _afficherErreur(e.message);
    } catch (_) {
      _afficherErreur("Impossible de contacter le serveur.");
    } finally {
      if (mounted) setState(() => _actionRemboursementEnCours = false);
    }
  }

  Future<void> _retirerContestation(int id) async {
    setState(() => _actionRemboursementEnCours = true);
    try {
      await _api.post('/remboursements/$id/retirer-contestation', {});
      await _charger();
    } on ApiException catch (e) {
      _afficherErreur(e.message);
    } catch (_) {
      _afficherErreur("Impossible de contacter le serveur.");
    } finally {
      if (mounted) setState(() => _actionRemboursementEnCours = false);
    }
  }

  // ---------- PDF ----------

  Future<void> _ouvrirPdf(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, webOnlyWindowName: '_blank')) {
      if (!mounted) return;
      _afficherErreur("Impossible d'ouvrir le document.");
    }
  }

  // ---------- Affichage ----------

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F7),
      appBar: AppBar(
        backgroundColor: _indigo,
        title: Text(_contrat != null ? 'Contrat #${_contrat!.id}' : 'Contrat'),
      ),
      body: _buildBody(userId),
    );
  }

  Widget _buildBody(int? userId) {
    if (_erreur != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_erreur!, style: const TextStyle(color: _rust), textAlign: TextAlign.center),
        ),
      );
    }
    final c = _contrat;
    if (c == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final mesSignatures = userId != null ? c.aSignePar(userId) : false;

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle('Résumé du prêt'),
          _card([
            _row('Prêteur', c.preteurNom),
            _row('Emprunteur', c.emprunteurNom),
            _row('Montant', c.montantFormate),
            _row('Remise des fonds', c.formaterDate(c.dateRemiseFonds)),
            _row('Échéance', c.formaterDate(c.dateEcheance)),
            _row('Remboursement', c.modeRemboursementAffiche),
            if (c.tauxInteret != null) _row("Taux d'intérêt", '${c.tauxInteret}%'),
            if (c.garanties != null && c.garanties!.isNotEmpty) _row('Garanties', c.garanties!),
          ]),
          _sectionTitle('Signatures'),
          _card([
            _signataireRow('Prêteur', c.preteurNom, c.aSignePar(c.preteurId)),
            const Divider(height: 20),
            _signataireRow('Emprunteur', c.emprunteurNom, c.aSignePar(c.emprunteurId)),
          ]),
          if (c.estConclu) ...[
            _sectionTitle('Document'),
            _card([
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, color: _rust, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Contrat_Fayko_${c.id}.pdf',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    if (c.pdfUrl != null)
                      TextButton(
                        onPressed: () => _ouvrirPdf(c.pdfUrl!),
                        child: const Text('Ouvrir'),
                      ),
                  ],
                ),
              ),
            ]),
            _sectionTitle('Remboursements'),
            _buildRemboursements(c, userId),
          ],
          const SizedBox(height: 8),
          _buildActionZone(c, userId, mesSignatures),
        ],
      ),
    );
  }

  Widget _buildRemboursements(Contrat c, int? userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card([
          _row('Montant du prêt', c.montantFormate),
          _row('Remboursé (confirmé)', '${c.totalRembourseConfirme.toInt()} F'),
        ]),
        if (c.remboursements.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Aucun remboursement déclaré pour le moment.', style: TextStyle(color: Colors.black45, fontSize: 12.5)),
          )
        else
          ...c.remboursements.map((r) => _remboursementCard(r, userId)),
        if (c.statut != 'solde')
          OutlinedButton.icon(
            onPressed: _actionRemboursementEnCours ? null : _ouvrirDialogueDeclaration,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Déclarer un remboursement'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _remboursementCard(Remboursement r, int? userId) {
    Color couleur;
    String label;
    switch (r.statutConfirmation) {
      case 'confirme':
        couleur = _teal;
        label = 'Confirmé';
        break;
      case 'conteste':
        couleur = _rust;
        label = 'Contesté';
        break;
      default:
        couleur = _amber;
        label = 'En attente de confirmation';
    }

    final peutAgir = userId != null && userId != r.declarePar && r.statutConfirmation == 'en_attente';

    // Seule la partie qui n'a PAS déclaré peut avoir contesté — donc si le
    // statut est "conteste" et que l'utilisateur courant n'est pas le
    // déclarant, c'est forcément lui l'auteur de la contestation.
    final peutRetirerContestation = userId != null && userId != r.declarePar && r.statutConfirmation == 'conteste';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8DEE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r.montantFormate, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(label, style: TextStyle(color: couleur, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text('Déclaré le ${r.dateDeclaration.day}/${r.dateDeclaration.month}/${r.dateDeclaration.year}',
              style: const TextStyle(color: Colors.black45, fontSize: 11.5)),
          const SizedBox(height: 2),
          Text('Réf. ${r.referenceTransaction}', style: const TextStyle(color: Colors.black45, fontSize: 11.5)),
          if (peutAgir) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _actionRemboursementEnCours ? null : () => _contesterRemboursement(r.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _rust,
                      side: const BorderSide(color: _rust),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Contester', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _actionRemboursementEnCours ? null : () => _confirmerRemboursement(r.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Confirmer', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
              ],
            ),
          ],
          if (peutRetirerContestation) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _actionRemboursementEnCours ? null : () => _retirerContestation(r.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: _indigo,
                side: const BorderSide(color: _indigo),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Retirer ma contestation', style: TextStyle(fontSize: 12.5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionZone(Contrat c, int? userId, bool mesSignatures) {
    if (c.statut != null && c.fraisPayes) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _teal.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: const [
            Icon(Icons.verified, color: _teal, size: 20),
            SizedBox(width: 8),
            Text('Contrat conclu et archivé', style: TextStyle(color: _teal, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    if (c.lesDeuxOntSigne && !c.fraisPayes) {
      return ElevatedButton(
        onPressed: _ouvrirFeuillePaiement,
        style: ElevatedButton.styleFrom(
          backgroundColor: _indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('Continuer vers le paiement (500 FCFA)'),
      );
    }

    if (mesSignatures && !c.lesDeuxOntSigne) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: const Text(
          "Signature enregistrée. En attente de l'autre partie.",
          style: TextStyle(color: _teal, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (userId != null && !mesSignatures) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              "Aucun contrat n'est créé tant que les deux parties n'ont pas signé activement.",
              style: TextStyle(color: Colors.black45, fontSize: 12.5),
            ),
          ),
          ElevatedButton(
            onPressed: _lancerSignature,
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: const Color(0xFF3A2A0C),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text("J'accepte et je signe"),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Colors.black54),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 22),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD8DEE2)),
        ),
        child: Column(children: children),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            Flexible(
              child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _signataireRow(String role, String nom, bool aSigne) => Row(
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: aSigne ? _teal.withOpacity(0.12) : const Color(0xFFE2E6E8),
            ),
            child: Icon(aSigne ? Icons.check : Icons.hourglass_empty, size: 14, color: aSigne ? _teal : Colors.black45),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$nom ($role)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                Text(aSigne ? 'Signé' : 'En attente de signature', style: const TextStyle(fontSize: 11.5, color: Colors.black45)),
              ],
            ),
          ),
        ],
      );
}