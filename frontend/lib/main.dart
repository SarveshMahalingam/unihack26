import 'dart:ui';
import 'package:app/loginscreen.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EthicalScannerApp());
}

class EthicalScannerApp extends StatelessWidget {
  const EthicalScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ethical Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,scaffoldBackgroundColor: Colors.white, // Cream background
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF545333),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// ==========================================
// 1. MAIN SCANNER SCREEN
// ==========================================
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool isScanning = true;
  bool hasPermission = false;
  final MobileScannerController controller = MobileScannerController();

  // --- CUSTOM PALETTE ---
  final Color cream = const Color(0xffffffff);
  final Color coral = const Color(0xfff57758);
  final Color skyBlue = const Color(0xff40bced);
  final Color deepOlive = const Color(0xFF545333);

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() => hasPermission = status.isGranted);
  }

  // --- CUSTOM SLIDE TRANSITION FOR PROFILE ---
  void _openProfileScreen() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0); // Slides in from the left
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  // --- IKEA STYLE HELP BOTTOM SHEET ---
  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("How to scan", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: coral)),
                  IconButton(
                    icon: Icon(Icons.close, color: coral),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildHelpRow(Icons.qr_code_scanner, "Scan Barcodes", "Align the barcode within the central frame."),
              const SizedBox(height: 20),
              _buildHelpRow(Icons.health_and_safety, "Personalized Audit", "We cross-reference ingredients with your profile."),
              const SizedBox(height: 20),
              _buildHelpRow(Icons.eco, "Ethical Score", "Instantly receive health and sustainability ratings."),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 30, color: skyBlue),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: coral)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 14, color: deepOlive)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco_rounded, size: 80, color: coral),
              const SizedBox(height: 20),
              Text(
                "Camera access required", 
                style: TextStyle(color: coral, fontSize: 18, fontWeight: FontWeight.w500)
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: coral, 
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _requestCameraPermission,
                child: const Text("Allow Camera", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // TOP LEFT PROFILE BUTTON
        leading: IconButton(
          icon: const Icon(Icons.person, size: 32),
          color: coral,
          onPressed: _openProfileScreen,
        ),
        title: Text(
          'Ethical Scanner', 
          style: TextStyle(
            letterSpacing: 1.5, 
            fontWeight: FontWeight.w900, 
            fontSize: 30,
            color: coral,
          )
        ),
        centerTitle: true,
        // TOP RIGHT HELP BUTTON
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, size: 28),
            color: coral,
            onPressed: _showHelpSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 1. Raw Camera Feed
          MobileScanner(
            controller: controller,
            onDetect: (BarcodeCapture capture) {
              if (!isScanning) return;
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null) {
                  setState(() => isScanning = false);
                  
                  // Fun Success Message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white70),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Captured: ${barcode.rawValue}',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                            )
                          ),
                        ],
                      ),
                      backgroundColor: skyBlue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(20),
                      elevation: 10,
                    ),
                  );

                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) setState(() => isScanning = true);
                  });
                  break;
                }
              }
            },
          ),
          
          // 2. Muted black Overlay Cutout
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black12.withAlpha(210), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 350, // IKEA Landscape width
                      height: 350, // IKEA Landscape height
                      decoration: BoxDecoration(
                        color: Colors.black, // Punches the hole
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Thick Rounded Border
          Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: isScanning ? coral : skyBlue,
                    width: 13,
                  ),
                ),
              ),
            ),
          ),

          // 4. Frosted White Glass Panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xffffffff).withAlpha(200),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white70.withAlpha(150), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isScanning ? Icons.qr_code_scanner : Icons.hourglass_empty, 
                          color: coral
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isScanning ? "Align barcode in frame" : "Processing...",
                          style: TextStyle(
                            color: coral, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 2. PROFILE & INFO EDITING PAGE
// ==========================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _allergiesController = TextEditingController();
  final _avoidController = TextEditingController();
  
  final Color white = Colors.white70;
  final Color coral = const Color(0xfff57758);
  final Color skyBlue = const Color(0xff40bced);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _allergiesController.text = prefs.getString('allergies') ?? '';
      _avoidController.text = prefs.getString('avoid_ingredients') ?? '';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('allergies', _allergiesController.text);
    await prefs.setString('avoid_ingredients', _avoidController.text);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Profile Updated!'), backgroundColor: skyBlue),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: coral),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Your Profile', style: TextStyle(color: coral, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.person_pin, size: 80, color: skyBlue),
            const SizedBox(height: 30),
            TextField(
              controller: _allergiesController,
              decoration: InputDecoration(
                labelText: 'Allergies (e.g., peanuts)',
                labelStyle: TextStyle(color: coral),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: coral, width: 3), borderRadius: BorderRadius.circular(15)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: skyBlue, width: 2), borderRadius: BorderRadius.circular(15)),
                prefixIcon: Icon(Icons.warning_amber, color: coral),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _avoidController,
              decoration: InputDecoration(
                labelText: 'Ingredients to Avoid (e.g., pork)',
                labelStyle: TextStyle(color: coral),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: coral, width: 3), borderRadius: BorderRadius.circular(15)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: skyBlue, width: 2), borderRadius: BorderRadius.circular(15)),
                prefixIcon: Icon(Icons.do_not_disturb_alt, color: coral),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: _savePreferences,
              child: const Text('Save Dietary Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}