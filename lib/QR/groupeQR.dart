import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './qr.dart'; // Assurez-vous que QRCodePage est bien défini dans ce fichier
import '../couleur/background_widget.dart'; // Import du BackgroundWidget
import 'GroupCreatorQR.dart'; // Import de la page des groupes créés
import 'GroupdemandQR.dart';

class GroupListPage extends StatelessWidget {
  const GroupListPage({super.key});

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
                  'MES GROUPES ACCEPTÉS',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic, // Texte en italique
                    fontSize: 20, // Taille de la police
                    color: Colors.white, // Couleur blanche
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Carte pour "Scanner un QR Code"
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.green,
                          size: 40,
                        ),
                        title: Text(
                          'Scanner un QR Code',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          'Utilisez cette option si vous êtes le créateur d\'un groupe pour scanner les QR Codes des participants.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[300],
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                        ),
                        onTap: () {
                          // Naviguer vers la page des groupes créés
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreatorGroupsPage(),
                            ),
                          );
                        },
                      ),
                    ),

                    // Texte "OU" centré
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'OU',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Carte pour "Générer un QR Code"
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(
                          Icons.qr_code,
                          color: Colors.blue,
                          size: 40,
                        ),
                        title: Text(
                          'Générer un QR Code',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          'Utilisez cette option si vous avez rejoint un groupe pour générer votre QR Code.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[300],
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                        ),
                        onTap: () {
                          // Naviguer vers la page des groupes demandés
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RequestedGroupsPage(),
                            ),
                          );
                        },
                      ),
                    ),

                    // Texte explicatif en dessous
                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informations importantes',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1. Vous devez scanner votre QR Code uniquement devant le lieu de l\'événement (ex. : boîte de nuit, salle de concert, etc.).',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[300],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '2. Le QR Code est valide uniquement à cet endroit et ne peut pas être utilisé ailleurs.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[300],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '3. Assurez-vous que votre QR Code est bien lisible (pas de fissures ou d\'écran sale).',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[300],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '4. Si vous êtes le créateur du groupe, utilisez l\'option "Scanner un QR Code" pour valider les participants.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[300],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '5. Si vous avez rejoint un groupe, utilisez l\'option "Générer un QR Code" pour obtenir votre code personnel.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
