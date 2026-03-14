import 'package:flutter/material.dart';
import 'main_layout.dart';
import '../services/api_service.dart';
class PreferencesScreen extends StatefulWidget {
  final String userId; // Pass this from the Auth Screen!

  const PreferencesScreen({super.key, required this.userId});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _dislikesController = TextEditingController();
  final TextEditingController _dietaryController = TextEditingController();

  void _saveAndContinue() async {
    try {
      // Create the JSON payload
      final prefsData = {
        "allergies": _allergiesController.text.split(',').map((e) => e.trim()).toList(),
        "dislikes": _dislikesController.text.split(',').map((e) => e.trim()).toList(),
        "dietary_goals": _dietaryController.text.split(',').map((e) => e.trim()).toList(),
      };

      // Hit the backend!
      await ApiService.updatePreferences(widget.userId, prefsData);

      // Navigate to the main app
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const MainLayout())
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Set Preferences", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("What should we look out for?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text("Separate multiple items with commas.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            _buildInputSection("Allergies", "e.g. peanuts, dairy, shellfish", _allergiesController),
            const SizedBox(height: 20),
            
            _buildInputSection("Ingredients to Avoid", "e.g. cilantro, palm oil, pork", _dislikesController),
            const SizedBox(height: 20),
            
            _buildInputSection("Dietary Goals", "e.g. vegan, keto, gluten-free", _dietaryController),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008C5A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _saveAndContinue,
                child: const Text("Save & Start Scanning", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(String title, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}