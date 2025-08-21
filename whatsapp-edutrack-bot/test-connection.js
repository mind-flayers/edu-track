const admin = require('firebase-admin');
const axios = require('axios');

// Initialize Firebase Admin with service account key
try {
  const serviceAccount = require('./service-account-key.json');
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'edutrack-73a2e'
  });
  
  console.log('✅ Firebase Admin SDK initialized successfully');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
  console.log('💡 Make sure service-account-key.json exists and is valid');
  process.exit(1);
}

const db = admin.firestore();

// Configuration
const WHATSAPP_BOT_URL = 'http://localhost:3000';

console.log('🧪 Testing Firebase Bridge Connection...');

async function testFirebaseConnection() {
  try {
    console.log('🔍 Testing Firestore connection...');
    
    // Test basic Firestore connection
    const testDoc = await db.collection('test').limit(1).get();
    console.log('✅ Firestore connection successful');
    
    // Look for WhatsApp queue collections
    console.log('🔍 Searching for whatsappQueue collections...');
    
    const queueSnapshot = await db.collectionGroup('whatsappQueue').limit(10).get();
    
    if (queueSnapshot.empty) {
      console.log('📭 No whatsappQueue documents found');
      console.log('💡 This means either:');
      console.log('  1. No WhatsApp messages have been queued yet');
      console.log('  2. The Flutter app is not connected to the correct Firebase project');
      console.log('  3. The collection structure is different than expected');
    } else {
      console.log(`📋 Found ${queueSnapshot.docs.length} whatsappQueue document(s)`);
      
      // Show admin UIDs found
      const adminUids = new Set();
      queueSnapshot.docs.forEach(doc => {
        const pathParts = doc.ref.path.split('/');
        if (pathParts[0] === 'admins' && pathParts.length >= 2) {
          adminUids.add(pathParts[1]);
        }
        console.log(`📄 Document path: ${doc.ref.path}`);
        console.log(`📝 Data:`, doc.data());
      });
      
      console.log(`👥 Admin UIDs with WhatsApp queues: ${Array.from(adminUids).join(', ')}`);
    }
    
    // Test WhatsApp bot connection
    console.log('🤖 Testing WhatsApp bot connection...');
    try {
      const response = await axios.get(`${WHATSAPP_BOT_URL}/health`, { timeout: 5000 });
      console.log('✅ WhatsApp bot is responding:', response.data);
    } catch (botError) {
      console.log('❌ WhatsApp bot is not responding:', botError.message);
      console.log('💡 Make sure to start the WhatsApp bot first: npm start');
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error('Full error:', error);
  }
}

// Run the test
testFirebaseConnection().then(() => {
  console.log('\n🏁 Test completed. Check the results above.');
  process.exit(0);
});

// Handle errors
process.on('unhandledRejection', (error) => {
  console.error('❌ Unhandled rejection:', error);
  process.exit(1);
});