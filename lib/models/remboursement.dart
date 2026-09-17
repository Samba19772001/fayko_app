/// Représente un remboursement déclaré (§3.6) : le prêteur ou l'emprunteur
/// déclare avoir reçu/payé un montant, rattaché à une référence de
/// transaction vérifiable (mobile money ou virement). L'autre partie
/// confirme ou conteste.
class Remboursement {
  final int id;
  final int contratId;
  final double montant;
  final String referenceTransaction;
  final int declarePar;
  final String statutConfirmation;
  final DateTime dateDeclaration;

  Remboursement({
    required this.id,
    required this.contratId,
    required this.montant,
    required this.referenceTransaction,
    required this.declarePar,
    required this.statutConfirmation,
    required this.dateDeclaration,
  });

  factory Remboursement.fromJson(Map<String, dynamic> json) {
    return Remboursement(
      id: json['id'],
      contratId: json['contrat_id'],
      montant: double.parse(json['montant'].toString()),
      referenceTransaction: json['reference_transaction'] ?? '',
      declarePar: json['declare_par'],
      statutConfirmation: json['statut_confirmation'],
      dateDeclaration: DateTime.parse(json['date_declaration']),
    );
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