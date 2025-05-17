import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../couleur/background_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'qr.dart'; // Importez votre page de scan QR Code

class CreatorGroupsPage extends StatelessWidget {
  const CreatorGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundWidget(), // Arrière-plan animé
          Column(
            children: [
              AppBar(
                title: Text(
                  'Mes Groupes Créés',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('groups')
                          .where('createdBy', isEqualTo: userId)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
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

                    final groups = snapshot.data!.docs;

                    if (groups.isEmpty) {
                      return Center(
                        child: Text(
                          'Vous n\'avez créé aucun groupe.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group =
                            groups[index].data() as Map<String, dynamic>;
                        final eventId = group['eventId'];

                        if (eventId == null) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: Colors.white.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                'Aucun événement associé.',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[300],
                                ),
                              ),
                            ),
                          );
                        }

                        return FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('events')
                                  .doc(eventId)
                                  .get(),
                          builder: (context, eventSnapshot) {
                            if (eventSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                color: Colors.white.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const ListTile(
                                  title: Text(
                                    'Chargement...',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              );
                            }

                            if (eventSnapshot.hasError ||
                                !eventSnapshot.hasData ||
                                !eventSnapshot.data!.exists) {
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                color: Colors.white.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const ListTile(
                                  title: Text(
                                    'Événement introuvable.',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              );
                            }

                            final eventData =
                                eventSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            final eventName =
                                eventData['name'] ?? 'Nom inconnu';
                            final eventDescription =
                                eventData['description'] ??
                                'Aucune description';
                            final eventDate =
                                eventData['date'] ?? 'Date inconnue';
                            final eventLocation =
                                eventData['location'] ?? 'Lieu inconnu';
                            final eventEtablissement =
                                eventData['etablissement'] ??
                                'Établissement inconnu';
                            final eventImageUrl = eventData['imageUrl'] ?? '';

                            return GestureDetector(
                              onTap: () {
                                // Afficher le groupId dans la console de débogage
                                final groupId = group['id'] ?? groups[index].id;
                                debugPrint('Group ID : $groupId');

                                // Naviguer vers la page de scan QR Code
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => QRCodeScanPage(
                                          groupId:
                                              groupId, // Passer le groupId à la page de scan
                                        ),
                                  ),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                color: Colors.white.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (eventImageUrl.isNotEmpty)
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                        child: Image.network(
                                          eventImageUrl,
                                          width: double.infinity,
                                          height: 150,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            eventName.toUpperCase(),
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontStyle: FontStyle.italic,
                                              fontSize: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Date : $eventDate',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey[300],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Lieu : $eventLocation',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey[300],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Établissement : $eventEtablissement',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey[300],
                                            ),
                                          ),
                                        ],
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
