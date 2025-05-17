import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../couleur/background_widget.dart'; // Import du BackgroundWidget

class AlternativePage extends StatelessWidget {
  final String userId;
  final String groupId;

  const AlternativePage({
    super.key,
    required this.userId,
    required this.groupId,
  });

  Future<Map<String, dynamic>?> _fetchUserData(String userId) async {
    try {
      debugPrint('Récupération des données utilisateur pour userId: $userId');
      final userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userSnapshot.exists) {
        debugPrint(
          'Données utilisateur récupérées avec succès : ${userSnapshot.data()}',
        );
        return userSnapshot.data();
      } else {
        debugPrint('Aucune donnée trouvée pour userId: $userId');
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des données utilisateur : $e');
    }
    return null;
  }

  Future<void> _acceptRequest(BuildContext context) async {
    try {
      debugPrint(
        'Recherche du document dans groupJoinRequests pour userId: $userId et groupId: $groupId',
      );

      // Rechercher le document correspondant à userId et groupId
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('groupJoinRequests')
              .where('userId', isEqualTo: userId)
              .where('groupId', isEqualTo: groupId)
              .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint(
          'Aucun document trouvé pour userId: $userId et groupId: $groupId',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur : Document introuvable.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Récupérer le premier document correspondant
      final doc = querySnapshot.docs.first;
      debugPrint('Document trouvé : ${doc.id}, données : ${doc.data()}');

      // Mettre à jour le statut
      await doc.reference.update({'status': 'accepted'});

      debugPrint('Statut mis à jour avec succès pour le document : ${doc.id}');

      // Récupérer les informations de l'utilisateur
      final userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (!userSnapshot.exists) {
        debugPrint('Utilisateur introuvable pour userId: $userId');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur : Utilisateur introuvable.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userData = userSnapshot.data()!;
      final sexe = userData['sexe'] ?? 'unknown';

      // Ajouter l'utilisateur dans le groupe
      final groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId);

      final groupSnapshot = await groupRef.get();
      if (!groupSnapshot.exists) {
        debugPrint('Groupe introuvable pour groupId: $groupId');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur : Groupe introuvable.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final groupData = groupSnapshot.data()!;
      final members = groupData['members'] as Map<String, dynamic>? ?? {};

      if (sexe == 'homme') {
        debugPrint('Ajout de l\'utilisateur dans la liste des hommes');
        await groupRef.update({
          'members.men': FieldValue.arrayUnion([userId]),
        });
      } else if (sexe == 'femme') {
        debugPrint('Ajout de l\'utilisateur dans la liste des femmes');
        await groupRef.update({
          'members.women': FieldValue.arrayUnion([userId]),
        });
      } else {
        debugPrint('Sexe inconnu pour userId: $userId');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur : Sexe inconnu.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      debugPrint('Utilisateur ajouté avec succès dans le groupe');

      // Ajouter l'utilisateur au chat du groupe
      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(groupId);
      final chatSnapshot = await chatRef.get();

      if (!chatSnapshot.exists) {
        // Si le chat n'existe pas encore, le créer
        await chatRef.set({
          'groupId': groupId,
          'createdAt': FieldValue.serverTimestamp(),
          'members': [userId],
        });
        debugPrint('Chat créé pour le groupe : $groupId');
      } else {
        // Ajouter l'utilisateur à la liste des membres du chat
        await chatRef.update({
          'members': FieldValue.arrayUnion([userId]),
        });
        debugPrint('Utilisateur ajouté au chat du groupe : $groupId');
      }

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Utilisateur accepté et ajouté au groupe et au chat avec succès !',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Retour à la page précédente
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint(
        'Erreur lors de la mise à jour du statut ou de l\'ajout au groupe/chat : $e',
      );
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
          // Fond animé
          const BackgroundWidget(),

          // Contenu principal
          Column(
            children: [
              // Barre personnalisée
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Row(
                  children: [
                    // Bouton de retour
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () {
                        debugPrint('Retour à la page précédente');
                        Navigator.of(
                          context,
                        ).pop(); // Retour à la page précédente
                      },
                    ),
                    // Texte de l'AppBar
                    Text(
                      '📋 Confirmation',
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

              // Contenu explicatif
              Expanded(
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchUserData(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      debugPrint('Chargement des données utilisateur...');
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      );
                    }

                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      debugPrint('Erreur ou aucune donnée utilisateur trouvée');
                      return const Center(
                        child: Text(
                          'Erreur lors du chargement des informations utilisateur.',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final userData = snapshot.data!;
                    final userName = userData['username'] ?? 'Nom inconnu';
                    final userPhoto = userData['photoURL'];

                    debugPrint(
                      'Affichage des informations utilisateur : $userData',
                    );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre principal
                          Card(
                            color: Colors.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Les femmes n\'ont pas besoin de payer pour rejoindre un groupe.',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Explications détaillées
                          Card(
                            color: Colors.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Comment cela fonctionne ?',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '1️⃣ Une fois que vous avez accepté une femme dans votre groupe, elle sera automatiquement liée à un homme de votre groupe.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '2️⃣ Ce processus garantit une expérience sécurisée et organisée pour tous les membres du groupe.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Confirmation d'ajout
                          Card(
                            color: Colors.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Photo de l'utilisateur
                                  if (userPhoto != null)
                                    ClipOval(
                                      child: Image.network(
                                        userPhoto,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.person,
                                      size: 100,
                                      color: Colors.grey,
                                    ),
                                  const SizedBox(height: 16),

                                  // Nom de l'utilisateur
                                  Text(
                                    userName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Texte de confirmation
                                  Text(
                                    'Êtes-vous sûr de vouloir accepter $userName dans votre groupe ?',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Boutons d'action
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Bouton Annuler
                                      OutlinedButton(
                                        onPressed: () {
                                          debugPrint(
                                            'Action annulée par l\'utilisateur',
                                          );
                                          Navigator.of(
                                            context,
                                          ).pop(); // Annuler
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'ANNULER',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),

                                      // Bouton Accepter
                                      OutlinedButton(
                                        onPressed: () {
                                          debugPrint('Bouton Accepter cliqué');
                                          _acceptRequest(context);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'ACCEPTER',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
        ],
      ),
    );
  }
}
