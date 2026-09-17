import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'complete_profile_screen.dart';
import 'identity_verification_screen.dart';

/// Écran de profil : informations de l'utilisateur, menu vers les
/// réglages, et déconnexion.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _indigo = Color(0xFF1E3A5F);
  static const _teal = Color(0xFF1F7A66);
  static const _rust = Color(0xFFA6402F);

  Future<void> _confirmerDeconnexion(BuildContext context) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vous devrez à nouveau vérifier votre numéro pour vous reconnecter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Se déconnecter', style: TextStyle(color: _rust)),
          ),
        ],
      ),
    );
    if (confirme == true && context.mounted) {
      await context.read<AuthProvider>().deconnexion();
    }
  }

  String _initiales(String nom) {
    final parts = nom.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F7),
      appBar: AppBar(
        backgroundColor: _indigo,
        title: const Text('Profil'),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: _indigo,
                      child: Text(
                        _initiales(user.nomComplet),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.nomComplet,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.telephone,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: user.estVerifie
                                  ? _teal.withOpacity(0.12)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user.estVerifie
                                  ? '✓ Compte vérifié'
                                  : 'Compte non vérifié',
                              style: TextStyle(
                                color: user.estVerifie ? _teal : Colors.black54,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _menuItem(
                  context,
                  label: 'Mes informations',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CompleteProfileScreen(),
                    ),
                  ),
                ),
                _menuItem(
                  context,
                  label: "Vérification d'identité (CNI)",
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const IdentityVerificationScreen()),
                  ),
                ),
                _menuItem(
                  context,
                  label: "Aide & assistance",
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Écran à venir')),
                  ),
                ),
                const SizedBox(height: 12),
                _menuItem(
                  context,
                  label: 'Se déconnecter',
                  color: _rust,
                  showArrow: false,
                  onTap: () => _confirmerDeconnexion(context),
                ),
              ],
            ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF16233A),
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFD8DEE2))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: color)),
            if (showArrow)
              const Icon(Icons.chevron_right, color: Colors.black38, size: 20),
          ],
        ),
      ),
    );
  }
}
