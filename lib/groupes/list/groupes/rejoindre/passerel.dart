import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../couleur/background_widget.dart';
import '../../../../nav/custom_bottom_nav.dart';
import 'mon_groupe.dart';
import 'mes_attentes.dart';

class Passerel extends StatefulWidget {
  const Passerel({super.key});

  @override
  _PasserelState createState() => _PasserelState();
}

class _PasserelState extends State<Passerel> {
  final int _selectedIndex =
      3; // Définir _selectedIndex pour gérer l'état de la navigation

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundWidget(), // Ajout de l'arrière-plan
          // AppBar personnalisée
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              16,
              50,
              5,
              5,
            ), // Espacement pour l'AppBar
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
                    Navigator.of(context).pop(); // Retour à la page précédente
                  },
                ),
                // Texte de l'AppBar
                Text(
                  'MES GROUPES',
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

          // Contenu principal
          Padding(
            padding: const EdgeInsets.only(top: 0), // Décalage sous l'AppBar
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Centrer verticalement
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Centrer horizontalement
                children: [
                  // Carte pour "Mes Demandes"
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const MonGroupe(), // Rediriger vers MonGroupe
                        ),
                      );
                    },
                    child: Card(
                      color: Colors.black.withOpacity(
                        0.4,
                      ), // Fond semi-transparent
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      child: Container(
                        height: 150, // Hauteur de la carte
                        width:
                            double
                                .infinity, // Prendre toute la largeur disponible
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'MES DEMANDES'
                                    .toUpperCase(), // Texte en majuscules
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 22, // Taille du texte
                                  fontWeight: FontWeight.bold,
                                  fontStyle:
                                      FontStyle.italic, // Texte en italique
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Bulle pour afficher le nombre de groupes
                              StreamBuilder<QuerySnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection('groups')
                                        .where('createdBy', isEqualTo: userId)
                                        .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return const Text(
                                      'Erreur',
                                      style: TextStyle(color: Colors.red),
                                    );
                                  }

                                  final int groupCount =
                                      snapshot.data?.docs.length ?? 0;

                                  return Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$groupCount',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24), // Espacement entre les cartes
                  // Carte pour "Mes Demandes en Attente"
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MesAttentes(),
                        ),
                      );
                    },
                    child: Card(
                      color: Colors.black.withOpacity(
                        0.4,
                      ), // Fond semi-transparent
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      child: Container(
                        height: 150, // Hauteur de la carte
                        width:
                            double
                                .infinity, // Prendre toute la largeur disponible
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'MES DEMANDES EN ATTENTE'
                                    .toUpperCase(), // Texte en majuscules
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 22, // Taille du texte
                                  fontWeight: FontWeight.bold,
                                  fontStyle:
                                      FontStyle.italic, // Texte en italique
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Bulle pour afficher le nombre de demandes en attente
                              StreamBuilder<QuerySnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection('groupJoinRequests')
                                        .where('userId', isEqualTo: userId)
                                        .where('status', isEqualTo: 'pending')
                                        .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return const Text(
                                      'Erreur',
                                      style: TextStyle(color: Colors.red),
                                    );
                                  }

                                  final int pendingCount =
                                      snapshot.data?.docs.length ?? 0;

                                  return Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$pendingCount',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24), // Espacement entre les cartes
                  // Nouvelle carte pour les informations utiles
                  Card(
                    color: Colors.black.withOpacity(
                      0.4,
                    ), // Fond semi-transparent
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    child: Container(
                      height: 150, // Hauteur de la carte
                      width:
                          double
                              .infinity, // Prendre toute la largeur disponible
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INFORMATIONS UTILES', // Texte en majuscules
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 22, // Taille du texte
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic, // Texte en italique
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Consultez vos demandes en attente.',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '• Créez et gérez vos groupes.',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '• Contactez le support en cas de besoin.',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
