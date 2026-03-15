import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // Import this to access your ScannerScreen

// ==========================================
// 3. SIGN UP / ONBOARDING PAGE
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _avoidController = TextEditingController();

  final Color coral = const Color(0xfff57758);
  final Color skyBlue = const Color(0xff40bced);


  Future<void> _completeSignUp() async {
    // 1. Save all their data locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text);
    await prefs.setString('allergies', _allergiesController.text);
    await prefs.setString('avoid_ingredients', _avoidController.text);
    
    // 2. Mark them as logged in forever!
    await prefs.setBool('isLoggedIn', true);

    // 3. Send them to the Scanner Screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ScannerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo Area
                Icon(Icons.qr_code_scanner_rounded, size: 90, color: coral),
                const SizedBox(height: 20),
                Text(
                  "Welcome to Ethical Scanner",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: coral,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Personalize your ethical scanning experience.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                const SizedBox(height: 40),

                // Form Fields
                _buildTextField(
                  controller: _nameController,
                  label: "Your Name",
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _allergiesController,
                  label: "Allergens",
                  icon: Icons.warning_amber_rounded,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _avoidController,
                  label: "Ingredients to Avoid",
                  icon: Icons.do_not_disturb_alt_rounded,
                ),
                
                const SizedBox(height: 50),

                // Huge Coral Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: coral,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _completeSignUp,
                  child: const Text(
                    "Start Scanning",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to keep the UI code clean and consistent
  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: skyBlue, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: skyBlue),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: skyBlue.withAlpha(100), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: coral, width: 3),
        ),
      ),
    );
  }
}