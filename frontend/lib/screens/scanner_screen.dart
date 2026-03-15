import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import 'analysis_screen.dart'; 
import '../widgets/fun_fact_loading.dart'; 

class ScannerScreen extends StatefulWidget {
  final String userId; 

  const ScannerScreen({super.key, required this.userId});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isProcessing = false;

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return; 
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() => _isProcessing = true);
      
      final String barcode = barcodes.first.rawValue!;
      print("Scanned barcode: $barcode");

      // Pop up the Fun Fact Loading Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const FunFactLoadingDialog(),
      );

      try {
        final result = await ApiService.scanProduct(barcode, widget.userId);
        
        // 🚨 SAFELY close the dialog using rootNavigator
        if (mounted) Navigator.of(context, rootNavigator: true).pop();

        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnalysisScreen(resultData: result),
            ),
          );
        }
      } catch (e) {
        // 🚨 SAFELY close the dialog on error
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        
        // Friendly error message
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
      } finally {
        // Wait 2 seconds before unlocking the camera to prevent spamming
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scan a Product', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: MobileScanner(
        onDetect: _handleBarcode,
      ),
    );
  }
}