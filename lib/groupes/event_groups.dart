import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './list/groupes/widgets/group_bubble.dart';
import './list/groupes/widgets/more_groups_bubble.dart';

class EventGroups extends StatelessWidget {
  final String eventId;

  const EventGroups({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('groups')
              .where('eventId', isEqualTo: eventId)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 60);
        }

        final groups = snapshot.data!.docs;

        return SizedBox(
          height: 60,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              ...List.generate(groups.length.clamp(0, 3), (index) {
                final group = groups[index];
                return Positioned(
                  left: index * 30.0,
                  child: GroupBubble(group: group),
                );
              }),
              if (groups.length > 3)
                Positioned(
                  left: 90,
                  child: MoreGroupsBubble(
                    count: groups.length - 3,
                    eventId: eventId,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
