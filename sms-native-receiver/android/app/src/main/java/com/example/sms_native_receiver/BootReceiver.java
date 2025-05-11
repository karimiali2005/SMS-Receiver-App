package com.example.sms_native_receiver;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import android.widget.Toast;
import android.os.Build;

public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        Log.d("BOOT_RECEIVER", "✅ Boot completed");

        Intent serviceIntent = new Intent(context, SmsListenerService.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent);
        } else {
            context.startService(serviceIntent);
        }

        Toast.makeText(context, "✅ SMS Foreground Service Started", Toast.LENGTH_LONG).show();
    }

}
