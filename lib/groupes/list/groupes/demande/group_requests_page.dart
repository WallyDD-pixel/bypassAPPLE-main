  import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bypass/paiement/stripe_payment_service.dart';
import 'accept_request_page.dart';
import '../../../../couleur/background_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupRequestsPage extends StatelessWidget {
  final String groupId;
  

  const GroupRequestsPage({super.key, required this.groupId});

  Future<void> _acceptRequest(String requestId, String userId) async {
    try {
      final groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId);

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
    } catch (e) {
      print('Erreur lors de l\'acceptation de la demande : $e');
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      // Supprimer la demande
      await FirebaseFirestore.instance
          .collection('groupJoinRequests')
          .doc(requestId)
          .delete();
    } catch (e) {
      print('Erreur lors du refus de la demande : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background animé
          const BackgroundWidget(),

          // Contenu principal
          Column(
            children: [
              // Barre personnalisée
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
                decoration: const BoxDecoration(
                  color: Colors.transparent, // Fond transparent
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(
                        0,
                        0,
                        0,
                        0,
                      ), // Ombre pour un effet de profondeur
                      offset: Offset(0, 2), // Décalage de l'ombre
                      blurRadius: 4, // Flou de l'ombre
                    ),
                  ],
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
                        Navigator.of(
                          context,
                        ).pop(); // Retour à la page précédente
                      },
                    ),
                    // Texte de l'AppBar
                    Text(
                      'DEMANDE EN ATTENTE',
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
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('groupJoinRequests')
                          .where('groupId', isEqualTo: groupId)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Une erreur est survenue',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final requests = snapshot.data?.docs ?? [];

                    if (requests.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucune demande pour ce groupe',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        final data = request.data() as Map<String, dynamic>;

                        return FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(data['userId'])
                                  .get(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (userSnapshot.hasError ||
                                !userSnapshot.hasData) {
                              return const Center(
                                child: Text(
                                  'Erreur lors du chargement des informations utilisateur',
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            }

                            final userData =
                                userSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            final userName =
                                userData['username'] ?? 'Nom inconnu';
                            final userPhoto = userData['photoURL'];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: const Color.fromARGB(0, 33, 33, 33),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Photo de l'utilisateur
                                        if (userPhoto != null)
                                          ClipOval(
                                            child: Image.network(
                                              userPhoto,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        else
                                          const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        const SizedBox(width: 16),

                                        // Nom de l'utilisateur
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                userName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Statut : ${data['status']}',
                                                style: TextStyle(
                                                  color:
                                                      data['status'] ==
                                                              'pending'
                                                          ? Colors.orange
                                                          : Colors.green,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Explications
                                    const Text(
                                      'Explications :',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '1. Si vous acceptez, l\'utilisateur sera ajouté au groupe et le paiement sera capturé.',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '2. Si vous refusez, la demande sera supprimée et aucun paiement ne sera effectué.',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    const SizedBox(height: 16),

                                    // Boutons d'action
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (data['status'] == 'pending') ...[
                                          // Bouton Accepter
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => AcceptRequestPage(
                                                        requestId: request.id,
                                                        userId: data['userId'],
                                                        groupId: groupId,
                                                        price: data['price'],
                                                      ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                            ),
                                            label: const Text('Accepter'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                          // Bouton Refuser
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              _rejectRequest(
                                                request.id,
                                              ); // Appeler la méthode pour rejeter la demande
                                            },
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                            ),
                                            label: const Text('Refuser'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ] else ...[
                                          // Message si la demande est déjà acceptée
                                          const Text(
                                            'Demande déjà acceptée',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}