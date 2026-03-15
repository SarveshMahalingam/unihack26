import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final String userId;

  const EditProfileScreen({super.key, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // 🚨 Make sure this IP matches the one in your ProfileScreen!
  final String apiUrl = 'http://10.44.177.27:8000';

  bool isLoading = true;
  bool isSaving = false;

  List<String> allergies = [];
  List<String> dislikes = [];
  List<String> dietaryGoals = [];
  List<String> savedEthicalTags = []; // Hidden list to protect your toggle states!

  final TextEditingController _allergyCtrl = TextEditingController();
  final TextEditingController _dislikeCtrl = TextEditingController();
  final TextEditingController _dietCtrl = TextEditingController();

  final List<String> _knownEthics = [
    "Fair Trade & Labor",
    "Cruelty-Free",
    "Eco-Friendly Packaging"
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentData();
  }

  Future<void> _fetchCurrentData() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/profile/${widget.userId}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        setState(() {
          allergies = List<String>.from(data['allergies'] ?? []);
          dislikes = List<String>.from(data['dislikes'] ?? []);
          
          final allGoals = List<String>.from(data['dietary_goals'] ?? []);
          
          // Separate the normal diet goals from the ethical toggles
          savedEthicalTags = allGoals.where((g) => _knownEthics.contains(g)).toList();
          dietaryGoals = allGoals.where((g) => !_knownEthics.contains(g)).toList();
          
          isLoading = false;
        });
      }
    } catch (e) {
      print("Failed to load data: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => isSaving = true);
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/profile/${widget.userId}'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "allergies": allergies,
          "dislikes": dislikes,
          // Recombine the diet text inputs with the hidden ethical toggles!
          "dietary_goals": [...dietaryGoals, ...savedEthicalTags]
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          // Pop the screen and return true so the previous screen knows to refresh
          Navigator.pop(context, true); 
        }
      }
    } catch (e) {
      print("Save failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _addItem(String item, List<String> list, TextEditingController controller) {
    String trimmed = item.trim();
    if (trimmed.isNotEmpty && !list.contains(trimmed)) {
      setState(() {
        list.add(trimmed);
        controller.clear();
      });
    }
  }

  // --- UI BUILDER HELPER ---
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
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Edit Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF008C5A)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputSection("Allergies", "e.g., Peanuts, Dairy", allergies, _allergyCtrl, Colors.red.shade400),
                _buildInputSection("Dislikes", "e.g., Mushrooms, Cilantro", dislikes, _dislikeCtrl, Colors.orange.shade400),
                _buildInputSection("Dietary Goals", "e.g., Vegan, Keto", dietaryGoals, _dietCtrl, Colors.blue.shade400),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008C5A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: isSaving 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Save Changes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
    );
  }
}