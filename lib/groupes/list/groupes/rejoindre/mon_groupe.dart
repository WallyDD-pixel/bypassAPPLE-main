import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../demande/group_requests_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../couleur/background_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class MonGroupe extends StatefulWidget {
  const MonGroupe({super.key});

  @override
  State<MonGroupe> createState() => _MonGroupeState();
}

class _MonGroupeState extends State<MonGroupe> {
  String _formatDate(Timestamp timestamp) {
    return DateFormat('dd MMMM yyyy à HH:mm').format(timestamp.toDate());
  }

  Future<List<Map<String, dynamic>>> _fetchAllGroupAndEventDetails(
    List<QueryDocumentSnapshot> requests,
  ) async {
    final seenGroupIds = <String>{}; // Utilisez un Set pour éviter les doublons

    return Future.wait(
      requests.map((request) async {
        final data = request.data() as Map<String, dynamic>;
        final groupId = data['groupId'];
        final eventId = data['eventId'];

        // Vérifiez si le groupId a déjà été traité
        if (seenGroupIds.contains(groupId)) {
          return null; // Ignorez les doublons
        }
        seenGroupIds.add(groupId);

        final groupSnapshot =
            await FirebaseFirestore.instance
                .collection('groups')
                .doc(groupId)
                .get();

        final eventSnapshot =
            await FirebaseFirestore.instance
                .collection('events')
                .doc(eventId)
                .get();

        return {
          'groupId': groupId,
          'eventId': eventId,
          'groupDetails': groupSnapshot.data(),
          'eventDetails': eventSnapshot.data(),
          'requestData': data,
        };
      }),
    ).then(
      (results) =>
          results
              .where((item) => item != null)
              .cast<Map<String, dynamic>>()
              .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundWidget(), // Arrière-plan fixe
          Column(
            children: [
              // AppBar personnalisée
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
                    // Texte "MES DEMANDES"
                    const Text(
                      'MES DEMANDES',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('groupJoinRequests')
                          .where('creatorId', isEqualTo: userId)
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
                          'Vous n\'avez créé aucun groupe',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      );
                    }

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchAllGroupAndEventDetails(requests),
                      builder: (context, futureSnapshot) {
                        if (futureSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.green,
                            ),
                          );
                        }

                        if (futureSnapshot.hasError) {
                          return const Center(
                            child: Text(
                              'Erreur lors du chargement des données',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        final items = futureSnapshot.data ?? [];

                        return ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final groupDetails =
                                item['groupDetails'] as Map<String, dynamic>?;
                            final eventDetails =
                                item['eventDetails'] as Map<String, dynamic>?;
                            final requestData =
                                item['requestData'] as Map<String, dynamic>;

                            if (groupDetails == null || eventDetails == null) {
                              return const SizedBox.shrink();
                            }

                            final eventImageUrl =
                                eventDetails['imageUrl'] ?? '';
                            final members =
                                groupDetails['members']
                                    as Map<String, dynamic>? ??
                                {};
                            final men = (members['men'] as List?) ?? [];
                            final women = (members['women'] as List?) ?? [];
                            final request = requests[index];

                            final data = request.data() as Map<String, dynamic>;

                            final groupId = data['groupId'] as String? ?? '';

                            final menCount = men.length;
                            final womenCount = women.length;
                            final maxMen = groupDetails['maxMen'] as int? ?? 0;
                            final maxWomen =
                                groupDetails['maxWomen'] as int? ?? 0;

                            return GestureDetector(
                              onTap: () {
                                // Ajoutez un log pour vérifier la valeur de groupId
                                print('groupId : $groupId');

                                if (groupId.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Erreur : identifiant du groupe introuvable.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => GroupRequestsPage(
                                          groupId:
                                              groupId, // Passez ici l'identifiant du groupe
                                        ),
                                  ),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: const Color.fromARGB(62, 13, 12, 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Affichage de l'image de l'événement
                                      if (eventImageUrl.isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: eventImageUrl,
                                            height: 100,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder:
                                                (context, url) =>
                                                    Shimmer.fromColors(
                                                      baseColor:
                                                          Colors.grey[800]!,
                                                      highlightColor:
                                                          Colors.grey[500]!,
                                                      child: Container(
                                                        height: 100,
                                                        width: double.infinity,
                                                        color: Colors.grey[800],
                                                      ),
                                                    ),
                                            errorWidget:
                                                (
                                                  context,
                                                  url,
                                                  error,
                                                ) => const Center(
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.red,
                                                    size: 50,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      const SizedBox(height: 8),

                                      // Titre et prix alignés horizontalement
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              (eventDetails['name'] ??
                                                      'Nom inconnu')
                                                  .toUpperCase(),
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                fontStyle: FontStyle.italic,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '${requestData['price']}€',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),

                                      Text(
                                        () {
                                          final int maxMen =
                                              groupDetails['maxMen'] ?? 0;
                                          final int maxWomen =
                                              groupDetails['maxWomen'] ?? 0;

                                          final List<dynamic> men =
                                              groupDetails['members']['men'] ??
                                              [];
                                          final List<dynamic> women =
                                              groupDetails['members']['women'] ??
                                              [];

                                          final int currentMen = men.length;
                                          final int currentWomen = women.length;

                                          if (currentMen >= maxMen &&
                                              currentWomen >= maxWomen) {
                                            return 'Statut : Groupe complet';
                                          } else if (currentMen < maxMen &&
                                              currentWomen < maxWomen) {
                                            final int remainingMen =
                                                maxMen - currentMen;
                                            final int remainingWomen =
                                                maxWomen - currentWomen;
                                            return 'Statut : $remainingMen homme(s) et $remainingWomen femme(s) requis';
                                          } else if (currentMen < maxMen) {
                                            final int remainingMen =
                                                maxMen - currentMen;
                                            return 'Statut : $remainingMen homme(s) requis';
                                          } else if (currentWomen < maxWomen) {
                                            final int remainingWomen =
                                                maxWomen - currentWomen;
                                            return 'Statut : $remainingWomen femme(s) requis';
                                          } else {
                                            return 'Statut : Statut inconnu';
                                          }
                                        }(),
                                        style: const TextStyle(
                                          color:
                                              Colors
                                                  .orange, // Couleur par défaut
                                          fontSize:
                                              18, // Augmenté pour le statut
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Bulles pour les hommes et les femmes
                                      Row(
                                        children: [
                                          // Bulles pour les hommes
                                          Row(
                                            children: List.generate(maxMen, (
                                              index,
                                            ) {
                                              final bubbleSize =
                                                  maxMen > 3 ? 40.0 : 50.0;
                                              if (index < menCount) {
                                                final userId = men[index];
                                                return FutureBuilder<
                                                  DocumentSnapshot
                                                >(
                                                  future:
                                                      FirebaseFirestore.instance
                                                          .collection('users')
                                                          .doc(userId)
                                                          .get(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return Shimmer.fromColors(
                                                        baseColor:
                                                            Colors.grey[800]!,
                                                        highlightColor:
                                                            Colors.grey[500]!,
                                                        child: Container(
                                                          margin:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 2,
                                                              ),
                                                          width: bubbleSize,
                                                          height: bubbleSize,
                                                          decoration:
                                                              BoxDecoration(
                                                                color:
                                                                    Colors
                                                                        .grey[800],
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                              ),
                                                        ),
                                                      );
                                                    }

                                                    final photoURL =
                                                        (snapshot.data?.data()
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >?)?['photoURL'];
                                                    return Container(
                                                      margin:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 2,
                                                          ),
                                                      width: bubbleSize,
                                                      height: bubbleSize,
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue
                                                            .withOpacity(0.2),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                      child:
                                                          photoURL != null
                                                              ? ClipOval(
                                                                child: Image.network(
                                                                  photoURL,
                                                                  fit:
                                                                      BoxFit
                                                                          .cover,
                                                                ),
                                                              )
                                                              : const Center(
                                                                child: Text(
                                                                  '?',
                                                                  style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .blue,
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                    );
                                                  },
                                                );
                                              } else {
                                                return Container(
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 2,
                                                      ),
                                                  width: bubbleSize,
                                                  height: bubbleSize,
                                                  decoration: BoxDecoration(
                                                    color: Colors.transparent,
                                                    border: Border.all(
                                                      color: Colors.blue,
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                      '?',
                                                      style: TextStyle(
                                                        color: Colors.blue,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                            }),
                                          ),
                                          const SizedBox(width: 2),

                                          // Bulles pour les femmes
                                          Row(
                                            children: List.generate(maxWomen, (
                                              index,
                                            ) {
                                              final bubbleSize =
                                                  maxWomen > 3 ? 40.0 : 50.0;
                                              if (index < womenCount) {
                                                final userId = women[index];
                                                return FutureBuilder<
                                                  DocumentSnapshot
                                                >(
                                                  future:
                                                      FirebaseFirestore.instance
                                                          .collection('users')
                                                          .doc(userId)
                                                          .get(),
                                                  builder: (context, snapshot) {
                                                    final photoURL =
                                                        (snapshot.data?.data()
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >?)?['photoURL'];
                                                    return Container(
                                                      margin:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 2,
                                                          ),
                                                      width: bubbleSize,
                                                      height: bubbleSize,
                                                      decoration: BoxDecoration(
                                                        color: Colors.pink
                                                            .withOpacity(0.2),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: Colors.pink,
                                                        ),
                                                      ),
                                                      child:
                                                          photoURL != null
                                                              ? ClipOval(
                                                                child: Image.network(
                                                                  photoURL,
                                                                  fit:
                                                                      BoxFit
                                                                          .cover,
                                                                ),
                                                              )
                                                              : const Center(
                                                                child: Text(
                                                                  '?',
                                                                  style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .pink,
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                    );
                                                  },
                                                );
                                              } else {
                                                return Container(
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 2,
                                                      ),
                                                  width: bubbleSize,
                                                  height: bubbleSize,
                                                  decoration: BoxDecoration(
                                                    color: Colors.transparent,
                                                    border: Border.all(
                                                      color: Colors.pink,
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                      '?',
                                                      style: TextStyle(
                                                        color: Colors.pink,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                            }),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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
