# WhatsApp EduTrack Integration Setup

## Smart Solution for Network Connectivity Issues

Since we encountered network connectivity issues between your Android device and PC, we've implemented a **Firebase Bridge** solution that eliminates the need for direct network connectivity.

## Architecture

```
Flutter App (Android) → Firebase Firestore → Node.js Bridge → WhatsApp Bot → WhatsApp Web
```

## Setup Instructions

### 1. Install Dependencies

```bash
cd whatsapp-edutrack-bot
npm install
```

### 2. Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/project/edutrack-73a2e/settings/serviceaccounts/adminsdk)
2. Click "Generate new private key"
3. Download the JSON file
4. Rename it to `service-account-key.json`
5. Place it in the `whatsapp-edutrack-bot` folder

### 3. Start the WhatsApp Bot Server

```bash
cd whatsapp-edutrack-bot
npm start
```

- Scan the QR code with WhatsApp
- Wait for "WhatsApp bot is ready!" message

### 4. Start the Firebase Bridge (New Terminal)

```bash
cd whatsapp-edutrack-bot
npm run bridge
```

This will:
- Monitor Firestore for queued messages
- Forward messages to your WhatsApp bot
- Update message status in Firebase

### 5. Test the Integration

1. Open your Flutter app
2. Scan a student QR code
3. Select a subject
4. Mark attendance
5. Check that the message appears in Firestore and gets delivered via WhatsApp

## How It Works

### Flutter App Side
- When you mark attendance, the app queues a message in Firestore
- Path: `admins/{adminUid}/whatsappQueue/{messageId}`
- Status: `pending` → `processing` → `completed` or `failed`

### Firebase Bridge Side
- Monitors Firestore every 10 seconds
- Finds messages with `status: 'pending'`
- Sends them to your WhatsApp bot via HTTP
- Updates status based on success/failure

### Benefits of This Architecture

✅ **No Network Issues**: Firebase is always accessible from both Android and PC
✅ **Reliable**: Built-in retry mechanism with status tracking
✅ **Scalable**: Can handle multiple admins and message queues
✅ **Monitoring**: Real-time status updates in Firestore
✅ **Offline Support**: Messages queue up when network is down

## Troubleshooting

### WhatsApp Bot Issues
```bash
# Check if bot is running
curl http://localhost:3000/health

# Should return: {"status":"healthy","timestamp":"..."}
```

### Firebase Bridge Issues
```bash
# Check if bridge can connect to bot
curl http://localhost:3000/health

# Check Firestore permissions in Firebase Console
```

### Flutter App Issues
- Make sure WhatsAppQueueService is properly initialized
- Check that messages are appearing in Firestore console
- Verify admin UID is correctly set

## Message Flow Example

1. **Flutter**: QR scan → Mark attendance → Queue message in Firestore
2. **Firestore**: Message appears with `status: "pending"`
3. **Bridge**: Detects pending message → Sends to WhatsApp bot
4. **WhatsApp Bot**: Receives message → Sends via WhatsApp Web
5. **Bridge**: Updates status to `"completed"` in Firestore
6. **Flutter**: Can monitor status via real-time stream

## Firebase Collection Structure

```
admins/
  └── {adminUid}/
      └── whatsappQueue/
          └── {messageId}/
              ├── recipientNumber: "94757593737"
              ├── message: "📚 Attendance Update..."
              ├── messageType: "attendance"
              ├── status: "pending" | "processing" | "completed" | "failed"
              ├── attempts: 0
              ├── maxAttempts: 3
              ├── createdAt: Timestamp
              ├── updatedAt: Timestamp
              └── metadata: {...}
```

This solution completely bypasses the network connectivity issues we encountered and provides a robust, production-ready WhatsApp integration! 🎉