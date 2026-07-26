import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/animated_gradient_bg.dart';
import '../../shared/widgets/continue_button.dart';
import 'presentation/controllers/auth_controller.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _enterController;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  Future<void> _openEmailApp() async {
  try {
    if (Platform.isAndroid) {
      // Direct OS-level intent targeting the installed Gmail App's Main Launcher Activity
      final AndroidIntent intent = const AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.LAUNCHER',
        package: 'com.google.android.gm',
      );
      await intent.launch();
      return;
    } else if (Platform.isIOS) {
      final Uri iosGmailScheme = Uri.parse('googlegmail:///');
      if (await canLaunchUrl(iosGmailScheme)) {
        await launchUrl(iosGmailScheme, mode: LaunchMode.externalApplication);
        return;
      }
    }
  } catch (e) {
    debugPrint('Native launch failed: $e');
  }

  // Fallback snackbar if the launch fails
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Could not open the Gmail App.'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    
    final isVerified = await ref.read(authControllerProvider.notifier).checkEmailVerified();
    
    if (mounted) {
      setState(() => _isChecking = false);
      if (isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: context.colors.primary,
          ),
        );
        context.go('/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email is not verified yet. Please check your inbox.'),
            backgroundColor: context.customColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading || _isChecking;

    return Scaffold(
      body: AnimatedGradientBackground(
        showParticles: true,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Spacer(flex: 2),

                _animatedEntry(
                  delay: 0.1,
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.primary.withOpacity(0.1),
                      border: Border.all(
                        color: context.colors.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.mark_email_unread_rounded,
                      size: 64,
                      color: context.colors.primary,
                    ),
                  ),
                ),

                SizedBox(height: 32),

                _animatedEntry(
                  delay: 0.2,
                  child: Text(
                    'Verify your email',
                    style: AppTypography.display.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 16),

                _animatedEntry(
                  delay: 0.3,
                  child: Text(
                    'We\'ve sent a verification link to your email address. Please verify your email to access your account.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: context.customColors.grey400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                Spacer(flex: 2),

                _animatedEntry(
                  delay: 0.4,
                  child: ContinueButton(
                    text: 'Open Email App',
                    onPressed: _openEmailApp,
                  ),
                ),

                SizedBox(height: 16),

                _animatedEntry(
                  delay: 0.5,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.primary,
                      side: BorderSide(color: context.colors.primary),
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: isLoading ? null : _checkVerification,
                    child: Text(isLoading ? 'Checking...' : 'Refresh Status'),
                  ),
                ),

                SizedBox(height: 24),

                _animatedEntry(
                  delay: 0.6,
                  child: TextButton(
                    onPressed: isLoading ? null : () {
                      ref.read(authControllerProvider.notifier).sendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Verification email resent.'),
                          backgroundColor: context.colors.primary,
                        ),
                      );
                    },
                    child: Text(
                      'Resend Verification Email',
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                _animatedEntry(
                  delay: 0.7,
                  child: TextButton(
                    onPressed: isLoading ? null : () {
                      ref.read(authControllerProvider.notifier).signOut();
                    },
                    child: Text(
                      'Sign Out',
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.customColors.grey500,
                      ),
                    ),
                  ),
                ),

                Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _animatedEntry({required double delay, required Widget child}) {
    final begin = delay;
    final end = (delay + 0.3).clamp(0.0, 1.0);
    return SlideTransition(
      position: Tween<Offset>(begin: Offset(0, 0.15), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _enterController,
              curve: Interval(begin, end, curve: Curves.easeOutCubic),
            ),
          ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _enterController,
            curve: Interval(begin, end, curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }
}
