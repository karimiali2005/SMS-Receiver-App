import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/api_config.dart';

class ApiClient {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken");
    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  Future<http.Response> post(String path, dynamic body) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse("$baseUrl$path"),
      headers: headers,
      body: body,
    );

    // 🔄 If token expired, refresh and retry once
    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        final newHeaders = await _getHeaders();
        return await http.post(
          Uri.parse("$baseUrl$path"),
          headers: newHeaders,
          body: body,
        );
      }
    }

    return response;
  }

  Future<http.Response> get(String path) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse("$baseUrl$path"),
      headers: headers,
    );

    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        final newHeaders = await _getHeaders();
        return await http.get(Uri.parse("$baseUrl$path"), headers: newHeaders);
      }
    }

    return response;
  }

  // 🔁 Auto-refresh access token using refresh token
  Future<bool> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString("refreshToken");
    if (refreshToken == null) return false;

    final baseUrl = await ApiConfig.getBaseUrl();
    final response = await http.post(
      Uri.parse("$baseUrl/auth/refresh"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refreshToken": refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setString("accessToken", data["token"]);
      await prefs.setString("refreshToken", data["refreshToken"]);
      print("🔁 Token refreshed successfully.");
      return true;
    } else {
      await prefs.remove("accessToken");
      await prefs.remove("refreshToken");
      print("❌ Token refresh failed. Logging out.");
      return false;
    }
  }
}
