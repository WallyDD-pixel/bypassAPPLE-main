import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'custom_bottom_nav.dart'; // Importez le menu de navigation personnalisé
import '../home_page.dart';
import '../auth/custom_login_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool pushNotifications = true;
  bool faceIdEnabled = true;
  int _selectedIndex = 4; // Index par défaut pour la page Profil

  void navigateWithAnimation(BuildContext context, Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // Départ de la droite
          const end = Offset.zero; // Arrivée au centre
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigation vers d'autres pages avec animation
    if (index == 0) {
      navigateWithAnimation(context, const HomePage());
    } else if (index == 1) {
      navigateWithAnimation(context, const Center(child: Text('Recherche')));
    } else if (index == 2) {
      navigateWithAnimation(context, const Center(child: Text('Ajouter')));
    } else if (index == 3) {
      navigateWithAnimation(context, const Center(child: Text('Favoris')));
    }
  }

  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const CustomLoginPage(),
        ), // Redirige vers CustomLoginPage
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la déconnexion : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: Colors.black,
        ),
        body: const Center(
          child: Text(
            'Aucun utilisateur connecté',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black87, // Définir la couleur de l'arrière-plan
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Erreur lors du chargement des données',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;

          if (userData == null) {
            return const Center(
              child: Text(
                'Aucune donnée utilisateur trouvée',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Avatar et nom d'utilisateur
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 35, // Réduction de la taille de l'avatar
                        backgroundImage:
                            userData['photoURL'] != null
                                ? NetworkImage(userData['photoURL'])
                                : null,
                        child:
                            userData['photoURL'] == null
                                ? const Icon(
                                  Icons.person,
                                  size: 40, // Réduction de la taille de l'icône
                                  color: Colors.black,
                                )
                                : null,
                      ),
                      const SizedBox(height: 12), // Réduction de l'espacement
                      Text(
                        userData['username'] ?? 'Nom d\'utilisateur inconnu',
                        style: const TextStyle(
                          fontSize: 24, // Réduction de la taille du texte
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Couleur du texte
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userData['email'] ?? 'Email non disponible',
                        style: const TextStyle(
                          fontSize: 14, // Réduction de la taille du texte
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12), // Réduction de l'espacement
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.white38),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24, // Réduction de la largeur
                            vertical: 10, // Réduction de la hauteur
                          ),
                        ),
                        child: const Text(
                          "Modifier le profil",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24), // Réduction de l'espacement
                  // Section Inventories
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        "Inventories",
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Menu Inventories
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          icon: Icons.home,
                          title: "Mes magasins",
                          trailing: Container(
                            width: 20, // Réduction de la taille
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                "2",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      10, // Réduction de la taille du texte
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Divider(color: Colors.grey[800], height: 1, indent: 56),
                        _buildListTile(
                          icon: Icons.help_outline,
                          title: "Support",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16), // Réduction de l'espacement
                  // Section Préférences
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        "Préférences",
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Menu Préférences
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.notifications_none,
                          title: "Notifications push",
                          value: pushNotifications,
                          onChanged: (value) {
                            setState(() {
                              pushNotifications = value;
                            });
                          },
                        ),
                        Divider(color: Colors.grey[800], height: 1, indent: 56),
                        _buildSwitchTile(
                          icon: Icons.face,
                          title: "Face ID",
                          value: faceIdEnabled,
                          onChanged: (value) {
                            setState(() {
                              faceIdEnabled = value;
                            });
                          },
                        ),
                        Divider(color: Colors.grey[800], height: 1, indent: 56),
                        _buildListTile(icon: Icons.grid_3x3, title: "Code PIN"),
                        Divider(color: Colors.grey[800], height: 1, indent: 56),
                        _buildListTile(
                          icon: Icons.logout,
                          title: "Se déconnecter",
                          iconColor: Colors.red[400],
                          titleColor: Colors.red[400],
                          onTap: _signOut, // Appelle la méthode de déconnexion
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? iconColor,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 32, // Réduction de la taille
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, color: titleColor ?? Colors.white),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      dense: true,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        width: 32, // Réduction de la taille
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Colors.white),
      ),
      value: value,
      activeColor: Colors.white,
      activeTrackColor: Colors.green,
      inactiveThumbColor: Colors.grey,
      inactiveTrackColor: Colors.grey[700],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      dense: true,
      onChanged: onChanged,
    );
  }
}
