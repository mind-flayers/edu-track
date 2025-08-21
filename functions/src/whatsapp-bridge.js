const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

// WhatsApp notification trigger via Firebase
exports.sendWhatsAppNotification = functions.firestore
  .document('admins/{adminId}/whatsappQueue/{messageId}')
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const { adminId } = context.params;
    
    try {
      console.log('📱 Processing WhatsApp message:', messageData);
      
      // Get admin's WhatsApp bot configuration
      const adminDoc = await admin.firestore()
        .collection('admins')
        .doc(adminId)
        .collection('adminProfile')
        .doc('profile')
        .get();
      
      const adminData = adminDoc.data();
      const whatsappBotUrl = adminData?.whatsappBotUrl || 'http://localhost:3000';
      
      // Try to send via WhatsApp bot
      const response = await axios.post(`${whatsappBotUrl}/send-message`, {
        phone: messageData.phone,
        message: messageData.message,
        type: messageData.type
      }, {
        timeout: 15000,
        headers: { 'Content-Type': 'application/json' }
      });
      
      if (response.status === 200 && response.data.success) {
        console.log('✅ WhatsApp message sent successfully');
        
        // Mark as sent
        await snap.ref.update({
          status: 'sent',
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          response: response.data
        });
      } else {
        throw new Error('WhatsApp API returned error: ' + JSON.stringify(response.data));
      }
      
    } catch (error) {
      console.error('❌ WhatsApp send failed:', error.message);
      
      // Mark as failed with retry info
      await snap.ref.update({
        status: 'failed',
        error: error.message,
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
        retryCount: (messageData.retryCount || 0) + 1
      });
      
      // Schedule retry if not exceeded max attempts
      if ((messageData.retryCount || 0) < 3) {
        console.log('🔄 Scheduling retry...');
        // Could implement exponential backoff retry here
      }
    }
  });

// Manual retry function
exports.retryFailedWhatsAppMessages = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  const adminId = context.auth.uid;
  
  try {
    const failedMessages = await admin.firestore()
      .collection('admins')
      .doc(adminId)
      .collection('whatsappQueue')
      .where('status', '==', 'failed')
      .where('retryCount', '<', 3)
      .get();
    
    let retryCount = 0;
    
    for (const doc of failedMessages.docs) {
      // Reset to pending to trigger the function again
      await doc.ref.update({
        status: 'pending',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      retryCount++;
    }
    
    return { success: true, retriedCount: retryCount };
  } catch (error) {
    console.error('Error retrying messages:', error);
    throw new functions.https.HttpsError('internal', 'Failed to retry messages');
  }
});