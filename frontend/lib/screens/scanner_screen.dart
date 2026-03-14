import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';

class ScannerScreen extends StatefulWidget {
  final String userId; // Pass the user's ID here after they log in

  const ScannerScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isProcessing = false;

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return; // Prevent multiple scans at once
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() => _isProcessing = true);
      
      final String barcode = barcodes.first.rawValue!;
      print("Scanned barcode: $barcode"); // Check your debug console!

      try {
        // Send it to your FastAPI backend
        final result = await ApiService.scanProduct(barcode, widget.userId);
        
        // Print the Gemini response to the console for now
        print("Gemini Analysis: $result");

        // TODO: Navigate to a Results Screen to show the 'status', 'alerts', and 'summary'
        
      } catch (e) {
        print("Error analyzing product: $e");
      } finally {
        // Wait a few seconds before allowing another scan
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan a Product')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleBarcode,
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(), // Show loading spinner while Gemini thinks
            ),
        ],
      ),
    );
  }
}