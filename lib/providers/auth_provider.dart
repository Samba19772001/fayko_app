import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

/// Gère l'état de connexion dans toute l'app : qui est connecté, et permet
/// à n'importe quel écran de réagir (via Provider) quand cet état change,
/// par exemple pour rediriger vers l'accueil après une connexion réussie.
class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  /// Étape 1 de la connexion (§3.1) : demande un code par SMS.
  Future<void> demanderCode(String telephone) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.post('/auth/demander-code', {
        'telephone': telephone,
      }, withAuth: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Étape 2 : valide le code, sauvegarde le jeton, charge l'utilisateur.
  Future<void> verifierCode(String telephone, String code) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.post('/auth/verifier-code', {
        'telephone': telephone,
        'code': code,
      }, withAuth: false);
      await _api.saveToken(data['token']);
      _user = User.fromJson(data['user']);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tente de restaurer une session existante au lancement de l'app
  /// (jeton déjà stocké depuis une connexion précédente).
  Future<void> chargerSessionExistante() async {
    try {
      final data = await _api.get('/auth/moi');
      _user = User.fromJson(data);
      notifyListeners();
    } catch (_) {
      // Pas de jeton valide : l'utilisateur devra se reconnecter.
    }
  }

  Future<void> deconnexion() async {
    try {
      await _api.post('/auth/deconnexion', {});
    } catch (_) {
      // Même si l'appel échoue, on déconnecte localement.
    }
    await _api.deleteToken();
    _user = null;
    notifyListeners();
  }

  /// Complète le profil (nom, prénom, CNI) — §3.2. Ne rend pas le compte
  /// "vérifié" pour autant, ça reste une étape distincte (vérification
  /// d'identité par un agent, non couverte ici).
  Future<void> completerProfil({
    required String nom,
    required String prenom,
    required String numeroCni,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.post('/auth/completer-profil', {
        'nom': nom,
        'prenom': prenom,
        'numero_cni': numeroCni,
      });
      _user = User.fromJson(data['user']);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
