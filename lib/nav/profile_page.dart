import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          'Bienvenue sur la page de profil',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
