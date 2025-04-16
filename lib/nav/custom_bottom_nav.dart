import 'package:flutter/material.dart';
import 'profile_page.dart'; // Importez la page de profil

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.black.withOpacity(0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) {
              if (index == 4) { // Index du bouton Profil
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
              } else {
                onTap(index); // Appeler la fonction onTap pour les autres boutons
              }
            },
            backgroundColor: Colors.transparent,
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey.withOpacity(0.5),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedFontSize: 7, // Augmentation de la taille de police
            unselectedFontSize: 12, // Augmentation de la taille de police
            selectedIconTheme: const IconThemeData(size: 28),
            unselectedIconTheme: const IconThemeData(size: 24),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              height: 1.5, // Ajout d'espace vertical pour le texte
            ),
            unselectedLabelStyle: const TextStyle(
              height: 1.5, // Ajout d'espace vertical pour le texte
            ),
            items: [
              _buildNavItem(Icons.home_rounded, 'Accueil', 0),
              _buildNavItem(Icons.search_rounded, 'Recherche', 1),
              _buildNavItem(Icons.add_circle_rounded, 'Ajouter', 2),
              _buildNavItem(Icons.favorite_rounded, 'Favoris', 3),
              _buildNavItem(Icons.person_rounded, 'Profil', 4),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index,
  ) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selectedIndex == index ? Colors.green : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                selectedIndex == index
                    ? Colors.green.withOpacity(0.2)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon),
        ),
      ),
      label: label,
    );
  }
}