import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'GroupJoinRequest.dart';
import 'package:bypass/groupes/list/groupes/rejoindre/recherche/search_bar.dart'
    as custom; // Alias pour votre SearchBar personnalisé

import 'package:firebase_auth/firebase_auth.dart';

class JoinGroup extends StatefulWidget {
  final String eventId;

  const JoinGroup({super.key, required this.eventId});

  @override
  _JoinGroupState createState() => _JoinGroupState();
}

class _JoinGroupState extends State<JoinGroup> {
  List<QueryDocumentSnapshot> searchResults = [];

  String searchQuery = '';

  String _formatDate(Timestamp? timestamp) =>
      timestamp == null
          ? 'Date inconnue'
          : DateFormat('dd/MM/yyyy à HH:mm').format(timestamp.toDate());

  String _formatPrice(num? price) =>
      price == null ? 'Prix non défini' : '${price.toString()}€';

  Widget _buildCreatorPhoto(String? creatorId) {
    return creatorId == null
        ? const SizedBox.shrink()
        : StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(creatorId)
                  .snapshots(),
          builder: (context, snapshot) {
            final photoURL =
                (snapshot.data?.data() as Map<String, dynamic>?)?['photoURL'];
            return CircleAvatar(
              radius: 25,
              backgroundImage:
                  photoURL != null
                      ? CachedNetworkImageProvider(photoURL)
                      : null,
              child:
                  photoURL == null
                      ? const Icon(Icons.person, color: Colors.green)
                      : null,
            );
          },
        );
  }

  Future<bool> hasPendingRequest(String groupId, String userId) async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('groupJoinRequests')
            .where('groupId', isEqualTo: groupId)
            .where('userId', isEqualTo: userId)
            .where(
              'status',
              isEqualTo: 'pending',
            ) // Vérifie uniquement les demandes en attente
            .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Widget _buildCreatorInfo(String? creatorId) {
    return creatorId == null
        ? const Text(
          'Créateur inconnu',
          style: TextStyle(color: Colors.green, fontSize: 12),
        )
        : StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(creatorId)
                  .snapshots(),
          builder: (context, snapshot) {
            final username =
                (snapshot.data?.data() as Map<String, dynamic>?)?['username'] ??
                'Utilisateur inconnu';
            return Text(
              'Groupe de $username',
              style: const TextStyle(
                color: Color.fromARGB(255, 243, 243, 243),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text('Rejoindre un groupe'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Barre de recherche
          custom.SearchBar(
            eventId: widget.eventId, // Passez l'eventId ici
            onResults: (results) {
              setState(() {
                searchResults = results;
              });
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('groups')
                      .where('eventId', isEqualTo: widget.eventId)
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
                      'Une erreur est survenue',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                final groups = snapshot.data?.docs ?? [];
                final filteredGroups =
                    groups.where((group) {
                      final data = group.data() as Map<String, dynamic>;
                      final groupName =
                          (data['name'] ?? '').toString().toLowerCase();
                      return groupName.contains(searchQuery);
                    }).toList();

                if (filteredGroups.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun groupe disponible',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) {
                    final group = filteredGroups[index];
                    final data = group.data() as Map<String, dynamic>;
                    final creatorId = data['createdBy'] as String?;
                    final members =
                        data['members'] as Map<String, dynamic>? ?? {};
                    final menCount = (members['men'] as List?)?.length ?? 0;
                    final womenCount = (members['women'] as List?)?.length ?? 0;
                    final totalParticipants = menCount + womenCount;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.15),
                            Colors.green.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data['photoURL'] != null)
                            CachedNetworkImage(
                              imageUrl: data['photoURL'],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.green,
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white54,
                                  ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _buildCreatorPhoto(creatorId),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildCreatorInfo(creatorId),
                                    ),
                                    Text(
                                      _formatPrice(data['price'] as num?),
                                      style: const TextStyle(
                                        color: Color.fromARGB(
                                          255,
                                          230,
                                          230,
                                          230,
                                        ),
                                        fontSize: 26,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Bulles pour les hommes (ordre inversé)
                                    Row(
                                      children:
                                          List.generate(data['maxMen'] as int, (
                                            index,
                                          ) {
                                            if (index < menCount) {
                                              final userId =
                                                  (members['men']
                                                      as List)[index];
                                              return FutureBuilder<
                                                DocumentSnapshot
                                              >(
                                                future:
                                                    FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(userId)
                                                        .get(),
                                                builder: (context, snapshot) {
                                                  final photoURL =
                                                      (snapshot.data?.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >?)?['photoURL'];
                                                  return Container(
                                                    margin:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 2,
                                                        ),
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue
                                                          .withOpacity(0.2),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                    child:
                                                        photoURL != null
                                                            ? ClipOval(
                                                              child: Image.network(
                                                                photoURL,
                                                                fit:
                                                                    BoxFit
                                                                        .cover,
                                                              ),
                                                            )
                                                            : const Icon(
                                                              Icons.person,
                                                              color:
                                                                  Colors.blue,
                                                              size: 16,
                                                            ),
                                                  );
                                                },
                                              );
                                            } else {
                                              return Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 2,
                                                    ),
                                                width: 30,
                                                height: 30,
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  border: Border.all(
                                                    color: Colors.blue,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                              );
                                            }
                                          }).reversed.toList(),
                                    ),
                                    // Bulles pour les femmes (ordre normal)
                                    Row(
                                      children: List.generate(
                                        data['maxWomen'] as int,
                                        (index) {
                                          if (index < womenCount) {
                                            final userId =
                                                (members['women']
                                                    as List)[index];
                                            return FutureBuilder<
                                              DocumentSnapshot
                                            >(
                                              future:
                                                  FirebaseFirestore.instance
                                                      .collection('users')
                                                      .doc(userId)
                                                      .get(),
                                              builder: (context, snapshot) {
                                                final photoURL =
                                                    (snapshot.data?.data()
                                                        as Map<
                                                          String,
                                                          dynamic
                                                        >?)?['photoURL'];
                                                return Container(
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 2,
                                                      ),
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    color: Colors.pink
                                                        .withOpacity(0.2),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.pink,
                                                    ),
                                                  ),
                                                  child:
                                                      photoURL != null
                                                          ? ClipOval(
                                                            child: Image.network(
                                                              photoURL,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          )
                                                          : const Icon(
                                                            Icons.person,
                                                            color: Colors.pink,
                                                            size: 16,
                                                          ),
                                                );
                                              },
                                            );
                                          } else {
                                            return Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 2,
                                                  ),
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                color: Colors.transparent,
                                                border: Border.all(
                                                  color: Colors.pink,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FutureBuilder<bool>(
                                    future: hasPendingRequest(
                                      group.id,
                                      FirebaseAuth.instance.currentUser!.uid,
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircularProgressIndicator(
                                          color: Colors.green,
                                        );
                                      }

                                      if (snapshot.hasError) {
                                        return const Text(
                                          'Erreur lors de la vérification',
                                          style: TextStyle(color: Colors.red),
                                        );
                                      }

                                      final hasRequest = snapshot.data ?? false;
                                      final userId =
                                          FirebaseAuth
                                              .instance
                                              .currentUser!
                                              .uid;

                                      // Vérifier si l'utilisateur est le créateur du groupe
                                      if (creatorId == userId) {
                                        return const Text(
                                          'Vous êtes le créateur de ce groupe',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }

                                      // Vérifier si une demande est déjà en attente
                                      if (hasRequest) {
                                        return const Text(
                                          'Demande en attente',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }

                                      // Vérifier si le groupe est complet
                                      return totalParticipants >=
                                              (data['totalCapacity'] as int)
                                          ? const Text(
                                            'Groupe complet',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                          : TextButton.icon(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          GroupJoinRequest(
                                                            groupId: group.id,
                                                            eventId:
                                                                widget.eventId,
                                                            creatorId:
                                                                creatorId ?? '',
                                                            price:
                                                                data['price']
                                                                    as num? ??
                                                                0,
                                                          ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.group_add,
                                              color: Colors.green,
                                            ),
                                            label: const Text(
                                              'Rejoindre',
                                              style: TextStyle(
                                                color: Colors.green,
                                              ),
                                            ),
                                          );
                                    },
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }
}
