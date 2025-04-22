import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchBar extends StatefulWidget {
  final ValueChanged<List<QueryDocumentSnapshot>> onResults;
  final String eventId; // Ajout du paramètre eventId

  const SearchBar({super.key, required this.onResults, required this.eventId});

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _controller = TextEditingController();
  List<QueryDocumentSnapshot> _searchResults = [];

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      widget.onResults(_searchResults);
      return;
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('groups')
              .where('eventId', isEqualTo: 'someEventId')
              .orderBy('name')
              .startAt([query])
              .endAt(['$query\uf8ff'])
              .get();

      setState(() {
        _searchResults = snapshot.docs;
      });

      widget.onResults(_searchResults);
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Index manquant'),
                content: const Text(
                  'Cette recherche nécessite un index Firestore. Veuillez le créer dans la console Firebase.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      } else {
        print('Erreur Firestore : ${e.message}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _controller,
            onChanged: _performSearch,
            decoration: InputDecoration(
              hintText: 'Rechercher un groupe...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        // Afficher les résultats de recherche
        if (_searchResults.isNotEmpty)
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final group =
                    _searchResults[index].data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(
                    group['name'] ?? 'Nom inconnu',
                    style: const TextStyle(color: Colors.black),
                  ),
                  subtitle: Text(
                    group['description'] ?? 'Pas de description',
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        if (_searchResults.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Aucun résultat trouvé.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
