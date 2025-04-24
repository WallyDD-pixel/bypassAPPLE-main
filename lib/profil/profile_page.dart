import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../couleur/background_widget.dart'; // Importez votre widget d'arrière-plan
import 'publication.dart'; // Importez votre page des publications

class UserProfilePage extends StatelessWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

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
                // AppBar personnalisée avec le nom d'utilisateur
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
                      FutureBuilder<DocumentSnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .get(), // Récupérer les données de l'utilisateur
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text(
                              'Chargement...',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                              ),
                            );
                          }

                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const Text(
                              'Utilisateur introuvable',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                              ),
                            );
                          }

                          final userData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final userName =
                              userData['username'] ?? 'Utilisateur inconnu';

                          return Text(
                            userName.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(), // Récupérer les données de l'utilisateur
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Center(
                          child: Text(
                            'Utilisateur introuvable.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        );
                      }

                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final userName =
                          userData['username'] ?? 'Utilisateur inconnu';
                      final userPhotoUrl = userData['photoURL'];
                      final userBio = userData['bio'] ?? 'Aucune biographie';
                      final userPosts =
                          userData['posts'] as List<dynamic>? ?? [];

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Photo de profil centrée
                            Center(
                              child:
                                  userPhotoUrl != null
                                      ? CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          userPhotoUrl,
                                        ),
                                        radius: 60,
                                      )
                                      : const CircleAvatar(
                                        backgroundColor: Colors.grey,
                                        radius: 60,
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 60,
                                        ),
                                      ),
                            ),
                            const SizedBox(height: 16),
                            // Nom d'utilisateur centré
                            Center(
                              child: Text(
                                userName.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Biographie centrée
                            Center(
                              child: Text(
                                userBio,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Section "Publications"
                            Text(
                              'Publications',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Grille des publications
                            Expanded(
                              child:
                                  userPosts.isNotEmpty
                                      ? GridView.builder(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3, // 3 colonnes
                                              crossAxisSpacing: 8,
                                              mainAxisSpacing: 8,
                                            ),
                                        itemCount: userPosts.length,
                                        itemBuilder: (context, index) {
                                          final postUrl = userPosts[index];
                                          return GestureDetector(
                                            onTap: () {
                                              // Naviguer vers la page des publications
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => PublicationsPage(
                                                        imageUrls:
                                                            userPosts
                                                                .cast<
                                                                  String
                                                                >(), // Passez la liste des images
                                                      ),
                                                ),
                                              );
                                            },
                                            child: Card(
                                              elevation:
                                                  4, // Ombre sous la carte
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                    image: NetworkImage(
                                                      postUrl,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                      : const Center(
                                        child: Text(
                                          'Aucune publication disponible.',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                          ),
                                        ),
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
