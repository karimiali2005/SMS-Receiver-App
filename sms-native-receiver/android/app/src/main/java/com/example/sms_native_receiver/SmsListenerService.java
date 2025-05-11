package com.example.sms_native_receiver;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;

import androidx.core.app.NotificationCompat;

public class SmsListenerService extends Service {

    private static final String CHANNEL_ID = "sms_foreground_service_channel";
    private static final int NOTIF_ID = 101;
    private SmsReceiver smsReceiver;

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d("SmsListenerService", "✅ Foreground service created");

        // Create notification channel (Android 8+)
        createNotificationChannel();

        // Start foreground service with notification
        Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("📩 SMS Listener Running")
                .setContentText("Listening for incoming SMS...")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOngoing(true)
                .build();
        startForeground(NOTIF_ID, notification);

        // Register dynamic SMS receiver
        smsReceiver = new SmsReceiver();
        IntentFilter filter = new IntentFilter("android.provider.Telephony.SMS_RECEIVED");
        filter.setPriority(IntentFilter.SYSTEM_HIGH_PRIORITY);
        registerReceiver(smsReceiver, filter);
        Log.d("SmsListenerService", "📶 Registered dynamic SMS receiver");
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (smsReceiver != null) {
            unregisterReceiver(smsReceiver);
            Log.d("SmsListenerService", "🛑 Unregistered SMS receiver");
        }
        stopForeground(true);
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null; // Not used
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel serviceChannel = new NotificationChannel(
                    CHANNEL_ID,
                    "SMS Foreground Service",
                    NotificationManager.IMPORTANCE_LOW);
            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(serviceChannel);
        }
    }
}
