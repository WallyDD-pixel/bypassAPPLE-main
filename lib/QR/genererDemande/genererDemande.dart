import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../couleur/background_widget.dart'; // Importer le widget d'arrière-plan animé

class QRCodePage extends StatefulWidget {
  final String groupId;
  final String
  userId; // ID de l'utilisateur pour identifier la demande existante

  const QRCodePage({super.key, required this.groupId, required this.userId});

  @override
  State<QRCodePage> createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  String? qrId; // Identifiant unique pour le QR Code
  bool hasShownDialog =
      false; // Pour éviter d'afficher plusieurs fois le dialogue
  bool hasUpdatedBalance =
      false; // Pour éviter d'incrémenter plusieurs fois balancetotal

  @override
  void initState() {
    super.initState();
    _generateOrUpdateQrCode(); // Générer ou mettre à jour le QR Code
  }

  Future<void> _generateOrUpdateQrCode() async {
    try {
      // Rechercher la demande existante dans Firestore
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('groupJoinRequests')
              .where('groupId', isEqualTo: widget.groupId)
              .where('userId', isEqualTo: widget.userId)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Si une demande existe, récupérer son ID et ses données
        final doc = querySnapshot.docs.first;
        final docId = doc.id;
        final data = doc.data();

        // Récupérer ou générer un QR Code
        final existingQrId = data['qrId'];
        if (existingQrId != null && existingQrId.isNotEmpty) {
          // Si un QR Code existe déjà, l'utiliser
          setState(() {
            qrId = existingQrId;
          });
          debugPrint('QR Code existant trouvé : $existingQrId');
        } else {
          // Sinon, générer un nouvel identifiant unique pour le QR Code
          final uniqueQrId = const Uuid().v4();
          await FirebaseFirestore.instance
              .collection('groupJoinRequests')
              .doc(docId)
              .update({
                'qrId': uniqueQrId,
                'isScanned': false, // Initialiser à false
                'updatedAt':
                    FieldValue.serverTimestamp(), // Ajouter une date de mise à jour
              });

          setState(() {
            qrId = uniqueQrId;
          });
          debugPrint('Nouveau QR Code généré : $uniqueQrId');
        }
      } else {
        debugPrint(
          'Aucune demande existante trouvée pour ce groupe et cet utilisateur.',
        );
      }
    } catch (e) {
      debugPrint(
        'Erreur lors de la mise à jour ou de la récupération de la demande : $e',
      );
    }
  }

  void _updateBalanceIfNeeded(double prixNet) async {
    if (hasUpdatedBalance) return; // Empêcher plusieurs mises à jour

    try {
      final groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId);
      final groupSnapshot = await groupRef.get();

      if (groupSnapshot.exists) {
        final groupData = groupSnapshot.data() as Map<String, dynamic>;
        final double currentBalance =
            groupData['balancetotal'] as double? ?? 0.0;

        // Ajouter prixNet au champ balancetotal
        final double updatedBalance = currentBalance + prixNet;

        await groupRef.update({'balancetotal': updatedBalance});
        debugPrint('Balance totale mise à jour : $updatedBalance');
      } else {
        // Si le document du groupe n'existe pas, le créer avec balancetotal
        await groupRef.set({'balancetotal': prixNet});
        debugPrint('Balance totale initialisée avec : $prixNet');
      }

      hasUpdatedBalance = true; // Marquer comme mis à jour
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de balancetotal : $e');
    }
  }

  void _showSuccessDialog() {
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
            content: const Text(
              'Vous avez bien été scanné avec succès !',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87, // Texte en noir
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QR Code',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent, // Rendre l'AppBar transparente
        elevation: 0,
      ),
      extendBodyBehindAppBar: true, // Étendre le corps derrière l'AppBar
      body: Stack(
        children: [
          const BackgroundWidget(), // Ajouter l'arrière-plan animé
          Center(
            child:
                qrId == null
                    ? const CircularProgressIndicator(
                      color: Colors.white,
                    ) // Afficher un indicateur de chargement pendant la mise à jour
                    : StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('groupJoinRequests')
                          .where('groupId', isEqualTo: widget.groupId)
                          .where('userId', isEqualTo: widget.userId)
                          .snapshots()
                          .map((snapshot) => snapshot.docs.first),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator(
                            color: Colors.white,
                          );
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Text(
                            'Erreur lors du chargement des données.',
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final bool isScanned = data['isScanned'] ?? false;
                        final double prixNet =
                            data['prixnet'] as double? ?? 0.0;

                        // Si le QR code est scanné, mettre à jour le champ balancetotal dans la collection groups
                        if (isScanned && !hasShownDialog) {
                          hasShownDialog =
                              true; // Empêcher plusieurs affichages
                          WidgetsBinding.instance.addPostFrameCallback((
                            _,
                          ) async {
                            try {
                              final docRef = FirebaseFirestore.instance
                                  .collection('groupJoinRequests')
                                  .where('groupId', isEqualTo: widget.groupId)
                                  .where('userId', isEqualTo: widget.userId);

                              final querySnapshot = await docRef.get();
                              if (querySnapshot.docs.isNotEmpty) {
                                final doc = querySnapshot.docs.first;
                                final data = doc.data() as Map<String, dynamic>;

                                // Vérifiez si `balanceUpdated` est déjà `true`
                                final bool balanceUpdated =
                                    data['balanceUpdated'] ?? false;

                                if (!balanceUpdated) {
                                  final groupRef = FirebaseFirestore.instance
                                      .collection('groups')
                                      .doc(widget.groupId);

                                  final groupSnapshot = await groupRef.get();

                                  if (groupSnapshot.exists) {
                                    final groupData =
                                        groupSnapshot.data()
                                            as Map<String, dynamic>;
                                    final double currentBalance =
                                        groupData['balancetotal'] as double? ??
                                        0.0;

                                    // Ajouter prixNet au champ balancetotal
                                    final double updatedBalance =
                                        currentBalance + prixNet;

                                    await groupRef.update({
                                      'balancetotal': updatedBalance,
                                    });
                                    debugPrint(
                                      'Balance totale mise à jour : $updatedBalance',
                                    );
                                  } else {
                                    // Si le document du groupe n'existe pas, le créer avec balancetotal
                                    await groupRef.set({
                                      'balancetotal': prixNet,
                                    });
                                    debugPrint(
                                      'Balance totale initialisée avec : $prixNet',
                                    );
                                  }

                                  // Marquer `balanceUpdated` comme `true` dans le document `groupJoinRequests`
                                  await doc.reference.update({
                                    'balanceUpdated': true,
                                  });
                                  debugPrint(
                                    'Champ balanceUpdated mis à jour à true.',
                                  );
                                } else {
                                  debugPrint(
                                    'La balance a déjà été mise à jour pour ce QR code.',
                                  );
                                }
                              }

                              // Afficher le dialogue de succès
                              _showSuccessDialog();
                            } catch (e) {
                              debugPrint(
                                'Erreur lors de la mise à jour de balancetotal : $e',
                              );
                            }
                          });
                        }

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Conteneur pour le QR Code avec un style amélioré
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data:
                                    qrId!, // Les données à encoder dans le QR Code
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Texte d'instruction
                            Text(
                              'Scannez ce QR Code pour accéder au groupe',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            // Statut du QR Code
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isScanned
                                        ? Colors.green.shade600
                                        : Colors.red.shade600,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isScanned
                                    ? 'Le QR Code a été scanné.'
                                    : 'Le QR Code n\'a pas encore été scanné.',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
