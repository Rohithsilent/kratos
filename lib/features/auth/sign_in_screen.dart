import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/animated_gradient_bg.dart';
import '../../shared/widgets/glass_text_field.dart';
import '../../shared/widgets/social_auth_button.dart';
import '../../shared/widgets/continue_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'presentation/controllers/auth_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

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
    _passwordController.dispose();
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
                      AppStrings.welcomeBack,
                      style: AppTypography.display.copyWith(
                        color: AppColors.white,
                        fontSize: 42,
                      ),
                    ),
                  ),

                  SizedBox(height: 40),

                  // Email
                  _animatedEntry(
                    delay: 0.2,
                    child: GlassTextField(
                      hintText: '${AppStrings.email} or Phone',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icon(
                        Icons.mail_outline_rounded,
                        color: AppColors.grey500,
                        size: 20,
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Password
                  _animatedEntry(
                    delay: 0.3,
                    child: GlassTextField(
                      hintText: AppStrings.password,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.grey500,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.grey500,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  // Remember me + Forgot password
                  _animatedEntry(
                    delay: 0.35,
                    child: Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _rememberMe = !_rememberMe),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: _rememberMe
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _rememberMe
                                          ? AppColors.primary
                                          : AppColors.grey600,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: _rememberMe
                                      ? Icon(
                                          Icons.check,
                                          size: 14,
                                          color: AppColors.white,
                                        )
                                      : null,
                                ),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    AppStrings.rememberMe,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.grey400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            context.push('/forgot-password');
                          },
                          child: Text(
                            AppStrings.forgotPassword,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 28),

                  // Sign In button
                  _animatedEntry(
                    delay: 0.4,
                    child: ContinueButton(
                      text: isLoading ? 'Signing In...' : AppStrings.signIn,
                      onPressed: isLoading
                          ? () {}
                          : () {
                              final identifier = _emailController.text.trim();
                              final password = _passwordController.text;
                              if (identifier.isEmpty) {
                                return;
                              }

                              final isPhone = RegExp(
                                r'^\d{10}$',
                              ).hasMatch(identifier);
                              
                              if (isPhone) {
                                ref
                                    .read(authControllerProvider.notifier)
                                    .verifyPhoneNumber(identifier);
                                _showOTPDialog(context, ref);
                              } else {
                                if (password.isEmpty) return;
                                ref
                                    .read(authControllerProvider.notifier)
                                    .signInWithEmail(identifier, password);
                              }
                            },
                    ),
                  ),

                  SizedBox(height: 28),

                  // Divider
                  _animatedEntry(
                    delay: 0.45,
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(color: Colors.white.withOpacity(0.08)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.grey500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Colors.white.withOpacity(0.08)),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 28),

                  // Social buttons
                  _animatedEntry(
                    delay: 0.5,
                    child: SocialAuthButton(
                      label: AppStrings.continueWithGoogle,
                      icon: Icons.g_mobiledata_rounded,
                      onPressed: isLoading
                          ? () {}
                          : () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .signInWithGoogle(isLogin: true);
                            },
                    ),
                  ),

                  SizedBox(height: 12),

                  _animatedEntry(
                    delay: 0.55,
                    child: SocialAuthButton(
                      label: AppStrings.continueWithApple,
                      icon: Icons.apple_rounded,
                      onPressed: () {},
                    ),
                  ),

                  SizedBox(height: 32),

                  // Register link
                  _animatedEntry(
                    delay: 0.6,
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          context.replace('/onboarding');
                        },
                        child: RichText(
                          text: TextSpan(
                            text: AppStrings.noAccount,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.grey400,
                            ),
                            children: [
                              TextSpan(
                                text: AppStrings.register,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
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

  void _showOTPDialog(BuildContext context, WidgetRef ref) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Enter OTP',
            style: AppTypography.headlineSmall.copyWith(color: AppColors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please enter the 6-digit code sent to your phone.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.grey400),
              ),
              SizedBox(height: 16),
              GlassTextField(
                controller: otpController,
                hintText: '000000',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: AppColors.grey400)),
            ),
            TextButton(
              onPressed: () {
                final code = otpController.text.trim();
                if (code.length == 6) {
                  Navigator.of(context).pop();
                  ref.read(authControllerProvider.notifier).verifyOTP(code);
                }
              },
              child: Text('Verify', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }
}
