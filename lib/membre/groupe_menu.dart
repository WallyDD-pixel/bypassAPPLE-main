import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../couleur/background_widget.dart'; // Importez votre widget d'arrière-plan
import 'groupe_membre.dart'; // Importez votre page de membres de groupe

class GroupMenuPage extends StatelessWidget {
  final String groupId;

  const GroupMenuPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Ajuste le contenu pour éviter la superposition
      body: Stack(
        children: [
          // Arrière-plan animé
          const BackgroundWidget(),
          // Contenu principal avec AppBar
          SafeArea(
            child: Column(
              children: [
                // AppBar personnalisée
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          Navigator.of(context).pop(); // Bouton de retour
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'MENU DU GROUPE',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Contenu principal
                Expanded(
                  child: FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('groups')
                            .doc(groupId)
                            .get(), // Récupérer le document du groupe
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Center(
                          child: Text(
                            'Groupe introuvable.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        );
                      }

                      final groupData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final createdBy =
                          groupData['createdBy'] as String?; // ID du créateur
                      final eventId =
                          groupData['eventId'] as String?; // ID de l'événement
                      final arrivalTimeRaw = groupData['arrivalTime'];
                      Timestamp? arrivalTime;

                      if (arrivalTimeRaw is Timestamp) {
                        arrivalTime =
                            arrivalTimeRaw; // Si c'est déjà un Timestamp
                      } else if (arrivalTimeRaw is Map<String, dynamic>) {
                        // Si c'est un objet, convertissez-le en Timestamp
                        final seconds = arrivalTimeRaw['_seconds'] as int?;
                        final nanoseconds =
                            arrivalTimeRaw['_nanoseconds'] as int?;
                        if (seconds != null && nanoseconds != null) {
                          arrivalTime = Timestamp(seconds, nanoseconds);
                        }
                      }

                      if (createdBy == null) {
                        return const Center(
                          child: Text(
                            'Créateur introuvable.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        );
                      }

                      return FutureBuilder<DocumentSnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(createdBy)
                                .get(), // Récupérer les données du créateur
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return const Center(
                              child: Text(
                                'Créateur introuvable.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }

                          final userData =
                              userSnapshot.data!.data() as Map<String, dynamic>;
                          final creatorName =
                              userData['username'] ?? 'Utilisateur inconnu';
                          final creatorPhotoUrl = userData['photoURL'];

                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Informations sur le créateur
                                Row(
                                  children: [
                                    creatorPhotoUrl != null
                                        ? CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            creatorPhotoUrl,
                                          ),
                                          radius: 30,
                                        )
                                        : const CircleAvatar(
                                          backgroundColor: Colors.grey,
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.white,
                                          ),
                                          radius: 30,
                                        ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Titre "GROUPE DE [Nom du créateur]"
                                        Text(
                                          'GROUPE DE ${creatorName.toUpperCase()}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            fontStyle: FontStyle.italic,
                                            color: const Color.fromARGB(
                                              255,
                                              255,
                                              255,
                                              255,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        // Texte explicatif "Heure d'arrivée"
                                        Text(
                                          'HEURE D\'ARRIVÉE : ${arrivalTime != null ? _formatArrivalTime(arrivalTime) : 'Non spécifiée'}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontStyle: FontStyle.italic,
                                            color: const Color.fromARGB(
                                              255,
                                              255,
                                              255,
                                              255,
                                            ), // Texte en blanc
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Récupérer et afficher les informations de l'événement
                                if (eventId != null)
                                  FutureBuilder<DocumentSnapshot>(
                                    future:
                                        FirebaseFirestore.instance
                                            .collection('events')
                                            .doc(eventId)
                                            .get(), // Récupérer les données de l'événement
                                    builder: (context, eventSnapshot) {
                                      if (eventSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      if (!eventSnapshot.hasData ||
                                          !eventSnapshot.data!.exists) {
                                        return const Center(
                                          child: Text(
                                            'Événement introuvable.',
                                            style: TextStyle(
                                              color: Color.fromARGB(
                                                255,
                                                255,
                                                255,
                                                255,
                                              ),
                                              fontSize: 16,
                                            ),
                                          ),
                                        );
                                      }

                                      final eventData =
                                          eventSnapshot.data!.data()
                                              as Map<String, dynamic>;
                                      final eventImage =
                                          eventData['imageUrl'] ?? '';
                                      final eventName =
                                          eventData['name'] ??
                                          'Nom de l\'événement';
                                      final eventLocation =
                                          eventData['location'] ??
                                          'Localisation inconnue';
                                      final eventDateTimestamp =
                                          eventData['date'] as Timestamp?;
                                      final eventDate =
                                          eventDateTimestamp != null
                                              ? _formatTimestamp(
                                                eventDateTimestamp,
                                              )
                                              : 'Date inconnue';
                                      final eventEtablissement =
                                          eventData['etablissement'] ??
                                          'Établissement inconnu';

                                      return Column(
                                        children: [
                                          Card(
                                            color: const Color.fromARGB(
                                              36,
                                              0,
                                              0,
                                              0,
                                            ),
                                            elevation: 4,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Image de l'événement
                                                if (eventImage.isNotEmpty)
                                                  ClipRRect(
                                                    borderRadius:
                                                        const BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            12,
                                                          ),
                                                        ),
                                                    child: Image.network(
                                                      eventImage,
                                                      height: 200,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    16.0,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Nom de l'événement
                                                      Text(
                                                        eventName.toUpperCase(),
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 30,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          color:
                                                              const Color.fromARGB(
                                                                255,
                                                                255,
                                                                255,
                                                                255,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      // Établissement
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.business,
                                                            color: Colors.grey,
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Text(
                                                            eventEtablissement,
                                                            style: const TextStyle(
                                                              fontSize: 16,
                                                              color:
                                                                  Color.fromARGB(
                                                                    221,
                                                                    255,
                                                                    253,
                                                                    253,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      // Localisation
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.location_on,
                                                            color: Colors.grey,
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Text(
                                                            eventLocation,
                                                            style: const TextStyle(
                                                              fontSize: 16,
                                                              color:
                                                                  Color.fromARGB(
                                                                    221,
                                                                    255,
                                                                    255,
                                                                    255,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      // Date
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .calendar_today,
                                                            color: Colors.grey,
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Text(
                                                            eventDate,
                                                            style: const TextStyle(
                                                              fontSize: 16,
                                                              color:
                                                                  Color.fromARGB(
                                                                    221,
                                                                    239,
                                                                    239,
                                                                    239,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          // Bouton "PARTICIPANTS"
                                          Column(
                                            children: [
                                              Card(
                                                color: const Color.fromARGB(
                                                  22,
                                                  0,
                                                  0,
                                                  0,
                                                ),
                                                elevation: 4,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  side: const BorderSide(
                                                    color: Color.fromARGB(
                                                      255,
                                                      255,
                                                      255,
                                                      255,
                                                    ), // Couleur des contours
                                                    width:
                                                        2.0, // Épaisseur des contours
                                                  ),
                                                ),
                                                child: InkWell(
                                                  onTap: () {
                                                    // Naviguer vers la page des membres du groupe
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (context) =>
                                                                GroupMembersPage(
                                                                  groupId:
                                                                      groupId,
                                                                ),
                                                      ),
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 16.0,
                                                          horizontal: 24.0,
                                                        ),
                                                    child: Center(
                                                      child: Text(
                                                        'PARTICIPANTS',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 16,
                                              ), // Espacement entre les deux cartes
                                              Card(
                                                color: const Color.fromARGB(
                                                  22,
                                                  0,
                                                  0,
                                                  0,
                                                ),
                                                elevation: 4,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  side: const BorderSide(
                                                    color: Color.fromARGB(
                                                      255,
                                                      255,
                                                      255,
                                                      255,
                                                    ), // Couleur des contours
                                                    width:
                                                        2.0, // Épaisseur des contours
                                                  ),
                                                ),
                                                child: InkWell(
                                                  onTap: () {
                                                    // Action pour quitter le groupe
                                                    showDialog(
                                                      context: context,
                                                      builder:
                                                          (
                                                            context,
                                                          ) => AlertDialog(
                                                            backgroundColor:
                                                                const Color.fromARGB(
                                                                  255,
                                                                  30,
                                                                  30,
                                                                  30,
                                                                ), // Fond sombre
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    16,
                                                                  ), // Coins arrondis
                                                            ),
                                                            title: Text(
                                                              'Quitter le groupe',
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                            ),
                                                            content: Text(
                                                              'Êtes-vous sûr de vouloir quitter ce groupe ? Cette action est irréversible.',
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 16,
                                                                color:
                                                                    Colors
                                                                        .grey[400],
                                                              ),
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(); // Fermer la boîte de dialogue
                                                                },
                                                                style: TextButton.styleFrom(
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white, // Couleur du texte
                                                                  textStyle: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                child:
                                                                    const Text(
                                                                      'ANNULER',
                                                                    ),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () {
                                                                  // Logique pour quitter le groupe
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(); // Fermer la boîte de dialogue
                                                                  // Ajoutez ici la logique pour quitter le groupe
                                                                },
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red, // Couleur du bouton
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          12,
                                                                        ), // Coins arrondis
                                                                  ),
                                                                  padding: const EdgeInsets.symmetric(
                                                                    vertical:
                                                                        12.0,
                                                                    horizontal:
                                                                        24.0,
                                                                  ),
                                                                ),
                                                                child: Text(
                                                                  'CONFIRMER',
                                                                  style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 16.0,
                                                          horizontal: 24.0,
                                                        ),
                                                    child: Center(
                                                      child: Text(
                                                        'QUITTER LE GROUPE',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          color:
                                                              Colors
                                                                  .red, // Texte en rouge pour indiquer une action importante
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
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
          ),
        ],
      ),
    );
  }

  // Méthode pour formater le Timestamp en chaîne lisible
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatArrivalTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hours = date.hour.toString().padLeft(
      2,
      '0',
    ); // Ajoute un zéro devant si nécessaire
    final minutes = date.minute.toString().padLeft(
      2,
      '0',
    ); // Ajoute un zéro devant si nécessaire
    return '$hours:$minutes'; // Format HH:mm
  }
}
