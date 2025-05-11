import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("apiBaseUrl") ??
        "http://192.168.1.100:5049"; // fallback
  }
}
