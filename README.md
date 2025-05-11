# 📱 SMS Receiver App (Flutter + ASP.NET Core)

**A native Android app that automatically receives, filters, and syncs SMS messages to a secure Web API.**

---

## 🔹 Description

This project includes a Flutter mobile app and an ASP.NET Core Web API backend. The mobile app listens for incoming SMS messages using native Android code and stores them in a local SQLite database. It then syncs those messages to a secure server using JWT authentication and refresh tokens.

---

## ✨ Features

- 📩 **Native SMS Receiver** (runs in background)
- ✅ **Allowed Sender Filtering**
- 🔐 **JWT Authentication with Refresh Token**
- 🔄 **Automatic Sync with Server**
- 💾 **SQLite Local Storage with Duplicate Prevention**
- 🌐 **Online Sync on Connectivity Available**
- ⚙️ **Custom Config Screen (API URL + Senders)**
- 🔔 **Notifications for Incoming SMS**

---

## 🛠️ Technologies Used

| Layer            | Tech Stack                      |
|------------------|---------------------------------|
| Frontend (Mobile) | Flutter, Dart, Method Channels  |
| Native Android    | Java (SMS receiver, DB bridge)  |
| Backend (Server)  | ASP.NET Core Web API, C#        |
| Database          | SQLite (local), SQL Server      |
| Auth              | JWT (Access + Refresh Token)    |

---

## 📂 Project Structure

- `/flutter_app/` - Flutter front-end + native Android integration
- `/SmsReceiverApi/` - ASP.NET Core Web API with SQL Server
- `SmsDatabaseHelper.java` - Native code for local message storage
- `SmsReceiver.java` - Native BroadcastReceiver for SMS
- `DatabaseService.dart` - Local SQLite handler

---

## 🚀 How to Run

### 🧩 Flutter App
1. Clone the repo and run:
   ```bash
   flutter pub get
   flutter run
