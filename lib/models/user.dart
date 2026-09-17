/// Représente un utilisateur Fayko tel que renvoyé par l'API.
/// Miroir du modèle User côté Laravel (cahier des charges §5.3).
class User {
  final int id;
  final String telephone;
  final String? nom;
  final String? prenom;
  final String statutVerification; // 'non_verifie' | 'verifie'

  User({
    required this.id,
    required this.telephone,
    this.nom,
    this.prenom,
    required this.statutVerification,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      telephone: json['telephone'],
      nom: json['nom'],
      prenom: json['prenom'],
      statutVerification: json['statut_verification'] ?? 'non_verifie',
    );
  }

  bool get estVerifie => statutVerification == 'verifie';
  bool get estEnAttente => statutVerification == 'en_attente';

  String get nomComplet {
    if (nom == null && prenom == null) return telephone;
    return '${prenom ?? ''} ${nom ?? ''}'.trim();
  }
}
