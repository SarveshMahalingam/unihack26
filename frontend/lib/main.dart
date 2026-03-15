import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_screen.dart';     // Adjust paths if your files 
import 'screens/main_layout.dart';    // are in a different folder!

void main() async {
  // 1. Essential for accessing phone storage before the app starts
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Check if a user is already logged in
  final prefs = await SharedPreferences.getInstance();
  final String? userId = prefs.getString('user_id');

  runApp(MyApp(initialUserId: userId));
}

class MyApp extends StatelessWidget {
  final String? initialUserId;
  
  const MyApp({super.key, this.initialUserId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EthiScan AI',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      // 3. The Logic: If we have an ID, skip login and go to the app
      home: initialUserId != null 
          ? MainLayout(userId: initialUserId!) 
          : const AuthScreen(),
    );
  }
}