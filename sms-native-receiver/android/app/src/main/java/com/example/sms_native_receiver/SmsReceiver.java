package com.example.sms_native_receiver;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.telephony.SmsMessage;
import android.util.Log;
import android.widget.Toast;
import android.provider.Telephony;
import android.os.Bundle;

import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import org.json.JSONObject;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

import io.flutter.plugin.common.MethodChannel;

public class SmsReceiver extends BroadcastReceiver {
    public static MethodChannel channel;

    @Override
    public void onReceive(Context context, Intent intent) {
        // ✅ Get all message parts
        SmsMessage[] messages = Telephony.Sms.Intents.getMessagesFromIntent(intent);
        StringBuilder fullMessage = new StringBuilder();
        String sender = null;

        for (SmsMessage sms : messages) {
            fullMessage.append(sms.getMessageBody());
            if (sender == null) {
                sender = sms.getOriginatingAddress();
            }
        }

        if (sender != null) {
            String body = fullMessage.toString();
            String timestamp = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault())
                    .format(new Date());

            // ✅ Save to native SQLite
            SmsDatabaseHelper dbHelper = new SmsDatabaseHelper(context);
            dbHelper.insertMessage(sender, body, timestamp, 0); // 0 = automatic
            Log.d("SMS_RECEIVER", "✅ Auto SMS saved from: " + sender);

            // ✅ Toast
            Toast.makeText(context, "SMS from: " + sender, Toast.LENGTH_SHORT).show();

            // ✅ Notify Flutter with proper JSON
            if (SmsReceiver.channel != null) {
                try {
                    JSONObject json = new JSONObject();
                    json.put("sender", sender);
                    json.put("body", body);
                    json.put("timestamp", timestamp);
                    SmsReceiver.channel.invokeMethod("smsReceived", json.toString());
                    Log.d("SMS_RECEIVER", "📤 Notified Flutter with SMS");
                } catch (Exception e) {
                    Log.e("SMS_RECEIVER", "❌ JSON error: " + e.getMessage());
                }
            }

            // ✅ Show Notification
            showSmsNotification(context, sender, body);
        }
    }

    private void showSmsNotification(Context context, String sender, String body) {
        String CHANNEL_ID = "sms_new_channel";
        int NOTIF_ID = 100;

        // Android 8+ requires a channel
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "New SMS Alerts",
                    NotificationManager.IMPORTANCE_HIGH);
            NotificationManager manager = context.getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }

        // Tap opens app
        Intent openAppIntent = new Intent(context, MainActivity.class);
        openAppIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        PendingIntent pendingIntent = PendingIntent.getActivity(
                context,
                0,
                openAppIntent,
                PendingIntent.FLAG_IMMUTABLE);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("New SMS from: " + sender)
                .setContentText(body)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
                .setBadgeIconType(NotificationCompat.BADGE_ICON_SMALL)
                .setNumber(1)
                .setOngoing(true);

        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(context);
        notificationManager.notify(NOTIF_ID, builder.build());
    }
}
