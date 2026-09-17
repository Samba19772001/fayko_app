import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

/// Upload des photos de CNI recto/verso (§3.2). Fait passer le compte en
/// "en_attente" jusqu'à validation par un agent via le panneau admin.
class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> {
  final _picker = ImagePicker();

  XFile? _recto;
  XFile? _verso;
  Uint8List? _rectoBytes;
  Uint8List? _versoBytes;

  bool _envoiEnCours = false;
  String? _erreur;
  String? _succes;

  static const _indigo = Color(0xFF1E3A5F);

  Future<void> _choisirPhoto({required bool estRecto}) async {
    final fichier = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (fichier == null) return;
    final bytes = await fichier.readAsBytes();
    setState(() {
      if (estRecto) {
        _recto = fichier;
        _rectoBytes = bytes;
      } else {
        _verso = fichier;
        _versoBytes = bytes;
      }
    });
  }

  Future<void> _envoyer() async {
    if (_recto == null || _verso == null) {
      setState(() => _erreur = "Merci d'ajouter les deux photos (recto et verso).");
      return;
    }

    setState(() {
      _envoiEnCours = true;
      _erreur = null;
      _succes = null;
    });

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/auth/verification-identite');
      final request = http.MultipartRequest('POST', uri);

      final storage = ApiService();
      final token = await storage.debugToken();
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.files.add(http.MultipartFile.fromBytes('cni_recto', _rectoBytes!, filename: 'recto.jpg'));
      request.files.add(http.MultipartFile.fromBytes('cni_verso', _versoBytes!, filename: 'verso.jpg'));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final decoded = jsonDecode(body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        setState(() => _succes = decoded['message']);
        await context.read<AuthProvider>().chargerSessionExistante();
      } else {
        setState(() => _erreur = decoded['message'] ?? "Une erreur est survenue.");
      }
    } catch (_) {
      setState(() => _erreur = "Impossible de contacter le serveur.");
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F7),
      appBar: AppBar(
        backgroundColor: _indigo,
        title: const Text("Vérification d'identité"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user?.estEnAttente == true)
              _bandeau(
                "Vos documents sont en cours de validation par un agent. Vous recevrez une notification une fois la vérification terminée.",
                background: const Color(0xFFF6EDDA),
                couleurTexte: const Color(0xFFB8862B),
              )
            else ...[
              const Text(
                "Pour vérifier votre identité, ajoutez une photo claire du recto et du verso de votre CNI.",
                style: TextStyle(color: Colors.black54, fontSize: 13.5),
              ),
              const SizedBox(height: 22),
              _photoField(label: 'Recto de la CNI', bytes: _rectoBytes, onTap: () => _choisirPhoto(estRecto: true)),
              const SizedBox(height: 18),
              _photoField(label: 'Verso de la CNI', bytes: _versoBytes, onTap: () => _choisirPhoto(estRecto: false)),
              if (_erreur != null) ...[
                const SizedBox(height: 16),
                _bandeau(_erreur!, background: const Color(0xFFF5E4E0), couleurTexte: const Color(0xFFA6402F)),
              ],
              if (_succes != null) ...[
                const SizedBox(height: 16),
                _bandeau(_succes!, background: const Color(0xFFE4F1EC), couleurTexte: const Color(0xFF1F7A66)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _envoiEnCours ? null : _envoyer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _envoiEnCours
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Envoyer pour validation'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bandeau(String message, {required Color background, required Color couleurTexte}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Text(message, style: TextStyle(color: couleurTexte, fontSize: 13)),
    );
  }

  Widget _photoField({required String label, required Uint8List? bytes, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
            ),
            child: bytes == null
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: Colors.black38, size: 28),
                        SizedBox(height: 8),
                        Text('Ajouter une photo', style: TextStyle(color: Colors.black45, fontSize: 12.5)),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  ),
          ),
        ),
      ],
    );
  }
}