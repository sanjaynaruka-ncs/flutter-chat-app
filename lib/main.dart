import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/auth_gate.dart';
import 'helpers/contact_helper.dart';
import 'helpers/contact_resolver.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await ContactResolver.loadContacts(); // ⭐ REQUIRED

  runApp(const TokWalkerApp());
}

class TokWalkerApp extends StatelessWidget {
  const TokWalkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TokWalker',
      home: AuthGate(), // 👈 THIS IS THE KEY LINE
    );
  }
}
