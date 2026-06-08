import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/animated_gradient_bg.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/continue_button.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _cardController;

  late Animation<double> _logoFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleFade;
  late Animation<Offset> _cardsSlide;
  late Animation<double> _cardsFade;
  late Animation<Offset> _ctaSlide;
  late Animation<double> _ctaFade;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2200),
    );
    _cardController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // Staggered entrance animations
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Interval(0.0, 0.3, curve: Curves.easeOut)),
    );
    _titleSlide = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Interval(0.15, 0.45, curve: Curves.easeOutCubic)),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Interval(0.15, 0.45, curve: Curves.easeOut)),
    );
    _subtitleSlide = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Interval(0.3, 0.6, curve: Curves.easeOutCubic)),
    );
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Interval(0.3, 0.6, curve: Curves.easeOut)),
    );
    _cardsSlide = Tween<Offset>(begin: Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Interval(0.45, 0.75, curve: Curves.easeOutCubic)),
    );
    _cardsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Interval(0.45, 0.75, curve: Curves.easeOut)),
    );
    _ctaSlide = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Interval(0.6, 0.9, curve: Curves.easeOutCubic)),
    );
    _ctaFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Interval(0.6, 0.9, curve: Curves.easeOut)),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _navigateToRegister() {
    context.push('/onboarding');
  }

  void _navigateToSignIn() {
    context.push('/signin');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: AnimatedGradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ─── Top Section ───
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Spacer(flex: 2),

                      // Logo
                      FadeTransition(
                        opacity: _logoFade,
                        child: Text(
                          AppStrings.appName,
                          style: AppTypography.display.copyWith(
                            color: AppColors.primary,
                            fontSize: 56,
                            letterSpacing: 12,
                          ),
                        ),
                      ),
                      SizedBox(height: 32),

                      // Headline
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleFade,
                          child: Text(
                            AppStrings.appTagline,
                            textAlign: TextAlign.center,
                            style: AppTypography.headlineLarge.copyWith(
                              color: AppColors.white,
                              fontSize: 34,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Subtitle
                      SlideTransition(
                        position: _subtitleSlide,
                        child: FadeTransition(
                          opacity: _subtitleFade,
                          child: Text(
                            AppStrings.appDescription,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.grey400,
                              height: 1.7,
                            ),
                          ),
                        ),
                      ),

                      Spacer(),

                      // Floating stat cards
                      SlideTransition(
                        position: _cardsSlide,
                        child: FadeTransition(
                          opacity: _cardsFade,
                          child: AnimatedBuilder(
                            animation: _cardController,
                            builder: (context, _) {
                              final offset = _cardController.value * 6 - 3;
                              return Transform.translate(
                                offset: Offset(0, offset),
                                child: Row(
                                  children: [
                                    Expanded(child: _StatCard(value: AppStrings.cardWarriors, label: AppStrings.cardWarriorsLabel)),
                                    SizedBox(width: 10),
                                    Expanded(child: _StatCard(value: AppStrings.cardWorkouts, label: AppStrings.cardWorkoutsLabel)),
                                    SizedBox(width: 10),
                                    Expanded(child: _StatCard(value: AppStrings.cardTransformations, label: AppStrings.cardTransformationsLabel)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      Spacer(),
                    ],
                  ),
                ),
              ),

              // ─── Bottom CTA Section ───
              SlideTransition(
                position: _ctaSlide,
                child: FadeTransition(
                  opacity: _ctaFade,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(24, 28, 24, bottomPadding + 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                          border: Border(
                            top: BorderSide(color: Colors.white.withOpacity(0.08)),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ContinueButton(
                              text: AppStrings.getStarted,
                              onPressed: _navigateToRegister,
                              icon: Icons.arrow_forward_rounded,
                            ),
                            SizedBox(height: 14),
                            TextButton(
                              onPressed: _navigateToSignIn,
                              child: RichText(
                                text: TextSpan(
                                  text: AppStrings.alreadyHaveAccount,
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.grey400),
                                  children: [
                                    TextSpan(
                                      text: ' ${AppStrings.signIn}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      borderRadius: 18,
      child: Column(
        children: [
          Text(value, style: AppTypography.headlineSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.grey400), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
