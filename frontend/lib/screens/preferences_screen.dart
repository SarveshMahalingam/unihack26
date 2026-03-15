// import 'package:flutter/material.dart';
// import 'main_layout.dart';
// import '../services/api_service.dart';

// class PreferencesScreen extends StatefulWidget {
//   final String userId;

//   const PreferencesScreen({super.key, required this.userId});

//   @override
//   State<PreferencesScreen> createState() => _PreferencesScreenState();
// }

// class _PreferencesScreenState extends State<PreferencesScreen> {
//   final TextEditingController _allergiesController = TextEditingController();
//   final TextEditingController _dislikesController = TextEditingController();
//   final TextEditingController _dietaryController = TextEditingController();
//   bool _isSaving = false;

//   void _saveAndContinue() async {
//   print("🔘 SAVE BUTTON CLICKED!"); // <--- ADD THIS
//   setState(() => _isSaving = true);
//   try {
//     final prefsData = {
//       // Ensure we always send a List, even if empty
//       "allergies": _allergiesController.text.isNotEmpty 
//           ? _allergiesController.text.split(',').map((e) => e.trim()).toList() 
//           : [],
//       "dislikes": _dislikesController.text.isNotEmpty 
//           ? _dislikesController.text.split(',').map((e) => e.trim()).toList() 
//           : [],
//       "dietary_goals": _dietaryController.text.isNotEmpty 
//           ? _dietaryController.text.split(',').map((e) => e.trim()).toList() 
//           : [],
//     };

//     print("🚀 SENDING DATA: $prefsData"); // Check your Flutter console for this!
//     await ApiService.updatePreferences(widget.userId, prefsData);

//       // 3. Navigate to the main app layout
//       if (mounted) {
//         Navigator.pushReplacement(
//           context, 
//           MaterialPageRoute(builder: (_) => MainLayout(userId: widget.userId))
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isSaving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: const Text("Set Preferences", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("What should we look out for?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
//             const SizedBox(height: 8),
//             const Text("Separate multiple items with commas.", style: TextStyle(color: Colors.grey)),
//             const SizedBox(height: 30),

//             _buildInputSection("Allergies", "e.g. peanuts, dairy, shellfish", _allergiesController),
//             const SizedBox(height: 20),
            
//             _buildInputSection("Ingredients to Avoid", "e.g. cilantro, palm oil, pork", _dislikesController),
//             const SizedBox(height: 20),
            
//             _buildInputSection("Dietary Goals", "e.g. vegan, keto, gluten-free", _dietaryController),
//             const SizedBox(height: 40),

//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF008C5A),
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                 ),
//                 onPressed: _isSaving ? null : _saveAndContinue,
//                 child: _isSaving 
//                   ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                   : const Text("Save & Start Scanning", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInputSection(String title, String hint, TextEditingController controller) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//         const SizedBox(height: 8),
//         TextField(
//           controller: controller,
//           decoration: InputDecoration(
//             hintText: hint,
//             filled: true,
//             fillColor: Colors.grey.shade100,
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'main_layout.dart';
import '../services/api_service.dart';

class PreferencesScreen extends StatefulWidget {
  final String userId;

  const PreferencesScreen({super.key, required this.userId});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _dislikesController = TextEditingController();
  final TextEditingController _dietaryController = TextEditingController();
  
  bool _isSaving = false;

  // 🚨 NEW: Lists to hold the UI chips!
  List<String> allergies = [];
  List<String> dislikes = [];
  List<String> dietaryGoals = [];

  // Helper to add items to the lists
  void _addItem(String item, List<String> list, TextEditingController controller) {
    String trimmed = item.trim();
    if (trimmed.isNotEmpty && !list.contains(trimmed)) {
      setState(() {
        list.add(trimmed);
        controller.clear();
      });
    }
  }

  void _saveAndContinue() async {
    setState(() => _isSaving = true);
    try {
      // 🚨 Much cleaner payload! We just pass the lists directly.
      final prefsData = {
        "allergies": allergies,
        "dislikes": dislikes,
        "dietary_goals": dietaryGoals,
      };

      print("🚀 SENDING DATA: $prefsData"); 
      await ApiService.updatePreferences(widget.userId, prefsData);

      // Navigate to the main app layout
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => MainLayout(userId: widget.userId))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
            const Text("Add your dietary requirements below.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            // 🚨 NEW CHIP UI SECTIONS
            _buildInputSection("Allergies", "e.g. peanuts, dairy", allergies, _allergiesController, Colors.red.shade400),
            _buildInputSection("Ingredients to Avoid", "e.g. cilantro, palm oil", dislikes, _dislikesController, Colors.orange.shade400),
            _buildInputSection("Dietary Goals", "e.g. vegan, keto", dietaryGoals, _dietaryController, Colors.green.shade400),
            
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008C5A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _saveAndContinue,
                child: _isSaving 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Save & Start Scanning", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 🚨 REPLACED WITH THE DYNAMIC PLUS-BUTTON UI
  Widget _buildInputSection(String title, String hint, List<String> items, TextEditingController controller, Color chipColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onSubmitted: (val) => _addItem(val, items, controller),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(color: const Color(0xFF008C5A), borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _addItem(controller.text, items, controller),
              ),
            )
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Chip(
              label: Text(item, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              backgroundColor: chipColor,
              deleteIconColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: chipColor)),
              onDeleted: () => setState(() => items.remove(item)),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}