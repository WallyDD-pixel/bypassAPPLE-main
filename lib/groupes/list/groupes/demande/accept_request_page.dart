import 'package:bypass/paiement/stripe_payment_service.dart';
import 'package:flutter/material.dart';
import '../../../../couleur/background_widget.dart'; // Importez votre BackgroundWidget
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AcceptRequestPage extends StatefulWidget {
  final String requestId;
  final String userId;
  final String groupId;
  final double price;

  const AcceptRequestPage({
    super.key,
    required this.requestId,
    required this.userId,
    required this.groupId,
    required this.price,
  });

  @override
  _AcceptRequestPageState createState() => _AcceptRequestPageState();
}

class _AcceptRequestPageState extends State<AcceptRequestPage> {
  Future<void> _acceptRequest(String requestId, String userId) async {
    try {
      final groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId);

      // Ajouter l'utilisateur au groupe
      await groupRef.update({
        'members.men': FieldValue.arrayUnion([
          userId,
        ]), // Ajout à la liste des membres
      });

      // Mettre à jour le statut de la demande
      final requestRef = FirebaseFirestore.instance
          .collection('groupJoinRequests')
          .doc(requestId);
      final requestSnapshot = await requestRef.get();
      final requestData = requestSnapshot.data() as Map<String, dynamic>;

      await requestRef.update({
        'status': 'accepted', // Mettre le statut à "accepted"
      });

      // Capturer le paiement
      final paymentIntentId = requestData['paymentIntentId'];
      if (paymentIntentId != null) {
        await StripeService.capturePayment(paymentIntentId);
      }

      // Calculer le montant net pour le créateur
      final double price = requestData['price'] as double;
      const double stripeFeePercentageEuropean =
          1.4; // Frais Stripe pour les cartes européennes
      const double stripeFeePercentageNonEuropean =
          2.9; // Frais Stripe pour les cartes non européennes
      const double stripeFixedFee = 0.25; // Frais fixes Stripe (en euros)
      const double platformFeePercentage = 5.0; // Frais de la plateforme

      // Supposons que vous détectez si la carte est européenne ou non
      final bool isEuropeanCard = true; // Changez cette valeur selon le cas

      // Calculer les frais Stripe
      final double stripeFeePercentage =
          isEuropeanCard
              ? stripeFeePercentageEuropean
              : stripeFeePercentageNonEuropean;

      final double stripeFee =
          (price * stripeFeePercentage / 100) + stripeFixedFee;

      // Calculer les frais de la plateforme
      final double platformFee = price * platformFeePercentage / 100;

      // Calculer le montant net pour le créateur
      final double netAmount = price - stripeFee - platformFee;

      // Ajouter le montant net au champ "solde" du créateur
      final creatorRef = FirebaseFirestore.instance
          .collection('users')
          .doc(requestData['creatorId']);

      // Vérifier si le champ "solde" existe, sinon l'initialiser à 0
      final creatorSnapshot = await creatorRef.get();
      if (!creatorSnapshot.exists ||
          !creatorSnapshot.data()!.containsKey('solde')) {
        await creatorRef.set({'solde': 0}, SetOptions(merge: true));
      }

      // Ajouter le montant net au solde
      await creatorRef.update({
        'solde': FieldValue.increment(
          netAmount,
        ), // Ajouter le montant net au solde
      });

      // Ajouter le champ "priceFee" dans la demande
      await requestRef.update({
        'priceFee': netAmount, // Enregistrer le montant net dans priceFee
      });

      // Récupérer les données du groupe
      final groupSnapshot = await groupRef.get();
      final groupData = groupSnapshot.data() as Map<String, dynamic>;

      final maxMen = groupData['maxMen'] as int? ?? 0;
      final maxWomen = groupData['maxWomen'] as int? ?? 0;

      final members = groupData['members'] as Map<String, dynamic>? ?? {};
      final menCount = (members['men'] as List?)?.length ?? 0;
      final womenCount = (members['women'] as List?)?.length ?? 0;

      // Calculer les places restantes
      final remainingMen = maxMen - menCount;
      final remainingWomen = maxWomen - womenCount;

      // Mettre à jour le champ "status" dans la collection "groups"
      await groupRef.update({
        'status':
            'Il reste $remainingMen place(s) pour les hommes et $remainingWomen place(s) pour les femmes',
      });

      // Ajouter l'utilisateur dans la collection "chats"
      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.groupId);

      // Vérifiez si le document existe
      final chatSnapshot = await chatRef.get();
      if (!chatSnapshot.exists) {
        debugPrint(
          'Le document chats/${widget.groupId} n\'existe pas. Création...',
        );
        // Créez le document avec le champ "participants"
        await chatRef.set({
          'participants': [userId], // Initialisez le tableau "participants"
          'createdAt':
              FieldValue.serverTimestamp(), // Ajoutez une date de création
          'groupId': widget.groupId, // Ajoutez l'ID du groupe
          'createdBy':
              FirebaseAuth.instance.currentUser?.uid, // Créateur du groupe
        });
      } else {
        debugPrint(
          'Le document chats/${widget.groupId} existe. Mise à jour...',
        );
        // Mettez à jour le tableau "participants" si le document existe
        await chatRef.update({
          'participants': FieldValue.arrayUnion([userId]),
        });
      }
      debugPrint('Ajout de l\'utilisateur $userId au groupe ${widget.groupId}');

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande acceptée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Retour à la page précédente
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  bool _isChecked = false; // État de la checkbox
  final int _selectedIndex = 0; // Index de la barre de navigation

  @override
  Widget build(BuildContext context) {
    // Définir les pourcentages de frais
    const double stripeFeePercentage =
        1.4; // Frais Stripe pour les cartes européennes
    const double platformFeePercentage = 5.0; // Frais de la plateforme
    const double stripeFixedFee = 0.25; // Frais fixes Stripe (en euros)

    // Calculer les frais Stripe
    final double stripeFee =
        (widget.price * stripeFeePercentage / 100) + stripeFixedFee;

    // Calculer les frais de la plateforme
    final double platformFee = widget.price * platformFeePercentage / 100;

    // Calculer le montant net pour le créateur
    final double netAmount = widget.price - stripeFee - platformFee;

    return Scaffold(
      body: Stack(
        children: [
          // Background animé
          const BackgroundWidget(),

          // Barre de navigation en haut
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              16,
              50,
              5,
              5,
            ), // Espacement pour l'AppBar
            decoration: const BoxDecoration(
              color: Colors.transparent, // Fond transparent
            ),
            child: Row(
              children: [
                // Bouton de retour
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left, // Icône de retour élégante
                    color: Colors.white, // Couleur blanche
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Retour à la page précédente
                  },
                ),
                // Texte de l'AppBar
                Text(
                  'MES GROUPES',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Contenu principal
          Padding(
            padding: const EdgeInsets.only(
              top: 100,
            ), // Ajout d'un padding en haut
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre principal
                        Card(
                          color: const Color.fromARGB(
                            0,
                            0,
                            0,
                            0,
                          ).withOpacity(0.3), // Fond transparent avec opacité
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: const Text(
                              'Êtes-vous sûr de vouloir accepter cette demande ?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Détails des frais
                        Card(
                          color: Colors.black.withOpacity(
                            0.3,
                          ), // Fond transparent avec opacité

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Détails des frais :',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDetailRow(
                                  'Prix total payé par l\'utilisateur :',
                                  '${widget.price.toStringAsFixed(2)} €',
                                  valueFontSize: 18.0,
                                ),
                                _buildDetailRow(
                                  'Frais Stripe :',
                                  '${stripeFee.toStringAsFixed(2)} €',
                                  valueFontSize: 16.0,
                                ),
                                _buildDetailRow(
                                  'Frais de la plateforme :',
                                  '${platformFee.toStringAsFixed(2)} €',
                                  valueFontSize: 16.0,
                                ),
                                _buildDetailRow(
                                  'Montant net pour le créateur :',
                                  '${netAmount.toStringAsFixed(2)} €',
                                  valueColor: Colors.green,
                                  valueFontSize: 18.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Conditions générales avec checkbox
                        Card(
                          color: Colors.black.withOpacity(
                            0.3,
                          ), // Fond transparent avec opacité

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _isChecked,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _isChecked = value ?? false;
                                        });
                                      },
                                      activeColor: Colors.green,
                                      checkColor: Colors.white,
                                    ),
                                    const Expanded(
                                      child: Text(
                                        'J\'accepte les conditions générales d\'utilisation.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    // Naviguer vers la page des conditions générales
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const TermsAndConditionsPage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Voir les conditions générales',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Boutons d'action en bas
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pop(); // Retour à la page précédente
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            _isChecked
                                ? () {
                                  _acceptRequest(
                                    widget.requestId,
                                    widget.userId,
                                  ); // Appeler la méthode pour accepter la demande
                                }
                                : null, // Désactiver le bouton si la checkbox n'est pas cochée
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Accepter',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher une ligne de détail
  Widget _buildDetailRow(
    String label,
    String value, {
    Color valueColor = Colors.white,
    double valueFontSize = 14.0,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(
          0,
          0,
          0,
          0,
        ).withOpacity(0.3), // Fond semi-transparent
        borderRadius: BorderRadius.circular(8), // Coins arrondis
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 12.0,
      ), // Espacement interne
      margin: const EdgeInsets.symmetric(vertical: 4.0), // Espacement externe
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              color: valueColor,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// Page des conditions générales (à personnaliser)
class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conditions générales'),
        backgroundColor: Colors.black,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Voici les conditions générales d\'utilisation...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      backgroundColor: Colors.black87,
    );
  }
}
