class SmsMessageModel {
  final String sender;
  final String body;
  final String timestamp;
  final bool isManual; // ✅ Add this

  SmsMessageModel({
    required this.sender,
    required this.body,
    required this.timestamp,
    this.isManual = false, // ✅ Default is false
  });

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'body': body,
      'timestamp': timestamp,
      'isManual': isManual ? 1 : 0, // ✅ Save as 0/1
    };
  }

  factory SmsMessageModel.fromMap(Map<String, dynamic> map) {
    return SmsMessageModel(
      sender: map['sender'],
      body: map['body'],
      timestamp: map['timestamp'],
      isManual: map['isManual'] == 1, // ✅ Read from int
    );
  }
}
