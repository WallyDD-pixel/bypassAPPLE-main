import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../couleur/background_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../rejoindre/voirgroupe/voir.dart';

class MesGroupesAcceptes extends StatelessWidget {
  const MesGroupesAcceptes({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundWidget(), // Arrière-plan animé

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
                    // Texte de l'AppBar
                    Text(
                      'MES GROUPES ACCEPTÉS',
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

              // Liste des groupes acceptés
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('groupJoinRequests')
                          .where('userId', isEqualTo: userId)
                          .where('status', isEqualTo: 'accepted')
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
                          '❌ Une erreur est survenue',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final requests = snapshot.data?.docs ?? [];

                    if (requests.isEmpty) {
                      return const Center(
                        child: Text(
                          '🤷‍♂️ Aucun groupe accepté',
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
                                  .collection('groups')
                                  .doc(data['groupId'])
                                  .get(),
                          builder: (context, groupSnapshot) {
                            if (groupSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (groupSnapshot.hasError ||
                                !groupSnapshot.hasData) {
                              return const Center(
                                child: Text(
                                  '❌ Erreur lors du chargement des informations du groupe',
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            }

                            final groupData =
                                groupSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            final createdBy =
                                groupData['createdBy'] ?? 'Inconnu';
                            final groupDescription =
                                groupData['description'] ??
                                'Aucune description';
                            final groupImage = groupData['imageUrl'];
                            final members =
                                groupData['members'] as Map<String, dynamic>? ??
                                {};
                            final men =
                                (members['men'] as List<dynamic>? ?? []);
                            final women =
                                (members['women'] as List<dynamic>? ?? []);

                            // Récupérer les informations du créateur
                            return FutureBuilder<DocumentSnapshot>(
                              future:
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(createdBy)
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
                                      '❌ Erreur lors du chargement des informations du créateur',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  );
                                }

                                final userData =
                                    userSnapshot.data!.data()
                                        as Map<String, dynamic>;
                                final creatorName =
                                    userData['username'] ?? 'Nom inconnu';
                                final creatorPhoto = userData['photoURL'];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: const Color.fromARGB(62, 13, 12, 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            // Photo du créateur avec une bordure dorée
                                            Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color:
                                                      Colors
                                                          .amber, // Couleur dorée pour la bordure
                                                  width:
                                                      3, // Épaisseur de la bordure
                                                ),
                                              ),
                                              child: ClipOval(
                                                child:
                                                    creatorPhoto != null
                                                        ? Image.network(
                                                          creatorPhoto,
                                                          width: 50,
                                                          height: 50,
                                                          fit: BoxFit.cover,
                                                        )
                                                        : const Icon(
                                                          Icons.person,
                                                          size: 50,
                                                          color: Colors.grey,
                                                        ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),

                                            // Nom du créateur
                                            Expanded(
                                              child: Text(
                                                'GROUPE DE $creatorName'
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 8),

                                        // Bulles des membres
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            // Bulles pour les hommes
                                            ...men.map((userId) {
                                              return FutureBuilder<
                                                DocumentSnapshot
                                              >(
                                                future:
                                                    FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(userId)
                                                        .get(),
                                                builder: (
                                                  context,
                                                  userSnapshot,
                                                ) {
                                                  if (userSnapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return const SizedBox(
                                                      width: 40,
                                                      height: 40,
                                                      child:
                                                          CircularProgressIndicator(),
                                                    );
                                                  }

                                                  if (userSnapshot.hasError ||
                                                      !userSnapshot.hasData) {
                                                    return const Icon(
                                                      Icons.error,
                                                      color: Colors.red,
                                                    );
                                                  }

                                                  final userData =
                                                      userSnapshot.data!.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  final photoURL =
                                                      userData['photoURL'];
                                                  final username =
                                                      userData['username'] ??
                                                      'Nom inconnu';
                                                  final sexe =
                                                      userData['sexe'] ??
                                                      'unknown';

                                                  // Définir la couleur de la bordure
                                                  final borderColor =
                                                      userId == createdBy
                                                          ? Colors
                                                              .amber // Bordure dorée pour le créateur
                                                          : sexe == 'homme'
                                                          ? Colors
                                                              .blue // Bordure bleue pour les hommes
                                                          : sexe == 'femme'
                                                          ? Colors
                                                              .pink // Bordure rose pour les femmes
                                                          : Colors
                                                              .grey; // Bordure grise par défaut

                                                  return Tooltip(
                                                    message: username,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: borderColor,
                                                          width:
                                                              2, // Épaisseur de la bordure
                                                        ),
                                                      ),
                                                      child: ClipOval(
                                                        child:
                                                            photoURL != null
                                                                ? Image.network(
                                                                  photoURL,
                                                                  width: 40,
                                                                  height: 40,
                                                                  fit:
                                                                      BoxFit
                                                                          .cover,
                                                                )
                                                                : const Icon(
                                                                  Icons.person,
                                                                  size: 40,
                                                                  color:
                                                                      Colors
                                                                          .grey,
                                                                ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            }).toList(),

                                            // Bulles pour les femmes
                                            ...women.map((userId) {
                                              return FutureBuilder<
                                                DocumentSnapshot
                                              >(
                                                future:
                                                    FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(userId)
                                                        .get(),
                                                builder: (
                                                  context,
                                                  userSnapshot,
                                                ) {
                                                  if (userSnapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return const SizedBox(
                                                      width: 40,
                                                      height: 40,
                                                      child:
                                                          CircularProgressIndicator(),
                                                    );
                                                  }

                                                  if (userSnapshot.hasError ||
                                                      !userSnapshot.hasData) {
                                                    return const Icon(
                                                      Icons.error,
                                                      color: Colors.red,
                                                    );
                                                  }

                                                  final userData =
                                                      userSnapshot.data!.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  final photoURL =
                                                      userData['photoURL'];
                                                  final username =
                                                      userData['username'] ??
                                                      'Nom inconnu';
                                                  final sexe =
                                                      userData['sexe'] ??
                                                      'unknown';

                                                  // Définir la couleur de la bordure
                                                  final borderColor =
                                                      userId == createdBy
                                                          ? Colors
                                                              .amber // Bordure dorée pour le créateur
                                                          : sexe == 'homme'
                                                          ? Colors
                                                              .blue // Bordure bleue pour les hommes
                                                          : sexe == 'femme'
                                                          ? Colors
                                                              .pink // Bordure rose pour les femmes
                                                          : Colors
                                                              .grey; // Bordure grise par défaut

                                                  return Tooltip(
                                                    message: username,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: borderColor,
                                                          width:
                                                              2, // Épaisseur de la bordure
                                                        ),
                                                      ),
                                                      child: ClipOval(
                                                        child:
                                                            photoURL != null
                                                                ? Image.network(
                                                                  photoURL,
                                                                  width: 40,
                                                                  height: 40,
                                                                  fit:
                                                                      BoxFit
                                                                          .cover,
                                                                )
                                                                : const Icon(
                                                                  Icons.person,
                                                                  size: 40,
                                                                  color:
                                                                      Colors
                                                                          .grey,
                                                                ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            }).toList(),
                                          ],
                                        ),
                                        const SizedBox(height: 16),

                                        // Bouton pour afficher plus de détails
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .end, // Aligne le bouton à droite
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) => VoirGroupe(
                                                          groupId:
                                                              data['groupId'],
                                                        ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors
                                                        .transparent, // Fond transparent
                                                side: const BorderSide(
                                                  color: Color.fromARGB(
                                                    255,
                                                    255,
                                                    255,
                                                    255,
                                                  ), // Couleur de la bordure
                                                  width:
                                                      2, // Épaisseur de la bordure
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 14,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12,
                                                      ), // Coins arrondis
                                                ),
                                                elevation: 0, // Pas d'ombre
                                              ),
                                              child: const Text(
                                                'VOIR LE GROUPE',
                                                style: TextStyle(
                                                  color: Color.fromARGB(
                                                    255,
                                                    255,
                                                    255,
                                                    255,
                                                  ), // Couleur du texte
                                                  fontSize:
                                                      16, // Taille de la police
                                                  fontWeight:
                                                      FontWeight
                                                          .bold, // Texte en gras
                                                  fontStyle:
                                                      FontStyle
                                                          .italic, // Texte en italique
                                                  fontFamily:
                                                      'Roboto', // Police Roboto
                                                ),
                                              ),
                                            ),
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
