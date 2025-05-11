package com.example.sms_native_receiver;

import android.content.Context;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.content.ContentValues;
import android.util.Log;

import java.util.HashSet;
import java.util.Set;

public class SmsDatabaseHelper extends SQLiteOpenHelper {

    private static final String TAG = "SMS_DB_HELPER";

    private static final String DB_PATH = "/data/data/com.example.sms_native_receiver/databases/";
    private static final String DB_NAME = "sms_receiver.db";
    private static final int DB_VERSION = 1;

    public static final String TABLE_MESSAGES = "messages";
    public static final String COL_SENDER = "sender";
    public static final String COL_BODY = "body";
    public static final String COL_TIMESTAMP = "timestamp";
    public static final String COL_IS_MANUAL = "isManual";

    private final Context context;

    public SmsDatabaseHelper(Context ctx) {
        super(ctx, DB_PATH + DB_NAME, null, DB_VERSION);
        this.context = ctx;
        Log.d(TAG, "📦 Database initialized at: " + DB_PATH + DB_NAME);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        Log.d(TAG, "🛠️ Creating messages table...");
        db.execSQL("CREATE TABLE IF NOT EXISTS " + TABLE_MESSAGES + " (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                COL_SENDER + " TEXT, " +
                COL_BODY + " TEXT, " +
                COL_TIMESTAMP + " TEXT, " +
                COL_IS_MANUAL + " INTEGER)");
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        // Future DB schema upgrades go here
    }

    public void insertMessage(String sender, String body, String timestamp, int isManual) {
        try {
            if (!isAllowedSender(sender)) {
                Log.w(TAG, "⛔ Skipping sender: " + sender + " (not allowed)");
                return;
            }

            if (messageExists(sender, body, timestamp)) {
                Log.w(TAG, "⚠️ Duplicate SMS from: " + sender + " - skipping...");
                return;
            }

            SQLiteDatabase db = this.getWritableDatabase();
            ContentValues values = new ContentValues();
            values.put(COL_SENDER, sender);
            values.put(COL_BODY, body);
            values.put(COL_TIMESTAMP, timestamp);
            values.put(COL_IS_MANUAL, isManual);

            long result = db.insert(TABLE_MESSAGES, null, values);
            db.close();

            if (result != -1) {
                Log.d(TAG, "✅ SMS saved: " + sender);
            } else {
                Log.e(TAG, "❌ Failed to insert SMS from: " + sender);
            }

        } catch (Exception e) {
            Log.e(TAG, "❌ Error inserting SMS: " + e.getMessage());
        }
    }

    private boolean messageExists(String sender, String body, String timestamp) {
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query(
                TABLE_MESSAGES,
                null,
                COL_SENDER + "=? AND " + COL_BODY + "=? AND " + COL_TIMESTAMP + "=?",
                new String[] { sender, body, timestamp },
                null, null, null);

        boolean exists = (cursor != null && cursor.getCount() > 0);
        if (cursor != null)
            cursor.close();
        return exists;
    }

    private boolean isAllowedSender(String sender) {
        try {
            SharedPreferences prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);
            String rawList = prefs.getString("flutter.allowedSenders", null);

            if (rawList == null || rawList.isEmpty()) {
                Log.w(TAG, "⚠️ No allowedSenders configured — allowing all senders.");
                return true;
            }

            Set<String> allowedSet = new HashSet<>();
            for (String s : rawList.replace("[", "").replace("]", "").split(",")) {
                s = s.trim().replace("\"", "").replace("+", "").replace(" ", "");
                if (!s.isEmpty()) {
                    allowedSet.add(s);
                }
            }

            String normalizedSender = sender.replace("+", "").replace(" ", "");
            boolean allowed = allowedSet.contains(normalizedSender);

            Log.d(TAG, "🔍 Allowed list: " + allowedSet);
            Log.d(TAG, "🔎 Checking sender: " + normalizedSender + " => Allowed: " + allowed);

            return allowed;

        } catch (Exception e) {
            Log.e(TAG, "❌ Error checking allowed senders: " + e.getMessage());
            return true; // allow all on error
        }
    }
}
