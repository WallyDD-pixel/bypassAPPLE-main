import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './qr.dart'; // Assurez-vous que QRCodePage est bien défini dans ce fichier
import '../couleur/background_widget.dart'; // Import du BackgroundWidget

class GroupListPage extends StatelessWidget {
  const GroupListPage({super.key});

  Future<List<Map<String, dynamic>>> _fetchAcceptedGroups() async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      // Récupérer les groupes où l'utilisateur est accepté
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('groupJoinRequests')
              .where(
                'status',
                isEqualTo: 'accepted',
              ) // Filtrer par statut accepté
              .where(
                'userId',
                isEqualTo: userId,
              ) // Filtrer par utilisateur actuel
              .get();

      // Transformer les documents en une liste de Map
      final List<Map<String, dynamic>> groups = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final String groupId = data['groupId'] ?? 'ID non spécifié';

        // Récupérer le créateur du groupe depuis la collection "groups"
        final groupSnapshot =
            await FirebaseFirestore.instance
                .collection('groups')
                .doc(groupId)
                .get();

        if (groupSnapshot.exists) {
          final groupData = groupSnapshot.data();
          final String createdBy =
              groupData?['createdBy'] ?? 'Créateur inconnu';

          // Récupérer le username et la photoURL du créateur depuis la collection "users"
          final userSnapshot =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(createdBy)
                  .get();

          final String username =
              userSnapshot.exists
                  ? (userSnapshot.data()?['username'] ?? 'Utilisateur inconnu')
                  : 'Utilisateur inconnu';

          final String? photoURL =
              userSnapshot.exists
                  ? (userSnapshot.data() != null
                      ? userSnapshot.data()!['photoURL']
                      : null)
                  : null;

          // Ajouter les données au groupe
          groups.add({
            "groupId": groupId,
            "creatorId": createdBy,
            "creatorUsername": username,
            "photoURL": photoURL, // Ajout de la photoURL
            "eventId": data['eventId'] ?? 'Événement non spécifié',
            "paymentIntentId":
                data['paymentIntentId'] ?? 'Paiement non spécifié',
            "price": data['price'] ?? 0,
            "scanqr": data['scanqr'] ?? true,
            "status": data['status'] ?? 'Statut inconnu',
            "createdAt": data['createdAt'] ?? 'Date non spécifiée',
          });
        }
      }

      return groups;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des groupes : $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundWidget(), // Ajout du BackgroundWidget
          Column(
            children: [
              AppBar(
                title: Text(
                  'Mes Groupes Acceptés',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchAcceptedGroups(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erreur lors du chargement des groupes.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      );
                    }

                    final groups = snapshot.data ?? [];

                    if (groups.isEmpty) {
                      return Center(
                        child: Text(
                          'Vous n\'êtes accepté dans aucun groupe.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        final bool isScanned =
                            group['scanqr'] ==
                            true; // Vérifier si scanqr est true

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              0.1,
                            ), // Transparence
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  0.2,
                                ), // Ombre légère
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              radius: 35, // Augmenter la taille du CircleAvatar
                              backgroundImage:
                                  group['photoURL'] != null
                                      ? NetworkImage(
                                        group['photoURL']!,
                                      ) // Charger l'image depuis le champ photoURL
                                      : null, // Si aucune URL n'est disponible
                              child:
                                  group['photoURL'] == null
                                      ? const Icon(
                                        Icons
                                            .person, // Icône par défaut si pas de photo
                                        color: Colors.white,
                                        size:
                                            40, // Augmenter la taille de l'icône par défaut
                                      )
                                      : null,
                            ),
                            title: Text(
                              'GROUPE DE ${group['creatorUsername']}'
                                  .toUpperCase(), // Convertir en majuscules
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                fontStyle: FontStyle.italic, // Italique
                                color:
                                    Colors
                                        .white, // Texte blanc pour contraster avec le fond
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  '${group['price']} €', // Afficher uniquement le prix
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        24, // Taille plus grande pour le prix
                                    color:
                                        Colors
                                            .greenAccent, // Couleur verte pour mettre en valeur
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isScanned
                                            ? Colors.red.withOpacity(
                                              0.2,
                                            ) // Fond rouge si déjà scanné
                                            : Colors.green.withOpacity(
                                              0.2,
                                            ), // Fond vert sinon
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isScanned
                                        ? 'DÉJÀ SCANNÉ'
                                        : 'ACCEPTÉ', // Texte conditionnel
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color:
                                          isScanned
                                              ? Colors
                                                  .redAccent // Couleur rouge si déjà scanné
                                              : Colors
                                                  .greenAccent, // Couleur verte sinon
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing:
                                isScanned
                                    ? const Icon(
                                      Icons.check_circle,
                                      color:
                                          Colors
                                              .red, // Icône rouge si déjà scanné
                                      size: 40,
                                    )
                                    : Container(
                                      padding: const EdgeInsets.all(
                                        8,
                                      ), // Espacement interne
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(
                                          0.2,
                                        ), // Fond légèrement coloré
                                        shape:
                                            BoxShape.circle, // Forme circulaire
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ), // Ombre subtile
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.qr_code,
                                        color: Colors.green,
                                        size: 40, // Taille de l'icône
                                      ),
                                    ),
                            onTap:
                                isScanned
                                    ? null // Désactiver l'interaction si déjà scanné
                                    : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => QRCodeScanPage(),
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
        ],
      ),
    );
  }
}
