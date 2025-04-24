import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_logic.dart';
import '../membre/groupe_menu.dart';

class ChatView extends StatelessWidget {
  final String groupId;

  const ChatView({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return ChangeNotifierProvider(
      create: (_) => ChatLogic(groupId: groupId),
      child: Scaffold(
        backgroundColor: Colors.black, // Fond sombre pour un design moderne
        body: Consumer<ChatLogic>(
          builder: (context, chatLogic, child) {
            return Column(
              children: [
                // AppBar personnalisé
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900], // Fond sombre pour l'AppBar
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20), // Bordures arrondies en bas
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 5), // Ombre sous l'AppBar
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Bouton de retour
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 28,
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
                          radius: 25,
                        )
                      else
                        const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                          radius: 25,
                        ),
                      const SizedBox(width: 15),
                      // Bouton pour afficher les membres
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        GroupMenuPage(groupId: groupId),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${chatLogic.memberCount} membres',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.arrow_forward_ios, // Icône de flèche
                                color: Colors.white70,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenu principal
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850], // Fond pour le contenu
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20), // Bordures arrondies en haut
                      ),
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('chats')
                              .doc(groupId)
                              .collection('messages')
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
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
                            final timestamp =
                                message['timestamp'] as Timestamp?;

                            final isCurrentUser = senderId == currentUser?.uid;

                            return Align(
                              alignment:
                                  isCurrentUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 5,
                                  horizontal: 10,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      isCurrentUser
                                          ? Colors.green[400]
                                          : Colors.grey[700],
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(12),
                                    topRight: const Radius.circular(12),
                                    bottomLeft:
                                        isCurrentUser
                                            ? const Radius.circular(12)
                                            : Radius.zero,
                                    bottomRight:
                                        isCurrentUser
                                            ? Radius.zero
                                            : const Radius.circular(12),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
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
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                // Champ de saisie et bouton d'envoi
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chatLogic.messageController,
                          decoration: InputDecoration(
                            hintText: 'Écrivez un message...',
                            hintStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) {
                            chatLogic.notifyListeners();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
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
