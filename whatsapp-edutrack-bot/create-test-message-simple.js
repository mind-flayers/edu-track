const admin = require('firebase-admin');

// Initialize Firebase Admin
try {
  const serviceAccount = require('./service-account-key.json');
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'edutrack-73a2e'
  });
  
  console.log('✅ Firebase Admin SDK initialized');
} catch (error) {
  console.error('❌ Failed to initialize Firebase:', error.message);
  process.exit(1);
}

const db = admin.firestore();

// Create test message for attendance notification
async function createAttendanceTestMessage(adminUid, phoneNumber) {
  try {
    const messageData = {
      phone: phoneNumber,
      message: `✅ *Attendance Test Message*

Hello Parent,

This is a TEST message to verify WhatsApp integration is working.

*Student:* Test Student
*Subject:* Mathematics
*Class:* Grade 10A
*Date:* ${new Date().toLocaleDateString()}
*Time:* ${new Date().toLocaleTimeString()}
*Status:* PRESENT ✅

This message was sent from the WhatsApp testing system.

Best regards,
EduTrack System
_Powered by EduTrack_`,
      type: 'test_attendance',
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      metadata: {
        testMessage: true,
        source: 'manual_test_script',
        studentName: 'Test Student',
        subject: 'Mathematics'
      },
      attempts: 0
    };
    
    const docRef = await db
      .collection('admins')
      .doc(adminUid)
      .collection('whatsappQueue')
      .add(messageData);
    
    console.log('✅ Test attendance message created!');
    console.log(`   Message ID: ${docRef.id}`);
    console.log(`   Admin UID: ${adminUid}`);
    console.log(`   Phone: ${phoneNumber}`);
    console.log(`   Status: pending`);
    console.log('\n⏳ Message will be processed by Firebase Bridge within 10 seconds...');
    
    return docRef.id;
  } catch (error) {
    console.error('❌ Error creating test message:', error.message);
    throw error;
  }
}

// Create test message for payment notification
async function createPaymentTestMessage(adminUid, phoneNumber) {
  try {
    const messageData = {
      phone: phoneNumber,
      message: `💰 *Payment Test Message*

Dear Parent,

This is a TEST message to verify payment notifications.

*Student:* Test Student
*Type:* Monthly Payment
*Amount:* Rs. 5000.00
*Month:* ${new Date().toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}
*Receipt #:* TEST${Date.now()}
*Status:* PAID ✅

Thank you for your payment!

Best regards,
EduTrack System
_Powered by EduTrack_`,
      type: 'test_payment',
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      metadata: {
        testMessage: true,
        source: 'manual_test_script',
        studentName: 'Test Student',
        amount: 5000
      },
      attempts: 0
    };
    
    const docRef = await db
      .collection('admins')
      .doc(adminUid)
      .collection('whatsappQueue')
      .add(messageData);
    
    console.log('✅ Test payment message created!');
    console.log(`   Message ID: ${docRef.id}`);
    console.log(`   Admin UID: ${adminUid}`);
    console.log(`   Phone: ${phoneNumber}`);
    console.log(`   Status: pending`);
    console.log('\n⏳ Message will be processed by Firebase Bridge within 10 seconds...');
    
    return docRef.id;
  } catch (error) {
    console.error('❌ Error creating test message:', error.message);
    throw error;
  }
}

// Get all admin UIDs
async function getAllAdmins() {
  try {
    const adminsSnapshot = await db.collection('admins').listDocuments();
    return adminsSnapshot.map(doc => doc.id);
  } catch (error) {
    console.error('❌ Error getting admins:', error.message);
    return [];
  }
}

// Main function
async function main() {
  console.log('\n====================================');
  console.log('WhatsApp Test Message Creator');
  console.log('====================================\n');
  
  // Get phone number from command line arguments
  const phoneNumber = process.argv[2];
  const messageType = process.argv[3] || 'attendance';
  
  if (!phoneNumber) {
    console.log('❌ Error: Phone number required\n');
    console.log('Usage:');
    console.log('  node create-test-message-simple.js <phone> [type]');
    console.log('\nExamples:');
    console.log('  node create-test-message-simple.js 0771234567');
    console.log('  node create-test-message-simple.js 0771234567 attendance');
    console.log('  node create-test-message-simple.js 0771234567 payment');
    console.log('\nPhone formats accepted:');
    console.log('  0771234567  (local format - will be converted)');
    console.log('  94771234567 (international without +)');
    console.log('  +94771234567 (international with +)');
    process.exit(1);
  }
  
  // Get all admins
  console.log('🔍 Finding admins in database...');
  const adminUids = await getAllAdmins();
  
  if (adminUids.length === 0) {
    console.log('❌ No admins found in database');
    process.exit(1);
  }
  
  console.log(`✅ Found ${adminUids.length} admin(s):`);
  adminUids.forEach((uid, index) => {
    console.log(`   ${index + 1}. ${uid}`);
  });
  
  // Use first admin for testing
  const adminUid = adminUids[0];
  console.log(`\n📝 Using admin: ${adminUid}`);
  console.log(`📱 Phone number: ${phoneNumber}`);
  console.log(`📋 Message type: ${messageType}\n`);
  
  // Create test message
  if (messageType.toLowerCase() === 'payment') {
    await createPaymentTestMessage(adminUid, phoneNumber);
  } else {
    await createAttendanceTestMessage(adminUid, phoneNumber);
  }
  
  console.log('\n📊 To monitor message status:');
  console.log(`   1. Check Firebase Bridge terminal for processing logs`);
  console.log(`   2. Check WhatsApp on ${phoneNumber} for the message`);
  console.log(`   3. View Firestore: https://console.firebase.google.com/project/edutrack-73a2e/firestore`);
  console.log(`      Path: admins/${adminUid}/whatsappQueue`);
  
  console.log('\n✅ Done!\n');
  process.exit(0);
}

// Run main function
main().catch(error => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});
