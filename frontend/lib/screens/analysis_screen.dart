import 'package:flutter/material.dart';

class AnalysisScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const AnalysisScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    // Safely extract the Mega-Payload
    final bool isSafe = resultData['health_match'] ?? false;
    final String healthStatus = resultData['health_status'] ?? 'Analysis Complete';
    final String productName = resultData['product_name'] ?? 'Unknown Product';
    final String parent_company = resultData['parent_company'] ?? 'Unknown Brand';
    
    // Scores
    final String nutriScore = resultData['nutri_score'] ?? '?';
    final int ethicsScore = resultData['ethics_score'] ?? 0;
    final String ethicsSummary = resultData['ethics_summary'] ?? '';
    
    // Flagged Ingredients Array
    final List<dynamic> flagged = resultData['flagged_ingredients'] is List 
        ? resultData['flagged_ingredients'] 
        : [];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Scan Results", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isSafe ? Colors.green.shade700 : Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. HEALTH STATUS BANNER ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isSafe ? Colors.green.shade700 : Colors.red.shade700,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Icon(isSafe ? Icons.check_circle : Icons.warning_rounded, color: Colors.white, size: 60),
                  const SizedBox(height: 8),
                  Text(
                    healthStatus.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 2. PRODUCT INFO ---
                  Text(productName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  Text(parent_company.toUpperCase(), style: TextStyle(fontSize: 14, color: Colors.grey.shade600, letterSpacing: 1.2)),
                  const SizedBox(height: 24),

                  // --- 3. THE SCORE CARDS (Nutri-Score & Ethics) ---
                  Row(
                    children: [
                      Expanded(
                        child: _ScoreCard(
                          title: "NUTRI-SCORE",
                          score: nutriScore,
                          color: nutriScore == 'A' || nutriScore == 'B' ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ScoreCard(
                          title: "ETHICS SCORE",
                          score: "$ethicsScore/10",
                          color: ethicsScore >= 7 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Ethics Summary Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueGrey.shade100),
                    ),
                    child: Text("🏢 $ethicsSummary", style: TextStyle(color: Colors.blueGrey.shade800)),
                  ),
                  const SizedBox(height: 24),

                  // --- 4. FLAGGED INGREDIENTS ---
                  if (!isSafe && flagged.isNotEmpty) ...[
                    const Text("⚠️ CONFLICTING INGREDIENTS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: flagged.map((ingredient) {
                        return Chip(
                          label: Text(ingredient.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.red.shade600,
                          deleteIconColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        );
                      }).toList(),
                    ),
                  ],
                  
                  if (isSafe)
                     Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                       child: const Row(
                         children: [
                           Icon(Icons.thumb_up, color: Colors.green),
                           SizedBox(width: 12),
                           Expanded(child: Text("This product perfectly matches your dietary profile!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                         ],
                       ),
                     )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Widget for the neat side-by-side Score Cards
class _ScoreCard extends StatelessWidget {
  final String title;
  final String score;
  final Color color;

  const _ScoreCard({required this.title, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text(score, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}