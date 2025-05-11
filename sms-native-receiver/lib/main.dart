import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'models/sms_message.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'services/sms_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'screens/config_screen.dart';
import 'dart:async';
import 'dart:convert'; // ✅ ADD THIS

// Just testing Git change

void main() => runApp(const MyRootApp());

class MyRootApp extends StatelessWidget {
  const MyRootApp({super.key});



  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey("apiBaseUrl")) {
      await prefs.setString("apiBaseUrl", "http://192.168.1.100:5049");
    }
    if (!prefs.containsKey("allowedSenders")) {
      await prefs.setStringList("allowedSenders", [
        "+4915123456789",
        "+491766543210",
        "+491601234567",
      ]);
    }

    return prefs.getBool("isLoggedIn") ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return MaterialApp(
          title: 'SMS Native Receiver',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: snapshot.data! ? const MyApp() : const LoginScreen(),
        );
      },
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const platform = MethodChannel("com.example.sms_native_receiver/sms");
  final dbService = DatabaseService();
  String _message = "Waiting for SMS...";

  static const Duration syncInterval = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await saveDeviceIdOnce();
    await _askSmsPermission();
    _listenToNativeSms();
    await requestIgnoreBatteryOptimizations();
    await _handleLastReadDate();
    await _syncNativeInbox();
    _startInternetSyncListener();
    _startSyncTimer();
  }

  Future<void> saveDeviceIdOnce() async {
    final info = DeviceInfoPlugin();
    final androidInfo = await info.androidInfo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("deviceId", androidInfo.id);
  }

  Future<void> _askSmsPermission() async {
    if (await Permission.sms.isDenied) {
      await Permission.sms.request();
    }
  }

  void _listenToNativeSms() {
    platform.setMethodCallHandler((call) async {
      print(
        "📥 Received native SMS callback: \${call.method} - \${call.arguments}",
      );

      // inside your method
      if (call.method == "smsReceived" || call.method == "smsManual") {
        final fullText = call.arguments ?? "";

        try {
          final Map<String, dynamic> data = jsonDecode(fullText);

          final sms = SmsMessageModel(
            sender: data['sender'] ?? '',
            body: data['body'] ?? '',
            timestamp: data['timestamp'] ?? '',
            isManual: call.method == "smsManual",
          );

          final exists = await dbService.exists(sms);
          if (!exists) {
            await dbService.insertMessage(sms);
            setState(() => _message = "Synced from ${sms.sender}: ${sms.body}");

            final prefs = await SharedPreferences.getInstance();
            final currentTimestamp = DateTime.tryParse(sms.timestamp);
            final lastReadRaw = prefs.getString("lastReadDate");
            final lastRead =
                lastReadRaw != null ? DateTime.tryParse(lastReadRaw) : null;

            if (currentTimestamp != null &&
                (lastRead == null || currentTimestamp.isAfter(lastRead))) {
              await prefs.setString("lastReadDate", sms.timestamp);
              print("🆕 Updated local lastReadDate: ${sms.timestamp}");
            }
          }
        } catch (e) {
          print("❌ Failed to decode SMS JSON: $e");
        }
      }
    });
  }

  Future<void> requestIgnoreBatteryOptimizations() async {
    const platform = MethodChannel("battery_optimization");
    try {
      await platform.invokeMethod("openBatterySettings");
    } on PlatformException catch (e) {
      print("⚠️ Battery optimization: \${e.message}");
    }
  }

  Future<void> _handleLastReadDate() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey("lastReadDate")) {
      final formatted = DateTime.now().toUtc().toIso8601String();
      await prefs.setString("lastReadDate", formatted);
      print("🆕 First run. Saving current time as LastReadDate...");
    } else {
      print("🔁 LastReadDate found: ${prefs.getString("lastReadDate")}");
    }
  }

  Future<void> _syncNativeInbox() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReadDate = prefs.getString("lastReadDate");
    if (lastReadDate != null) {
      await platform.invokeMethod("readInboxAfter", {
        "lastReadDate": lastReadDate,
      });
    }
  }

  void _startInternetSyncListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        print("🌐 Internet available, syncing...");
        _sendAndDeleteSyncedMessages();
        _updateLastReadDateOnServer();
      } else {
        print("📴 No internet, waiting...");
      }
    });
  }

  void _startSyncTimer() {
    Timer.periodic(syncInterval, (timer) async {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        print("⏱️ Periodic Sync Triggered...");
        await _sendAndDeleteSyncedMessages();
        await _updateLastReadDateOnServer();
      } else {
        print("🚫 No internet during scheduled sync.");
      }
    });
  }

  // ✅ Modified to avoid duplicates
  Future<void> _sendAndDeleteSyncedMessages() async {
    if (_isSyncing) {
      print("⏳ Already syncing. Skipping this call.");
      return;
    }
    _isSyncing = true;

    final messages = await dbService.getMessages();
    print("📨 Found \${messages.length} unsynced messages in local DB");

    List<String> failedMessages = [];

    for (final msg in messages) {
      final result = await saveSmsToServer(
        msg.sender,
        msg.body,
        msg.timestamp,
        msg.isManual,
      );

      if (result["success"] == true) {
        await dbService.deleteMessage(msg);
        print("✅ SMS synced: \${msg.sender}");
      } else {
        final error = result["error"] ?? "Unknown error";
        final summary = "Sender: \${msg.sender}\nError: \$error";
        failedMessages.add(summary);
        print("❌ Failed to send SMS:\n\$summary");
      }
    }

    _isSyncing = false;

    if (failedMessages.isNotEmpty && mounted) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("❌ Errors While Sending SMS"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      failedMessages
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text("• \$e"),
                            ),
                          )
                          .toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("OK"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ All SMS messages sent successfully.")),
      );
    }
  }

  // ✅ Add a private flag in your state class
  bool _isSyncing = false;

  Future<void> _updateLastReadDateOnServer() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReadDate = prefs.getString("lastReadDate");
    final deviceId = prefs.getString("deviceId") ?? "unknown-device";
    if (lastReadDate != null) {
      await updateLastReadDateToServer(deviceId, lastReadDate);
      print("✅ Sent LastReadDate to server: \$lastReadDate");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text("SMS Manager")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_message, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final messages = await dbService.getMessages();
                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text("Stored SMS"),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                messages
                                    .map(
                                      (msg) =>
                                          Text('${msg.sender}: ${msg.body}\n'),
                                    )
                                    .toList(),
                          ),
                        ),
                      ),
                );
              },
              child: const Text("Show Stored Messages"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _sendAndDeleteSyncedMessages();
                await _updateLastReadDateOnServer();
              },
              child: const Text("Retry Sending Unsynced SMS"),
            ),
            ElevatedButton(
              onPressed: () async {
                await AuthService().logout();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text("Logout"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConfigScreen()),
                );
              },
              child: const Text("Config Settings"),
            ),
          ],
        ),
      ),
    );
  }
}
