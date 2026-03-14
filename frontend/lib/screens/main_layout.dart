import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'analysis_screen.dart'; // Make sure this matches your file name!

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 1; // Default to Scanner (middle)

  // --- Screens ---
  final List<Widget> _screens = [
    const HistoryScreen(), // History
    const ScannerTab(), // Scanner
    const ProfileScreen(), // Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF008C5A),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

// ==========================================
// THE MANUAL SCANNER TAB
// ==========================================
class ScannerTab extends StatefulWidget {
  const ScannerTab({super.key});

  @override
  State<ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<ScannerTab> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isAwaitingScan = false; // The lock that prevents auto-scanning

  void _triggerScan() {
    setState(() => _isAwaitingScan = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Scanning active... point at barcode!"), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The Camera Feed
        MobileScanner(
          controller: _cameraController,
          onDetect: (capture) async {
            // ONLY process if the user clicked the button
            if (!_isAwaitingScan) return;

            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
              setState(() => _isAwaitingScan = false); // Lock it back up
              
              final String barcode = barcodes.first.rawValue!;
              print("Manually captured barcode: $barcode");
              
              // Show a loading snackbar so the user knows it's thinking
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Analyzing ingredients with AI..."), duration: Duration(seconds: 4)),
              );

              try {
                // 1. Get the logged-in User ID from phone storage
                final prefs = await SharedPreferences.getInstance();
                final userId = prefs.getString('user_id');

                if (userId == null) {
                  throw Exception("User ID not found. Please log in again.");
                }

                // 2. Hit your FastAPI backend!
                final resultData = await ApiService.scanProduct(barcode, userId);

                // 3. Navigate to the Analysis Screen with the Gemini data
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide loading
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnalysisScreen(resultData: resultData),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            }
          },
        ),

        // 2. The Dark Cutout Overlay
        ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.srcOut),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.black, // Punches the hole
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. The Big "SCAN" Button
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008C5A),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _triggerScan,
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text("Tap to Scan", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        )
      ],
    );
  }
}