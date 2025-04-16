import 'package:cloud_firestore/cloud_firestore.dart';

class DateFormatter {
  static String formatDate(dynamic date) {
    if (date == null) return 'Date non définie';
    if (date is Timestamp) {
      final DateTime dateTime = date.toDate();
      return '${dateTime.day} ${_getMonth(dateTime.month)} ${dateTime.year}';
    }
    return 'Date invalide';
  }

  static String _getMonth(int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }
}