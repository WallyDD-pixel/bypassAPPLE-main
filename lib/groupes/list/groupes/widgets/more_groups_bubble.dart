import 'package:flutter/material.dart';
import '../../event_groups_list.dart';

class MoreGroupsBubble extends StatelessWidget {
  final int count;
  final String eventId;

  const MoreGroupsBubble({
    super.key,
    required this.count,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventGroupsList(eventId: eventId),
        ),
      ),
      child: Container(
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
          child: Text(
            '+$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}