import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // IMPORTANT IP NOTE: 
  // - If using iOS Simulator: Use 'http://127.0.0.1:8000'
  // - If using Android Emulator: Use 'http://10.0.2.2:8000'
  // - If using a physical phone: Use your Mac's local WiFi IP
  static const String baseUrl = 'http://10.44.177.27:8000'; // Your working Hotspot IP

  // ==========================================
  // 1. SCANNER API
  // ==========================================
  static Future<Map<String, dynamic>> scanProduct(String barcode, String userId) async {
    try {
      final url = '$baseUrl/scan/$barcode?user_id=$userId';
      print("🚨 ATTEMPTING TO HIT URL: $url");
      
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
  
  // Sign Up
  static Future<String> signUp(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'), // Assuming this is your FastAPI create user route
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email, 
          'password': password,
          // If your FastAPI schema requires 'name', you might need to add it to your UserCreate schema!
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id']; // Returns the UUID from your database
      } else {
        throw Exception('Failed to sign up: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error during sign up: $e');
    }
  }

  // Log In
  static Future<String> logIn(String email, String password) async {
    try {
      // NOTE: Update this URL if your FastAPI login route is named differently
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

  // Update Preferences (Allergies, Dislikes, Diets)
  static Future<void> updatePreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(preferences),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update preferences: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error updating profile: $e');
    }
  }
}