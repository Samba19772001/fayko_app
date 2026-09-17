import 'remboursement.dart';

/// Représente un contrat tel que renvoyé par l'API (§5.3 côté Laravel).
class Contrat {
  final int id;
  final int preteurId;
  final int emprunteurId;
  final double montant;
  final String devise;
  final DateTime dateRemiseFonds;
  final DateTime dateEcheance;
  final double? tauxInteret;
  final String? garanties;
  final String modeRemboursement;
  final String? statut;
  final bool fraisPayes;
  final String? pdfUrl;
  final String preteurNom;
  final String preteurTelephone;
  final String emprunteurNom;
  final String emprunteurTelephone;
  final List<int> signataireIds;
  final List<Remboursement> remboursements;

  Contrat({
    required this.id,
    required this.preteurId,
    required this.emprunteurId,
    required this.montant,
    required this.devise,
    required this.dateRemiseFonds,
    required this.dateEcheance,
    this.tauxInteret,
    this.garanties,
    required this.modeRemboursement,
    required this.statut,
    required this.fraisPayes,
    this.pdfUrl,
    required this.preteurNom,
    required this.preteurTelephone,
    required this.emprunteurNom,
    required this.emprunteurTelephone,
    required this.signataireIds,
    required this.remboursements,
  });

  factory Contrat.fromJson(Map<String, dynamic> json) {
    String nomOuTelephone(Map<String, dynamic> personne) {
      final prenom = personne['prenom'];
      final nom = personne['nom'];
      if (prenom == null && nom == null) return personne['telephone'];
      return '${prenom ?? ''} ${nom ?? ''}'.trim();
    }

    final signatures = (json['signatures'] as List?) ?? [];
    final remboursementsJson = (json['remboursements'] as List?) ?? [];

    return Contrat(
      id: json['id'],
      preteurId: json['preteur_id'],
      emprunteurId: json['emprunteur_id'],
      montant: double.parse(json['montant'].toString()),
      devise: json['devise'] ?? 'FCFA',
      dateRemiseFonds: DateTime.parse(json['date_remise_fonds']),
      dateEcheance: DateTime.parse(json['date_echeance']),
      tauxInteret: json['taux_interet'] != null ? double.parse(json['taux_interet'].toString()) : null,
      garanties: json['garanties'],
      modeRemboursement: json['mode_remboursement'],
      statut: json['statut'],
      fraisPayes: json['frais_payes'] ?? false,
      pdfUrl: json['pdf_url'],
      preteurNom: nomOuTelephone(json['preteur']),
      preteurTelephone: json['preteur']['telephone'],
      emprunteurNom: nomOuTelephone(json['emprunteur']),
      emprunteurTelephone: json['emprunteur']['telephone'],
      signataireIds: signatures.map<int>((s) => s['user_id'] as int).toList(),
      remboursements: remboursementsJson.map((r) => Remboursement.fromJson(r)).toList(),
    );
  }

  bool aSignePar(int userId) => signataireIds.contains(userId);
  bool get lesDeuxOntSigne => signataireIds.length == 2;
  bool get estConclu => statut != null && fraisPayes;

  double get totalRembourseConfirme => remboursements
      .where((r) => r.statutConfirmation == 'confirme')
      .fold(0.0, (total, r) => total + r.montant);

  String get statutAffiche {
    switch (statut) {
      case 'actif': return 'Actif';
      case 'en_retard': return 'En retard';
      case 'impaye': return 'Impayé';
      case 'solde': return 'Soldé';
      case 'litige': return 'Litige';
      default: return 'En attente de signature';
    }
  }

  String get modeRemboursementAffiche {
    switch (modeRemboursement) {
      case 'mobile_money': return 'Mobile money';
      case 'especes': return 'Espèces';
      case 'virement': return 'Virement bancaire';
      default: return modeRemboursement;
    }
  }

  String get montantFormate => _formaterNombre(montant);
  String _formaterNombre(double n) {
    final entier = n.toInt();
    final str = entier.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return '$buffer F';
  }

  String formaterDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}