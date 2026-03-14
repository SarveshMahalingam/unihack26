import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // TODO: Fetch this list from your FastAPI backend (e.g., GET /history/{user_id})
  // For the hackathon mockup, we are using the exact data from your screenshot.
  final List<Map<String, dynamic>> scanHistory = [
    {
      "name": "Classic Chocolate Bar",
      "brand": "ChocoCorp",
      "ethics_score": 42,
      "date": "Today, 10:42 AM",
      "health_status": "danger", // danger, safe, warning
    },
    {
      "name": "Organic Oats",
      "brand": "Nature's Path",
      "ethics_score": 85,
      "date": "Yesterday, 3:15 PM",
      "health_status": "safe",
    },
    {
      "name": "Generic Peanut Butter",
      "brand": "Store Brand",
      "ethics_score": 55,
      "date": "Mar 10, 11:20 AM",
      "health_status": "warning",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Header & Filter Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recent Scans", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  IconButton(
                    icon: const Icon(Icons.filter_alt_outlined, color: Colors.black87),
                    onPressed: () {
                      // TODO: Implement filter bottom sheet
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Search past scans...",
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // The History List
              Expanded(
                child: ListView.builder(
                  itemCount: scanHistory.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryCard(scanHistory[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final int score = item['ethics_score'];
    final String healthStatus = item['health_status'];

    // Determine Ethics Score Colors
    Color scoreBgColor;
    Color scoreTextColor;
    if (score >= 80) {
      scoreBgColor = const Color(0xFFEAF5EB); // Light Green
      scoreTextColor = Colors.green;
    } else if (score >= 50) {
      scoreBgColor = const Color(0xFFFFF9E6); // Light Orange
      scoreTextColor = Colors.orange;
    } else {
      scoreBgColor = const Color(0xFFFEECEE); // Light Red
      scoreTextColor = Colors.red;
    }

    // Determine Health Icon
    IconData healthIcon;
    Color healthIconColor;
    if (healthStatus == 'safe') {
      healthIcon = Icons.check_circle_outline;
      healthIconColor = Colors.green;
    } else if (healthStatus == 'warning') {
      healthIcon = Icons.shield_outlined;
      healthIconColor = Colors.orange;
    } else {
      healthIcon = Icons.shield_outlined; // Danger shield
      healthIconColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // Grey Image Placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(item['brand'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Ethics Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: scoreBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("${item['ethics_score']} Ethics", style: TextStyle(color: scoreTextColor, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                    const SizedBox(width: 12),
                    // Date
                    Text(item['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          
          // Health Icon Indicator
          Icon(healthIcon, color: healthIconColor, size: 28),
        ],
      ),
    );
  }
}