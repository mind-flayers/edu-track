# 📱 WhatsApp Notification Setup Guide
## Using whatsapp-web.js + n8n on fly.io

> ⚠️ **Important Disclaimer**: This guide describes an unofficial method of sending WhatsApp messages that may violate WhatsApp's Terms of Service. Use at your own risk. For production applications, consider using the official WhatsApp Business API.

## 📋 Feasibility Analysis

### ✅ Pros
- **Cost-effective**: Free tier available on all platforms
- **Full control**: Complete customization of message flow
- **Multiple numbers**: Can switch between different WhatsApp accounts
- **No API limits**: Unlike official APIs with message quotas
- **Real-time**: Instant message delivery
- **Rich media**: Support for images, documents, location sharing

### ❌ Cons
- **Terms of Service violation**: WhatsApp prohibits automated messaging
- **Account ban risk**: WhatsApp may detect and ban your number
- **Manual authentication**: Requires QR code scanning every few weeks
- **Resource intensive**: Runs a full browser instance
- **Reliability concerns**: May break with WhatsApp Web updates
- **Not enterprise-ready**: Unsuitable for critical business operations

### 🎯 Recommendation
Use this approach for:
- **Proof of concept** and testing
- **Small-scale operations** (< 100 messages/day)
- **Development environment**
- **Learning and experimentation**

**Migrate to official WhatsApp Business API for production use.**

---

## 🚀 Prerequisites

### Software Requirements
- Node.js 18+ 
- Git
- Docker (for deployment)
- A dedicated WhatsApp number (not your personal number)

### Platform Accounts
- [fly.io](https://fly.io) account
- Dedicated WhatsApp account
- Basic understanding of REST APIs and webhooks

### Estimated Setup Time
- **First-time setup**: 4-6 hours
- **With experience**: 1-2 hours

---

## 🌐 Part 1: Setting Up fly.io

### Step 1: Account Creation and CLI Installation

1. **Create fly.io Account**
   ```bash
   # Visit https://fly.io/app/sign-up
   # Sign up with GitHub or email
   ```

2. **Install flyctl CLI**
   ```bash
   # Windows (PowerShell)
   iwr https://fly.io/install.ps1 -useb | iex
   
   # macOS/Linux
   curl -L https://fly.io/install.sh | sh
   ```

3. **Login to fly.io**
   ```bash
   flyctl auth login
   ```

4. **Verify Installation**
   ```bash
   flyctl version
   ```

### Step 2: Understanding fly.io Basics

#### Key Concepts:
- **Apps**: Your deployed applications
- **Volumes**: Persistent storage for your data
- **Regions**: Geographic deployment locations
- **Scaling**: Automatic or manual resource allocation

#### Pricing Overview:
- **Free tier**: 160GB-hours/month (enough for small apps)
- **Persistent volumes**: $0.15/GB/month
- **Bandwidth**: First 160GB free

---

## 🤖 Part 2: WhatsApp Bot with whatsapp-web.js

### Step 1: Understanding whatsapp-web.js

#### What it does:
- Connects to WhatsApp Web programmatically
- Automates message sending through browser automation
- Maintains session state for persistent connections

#### Architecture:
```
Flutter App → Webhook → n8n → whatsapp-web.js → WhatsApp Web → Recipient
```

### Step 2: Creating the WhatsApp Bot Service

1. **Create Project Directory**
   ```bash
   mkdir whatsapp-edutrack-bot
   cd whatsapp-edutrack-bot
   npm init -y
   ```

2. **Install Dependencies**
   ```bash
   npm install whatsapp-web.js express cors helmet dotenv qrcode-terminal
   npm install --save-dev nodemon
   ```

3. **Create Bot Server** (`server.js`)
   ```javascript
   const { Client, LocalAuth } = require('whatsapp-web.js');
   const express = require('express');
   const cors = require('cors');
   const helmet = require('helmet');
   const qrcode = require('qrcode-terminal');
   require('dotenv').config();

   const app = express();
   const PORT = process.env.PORT || 3000;

   // Middleware
   app.use(helmet());
   app.use(cors());
   app.use(express.json({ limit: '10mb' }));

   // WhatsApp Client with persistent session
   const client = new Client({
     authStrategy: new LocalAuth({
       dataPath: '/data/whatsapp-session', // Persistent storage
       clientId: process.env.CLIENT_ID || 'edutrack-bot'
     }),
     puppeteer: {
       headless: true,
       args: [
         '--no-sandbox',
         '--disable-setuid-sandbox',
         '--disable-dev-shm-usage',
         '--disable-accelerated-2d-canvas',
         '--no-first-run',
         '--no-zygote',
         '--single-process',
         '--disable-gpu'
       ]
     }
   });

   // QR Code for initial authentication
   client.on('qr', (qr) => {
     console.log('QR RECEIVED', qr);
     qrcode.generate(qr, { small: true });
   });

   client.on('ready', () => {
     console.log('✅ WhatsApp client is ready!');
   });

   client.on('authenticated', () => {
     console.log('🔐 WhatsApp client authenticated');
   });

   client.on('auth_failure', (msg) => {
     console.error('❌ Authentication failed', msg);
   });

   client.on('disconnected', (reason) => {
     console.log('📱 WhatsApp client disconnected', reason);
   });

   // Health check endpoint
   app.get('/health', (req, res) => {
     res.json({ 
       status: 'ok',
       whatsapp_ready: client.info ? true : false,
       timestamp: new Date().toISOString()
     });
   });

   // Send message endpoint
   app.post('/send-message', async (req, res) => {
     try {
       const { phoneNumber, message, type = 'text' } = req.body;

       if (!phoneNumber || !message) {
         return res.status(400).json({ 
           error: 'Phone number and message are required' 
         });
       }

       // Format phone number (remove spaces, add country code if missing)
       const formattedNumber = phoneNumber.replace(/\s/g, '') + '@c.us';

       // Send message
       const sentMessage = await client.sendMessage(formattedNumber, message);

       res.json({ 
         success: true,
         messageId: sentMessage.id.id,
         timestamp: new Date().toISOString()
       });

       console.log(`✅ Message sent to ${phoneNumber}: ${message.substring(0, 50)}...`);

     } catch (error) {
       console.error('❌ Error sending message:', error);
       res.status(500).json({ 
         error: 'Failed to send message',
         details: error.message 
       });
     }
   });

   // Get client info
   app.get('/info', async (req, res) => {
     try {
       if (!client.info) {
         return res.status(503).json({ error: 'WhatsApp client not ready' });
       }

       res.json({
         client_info: client.info,
         ready: true
       });
     } catch (error) {
       res.status(500).json({ error: error.message });
     }
   });

   // Graceful shutdown
   process.on('SIGINT', async () => {
     console.log('🛑 Shutting down gracefully...');
     await client.destroy();
     process.exit(0);
   });

   // Start server and WhatsApp client
   app.listen(PORT, () => {
     console.log(`🚀 Server running on port ${PORT}`);
     console.log(`📱 Starting WhatsApp client...`);
     client.initialize();
   });
   ```

4. **Create Environment File** (`.env`)
   ```env
   PORT=3000
   CLIENT_ID=edutrack-bot
   NODE_ENV=production
   ```

5. **Create Package.json Scripts**
   ```json
   {
     "scripts": {
       "start": "node server.js",
       "dev": "nodemon server.js",
       "test": "curl -X GET http://localhost:3000/health"
     }
   }
   ```

### Step 3: Testing Locally

1. **Start the Bot**
   ```bash
   npm run dev
   ```

2. **Scan QR Code**
   - Open WhatsApp on your phone
   - Go to Settings → Linked Devices
   - Scan the QR code shown in terminal

3. **Test Message Sending**
   ```bash
   curl -X POST http://localhost:3000/send-message \
     -H "Content-Type: application/json" \
     -d '{
       "phoneNumber": "+1234567890",
       "message": "Test message from EduTrack!"
     }'
   ```

---

## ⚙️ Part 3: n8n Workflow Automation

### Step 1: Understanding n8n

n8n is a workflow automation tool that connects different services through nodes:
- **Trigger nodes**: Start workflows (webhooks, schedules)
- **Regular nodes**: Process data (HTTP requests, data transformation)
- **Output nodes**: Send results (database, notifications)

### Step 2: n8n Project Setup

1. **Create n8n Project**
   ```bash
   mkdir n8n-edutrack
   cd n8n-edutrack
   npm init -y
   npm install n8n
   ```

2. **Create n8n Configuration** (`docker-compose.yml`)
   ```yaml
   version: '3.8'
   services:
     n8n:
       image: docker.n8n.io/n8nio/n8n
       ports:
         - "5678:5678"
       environment:
         - GENERIC_TIMEZONE=Asia/Colombo
         - N8N_SECURE_COOKIE=false
         - WEBHOOK_URL=https://your-app.fly.dev
       volumes:
         - n8n_data:/home/node/.n8n
   volumes:
     n8n_data:
   ```

3. **Start n8n Locally**
   ```bash
   npx n8n start --tunnel
   ```

### Step 3: Creating WhatsApp Workflows

1. **Access n8n Interface**
   - Open `http://localhost:5678`
   - Create your first workflow

2. **Create Attendance Notification Workflow**

   **Workflow Structure:**
   ```
   Webhook Trigger → Data Processing → HTTP Request → WhatsApp Bot
   ```

   **Nodes Configuration:**

   a) **Webhook Trigger Node:**
   ```json
   {
     "httpMethod": "POST",
     "path": "attendance-notification",
     "responseMode": "responseNode"
   }
   ```

   b) **Function Node (Message Formatter):**
   ```javascript
   // Format attendance message
   const studentName = $json.studentName;
   const subject = $json.subject;
   const parentName = $json.parentName;
   const className = $json.className;
   const date = new Date().toLocaleDateString();
   const schoolName = $json.schoolName;

   const message = `✅ Attendance Marked

   Hello ${parentName},

   Your child ${studentName} from ${className} has been marked PRESENT for ${subject} on ${date}.

   Best regards,
   ${schoolName}
   Powered by EduTrack`;

   return {
     phoneNumber: $json.parentPhone,
     message: message,
     type: 'attendance'
   };
   ```

   c) **HTTP Request Node (to WhatsApp Bot):**
   ```json
   {
     "method": "POST",
     "url": "http://whatsapp-bot:3000/send-message",
     "headers": {
       "Content-Type": "application/json"
     },
     "body": {
       "phoneNumber": "={{ $json.phoneNumber }}",
       "message": "={{ $json.message }}"
     }
   }
   ```

   d) **Response Node:**
   ```json
   {
     "responseCode": 200,
     "body": {
       "success": true,
       "message": "Notification sent successfully"
     }
   }
   ```

3. **Create Payment Notification Workflow**

   **Function Node (Payment Message):**
   ```javascript
   const studentName = $json.studentName;
   const parentName = $json.parentName;
   const amount = $json.amount;
   const month = $json.month;
   const year = $json.year;
   const schoolName = $json.schoolName;

   const message = `💰 Payment Received

   Dear ${parentName},

   We have received the payment for ${studentName}.

   Amount: Rs.${amount}
   For: ${month} ${year}
   Date: ${new Date().toLocaleDateString()}

   Thank you for your payment!

   Best regards,
   ${schoolName}
   Powered by EduTrack`;

   return {
     phoneNumber: $json.parentPhone,
     message: message,
     type: 'payment'
   };
   ```

4. **Export Workflows**
   - Save workflows as JSON files
   - Store in your project repository

---

## 🐳 Part 4: Deployment to fly.io

### Step 1: Project Structure

```
edutrack-whatsapp-service/
├── whatsapp-bot/
│   ├── server.js
│   ├── package.json
│   └── .env
├── n8n/
│   ├── docker-compose.yml
│   └── workflows/
│       ├── attendance-notification.json
│       └── payment-notification.json
├── Dockerfile
├── docker-compose.yml
├── fly.toml
└── README.md
```

### Step 2: Create Multi-Service Docker Setup

1. **Main Docker Compose** (`docker-compose.yml`)
   ```yaml
   version: '3.8'
   services:
     whatsapp-bot:
       build: ./whatsapp-bot
       ports:
         - "3000:3000"
       volumes:
         - whatsapp_data:/data
       environment:
         - NODE_ENV=production
       restart: unless-stopped
       healthcheck:
         test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
         interval: 30s
         timeout: 10s
         retries: 3

     n8n:
       image: docker.n8n.io/n8nio/n8n
       ports:
         - "5678:5678"
       environment:
         - GENERIC_TIMEZONE=Asia/Colombo
         - N8N_SECURE_COOKIE=false
         - WEBHOOK_URL=https://your-app.fly.dev
         - DB_TYPE=sqlite
         - DB_SQLITE_DATABASE=/data/database.sqlite
       volumes:
         - n8n_data:/data
         - ./n8n/workflows:/import/workflows:ro
       depends_on:
         - whatsapp-bot
       restart: unless-stopped

   volumes:
     whatsapp_data:
     n8n_data:
   ```

2. **WhatsApp Bot Dockerfile** (`whatsapp-bot/Dockerfile`)
   ```dockerfile
   FROM node:18-slim

   # Install Chrome dependencies
   RUN apt-get update && apt-get install -y \
       chromium \
       curl \
       && rm -rf /var/lib/apt/lists/*

   # Set Chrome executable path
   ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
   ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

   WORKDIR /app

   COPY package*.json ./
   RUN npm ci --only=production

   COPY . .

   # Create data directory
   RUN mkdir -p /data

   EXPOSE 3000

   USER node

   CMD ["node", "server.js"]
   ```

3. **fly.toml Configuration**
   ```toml
   app = "edutrack-whatsapp-service"
   primary_region = "sin" # Singapore region

   [build]
     dockerfile = "Dockerfile"

   [[mounts]]
     source = "whatsapp_data"
     destination = "/data"
     processes = ["app"]

   [http_service]
     internal_port = 5678
     force_https = true
     auto_stop_machines = false
     auto_start_machines = true
     min_machines_running = 1

     [[http_service.checks]]
       grace_period = "30s"
       interval = "30s"
       method = "GET"
       path = "/health"
       protocol = "http"
       timeout = "10s"

   [[services]]
     internal_port = 3000
     protocol = "tcp"

     [[services.ports]]
       handlers = ["http"]
       port = "80"

     [[services.ports]]
       handlers = ["tls", "http"]
       port = "443"

   [vm]
     memory = "1gb"
     cpu_kind = "shared"
     cpus = 1

   [env]
     NODE_ENV = "production"
   ```

### Step 3: Deploy to fly.io

1. **Initialize fly.io App**
   ```bash
   flyctl apps create edutrack-whatsapp-service
   ```

2. **Create Persistent Volume**
   ```bash
   flyctl volumes create whatsapp_data --size 1 --region sin
   ```

3. **Set Environment Variables**
   ```bash
   flyctl secrets set CLIENT_ID=edutrack-bot
   flyctl secrets set WEBHOOK_SECRET=your-secret-key
   ```

4. **Deploy Application**
   ```bash
   flyctl deploy
   ```

5. **Monitor Deployment**
   ```bash
   flyctl status
   flyctl logs
   ```

### Step 4: Initial Setup on Deployed App

1. **Access WhatsApp Bot**
   ```bash
   flyctl ssh console
   # Inside the container, check logs for QR code
   docker logs <whatsapp-bot-container>
   ```

2. **Connect WhatsApp**
   - The QR code will appear in logs
   - Scan with your dedicated WhatsApp account

3. **Import n8n Workflows**
   - Access n8n at `https://your-app.fly.dev`
   - Import the workflow JSON files
   - Configure webhook URLs

---

## 🔗 Part 5: Flutter App Integration

### Step 1: Update QR Scanner Service

1. **Create WhatsApp Notification Service** (`lib/services/whatsapp_service.dart`)
   ```dart
   import 'dart:convert';
   import 'package:http/http.dart' as http;

   class WhatsAppService {
     static const String baseUrl = 'https://your-app.fly.dev';
     static const String webhookSecret = 'your-secret-key';

     static Future<bool> sendAttendanceNotification({
       required String studentName,
       required String parentName,
       required String parentPhone,
       required String subject,
       required String className,
       required String schoolName,
     }) async {
       try {
         final response = await http.post(
           Uri.parse('$baseUrl/webhook/attendance-notification'),
           headers: {
             'Content-Type': 'application/json',
             'X-Webhook-Secret': webhookSecret,
           },
           body: json.encode({
             'studentName': studentName,
             'parentName': parentName,
             'parentPhone': parentPhone,
             'subject': subject,
             'className': className,
             'schoolName': schoolName,
             'timestamp': DateTime.now().toIso8601String(),
           }),
         );

         return response.statusCode == 200;
       } catch (e) {
         print('Error sending WhatsApp notification: $e');
         return false;
       }
     }

     static Future<bool> sendPaymentNotification({
       required String studentName,
       required String parentName,
       required String parentPhone,
       required double amount,
       required String month,
       required int year,
       required String schoolName,
     }) async {
       try {
         final response = await http.post(
           Uri.parse('$baseUrl/webhook/payment-notification'),
           headers: {
             'Content-Type': 'application/json',
             'X-Webhook-Secret': webhookSecret,
           },
           body: json.encode({
             'studentName': studentName,
             'parentName': parentName,
             'parentPhone': parentPhone,
             'amount': amount,
             'month': month,
             'year': year,
             'schoolName': schoolName,
             'timestamp': DateTime.now().toIso8601String(),
           }),
         );

         return response.statusCode == 200;
       } catch (e) {
         print('Error sending payment notification: $e');
         return false;
       }
     }
   }
   ```

2. **Update QR Scanner** (in existing file)
   ```dart
   // Import the service
   import 'package:edu_track/services/whatsapp_service.dart';

   // Update the attendance marking method
   Future<void> _markAttendanceWithSubject(String subject) async {
     // ... existing code ...

     try {
       // ... existing Firestore logic ...

       // Send WhatsApp notification via n8n
       final whatsappSent = await WhatsAppService.sendAttendanceNotification(
         studentName: _foundStudent!.name,
         parentName: _foundStudent!.parentName,
         parentPhone: _foundStudent!.parentPhone,
         subject: subject,
         className: _foundStudent!.className,
         schoolName: _academyName ?? 'EduTrack Academy',
       );

       if (whatsappSent) {
         _showStatusMessage('Attendance marked & WhatsApp sent!', isError: false);
       } else {
         _showStatusMessage('Attendance marked, but WhatsApp failed.', isError: true);
       }

       // ... rest of existing code ...
     } catch (e) {
       // ... existing error handling ...
     }
   }

   // Update payment marking method
   Future<void> _markPayment() async {
     // ... existing code ...

     try {
       // ... existing Firestore logic ...

       // Send WhatsApp notification via n8n
       final whatsappSent = await WhatsAppService.sendPaymentNotification(
         studentName: _foundStudent!.name,
         parentName: _foundStudent!.parentName,
         parentPhone: _foundStudent!.parentPhone,
         amount: amount,
         month: _selectedMonth!,
         year: currentYear,
         schoolName: _academyName ?? 'EduTrack Academy',
       );

       if (whatsappSent) {
         _showStatusMessage('Payment marked & WhatsApp sent!', isError: false);
       } else {
         _showStatusMessage('Payment marked, but WhatsApp failed.', isError: true);
       }

       // ... rest of existing code ...
     } catch (e) {
       // ... existing error handling ...
     }
   }
   ```

---

## 🔧 Part 6: Monitoring and Maintenance

### Step 1: Health Monitoring

1. **Create Monitoring Dashboard** (`monitor.js`)
   ```javascript
   const express = require('express');
   const app = express();

   app.get('/dashboard', async (req, res) => {
     const status = {
       whatsapp_bot: await checkWhatsAppBot(),
       n8n: await checkN8N(),
       last_message: await getLastMessage(),
       uptime: process.uptime(),
       memory: process.memoryUsage()
     };

     res.json(status);
   });

   async function checkWhatsAppBot() {
     try {
       const response = await fetch('http://localhost:3000/health');
       return await response.json();
     } catch (error) {
       return { status: 'error', error: error.message };
     }
   }
   ```

2. **Set Up Alerts**
   ```bash
   # Create alert webhook
   flyctl secrets set ALERT_WEBHOOK_URL=https://your-discord-webhook
   ```

### Step 2: Backup and Recovery

1. **Backup WhatsApp Sessions**
   ```bash
   # Create backup script
   flyctl ssh console -C "tar -czf /backup/session-$(date +%Y%m%d).tar.gz /data/whatsapp-session"
   ```

2. **Automated Backups**
   ```yaml
   # Add to docker-compose.yml
   backup:
     image: alpine:latest
     volumes:
       - whatsapp_data:/data:ro
       - ./backups:/backup
     command: |
       sh -c "while true; do
         tar -czf /backup/session-$$(date +%Y%m%d-%H%M).tar.gz /data/whatsapp-session
         sleep 21600  # Every 6 hours
       done"
   ```

### Step 3: Troubleshooting Common Issues

#### WhatsApp Session Expired
```bash
# Check logs
flyctl logs -a edutrack-whatsapp-service

# Restart app to trigger QR code
flyctl apps restart edutrack-whatsapp-service

# Access logs to get QR code
flyctl logs -a edutrack-whatsapp-service | grep "QR"
```

#### High Memory Usage
```bash
# Check resource usage
flyctl status -a edutrack-whatsapp-service

# Scale up if needed
flyctl scale memory 2048 -a edutrack-whatsapp-service
```

#### Messages Not Sending
```bash
# Test WhatsApp bot directly
curl -X POST https://your-app.fly.dev/send-message \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+1234567890", "message": "Test"}'

# Check n8n workflow logs
# Access n8n dashboard and check execution logs
```

---

## 🏢 Part 7: Migration to Production (WhatsApp Business API)

### When to Migrate
- Sending > 100 messages per day
- Need 99.9% reliability
- Compliance requirements
- Business-critical notifications

### Migration Steps

1. **Set Up WhatsApp Business API**
   ```bash
   # Using Twilio
   npm install twilio
   ```

2. **Create Production Service**
   ```javascript
   const twilio = require('twilio');

   class ProductionWhatsAppService {
     constructor() {
       this.client = twilio(
         process.env.TWILIO_ACCOUNT_SID,
         process.env.TWILIO_AUTH_TOKEN
       );
     }

     async sendMessage(to, body) {
       try {
         const message = await this.client.messages.create({
           body: body,
           from: 'whatsapp:+14155238886', // Twilio Sandbox
           to: `whatsapp:${to}`
         });
         return { success: true, messageId: message.sid };
       } catch (error) {
         return { success: false, error: error.message };
       }
     }
   }
   ```

3. **Gradual Migration**
   - Keep both systems running
   - Route critical messages to official API
   - Use unofficial method as backup

---

## 💰 Cost Analysis

### Development Environment (Free Tier)
- **fly.io**: Free tier (160GB-hours/month)
- **WhatsApp**: Free (but risks account ban)
- **n8n**: Self-hosted (free)
- **Total**: $0/month

### Small Scale Production (100-500 messages/month)
- **fly.io**: ~$10-20/month (persistent volume + compute)
- **WhatsApp**: Free (high risk)
- **Backup phone numbers**: $10/month
- **Total**: $20-30/month

### Recommended Production Setup
- **WhatsApp Business API**: $0.05-0.09 per message
- **fly.io**: $10-20/month
- **Monitoring**: $5-10/month
- **Total**: $15-30/month + message costs

---

## 🛡️ Security Considerations

### Data Protection
```javascript
// Encrypt sensitive data
const crypto = require('crypto');

function encryptPhone(phoneNumber) {
  const cipher = crypto.createCipher('aes192', process.env.ENCRYPTION_KEY);
  let encrypted = cipher.update(phoneNumber, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return encrypted;
}
```

### Rate Limiting
```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // Limit each IP to 10 requests per windowMs
  message: 'Too many requests from this IP'
});

app.use('/send-message', limiter);
```

### Webhook Security
```javascript
const crypto = require('crypto');

function verifyWebhook(req, res, next) {
  const signature = req.headers['x-webhook-secret'];
  const expectedSignature = process.env.WEBHOOK_SECRET;
  
  if (signature !== expectedSignature) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  
  next();
}
```

---

## 📈 Scaling Considerations

### Multiple WhatsApp Numbers
```javascript
class MultiNumberManager {
  constructor() {
    this.clients = new Map();
    this.currentIndex = 0;
  }

  addClient(phoneNumber, client) {
    this.clients.set(phoneNumber, client);
  }

  getNextClient() {
    const clients = Array.from(this.clients.values());
    const client = clients[this.currentIndex % clients.length];
    this.currentIndex++;
    return client;
  }

  async sendMessage(message, phoneNumber) {
    const client = this.getNextClient();
    return await client.sendMessage(phoneNumber, message);
  }
}
```

### Load Balancing
```yaml
# fly.toml
[vm]
  memory = "2gb"
  cpu_kind = "shared"
  cpus = 2

[[services]]
  internal_port = 3000
  protocol = "tcp"
  
  # Multiple instances
  [[services.concurrency]]
    type = "requests"
    soft_limit = 100
    hard_limit = 200
```

---

## 🎓 Best Practices

### 1. Message Templates
```javascript
const messageTemplates = {
  attendance: (data) => `✅ Attendance Marked
Hello ${data.parentName},
Your child ${data.studentName} from ${data.className} has been marked PRESENT for ${data.subject}.
Date: ${new Date().toLocaleDateString()}
Time: ${new Date().toLocaleTimeString()}

Best regards,
${data.schoolName}`,

  payment: (data) => `💰 Payment Received
Dear ${data.parentName},
Payment of Rs.${data.amount} has been received for ${data.studentName}.
Month: ${data.month} ${data.year}
Receipt #: ${data.receiptId}

Thank you!
${data.schoolName}`,

  reminder: (data) => `⏰ Fee Reminder
Dear ${data.parentName},
Friendly reminder: Fee payment for ${data.studentName} is due.
Amount: Rs.${data.amount}
Due Date: ${data.dueDate}

Please pay at your earliest convenience.
${data.schoolName}`
};
```

### 2. Error Handling
```javascript
class WhatsAppError extends Error {
  constructor(message, code, phoneNumber) {
    super(message);
    this.code = code;
    this.phoneNumber = phoneNumber;
    this.timestamp = new Date().toISOString();
  }
}

async function sendMessageWithRetry(phoneNumber, message, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await sendMessage(phoneNumber, message);
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
    }
  }
}
```

### 3. Logging and Analytics
```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'whatsapp.log' }),
    new winston.transports.Console()
  ]
});

function logMessage(phoneNumber, message, status) {
  logger.info({
    type: 'whatsapp_message',
    phoneNumber: phoneNumber.replace(/\d{4}$/, 'XXXX'), // Privacy
    messageLength: message.length,
    status: status,
    timestamp: new Date().toISOString()
  });
}
```

---

## 🚨 Important Disclaimers

### Legal and Compliance
1. **WhatsApp Terms of Service**: This method violates WhatsApp's ToS
2. **Data Protection**: Ensure GDPR/local compliance for parent data
3. **Consent**: Get explicit consent before sending messages
4. **Business Use**: Not recommended for commercial operations

### Technical Limitations
1. **Account Bans**: WhatsApp may ban your number without warning
2. **Message Limits**: Unofficial rate limits may apply
3. **Reliability**: Service may break with WhatsApp updates
4. **Support**: No official support from WhatsApp

### Recommendations
- **Use for prototyping only**
- **Migrate to official API for production**
- **Have backup communication methods**
- **Monitor for account bans regularly**

---

## 🆘 Support and Resources

### Documentation
- [whatsapp-web.js Documentation](https://wwebjs.dev/)
- [n8n Documentation](https://docs.n8n.io/)
- [fly.io Documentation](https://fly.io/docs/)
- [WhatsApp Business API](https://developers.facebook.com/docs/whatsapp)

### Community Support
- [whatsapp-web.js Discord](https://discord.gg/wyKybbF)
- [n8n Community Forum](https://community.n8n.io/)
- [fly.io Community](https://community.fly.io/)

### Professional Alternatives
- [Twilio WhatsApp API](https://www.twilio.com/whatsapp)
- [MessageBird WhatsApp API](https://messagebird.com/channels/whatsapp-business)
- [360Dialog WhatsApp API](https://www.360dialog.com/)

---

## 📝 Conclusion

This guide provides a comprehensive setup for WhatsApp notifications using unofficial methods. While technically feasible and cost-effective, it comes with significant risks and limitations.

### For Development/Testing: ✅ Recommended
- Quick setup and testing
- Cost-effective proof of concept
- Learning experience

### For Production: ❌ Not Recommended
- High risk of service interruption
- Terms of Service violations
- Unreliable for critical communications

### Next Steps:
1. Set up the development environment following this guide
2. Test with a small group of users
3. Plan migration to official WhatsApp Business API
4. Implement proper monitoring and backup strategies

Remember: **Always have a fallback communication method (SMS, email) for critical notifications.**

---

*Last updated: August 2025*
*Version: 1.0*