import 'dart:ui'; // Import nécessaire pour BackdropFilter
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import pour récupérer l'utilisateur connecté
import '../../../../../couleur/background_widget.dart'; // Import du background animé
import 'package:google_fonts/google_fonts.dart';
import './valider.dart'; // Import de la page de demande envoyée

class NewPageForWomen extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String eventId;

  const NewPageForWomen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.eventId,
  });

  Future<void> _sendJoinRequest(BuildContext context) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final documentId =
          '$groupId-$userId'; // ID du document sous la forme groupId-userId

      // Vérifier si une demande existe déjà
      final existingRequest =
          await FirebaseFirestore.instance
              .collection('groupJoinRequests')
              .doc(documentId)
              .get();

      if (existingRequest.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez déjà envoyé une demande pour ce groupe.'),
          ),
        );
        return;
      }

      // Récupérer le creatorId depuis la collection 'groups'
      final groupSnapshot =
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(groupId)
              .get();

      if (!groupSnapshot.exists) {
        throw Exception('Le groupe avec l\'ID $groupId n\'existe pas.');
      }

      final groupData = groupSnapshot.data() as Map<String, dynamic>;
      final String creatorId = groupData['createdBy'] ?? '';

      // Ajouter une nouvelle demande dans Firestore
      await FirebaseFirestore.instance
          .collection('groupJoinRequests')
          .doc(documentId)
          .set({
            'groupId': groupId,
            'userId': userId,
            'creatorId': creatorId, // Ajouter le creatorId récupéré
            'status': 'pending', // Statut initial de la demande
            'eventId': eventId,
            'sexe': 'femme', // Sexe de l'utilisateur
            'createdAt':
                FieldValue.serverTimestamp(), // Date et heure de la demande
          });

      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const RequestSentPage()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi de la demande : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final documentId =
        '$groupId-$userId'; // ID du document sous la forme groupId-userId

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
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
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
                    Expanded(
                      child: Text(
                        'PRÉVISUALISATION DES GROUPES',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section d'explications
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Cette page affiche les membres du groupe sélectionné. '
                  'Les garçons sont affichés en haut et les filles en bas. '
                  'Chaque membre est représenté par une photo de profil et un pseudo.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // Contenu principal
              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('groups')
                          .doc(groupId) // Utiliser l'ID du document groupId
                          .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      );
                    }

                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        !snapshot.data!.exists) {
                      return Center(
                        child: Text(
                          'Erreur lors du chargement des membres du groupe.',
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    final groupData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final members =
                        groupData['members'] as Map<String, dynamic>? ?? {};
                    final men = (members['men'] as List?) ?? [];
                    final women = (members['women'] as List?) ?? [];

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Liste des hommes
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children:
                                men.map((userId) {
                                  return FutureBuilder<DocumentSnapshot>(
                                    future:
                                        FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(userId)
                                            .get(),
                                    builder: (context, userSnapshot) {
                                      if (userSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          width: 150,
                                          height: 200,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }

                                      if (userSnapshot.hasError ||
                                          !userSnapshot.hasData) {
                                        return const SizedBox(
                                          width: 150,
                                          height: 200,
                                          child: Center(
                                            child: Icon(
                                              Icons.error,
                                              color: Colors.red,
                                            ),
                                          ),
                                        );
                                      }

                                      final userData =
                                          userSnapshot.data!.data()
                                              as Map<String, dynamic>;
                                      final photoURL =
                                          userData['photoURL'] as String?;
                                      final username =
                                          userData['username'] as String? ??
                                          'Inconnu';

                                      return Container(
                                        width: 150,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.blue.withOpacity(0.5),
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Stack(
                                            children: [
                                              // Photo de profil
                                              photoURL != null
                                                  ? Image.network(
                                                    photoURL,
                                                    width: 150,
                                                    height: 200,
                                                    fit: BoxFit.cover,
                                                  )
                                                  : Container(
                                                    width: 150,
                                                    height: 200,
                                                    color: Colors.grey,
                                                    child: const Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                      size: 60,
                                                    ),
                                                  ),
                                              // Effet de flou
                                              Positioned.fill(
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                    sigmaX: 5,
                                                    sigmaY: 5,
                                                  ),
                                                  child: Container(
                                                    color: Colors.blue
                                                        .withOpacity(0.2),
                                                  ),
                                                ),
                                              ),
                                              // Nom de l'utilisateur
                                              Center(
                                                child: Text(
                                                  username,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 32),

                          // Liste des femmes
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children:
                                women.map((userId) {
                                  return FutureBuilder<DocumentSnapshot>(
                                    future:
                                        FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(userId)
                                            .get(),
                                    builder: (context, userSnapshot) {
                                      if (userSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          width: 150,
                                          height: 200,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }

                                      if (userSnapshot.hasError ||
                                          !userSnapshot.hasData) {
                                        return const SizedBox(
                                          width: 150,
                                          height: 200,
                                          child: Center(
                                            child: Icon(
                                              Icons.error,
                                              color: Colors.red,
                                            ),
                                          ),
                                        );
                                      }

                                      final userData =
                                          userSnapshot.data!.data()
                                              as Map<String, dynamic>;
                                      final photoURL =
                                          userData['photoURL'] as String?;
                                      final username =
                                          userData['username'] as String? ??
                                          'Inconnu';

                                      return Container(
                                        width: 150,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.pink.withOpacity(0.5),
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Stack(
                                            children: [
                                              // Photo de profil
                                              photoURL != null
                                                  ? Image.network(
                                                    photoURL,
                                                    width: 150,
                                                    height: 200,
                                                    fit: BoxFit.cover,
                                                  )
                                                  : Container(
                                                    width: 150,
                                                    height: 200,
                                                    color: Colors.grey,
                                                    child: const Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                      size: 60,
                                                    ),
                                                  ),
                                              // Effet de flou
                                              Positioned.fill(
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                    sigmaX: 5,
                                                    sigmaY: 5,
                                                  ),
                                                  child: Container(
                                                    color: Colors.pink
                                                        .withOpacity(0.2),
                                                  ),
                                                ),
                                              ),
                                              // Nom de l'utilisateur
                                              Center(
                                                child: Text(
                                                  username,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bouton pour envoyer une demande
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16.0,
                  16.0,
                  16.0,
                  32.0,
                ), // Augmente le padding en bas
                child: ElevatedButton(
                  onPressed: () => _sendJoinRequest(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Faire une demande pour rejoindre',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
