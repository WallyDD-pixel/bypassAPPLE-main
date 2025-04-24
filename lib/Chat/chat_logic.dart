import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatLogic extends ChangeNotifier {
  final String groupId;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<DocumentSnapshot> messages = [];
  bool isLoadingMore = false;
  bool hasMoreMessages = true;
  DocumentSnapshot? lastDocument;

  String? creatorName;
  String? creatorPhotoUrl;
  int memberCount = 0; // Nombre de membres
  bool isLoadingMessages = true;

  bool _isDisposed = false; // Variable pour suivre l'état de l'objet

  ChatLogic({required this.groupId}) {
    _loadInitialMessages();
    _loadGroupInfo();

    // Écoute en temps réel pour les nouveaux messages
    FirebaseFirestore.instance
        .collection('chats')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty && !_isDisposed) {
            messages.insert(0, snapshot.docs.first);
            notifyListeners();
          }
        });
  }

  Future<void> _loadGroupInfo() async {
    try {
      final groupDoc =
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(groupId)
              .get();

      if (groupDoc.exists) {
        final groupData = groupDoc.data() as Map<String, dynamic>;

        // Récupérer l'ID du créateur
        final creatorId = groupData['createdBy'];

        // Récupérer le nom d'utilisateur du créateur
        if (creatorId != null) {
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(creatorId)
                  .get();

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            creatorName =
                userData['username'] ?? 'Inconnu'; // Nom d'utilisateur
          } else {
            creatorName = 'Inconnu';
          }
        } else {
          creatorName = 'Inconnu';
        }

        // Récupérer la photo du créateur
        creatorPhotoUrl = groupData['photoURL'];

        // Calculer le nombre de membres à partir du tableau "participants"
        final participants = groupData['participants'] as List<dynamic>? ?? [];

        // Ajouter le créateur au tableau des participants s'il n'est pas déjà inclus
        if (creatorId != null && !participants.contains(creatorId)) {
          participants.add(creatorId);
        }

        // Mettre à jour le nombre total de membres
        memberCount = participants.length;
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des informations du groupe : $e');
    } finally {
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<bool> isUserParticipant() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('Aucun utilisateur connecté.');
        return false;
      }

      final chatDoc =
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(groupId)
              .get();

      if (chatDoc.exists) {
        final chatData = chatDoc.data() as Map<String, dynamic>;
        final participants = chatData['participants'] as List<dynamic>? ?? [];

        // Vérifiez si l'utilisateur est dans la liste des participants
        return participants.contains(currentUser.uid);
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification des participants : $e');
    }
    return false;
  }

  Future<void> _loadInitialMessages() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(groupId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(20)
              .get();

      messages = querySnapshot.docs;
      if (querySnapshot.docs.isNotEmpty) {
        lastDocument = querySnapshot.docs.last;
      }
      hasMoreMessages = querySnapshot.docs.length == 20;
      isLoadingMessages = false;
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des messages initiaux : $e');
    }
  }

  Future<String> getCreatorName(String groupId) async {
    try {
      // Récupérer le document du groupe
      final chatDoc =
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(groupId)
              .get();

      if (chatDoc.exists) {
        final chatData = chatDoc.data() as Map<String, dynamic>;

        // Vérifiez si le champ "createdBy" existe
        final creatorId = chatData['createdBy'] ?? '';
        if (creatorId.isEmpty) {
          return 'Créateur inconnu';
        }

        // Récupérer le document utilisateur correspondant
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(creatorId)
                .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          return userData['username'] ?? 'Utilisateur inconnu';
        } else {
          return 'Créateur introuvable';
        }
      } else {
        return 'Groupe introuvable';
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du nom du créateur : $e');
      return 'Erreur';
    }
  }

  Future<void> loadMoreMessages() async {
    if (lastDocument == null || isLoadingMore || !hasMoreMessages) return;

    isLoadingMore = true;
    if (!_isDisposed) notifyListeners();

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(groupId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .startAfterDocument(lastDocument!)
              .limit(20)
              .get();

      messages.addAll(querySnapshot.docs);
      if (querySnapshot.docs.isNotEmpty) {
        lastDocument = querySnapshot.docs.last;
      }
      hasMoreMessages = querySnapshot.docs.length == 20;
      isLoadingMore = false;
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement de plus de messages : $e');
      isLoadingMore = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  void sendMessage() {
    final currentUser =
        FirebaseAuth.instance.currentUser; // Récupérer l'utilisateur connecté
    if (currentUser == null) {
      debugPrint('Aucun utilisateur connecté.');
      return;
    }

    if (messageController.text.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('chats')
          .doc(groupId)
          .collection('messages')
          .add({
            'text': messageController.text,
            'senderId':
                currentUser.uid, // Utiliser l'ID de l'utilisateur connecté
            'senderName':
                currentUser.displayName ??
                'Utilisateur', // Nom de l'utilisateur
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false, // Initialiser à non lu
          })
          .then((_) {
            if (!_isDisposed) {
              messageController.clear();
              notifyListeners();
            }
          })
          .catchError((error) {
            debugPrint('Erreur lors de l\'envoi du message : $error');
          });
    }
  }

  @override
  void dispose() {
    _isDisposed = true; // Marquez l'objet comme supprimé
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
