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

  Future<Map<String, dynamic>?> _fetchGroupDetails(String groupId) async {
    final groupSnapshot =
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .get();

    if (groupSnapshot.exists) {
      return groupSnapshot.data();
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchEventDetails(String eventId) async {
    final eventSnapshot =
        await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .get();

    if (eventSnapshot.exists) {
      return eventSnapshot.data();
    }
    return null;
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

                    // Regrouper les demandes par groupId
                    final Map<String, List<QueryDocumentSnapshot>>
                    groupedRequests = {};
                    for (var request in requests) {
                      final data = request.data() as Map<String, dynamic>;
                      final groupId = data['groupId'];
                      if (!groupedRequests.containsKey(groupId)) {
                        groupedRequests[groupId] = [];
                      }
                      groupedRequests[groupId]!.add(request);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: groupedRequests.keys.length,
                      itemBuilder: (context, index) {
                        final groupId = groupedRequests.keys.elementAt(index);
                        final groupRequests = groupedRequests[groupId]!;

                        // Utiliser les données de la première demande pour récupérer les détails du groupe
                        final firstRequestData =
                            groupRequests.first.data() as Map<String, dynamic>;

                        return FutureBuilder<Map<String, dynamic>?>(
                          future: _fetchGroupDetails(groupId),
                          builder: (context, groupSnapshot) {
                            if (groupSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.green,
                                ),
                              );
                            }

                            if (groupSnapshot.hasError ||
                                groupSnapshot.data == null) {
                              return const Center(
                                child: Text(
                                  'Erreur lors du chargement des détails du groupe',
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            }

                            final groupDetails = groupSnapshot.data!;
                            final members =
                                groupDetails['members']
                                    as Map<String, dynamic>? ??
                                {};
                            final men = (members['men'] as List?) ?? [];
                            final women = (members['women'] as List?) ?? [];
                            final menCount = men.length;
                            final womenCount = women.length;
                            final maxMen = groupDetails['maxMen'] as int? ?? 0;
                            final maxWomen =
                                groupDetails['maxWomen'] as int? ?? 0;

                            return FutureBuilder<Map<String, dynamic>?>(
                              future: _fetchEventDetails(
                                firstRequestData['eventId'],
                              ),
                              builder: (context, eventSnapshot) {
                                if (eventSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.green,
                                    ),
                                  );
                                }

                                if (eventSnapshot.hasError ||
                                    eventSnapshot.data == null) {
                                  return const Center(
                                    child: Text(
                                      'Erreur lors du chargement des détails de l\'événement',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  );
                                }

                                final eventDetails = eventSnapshot.data!;
                                final eventImageUrl =
                                    eventDetails['imageUrl'] ?? '';

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (context) => GroupRequestsPage(
                                              groupId: groupId,
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: CachedNetworkImage(
                                                imageUrl: eventImageUrl,
                                                height: 100,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                placeholder:
                                                    (
                                                      context,
                                                      url,
                                                    ) => Shimmer.fromColors(
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
                                                        Icons
                                                            .image_not_supported,
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                '${firstRequestData['price']}€',
                                                style: const TextStyle(
                                                  color: Color.fromARGB(
                                                    255,
                                                    255,
                                                    255,
                                                    255,
                                                  ),
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Statut
                                          Text(
                                            'Statut : ${groupDetails['status'] ?? 'Statut inconnu'}',
                                            style: GoogleFonts.poppins(
                                              color:
                                                  groupDetails['status'] ==
                                                          'pending'
                                                      ? Colors.orange
                                                      : const Color.fromARGB(
                                                        255,
                                                        255,
                                                        255,
                                                        255,
                                                      ),
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight
                                                      .w500, // Poids de la police (optionnel)
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          Row(
                                            children: [
                                              // Bulles pour les hommes
                                              Row(
                                                children: List.generate(maxMen, (
                                                  index,
                                                ) {
                                                  final bubbleSize =
                                                      maxMen > 3
                                                          ? 40.0
                                                          : 50.0; // Réduire la taille si plus de 3 bulles
                                                  if (index < menCount) {
                                                    final userId = men[index];
                                                    return FutureBuilder<
                                                      DocumentSnapshot
                                                    >(
                                                      future:
                                                          FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'users',
                                                              )
                                                              .doc(userId)
                                                              .get(),
                                                      builder: (
                                                        context,
                                                        snapshot,
                                                      ) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return Shimmer.fromColors(
                                                            baseColor:
                                                                Colors
                                                                    .grey[800]!,
                                                            highlightColor:
                                                                Colors
                                                                    .grey[500]!,
                                                            child: Container(
                                                              margin:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        2,
                                                                  ),
                                                              width: bubbleSize,
                                                              height:
                                                                  bubbleSize,
                                                              decoration: BoxDecoration(
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
                                                            (snapshot.data
                                                                    ?.data()
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
                                                                .withOpacity(
                                                                  0.2,
                                                                ),
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                              color:
                                                                  Colors.blue,
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
                                                                            Colors.blue,
                                                                        fontSize:
                                                                            20, // Taille du point d'interrogation
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                        );
                                                      },
                                                    );
                                                  } else {
                                                    // Bulle vide avec un point d'interrogation
                                                    return Container(
                                                      margin:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 2,
                                                          ),
                                                      width: bubbleSize,
                                                      height: bubbleSize,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.transparent,
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
                                                            fontSize:
                                                                20, // Taille du point d'interrogation
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
                                                      maxWomen > 3
                                                          ? 40.0
                                                          : 50.0; // Réduire la taille si plus de 3 bulles
                                                  if (index < womenCount) {
                                                    final userId = women[index];
                                                    return FutureBuilder<
                                                      DocumentSnapshot
                                                    >(
                                                      future:
                                                          FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'users',
                                                              )
                                                              .doc(userId)
                                                              .get(),
                                                      builder: (
                                                        context,
                                                        snapshot,
                                                      ) {
                                                        final photoURL =
                                                            (snapshot.data
                                                                    ?.data()
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
                                                                .withOpacity(
                                                                  0.2,
                                                                ),
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                              color:
                                                                  Colors.pink,
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
                                                                            Colors.pink,
                                                                        fontSize:
                                                                            20, // Taille du point d'interrogation
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                        );
                                                      },
                                                    );
                                                  } else {
                                                    // Bulle vide avec un point d'interrogation
                                                    return Container(
                                                      margin:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 2,
                                                          ),
                                                      width: bubbleSize,
                                                      height: bubbleSize,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.transparent,
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
                                                            fontSize:
                                                                20, // Taille du point d'interrogation
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
