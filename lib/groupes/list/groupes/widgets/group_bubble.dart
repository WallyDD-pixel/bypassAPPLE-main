import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GroupBubble extends StatelessWidget {
  final DocumentSnapshot group;

  const GroupBubble({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final data = group.data() as Map<String, dynamic>?;
    final creatorId = data?['createdBy'] as String?;

    return StreamBuilder<DocumentSnapshot>(
      stream: creatorId != null
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(creatorId)
              .snapshots()
          : null,
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final photoURL = userData?['photoURL'] as String?;

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.green.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.green.withOpacity(0.2),
            child: ClipOval(
              child: photoURL != null
                  ? CachedNetworkImage(
                      imageUrl: photoURL,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 25,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 25,
                    ),
            ),
          ),
        );
      },
    );
  }
}