import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/date_formatter.dart';
import '../../../groupes/create_group_form.dart';
import '../../../groupes/list/groupes/rejoindre/join_group.dart';

class EventCard extends StatelessWidget {
  final DocumentSnapshot event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  Future<void> _createGroup(String eventId, int maxMen, int maxWomen) async {
    try {
      debugPrint('Début de la création du groupe...');
      final groupRef = FirebaseFirestore.instance.collection('groups').doc();

      // Calculer les places restantes initiales
      final status =
          'Il reste $maxMen place(s) pour les hommes et $maxWomen place(s) pour les femmes';

      // Créer le groupe avec les valeurs initiales
      await groupRef.set({
        'eventId': eventId,
        'maxMen': maxMen,
        'maxWomen': maxWomen,
        'members': {'men': [], 'women': []},
        'createdBy': FirebaseAuth.instance.currentUser!.uid,
        'status': status, // Champ "status" défini dès la création
      });

      debugPrint('Groupe créé avec succès avec le statut : $status');
    } catch (e) {
      debugPrint('Erreur lors de la création du groupe : $e');
    }
  }

  Widget _buildGroupsWidget() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('groups')
              .where('eventId', isEqualTo: event.id)
              .limit(3)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Erreur de chargement des groupes: ${snapshot.error}');
          return const SizedBox(height: 50);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.green,
              ),
            ),
          );
        }

        final groups = snapshot.data?.docs ?? [];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...groups.take(3).map((group) {
              final data = group.data() as Map<String, dynamic>;
              return StreamBuilder<DocumentSnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(data['createdBy'])
                        .snapshots(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasData) {
                    final userData =
                        userSnapshot.data?.data() as Map<String, dynamic>?;
                    final photoUrl = userData?['photoURL'] as String?;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.green.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.green.withOpacity(0.2),
                          backgroundImage:
                              photoUrl != null
                                  ? CachedNetworkImageProvider(photoUrl)
                                  : null,
                          child:
                              photoUrl == null
                                  ? Text(
                                    data['name']
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                    );
                  }
                  return const SizedBox(width: 40);
                },
              );
            }),
            if (groups.length > 3)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.green.withOpacity(0.2),
                  child: Text(
                    '+${groups.length - 3}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _navigateToCreateGroup(BuildContext context) {
    try {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  CreateGroupForm(eventId: event.id),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      debugPrint('Erreur de navigation: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToGroupsList(BuildContext context) {
    try {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  JoinGroup(eventId: event.id),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      debugPrint('Erreur de navigation: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      color: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: event['imageUrl'] ?? 'assets/event_default.jpg',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        height: 200,
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.green),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        height: 200,
                        color: Colors.black26,
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                event['name'] ?? 'Sans titre',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormatter.formatDate(event['date']),
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event['location'] ?? 'Lieu non défini',
                      style: const TextStyle(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Flexible(child: _buildGroupsWidget()),
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('groups')
                            .where('eventId', isEqualTo: event.id)
                            .limit(1)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          width: 40,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.green,
                            ),
                          ),
                        );
                      }

                      final hasGroups = (snapshot.data?.docs.length ?? 0) > 0;

                      return Row(
                        children: [
                          // Bouton "Créer"
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: OutlinedButton(
                              onPressed: () => _navigateToCreateGroup(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor: Colors.transparent,
                              ),
                              child: const Text(
                                'CRÉER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ), // Espacement entre les boutons
                          // Bouton "Rejoindre"
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: OutlinedButton(
                              onPressed:
                                  hasGroups
                                      ? () => _navigateToGroupsList(context)
                                      : null, // Désactiver si aucun groupe
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor: Colors.transparent,
                              ),
                              child: const Text(
                                'REJOINDRE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
