const express = require('express');
const Razorpay = require('razorpay');
const crypto = require('crypto');
const admin = require('firebase-admin');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Simple health check for the Vercel preview window
app.get('/', (req, res) => {
  res.status(200).send('Kratos Backend is running perfectly! 🚀');
});

// Initialize Firebase Admin (Only initialize once)
if (!admin.apps?.length) {
  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
      
      // Fix for Vercel: Unescape literal \n characters to actual newlines
      if (serviceAccount.private_key) {
        serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
      }

      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
    } else {
      console.warn("FIREBASE_SERVICE_ACCOUNT_KEY is missing. Database operations will fail.");
    }
  } catch (error) {
    console.error("Firebase Admin initialization failed. Ensure FIREBASE_SERVICE_ACCOUNT_KEY is set correctly.", error);
  }
}

const db = admin.apps?.length ? admin.firestore() : null;

// Initialize Razorpay
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || 'rzp_test_placeholder',
  key_secret: process.env.RAZORPAY_KEY_SECRET || 'placeholder',
});

// Middleware to validate Firebase ID Token
const validateFirebaseIdToken = async (req, res, next) => {
  if ((!req.headers.authorization || !req.headers.authorization.startsWith('Bearer '))) {
    console.error('No Firebase ID token was passed as a Bearer token in the Authorization header.');
    res.status(401).send({ error: 'Unauthorized: No token provided' });
    return;
  }

  const idToken = req.headers.authorization.split('Bearer ')[1];

  try {
    const decodedIdToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedIdToken;
    next();
  } catch (error) {
    console.error('Error while verifying Firebase ID token:', error);
    res.status(401).send({ error: 'Unauthorized: Invalid token' });
  }
};

// Endpoint to create a subscription (Protected)
app.post('/api/create-subscription', validateFirebaseIdToken, async (req, res) => {
  try {
    const { plan_id } = req.body;
    const uid = req.user.uid; // Securely obtained from token

    if (!plan_id) {
      return res.status(400).json({ error: 'plan_id is required' });
    }

    // Determine if the plan is yearly to safely calculate the maximum allowed billing cycles
    const isYearly = (plan_id === process.env.PLAN_PRO_YEARLY) || (plan_id === process.env.PLAN_PREMIUM_YEARLY);
    
    // Production Solution: Razorpay & UPI have a strict max expiry year of 2120.
    // 50 cycles for a Yearly plan = 50 years.
    // 600 cycles for a Monthly plan = 50 years. 
    // This gives the absolute maximum uninterrupted subscription life without crashing the bank APIs.
    const safeTotalCount = isYearly ? 50 : 600;

    // Create a subscription in Razorpay
    const subscription = await razorpay.subscriptions.create({
      plan_id: plan_id,
      total_count: safeTotalCount,
      customer_notify: 1, // Razorpay handles email notifications
      notes: {
        userId: uid, // VERY IMPORTANT: Pass the user ID so the webhook knows who paid!
      }
    });

    res.status(200).json(subscription);
  } catch (error) {
    console.error('Error creating Razorpay subscription:', error);
    res.status(500).json({ error: 'Failed to create subscription', details: error });
  }
});

// Webhook endpoint (Public, but secured via secret validation)
app.post('/api/webhook', async (req, res) => {
  // 1. Verify Webhook Signature
  const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
  const signature = req.headers['x-razorpay-signature'];
  const eventId = req.headers['x-razorpay-event-id'];
  const payload = req.body;

  if (!webhookSecret) {
    console.error('Missing RAZORPAY_WEBHOOK_SECRET in environment variables.');
    return res.status(500).json({ error: 'Server configuration error' });
  }

  const generatedSignature = crypto
    .createHmac('sha256', webhookSecret)
    .update(JSON.stringify(payload))
    .digest('hex');

  if (generatedSignature !== signature) {
    console.error('Invalid webhook signature!');
    return res.status(400).json({ error: 'Invalid signature' });
  }

  // 2. Idempotency Check (Prevent processing the same event twice)
  if (!db) {
    return res.status(500).json({ error: 'Database not initialized' });
  }

  const processedRef = db.collection('processed_webhooks').doc(eventId);
  const processedDoc = await processedRef.get();
  
  if (processedDoc.exists) {
    console.log(`Webhook ${eventId} already processed. Skipping.`);
    return res.status(200).json({ status: 'ok', message: 'Already processed' });
  }

  try {
    const event = payload.event;
    
    // 3. Log the webhook event for auditing
    await db.collection('payment_logs').add({
      eventId: eventId,
      event: event,
      payload: payload,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'received'
    });

    // 4. Process Subscription Events
    if (event.startsWith('subscription.')) {
      const subscriptionInfo = payload.payload.subscription.entity;
      const subId = subscriptionInfo.id;
      const planId = subscriptionInfo.plan_id;
      const uid = subscriptionInfo.notes?.userId;

      if (!uid) {
         console.error(`Received subscription event ${eventId} but no userId in notes!`);
         return res.status(400).json({ error: 'Missing userId in notes' });
      }

      const subRef = db.collection('subscriptions').doc(subId);
      
      const updateData = {
        userId: uid,
        planId: planId,
        provider: 'razorpay',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: subscriptionInfo.status
      };

      // Add start and end dates if available
      if (subscriptionInfo.start_at) {
         updateData.startDate = new Date(subscriptionInfo.start_at * 1000);
      }
      if (subscriptionInfo.current_end) {
         updateData.renewalDate = new Date(subscriptionInfo.current_end * 1000);
      }
      if (subscriptionInfo.charge_at) {
         updateData.nextChargeDate = new Date(subscriptionInfo.charge_at * 1000);
      }

      // If it's a successful charge, record the payment ID
      if (event === 'subscription.charged') {
         const paymentInfo = payload.payload.payment?.entity;
         if (paymentInfo) {
             updateData.lastPaymentId = paymentInfo.id;
         }
      }

      // Write to subscriptions collection
      await subRef.set(updateData, { merge: true });
    }

    if (event === 'payment.failed') {
        console.warn(`Payment failed for event ${eventId}`);
        // Additional handling for failed payments could go here
    }

    // Mark as processed
    await processedRef.set({
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
      event: event
    });

    res.status(200).json({ status: 'ok' });
  } catch (error) {
    console.error('Webhook Error:', error);
    // Return 500 so Razorpay retries the webhook
    res.status(500).json({ error: 'Webhook processing failed' });
  }
});

module.exports = app;
