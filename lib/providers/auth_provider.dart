import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

/// Gère l'état de connexion dans toute l'app. Deux parcours distincts :
///  - Connexion : téléphone + mot de passe, aucun OTP.
///  - Inscription : OTP une seule fois pour prouver le numéro, puis
///    définition du mot de passe dans la foulée.
class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  /// Connexion standard.
  Future<void> connexion(String telephone, String motDePasse) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.post('/auth/connexion', {
        'telephone': telephone,
        'mot_de_passe': motDePasse,
      }, withAuth: false);
      await _api.saveToken(data['token']);
      _user = User.fromJson(data['user']);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inscription étape 1 : demande le code de vérification du numéro.
  Future<void> inscriptionDemanderCode(String telephone) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.post('/auth/inscription/demander-code', {'telephone': telephone}, withAuth: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inscription étape 2 : valide le code et définit le mot de passe.
  Future<void> inscriptionDefinirMotDePasse(String telephone, String code, String motDePasse) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.post('/auth/inscription/definir-mot-de-passe', {
        'telephone': telephone,
        'code': code,
        'mot_de_passe': motDePasse,
      }, withAuth: false);
      await _api.saveToken(data['token']);
      _user = User.fromJson(data['user']);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
}