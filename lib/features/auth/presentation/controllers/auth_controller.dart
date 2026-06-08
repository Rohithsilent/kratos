import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/user_model.dart';

final authControllerProvider = AsyncNotifierProvider.autoDispose<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No initialization needed
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).signInWithEmailAndPassword(email, password));
  }

  String? _verificationId;
  int? _resendToken;

  Future<void> verifyPhoneNumber(String phone) async {
    state = const AsyncValue.loading();
    try {
      // Assuming 10-digit number is an Indian number for this implementation
      final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';
      await ref.read(authRepositoryProvider).verifyPhoneNumber(
        phoneNumber: formattedPhone,
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          state = const AsyncValue.data(null);
        },
        verificationFailed: (e) {
          state = AsyncValue.error(e, StackTrace.current);
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> verifyOTP(String smsCode) async {
    if (_verificationId == null) {
      state = AsyncValue.error(Exception('Verification ID is missing. Request a new code.'), StackTrace.current);
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).verifyOTP(_verificationId!, smsCode));
  }

  Future<void> signInWithGoogle({bool isLogin = false, UserModel? onboardingData}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).signInWithGoogle(isLogin: isLogin, onboardingData: onboardingData));
  }

  Future<void> registerWithEmail(String email, String password, UserModel userData) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).registerWithEmail(email, password, userData));
  }

  Future<void> sendEmailVerification() async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).sendEmailVerification());
  }

  Future<bool> checkEmailVerified() async {
    state = AsyncValue.loading();
    bool isVerified = false;
    state = await AsyncValue.guard(() async {
      isVerified = await ref.read(authRepositoryProvider).checkEmailVerified();
    });
    return isVerified;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).sendPasswordResetEmail(email));
  }

  Future<void> signOut() async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).signOut());
  }
}
