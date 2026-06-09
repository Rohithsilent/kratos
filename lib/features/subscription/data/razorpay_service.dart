import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Function(String)? onPaymentSuccessCallback;
  Function(String)? onPaymentErrorCallback;
  
  String? _pendingTier;

  RazorpayService({required FirebaseFirestore firestore, required FirebaseAuth auth})
      : _firestore = firestore,
        _auth = auth {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openCheckout({
    required int amountInPaise,
    required String tierName,
    required String name,
    required String description,
    required String contact,
    required String email,
  }) {
    _pendingTier = tierName;
    var options = {
      'key': 'rzp_test_YourTestKeyHere', // TODO: Replace with actual Razorpay test key
      'amount': amountInPaise,
      'name': name,
      'description': description,
      'prefill': {
        'contact': contact,
        'email': email,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      if (onPaymentErrorCallback != null) {
        onPaymentErrorCallback!(e.toString());
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = _auth.currentUser;
    if (user != null && _pendingTier != null) {
      try {
        // Calculate expiry date
        DateTime now = DateTime.now();
        DateTime expiry;
        if (_pendingTier == 'pro') {
          expiry = DateTime(now.year, now.month + 1, now.day);
        } else if (_pendingTier == 'premium') {
          expiry = DateTime(now.year + 1, now.month, now.day);
        } else {
          expiry = now;
        }

        // Update user document
        await _firestore.collection('users').doc(user.uid).update({
          'subscriptionTier': _pendingTier,
          'subscriptionExpiry': expiry.toIso8601String(),
        });

        if (onPaymentSuccessCallback != null) {
          onPaymentSuccessCallback!('Successfully upgraded to $_pendingTier!');
        }
      } catch (e) {
        if (onPaymentErrorCallback != null) {
          onPaymentErrorCallback!('Failed to update subscription status.');
        }
      }
    }
    _pendingTier = null;
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (onPaymentErrorCallback != null) {
      onPaymentErrorCallback!(response.message ?? 'Payment failed.');
    }
    _pendingTier = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (onPaymentErrorCallback != null) {
      onPaymentErrorCallback!('External wallets not supported currently.');
    }
    _pendingTier = null;
  }

  void dispose() {
    _razorpay.clear();
  }
}
