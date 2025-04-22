import 'dart:convert'; // Ajout de l'import pour jsonDecode
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class StripeService {
  static String apiBase = 'https://api.stripe.com/v1';
  static String paymentApiUrl = '${StripeService.apiBase}/payment_intents';
  static String secret =
      "sk_test_51R9UtSIxsnbgzJcJ3ngzWeIaHRaPzOV6uMSLyN4QDucfvJwyPSwl3M8lPGxOFBVDP8oIskTKPdNHeFjjnWx5X30m00uyKj5EkW"; // Remplacez par votre clé secrète

  static Map<String, String> headers = {
    "Authorization":
        'Bearer ${StripeService.secret}', // Correction de "Authorization"
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  static void init() {
    Stripe.publishableKey =
        'pk_test_51R9UtSIxsnbgzJcJs5gS6kaiUtSSV9bzPyoa5dXz2AR6tP65JXvBK0MSI3QHN4BrxDHgnSMBp9NuObhWqnOpTeKY00qwNSuZ0t'; // Remplacez par votre clé publique
  }

  static Future<Map<String, dynamic>> createPaymentIntent(
    String amount,
    String currency,
  ) async {
    try {
      final body = {
        'amount': amount, // Montant en centimes
        'currency': currency, // Devise (ex : 'eur')
        'payment_method_types[]': 'card', // Méthode de paiement
        'capture_method': 'manual', // Pré-autorisation
      };

      final response = await http.post(
        Uri.parse(paymentApiUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Convertit la réponse JSON en Map
      } else {
        throw Exception(
          'Erreur lors de la création du PaymentIntent : ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erreur lors de la création du PaymentIntent : $e');
    }
  }

  static Future<void> initPaymentSheet(String amount, String currency) async {
    try {
      final paymentIntent = await createPaymentIntent(amount, currency);

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: "Your Merchant Name",
          style: ThemeMode.light,
        ),
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de l\'initialisation de la feuille de paiement : $e',
      );
    }
  }

  static Future<void> presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      throw Exception(
        'Erreur lors de la présentation de la feuille de paiement : $e',
      );
    }
  }

  static Future<void> capturePayment(String paymentIntentId) async {
    try {
      final url =
          '${StripeService.apiBase}/payment_intents/$paymentIntentId/capture';

      final response = await http.post(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        print('Paiement capturé avec succès pour $paymentIntentId');
      } else {
        throw Exception(
          'Erreur lors de la capture du paiement : ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erreur lors de la capture du paiement : $e');
    }
  }
}
