import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QRCodeScanPage extends StatefulWidget {
  final String groupId;

  const QRCodeScanPage({super.key, required this.groupId});

  @override
  State<QRCodeScanPage> createState() => _QRCodeScanPageState();
}

class _QRCodeScanPageState extends State<QRCodeScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  List<String> validQrCodes = []; // Déclaration correcte de validQrCodes
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGroupJoinRequests(); // Charger les QR Codes valides pour ce groupe
  }

  Future<void> _fetchGroupJoinRequests() async {
    setState(() {
      isLoading = false; // Arrêter le chargement (pas nécessaire ici)
    });
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) async {
      final qrCode = scanData.code;

      if (qrCode != null) {
        debugPrint('QR Code scanné : $qrCode');
        controller.pauseCamera();

        // Vérifier si le QR Code est valide pour ce groupe
        await _validateQrCode(qrCode);
      } else {
        debugPrint('QR Code invalide ou vide.');
      }
    });
  }

  Future<void> _validateQrCode(String qrCode) async {
    try {
      // Rechercher le document correspondant au QR Code scanné
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('groupJoinRequests')
              .where('qrId', isEqualTo: qrCode)
              .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('Aucun document trouvé pour ce QR Code.');
        _showErrorDialog('QR Code invalide ou non lié à ce groupe.');
        controller?.resumeCamera();
        return;
      }

      final requestData = querySnapshot.docs.first.data();
      final String creatorId = requestData['creatorId'] ?? '';
      final String groupId = requestData['groupId'] ?? '';

      // Vérifier si l'utilisateur connecté est le créateur du groupe
      final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      if (creatorId != currentUserId) {
        debugPrint('L\'utilisateur scannant n\'est pas le créateur du groupe.');
        _showErrorDialog('Vous n\'êtes pas autorisé à scanner ce QR Code.');
        controller?.resumeCamera();
        return;
      }

      // Vérifier si le QR Code appartient au groupe géré par l'utilisateur
      if (groupId != widget.groupId) {
        debugPrint('Le QR Code scanné n\'appartient pas à ce groupe.');
        _showErrorDialog('Ce QR Code n\'appartient pas à ce groupe.');
        controller?.resumeCamera();
        return;
      }

      // Si tout est valide
      debugPrint('QR Code valide pour ce groupe.');
      _handleValidQrCode(qrCode);
    } catch (e) {
      debugPrint('Erreur lors de la validation du QR Code : $e');
      _showErrorDialog('Une erreur est survenue lors de la validation.');
      controller?.resumeCamera();
    }
  }

  void _handleValidQrCode(String qrCode) async {
    try {
      // Étape 1 : Rechercher le document correspondant au QR Code scanné
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('groupJoinRequests')
              .where('qrId', isEqualTo: qrCode)
              .get();

      if (querySnapshot.docs.isEmpty) {
        // Si aucun document n'est trouvé
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Erreur'),
                content: const Text(
                  'Aucun utilisateur trouvé pour ce QR Code.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      controller?.resumeCamera();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
        return;
      }

      // Étape 2 : Récupérer le userId du document trouvé
      final requestData = querySnapshot.docs.first.data();
      final String userId = requestData['userId'] ?? '';

      if (userId.isEmpty) {
        // Si le userId est vide ou null
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Erreur'),
                content: const Text('Aucun utilisateur associé à ce QR Code.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      controller?.resumeCamera();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
        return;
      }

      // Étape 3 : Rechercher les informations de l'utilisateur dans la collection 'users'
      final userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (!userSnapshot.exists) {
        // Si l'utilisateur n'existe pas
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Erreur'),
                content: const Text('Utilisateur introuvable.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      controller?.resumeCamera();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
        return;
      }

      // Étape 4 : Récupérer les informations de l'utilisateur
      final userData = userSnapshot.data() as Map<String, dynamic>;
      final String userName = userData['username'] ?? 'Nom inconnu';
      final String userEmail = userData['email'] ?? 'Email inconnu';

      // Afficher les informations de l'utilisateur dans une boîte de dialogue
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // Bordures arrondies
              ),
              backgroundColor: Colors.white, // Couleur de fond
              title: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green, // Icône verte pour indiquer le succès
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Succès',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.green, // Titre en vert
                    ),
                  ),
                ],
              ),
              content: Text(
                'Le QR Code de $userName a été scanné avec succès !',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87, // Texte en noir
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    controller?.resumeCamera();
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green, // Bouton en vert
                    ),
                  ),
                ),
              ],
            ),
      );
    } catch (e) {
      // Gestion des erreurs
      debugPrint(
        'Erreur lors de la récupération des informations utilisateur : $e',
      );
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Erreur'),
              content: const Text(
                'Une erreur est survenue lors de la récupération des informations utilisateur.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    controller?.resumeCamera();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Erreur'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scanner QR Code',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.green,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 300,
            ),
          ),
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}
