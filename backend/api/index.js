const express = require('express');
const Razorpay = require('razorpay');
const crypto = require('crypto');
const admin = require('firebase-admin');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin (Only initialize once)
if (!admin.apps.length) {
  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
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

const db = admin.apps.length ? admin.firestore() : null;

// Initialize Razorpay
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || 'rzp_test_placeholder',
  key_secret: process.env.RAZORPAY_KEY_SECRET || 'placeholder',
});

// Endpoint to create a subscription
app.post('/api/create-subscription', async (req, res) => {
  try {
    const { plan_id, uid } = req.body;

    if (!plan_id || !uid) {
      return res.status(400).json({ error: 'plan_id and uid are required' });
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
        return res.status(500).json({ error: 'Webhook secret not configured on server' });
    }

    // Verify signature
    const signature = req.headers['x-razorpay-signature'];
    const expectedSignature = crypto
      .createHmac('sha256', secret)
      .update(JSON.stringify(req.body))
      .digest('hex');

    if (expectedSignature === signature) {
      const event = req.body.event;

      if (event === 'subscription.charged') {
        const subscriptionInfo = req.body.payload.subscription.entity;
        const uid = subscriptionInfo.notes.uid;
        const planId = subscriptionInfo.plan_id;
        
        // Map planId to tier name
        let tier = 'base';
        if (planId === process.env.PLAN_PRO_MONTHLY || planId === process.env.PLAN_PRO_YEARLY) {
          tier = 'pro';
        } else if (planId === process.env.PLAN_PREMIUM_MONTHLY || planId === process.env.PLAN_PREMIUM_YEARLY) {
          tier = 'premium';
        }
        
        // Determine expiry date based on the next billing date from Razorpay
        const expiryDate = new Date(subscriptionInfo.charge_at * 1000);

        if (uid && db) {
          await db.collection('users').doc(uid).update({
            subscriptionTier: tier,
            subscriptionExpiry: expiryDate.toISOString(),
            razorpaySubscriptionId: subscriptionInfo.id,
            subscriptionStatus: subscriptionInfo.status
          });
        }
      }
      
      // Handle cancellation or halt
      if (event === 'subscription.halted' || event === 'subscription.cancelled') {
         const subscriptionInfo = req.body.payload.subscription.entity;
         const uid = subscriptionInfo.notes.uid;
         if (uid && db) {
             await db.collection('users').doc(uid).update({
                 subscriptionStatus: subscriptionInfo.status
             });
         }
      }

      res.status(200).json({ status: 'ok' });
    } else {
      res.status(400).json({ error: 'Invalid signature' });
    }
  } catch (error) {
    console.error('Webhook Error:', error);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
});

module.exports = app;
