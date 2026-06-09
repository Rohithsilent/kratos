import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/continue_button.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // ─── Animation Controllers ───
  late AnimationController _heroController;
  late AnimationController _glowPulseController;
  late AnimationController _scrollHintController;
  late AnimationController _shimmerController;

  // ─── Hero Animations ───
  late Animation<double> _glowExpand;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _brandReveal;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _scrollHintFade;

  // ─── Scroll Controller ───
  late ScrollController _scrollController;
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController()
      ..addListener(_onScroll);

    // Main hero entrance: 2.4s total choreography
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Continuous glow pulse behind helmet
    _glowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // Bouncing scroll indicator
    _scrollHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Shimmer across brand name
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // ── Staggered timeline ──

    // 0ms–600ms: Glow expands from center
    _glowExpand = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    // 200ms–800ms: Logo scales in
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.08, 0.35, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.08, 0.30, curve: Curves.easeOut),
      ),
    );

    // 600ms–1200ms: Brand name reveal
    _brandReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.25, 0.50, curve: Curves.easeOutCubic),
      ),
    );

    // 800ms–1400ms: Tagline slide + fade
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.35, 0.58, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.35, 0.58, curve: Curves.easeOutCubic),
      ),
    );

    // 1200ms–1800ms: Scroll indicator fades in
    _scrollHintFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.55, 0.75, curve: Curves.easeOut),
      ),
    );

    _heroController.forward();

    // Start shimmer after brand reveals
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) _shimmerController.forward();
    });
  }

  void _onScroll() {
    if (!mounted) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll > 0) {
      setState(() {
        _scrollProgress = (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
      });
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    _glowPulseController.dispose();
    _scrollHintController.dispose();
    _shimmerController.dispose();
    _scrollController.dispose();
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // ─── Scrollable Content ───
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ═══ SECTION 1: HERO ═══
              SliverToBoxAdapter(
                child: SizedBox(
                  height: screenHeight,
                  child: _buildHeroSection(screenWidth, screenHeight),
                ),
              ),

              // ═══ SECTION 2: FEATURE PILLARS ═══
              SliverToBoxAdapter(
                child: _buildFeatureSection(screenWidth),
              ),

              // ═══ Bottom spacer for CTA ═══
              SliverToBoxAdapter(
                child: SizedBox(height: 140 + bottomPadding),
              ),
            ],
          ),

          // ─── Fixed CTA at bottom ───
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildCTASection(bottomPadding),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  //  SECTION 1: HERO — Fullscreen cinematic entrance
  // ═════════════════════════════════════════════════════════════════
  Widget _buildHeroSection(double screenWidth, double screenHeight) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _heroController,
        _glowPulseController,
        _scrollHintController,
      ]),
      builder: (context, _) {
        final glowPulse = 0.8 + _glowPulseController.value * 0.2;
        final scrollBounce = _scrollHintController.value * 10;

        return Stack(
          alignment: Alignment.center,
          children: [
            // ── Background: Pure black ──
            Container(color: const Color(0xFF050505)),

            // ── Radial glow behind helmet ──
            Positioned(
              top: screenHeight * 0.18,
              child: Opacity(
                opacity: _glowExpand.value * 0.7,
                child: Container(
                  width: 340 * _glowExpand.value * glowPulse,
                  height: 340 * _glowExpand.value * glowPulse,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        context.colors.primary.withOpacity(0.25),
                        context.colors.primary.withOpacity(0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // ── Secondary ambient glow (bottom-left) ──
            Positioned(
              bottom: screenHeight * 0.25,
              left: -60,
              child: Opacity(
                opacity: _glowExpand.value * 0.3,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        context.colors.primary.withOpacity(0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Content column ──
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    // ── Spartan Helmet Logo ──
                    Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoFade.value,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: context.colors.primary
                                    .withOpacity(0.3 * _logoFade.value * glowPulse),
                                blurRadius: 60,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/icon/kratos_foreground1.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Brand Name: "KRATOS" ──
                    ClipRect(
                      child: Align(
                        alignment: Alignment.center,
                        widthFactor: _brandReveal.value.clamp(0.001, 1.0),
                        child: _buildShimmerText(
                          AppStrings.appName,
                          AppTypography.display.copyWith(
                            color: Colors.white,
                            fontSize: 64,
                            letterSpacing: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Tagline ──
                    SlideTransition(
                      position: _taglineSlide,
                      child: FadeTransition(
                        opacity: _taglineFade,
                        child: Text(
                          AppStrings.appTagline.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: AppTypography.labelBold.copyWith(
                            color: context.colors.primary.withOpacity(0.85),
                            fontSize: 13,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 4),

                    // ── Scroll indicator ──
                    Opacity(
                      opacity: _scrollHintFade.value *
                          (1.0 - _scrollProgress * 3).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, scrollBounce),
                        child: Column(
                          children: [
                            Text(
                              'EXPLORE',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white.withOpacity(0.3),
                                letterSpacing: 3,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white.withOpacity(0.25),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Shimmer text effect ───
  Widget _buildShimmerText(String text, TextStyle style) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        if (_shimmerController.value == 0 || _shimmerController.value == 1) {
          return Text(text, style: style, textAlign: TextAlign.center);
        }
        return ShaderMask(
          shaderCallback: (bounds) {
            final shimmerPosition = _shimmerController.value * 3 - 1;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white,
                context.colors.primary.withOpacity(0.9),
                Colors.white,
              ],
              stops: [
                (shimmerPosition - 0.3).clamp(0.0, 1.0),
                shimmerPosition.clamp(0.0, 1.0),
                (shimmerPosition + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: Text(text, style: style, textAlign: TextAlign.center),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════
  //  SECTION 2: FEATURE PILLARS — Nike campaign-style
  // ═════════════════════════════════════════════════════════════════
  Widget _buildFeatureSection(double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          // Section label
          _buildScrollReveal(
            delay: 0.0,
            child: Text(
              'BUILT FOR WARRIORS',
              style: AppTypography.labelBold.copyWith(
                color: context.colors.primary.withOpacity(0.7),
                fontSize: 11,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildScrollReveal(
            delay: 0.05,
            child: Container(
              width: 32,
              height: 2,
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Three feature pillars
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildScrollReveal(
                  delay: 0.1,
                  child: _FeaturePillar(
                    icon: Icons.psychology_rounded,
                    title: AppStrings.featureAiTitle,
                    subtitle: AppStrings.featureAiSubtitle,
                    description: AppStrings.featureAiDesc,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScrollReveal(
                  delay: 0.2,
                  child: _FeaturePillar(
                    icon: Icons.insights_rounded,
                    title: AppStrings.featureTrackTitle,
                    subtitle: AppStrings.featureTrackSubtitle,
                    description: AppStrings.featureTrackDesc,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScrollReveal(
                  delay: 0.3,
                  child: _FeaturePillar(
                    icon: Icons.headphones_rounded,
                    title: AppStrings.featureMusicTitle,
                    subtitle: AppStrings.featureMusicSubtitle,
                    description: AppStrings.featureMusicDesc,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Scroll-aware reveal animation ───
  Widget _buildScrollReveal({required double delay, required Widget child}) {
    // Feature section starts after hero (scrollProgress > 0)
    final effectiveProgress =
        ((_scrollProgress - 0.1 - delay) * 4).clamp(0.0, 1.0);
    final curve = Curves.easeOutCubic.transform(effectiveProgress);

    return Transform.translate(
      offset: Offset(0, 30 * (1 - curve)),
      child: Opacity(
        opacity: curve,
        child: child,
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  //  SECTION 3: FIXED CTA — Frosted glass bottom panel
  // ═════════════════════════════════════════════════════════════════
  Widget _buildCTASection(double bottomPadding) {

    return AnimatedBuilder(
      animation: _heroController,
      builder: (context, _) {
        // CTA slides up after hero completes
        final ctaSlide = Tween<double>(begin: 80, end: 0).transform(
          CurvedAnimation(
            parent: _heroController,
            curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
          ).value,
        );

        return Transform.translate(
          offset: Offset(0, ctaSlide * (1 - _scrollProgress.clamp(0.0, 1.0))),
          child: Opacity(
            opacity: CurvedAnimation(
              parent: _heroController,
              curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
            ).value.clamp(0.0, 1.0),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                      24, 24, 24, bottomPadding + 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A).withOpacity(0.85),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28)),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Primary CTA
                      ContinueButton(
                        text: AppStrings.getStarted,
                        onPressed: _navigateToRegister,
                        icon: Icons.arrow_forward_rounded,
                      ),

                      const SizedBox(height: 14),

                      // Sign In link
                      TextButton(
                        onPressed: _navigateToSignIn,
                        child: RichText(
                          text: TextSpan(
                            text: AppStrings.alreadyHaveAccount,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.35),
                            ),
                            children: [
                              TextSpan(
                                text: ' ${AppStrings.signIn}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: context.colors.primary,
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
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════
//  FEATURE PILLAR WIDGET
// ═════════════════════════════════════════════════════════════════
class _FeaturePillar extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;

  const _FeaturePillar({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icon container with glass effect
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: context.colors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.colors.primary.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: context.colors.primary,
            size: 24,
          ),
        ),

        const SizedBox(height: 16),

        // Title (two lines, stacked)
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.labelBold.copyWith(
            color: Colors.white,
            fontSize: 12,
            letterSpacing: 2,
            height: 1.3,
          ),
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTypography.labelBold.copyWith(
            color: context.colors.primary,
            fontSize: 12,
            letterSpacing: 2,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 10),

        // Description
        Text(
          description,
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withOpacity(0.35),
            fontSize: 10,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
