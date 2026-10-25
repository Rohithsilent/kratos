/// Build-time configuration for the payment integration.
///
/// None of these values is a server secret. The Razorpay secret and webhook
/// secret remain only in the payment backend. Empty defaults intentionally
/// disable checkout rather than sending a production build to localhost.
class SubscriptionConstants {
  static const String backendUrl = String.fromEnvironment(
    'RAZORPAY_BACKEND_URL',
    defaultValue: '',
  );
  static const String keyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: '',
  );
  static const String proMonthlyPlanId = String.fromEnvironment(
    'RAZORPAY_PLAN_PRO_MONTHLY',
    defaultValue: '',
  );
  static const String proYearlyPlanId = String.fromEnvironment(
    'RAZORPAY_PLAN_PRO_YEARLY',
    defaultValue: '',
  );
  static const String premiumMonthlyPlanId = String.fromEnvironment(
    'RAZORPAY_PLAN_PREMIUM_MONTHLY',
    defaultValue: '',
  );
  static const String premiumYearlyPlanId = String.fromEnvironment(
    'RAZORPAY_PLAN_PREMIUM_YEARLY',
    defaultValue: '',
  );

  static bool get isCheckoutConfigured =>
      backendUrl.isNotEmpty &&
      keyId.isNotEmpty &&
      proMonthlyPlanId.isNotEmpty &&
      proYearlyPlanId.isNotEmpty &&
      premiumMonthlyPlanId.isNotEmpty &&
      premiumYearlyPlanId.isNotEmpty;
}
