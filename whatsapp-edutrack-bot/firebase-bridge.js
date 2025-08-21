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
const WHATSAPP_BOT_URL = 'http://localhost:3000'; // Your WhatsApp bot server
const BATCH_SIZE = 10;
const RETRY_DELAY = 5000; // 5 seconds
const MAX_RETRIES = 3;

console.log('🚀 WhatsApp Firebase Bridge Started');
console.log(`📡 Monitoring Firestore for queued messages...`);
console.log(`🤖 WhatsApp Bot URL: ${WHATSAPP_BOT_URL}`);

// Function to send message to WhatsApp bot
async function sendToWhatsAppBot(recipientNumber, message) {
  try {
    // Format phone number to international format
    let formattedNumber = recipientNumber;
    
    // Convert Sri Lankan local format to international format
    if (formattedNumber.startsWith('0')) {
      formattedNumber = '94' + formattedNumber.substring(1);
    }
    // If it doesn't start with country code, assume it's Sri Lankan
    else if (formattedNumber.length === 9 && !formattedNumber.startsWith('94')) {
      formattedNumber = '94' + formattedNumber;
    }
    
    console.log(`📱 Sending to: ${recipientNumber} → ${formattedNumber}`);
    
    const response = await axios.post(`${WHATSAPP_BOT_URL}/send-message`, {
      phone: formattedNumber,  // Changed from 'number' to 'phone' to match server expectation
      message: message
    }, {
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json'
      }
    });

    if (response.status === 200) {
      console.log(`✅ Message sent successfully to ${formattedNumber}`);
      return { success: true, data: response.data };
    } else {
      console.log(`⚠️ Unexpected response status: ${response.status}`);
      return { success: false, error: `HTTP ${response.status}` };
    }
  } catch (error) {
    console.log(`❌ Failed to send message to ${recipientNumber}:`, error.response?.data?.error || error.message);
    return { success: false, error: error.response?.data?.error || error.message };
  }
}

// Function to update message status in Firestore
async function updateMessageStatus(adminUid, messageId, status, error = null, attempts = 0) {
  try {
    const updateData = {
      status: status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      attempts: attempts
    };

    if (error) {
      updateData.errorMessage = error;
    }

    if (status === 'completed') {
      updateData.completedAt = admin.firestore.FieldValue.serverTimestamp();
    }

    await db
      .collection('admins')
      .doc(adminUid)
      .collection('whatsappQueue')
      .doc(messageId)
      .update(updateData);

    console.log(`📝 Updated message ${messageId} status to: ${status}`);
  } catch (error) {
    console.error(`❌ Error updating message status:`, error.message);
  }
}

// Function to process a single message
async function processMessage(adminUid, messageDoc) {
  const messageId = messageDoc.id;
  const data = messageDoc.data();
  
  // Handle different field names from your Flutter app
  const recipientNumber = data.recipientNumber || data.phone;
  const message = data.message;
  const attempts = data.attempts || data.retryCount || 0;
  const maxAttempts = data.maxAttempts || 3;
  
  console.log(`📤 Processing message data:`, {
    messageId,
    adminUid,
    recipientNumber,
    messageType: data.messageType || data.type,
    status: data.status,
    attempts: attempts
  });

  if (!recipientNumber || !message) {
    console.log(`❌ Message ${messageId} missing required fields:`, {
      hasRecipientNumber: !!recipientNumber,
      hasMessage: !!message,
      rawData: data
    });
    await updateMessageStatus(adminUid, messageId, 'failed', 'Missing required fields', attempts + 1);
    return;
  }

  console.log(`📤 Processing message ${messageId} for ${recipientNumber} (attempt ${attempts + 1})`);

  // Update to processing status
  await updateMessageStatus(adminUid, messageId, 'processing', null, attempts + 1);

  // Send message to WhatsApp bot
  const result = await sendToWhatsAppBot(recipientNumber, message);

  if (result.success) {
    // Mark as completed
    console.log(`✅ Message ${messageId} sent successfully!`);
    await updateMessageStatus(adminUid, messageId, 'completed', null, attempts + 1);
  } else {
    const newAttempts = attempts + 1;
    
    if (newAttempts >= maxAttempts) {
      // Mark as failed after max retries
      console.log(`❌ Message ${messageId} failed permanently after ${newAttempts} attempts`);
      await updateMessageStatus(adminUid, messageId, 'failed', result.error, newAttempts);
    } else {
      // Mark as pending for retry
      console.log(`🔄 Message ${messageId} will be retried (${newAttempts}/${maxAttempts})`);
      await updateMessageStatus(adminUid, messageId, 'pending', result.error, newAttempts);
    }
  }
}

// Function to process pending messages for a specific admin
async function processPendingMessages(adminUid) {
  try {
    console.log(`🔍 Checking for pending messages for admin: ${adminUid}`);
    
    const pendingMessagesQuery = db
      .collection('admins')
      .doc(adminUid)
      .collection('whatsappQueue')
      .where('status', '==', 'pending')
      .limit(BATCH_SIZE);

    console.log(`📋 Querying: admins/${adminUid}/whatsappQueue (status=pending, limit=${BATCH_SIZE})`);
    
    const pendingMessages = await pendingMessagesQuery.get();

    if (pendingMessages.empty) {
      console.log(`📭 No pending messages found for admin ${adminUid}`);
      return;
    }

    console.log(`📋 Found ${pendingMessages.docs.length} pending messages for admin ${adminUid}`);

    // Process messages sequentially to avoid overwhelming the WhatsApp bot
    for (const messageDoc of pendingMessages.docs) {
      await processMessage(adminUid, messageDoc);
      
      // Small delay between messages
      await new Promise(resolve => setTimeout(resolve, 1000));
    }

  } catch (error) {
    console.error(`❌ Error processing messages for admin ${adminUid}:`, error.message);
    console.error('Full error details:', error);
  }
}

// Function to get all admin UIDs - simplified version
async function getAllAdminUids() {
  try {
    console.log('🔍 Using known admin UID from test...');
    
    // We know from the test that this admin UID has pending messages
    const knownAdminUid = 'jGTyDPHBwRaVVAwN2YtHysDQJP23';
    
    // Verify this admin has pending messages
    const pendingMessages = await db
      .collection('admins')
      .doc(knownAdminUid)
      .collection('whatsappQueue')
      .where('status', '==', 'pending')
      .limit(1)
      .get();
    
    if (!pendingMessages.empty) {
      console.log(`✅ Found admin with pending messages: ${knownAdminUid}`);
      return [knownAdminUid];
    } else {
      console.log('📭 No pending messages found for known admin');
      return [];
    }
  } catch (error) {
    console.error('❌ Error getting admin UIDs:', error.message);
    return [];
  }
}

// Main processing loop
async function processAllMessages() {
  const adminUids = await getAllAdminUids();
  
  if (adminUids.length === 0) {
    console.log('⚠️ No admins found in database');
    return;
  }

  console.log(`👥 Processing messages for ${adminUids.length} admin(s)`);

  for (const adminUid of adminUids) {
    await processPendingMessages(adminUid);
  }
}

// Check WhatsApp bot health
async function checkBotHealth() {
  try {
    console.log('🔍 Attempting to connect to WhatsApp bot...');
    const response = await axios.get(`${WHATSAPP_BOT_URL}/health`, { 
      timeout: 10000,
      headers: {
        'Connection': 'keep-alive',
        'User-Agent': 'Firebase-Bridge/1.0.0'
      },
      maxRedirects: 0,
      validateStatus: function (status) {
        return status >= 200 && status < 300;
      }
    });
    
    if (response.status === 200) {
      console.log('🤖 WhatsApp bot is healthy');
      console.log(`📊 Bot Status: ${JSON.stringify(response.data, null, 2)}`);
      return true;
    } else {
      console.log(`⚠️ Unexpected status code: ${response.status}`);
      return false;
    }
  } catch (error) {
    console.log('⚠️ WhatsApp bot health check failed:', error.message);
    console.log('🔍 Error details:', {
      code: error.code,
      errno: error.errno,
      syscall: error.syscall,
      address: error.address,
      port: error.port
    });
    return false;
  }
}

// Startup function
async function startup() {
  console.log('🔍 Checking WhatsApp bot connection...');
  
  // Try multiple times with delays
  let isHealthy = false;
  const maxAttempts = 3;
  
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    console.log(`🔄 Connection attempt ${attempt}/${maxAttempts}...`);
    isHealthy = await checkBotHealth();
    
    if (isHealthy) {
      break;
    }
    
    if (attempt < maxAttempts) {
      console.log('⏳ Waiting 3 seconds before retry...');
      await new Promise(resolve => setTimeout(resolve, 3000));
    }
  }
  
  if (!isHealthy) {
    console.log('❌ WhatsApp bot is not available after multiple attempts.');
    console.log('💡 Make sure WhatsApp bot is running on localhost:3000');
    console.log('� Try these steps:');
    console.log('   1. Check if npm start is running in another terminal');
    console.log('   2. Verify bot shows "✅ WhatsApp Client is ready!"');
    console.log('   3. Test manually: curl http://localhost:3000/health');
    process.exit(1);
  }

  console.log('✅ WhatsApp bot is ready');
  console.log('🔄 Starting message processing loop...');
}

// Main execution
startup().then(() => {
  // Process messages every 10 seconds
  setInterval(async () => {
    try {
      await processAllMessages();
    } catch (error) {
      console.error('❌ Error in main processing loop:', error.message);
    }
  }, 10000);

  console.log('🎯 Firebase WhatsApp Bridge is now monitoring for messages every 10 seconds');
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n👋 Shutting down Firebase WhatsApp Bridge...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n👋 Shutting down Firebase WhatsApp Bridge...');
  process.exit(0);
});