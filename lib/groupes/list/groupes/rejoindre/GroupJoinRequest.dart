import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';
import '../../../../paiement/stripe_payment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bypass/groupes/list/groupes/rejoindre/join_group.dart';
import '../rejoindre/Felicitation/succes.dart';

class GroupJoinRequest extends StatelessWidget {
  final String groupId;
  final String eventId;
  final String creatorId;
  final num price;

  const GroupJoinRequest({
    super.key,
    required this.groupId,
    required this.eventId,
    required this.creatorId,
    required this.price,
  });

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date inconnue';
    return DateFormat('dd/MM/yyyy à HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text('Détails du groupe'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Informations de l'événement
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('events')
                      .doc(eventId)
                      .snapshots(),
              builder: (context, eventSnapshot) {
                if (!eventSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                }

                final eventData =
                    eventSnapshot.data?.data() as Map<String, dynamic>?;

                return Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eventData?['imageUrl'] != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: eventData!['imageUrl'],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.green,
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white54,
                                  size: 50,
                                ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eventData?['name'] ?? 'Événement',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              eventData?['description'] ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  eventData?['location'] ??
                                      'Localisation inconnue',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.business,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  eventData?['etablissement'] ??
                                      'Établissement inconnu',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  eventData?['date'] != null
                                      ? DateFormat(
                                        'dd MMMM yyyy à HH:mm',
                                      ).format(
                                        (eventData!['date'] as Timestamp)
                                            .toDate(),
                                      )
                                      : 'Date inconnue',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Informations du créateur
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(creatorId)
                      .snapshots(),
              builder: (context, creatorSnapshot) {
                if (!creatorSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                }

                final creatorData =
                    creatorSnapshot.data?.data() as Map<String, dynamic>?;
                final username =
                    creatorData?['username'] ?? 'Utilisateur inconnu';
                final photoURL = creatorData?['photoURL'];

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      if (photoURL != null)
                        Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: CachedNetworkImage(
                              imageUrl: photoURL,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.green,
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Demande pour rejoindre le groupe de ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Card explicative
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Comment ça marche ?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Vous allez faire une demande pour rejoindre le groupe.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '2. Le paiement est autorisé mais ne sera pas prélevé immédiatement.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '3. Si votre demande est acceptée, le paiement sera prélevé.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '4. Si votre demande est refusée, l’autorisation de prélèvement sera annulée.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Prix et bouton de paiement
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Prix : ',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      Text(
                        '${price.toString()}€',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          // Vérifiez que la variable price est définie et non nulle
                          if (price <= 0) {
                            throw Exception(
                              "Le prix est invalide ou non défini.",
                            );
                          }

                          // Récupérer l'ID de l'utilisateur connecté
                          final String? userId =
                              FirebaseAuth.instance.currentUser?.uid;
                          if (userId == null) {
                            throw Exception("Utilisateur non connecté.");
                          }

                          // Montant dynamique basé sur le prix
                          final int amount =
                              (price * 100).toInt(); // Convertir en centimes
                          const String currency = 'eur'; // Devise

                          // Créer un PaymentIntent avec pré-autorisation
                          final paymentIntent =
                              await StripeService.createPaymentIntent(
                                (price * 100)
                                    .toInt()
                                    .toString(), // Convertir en centimes et en entier
                                'eur', // Devise
                              );
                          final paymentIntentId = paymentIntent['id'];

                          // Initialiser la feuille de paiement
                          await Stripe.instance.initPaymentSheet(
                            paymentSheetParameters: SetupPaymentSheetParameters(
                              paymentIntentClientSecret:
                                  paymentIntent['client_secret'],
                              merchantDisplayName: 'Votre Application',
                              style: ThemeMode.light,
                            ),
                          );

                          // Présenter la feuille de paiement
                          await Stripe.instance.presentPaymentSheet();

                          // Enregistrer la demande dans Firestore
                          await createJoinRequest(
                            groupId: groupId,
                            eventId: eventId,
                            creatorId: creatorId,
                            price:
                                price.toDouble(), // Convertir price en double
                            userId:
                                userId, // Utiliser l'ID de l'utilisateur connecté
                            paymentIntentId:
                                paymentIntentId, // Ajouter le PaymentIntentId
                          );

                          // Récupérer les informations depuis Firebase
                          final eventSnapshot =
                              await FirebaseFirestore.instance
                                  .collection('events')
                                  .doc(eventId)
                                  .get();
                          final eventData =
                              eventSnapshot.data();

                          final location =
                              eventData?['location'] ?? 'Lieu inconnu';
                          final arrivalTime =
                              eventData?['date'] != null
                                  ? DateFormat('dd MMMM yyyy à HH:mm').format(
                                    (eventData!['date'] as Timestamp).toDate(),
                                  )
                                  : 'Date inconnue';

                          // Rediriger vers la page de félicitations avec les informations
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => PaymentSuccessPage(
                                    location: location ?? 'Lieu inconnu',
                                    arrivalTime:
                                        arrivalTime ?? 'Heure inconnue',
                                    groupId:
                                        groupId, // Passez ici l'ID du groupe
                                  ),
                            ),
                          );
                        } catch (e) {
                          // Afficher un message d'erreur
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Erreur'),
                                content: Text(
                                  'Une erreur s\'est produite : ${e.toString()}',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(
                                        context,
                                      ).pop(); // Fermer le dialogue
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Payer et Demander à rejoindre',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> createJoinRequest({
    required String groupId,
    required String eventId,
    required String creatorId,
    required double price,
    required String userId,
    required String paymentIntentId, // Nouveau paramètre
  }) async {
    try {
      final requestRef = FirebaseFirestore.instance
          .collection('groupJoinRequests')
          .doc(
            '$groupId-$userId',
          ); // Utiliser une clé unique pour identifier la demande

      await requestRef.set({
        'groupId': groupId,
        'eventId': eventId,
        'creatorId': creatorId,
        'price': price,
        'userId': userId,
        'paymentIntentId': paymentIntentId, // Enregistrer le PaymentIntentId
        'status': 'pending', // Statut initial de la demande
        'createdAt': FieldValue.serverTimestamp(),
        'scanqr': false,
      });

      print(
        'Demande enregistrée avec succès avec PaymentIntentId : $paymentIntentId',
      );
    } catch (e) {
      print('Erreur lors de l\'enregistrement de la demande : $e');
      throw Exception('Erreur lors de l\'enregistrement de la demande : $e');
    }
  }
}
