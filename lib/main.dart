import 'package:bypass/paiement/stripe_payment_service.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  StripeService.init(); // Initialisation de Stripe

  try {
    // Initialisation de Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configuration pour le développement
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );

    // Configuration de Firebase Storage
    FirebaseStorage.instance.setMaxUploadRetryTime(const Duration(seconds: 3));
    FirebaseStorage.instance.setMaxDownloadRetryTime(
      const Duration(seconds: 3),
    );
  } catch (e) {
    debugPrint('Erreur lors de l\'initialisation : $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mon Application',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const OnBoardingPage(),
    );
  }
}

class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<PageViewModel> pages = [
      PageViewModel(
        title: "Bienvenue",
        body: "Découvrez notre application",
        image: Image.asset("assets/onboard_one.png"),
      ),
      PageViewModel(
        title: "Fonctionnalités",
        body: "Explorez toutes nos fonctionnalités",
        image: Image.asset("assets/onboard_two.png"),
      ),
      PageViewModel(
        title: "C'est parti !",
        body: "Commencez à utiliser l'application",
        image: Image.asset("assets/onboard_three.png"),
      ),
    ];
    

    return Scaffold(
      body: IntroductionScreen(
        pages: pages,
        showSkipButton: true,
        skip: const Text("Passer"),
        next: const Text("Suivant"),
        done: const Text("Terminer"),
        onDone: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        },
        onSkip: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        },
        dotsDecorator: DotsDecorator(
          size: const Size(10.0, 10.0),
          color: Colors.grey,
          activeSize: const Size(22.0, 10.0),
          activeColor: Colors.blue,
          spacing: const EdgeInsets.symmetric(horizontal: 3.0),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
      ),
    );
    
    
  }
}
