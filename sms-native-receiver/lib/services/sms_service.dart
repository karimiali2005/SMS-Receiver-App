import 'dart:convert';
import 'api_client.dart';
import '../models/sms_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>> saveSmsToServer(
  String sender,
  String body,
  String timestamp,
  bool isManual,
) async {
  final prefs = await SharedPreferences.getInstance();
  final allowedNumbers = prefs.getString("allowedNumber");

  String normalize(String s) => s.replaceAll(RegExp(r'[\s+]'), '');

  if (allowedNumbers != null && allowedNumbers.isNotEmpty) {
    final List<String> list =
        allowedNumbers
            .split(',')
            .map((n) => normalize(n.trim()))
            .where((n) => n.isNotEmpty)
            .toList();

    final normalizedSender = normalize(sender);
    final isAllowed = list.any((n) => normalizedSender.contains(n));

    if (!isAllowed) {
      final msg = "❌ Blocked SMS from $sender - not in allowed list.";
      print(msg);
      return {"success": false, "error": msg};
    }
  }

  try {
    final api = ApiClient();
    final response = await api.post(
      "/api/sms/save",
      jsonEncode({
        "sender": sender,
        "body": body,
        "timestamp": timestamp,
        "isManual": isManual,
      }),
    );

    if (response.statusCode == 200) {
      print("✅ SMS sent successfully to server");
      return {"success": true};
    } else {
      print("❌ Server error: ${response.statusCode}");
      return {
        "success": false,
        "error": "❌ Server error: ${response.statusCode} ${response.body}",
      };
    }
  } catch (e) {
    final msg = "❌ Network/Parsing error: $e";
    print(msg);
    return {"success": false, "error": msg};
  }
}

Future<void> updateLastReadDateToServer(
  String deviceId,
  String timestamp,
) async {
  final api = ApiClient();
  final response = await api.post(
    "/api/device/update",
    jsonEncode({"deviceId": deviceId, "lastReadDate": timestamp}),
  );
  print("📅 LastReadDate update status: ${response.statusCode}");
}

Future<String?> fetchLastReadDate(String deviceId) async {
  final api = ApiClient();
  final response = await api.get("/api/device/$deviceId");
  if (response.statusCode == 200) {
    print("📥 Server lastReadDate: ${response.body}");
    return response.body.replaceAll('"', '');
  }
  return null;
}
