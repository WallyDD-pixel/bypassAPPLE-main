import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert'; // Import for jsonEncode

class QRCodePage extends StatefulWidget {
  final String groupId;
  final String eventId;
  final String requestId;
  final String userId;
  final String qrCodeId; // Identifiant unique pour le QR Code

  const QRCodePage({
    super.key,
    required this.groupId,
    required this.eventId,
    required this.requestId,
    required this.userId,
    required this.qrCodeId,
  });

  @override
  State<QRCodePage> createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage>
    with SingleTickerProviderStateMixin {
  String? qrData; // Données à afficher dans le QR code
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialiser l'animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Démarrer l'animation
    _animationController.repeat(reverse: true);

    // Générer les données du QR Code
    _generateQrData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _generateQrData() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint('Utilisateur non connecté.');
      return;
    }

    // Encoder les données dans un JSON valide
    final qrContent = jsonEncode({
      'userId': user.uid,
      'groupId': widget.groupId,
      'eventId': widget.eventId,
      'qrCodeId': widget.qrCodeId, // Inclure l'identifiant unique
      'requestId': widget.requestId,
    });

    setState(() {
      qrData = qrContent; // Utiliser le JSON encodé comme contenu du QR code
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mon QR Code',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Arrière-plan stylisé
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4CAF50), Color(0xFF087F23)],
              ),
            ),
          ),
          Center(
            child: StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('groupJoinRequests')
                      .doc(widget.requestId)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(color: Colors.white);
                }

                if (snapshot.hasError) {
                  return const Text(
                    'Une erreur est survenue.\nVeuillez réessayer.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text(
                    'Aucune donnée trouvée pour cette demande.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  );
                }

                final requestData =
                    snapshot.data!.data() as Map<String, dynamic>;
                final bool scanqr = requestData['scanqr'] ?? false;

                if (scanqr) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'QR Code scanné.\nVotre solde a bien été mis à jour.\nPassez une bonne soirée !',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return qrData == null
                    ? const Text(
                      'Impossible de générer le QR code.\nVeuillez réessayer.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                    : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _fadeAnimation,
                          child: QrImageView(
                            data: qrData!,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: const Text(
                            'Scannez ce QR code pour partager vos informations.',
                            style: TextStyle(
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
