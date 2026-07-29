const express = require('express');
const Razorpay = require('razorpay');
const crypto = require('crypto');
const { initializeApp, getApps, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
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
if (getApps().length === 0) {
  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
      initializeApp({
        credential: cert(serviceAccount)
      });
    } else {
      console.warn("FIREBASE_SERVICE_ACCOUNT_KEY is missing. Database operations will fail.");
    }
  } catch (error) {
    console.error("Firebase Admin initialization failed. Ensure FIREBASE_SERVICE_ACCOUNT_KEY is set correctly.", error);
  }
}

const db = getApps().length > 0 ? getFirestore() : null;
const auth = getApps().length > 0 ? getAuth() : null;

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
    const decodedIdToken = await auth.verifyIdToken(idToken);
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

    // Create a subscription in Razorpay
    const subscription = await razorpay.subscriptions.create({
      plan_id: plan_id,
      total_count: 1200, // A large number ensures it keeps renewing indefinitely
      customer_notify: 1, // Let Razorpay handle email notifications
      notes: {
        uid: uid // Attach user ID so we know who is paying inside the webhook
      }
    });

    res.json({
      subscription_id: subscription.id
    });
  } catch (error) {
    console.error('Error creating subscription:', error);
    res.status(500).json({ error: 'Failed to create subscription', details: error.message });
  }
});

// Razorpay Webhook Endpoint
app.post('/api/webhook', async (req, res) => {
  try {
    const secret = process.env.RAZORPAY_WEBHOOK_SECRET;

    if (!secret) {
      console.error('Webhook secret not configured on server');
      return res.status(500).json({ error: 'Webhook secret not configured on server' });
    }

    if (!db) {
      console.error('Firestore is not initialized.');
      return res.status(500).json({ error: 'Database error' });
    }

    // Verify signature
    const signature = req.headers['x-razorpay-signature'];
    const eventId = req.headers['x-razorpay-event-id'];
    
    if (!signature || !eventId) {
        return res.status(400).json({ error: 'Missing headers' });
    }

    const expectedSignature = crypto
      .createHmac('sha256', secret)
      .update(JSON.stringify(req.body))
      .digest('hex');

    if (expectedSignature !== signature) {
      console.error('Invalid webhook signature');
      return res.status(400).json({ error: 'Invalid signature' });
    }

    // Idempotency Check
    const processedRef = db.collection('processed_webhooks').doc(eventId);
    const doc = await processedRef.get();
    
    if (doc.exists) {
      console.log(`Webhook ${eventId} already processed. Skipping.`);
      return res.status(200).json({ status: 'ok', message: 'Already processed' });
    }

    const event = req.body.event;
    const payload = req.body.payload;

    // Log the event to payment_logs
    await db.collection('payment_logs').add({
      eventId: eventId,
      event: event,
      payload: payload,
      timestamp: FieldValue.serverTimestamp(),
      status: 'received'
    });

    // Process specific events
    let subscriptionInfo = null;
    let paymentInfo = null;
    
    if (payload.subscription && payload.subscription.entity) {
        subscriptionInfo = payload.subscription.entity;
    }
    
    if (payload.payment && payload.payment.entity) {
        paymentInfo = payload.payment.entity;
    }

    if (subscriptionInfo && subscriptionInfo.notes && subscriptionInfo.notes.uid) {
      const uid = subscriptionInfo.notes.uid;
      const planId = subscriptionInfo.plan_id;
      const subId = subscriptionInfo.id;
      
      const subRef = db.collection('subscriptions').doc(subId);
      
      let updateData = {
        subscriptionId: subId,
        userId: uid,
        planId: planId,
        provider: 'razorpay',
        updatedAt: FieldValue.serverTimestamp(),
        status: subscriptionInfo.status
      };

      if (event === 'subscription.activated') {
         updateData.startDate = new Date(subscriptionInfo.start_at * 1000);
         updateData.renewalDate = new Date(subscriptionInfo.charge_at * 1000);
      } else if (event === 'subscription.charged') {
         updateData.renewalDate = new Date(subscriptionInfo.charge_at * 1000);
         if (paymentInfo) {
             updateData.lastPaymentId = paymentInfo.id;
         }
      }

      // Write to subscriptions collection
      await subRef.set(updateData, { merge: true });
      
      // Update the user's tier for convenience if needed, though single source of truth is subscriptions collection.
      // We'll update a 'hasActiveSubscription' flag on the user.
      if (['active', 'authenticated'].includes(subscriptionInfo.status)) {
         await db.collection('users').doc(uid).update({
             hasActiveSubscription: true,
             currentSubscriptionId: subId
         }).catch(err => console.warn('Failed to update user doc:', err));
      } else if (['halted', 'cancelled', 'completed'].includes(subscriptionInfo.status)) {
         await db.collection('users').doc(uid).update({
             hasActiveSubscription: false
         }).catch(err => console.warn('Failed to update user doc:', err));
      }
    }

    if (event === 'payment.failed') {
        console.warn(`Payment failed for event ${eventId}`);
        // Additional handling for failed payments could go here (e.g., email notification)
    }

    // Mark as processed
    await processedRef.set({
      processedAt: FieldValue.serverTimestamp(),
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
