import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
class ApiService {
  // 🚨 MASTER IP: Ensure this matches 'ipconfig getifaddr en0' on your Mac!
  // static const String baseUrl = 'http://127.0.0.1:8000';
  static const String baseUrl = "http://10.44.177.27:8000"; // Your Mac's Wi-Fi IP

  // ==========================================
  // 1. SCANNER API
  // ==========================================
  static Future<Map<String, dynamic>> scanProduct(String barcode, String userId) async {
    try {
      final url = '$baseUrl/scan/$barcode?user_id=$userId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }

  // ==========================================
  // 2. AUTHENTICATION API
  // ==========================================
  
  static Future<String> signUp(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'), 
        headers: {'Content-Type': 'application/json'},
        // 🚨 ADDED 'name' HERE SO FASTAPI DOESN'T CRASH!
        body: jsonEncode({
          'name': name, 
          'email': email, 
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user_id']; 
      } else {
        throw Exception('Failed to sign up: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error during sign up: $e');
    }
  }

  static Future<String> logIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user_id']; 
      } else {
        throw Exception('Failed to log in: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error during log in: $e');
    }
  }

  // ==========================================
  // 3. PROFILE API
  // ==========================================

    static Future<void> updatePreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(preferences),
      ).timeout(const Duration(seconds: 10)); // 👈 Add this!

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
    
  }
  // Save Profile Data
  static Future<void> cacheProfileData(String userId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_$userId', jsonEncode(data));
  }

  // Get Profile Data
  static Future<Map<String, dynamic>?> getCachedProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('profile_$userId');
    if (dataString != null) return jsonDecode(dataString);
    return null;
  }

  // Save History Data
  static Future<void> cacheHistoryData(String userId, List<dynamic> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('history_$userId', jsonEncode(history));
  }

  // Get History Data
  static Future<List<dynamic>?> getCachedHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('history_$userId');
    if (dataString != null) return jsonDecode(dataString);
    return null;
  }
}