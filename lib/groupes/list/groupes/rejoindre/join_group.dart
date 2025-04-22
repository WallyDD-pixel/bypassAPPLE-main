import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'GroupJoinRequest.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../couleur/background_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class JoinGroup extends StatefulWidget {
  final String eventId;

  const JoinGroup({super.key, required this.eventId});

  @override
  _JoinGroupState createState() => _JoinGroupState();
}

class _JoinGroupState extends State<JoinGroup> {
  List<QueryDocumentSnapshot> searchResults = [];
  String searchQuery = '';
  int _selectedIndex = 0; // Index par défaut pour le menu de navigation

  String _formatDate(Timestamp? timestamp) =>
      timestamp == null
          ? 'Date inconnue'
          : DateFormat('dd/MM/yyyy à HH:mm').format(timestamp.toDate());

  String _formatPrice(num? price) =>
      price == null ? 'Prix non défini' : '${price.toString()}€';

  Widget _buildCreatorPhoto(String? creatorId) {
    return creatorId == null
        ? const SizedBox.shrink()
        : StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(creatorId)
                  .snapshots(),
          builder: (context, snapshot) {
            final photoURL =
                (snapshot.data?.data() as Map<String, dynamic>?)?['photoURL'];
            return CircleAvatar(
              radius: 25,
              backgroundImage:
                  photoURL != null
                      ? CachedNetworkImageProvider(photoURL)
                      : null,
              child:
                  photoURL == null
                      ? const Icon(Icons.person, color: Colors.green)
                      : null,
            );
          },
        );
  }

  Future<bool> hasPendingRequest(String groupId, String userId) async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('groupJoinRequests')
            .where('groupId', isEqualTo: groupId)
            .where('userId', isEqualTo: userId)
            .where(
              'status',
              isEqualTo: 'pending',
            ) // Vérifie uniquement les demandes en attente
            .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Widget _buildCreatorInfo(String? creatorId) {
    return creatorId == null
        ? const Text(
          'Créateur inconnu',
          style: TextStyle(color: Colors.green, fontSize: 12),
        )
        : StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(creatorId)
                  .snapshots(),
          builder: (context, snapshot) {
            final username =
                (snapshot.data?.data() as Map<String, dynamic>?)?['username'] ??
                'Utilisateur inconnu';
            return Text(
              'GROUPE DE ${username.toUpperCase()}',
              style: GoogleFonts.poppins(
                color: const Color.fromARGB(255, 243, 243, 243),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic, // Texte en italique
              ),
            );
          },
        );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigation vers d'autres pages en fonction de l'index
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const Center(child: Text('Accueil')),
        ),
      );
    } else if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const Center(child: Text('Recherche')),
        ),
      );
    } else if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const Center(child: Text('Ajouter')),
        ),
      );
    } else if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const Center(child: Text('Favoris')),
        ),
      );
    } else if (index == 4) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const Center(child: Text('Profil')),
        ),
      );
    }
  }

  Future<bool> isUserInGroup(String groupId, String userId) async {
    final groupSnapshot =
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .get();

    if (!groupSnapshot.exists) return false;

    final groupData = groupSnapshot.data() as Map<String, dynamic>;
    final members = groupData['members'] as Map<String, dynamic>? ?? {};
    final men = (members['men'] as List?) ?? [];
    final women = (members['women'] as List?) ?? [];

    // Vérifie si l'utilisateur est dans la liste des hommes ou des femmes
    return men.contains(userId) || women.contains(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arrière-plan animé
          const BackgroundWidget(),

          // Contenu principal
          Column(
            children: [
              const SizedBox(height: 52),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 16, left: 16),
                alignment: Alignment.topLeft, // Aligné à gauche
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
                      'REJOINDRE',
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
              // Liste des groupes
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('groups')
                          .where('eventId', isEqualTo: widget.eventId)
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

                    final groups = snapshot.data?.docs ?? [];
                    final filteredGroups =
                        groups.where((group) {
                          final data = group.data() as Map<String, dynamic>;
                          final groupName =
                              (data['name'] ?? '').toString().toLowerCase();
                          return groupName.contains(searchQuery);
                        }).toList();

                    if (filteredGroups.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucun groupe disponible',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredGroups.length,
                      itemBuilder: (context, index) {
                        final group = filteredGroups[index];
                        final data = group.data() as Map<String, dynamic>;
                        final creatorId = data['createdBy'] as String?;
                        final members =
                            data['members'] as Map<String, dynamic>? ?? {};
                        final menCount = (members['men'] as List?)?.length ?? 0;
                        final womenCount =
                            (members['women'] as List?)?.length ?? 0;
                        final totalParticipants = menCount + womenCount;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.15),
                                Colors.green.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (data['photoURL'] != null)
                                CachedNetworkImage(
                                  imageUrl: data['photoURL'],
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
                                      ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _buildCreatorPhoto(creatorId),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildCreatorInfo(creatorId),
                                        ),
                                        Text(
                                          _formatPrice(data['price'] as num?),
                                          style: const TextStyle(
                                            color: Color.fromARGB(
                                              255,
                                              230,
                                              230,
                                              230,
                                            ),
                                            fontSize: 26,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Affichage de l'heure d'arrivée
                                    FutureBuilder<DocumentSnapshot>(
                                      future:
                                          FirebaseFirestore.instance
                                              .collection('groups')
                                              .doc(
                                                group.id,
                                              ) // Assurez-vous que `group.id` est disponible
                                              .get(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.green,
                                            ),
                                          );
                                        }

                                        if (snapshot.hasError ||
                                            !snapshot.hasData ||
                                            !snapshot.data!.exists) {
                                          return const Text(
                                            'Heure d\'arrivée inconnue',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 14,
                                            ),
                                          );
                                        }

                                        final groupData =
                                            snapshot.data!.data()
                                                as Map<String, dynamic>;
                                        final arrivalTime =
                                            groupData['arrivalTime']
                                                as Map<String, dynamic>?;

                                        if (arrivalTime == null) {
                                          return const Text(
                                            'Heure d\'arrivée non définie',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          );
                                        }

                                        final hour =
                                            arrivalTime['hour'] as int? ?? 0;
                                        final minute =
                                            arrivalTime['minute'] as int? ?? 0;

                                        return Text(
                                          'Heure d\'arrivée : ${hour.toString().padLeft(2, '0')}h${minute.toString().padLeft(2, '0')}',
                                          style: GoogleFonts.poppins(
                                            color: const Color.fromARGB(
                                              255,
                                              210,
                                              210,
                                              210,
                                            ),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Bulles pour les hommes (ordre inversé)
                                        Row(
                                          children:
                                              List.generate(data['maxMen'] as int, (
                                                index,
                                              ) {
                                                if (index < menCount) {
                                                  final userId =
                                                      (members['men']
                                                          as List)[index];
                                                  return FutureBuilder<
                                                    DocumentSnapshot
                                                  >(
                                                    future:
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection('users')
                                                            .doc(userId)
                                                            .get(),
                                                    builder: (
                                                      context,
                                                      snapshot,
                                                    ) {
                                                      final photoURL =
                                                          (snapshot.data?.data()
                                                              as Map<
                                                                String,
                                                                dynamic
                                                              >?)?['photoURL'];
                                                      return Container(
                                                        margin:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 4,
                                                            ),
                                                        width: 45,
                                                        height: 45,
                                                        decoration:
                                                            BoxDecoration(
                                                              color: Colors.blue
                                                                  .withOpacity(
                                                                    0.2,
                                                                  ),
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
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
                                                                  Icons.person,
                                                                  color:
                                                                      Colors
                                                                          .blue,
                                                                  size: 20,
                                                                ),
                                                      );
                                                    },
                                                  );
                                                } else {
                                                  return Container(
                                                    margin:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 4,
                                                        ),
                                                    width: 45,
                                                    height: 45,
                                                    decoration: BoxDecoration(
                                                      color: Colors.transparent,
                                                      border: Border.all(
                                                        color: Colors.blue,
                                                      ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  );
                                                }
                                              }).reversed.toList(),
                                        ),

                                        // Bulles pour les femmes (ordre normal)
                                        Row(
                                          children: List.generate(
                                            data['maxWomen'] as int,
                                            (index) {
                                              if (index < womenCount) {
                                                final userId =
                                                    (members['women']
                                                        as List)[index];
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
                                                            horizontal: 4,
                                                          ),
                                                      width: 45,
                                                      height: 45,
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
                                                              : const Icon(
                                                                Icons.person,
                                                                color:
                                                                    Colors.pink,
                                                                size: 20,
                                                              ),
                                                    );
                                                  },
                                                );
                                              } else {
                                                return Container(
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                      ),
                                                  width: 45,
                                                  height: 45,
                                                  decoration: BoxDecoration(
                                                    color: Colors.transparent,
                                                    border: Border.all(
                                                      color: Colors.pink,
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FutureBuilder<bool>(
                                        future: Future.wait([
                                          hasPendingRequest(
                                            group.id,
                                            FirebaseAuth
                                                .instance
                                                .currentUser!
                                                .uid,
                                          ),
                                          isUserInGroup(
                                            group.id,
                                            FirebaseAuth
                                                .instance
                                                .currentUser!
                                                .uid,
                                          ),
                                        ]).then(
                                          (results) => results[0] || results[1],
                                        ),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator(
                                              color: Colors.green,
                                            );
                                          }

                                          if (snapshot.hasError) {
                                            return Text(
                                              'Erreur lors de la vérification',
                                              style: GoogleFonts.poppins(
                                                color: Colors.red,
                                              ),
                                            );
                                          }

                                          final isInGroupOrPending =
                                              snapshot.data ?? false;
                                          final userId =
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser!
                                                  .uid;

                                          // Vérifier si l'utilisateur est le créateur du groupe
                                          if (creatorId == userId) {
                                            return Text(
                                              'Vous êtes le créateur de ce groupe',
                                              style: GoogleFonts.poppins(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          }

                                          // Vérifier si l'utilisateur fait déjà partie du groupe ou a une demande en attente
                                          if (isInGroupOrPending) {
                                            return Text(
                                              'Vous faites déjà partie du groupe ou avez déjà envoyé une demande',
                                              style: GoogleFonts.poppins(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          }

                                          // Vérifier si le groupe est complet
                                          return totalParticipants >=
                                                  (data['totalCapacity'] as int)
                                              ? Text(
                                                'Groupe complet',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                              : TextButton.icon(
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder:
                                                          (
                                                            context,
                                                          ) => GroupJoinRequest(
                                                            groupId: group.id,
                                                            eventId:
                                                                widget.eventId,
                                                            creatorId:
                                                                creatorId ?? '',
                                                            price:
                                                                data['price']
                                                                    as num? ??
                                                                0,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.group_add,
                                                  color: Colors.green,
                                                ),
                                                label: Text(
                                                  'Rejoindre',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.green,
                                                  ),
                                                ),
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
