import 'package:flutter/material.dart';

class HomeFab extends StatelessWidget {
  final VoidCallback onPressed;

  const HomeFab({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.green.shade600,
      onPressed: onPressed,
      child: const Icon(
        Icons.chat,
        color: Colors.white,
      ),
    );
  }
}
