import 'package:flutter/material.dart';
//import 'package:neurodrive/core/theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const CustomButton({super.key, required this.text, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)), child: Text(text));
  }
}
