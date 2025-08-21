const admin = require('firebase-admin');

// Initialize Firebase Admin with service account key
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'edutrack-73a2e'
});

const db = admin.firestore();

// Test creating a message in Firebase
async function createTestMessage() {
  try {
    const adminUid = 'jGTyDPHBwRaVVAwN2YtHysDQJP23';
    
    const messageData = {
      phone: '0789393823',  // Local format - will be converted to international by bridge
      message: '🧪 **Test Message from Firebase Bridge**\n\nThis is a test to verify the complete WhatsApp integration is working with phone number formatting.\n\nTime: ' + new Date().toLocaleString(),
      type: 'test',
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      retryCount: 0,
      metadata: {
        testMessage: true,
        source: 'manual_test'
      }
    };
    
    const docRef = await db
      .collection('admins')
      .doc(adminUid)
      .collection('whatsappQueue')
      .add(messageData);
    
    console.log('✅ Test message created with ID:', docRef.id);
    console.log('📱 Phone number:', messageData.phone);
    console.log('📝 Message preview:', messageData.message.substring(0, 50) + '...');
    console.log('⏱️ The Firebase bridge should pick this up within 10 seconds!');
    
  } catch (error) {
    console.error('❌ Error creating test message:', error);
  } finally {
    process.exit(0);
  }
}

createTestMessage();