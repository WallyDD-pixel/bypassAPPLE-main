import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:google_fonts/google_fonts.dart';
import 'widgets/Groupinfosection.dart';
import 'widgets/price_section.dart';
import 'widgets/custom_button.dart';
import '../auth/custom_login_page.dart';

class CreateGroupDetailsPage extends StatefulWidget {
  final String eventId;
  final int maxWomen;

  const CreateGroupDetailsPage({
    super.key,
    required this.eventId,
    required this.maxWomen,
  });

  @override
  State<CreateGroupDetailsPage> createState() => _CreateGroupDetailsPageState();
}

class _CreateGroupDetailsPageState extends State<CreateGroupDetailsPage> {
  bool _isCreating = false;
  bool _isLoading = true;
  double _price = 20.0;
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isLoading = false);
      _checkAuth();
    }
  }

  void _checkAuth() {
    if (FirebaseAuth.instance.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoginDialog(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    Widget mainContent = Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        title: Text(
          'Détails du groupe',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
      body: _buildBody(),
    );

    if (_isLoading) {
      return Stack(
        children: [
          mainContent,
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1500),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (value * 0.2),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: Stack(
                                    children: [
                                      CircularProgressIndicator(
                                        color: Colors.green.withOpacity(0.3),
                                        strokeWidth: 3,
                                      ),
                                      Positioned.fill(
                                        child: TweenAnimationBuilder<double>(
                                          duration: const Duration(
                                            milliseconds: 1500,
                                          ),
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          builder: (context, value, child) {
                                            return Transform.rotate(
                                              angle: value * 6.28319, // 2 * pi
                                              child: CircularProgressIndicator(
                                                color: Colors.green,
                                                strokeWidth: 3,
                                                value: 0.25,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ShaderMask(
                                  shaderCallback:
                                      (bounds) => LinearGradient(
                                        colors: [
                                          Colors.white70,
                                          Colors.green.withOpacity(0.7),
                                        ],
                                        stops: [0.0, value],
                                      ).createShader(bounds),
                                  child: Text(
                                    'Chargement...',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 500),
                                  opacity: value,
                                  child: Text(
                                    'Veuillez patienter',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white38,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 0,
          title: Text(
            'Connexion requise',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.green.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                'Vous devez être connecté\npour créer un groupe',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _showLoginDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Se connecter',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return mainContent;
  }

  void _showLoginDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomLoginPage()),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.withOpacity(0.2), Colors.black, Colors.black],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GroupInfoSection(
                selectedTime: _selectedTime,
                onTimeChanged: (time) => setState(() => _selectedTime = time),
                maxWomen: widget.maxWomen,
              ),
              const SizedBox(height: 20),
              PriceSection(
                price: _price,
                onPriceChanged: (value) => setState(() => _price = value),
                maxWomen: widget.maxWomen,
              ),
              const SizedBox(height: 30),
              CustomButton(
                isLoading: _isCreating,
                onPressed: _createGroup,
                label: 'Créer le groupe',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    setState(() => _isCreating = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Vous devez être connecté pour créer un groupe';

      // Créer le groupe
      final groupRef = await FirebaseFirestore.instance
          .collection('groups')
          .add({
            'eventId': widget.eventId,
            'createdBy': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'arrivalTime': {
              'hour': _selectedTime.hour,
              'minute': _selectedTime.minute,
            },
            'maxWomen': widget.maxWomen,
            'maxMen': widget.maxWomen,
            'totalCapacity': widget.maxWomen * 2,
            'price': _price,
            'currency': 'EUR',
            'members': {
              'women': [user.uid],
              'men': [],
            },
          });

      // Créer le chat associé au groupe
      await FirebaseFirestore.instance.collection('chats').doc(groupRef.id).set({
        'groupId': groupRef.id,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'messages':
            [], // Vous pouvez initialiser avec une liste vide ou ne pas inclure ce champ
      });

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Groupe et chat créés avec succès',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _handleAuthenticationRequired() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomLoginPage()),
    );

    if (result == true) {
      // L'utilisateur est maintenant connecté, vous pouvez recharger les données
      // ou effectuer l'action qui nécessitait l'authentification
    }
  }
}
