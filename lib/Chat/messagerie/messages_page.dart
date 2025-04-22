import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'messages_logic.dart';
import '../../couleur/background_widget.dart'; // Importez votre widget d'arrière-plan
import '../chat_view.dart'; // Importez votre vue de chat

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupérer l'utilisateur actuellement connecté
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: const Center(
          child: Text(
            'Aucun utilisateur connecté.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    final String userId = currentUser.uid; // ID de l'utilisateur connecté

    return ChangeNotifierProvider(
      create: (_) => MessagesLogic(userId: userId),
      child: DefaultTabController(
        length: 2, // Deux onglets
        child: Scaffold(
          body: Stack(
            children: [
              // Arrière-plan
              const BackgroundWidget(), // Ajout de l'arrière-plan
              // Contenu principal
              Consumer<MessagesLogic>(
                builder: (context, logic, child) {
                  return Column(
                    children: [
                      // AppBar personnalisé avec TabBar
                      logic.isLoadingUser
                          ? Container(
                            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                          : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                            decoration: const BoxDecoration(
                              color: Colors.transparent, // Fond transparent
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(width: 15),
                                    // Photo de l'utilisateur
                                    CircleAvatar(
                                      backgroundImage:
                                          logic.photoUrl != null
                                              ? NetworkImage(logic.photoUrl!)
                                              : null,
                                      backgroundColor: Colors.grey,
                                      radius: 50,
                                      child:
                                          logic.photoUrl == null
                                              ? const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 60, // Taille de l'icône
                                              )
                                              : null, // Taille de l'image agrandie
                                    ),
                                    const SizedBox(width: 15),
                                    // Nom de l'utilisateur
                                    Text(
                                      (logic.username ?? 'Utilisateur')
                                          .toUpperCase(), // Convertir en majuscules
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24, // Taille spécifique
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FontStyle.italic, // Italique
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // TabBar pour les deux listes
                                const TabBar(
                                  indicatorColor: Colors.green,
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.grey,
                                  tabs: [
                                    Tab(text: 'Mes Groupes'),
                                    Tab(text: 'Mes Demandes'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      // Contenu des onglets
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Liste des messages de "Mes Groupes"
                            _buildGroupMessages(logic),
                            // Liste des messages de "Mes Demandes"
                            _buildRequestMessages(logic),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Liste des messages de "Mes Demandes"
  Widget _buildRequestMessages(MessagesLogic logic) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('requests') // Collection des demandes
              .where(
                'requesterId',
                isEqualTo: logic.userId,
              ) // Filtrer par utilisateur connecté
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Aucune demande en attente.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final requests = snapshot.data!.docs;

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final groupId = request['groupId'] ?? 'Inconnu';
            final createdAt = request['createdAt'] as Timestamp?;
            final status = request['status'] ?? 'En attente';

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.person_add, color: Colors.white),
              ),
              title: Text(
                'Groupe ID: $groupId',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              subtitle: Text(
                createdAt != null
                    ? _formatTimestamp(createdAt)
                    : 'Date inconnue',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              trailing: Text(
                status,
                style: TextStyle(
                  color: status == 'Accepté' ? Colors.green : Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Liste des messages de "Mes Demandes"
  Widget _buildGroupMessages(MessagesLogic logic) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('chats') // Collection des groupes
              .where(
                'createdBy',
                isEqualTo: logic.userId,
              ) // Filtrer par utilisateur connecté
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Aucun groupe trouvé.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final groups = snapshot.data!.docs;

        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final groupId = group['groupId'] ?? 'Inconnu';
            final createdAt = group['createdAt'] as Timestamp?;

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.group, color: Colors.white),
              ),
              title: Text(
                'Groupe ID: $groupId',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              subtitle: Text(
                createdAt != null
                    ? _formatTimestamp(createdAt)
                    : 'Date inconnue',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              onTap: () {
                // Naviguer vers la page de chat associée au groupe
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatView(groupId: groupId),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
