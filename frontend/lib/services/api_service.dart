import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // IMPORTANT IP NOTE: 
  // - If using iOS Simulator: Use 'http://127.0.0.1:8000'
  // - If using Android Emulator: Use 'http://10.0.2.2:8000'
  // - If using a physical phone: Use your Mac's local WiFi IP (e.g., 'http://192.168.1.X:8000')
  static const String baseUrl = 'http://10.44.177.27:8000';

  static Future<Map<String, dynamic>> scanProduct(String barcode, String userId) async {
    try {
      final url = '$baseUrl/scan/$barcode?user_id=$userId';
      print("🚨 ATTEMPTING TO HIT URL: $url");
      
      final response = await http.get(
        Uri.parse('$baseUrl/scan/$barcode?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }
}