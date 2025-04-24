import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../couleur/background_widget.dart'; // Importez votre widget d'arrière-plan
import '../profil/profile_page.dart'; // Importez votre page de profil utilisateur

class GroupMembersPage extends StatelessWidget {
  final String groupId;

  const GroupMembersPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arrière-plan animé
          const BackgroundWidget(),
          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                // AppBar personnalisée
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pop(); // Bouton de retour
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'MEMBRES DU GROUPE',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('chats')
                            .doc(groupId)
                            .get(), // Récupérer le document du groupe
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Center(
                          child: Text(
                            'Aucun membre trouvé.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        );
                      }

                      final groupData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final participants =
                          groupData['participants'] as List<dynamic>? ?? [];
                      final createdBy =
                          groupData['createdBy'] as String?; // ID du créateur

                      // Ajouter le créateur à la liste des participants s'il n'y est pas déjà
                      if (createdBy != null &&
                          !participants.contains(createdBy)) {
                        participants.insert(
                          0,
                          createdBy,
                        ); // Ajouter le créateur au début
                      }

                      if (participants.isEmpty) {
                        return const Center(
                          child: Text(
                            'Aucun membre trouvé.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Titre de la section
                            Text(
                              'LISTE DES MEMBRES',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Liste des membres
                            Expanded(
                              child: ListView.builder(
                                itemCount: participants.length,
                                itemBuilder: (context, index) {
                                  final participantId = participants[index];

                                  return FutureBuilder<DocumentSnapshot>(
                                    future:
                                        FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(participantId)
                                            .get(), // Récupérer les données de l'utilisateur
                                    builder: (context, userSnapshot) {
                                      if (userSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const ListTile(
                                          leading: CircularProgressIndicator(),
                                          title: Text('Chargement...'),
                                        );
                                      }

                                      if (!userSnapshot.hasData ||
                                          !userSnapshot.data!.exists) {
                                        return const ListTile(
                                          leading: Icon(
                                            Icons.error,
                                            color: Colors.red,
                                          ),
                                          title: Text(
                                            'Utilisateur introuvable',
                                          ),
                                        );
                                      }

                                      final userData =
                                          userSnapshot.data!.data()
                                              as Map<String, dynamic>;
                                      final userName =
                                          userData['username'] ??
                                          'Utilisateur inconnu';
                                      final userPhotoUrl = userData['photoURL'];

                                      return Card(
                                        color: const Color.fromARGB(
                                          50,
                                          0,
                                          0,
                                          0,
                                        ),
                                        elevation: 6,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          side: const BorderSide(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: ListTile(
                                          leading:
                                              userPhotoUrl != null
                                                  ? CircleAvatar(
                                                    backgroundImage:
                                                        NetworkImage(
                                                          userPhotoUrl,
                                                        ),
                                                  )
                                                  : const CircleAvatar(
                                                    backgroundColor:
                                                        Colors.grey,
                                                    child: Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                          title: Text(
                                            userName,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          subtitle:
                                              participantId == createdBy
                                                  ? Text(
                                                    'Créateur du groupe',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color: Colors.grey,
                                                    ),
                                                  )
                                                  : null,
                                          onTap: () {
                                            // Naviguer vers la page de profil utilisateur
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        UserProfilePage(
                                                          userId: participantId,
                                                        ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
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
  }
}
