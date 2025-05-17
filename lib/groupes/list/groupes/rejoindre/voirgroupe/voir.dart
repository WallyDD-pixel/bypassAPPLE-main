import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../couleur/background_widget.dart'; // Import de l'arrière-plan animé
import '../../../../../Chat/chat_view.dart'; // Importez votre page de chat
import 'package:firebase_auth/firebase_auth.dart';

class VoirGroupe extends StatelessWidget {
  final String groupId;

  const VoirGroupe({super.key, required this.groupId});

  // Fonction pour mettre la première lettre en majuscule
  String capitalize(String name) {
    if (name.isEmpty) return 'Nom inconnu';
    return name
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    const Text(
                      'PARTICIPANTS DU GROUPE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des participants
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('groups')
                          .doc(groupId)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(
                        child: Text(
                          '❌ Erreur lors du chargement des informations du groupe',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final groupData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final members =
                        groupData['members'] as Map<String, dynamic>? ?? {};
                    final men = (members['men'] as List<dynamic>? ?? []);
                    final women = (members['women'] as List<dynamic>? ?? []);

                    final allMembers = [...men, ...women];

                    if (allMembers.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucun membre dans ce groupe',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent:
                                200, // Largeur maximale pour chaque carte
                            mainAxisSpacing:
                                16, // Espacement vertical entre les cartes
                            crossAxisSpacing:
                                16, // Espacement horizontal entre les cartes
                            childAspectRatio:
                                3 / 4, // Ratio largeur/hauteur des cartes
                          ),
                      itemCount: allMembers.length,
                      itemBuilder: (context, index) {
                        final userId = allMembers[index];

                        return StreamBuilder<DocumentSnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .snapshots(),
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
                                  '❌ Erreur lors du chargement des informations utilisateur',
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
                            final createdBy =
                                snapshot
                                    .data!['createdBy']; // ID du créateur du groupe

                            // Vérifier si l'utilisateur est le créateur
                            final isCreator = userId == createdBy;

                            return Card(
                              color:
                                  isCreator
                                      ? const Color.fromARGB(
                                        255,
                                        255,
                                        215,
                                        0,
                                      ) // Fond doré pour le créateur
                                      : const Color.fromARGB(
                                        62,
                                        13,
                                        12,
                                        12,
                                      ), // Fond normal pour les autres
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side:
                                    isCreator
                                        ? const BorderSide(
                                          color:
                                              Colors
                                                  .amber, // Bordure dorée pour le créateur
                                          width: 2,
                                        )
                                        : userId ==
                                            FirebaseAuth
                                                .instance
                                                .currentUser!
                                                .uid
                                        ? const BorderSide(
                                          color:
                                              Colors
                                                  .blue, // Bordure bleue pour l'utilisateur connecté
                                          width: 2,
                                        )
                                        : BorderSide
                                            .none, // Pas de bordure pour les autres
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                      child:
                                          userPhoto != null
                                              ? Image.network(
                                                userPhoto,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                              )
                                              : Container(
                                                color: Colors.grey,
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 80,
                                                  color: Colors.white,
                                                ),
                                              ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      capitalize(userName),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color:
                                            isCreator
                                                ? Colors
                                                    .black // Texte noir pour le créateur
                                                : userId ==
                                                    FirebaseAuth
                                                        .instance
                                                        .currentUser!
                                                        .uid
                                                ? Colors
                                                    .blue // Texte bleu pour l'utilisateur connecté
                                                : Colors
                                                    .white, // Texte blanc pour les autres
                                        fontSize:
                                            16, // Taille de la police augmentée
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              Container(
                margin: const EdgeInsets.fromLTRB(24, 16, 24, 52),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatView(groupId: groupId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(
                      color: Color.fromARGB(255, 255, 255, 255),
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ENVOYER UN MESSAGE',
                    style: TextStyle(
                      color: Color.fromARGB(255, 208, 210, 208),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
