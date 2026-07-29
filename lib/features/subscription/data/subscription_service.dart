import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/subscription_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final subscriptionServiceProvider = Provider((ref) {
  return SubscriptionService(
    firestore: ref.watch(firestoreProvider),
  );
});

final currentSubscriptionProvider = StreamProvider<SubscriptionModel?>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) {
    return Stream.value(null);
  }
  final service = ref.watch(subscriptionServiceProvider);
  return service.getSubscriptionStream(user.uid);
});

class SubscriptionService {
  final FirebaseFirestore _firestore;

  SubscriptionService({required FirebaseFirestore firestore}) : _firestore = firestore;

  Stream<SubscriptionModel?> getSubscriptionStream(String uid) {
    return _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      // Taking the most recently updated subscription if multiple exist
      final docs = snapshot.docs.toList()
        ..sort((a, b) {
          final aTime = (a.data()['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bTime = (b.data()['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
        });
      
      return SubscriptionModel.fromJson(docs.first.data());
    });
  }
  
  bool isPlanPro(String planId) {
    return planId == dotenv.env['RAZORPAY_PLAN_PRO_MONTHLY'] || 
           planId == dotenv.env['RAZORPAY_PLAN_PRO_YEARLY'];
  }

  bool isPlanPremium(String planId) {
    return planId == dotenv.env['RAZORPAY_PLAN_PREMIUM_MONTHLY'] || 
           planId == dotenv.env['RAZORPAY_PLAN_PREMIUM_YEARLY'];
  }
}
