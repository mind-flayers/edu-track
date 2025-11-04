// Keep-alive script for free hosting (prevents auto-sleep)
// Deploy this to cron-job.org (free, no credit card)

const WHATSAPP_BOT_URL = process.env.WHATSAPP_BOT_URL || 'https://your-app.koyeb.app';

async function ping() {
  try {
    const response = await fetch(`${WHATSAPP_BOT_URL}/health`);
    const data = await response.json();
    
    console.log(`[${new Date().toISOString()}] Ping successful:`, data);
    
    if (!data.whatsapp_ready) {
      console.warn('⚠️ WhatsApp client not ready!');
    }
    
    return data;
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Ping failed:`, error.message);
    throw error;
  }
}

// Run the ping
ping()
  .then(() => process.exit(0))
  .catch(() => process.exit(1));
