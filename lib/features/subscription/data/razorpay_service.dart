import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/constants/subscription_constants.dart';

final razorpayServiceProvider = Provider((ref) {
  return RazorpayService(
    auth: ref.watch(firebaseAuthProvider),
  );
});

class RazorpayService {
  final FirebaseAuth _auth;
  late Razorpay _razorpay;

  static String get backendUrl => SubscriptionConstants.backendUrl;

  Function(String)? onPaymentSuccessCallback;
  Function(String)? onPaymentErrorCallback;
  
  RazorpayService({required FirebaseAuth auth}) : _auth = auth {
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
      if (!SubscriptionConstants.isCheckoutConfigured) {
        onPaymentErrorCallback?.call(
          'Subscriptions are not configured in this build. Please contact support.',
        );
        return;
      }
      final user = _auth.currentUser;
      if (user == null) {
        if (onPaymentErrorCallback != null) {
          onPaymentErrorCallback!('User not authenticated.');
        }
        return;
      }
      
      final idToken = await user.getIdToken();
      if (idToken == null) {
         if (onPaymentErrorCallback != null) {
          onPaymentErrorCallback!('Authentication error. Please sign in again.');
        }
        return;
      }

      // 1. Call your backend to generate a Razorpay Subscription ID
      final response = await http.post(
        Uri.parse('$backendUrl/api/create-subscription'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'plan_id': planId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final subscriptionId = data['id']; // Razorpay returns 'id', not 'subscription_id'

        // 2. Open Razorpay Checkout using the subscription_id
        var options = {
          'key': SubscriptionConstants.keyId,
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
        print('Backend Error: ${response.statusCode} - ${response.body}');
        if (onPaymentErrorCallback != null) {
          onPaymentErrorCallback!('Failed to start subscription. Please try again. (${response.statusCode})');
        }
      }
    } catch (e) {
      print('Razorpay Subscription Error: $e');
      if (onPaymentErrorCallback != null) {
        onPaymentErrorCallback!('Network error: Unable to connect to payment server. Details: $e');
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
