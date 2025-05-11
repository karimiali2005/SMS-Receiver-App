import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/api_config.dart';

class AuthService {
  Future<String?> login(String username, String password) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("accessToken", data["token"]);
        await prefs.setString("refreshToken", data["refreshToken"]);
        await prefs.setBool("isLoggedIn", true);
        return null; // ✅ success
      } else if (response.statusCode == 401) {
        return "❌ Invalid username or password";
      } else {
        return "❌ Login failed: ${response.statusCode}";
      }
    } catch (e) {
      return "🚫 Network error: ${e.toString()}";
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("accessToken");
    await prefs.remove("refreshToken");
    await prefs.remove("isLoggedIn");
    print("👋 Logged out");
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("accessToken");
  }
}
