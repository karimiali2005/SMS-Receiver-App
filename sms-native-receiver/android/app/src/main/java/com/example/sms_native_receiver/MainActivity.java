package com.example.sms_native_receiver;

import android.content.Context; // ✅ ADD THIS LINE
import android.content.Intent;
import android.os.Build;
import android.os.PowerManager;
import android.provider.Settings;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.database.Cursor;
import android.net.Uri;
import android.util.Log;
import java.time.Instant;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL_SMS = "com.example.sms_native_receiver/sms";
    private static final String CHANNEL_BATTERY = "battery_optimization";

    @Override
    protected void onStart() {
        super.onStart();
        Intent serviceIntent = new Intent(this, SmsListenerService.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent);
        } else {
            startService(serviceIntent);
        }
    }

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // SMS Channel
        MethodChannel smsChannel = new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                CHANNEL_SMS);
        SmsReceiver.channel = smsChannel;

        SmsReceiver.channel.setMethodCallHandler((call, result) -> {
            if (call.method.equals("readInboxAfter")) {
                String lastRead = call.argument("lastReadDate");
                readInboxSmsAfter(this, lastRead, SmsReceiver.channel);
                result.success(null);
            }
        });

        // Battery Optimization Channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_BATTERY)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("openBatterySettings")) {
                        String packageName = getPackageName();
                        PowerManager pm = (PowerManager) getSystemService(POWER_SERVICE);
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                                Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                                intent.setData(android.net.Uri.parse("package:" + packageName));
                                startActivity(intent);
                            }
                        }
                        result.success(null);
                    }
                });
    }

    public static void readInboxSmsAfter(Context context, String lastReadDateIso, MethodChannel flutterChannel) {
        try {
            Log.d("SMS_READ", "🔁 Scanning inbox after: " + lastReadDateIso);

            Uri uri = Uri.parse("content://sms/inbox");
            long lastReadMillis = Instant.parse(lastReadDateIso).toEpochMilli();

            Cursor cursor = context.getContentResolver().query(
                    uri,
                    null,
                    "date > ?",
                    new String[] { String.valueOf(lastReadMillis) },
                    "date ASC");

            int count = 0; // ✅ new counter for logging
            if (cursor != null && cursor.moveToFirst()) {
                do {
                    count++;
                    String address = cursor.getString(cursor.getColumnIndexOrThrow("address"));
                    String body = cursor.getString(cursor.getColumnIndexOrThrow("body"));
                    long timestamp = cursor.getLong(cursor.getColumnIndexOrThrow("date"));

                    String isoDate = Instant.ofEpochMilli(timestamp).toString();
                    String combined = address + ":" + body + ":" + isoDate;

                    flutterChannel.invokeMethod("smsManual", combined);
                } while (cursor.moveToNext());

                cursor.close();
                Log.d("SMS_READ", "📩 Fetched " + count + " new SMS from inbox.");
            }
        } catch (Exception e) {
            Log.e("SMS_READ", "Failed to read SMS: " + e.getMessage());
        }
    }

}
