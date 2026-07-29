import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String subscriptionId;
  final String userId;
  final String planId;
  final String provider;
  final String status;
  final DateTime? startDate;
  final DateTime? renewalDate;
  final String? lastPaymentId;

  SubscriptionModel({
    required this.subscriptionId,
    required this.userId,
    required this.planId,
    required this.provider,
    required this.status,
    this.startDate,
    this.renewalDate,
    this.lastPaymentId,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      subscriptionId: json['subscriptionId'] ?? '',
      userId: json['userId'] ?? '',
      planId: json['planId'] ?? '',
      provider: json['provider'] ?? '',
      status: json['status'] ?? 'inactive',
      startDate: json['startDate'] != null ? (json['startDate'] as Timestamp).toDate() : null,
      renewalDate: json['renewalDate'] != null ? (json['renewalDate'] as Timestamp).toDate() : null,
      lastPaymentId: json['lastPaymentId'],
    );
  }

  bool get isActive => status == 'active' || status == 'authenticated';
  
  bool get isPro {
    if (!isActive) return false;
    // You should use the exact Razorpay plan IDs here or check the planId format
    return planId.contains('PRO') || planId.toLowerCase().contains('pro');
  }

  bool get isPremium {
    if (!isActive) return false;
    // You should use the exact Razorpay plan IDs here or check the planId format
    return planId.contains('PREMIUM') || planId.toLowerCase().contains('premium');
  }
}
