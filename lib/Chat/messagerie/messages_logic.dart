import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagesLogic extends ChangeNotifier {
  final String userId;

  MessagesLogic({required this.userId}) {
    _loadUserInfo();
  }

  String? username;
  String? photoUrl;
  bool isLoadingUser = true;

  // Stream pour les messages généraux
  Stream<QuerySnapshot> get messagesStream {
    return FirebaseFirestore.instance
        .collection('chats') // Remplacez par votre collection Firestore
        .orderBy('timestamp', descending: true) // Trier par date
        .snapshots();
  }

  // Stream pour les messages de "Mes Groupes"
  // Stream pour les messages de "Mes Groupes"
  Stream<QuerySnapshot> get groupMessagesStream {
    return FirebaseFirestore.instance
        .collection('chats') // Collection des groupes
        .where(
          'createdBy',
          isEqualTo: userId, // Filtrer par groupes créés par l'utilisateur
        )
        .orderBy('createdAt', descending: true) // Trier par date de création
        .snapshots();
  }

  // Stream pour les messages de "Mes Demandes"
  Stream<QuerySnapshot> get requestMessagesStream {
    return FirebaseFirestore.instance
        .collection('requests') // Remplacez par votre collection Firestore
        .where(
          'requesterId',
          isEqualTo: userId,
        ) // Filtrer par demandes faites par l'utilisateur
        .orderBy('timestamp', descending: true) // Trier par date
        .snapshots();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userDoc.exists) {
        username = userDoc.data()?['username'] ?? 'Utilisateur';
        photoUrl = userDoc.data()?['photoURL'];
      } else {
        username = 'Utilisateur introuvable';
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des informations utilisateur : $e');
      username = 'Erreur';
    } finally {
      isLoadingUser = false;
      notifyListeners();
    }
  }
}
