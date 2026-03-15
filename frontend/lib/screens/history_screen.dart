// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import '../services/api_service.dart'; 
// import 'analysis_screen.dart';

// class HistoryScreen extends StatefulWidget {
//   const HistoryScreen({super.key});

//   @override
//   State<HistoryScreen> createState() => _HistoryScreenState();
// }

// class _HistoryScreenState extends State<HistoryScreen> {
//   List<dynamic> _historyItems = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchHistory();
//   }

//   Future<void> _fetchHistory() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getString('user_id');

//       if (userId == null) return;

//       // 1. INSTANT LOAD: Check phone storage first
//       final cachedHistoryString = prefs.getString('history_$userId');
//       if (cachedHistoryString != null) {
//         setState(() {
//           _historyItems = jsonDecode(cachedHistoryString);
//           _isLoading = false; // Turn off spinner instantly!
//         });
//       }

//       // 2. BACKGROUND SYNC: Fetch fresh data from your database
//       final response = await http.get(
//         Uri.parse('${ApiService.baseUrl}/history/$userId'),
//       );

//       if (response.statusCode == 200) {
//         final freshData = jsonDecode(response.body)['history'];
        
//         // Save this fresh data to the phone for next time
//         await prefs.setString('history_$userId', jsonEncode(freshData));

//         // Update UI with any new server changes
//         if (mounted) {
//           setState(() {
//             _historyItems = freshData;
//             _isLoading = false;
//           });
//         }
//       }
//     } catch (e) {
//       print("Offline mode or Error: Using locally cached history data. Error: $e");
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: const Text("Scan History", 
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
//         ),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator(color: Color(0xFF008C5A)))
//           : _historyItems.isEmpty
//               ? _buildEmptyState()
//               : RefreshIndicator(
//                   onRefresh: _fetchHistory,
//                   child: ListView.builder(
//                     padding: const EdgeInsets.all(16),
//                     itemCount: _historyItems.length,
//                     itemBuilder: (context, index) {
//                       final item = _historyItems[index];
//                       return _buildHistoryCard(context, item); 
//                     },
//                   ),
//                 ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.history, size: 64, color: Colors.grey.shade300),
//           const SizedBox(height: 16),
//           const Text("No scans found yet!", style: TextStyle(color: Colors.grey)),
//         ],
//       ),
//     );
//   }

//   Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> item) {
//     // Determine color based on health status
//     Color statusColor = item['health_status'] == 'Safe' ? Colors.green : Colors.red;
//     if (item['health_status'] == 'Caution') statusColor = Colors.orange;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
//         ],
//       ),
//       child: ListTile(
//         // 🚨 INSTANT NAVIGATION LOGIC (NO API CALL!) 🚨
//         onTap: () {
//           // Extract the mega-payload that is now saved directly in the history database column
//           final fullResponse = item['full_response'];

//           if (fullResponse == null) {
//             // Safety fallback for items scanned before we added the new database column
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('This is an old scan! Please rescan the item to view full details.'),
//                 backgroundColor: Colors.orange,
//               ),
//             );
//             return;
//           }

//           // Instantly push to the analysis screen using the stored data!
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AnalysisScreen(resultData: fullResponse),
//             ),
//           );
//         },
//         contentPadding: const EdgeInsets.all(16),
//         leading: Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: statusColor.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(Icons.fastfood_outlined, color: statusColor),
//         ),
//         title: Text(
//           item['product_name'] ?? "Unknown Product",
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//         ),
//         subtitle: Text(item['scanned_at'] ?? ""),
//         trailing: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//           decoration: BoxDecoration(
//             color: statusColor,
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Text(
//             item['health_status'] ?? "Unknown",
//             style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart'; 
import 'analysis_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _historyItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) return;

      // 1. INSTANT LOAD: Check phone storage first
      final cachedHistoryString = prefs.getString('history_$userId');
      if (cachedHistoryString != null) {
        setState(() {
          _historyItems = jsonDecode(cachedHistoryString);
          _isLoading = false; 
        });
      }

      // 2. BACKGROUND SYNC: Fetch fresh data from database
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/history/$userId'),
      );

      if (response.statusCode == 200) {
        final freshData = jsonDecode(response.body)['history'];
        
        await prefs.setString('history_$userId', jsonEncode(freshData));

        if (mounted) {
          setState(() {
            _historyItems = freshData;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Offline mode or Error: Using locally cached history data. Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70, // Slightly taller for a premium feel
        title: const Text("Scan History", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 24)
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF008C5A)))
          : _historyItems.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: const Color(0xFF008C5A),
                  onRefresh: _fetchHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 40),
                    itemCount: _historyItems.length,
                    itemBuilder: (context, index) {
                      final item = _historyItems[index];
                      return _buildHistoryCard(context, item); 
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text("No scans found yet!", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text("Items you scan will appear here.", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> item) {
    // Dynamic styling based on AI Health Status
    Color statusColor;
    IconData statusIcon;
    
    String rawStatus = (item['health_status'] ?? "").toString().toLowerCase();
    
    if (rawStatus.contains('safe')) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
    } else if (rawStatus.contains('caution')) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_rounded;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            final fullResponse = item['full_response'];

            if (fullResponse == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('This is an old scan! Please rescan the item to view full details.', style: TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.orange.shade800,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AnalysisScreen(resultData: fullResponse)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 28),
                ),
                const SizedBox(width: 16),
                
                // Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['product_name'] ?? "Unknown Product",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['scanned_at'] ?? "",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge & Chevron
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item['health_status'] ?? "Unknown",
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}