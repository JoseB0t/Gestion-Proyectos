import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String prettyDateTime(DateTime dt) {
  final f = DateFormat('yyyy-MM-dd HH:mm:ss');
  return f.format(dt);
}

String shortDate(DateTime dt) {
  final f = DateFormat('dd/MM/yyyy');
  return f.format(dt);
}

Color statusColor(String status) {
  switch (status) {
    case 'normal':
      return Color(0xFF2EB872);
    case 'warning':
      return Color(0xFFF4C542);
    case 'danger':
      return Color(0xFFEA4335);
    default:
      return Colors.grey;
  }
}

String uidNow() => DateTime.now().millisecondsSinceEpoch.toString();
