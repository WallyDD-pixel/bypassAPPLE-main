import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../couleur/background_widget.dart'; // Importez votre widget d'arrière-plan

class PublicationsPage extends StatelessWidget {
  final List<String> imageUrls;

  const PublicationsPage({super.key, required this.imageUrls});

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
                AppBar(
                  title: Text(
                    'PUBLICATIONS',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  backgroundColor: Colors.transparent, // Fond transparent
                  elevation: 0, // Supprime l'ombre
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop(); // Retour à la page précédente
                    },
                  ),
                ),
                Expanded(
                  child:
                      imageUrls.isNotEmpty
                          ? ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) {
                              final imageUrl = imageUrls[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[900],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Image
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (
                                              context,
                                              child,
                                              loadingProgress,
                                            ) {
                                              if (loadingProgress == null)
                                                return child;
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            },
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Center(
                                                child: Icon(
                                                  Icons.error,
                                                  color: Colors.red,
                                                  size: 50,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        // Titre ou description (optionnel)
                                        Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Text(
                                            'Titre de la publication',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
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
          ),
        ],
      ),
    );
  }
}
