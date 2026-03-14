import 'package:flutter/material.dart';
import 'screens/auth_screen.dart'; // <-- Importing your new auth screen!

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EthicalScannerApp());
}

class EthicalScannerApp extends StatelessWidget {
  const EthicalScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ethical Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF545333), // Your custom deep olive
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // THE MAGIC LINE: This tells the app to start at the new AuthScreen
      home: const AuthScreen(), 
    );
  }
}