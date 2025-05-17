import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../couleur/background_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './qr.dart'; // Assurez-vous que QRCodePage est bien défini dans ce fichier
import 'package:intl/intl.dart'; // Importer intl pour formater les dates
import './genererDemande/genererDemande.dart'; // Importer la page de génération de QR Code

class RequestedGroupsPage extends StatelessWidget {
  const RequestedGroupsPage({super.key});

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
                  'Mes Demandes de Groupes',
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
                          .collection('groupJoinRequests')
                          .where('userId', isEqualTo: userId)
                          .where(
                            'status',
                            isEqualTo: 'accepted',
                          ) // Exclure les demandes en attente
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.blue),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(
                        child: Text(
                          'Vous n\'avez aucune demande acceptée.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color.fromARGB(255, 188, 188, 188),
                          ),
                        ),
                      );
                    }

                    final requests = snapshot.data!.docs;

                    if (requests.isEmpty) {
                      return Center(
                        child: Text(
                          'Vous n\'avez fait aucune demande.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request =
                            requests[index].data() as Map<String, dynamic>;
                        final groupId = request['groupId'];

                        if (groupId == null) {
                          return const SizedBox(); // Ignorer si groupId est null
                        }

                        return FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('groups')
                                  .doc(groupId)
                                  .get(),
                          builder: (context, groupSnapshot) {
                            if (groupSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (groupSnapshot.hasError ||
                                !groupSnapshot.hasData ||
                                !groupSnapshot.data!.exists) {
                              return const Center(
                                child: Text(
                                  'Erreur lors du chargement des informations du groupe.',
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            }

                            final groupData =
                                groupSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            final eventId =
                                groupData['eventId'] ?? 'ID événement inconnu';
                            final creatorId =
                                groupData['createdBy'] ?? 'ID inconnu';
                            final men = groupData['members']['men'] ?? [];
                            final women = groupData['members']['women'] ?? [];

                            return FutureBuilder<DocumentSnapshot>(
                              future:
                                  FirebaseFirestore.instance
                                      .collection('events')
                                      .doc(eventId)
                                      .get(),
                              builder: (context, eventSnapshot) {
                                if (eventSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (eventSnapshot.hasError ||
                                    !eventSnapshot.hasData ||
                                    !eventSnapshot.data!.exists) {
                                  return const Center(
                                    child: Text(
                                      'Erreur lors du chargement des informations de l\'événement.',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  );
                                }

                                final eventData =
                                    eventSnapshot.data!.data()
                                        as Map<String, dynamic>;
                                final eventName =
                                    eventData['name'] ??
                                    'Nom de l\'événement inconnu';
                                final eventEtablissement =
                                    eventData['etablissement'] ??
                                    'Établissement inconnu';
                                final eventLocation =
                                    eventData['location'] ?? 'Lieu inconnu';
                                final eventDateRaw =
                                    eventData['date'] ?? 'Date non spécifiée';

                                // Formater la date
                                String eventDateFormatted;
                                try {
                                  if (eventDateRaw is Timestamp) {
                                    // Convertir le Timestamp en DateTime
                                    final dateTime = eventDateRaw.toDate();
                                    // Formater la date
                                    eventDateFormatted = DateFormat(
                                      'dd MMMM yyyy à HH:mm',
                                      'fr_FR',
                                    ).format(dateTime);
                                  } else if (eventDateRaw is String) {
                                    // Si la date est déjà une chaîne, la convertir en DateTime
                                    final dateTime = DateTime.parse(
                                      eventDateRaw,
                                    );
                                    eventDateFormatted = DateFormat(
                                      'dd MMMM yyyy à HH:mm',
                                      'fr_FR',
                                    ).format(dateTime);
                                  } else {
                                    // Si le format est inconnu, afficher la valeur brute
                                    eventDateFormatted =
                                        eventDateRaw.toString();
                                  }
                                } catch (e) {
                                  // En cas d'erreur, afficher la valeur brute
                                  eventDateFormatted = eventDateRaw.toString();
                                }

                                return FutureBuilder<DocumentSnapshot>(
                                  future:
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(creatorId)
                                          .get(),
                                  builder: (context, userSnapshot) {
                                    if (userSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    if (userSnapshot.hasError ||
                                        !userSnapshot.hasData ||
                                        !userSnapshot.data!.exists) {
                                      return const Center(
                                        child: Text(
                                          'Erreur lors du chargement des informations du créateur.',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      );
                                    }

                                    final userData =
                                        userSnapshot.data!.data()
                                            as Map<String, dynamic>;
                                    final creatorName =
                                        userData['username'] ?? 'Nom inconnu';

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 16,
                                      ),
                                      color: Colors.white.withOpacity(0.1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Titre
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.event,
                                                  color: Colors.blue,
                                                  size: 40,
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Text(
                                                    eventName,
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),

                                            // Informations principales
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on,
                                                  color: Colors.green,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Lieu : $eventLocation',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      color: Colors.grey[300],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.business,
                                                  color: Colors.orange,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Établissement : $eventEtablissement',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      color: Colors.grey[300],
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
                                                ...men.map<Widget>((userId) {
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
                                                      userSnapshot,
                                                    ) {
                                                      if (userSnapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return const SizedBox(
                                                          width: 40,
                                                          height: 40,
                                                          child:
                                                              CircularProgressIndicator(),
                                                        );
                                                      }

                                                      if (userSnapshot
                                                              .hasError ||
                                                          !userSnapshot
                                                              .hasData) {
                                                        return const Icon(
                                                          Icons.error,
                                                          color: Colors.red,
                                                        );
                                                      }

                                                      final userData =
                                                          userSnapshot.data!
                                                                  .data()
                                                              as Map<
                                                                String,
                                                                dynamic
                                                              >;
                                                      final photoURL =
                                                          userData['photoURL'];

                                                      return Tooltip(
                                                        message:
                                                            userData['username'] ??
                                                            'Nom inconnu',
                                                        child: Container(
                                                          width: 40,
                                                          height: 40,
                                                          decoration:
                                                              BoxDecoration(
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                                border: Border.all(
                                                                  color:
                                                                      Colors
                                                                          .blue,
                                                                  width: 2,
                                                                ),
                                                              ),
                                                          child: ClipOval(
                                                            child:
                                                                photoURL != null
                                                                    ? Image.network(
                                                                      photoURL,
                                                                      fit:
                                                                          BoxFit
                                                                              .cover,
                                                                    )
                                                                    : const Icon(
                                                                      Icons
                                                                          .person,
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
                                                ...women.map<Widget>((userId) {
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
                                                      userSnapshot,
                                                    ) {
                                                      if (userSnapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return const SizedBox(
                                                          width: 40,
                                                          height: 40,
                                                          child:
                                                              CircularProgressIndicator(),
                                                        );
                                                      }

                                                      if (userSnapshot
                                                              .hasError ||
                                                          !userSnapshot
                                                              .hasData) {
                                                        return const Icon(
                                                          Icons.error,
                                                          color: Colors.red,
                                                        );
                                                      }

                                                      final userData =
                                                          userSnapshot.data!
                                                                  .data()
                                                              as Map<
                                                                String,
                                                                dynamic
                                                              >;
                                                      final photoURL =
                                                          userData['photoURL'];

                                                      return Tooltip(
                                                        message:
                                                            userData['username'] ??
                                                            'Nom inconnu',
                                                        child: Container(
                                                          width: 40,
                                                          height: 40,
                                                          decoration:
                                                              BoxDecoration(
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                                border: Border.all(
                                                                  color:
                                                                      Colors
                                                                          .pink,
                                                                  width: 2,
                                                                ),
                                                              ),
                                                          child: ClipOval(
                                                            child:
                                                                photoURL != null
                                                                    ? Image.network(
                                                                      photoURL,
                                                                      fit:
                                                                          BoxFit
                                                                              .cover,
                                                                    )
                                                                    : const Icon(
                                                                      Icons
                                                                          .person,
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

                                            // Bouton "Générer le QR Code"
                                            Center(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  // Naviguer vers la page de génération de QR Code
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              QRCodePage(
                                                                groupId:
                                                                    groupId,
                                                                userId: userId,
                                                              ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'GÉNÉRER LE QR CODE',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
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
