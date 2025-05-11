import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _apiController = TextEditingController();
  final TextEditingController _numberInputController = TextEditingController();
  List<String> allowedNumbers = [];
  bool hasExistingConfig = false;

  @override
  void initState() {
    super.initState();
    _loadPrevious();
  }

  Future<void> _loadPrevious() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString("apiBaseUrl");
    final savedNumbers = prefs.getStringList("allowedSenders");

    _apiController.text = savedUrl ?? "http://192.168.1.100:5049";
    allowedNumbers =
        savedNumbers ?? ["+4915123456789", "+491766543210", "+491601234567"];

    hasExistingConfig = savedUrl != null || savedNumbers != null;
    setState(() {});
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("apiBaseUrl", _apiController.text.trim());
      await prefs.setStringList("allowedSenders", allowedNumbers);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _addNumber() {
    final newNumber = _numberInputController.text.trim();
    if (newNumber.isNotEmpty && !allowedNumbers.contains(newNumber)) {
      setState(() {
        allowedNumbers.add(newNumber);
        _numberInputController.clear();
      });
    }
  }

  void _removeNumber(String number) {
    setState(() {
      allowedNumbers.remove(number);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuration")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (hasExistingConfig)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    "✔ Configuration loaded. You can edit it below.",
                    style: TextStyle(color: Colors.green[700], fontSize: 16),
                  ),
                ),
              TextFormField(
                controller: _apiController,
                decoration: const InputDecoration(labelText: "API Base URL"),
                validator:
                    (v) => v == null || v.isEmpty ? "Enter API URL" : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _numberInputController,
                      decoration: const InputDecoration(
                        labelText: "Add Phone Number",
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addNumber,
                    child: const Text("Add"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: allowedNumbers.length,
                  itemBuilder: (context, index) {
                    final number = allowedNumbers[index];
                    return ListTile(
                      title: Text(number),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeNumber(number),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveConfig,
                child: const Text("Save & Continue"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
