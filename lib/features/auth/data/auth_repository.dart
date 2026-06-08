import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/providers/firebase_providers.dart';
import '../domain/models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _updateLastLogin(_auth.currentUser?.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during sign in.');
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(FirebaseAuthException) verificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
          await _updateLastLogin(_auth.currentUser?.uid);
        } catch (_) {}
      },
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserCredential> verifyOTP(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        final user = userCredential.user;
        if (user != null) {
          final newUser = UserModel(
            uid: user.uid,
            name: '',
            email: '',
            phone: user.phoneNumber ?? '',
            dob: '',
            sex: '',
            height: '',
            weight: '',
            profileImage: '',
            authProvider: 'phone',
            onboardingCompleted: false, // Force them to complete onboarding
            emailVerified: false,
            createdAt: DateTime.now().toIso8601String(),
            lastLogin: DateTime.now().toIso8601String(),
          );
          await saveUserData(newUser);
        }
      } else {
        await _updateLastLogin(userCredential.user?.uid);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Invalid verification code.');
    }
  }


  Future<UserCredential?> signInWithGoogle({bool isLogin = false, UserModel? onboardingData}) async {
    try {
      // Ensure any previous session is cleared to force the account picker
      try {
        await _googleSignIn.disconnect();
      } catch (_) {}
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // google_sign_in v7.x: use authenticate() instead of signIn()
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled by the user.');
      }

      // If they are logging in, verify the user exists in Firestore BEFORE authenticating with Firebase
      // to prevent the app router from instantly redirecting to the dashboard on an auth state change.
      if (isLogin && googleUser.email.isNotEmpty) {
        final querySnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: googleUser.email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          await _googleSignIn.signOut();
          throw Exception('No registered user found with this Google account. Please sign up first.');
        }
      }

      // v7.x: get idToken via the authentication property
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase Auth only needs the idToken for Google credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Check if new user to create profile
      if (userCredential.additionalUserInfo?.isNewUser == true) {

        final user = userCredential.user;
        if (user != null) {
          final newUser = UserModel(
            uid: user.uid,
            name: onboardingData?.name ?? user.displayName ?? '',
            email: onboardingData?.email ?? user.email ?? '',
            phone: onboardingData?.phone ?? user.phoneNumber ?? '',
            dob: onboardingData?.dob ?? '',
            sex: onboardingData?.sex ?? '',
            height: onboardingData?.height ?? '',
            weight: onboardingData?.weight ?? '',
            profileImage: user.photoURL ?? '',
            authProvider: 'google',
            onboardingCompleted: true, // We assume if they passed onboardingData, they completed it. If not, they skipped it somehow but we default to true to maintain previous behavior (or we can use onboardingData != null). Let's use true for now as they've gone through the flow.
            emailVerified: true,
            createdAt: DateTime.now().toIso8601String(),
            lastLogin: DateTime.now().toIso8601String(),
          );
          await saveUserData(newUser);
        }
      } else {
        await _updateLastLogin(userCredential.user?.uid);
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception(e.toString().contains('Google') ? e.toString().replaceAll('Exception: ', '') : 'Failed to sign in with Google.');
    }
  }

  Future<void> registerWithEmail(String email, String password, UserModel userData) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user != null) {
        final finalUserData = userData.copyWith(
          uid: user.uid,
          authProvider: 'email',
          createdAt: DateTime.now().toIso8601String(),
          lastLogin: DateTime.now().toIso8601String(),
          onboardingCompleted: true,
          emailVerified: false,
        );
        await saveUserData(finalUserData);
        print("AuthRepository: Attempting to send verification email to ${user.email}");
        try {
          await user.sendEmailVerification();
          print("AuthRepository: Successfully sent verification email.");
        } catch (e) {
          print("AuthRepository: Failed to send verification email. Error: $e");
          // Re-throwing might block the registration flow from fully succeeding in UI if email fails.
          // Usually we just ignore it or log it.
        }
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during registration.');
    }
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found for that email.');
      case 'wrong-password':
        return Exception('Wrong password provided for that user.');
      case 'invalid-email':
        return Exception('The email address is badly formatted.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      case 'email-already-in-use':
        return Exception('The account already exists for that email.');
      case 'operation-not-allowed':
        return Exception('Operation not allowed.');
      case 'weak-password':
        return Exception('The password provided is too weak.');
      case 'invalid-credential':
        return Exception('Invalid login credentials provided.');
      case 'invalid-verification-code':
        return Exception('The verification code from SMS/TOTP is invalid.');
      case 'invalid-verification-id':
        return Exception('The verification ID from SMS/TOTP is invalid.');
      default:
        return Exception('Authentication failed. Please try again.');
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    print("AuthRepository: Attempting to resend verification email to ${user?.email}");
    try {
      await user?.sendEmailVerification();
      print("AuthRepository: Successfully resent verification email.");
    } catch (e) {
      print("AuthRepository: Failed to resend verification email. Error: $e");
      rethrow;
    }
  }

  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        await _firestore.collection('users').doc(user.uid).update({'emailVerified': true});
        return true;
      }
    }
    return false;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> saveUserData(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toJson(), SetOptions(merge: true));
  }

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> _updateLastLogin(String? uid) async {
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'lastLogin': DateTime.now().toIso8601String(),
      }).catchError((_) {
        // Ignore errors if the document doesn't exist yet
      });
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
