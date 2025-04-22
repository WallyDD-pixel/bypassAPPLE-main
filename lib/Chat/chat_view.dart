import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_logic.dart';

class ChatView extends StatelessWidget {
  final String groupId;

  const ChatView({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final currentUser =
        FirebaseAuth.instance.currentUser; // Récupérer l'utilisateur connecté

    return ChangeNotifierProvider(
      create: (_) => ChatLogic(groupId: groupId),
      child: Scaffold(
        body: Consumer<ChatLogic>(
          builder: (context, chatLogic, child) {
            return Column(
              children: [
                // AppBar personnalisé
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 50, 5, 5),
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
                          Navigator.of(context).pop();
                        },
                      ),
                      // Photo du créateur
                      if (chatLogic.creatorPhotoUrl != null)
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                            chatLogic.creatorPhotoUrl!,
                          ),
                          radius: 20,
                        )
                      else
                        const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                          radius: 20,
                        ),
                      const SizedBox(width: 10),
                      // Texte de l'AppBar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chatLogic.creatorName != null
                                ? 'Groupe de ${chatLogic.creatorName}'
                                : 'Chargement...',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: const Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          Text(
                            '${chatLogic.memberCount} membres', // Nombre de membres
                            style: const TextStyle(
                              color: Color.fromARGB(179, 0, 0, 0),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Contenu principal
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('chats')
                            .doc(groupId)
                            .collection(
                              'messages',
                            ) // Sous-collection des messages
                            .orderBy(
                              'timestamp',
                              descending: true,
                            ) // Trier par date
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 80,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Aucun message pour le moment.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Soyez le premier à envoyer un message !',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final messages = snapshot.data!.docs;

                      return ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final senderId = message['senderId'] ?? 'Inconnu';
                          final text = message['text'] ?? '';
                          final timestamp = message['timestamp'] as Timestamp?;

                          final isCurrentUser = senderId == currentUser?.uid;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 10,
                            ),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  isCurrentUser
                                      ? Colors.green[300]
                                      : Colors
                                          .grey[800], // Couleur différente pour l'utilisateur connecté
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(10),
                                topRight: const Radius.circular(10),
                                bottomLeft:
                                    isCurrentUser
                                        ? const Radius.circular(10)
                                        : Radius.zero,
                                bottomRight:
                                    isCurrentUser
                                        ? Radius.zero
                                        : const Radius.circular(10),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  isCurrentUser
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  timestamp != null
                                      ? _formatTimestamp(timestamp)
                                      : '',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Champ de saisie et bouton d'envoi
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chatLogic.messageController,
                          decoration: const InputDecoration(
                            hintText: 'Écrivez un message...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            chatLogic
                                .notifyListeners(); // Met à jour l'état pour activer/désactiver le bouton
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.green),
                        onPressed:
                            chatLogic.messageController.text.isEmpty
                                ? null
                                : chatLogic.sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
