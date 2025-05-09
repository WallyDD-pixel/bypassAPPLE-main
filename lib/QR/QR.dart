import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:convert'; // Pour décoder les données JSON
import 'package:firebase_auth/firebase_auth.dart';
import '../home_page.dart'; // Remplacez par le chemin de votre page d'accueil
import 'dart:async'; // Pour utiliser Timer et Future.delayed

class QRCodeScanPage extends StatefulWidget {
  const QRCodeScanPage({super.key});

  @override
  State<QRCodeScanPage> createState() => _QRCodeScanPageState();
}

class _QRCodeScanPageState extends State<QRCodeScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isLoading = false; // Indique si une recherche est en cours
  bool isConfirmed = false; // Indique si l'inscription est confirmée
  String? confirmationMessage; // Message de confirmation
  bool isProcessing = false; // Empêche les détections multiples
  int countdown = 5; // Initialiser le compte à rebours à 5 secondes
  Timer? countdownTimer;

  @override
  void dispose() {
    countdownTimer?.cancel(); // Annuler le timer si la page est fermée
    controller?.dispose();
    super.dispose();
  }

  void _startCountdownAndRedirect() {
    countdown = 5; // Réinitialiser le compte à rebours à 5 secondes
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 1) {
        setState(() {
          countdown--; // Réduire le compte à rebours
          confirmationMessage =
              'Bonne soirée, votre inscription est confirmée.\nVous serez redirigé vers la page d\'accueil dans $countdown secondes.';
        });
      } else {
        timer.cancel(); // Arrêter le timer
        _redirectToHomePage(); // Rediriger vers la page d'accueil
      }
    });
  }

  void _redirectToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    ); // Rediriger vers la page d'accueil
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) async {
      if (isProcessing) return; // Empêche les détections multiples
      isProcessing = true;

      final qrCode = scanData.code;

      if (qrCode != null) {
        debugPrint('Contenu brut du QR Code : $qrCode');

        try {
          // Décoder les données JSON
          final decodedData = jsonDecode(qrCode);

          final String userId = decodedData['userId'];
          final String groupId = decodedData['groupId'];
          final String eventId = decodedData['eventId'];

          debugPrint('User ID : $userId');
          debugPrint('Group ID : $groupId');
          debugPrint('Event ID : $eventId');

          // Rechercher dans Firestore
          await _checkGroupJoinRequest(groupId, eventId, qrCode);

          // Arrêter la caméra après avoir scanné
          controller.pauseCamera();
        } catch (e) {
          debugPrint('Erreur lors du décodage des données QR Code : $e');
        } finally {
          isProcessing = false; // Réinitialise l'état après traitement
        }
      }
    });
  }

  Future<void> _checkGroupJoinRequest(
    String groupId,
    String eventId,
    String qrCode, // Le contenu brut du QR Code scanné
  ) async {
    setState(() {
      isLoading = true; // Démarre le chargement
      isConfirmed = false; // Réinitialise la confirmation
      confirmationMessage = null;
    });

    try {
      // Décoder le contenu du QR Code scanné
      final decodedQrCode = jsonDecode(qrCode);
      final String qrCodeIdScanned = decodedQrCode['qrCodeId'] ?? '';
      debugPrint('QR Code ID extrait du QR Code scanné : $qrCodeIdScanned');

      // Récupérer l'utilisateur connecté
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('Erreur : Aucun utilisateur connecté.');
        setState(() {
          isConfirmed = false;
          confirmationMessage = 'Erreur : Aucun utilisateur connecté.';
        });
        return;
      }

      final currentUserId = currentUser.uid;
      debugPrint('User ID de l\'utilisateur connecté : $currentUserId');
      debugPrint('Group ID scanné : $groupId');
      debugPrint('Event ID scanné : $eventId');

      // Rechercher dans la collection groupJoinRequests pour l'utilisateur connecté
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('groupJoinRequests')
              .where(
                'userId',
                isEqualTo: currentUserId,
              ) // Vérifier l'utilisateur connecté
              .where('groupId', isEqualTo: groupId)
              .where('eventId', isEqualTo: eventId)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        debugPrint('Correspondance trouvée dans groupJoinRequests.');

        // Récupérer l'ID du document correspondant
        final docId = querySnapshot.docs.first.id;

        // Récupérer les données du document correspondant
        final docData = querySnapshot.docs.first.data();
        final String qrCodeIdFromFirestore = docData['qrCodeId'] ?? '';
        final String userIdFromFirestore = docData['userId'] ?? '';
        final String groupIdFromFirestore = docData['groupId'] ?? '';
        final String eventIdFromFirestore = docData['eventId'] ?? '';

        // Afficher les valeurs pour le débogage
        debugPrint('User ID dans Firestore : $userIdFromFirestore');
        debugPrint('Group ID dans Firestore : $groupIdFromFirestore');
        debugPrint('Event ID dans Firestore : $eventIdFromFirestore');
        debugPrint('QR Code ID dans Firestore : $qrCodeIdFromFirestore');

        // Vérifier si l'userId correspond à l'utilisateur connecté
        if (userIdFromFirestore != currentUserId) {
          debugPrint(
            'Erreur : L\'userId dans groupJoinRequests ne correspond pas à l\'utilisateur connecté.',
          );
          setState(() {
            isConfirmed = false;
            confirmationMessage =
                'Erreur : Ce QR Code n\'est pas valide pour votre demande.';
          });
          return;
        }

        debugPrint(
          'Correspondance trouvée : l\'userId de l\'utilisateur connecté correspond à celui de Firestore.',
        );

        // Vérifier si le QR Code scanné correspond à celui dans Firestore
        if (qrCodeIdFromFirestore != qrCodeIdScanned) {
          debugPrint('QR Code ID scanné : $qrCodeIdScanned');
          debugPrint('QR Code ID dans Firestore : $qrCodeIdFromFirestore');
          debugPrint(
            'Erreur : Le QR Code scanné ne correspond pas à celui dans Firestore.',
          );
          setState(() {
            isConfirmed = false;
            confirmationMessage =
                'Erreur : Ce QR Code n\'est pas valide pour votre demande.';
          });
          return;
        }

        debugPrint(
          'Succès : Le QR Code scanné correspond à celui dans Firestore.',
        );

        // Vérifier si le champ scanqr est déjà à true
        final bool scanqr = docData['scanqr'] ?? false;

        if (!scanqr) {
          try {
            // Mettre à jour le champ scanqr à true pour le document correspondant
            await FirebaseFirestore.instance
                .collection('groupJoinRequests')
                .doc(docId)
                .update({'scanqr': true}); // Mettre à jour le champ scanqr

            debugPrint(
              'Champ scanqr mis à jour à true pour le document : $docId',
            );

            // Incrémenter le champ soldeReel dans la collection users
            final double incrementValue = docData['priceFee'] ?? 0.0;
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .update({'soldeReel': FieldValue.increment(incrementValue)});

            debugPrint(
              'Champ soldeReel incrémenté de $incrementValue pour l\'utilisateur : $currentUserId',
            );

            setState(() {
              isConfirmed = true;
              confirmationMessage =
                  'Bonne soirée, votre inscription est confirmée.\nVous serez redirigé vers la page d\'accueil dans $countdown secondes.';
            });

            _startCountdownAndRedirect(); // Démarrer le compte à rebours
          } catch (e) {
            debugPrint('Erreur lors de la mise à jour : $e');
            setState(() {
              isConfirmed = false;
              confirmationMessage = 'Erreur lors de la mise à jour.';
            });
          }
        } else {
          debugPrint(
            'Le champ scanqr est déjà à true. Aucune action supplémentaire.',
          );
          setState(() {
            isConfirmed = false;
            confirmationMessage =
                'Cette inscription a déjà été confirmée.\nVous serez redirigé vers la page d\'accueil dans $countdown secondes.';
          });

          _startCountdownAndRedirect(); // Démarrer le compte à rebours
        }
      } else {
        debugPrint('Aucune correspondance trouvée.');
        setState(() {
          isConfirmed = false;
          confirmationMessage = 'Aucune correspondance trouvée.';
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la recherche dans Firestore : $e');
      setState(() {
        isConfirmed = false;
        confirmationMessage = 'Erreur lors de la recherche.';
      });
    } finally {
      setState(() {
        isLoading = false; // Arrête le chargement
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan QR Code',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          // Section de scan QR code
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
          // Section des résultats
          if (isLoading || confirmationMessage != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.grey.shade900,
                padding: const EdgeInsets.all(16),
                child:
                    isLoading
                        ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : Card(
                          color:
                              isConfirmed
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              confirmationMessage ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
              ),
            ),
        ],
      ),
    );
  }
}
