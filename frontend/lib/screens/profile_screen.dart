// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../services/api_service.dart';
// import 'edit_profile_screen.dart'; 

// class ProfileScreen extends StatefulWidget {
//   final String userId;

//   const ProfileScreen({super.key, required this.userId});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   bool isLoading = true;
//   String userName = "Sarvesh"; 
//   int scanCount = 0;
//   List<String> userAllergies = [];
//   List<String> userDislikes = [];
//   List<String> userGoals = [];

//   Map<String, bool> ethicalPriorities = {
//     "Fair Trade & Labor": true,
//     "Cruelty-Free": true,
//     "Eco-Friendly Packaging": false,
//   };

//   @override
//   void initState() {
//     super.initState();
//     _fetchProfileData();
//   }

//   Future<void> _fetchProfileData() async {
//       final cachedData = await ApiService.getCachedProfile(widget.userId);
//       if (cachedData != null) {
//         setState(() {
//           userName = cachedData['user_name'] ?? "User";
//           scanCount = cachedData['scan_count'] ?? 0;
//           userAllergies = List<String>.from(cachedData['allergies'] ?? []);
//           userDislikes = List<String>.from(cachedData['dislikes'] ?? []);
//           userGoals = List<String>.from(cachedData['dietary_goals'] ?? []);
        
//           isLoading = false; // Turn off spinner instantly!
//         });
//       }
//       try {
//     final response = await http.get(Uri.parse('${ApiService.baseUrl}/profile/${widget.userId}'));
    
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
      
//       // Save this fresh data to the phone for next time!
//       await ApiService.cacheProfileData(widget.userId, data);

//       // Update UI with any new server changes
//       setState(() {
//         userName = data['user_name'] ?? "User";
//         scanCount = data['scan_count'] ?? 0;
//         userAllergies = List<String>.from(data['allergies'] ?? []);
//         userDislikes = List<String>.from(data['dislikes'] ?? []);
//         userGoals = List<String>.from(data['dietary_goals'] ?? []);

//         // ... (update goals same as above)
//         isLoading = false;
//       });
//     }
//   } catch (e) {
//     print("Offline mode: Using locally cached profile data. Error: $e");
//     setState(() => isLoading = false);
//   }
// }


//   Future<void> _updateProfileSilently() async {
//     try {
//       final payload = {
//         "allergies": userAllergies,
//         "dislikes": userDislikes,
//         "dietary_goals": userGoals
//       };
//       // Re-using our verified updatePreferences method
//       await ApiService.updatePreferences(widget.userId, payload);
//     } catch (e) {
//       print("⚠️ Silent update failed: $e");
//     }
//   }

//   void _toggleEthics(String key) {
//     setState(() {
//       ethicalPriorities[key] = !ethicalPriorities[key]!;
//     });
//     _updateProfileSilently();
//   }

//   void _openEditScreen() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => EditProfileScreen(userId: widget.userId)),
//     ).then((wasUpdated) {
//       if (wasUpdated == true) {
//         setState(() => isLoading = true);
//         _fetchProfileData();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF008C5A))));
//     }

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: const Text("Your Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 24)),
//         actions: [
//           IconButton(icon: const Icon(Icons.settings, color: Colors.grey), onPressed: _openEditScreen),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // User Card
//             _buildUserCard(),
//             const SizedBox(height: 32),

//             // Health & Dietary Heading
//             const Text("❤️ Health & Dietary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             Text("We'll alert you if a product conflicts with these.", 
//               style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
//             const SizedBox(height: 20),

//             // DYNAMIC CATEGORIES
//             _buildChipCategory("Allergies", Icons.health_and_safety, Colors.red, userAllergies),
//             _buildChipCategory("Avoid Ingredients", Icons.block, Colors.orange, userDislikes),
//             _buildChipCategory("Dietary Goals", Icons.eco, Colors.green, userGoals),

//             // If everything is empty
//             if (userAllergies.isEmpty && userDislikes.isEmpty && userGoals.isEmpty)
//               _buildEmptyPlaceholder(),

//             const SizedBox(height: 32),

//             // Ethical Priorities
//             const Text("🌿 Ethical Priorities", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 16),
//             ...ethicalPriorities.keys.map((key) => Padding(
//               padding: const EdgeInsets.only(bottom: 12),
//               child: _buildEthicsToggle(key, _getEthicsSubtitle(key), _getEthicsIcon(key)),
//             )).toList(),
            
//             const SizedBox(height: 80), 
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildUserCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: Colors.green.shade100,
//             child: Text(userName[0].toUpperCase(), 
//               style: const TextStyle(color: Color(0xFF008C5A), fontWeight: FontWeight.bold, fontSize: 24)),
//           ),
//           const SizedBox(width: 16),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//               Text("$scanCount Products Scanned", style: const TextStyle(color: Colors.grey, fontSize: 14)),
//             ],
//           )
//         ],
//       ),
//     );
//   }

//   //  Change 'Color' to 'MaterialColor' here
//   Widget _buildChipCategory(String title, IconData icon, MaterialColor color, List<String> items) {
//     if (items.isEmpty) return const SizedBox.shrink();

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, size: 16, color: color),
//               const SizedBox(width: 8),
//               // Now .shade700 will work perfectly
//               Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color.shade700, fontSize: 14)),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: items.map((tag) => Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: color.withOpacity(0.2)),
//               ),
//               child: Text(
//                 tag, 
//                 // Now .shade800 will work perfectly
//                 style: TextStyle(color: color.shade800, fontWeight: FontWeight.w600, fontSize: 13)
//               ),
//             )).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyPlaceholder() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
//       child: const Text("Tap settings to add allergies or diet goals.", 
//         style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
//     );
//   }

//   Widget _buildEthicsToggle(String title, String subtitle, IconData icon) {
//     bool isActive = ethicalPriorities[title] ?? false;
//     return GestureDetector(
//       onTap: () => _toggleEthics(title),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: isActive ? const Color(0xFFEAF5EB) : Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: isActive ? const Color(0xFF008C5A) : Colors.grey.shade300, width: isActive ? 2 : 1),
//         ),
//         child: Row(
//           children: [
//             Icon(icon, color: isActive ? const Color(0xFF008C5A) : Colors.grey),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                   Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
//                 ],
//               ),
//             ),
//             Icon(isActive ? Icons.check_circle : Icons.radio_button_unchecked, color: isActive ? const Color(0xFF008C5A) : Colors.grey),
//           ],
//         ),
//       ),
//     );
//   }

//   // Helper getters for Ethics section
//   String _getEthicsSubtitle(String key) {
//     if (key.contains("Fair")) return "Prioritize workers' rights and fair wages.";
//     if (key.contains("Cruelty")) return "No animal testing in the supply chain.";
//     return "Recyclable or minimal plastic usage.";
//   }

//   IconData _getEthicsIcon(String key) {
//     if (key.contains("Fair")) return Icons.people_outline;
//     if (key.contains("Cruelty")) return Icons.pets;
//     return Icons.recycling;
//   }
// }


// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../services/api_service.dart';
// import 'edit_profile_screen.dart'; 
// import 'auth_screen.dart'; // 🚨 Ensure this matches your login screen filename!

// class ProfileScreen extends StatefulWidget {
//   final String userId;

//   const ProfileScreen({super.key, required this.userId});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   bool isLoading = true;
//   String userName = "User"; 
//   int scanCount = 0;
//   List<String> userAllergies = [];
//   List<String> userDislikes = [];
//   List<String> userGoals = [];

//   @override
//   void initState() {
//     super.initState();
//     _fetchProfileData();
//   }

//   Future<void> _fetchProfileData() async {
//     // 1. INSTANT LOAD: Check phone storage first
//     final cachedData = await ApiService.getCachedProfile(widget.userId);
//     if (cachedData != null) {
//       setState(() {
//         userName = cachedData['user_name'] ?? "User";
//         scanCount = cachedData['scan_count'] ?? 0;
//         userAllergies = List<String>.from(cachedData['allergies'] ?? []);
//         userDislikes = List<String>.from(cachedData['dislikes'] ?? []);
//         userGoals = List<String>.from(cachedData['dietary_goals'] ?? []);
//         isLoading = false; 
//       });
//     }

//     // 2. BACKGROUND SYNC
//     try {
//       final response = await http.get(Uri.parse('${ApiService.baseUrl}/profile/${widget.userId}'));
      
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
        
//         // Save fresh data to local cache
//         await ApiService.cacheProfileData(widget.userId, data);

//         if (mounted) {
//           setState(() {
//             userName = data['user_name'] ?? "User";
//             scanCount = data['scan_count'] ?? 0;
//             userAllergies = List<String>.from(data['allergies'] ?? []);
//             userDislikes = List<String>.from(data['dislikes'] ?? []);
//             userGoals = List<String>.from(data['dietary_goals'] ?? []);
//             isLoading = false;
//           });
//         }
//       }
//     } catch (e) {
//       print("Offline mode: Using locally cached profile data. Error: $e");
//       if (mounted) setState(() => isLoading = false);
//     }
//   }

//   // 🚨 THE LOGOUT FUNCTION
//   void _logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear(); // Wipes the cache!
    
//     if (mounted) {
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => const AuthScreen()), 
//         (Route<dynamic> route) => false, 
//       );
//     }
//   }

//   void _openEditScreen() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => EditProfileScreen(userId: widget.userId)),
//     ).then((wasUpdated) {
//       if (wasUpdated == true) {
//         setState(() => isLoading = true);
//         _fetchProfileData();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF008C5A))));
//     }

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: const Text("Your Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 24)),
//         actions: [
//           // 🚨 REPLACED SETTINGS WITH LOGOUT
//           IconButton(
//             icon: const Icon(Icons.logout, color: Colors.red), 
//             onPressed: () {
//               showDialog(
//                 context: context,
//                 builder: (context) => AlertDialog(
//                   title: const Text("Log Out"),
//                   content: const Text("Are you sure you want to log out?"),
//                   actions: [
//                     TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
//                     TextButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         _logout();
//                       }, 
//                       child: const Text("Log Out", style: TextStyle(color: Colors.red))
//                     ),
//                   ],
//                 )
//               );
//             }
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // User Card
//             _buildUserCard(),
//             const SizedBox(height: 32),

//             // Health & Dietary Heading
//             const Text("❤️ Health & Dietary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             Text("We'll alert you if a product conflicts with these.", 
//               style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
//             const SizedBox(height: 20),

//             // 🚨 BIG BOX CATEGORIES (Dynamically hides if empty)
//             _buildBigBoxCategory("Allergies", Icons.health_and_safety, Colors.red, userAllergies),
//             _buildBigBoxCategory("Avoid Ingredients", Icons.block, Colors.orange, userDislikes),
//             _buildBigBoxCategory("Dietary Goals", Icons.eco, Colors.green, userGoals),

//             // If everything is empty
//             if (userAllergies.isEmpty && userDislikes.isEmpty && userGoals.isEmpty)
//               _buildEmptyPlaceholder(),

//             const SizedBox(height: 40), 
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildUserCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: Colors.green.shade100,
//             child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : "?", 
//               style: const TextStyle(color: Color(0xFF008C5A), fontWeight: FontWeight.bold, fontSize: 24)),
//           ),
//           const SizedBox(width: 16),
//           // Expanded pushes the edit button to the right edge
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                 Text("$scanCount Products Scanned", style: const TextStyle(color: Colors.grey, fontSize: 14)),
//               ],
//             ),
//           ),
//           // 🚨 EDIT BUTTON ADDED HERE
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.grey.shade100,
//               shape: BoxShape.circle,
//             ),
//             child: IconButton(
//               icon: const Icon(Icons.edit_document, color: Colors.black87, size: 20),
//               onPressed: _openEditScreen,
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   // 🚨 BIG BOX UI LOGIC
//   Widget _buildBigBoxCategory(String title, IconData icon, MaterialColor color, List<String> items) {
//     if (items.isEmpty) return const SizedBox.shrink();

//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.only(bottom: 20),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, size: 20, color: color.shade700),
//               const SizedBox(width: 8),
//               Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color.shade800, fontSize: 16)),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: items.map((tag) => Container(
//               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.white, 
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: color.withOpacity(0.4)),
//                 boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
//               ),
//               child: Text(tag.toUpperCase(), style: TextStyle(color: color.shade800, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
//             )).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyPlaceholder() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50, 
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.shade200)
//       ),
//       child: Column(
//         children: [
//           Icon(Icons.monitor_heart_outlined, size: 40, color: Colors.grey.shade400),
//           const SizedBox(height: 12),
//           const Text("No preferences set.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 4),
//           Text("Tap the edit button above to customize your health goals.", 
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'edit_profile_screen.dart'; 
import 'auth_screen.dart'; // 🚨 Ensure this matches your login screen filename!

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  String userName = "User"; 
  int scanCount = 0;
  List<String> userAllergies = [];
  List<String> userDislikes = [];
  List<String> userGoals = [];

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    // 1. INSTANT LOAD: Check phone storage first
    final cachedData = await ApiService.getCachedProfile(widget.userId);
    if (cachedData != null) {
      setState(() {
        userName = cachedData['user_name'] ?? "User";
        scanCount = cachedData['scan_count'] ?? 0;
        userAllergies = List<String>.from(cachedData['allergies'] ?? []);
        userDislikes = List<String>.from(cachedData['dislikes'] ?? []);
        userGoals = List<String>.from(cachedData['dietary_goals'] ?? []);
        isLoading = false; 
      });
    }

    // 2. BACKGROUND SYNC
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/profile/${widget.userId}'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Save fresh data to local cache
        await ApiService.cacheProfileData(widget.userId, data);

        if (mounted) {
          setState(() {
            userName = data['user_name'] ?? "User";
            scanCount = data['scan_count'] ?? 0;
            userAllergies = List<String>.from(data['allergies'] ?? []);
            userDislikes = List<String>.from(data['dislikes'] ?? []);
            userGoals = List<String>.from(data['dietary_goals'] ?? []);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Offline mode: Using locally cached profile data. Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 🚨 THE LOGOUT FUNCTION
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Wipes the cache!
    
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()), 
        (Route<dynamic> route) => false, 
      );
    }
  }

  void _openEditScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(userId: widget.userId)),
    ).then((wasUpdated) {
      if (wasUpdated == true) {
        setState(() => isLoading = true);
        _fetchProfileData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF008C5A))));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        title: const Text("Your Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent), 
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      }, 
                      child: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
                    ),
                  ],
                )
              );
            }
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🚨 NEW PREMIUM USER CARD
            _buildUserCard(),
            const SizedBox(height: 36),

            // Health & Dietary Heading
            const Text("Health & Dietary", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text("We'll alert you if a product conflicts with these.", 
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 24),

            // 🚨 NEW GRADIENT BOX CATEGORIES
            _buildBigBoxCategory("Allergies", Icons.health_and_safety_rounded, Colors.red, userAllergies),
            _buildBigBoxCategory("Avoid Ingredients", Icons.block_flipped, Colors.orange, userDislikes),
            _buildBigBoxCategory("Dietary Goals", Icons.eco_rounded, Colors.green, userGoals),

            // If everything is empty
            if (userAllergies.isEmpty && userDislikes.isEmpty && userGoals.isEmpty)
              _buildEmptyPlaceholder(),

            const SizedBox(height: 40), 
          ],
        ),
      ),
    );
  }

  // 🚨 STUNNING NEW USER CARD
  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF008C5A), Color(0xFF07402E)], // Brand gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF008C5A).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : "?", 
                style: const TextStyle(color: Color(0xFF07402E), fontWeight: FontWeight.w900, fontSize: 28)),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text("$scanCount Scans", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          // Subtle, elegant edit button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: _openEditScreen,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
              ),
            ),
          )
        ],
      ),
    );
  }

  // 🚨 NEW SOFT GRADIENT BOX UI
  Widget _buildBigBoxCategory(String title, IconData icon, MaterialColor color, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // The "Middle Ground": Soft pastel gradient that looks extremely clean
        gradient: LinearGradient(
          colors: [color.shade50, color.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.shade200.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: color.shade800),
              ),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color.shade900, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white, // Crisp white background for the chip
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.shade100),
                boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Text(tag.toUpperCase(), style: TextStyle(color: color.shade800, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5)
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
            child: Icon(Icons.monitor_heart_outlined, size: 36, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          const Text("No preferences set", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text("Tap the edit button above to customize your health goals.", 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }
}