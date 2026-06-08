import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/animated_gradient_bg.dart';
import '../../shared/widgets/glass_text_field.dart';
import '../../shared/widgets/continue_button.dart';
import 'presentation/controllers/auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  late AnimationController _enterController;

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
    _emailController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    ref.listen<AsyncValue<void>>(authControllerProvider, (_, state) {
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else if (!state.isLoading && state.hasValue) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent. Please check your inbox.'),
            backgroundColor: context.colors.primary,
          ),
        );
        context.pop();
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: AnimatedGradientBackground(
        showParticles: false,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),

                  // Back button
                  _animatedEntry(
                    delay: 0.0,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.06),
                        padding: EdgeInsets.all(12),
                      ),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Title
                  _animatedEntry(
                    delay: 0.1,
                    child: Text(
                      'Reset Password',
                      style: AppTypography.display.copyWith(
                        color: Colors.white,
                        fontSize: 42,
                      ),
                    ),
                  ),

                  SizedBox(height: 16),
                  
                  _animatedEntry(
                    delay: 0.15,
                    child: Text(
                      'Enter your email address to receive a password reset link.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: context.customColors.grey400,
                      ),
                    ),
                  ),

                  SizedBox(height: 40),

                  // Email
                  _animatedEntry(
                    delay: 0.2,
                    child: GlassTextField(
                      hintText: 'Email address',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icon(
                        Icons.mail_outline_rounded,
                        color: context.customColors.grey500,
                        size: 20,
                      ),
                    ),
                  ),

                  SizedBox(height: 40),

                  // Reset button
                  _animatedEntry(
                    delay: 0.3,
                    child: ContinueButton(
                      text: isLoading ? 'Sending...' : 'Send Reset Link',
                      onPressed: isLoading
                          ? () {}
                          : () {
                              final email = _emailController.text.trim();
                              if (email.isEmpty) return;
                              
                              ref
                                  .read(authControllerProvider.notifier)
                                  .sendPasswordResetEmail(email);
                            },
                    ),
                  ),
                ],
              ),
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
