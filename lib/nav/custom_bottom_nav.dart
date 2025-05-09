import 'package:flutter/material.dart';
import 'profile_page.dart';
import '../groupes/list/groupes/rejoindre/passerel.dart'; // Import de la nouvelle page
import '../home_page.dart'; // Import de la page Home
import '../Chat/messagerie/messages_page.dart';
import '../QR/groupeQR.dart';

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
      padding: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
      child: Container(
        height: 70, // Augmentez légèrement la hauteur
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
              color: const Color.fromARGB(0, 0, 0, 0).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: SafeArea(
            child: BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                onTap(index); // Mettre à jour selectedIndex avant la navigation
                if (index == 0) {
                  // Rediriger vers la page Home
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                } else if (index == 1) {
                  // Rediriger vers la page Messages
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MessagesPage(),
                    ),
                  );
                } else if (index == 4) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                } else if (index == 3) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const Passerel(), // Nouvelle page
                    ),
                  );
                } else if (index == 2) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const GroupListPage(), // Nouvelle page Ajouter
                    ),
                  );
                }
              },
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.green,
              unselectedItemColor: Colors.grey.withOpacity(0.5),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedFontSize: 7,
              unselectedFontSize: 12,
              selectedIconTheme: const IconThemeData(size: 28),
              unselectedIconTheme: const IconThemeData(size: 24),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
              unselectedLabelStyle: const TextStyle(height: 1.5),
              items: [
                _buildNavItem(Icons.home_rounded, 'Accueil', 0),
                _buildNavItem(Icons.message, 'Messages', 1),
                _buildNavItem(Icons.add_circle_rounded, 'Ajouter', 2),
                _buildNavItem(
                  Icons.group_rounded,
                  'Mes Groupes',
                  3,
                ), // Remplacement ici
                _buildNavItem(Icons.person_rounded, 'Profil', 4),
              ],
            ),
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
        padding: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color:
                  selectedIndex == index
                      ? const Color.fromARGB(255, 34, 145, 26) // Barre orange
                      : Colors.transparent, // Pas de barre si non sélectionné
              width: 2,
            ),
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), // Animation fluide
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                selectedIndex == index
                    ? Colors.green.withOpacity(
                      0.2,
                    ) // Fond vert clair si sélectionné
                    : Colors.transparent, // Pas de fond si non sélectionné
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon),
        ),
      ),
      label: label,
    );
  }
}
