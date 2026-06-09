import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/providers/firebase_providers.dart';

final razorpayServiceProvider = Provider((ref) {
  return RazorpayService(
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

class RazorpayService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  late Razorpay _razorpay;

  // IMPORTANT: Replace this with your actual deployed Vercel URL
  static const String backendUrl = 'https://your-vercel-app.vercel.app'; 

  Function(String)? onPaymentSuccessCallback;
  Function(String)? onPaymentErrorCallback;
  
  RazorpayService({required FirebaseFirestore firestore, required FirebaseAuth auth})
      : _firestore = firestore,
        _auth = auth {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> createSubscription({
    required String planId,
    required String uid,
    required String contact,
    required String email,
  }) async {
    try {
      // 1. Call your backend to generate a Razorpay Subscription ID
      final response = await http.post(
        Uri.parse('$backendUrl/api/create-subscription'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'plan_id': planId,
          'uid': uid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final subscriptionId = data['subscription_id'];

        // 2. Open Razorpay Checkout using the subscription_id
        var options = {
          'key': 'rzp_test_YourTestKeyHere', // TODO: Replace with your Razorpay Test Key
          'subscription_id': subscriptionId,
          'name': 'Kratos',
          'description': 'Kratos Subscription',
          'prefill': {
            'contact': contact,
            'email': email,
          },
        };

        _razorpay.open(options);
      } else {
        if (onPaymentErrorCallback != null) {
          onPaymentErrorCallback!('Failed to start subscription. Please try again.');
        }
      }
    } catch (e) {
      if (onPaymentErrorCallback != null) {
        onPaymentErrorCallback!('Network error: Unable to connect to payment server.');
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // The actual database upgrade is securely handled by your Vercel Webhook.
    // Here we just show a success message to the user.
    if (onPaymentSuccessCallback != null) {
      onPaymentSuccessCallback!('Payment successful! Your account is being upgraded...');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (onPaymentErrorCallback != null) {
      onPaymentErrorCallback!(response.message ?? 'Payment failed or cancelled.');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (onPaymentErrorCallback != null) {
      onPaymentErrorCallback!('External wallets not supported currently.');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
