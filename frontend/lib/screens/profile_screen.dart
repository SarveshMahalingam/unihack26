import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // TODO: Fetch this data dynamically from your FastAPI backend on initState()
  String userName = "Sarah Jenkins";
  int scanCount = 142;
  List<String> userAllergies = ["Nut Allergy", "Gluten-Free"];
  List<String> userDiet = ["Vegan"];

  // Toggle states for Ethical Priorities
  Map<String, bool> ethicalPriorities = {
    "Fair Trade & Labor": true,
    "Cruelty-Free": true,
    "Eco-Friendly Packaging": false,
  };

  void _toggleEthics(String key) {
    setState(() {
      ethicalPriorities[key] = !ethicalPriorities[key]!;
    });
    // TODO: Send updated preferences silently to the backend API here
  }

  void _openEditScreen() {
    // TODO: Navigate to EditProfileScreen (which is basically just the Onboarding screen again)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Your Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: _openEditScreen, // THE EDIT BUTTON!
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User ID Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      userName.split(' ').map((e) => e[0]).join(), // "SJ"
                      style: const TextStyle(color: Color(0xFF008C5A), fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text("$scanCount Products Scanned", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Health & Dietary Section
            const Text("❤️ Health & Dietary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("We will alert you if a scanned product conflicts with these settings.", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ...userAllergies.map((item) => _buildDietCard(item, Icons.shield_outlined, const Color(0xFFFEECEE), Colors.red)),
                ...userDiet.map((item) => _buildDietCard(item, Icons.eco_outlined, Colors.white, Colors.grey.shade800, hasBorder: true)),
              ],
            ),
            const SizedBox(height: 32),

            // Ethical Priorities Section
            const Text("🌿 Ethical Priorities", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildEthicsToggle("Fair Trade & Labor", "Prioritize workers' rights and fair wages.", Icons.people_outline),
            const SizedBox(height: 12),
            _buildEthicsToggle("Cruelty-Free", "No animal testing in the supply chain.", Icons.pets),
            const SizedBox(height: 12),
            _buildEthicsToggle("Eco-Friendly Packaging", "Recyclable or minimal plastic usage.", Icons.recycling),
            
            const SizedBox(height: 80), // Padding for bottom nav bar
          ],
        ),
      ),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildDietCard(String title, IconData icon, Color bgColor, Color iconColor, {bool hasBorder = false}) {
    return Container(
      width: (MediaQuery.of(context).size.width / 2) - 30, // 2 columns
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: hasBorder ? Border.all(color: Colors.grey.shade300) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEthicsToggle(String title, String subtitle, IconData icon) {
    bool isActive = ethicalPriorities[title] ?? false;
    
    return GestureDetector(
      onTap: () => _toggleEthics(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEAF5EB) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? const Color(0xFF008C5A) : Colors.grey.shade300, width: isActive ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? const Color(0xFF008C5A) : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isActive ? Colors.black : Colors.black87)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isActive ? Colors.grey.shade700 : Colors.grey)),
                ],
              ),
            ),
            Icon(
              isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isActive ? const Color(0xFF008C5A) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}