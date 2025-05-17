import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'accept_request_page.dart';
import 'alternative.dart'; // Importez la page alternative
import '../../../../couleur/background_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupRequestsPage extends StatelessWidget {
  final String groupId;

  const GroupRequestsPage({super.key, required this.groupId});

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

  Future<void> _handleAcceptRequest(
    BuildContext context,
    String requestId,
    String userId,
    double price,
  ) async {
    try {
      // Récupérer les informations de l'utilisateur
      final userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (!userSnapshot.exists) {
        throw Exception('Utilisateur introuvable');
      }

      final userData = userSnapshot.data() as Map<String, dynamic>;
      final sexe = userData['sexe'] ?? 'unknown';

      // Rediriger en fonction du sexe
      if (sexe == 'femme') {
        // Rediriger vers une autre page si l'utilisateur est une femme
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => AlternativePage(userId: userId, groupId: groupId),
          ),
        );
      } else {
        // Rediriger vers la page AcceptRequestPage pour les hommes
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => AcceptRequestPage(
                  requestId: requestId,
                  userId: userId,
                  groupId: groupId,
                  price: price,
                ),
          ),
        );
      }
    } catch (e) {
      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
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
                      '📋 LISTE DES DEMANDES',
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

              // Explications dans une card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: const Color.fromARGB(62, 13, 12, 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ℹ️ Explications :',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '1️⃣ Si vous acceptez, l\'utilisateur sera ajouté au groupe et le paiement sera capturé.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '2️⃣ Si vous refusez, la demande sera supprimée et aucun paiement ne sera effectué.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Liste des demandes
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('groupJoinRequests')
                          .where(
                            'groupId',
                            isEqualTo: groupId,
                          ) // Filtre par groupId
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      debugPrint(
                        'Chargement des demandes pour le groupe : $groupId',
                      );
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      );
                    }

                    if (snapshot.hasError) {
                      debugPrint(
                        'Erreur lors de la récupération des demandes : ${snapshot.error}',
                      );
                      return const Center(
                        child: Text(
                          '❌ Une erreur est survenue',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final requests = snapshot.data?.docs ?? [];
                    debugPrint(
                      'Nombre de demandes récupérées pour le groupe $groupId : ${requests.length}',
                    );

                    if (requests.isEmpty) {
                      debugPrint(
                        'Aucune demande trouvée pour le groupe $groupId.',
                      );
                      return const Center(
                        child: Text(
                          '🤷‍♂️ Aucune demande pour ce groupe',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        final data = request.data() as Map<String, dynamic>?;

                        if (data == null) {
                          debugPrint(
                            'Les données de la demande sont nulles pour l\'index $index.',
                          );
                          return const Center(
                            child: Text(
                              '❌ Données de la demande introuvables',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        debugPrint(
                          'Données de la demande à l\'index $index pour le groupe $groupId : $data',
                        );

                        return FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(data['userId'])
                                  .get(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              debugPrint(
                                'Chargement des données utilisateur pour l\'index $index...',
                              );
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (userSnapshot.hasError) {
                              debugPrint(
                                'Erreur lors de la récupération des données utilisateur : ${userSnapshot.error}',
                              );
                              return const Center(
                                child: Text(
                                  '❌ Erreur lors du chargement des informations utilisateur',
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            }

                            if (!userSnapshot.hasData ||
                                !userSnapshot.data!.exists) {
                              debugPrint(
                                'Le document utilisateur n\'existe pas pour l\'index $index.',
                              );
                              return const Center(
                                child: Text(
                                  '❌ Utilisateur introuvable',
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            }

                            final userData =
                                userSnapshot.data!.data()
                                    as Map<String, dynamic>?;

                            if (userData == null) {
                              debugPrint(
                                'Les données utilisateur sont nulles pour l\'index $index.',
                              );
                              return const Center(
                                child: Text(
                                  '❌ Les données utilisateur sont introuvables',
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            }

                            debugPrint(
                              'Données utilisateur récupérées pour l\'index $index : $userData',
                            );

                            final userName =
                                userData['username'] ?? 'Nom inconnu';
                            final userPhoto = userData['photoURL'];
                            final sexe = userData['sexe'] ?? 'unknown';

                            debugPrint('Nom utilisateur : $userName');
                            debugPrint(
                              'Photo utilisateur : ${userPhoto ?? "Aucune photo"}',
                            );
                            debugPrint('Sexe utilisateur : $sexe');

                            // Déterminez le texte à afficher pour le sexe
                            final sexeText =
                                (sexe == 'homme')
                                    ? 'Homme'
                                    : (sexe == 'femme')
                                    ? 'Femme'
                                    : 'Genre inconnu';

                            // Déterminez la couleur du statut
                            final statusColor =
                                (data['status'] == 'pending')
                                    ? Colors.orange
                                    : Colors.green;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: const Color.fromARGB(62, 13, 12, 12),
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

                                        // Nom de l'utilisateur et sexe
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${userName[0].toUpperCase()}${userName.substring(1)}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Sexe : $sexeText',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
                                              debugPrint(
                                                'Bouton Accepter cliqué pour l\'index $index.',
                                              );
                                              final double price =
                                                  (data['price'] as num?)
                                                      ?.toDouble() ??
                                                  0.0;
                                              _handleAcceptRequest(
                                                context,
                                                request.id,
                                                data['userId'],
                                                price,
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                            ),
                                            label: const Text('Accepter ✅'),
                                          ),
                                          // Bouton Refuser
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              debugPrint(
                                                'Bouton Refuser cliqué pour l\'index $index.',
                                              );
                                              _rejectRequest(request.id);
                                            },
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                            ),
                                            label: const Text('Refuser ❌'),
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
                                            '✅ Demande déjà acceptée',
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
