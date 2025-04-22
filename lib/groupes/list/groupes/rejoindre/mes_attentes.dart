import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../couleur/background_widget.dart';
import 'package:intl/intl.dart';
import '../../../../nav/custom_bottom_nav.dart';

class MesAttentes extends StatefulWidget {
  const MesAttentes({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MesAttentesState createState() => _MesAttentesState();
}

class _MesAttentesState extends State<MesAttentes> {
  final int _selectedIndex = 3;

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

  Future<String?> _fetchEventImageUrl(String eventId) async {
    final eventSnapshot =
        await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .get();

    if (eventSnapshot.exists) {
      return eventSnapshot.data()?['imageUrl'];
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

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre en haut à gauche
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    10,
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
                          Navigator.of(
                            context,
                          ).pop(); // Retour à la page précédente
                        },
                      ),
                      // Texte de l'AppBar
                      Text(
                        'MES DEMANDES EN ATTENTE',
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
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('groupJoinRequests')
                            .where('userId', isEqualTo: userId)
                            .where('status', isEqualTo: 'pending')
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
                            'Vous n\'avez fait aucune demande',
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

                          return FutureBuilder<Map<String, dynamic>?>(
                            future: _fetchGroupDetails(data['groupId']),
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
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: Colors.grey[900],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text(
                                      'Erreur lors du chargement des détails du groupe',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                );
                              }

                              final groupDetails = groupSnapshot.data!;
                              final groupName =
                                  groupDetails['name'] ??
                                  'Nom du groupe inconnu';
                              final createdBy =
                                  groupDetails['createdBy'] ?? 'Inconnu';
                              final maxMen = groupDetails['maxMen'] ?? 0;
                              final maxWomen = groupDetails['maxWomen'] ?? 0;
                              final men =
                                  (groupDetails['members']['men'] as List?) ??
                                  [];
                              final women =
                                  (groupDetails['members']['women'] as List?) ??
                                  [];

                              return FutureBuilder<String?>(
                                future: _fetchEventImageUrl(data['eventId']),
                                builder: (context, eventSnapshot) {
                                  if (eventSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.green,
                                      ),
                                    );
                                  }

                                  final eventImageUrl =
                                      eventSnapshot.data ?? '';

                                  return Card(
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

                                          // Groupe de (nom du créateur)
                                          FutureBuilder<DocumentSnapshot>(
                                            future:
                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(createdBy)
                                                    .get(),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const Text(
                                                  'Chargement...',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                );
                                              }

                                              if (snapshot.hasError ||
                                                  !snapshot.hasData ||
                                                  !snapshot.data!.exists) {
                                                return const Text(
                                                  'Groupe de : Utilisateur inconnu',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                );
                                              }

                                              final userData =
                                                  snapshot.data!.data()
                                                      as Map<String, dynamic>;
                                              final username =
                                                  userData['username'] ??
                                                  'Utilisateur inconnu';

                                              return Text(
                                                'Groupe de : $username',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 8),

                                          // Date de la demande
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Demandé le : ${data['createdAt'] != null ? _formatDate(data['createdAt'] as Timestamp) : 'Date inconnue'}',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),

                                          // Montant payé
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.euro,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Montant payé : ${data['price'] ?? 0} EUR',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Bulles pour les hommes et les femmes
                                          // Bulles pour les hommes et les femmes
                                          Row(
                                            children: [
                                              // Bulles pour les hommes
                                              Row(
                                                children: List.generate(maxMen, (
                                                  index,
                                                ) {
                                                  // Calculer la taille des bulles dynamiquement
                                                  final int totalBubbles =
                                                      maxMen + maxWomen;
                                                  final double bubbleSize =
                                                      totalBubbles > 6
                                                          ? 30.0
                                                          : 40.0; // Réduire la taille si plus de 6 bulles

                                                  if (index < men.length) {
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
                                                                  : const Icon(
                                                                    Icons
                                                                        .person,
                                                                    color:
                                                                        Colors
                                                                            .blue,
                                                                    size:
                                                                        20, // Taille de l'icône
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
                                                  // Calculer la taille des bulles dynamiquement
                                                  final int totalBubbles =
                                                      maxMen + maxWomen;
                                                  final double bubbleSize =
                                                      totalBubbles > 6
                                                          ? 30.0
                                                          : 40.0; // Réduire la taille si plus de 6 bulles

                                                  if (index < women.length) {
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
                                                                  : const Icon(
                                                                    Icons
                                                                        .person,
                                                                    color:
                                                                        Colors
                                                                            .pink,
                                                                    size:
                                                                        20, // Taille de l'icône
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
                                          // Statut de la demande
                                          Text(
                                            'Statut : En attente (le paiement sera prélevé si accepté)',
                                            style: GoogleFonts.poppins(
                                              color:
                                                  Colors
                                                      .orange, // Couleur orange pour indiquer l'attente
                                              fontSize: 12,
                                            ),
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
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    return DateFormat('dd MMMM yyyy à HH:mm').format(timestamp.toDate());
  }
}
