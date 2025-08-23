const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccountPath = path.join(__dirname, '..', 'whatsapp-edutrack-bot', 'service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccountPath)
});

const db = admin.firestore();

/**
 * Migration Script: Convert payment system from boolean 'paid' to string 'status'
 * 
 * Changes:
 * 1. Convert fees.paid (boolean) → fees.status ('PAID' | 'PENDING')
 * 2. Add students.isNonePayee (boolean, default: false)
 * 3. Update fee records with appropriate timestamps
 */

async function migratePaymentStatus() {
  console.log('🚀 Starting Payment Status Migration...');
  console.log('📋 Changes:');
  console.log('   - Convert fees.paid (boolean) → fees.status (string)');
  console.log('   - Add students.isNonePayee (boolean, default: false)');
  console.log('   - Preserve existing timestamps and add missing ones');
  console.log();

  let totalStudents = 0;
  let totalFees = 0;
  let studentsUpdated = 0;
  let feesUpdated = 0;
  const batchSize = 500; // Firestore batch limit
  
  try {
    // Get all admin documents
    const adminQuery = await db.collection('admins').get();
    console.log(`📁 Found ${adminQuery.docs.length} admin(s) to process`);

    for (const adminDoc of adminQuery.docs) {
      console.log(`\n🔧 Processing admin: ${adminDoc.id}`);
      
      // Get all students for this admin
      const studentsQuery = await adminDoc.ref.collection('students').get();
      totalStudents += studentsQuery.docs.length;
      console.log(`   📚 Found ${studentsQuery.docs.length} students`);

      // Process students in batches
      for (let i = 0; i < studentsQuery.docs.length; i += batchSize) {
        const batch = db.batch();
        const studentsBatch = studentsQuery.docs.slice(i, i + batchSize);
        
        for (const studentDoc of studentsBatch) {
          const studentData = studentDoc.data();
          
          // Add isNonePayee flag if not exists
          if (studentData.isNonePayee === undefined) {
            batch.update(studentDoc.ref, {
              isNonePayee: false, // Default to regular paying student
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            studentsUpdated++;
          }

          // Process fee records for this student
          const feesQuery = await studentDoc.ref.collection('fees').get();
          console.log(`     💰 Student ${studentDoc.id}: ${feesQuery.docs.length} fee records`);
          totalFees += feesQuery.docs.length;

          for (const feeDoc of feesQuery.docs) {
            const feeData = feeDoc.data();
            
            // Only migrate if 'paid' field exists and 'status' doesn't
            if (feeData.hasOwnProperty('paid') && !feeData.hasOwnProperty('status')) {
              const status = feeData.paid ? 'PAID' : 'PENDING';
              const updateData = {
                status: status,
                // Remove old paid field
                paid: admin.firestore.FieldValue.delete()
              };

              // Add appropriate timestamp if missing
              if (status === 'PAID' && !feeData.paidAt) {
                // Use existing timestamp or current time
                updateData.paidAt = feeData.markedAt || admin.firestore.FieldValue.serverTimestamp();
              } else if (status === 'PENDING' && !feeData.pendingAt) {
                // Add pendingAt timestamp for pending payments
                updateData.pendingAt = feeData.markedAt || admin.firestore.FieldValue.serverTimestamp();
              }

              batch.update(feeDoc.ref, updateData);
              feesUpdated++;
            }
          }
        }

        // Commit the batch
        if (studentsUpdated > 0 || feesUpdated > 0) {
          await batch.commit();
          console.log(`   ✅ Batch committed: ${studentsBatch.length} students processed`);
        }
      }
    }

    console.log('\n🎉 Migration completed successfully!');
    console.log('\n📊 Summary:');
    console.log(`   👥 Total students: ${totalStudents}`);
    console.log(`   📝 Students updated with isNonePayee: ${studentsUpdated}`);
    console.log(`   💳 Total fee records: ${totalFees}`);
    console.log(`   🔄 Fee records migrated: ${feesUpdated}`);

  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  }
}

/**
 * Verify migration results
 */
async function verifyMigration() {
  console.log('\n🔍 Verifying migration results...');
  
  try {
    // Check for any remaining 'paid' fields
    const feesWithPaidField = await db.collectionGroup('fees')
      .where('paid', '!=', null)
      .limit(5)
      .get();
    
    if (feesWithPaidField.docs.length > 0) {
      console.warn(`⚠️  Found ${feesWithPaidField.docs.length} fee records still with 'paid' field`);
      feesWithPaidField.docs.forEach(doc => {
        console.log(`   - ${doc.ref.path}`);
      });
    } else {
      console.log('✅ No remaining "paid" fields found');
    }

    // Check status field distribution
    const paidFees = await db.collectionGroup('fees')
      .where('status', '==', 'PAID')
      .limit(1)
      .get();
    
    const pendingFees = await db.collectionGroup('fees')
      .where('status', '==', 'PENDING')
      .limit(1)
      .get();

    console.log(`✅ Status field verification:`);
    console.log(`   - PAID records found: ${paidFees.docs.length > 0 ? 'Yes' : 'No'}`);
    console.log(`   - PENDING records found: ${pendingFees.docs.length > 0 ? 'Yes' : 'No'}`);

    // Check isNonePayee field
    const studentsWithNonePayee = await db.collectionGroup('students')
      .where('isNonePayee', '!=', null)
      .limit(5)
      .get();
    
    console.log(`✅ isNonePayee field added to ${studentsWithNonePayee.docs.length > 0 ? 'students' : 'no students'}`);
    
  } catch (error) {
    console.error('❌ Verification failed:', error);
  }
}

/**
 * Rollback migration (emergency only)
 */
async function rollbackMigration() {
  console.log('🔄 Rolling back migration...');
  console.warn('⚠️  This will convert status back to paid boolean and remove isNonePayee');
  
  try {
    const adminQuery = await db.collection('admins').get();
    
    for (const adminDoc of adminQuery.docs) {
      const studentsQuery = await adminDoc.ref.collection('students').get();
      
      for (const studentDoc of studentsQuery.docs) {
        const batch = db.batch();
        
        // Remove isNonePayee field
        batch.update(studentDoc.ref, {
          isNonePayee: admin.firestore.FieldValue.delete()
        });
        
        // Rollback fee records
        const feesQuery = await studentDoc.ref.collection('fees').get();
        for (const feeDoc of feesQuery.docs) {
          const feeData = feeDoc.data();
          
          if (feeData.hasOwnProperty('status')) {
            const paid = feeData.status === 'PAID';
            batch.update(feeDoc.ref, {
              paid: paid,
              status: admin.firestore.FieldValue.delete(),
              pendingAt: admin.firestore.FieldValue.delete()
            });
          }
        }
        
        await batch.commit();
      }
    }
    
    console.log('✅ Rollback completed');
  } catch (error) {
    console.error('❌ Rollback failed:', error);
  }
}

// Main execution
async function main() {
  const args = process.argv.slice(2);
  const command = args[0];

  switch (command) {
    case 'migrate':
      await migratePaymentStatus();
      await verifyMigration();
      break;
    case 'verify':
      await verifyMigration();
      break;
    case 'rollback':
      console.log('⚠️  ROLLBACK REQUESTED');
      console.log('This will undo all migration changes.');
      console.log('Type "yes" to confirm or anything else to cancel:');
      
      // Simple confirmation (you might want to use readline for better UX)
      if (args[1] === 'yes') {
        await rollbackMigration();
      } else {
        console.log('❌ Rollback cancelled');
      }
      break;
    default:
      console.log('📖 Usage:');
      console.log('  node migrate_payment_status.js migrate   # Run the migration');
      console.log('  node migrate_payment_status.js verify    # Verify migration results');
      console.log('  node migrate_payment_status.js rollback yes # Rollback (DANGEROUS)');
  }
  
  // Close the app
  process.exit(0);
}

main().catch(console.error);