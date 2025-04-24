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
              const BackgroundWidget(),
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
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(
                                22,
                                0,
                                0,
                                0,
                              ).withOpacity(0.7), // Fond semi-transparent
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(
                                  30,
                                ), // Bordures arrondies en bas
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(
                                    0,
                                    5,
                                  ), // Ombre sous l'AppBar
                                ),
                              ],
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
                                                size: 60,
                                              )
                                              : null,
                                    ),
                                    const SizedBox(width: 15),
                                    // Nom de l'utilisateur
                                    Expanded(
                                      child: Text(
                                        (logic.username ?? 'Utilisateur')
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        overflow:
                                            TextOverflow
                                                .ellipsis, // Gestion du débordement
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // TabBar pour les deux listes
                                const TabBar(
                                  indicatorColor: Colors.green,
                                  indicatorWeight: 3,
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.grey,
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  tabs: [
                                    Tab(text: 'Mes Groupes'),
                                    Tab(text: 'Mes Demandes'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      const SizedBox(height: 10),
                      // Contenu des onglets
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(
                              0.6,
                            ), // Fond semi-transparent
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(
                                40,
                              ), // Bordures arrondies en haut
                            ),
                          ),
                          child: TabBarView(
                            children: [
                              // Liste des messages de "Mes Groupes"
                              _buildGroupCard(logic),
                              // Liste des messages de "Mes Demandes"
                              _buildRequestCard(logic),
                            ],
                          ),
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

  // Card contenant la liste des groupes
  Widget _buildGroupCard(MessagesLogic logic) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 8), // Réduction de l'espace au-dessus
          Expanded(child: _buildGroupMessages(logic)),
        ],
      ),
    );
  }

  // Card contenant la liste des demandes
  Widget _buildRequestCard(MessagesLogic logic) {
    return Padding(
      padding: const EdgeInsets.all(16.0), // Espacement autour du contenu
      child: Column(
        children: [
          const SizedBox(height: 8), // Réduction de l'espace au-dessus
          Expanded(child: _buildRequestMessages(logic)),
        ],
      ),
    );
  }

  // Liste des messages de "Mes Groupes"
  Widget _buildGroupMessages(MessagesLogic logic) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('chats')
              .where('createdBy', isEqualTo: logic.userId)
              .snapshots(), // Écoute en temps réel
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
          padding: const EdgeInsets.all(8.0),
          itemBuilder: (context, index) {
            final group = groups[index];
            final groupId = group['groupId'] ?? 'Inconnu';
            final createdAt = group['createdAt'] as Timestamp?;
            final creatorId = group['createdBy'] ?? 'Inconnu';

            return StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(creatorId)
                      .snapshots(), // Écoute en temps réel pour les données utilisateur
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.group, color: Colors.white),
                    ),
                    title: const Text('Créateur inconnu'),
                    subtitle: Text(
                      createdAt != null
                          ? _formatTimestamp(createdAt)
                          : 'Date inconnue',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatView(groupId: groupId),
                        ),
                      );
                    },
                  );
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final creatorName =
                    userData['username'] ?? 'Utilisateur inconnu';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Card(
                    color: Colors.transparent,
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: Colors.white,
                        width: 1.0,
                      ), // Contour blanc
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('chats')
                              .doc(groupId)
                              .collection('messages')
                              .where(
                                'isRead',
                                isEqualTo: false,
                              ) // Messages non lus
                              .snapshots(),
                      builder: (context, unreadSnapshot) {
                        int unreadCount = 0;
                        if (unreadSnapshot.hasData) {
                          unreadCount = unreadSnapshot.data!.docs.length;
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          leading: Stack(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Icon(Icons.group, color: Colors.white),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4.0),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'GROUPE DE $creatorName'.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              Text(
                                createdAt != null
                                    ? _formatTimestamp(createdAt).split(' ')[1]
                                    : 'Heure inconnue',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          subtitle: StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('chats')
                                    .doc(groupId)
                                    .collection('messages')
                                    .orderBy('timestamp', descending: true)
                                    .limit(1)
                                    .snapshots(), // Écoute en temps réel pour les messages
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text(
                                  'Chargement...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Text(
                                  'Aucun message',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                );
                              }

                              final lastMessageData =
                                  snapshot.data!.docs.first.data()
                                      as Map<String, dynamic>;
                              final senderName =
                                  lastMessageData['senderName'] ?? 'Inconnu';
                              final text =
                                  lastMessageData['text'] ?? 'Message vide';
                              final timestamp =
                                  lastMessageData['timestamp'] as Timestamp?;

                              final formattedTime =
                                  timestamp != null
                                      ? '${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                                      : 'Heure inconnue';

                              return Text(
                                '$senderName : $text\n$formattedTime',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ChatView(groupId: groupId),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Liste des messages de "Mes Demandes"
  Widget _buildRequestMessages(MessagesLogic logic) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: logic.userId)
              .snapshots(), // Écoute en temps réel
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Aucune conversation trouvée.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final chats = snapshot.data!.docs;

        return ListView.builder(
          itemCount: chats.length,
          padding: const EdgeInsets.all(8.0),
          itemBuilder: (context, index) {
            final chat = chats[index];
            final groupId = chat['groupId'] ?? 'Inconnu';
            final createdAt = chat['createdAt'] as Timestamp?;
            final creatorId = chat['createdBy'] ?? 'Inconnu';

            return StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(creatorId)
                      .snapshots(), // Écoute en temps réel pour les données utilisateur
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return Card(
                    color: Colors.transparent,
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: Colors.white,
                        width: 1.0,
                      ), // Contour blanc
                    ),
                    child: ListTile(
                      title: const Text('Créateur inconnu'),
                      subtitle: Text(
                        createdAt != null
                            ? _formatTimestamp(createdAt)
                            : 'Date inconnue',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatView(groupId: groupId),
                          ),
                        );
                      },
                    ),
                  );
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final creatorName =
                    userData['username'] ?? 'Utilisateur inconnu';

                return Card(
                  color: Colors.transparent, // Fond transparent
                  elevation: 2, // Légère ombre pour un effet visuel
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      16,
                    ), // Bordures arrondies
                    side: const BorderSide(
                      color: Colors.white,
                      width: 1.0,
                    ), // Contour blanc
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'GROUPE DE $creatorName'.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Text(
                          createdAt != null
                              ? _formatTimestamp(createdAt).split(' ')[1]
                              : 'Heure inconnue',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    subtitle: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('chats')
                              .doc(groupId)
                              .collection('messages')
                              .orderBy('timestamp', descending: true)
                              .limit(1)
                              .snapshots(), // Écoute en temps réel pour les messages
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text(
                            'Chargement...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text(
                            'Aucun message',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          );
                        }

                        final lastMessageData =
                            snapshot.data!.docs.first.data()
                                as Map<String, dynamic>;
                        final senderName =
                            lastMessageData['senderName'] ?? 'Inconnu';
                        final text = lastMessageData['text'] ?? 'Message vide';
                        final timestamp =
                            lastMessageData['timestamp'] as Timestamp?;

                        final formattedTime =
                            timestamp != null
                                ? '${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                                : 'Heure inconnue';

                        return Text(
                          '$senderName : $text\n$formattedTime',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatView(groupId: groupId),
                        ),
                      );
                    },
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
