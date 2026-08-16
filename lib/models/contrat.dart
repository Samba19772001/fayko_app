/// Représente un contrat tel que renvoyé par l'API (§5.3 côté Laravel).
class Contrat {
  final int id;
  final double montant;
  final String devise;
  final DateTime dateEcheance;
  final String? statut; // null = en attente de signature
  final String preteurNom;
  final String preteurTelephone;
  final String emprunteurNom;
  final String emprunteurTelephone;

  Contrat({
    required this.id,
    required this.montant,
    required this.devise,
    required this.dateEcheance,
    required this.statut,
    required this.preteurNom,
    required this.preteurTelephone,
    required this.emprunteurNom,
    required this.emprunteurTelephone,
  });

  factory Contrat.fromJson(Map<String, dynamic> json) {
    String nomOuTelephone(Map<String, dynamic> personne) {
      final prenom = personne['prenom'];
      final nom = personne['nom'];
      if (prenom == null && nom == null) return personne['telephone'];
      return '${prenom ?? ''} ${nom ?? ''}'.trim();
    }

    return Contrat(
      id: json['id'],
      montant: double.parse(json['montant'].toString()),
      devise: json['devise'] ?? 'FCFA',
      dateEcheance: DateTime.parse(json['date_echeance']),
      statut: json['statut'],
      preteurNom: nomOuTelephone(json['preteur']),
      preteurTelephone: json['preteur']['telephone'],
      emprunteurNom: nomOuTelephone(json['emprunteur']),
      emprunteurTelephone: json['emprunteur']['telephone'],
    );
  }

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

  String get montantFormate {
    final entier = montant.toInt();
    final str = entier.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return '$buffer F';
  }
}