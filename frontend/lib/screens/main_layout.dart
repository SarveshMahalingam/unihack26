import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'analysis_screen.dart'; 
import '../widgets/fun_fact_loading.dart'; // 🚨 1. Added the Fun Fact Dialog import!

class MainLayout extends StatefulWidget {
  final String userId; 

  const MainLayout({super.key, required this.userId}); 

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 1; // Default to Scanner (middle)

  List<Widget> get _screens => [
    const HistoryScreen(), 
    const ScannerTab(), 
    ProfileScreen(userId: widget.userId), 
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
  bool _isAwaitingScan = false; 

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
        MobileScanner(
          controller: _cameraController,
          onDetect: (capture) async {
            if (!_isAwaitingScan) return;

            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
              setState(() => _isAwaitingScan = false); 
              
              final String barcode = barcodes.first.rawValue!;
              print("Manually captured barcode: $barcode");
              
              ScaffoldMessenger.of(context).hideCurrentSnackBar(); 

              // 🚨 2. POP UP THE FUN FACT DIALOG
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const FunFactLoadingDialog(),
              );

              try {
                final prefs = await SharedPreferences.getInstance();
                final userId = prefs.getString('user_id');

                if (userId == null) {
                  throw Exception("User ID not found. Please log in again.");
                }

                // 3. Hit the backend
                final resultData = await ApiService.scanProduct(barcode, userId);

                // 🚨 4. SAFELY close the dialog using rootNavigator
                if (mounted) Navigator.of(context, rootNavigator: true).pop();

                // 5. Navigate to results
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnalysisScreen(resultData: resultData),
                    ),
                  );
                }
              } catch (e) {
                // 🚨 6. SAFELY close the dialog on error
                if (mounted) Navigator.of(context, rootNavigator: true).pop();

                // 🚨 7. Show the friendly "Oops" message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Oops! The scan timed out or the product wasn\'t found. Please try scanning again! 🔄'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              }
            }
          },
        ),

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
                      color: Colors.black, 
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

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