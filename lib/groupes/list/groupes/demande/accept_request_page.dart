import 'package:bypass/paiement/stripe_payment_service.dart';
import 'package:flutter/material.dart';
import '../../../../couleur/background_widget.dart';
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
  Future<void> _acceptRequest(
    String requestId,
    String userId,
    double netAmount,
  ) async {
    try {
      debugPrint(
        'Recherche du document dans groupJoinRequests pour requestId: $requestId et userId: $userId',
      );

      // Rechercher le document correspondant à requestId
      final docRef = FirebaseFirestore.instance
          .collection('groupJoinRequests')
          .doc(requestId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        debugPrint('Aucun document trouvé pour requestId: $requestId');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur : Document introuvable.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Mettre à jour le statut
      await docRef.update({'status': 'accepted'});

      debugPrint('Statut mis à jour avec succès pour requestId: $requestId');

      // Récupérer les informations de l'utilisateur
      final userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (!userSnapshot.exists) {
        debugPrint('Utilisateur introuvable pour userId: $userId');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur : Utilisateur introuvable.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userData = userSnapshot.data()!;
      final sexe = userData['sexe'] ?? 'unknown';

      if (sexe != 'homme') {
        debugPrint('L\'utilisateur n\'est pas un homme.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur : Cet utilisateur n\'est pas un homme.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Ajouter l'utilisateur dans le groupe
      final groupId = docSnapshot.data()?['groupId'];
      if (groupId == null) {
        debugPrint('GroupId introuvable dans le document.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur : GroupId introuvable.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId);
      final groupSnapshot = await groupRef.get();

      if (!groupSnapshot.exists) {
        debugPrint('Groupe introuvable pour groupId: $groupId');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur : Groupe introuvable.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final groupData = groupSnapshot.data()!;
      final members = groupData['members'] as Map<String, dynamic>? ?? {};
      final men = (members['men'] as List<dynamic>? ?? []).length;
      final maxMen = groupData['maxMen'] as int? ?? 0;

      // Vérifier la limite des hommes
      if (men >= maxMen) {
        debugPrint('Le groupe a déjà atteint le nombre maximum d\'hommes');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur : Le groupe a déjà assez d\'hommes.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Ajouter l'utilisateur dans la liste des hommes
      debugPrint('Ajout de l\'utilisateur dans la liste des hommes');
      await groupRef.update({
        'members.men': FieldValue.arrayUnion([userId]),
      });

      debugPrint('Utilisateur ajouté avec succès dans le groupe');

      // Enregistrer la valeur de netAmount dans le champ prixnet
      debugPrint('Enregistrement de netAmount : $netAmount');
      await docRef.update({'prixnet': netAmount});

      debugPrint('netAmount enregistré avec succès dans le document.');

      // Ajouter l'utilisateur au chat du groupe
      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(groupId);
      final chatSnapshot = await chatRef.get();

      if (!chatSnapshot.exists) {
        // Si le chat n'existe pas encore, le créer
        await chatRef.set({
          'groupId': groupId,
          'createdAt': FieldValue.serverTimestamp(),
          'members': [userId],
        });
        debugPrint('Chat créé pour le groupe : $groupId');
      } else {
        // Ajouter l'utilisateur à la liste des membres du chat
        await chatRef.update({
          'members': FieldValue.arrayUnion([userId]),
        });
        debugPrint('Utilisateur ajouté au chat du groupe : $groupId');
      }

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Utilisateur accepté et ajouté au groupe et au chat avec succès !',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Retour à la page précédente
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint(
        'Erreur lors de la mise à jour du statut ou de l\'ajout au groupe/chat : $e',
      );
      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  bool _isChecked = false; // État de la checkbox

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

    // Calculer les frais totaux (Stripe + plateforme)
    final double totalFees = stripeFee + platformFee;

    // Calculer le montant net pour le créateur
    final double netAmount = widget.price - totalFees;

    return Scaffold(
      body: Stack(
        children: [
          // Background animé
          const BackgroundWidget(),

          // Barre de navigation en haut
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 50, 5, 5),
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
            padding: const EdgeInsets.only(top: 100),
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
                          color: Colors.black.withOpacity(0.3),
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
                          color: Colors.black.withOpacity(0.3),
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
                                const SizedBox(height: 16),

                                // Utilisation d'une table pour aligner les textes et les chiffres
                                Table(
                                  columnWidths: const {
                                    0: FlexColumnWidth(2),
                                    1: FlexColumnWidth(1),
                                  },
                                  children: [
                                    _buildTableRow(
                                      'Prix total payé par l\'utilisateur :',
                                      '${widget.price.toStringAsFixed(2)} €',
                                    ),
                                    _buildTableRow(
                                      'Frais totaux (Stripe + plateforme) :',
                                      '${totalFees.toStringAsFixed(2)} €',
                                    ),
                                    _buildTableRow(
                                      'Montant net pour le créateur :',
                                      '${netAmount.toStringAsFixed(2)} €',
                                      valueColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Conditions générales avec checkbox
                        Card(
                          color: Colors.black.withOpacity(0.3),
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
                                    netAmount,
                                  );
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

  // Widget pour construire une ligne de la table
  TableRow _buildTableRow(
    String label,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
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
