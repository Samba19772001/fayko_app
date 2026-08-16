import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/contrat.dart';
import 'new_contract_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _indigo = Color(0xFF1E3A5F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F7),
      appBar: AppBar(
        backgroundColor: _indigo,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Fayko.',
          style: TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white24,
              child: Text(
                _initiales(
                  context.watch<AuthProvider>().user?.nomComplet ?? '',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: const _ContractsListView(),
      bottomNavigationBar: _BottomNav(),
    );
  }

  String _initiales(String nom) {
    final parts = nom.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _ContractsListView extends StatefulWidget {
  const _ContractsListView();

  @override
  State<_ContractsListView> createState() => _ContractsListViewState();
}

class _ContractsListViewState extends State<_ContractsListView> {
  final _api = ApiService();
  String _role = 'preteur';
  List<Contrat>? _contrats;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _contrats = null;
      _erreur = null;
    });
    try {
      final data = await _api.get('/contrats?role=$_role');
      setState(
        () =>
            _contrats = (data as List).map((j) => Contrat.fromJson(j)).toList(),
      );
    } on ApiException catch (e) {
      setState(() => _erreur = e.message);
    } catch (_) {
      setState(() => _erreur = "Impossible de charger les contrats.");
    }
  }

  Color _couleurStatut(String? statut) {
    switch (statut) {
      case 'actif':
        return const Color(0xFF1F7A66);
      case 'en_retard':
        return const Color(0xFFB8862B);
      case 'impaye':
        return const Color(0xFFA6402F);
      case 'litige':
        return const Color(0xFF6B4C8A);
      default:
        return const Color(0xFF5B6B7F);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _charger,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _SegmentedRole(
              role: _role,
              onChanged: (role) {
                setState(() => _role = role);
                _charger();
              },
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_erreur != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _erreur!,
            style: const TextStyle(color: Color(0xFFA6402F)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_contrats == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_contrats!.isEmpty) {
      return Center(
        child: Text(
          _role == 'preteur'
              ? "Vous n'avez encore prêté à personne."
              : "Vous n'avez encore aucun emprunt.",
          style: const TextStyle(color: Colors.black45),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _contrats!.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final c = _contrats![i];
        final autrePartie = _role == 'preteur' ? c.emprunteurNom : c.preteurNom;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF1E3A5F),
            child: Text(
              autrePartie.isNotEmpty
                  ? autrePartie.substring(0, 1).toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(
            autrePartie,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Échéance ${c.dateEcheance.day}/${c.dateEcheance.month}/${c.dateEcheance.year}',
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                c.montantFormate,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _couleurStatut(c.statut).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  c.statutAffiche,
                  style: TextStyle(
                    color: _couleurStatut(c.statut),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SegmentedRole extends StatelessWidget {
  final String role;
  final ValueChanged<String> onChanged;

  const _SegmentedRole({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE2E6E8),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(child: _tab('Mes prêts', 'preteur')),
          Expanded(child: _tab('Mes emprunts', 'emprunteur')),
        ],
      ),
    );
  }

  Widget _tab(String label, String value) {
    final selected = role == value;
    return GestureDetector(
      onTap: () => onChanged(value),
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
            color: selected ? const Color(0xFF1E3A5F) : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      currentIndex: 0,
      selectedItemColor: const Color(0xFF1E3A5F),
      unselectedItemColor: Colors.black45,
      onTap: (index) {
        if (index == 0) return;
        if (index == 1) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const NewContractScreen()));
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Écran à venir')));
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'Nouveau',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.verified_outlined),
          label: 'Solvabilité',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profil',
        ),
      ],
    );
  }
}
