import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/continue_button.dart';
import 'package:go_router/go_router.dart';

// ═════════════════════════════════════════════════════════════════
//  KRATOS WELCOME SCREEN
//  Single-screen premium fitness experience.
//  No scrolling — everything fits in one viewport.
// ═════════════════════════════════════════════════════════════════

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
  late AnimationController _shimmerController;
  late AnimationController _particleController;
  late AnimationController _contentRevealController;
  late AnimationController _outlineController;

  // ─── Logo Reveal Animations ───
  late Animation<double> _outlineTrace;
  late Animation<double> _colorFill;

  // ─── Hero Animations ───
  late Animation<double> _glowExpand;
  late Animation<double> _logoScale;
  late Animation<double> _brandReveal;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;

  // ─── New Content Animations ───
  late Animation<double> _chipsFade;
  late Animation<double> _chipsScale;
  late Animation<double> _statsFade;
  late Animation<double> _descFade;
  late Animation<double> _trustFade;
  late Animation<double> _ctaFade;
  late Animation<double> _ctaSlide;

  @override
  void initState() {
    super.initState();

    // ── Logo outline trace + color fill (1.8s) ──
    _outlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Outline traces 0–65%, color fills 50–100%
    _outlineTrace = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _outlineController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeInOut),
      ),
    );
    _colorFill = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _outlineController,
        curve: const Interval(0.50, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Main hero entrance (2.4s, starts after outline) ──
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // ── Continuous glow pulse ──
    _glowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // ── PRESERVED: Shimmer across brand name ──
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // ── NEW: Particle drift (continuous) ──
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    // ── NEW: Content reveal after hero (chips → trust → CTA) ──
    _contentRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // ══════════════════════════════════════
    //  PRESERVED TIMELINE (exact same curves)
    // ══════════════════════════════════════

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

    // ══════════════════════════════════════
    //  NEW CONTENT TIMELINE
    // ══════════════════════════════════════

    // Feature chips: 0–60% of content reveal
    _chipsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentRevealController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _chipsScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentRevealController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    // Stats row: 20–55%
    _statsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentRevealController,
        curve: const Interval(0.15, 0.50, curve: Curves.easeOut),
      ),
    );

    // Description: 30–60%
    _descFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentRevealController,
        curve: const Interval(0.30, 0.60, curve: Curves.easeOut),
      ),
    );

    // Trust statement: 45–75%
    _trustFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentRevealController,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
      ),
    );

    // CTA + sign in: 60–100%
    _ctaFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentRevealController,
        curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
      ),
    );
    _ctaSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentRevealController,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // ── Launch sequence ──
    // 1. Outline traces first
    _outlineController.forward();

    // 2. Hero starts midway through outline (overlap for smooth transition)
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _heroController.forward();
    });

    // 3. Shimmer after brand reveals
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) _shimmerController.forward();
    });

    // 4. Content reveals after hero
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) _contentRevealController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _glowPulseController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    _contentRevealController.dispose();
    _outlineController.dispose();
    super.dispose();
  }

  void _navigateToRegister() => context.push('/onboarding');
  void _navigateToSignIn() => context.push('/signin');

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _heroController,
          _glowPulseController,
          _particleController,
          _contentRevealController,
          _outlineController,
        ]),
        builder: (context, _) {
          final glowPulse = 0.8 + _glowPulseController.value * 0.2;

          return Stack(
            children: [
              // ── Layer 0: Deep background ──
              Container(color: const Color(0xFF050505)),

              // ── Layer 1: Warrior silhouette atmosphere ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _WarriorAtmospherePainter(
                    progress: _glowExpand.value,
                    primaryColor: context.colors.primary,
                  ),
                ),
              ),

              // ── Layer 2: Floating particles ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _FloatingParticlePainter(
                    animationValue: _particleController.value,
                    primaryColor: context.colors.primary,
                    screenSize: size,
                  ),
                ),
              ),

              // ── Layer 3: Primary radial glow (behind helmet) ──
              Positioned(
                top: topPad + size.height * 0.08,
                left: 0,
                right: 0,
                child: Center(
                  child: Opacity(
                    opacity: _glowExpand.value * 0.6,
                    child: Container(
                      width: 380 * _glowExpand.value * glowPulse,
                      height: 380 * _glowExpand.value * glowPulse,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            context.colors.primary.withOpacity(0.20),
                            context.colors.primary.withOpacity(0.06),
                            context.colors.primary.withOpacity(0.02),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.35, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Layer 4: Bottom ambient glow (behind CTA) ──
              Positioned(
                bottom: -40,
                left: 0,
                right: 0,
                child: Center(
                  child: Opacity(
                    opacity: _ctaFade.value * 0.4,
                    child: Container(
                      width: 300,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(100),
                        gradient: RadialGradient(
                          colors: [
                            context.colors.primary.withOpacity(0.12),
                            context.colors.primary.withOpacity(0.04),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Layer 5: Main content ──
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive spacing based on available height
                      final available = constraints.maxHeight;
                      final isCompact = available < 680;
                      final logoSize = isCompact ? 120.0 : 140.0;

                      return Column(
                        children: [
                          // ── Top flexible spacer ──
                          SizedBox(height: available * (isCompact ? 0.06 : 0.08)),

                          // ── Spartan Helmet Logo with Outline Reveal ──
                          Transform.scale(
                            scale: _logoScale.value,
                            child: SizedBox(
                              width: logoSize,
                              height: logoSize,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Layer 1: Perfect edge-extracted neon outline mask
                                  if (_outlineTrace.value > 0)
                                    Positioned.fill(
                                      child: Opacity(
                                        opacity: (1.0 - _colorFill.value).clamp(0.0, 1.0),
                                        child: ShaderMask(
                                          shaderCallback: (bounds) {
                                            return SweepGradient(
                                              startAngle: 0.0,
                                              endAngle: pi * 2,
                                              transform: const GradientRotation(-pi / 2),
                                              colors: [
                                                Colors.white,
                                                Colors.white,
                                                Colors.transparent,
                                                Colors.transparent,
                                              ],
                                              stops: [
                                                0.0,
                                                _outlineTrace.value,
                                                (_outlineTrace.value + 0.05).clamp(0.0, 1.0),
                                                1.0,
                                              ],
                                            ).createShader(bounds);
                                          },
                                          blendMode: BlendMode.dstIn,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.white.withOpacity(0.3),
                                                  blurRadius: 15,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: Image.asset(
                                              'assets/icon/kratos_outline.png',
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Layer 2: Logo image with radial reveal mask
                                  Opacity(
                                    opacity: _colorFill.value,
                                    child: ShaderMask(
                                      shaderCallback: (bounds) {
                                        final radius = _colorFill.value * bounds.width * 1.2;
                                        return RadialGradient(
                                          radius: radius / bounds.width,
                                          colors: [
                                            Colors.white,
                                            Colors.white,
                                            Colors.transparent,
                                          ],
                                          stops: [
                                            0.0,
                                            (_colorFill.value * 0.85).clamp(0.0, 1.0),
                                            (_colorFill.value * 1.0).clamp(0.0, 1.0),
                                          ],
                                        ).createShader(bounds);
                                      },
                                      blendMode: BlendMode.dstIn,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: context.colors.primary.withOpacity(
                                                  0.3 * _colorFill.value * glowPulse),
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
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: isCompact ? 24 : 32),

                          // ── Brand Name: "KRATOS" (PRESERVED) ──
                          ClipRect(
                            child: Align(
                              alignment: Alignment.center,
                              widthFactor:
                                  _brandReveal.value.clamp(0.001, 1.0),
                              child: _buildShimmerText(
                                AppStrings.appName,
                                AppTypography.display.copyWith(
                                  color: Colors.white,
                                  fontSize: isCompact ? 48 : 56,
                                  letterSpacing: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isCompact ? 10 : 14),

                          // ── Tagline (PRESERVED) ──
                          SlideTransition(
                            position: _taglineSlide,
                            child: FadeTransition(
                              opacity: _taglineFade,
                              child: Text(
                                AppStrings.appTagline.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: AppTypography.labelBold.copyWith(
                                  color: context.colors.primary
                                      .withOpacity(0.85),
                                  fontSize: 12,
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isCompact ? 16 : 22),

                          // ── Feature Chips ──
                          Opacity(
                            opacity: _chipsFade.value,
                            child: Transform.scale(
                              scale: _chipsScale.value,
                              child: _buildFeatureChips(context),
                            ),
                          ),

                          const Spacer(flex: 2),

                          // ── Social Proof Stats ──
                          Opacity(
                            opacity: _statsFade.value,
                            child: _buildStatsRow(context),
                          ),

                          const Spacer(flex: 1),

                          // ── Subtle separator ──
                          Opacity(
                            opacity: _descFade.value,
                            child: Container(
                              width: 40,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    context.colors.primary.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isCompact ? 10 : 14),

                          // ── App description ──
                          Opacity(
                            opacity: _descFade.value,
                            child: Text(
                              'AI-powered workouts · Elite tracking\nPersonalized transformation plans',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white.withOpacity(0.22),
                                fontSize: 10,
                                letterSpacing: 0.5,
                                height: 1.7,
                              ),
                            ),
                          ),

                          const Spacer(flex: 1),

                          // ── Trust Statement ──
                          Opacity(
                            opacity: _trustFade.value,
                            child: Text(
                              AppStrings.trustStatement,
                              textAlign: TextAlign.center,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 11,
                                letterSpacing: 1.5,
                                height: 1.6,
                              ),
                            ),
                          ),

                          SizedBox(height: isCompact ? 16 : 20),

                          // ── CTA Button (ENHANCED) ──
                          Transform.translate(
                            offset: Offset(0, _ctaSlide.value),
                            child: Opacity(
                              opacity: _ctaFade.value,
                              child: _buildEnhancedCTA(context, glowPulse),
                            ),
                          ),

                          SizedBox(height: isCompact ? 8 : 12),

                          // ── Sign In Link ──
                          Opacity(
                            opacity: _ctaFade.value,
                            child: TextButton(
                              onPressed: _navigateToSignIn,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: RichText(
                                text: TextSpan(
                                  text: AppStrings.alreadyHaveAccount,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.35),
                                    fontSize: 13,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: ' ${AppStrings.signIn}',
                                      style:
                                          AppTypography.bodySmall.copyWith(
                                        color: context.colors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                              height: bottomPad > 0
                                  ? 4
                                  : (isCompact ? 12 : 16)),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SHIMMER TEXT (PRESERVED EXACTLY)
  // ═══════════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════════
  //  FEATURE CHIPS — Glassmorphic pills
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFeatureChips(BuildContext context) {
    final chips = [
      (Icons.restaurant_rounded, AppStrings.chipNutrition),
      (Icons.insights_rounded, AppStrings.chipTracking),
      (Icons.fitness_center_rounded, AppStrings.chipPlanner),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: chips.map((chip) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.07),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                chip.$1,
                size: 14,
                color: context.colors.primary.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Text(
                chip.$2,
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withOpacity(0.50),
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SOCIAL PROOF STATS — Three glassmorphic metric cards
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatsRow(BuildContext context) {
    final stats = [
      (AppStrings.cardWarriors, AppStrings.cardWarriorsLabel),
      (AppStrings.cardWorkouts, AppStrings.cardWorkoutsLabel),
      (AppStrings.cardTransformations, AppStrings.cardTransformationsLabel),
    ];

    return IntrinsicHeight(
      child: Row(
        children: stats.asMap().entries.map((entry) {
          final i = entry.key;
          final stat = entry.value;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Container(
                    width: 0.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.white.withOpacity(0.06),
                  ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stat.$1,
                        style: AppTypography.headlineLarge.copyWith(
                          color: context.colors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stat.$2.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withOpacity(0.30),
                          fontSize: 9,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  // ═══════════════════════════════════════════════════════════════
  //  ENHANCED CTA — Premium glow wrapper
  // ═══════════════════════════════════════════════════════════════
  Widget _buildEnhancedCTA(BuildContext context, double glowPulse) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                context.colors.primary.withOpacity(0.18 * glowPulse),
            blurRadius: 40,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color:
                context.colors.primary.withOpacity(0.08 * glowPulse),
            blurRadius: 80,
            spreadRadius: -8,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ContinueButton(
        text: AppStrings.getStarted,
        onPressed: _navigateToRegister,
        icon: Icons.arrow_forward_rounded,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
//  FLOATING PARTICLE PAINTER
//  ~18 soft crimson dots drifting upward with sine-wave sway.
//  Extremely subtle — atmospheric, not distracting.
// ═════════════════════════════════════════════════════════════════
class _FloatingParticlePainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Size screenSize;

  _FloatingParticlePainter({
    required this.animationValue,
    required this.primaryColor,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42); // Fixed seed for deterministic positions
    const particleCount = 18;

    for (int i = 0; i < particleCount; i++) {
      // Deterministic base position
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;

      // Each particle has its own phase offset
      final phase = i / particleCount;
      final t = (animationValue + phase) % 1.0;

      // Slow upward drift (wraps around)
      final y = (baseY - t * size.height * 0.6) % size.height;

      // Gentle horizontal sine sway
      final swayAmplitude = 8.0 + rng.nextDouble() * 12.0;
      final swayFreq = 1.0 + rng.nextDouble() * 1.5;
      final x = baseX + sin(t * pi * 2 * swayFreq) * swayAmplitude;

      // Variable size and opacity
      final radius = 0.8 + rng.nextDouble() * 1.8;
      final opacity = 0.08 + rng.nextDouble() * 0.16;

      final paint = Paint()
        ..color = primaryColor.withOpacity(opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.8);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// ═════════════════════════════════════════════════════════════════
//  WARRIOR ATMOSPHERE PAINTER
//  Abstract angular geometry suggesting a warrior silhouette.
//  Very low opacity — felt, not seen.
// ═════════════════════════════════════════════════════════════════
class _WarriorAtmospherePainter extends CustomPainter {
  final double progress;
  final Color primaryColor;

  _WarriorAtmospherePainter({
    required this.progress,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.1) return;

    final opacity = (progress * 0.035).clamp(0.0, 0.035);
    final paint = Paint()
      ..color = primaryColor.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;

    // Abstract angular form — like a distant warrior statue
    // Central vertical emphasis line
    final spine = Path()
      ..moveTo(centerX, size.height * 0.15)
      ..lineTo(centerX - 2, size.height * 0.65)
      ..lineTo(centerX + 2, size.height * 0.65)
      ..close();
    canvas.drawPath(spine, paint);

    // Broad shoulder suggestion (very wide, very faint triangle)
    final shoulders = Path()
      ..moveTo(centerX, size.height * 0.22)
      ..lineTo(centerX - size.width * 0.28, size.height * 0.32)
      ..lineTo(centerX + size.width * 0.28, size.height * 0.32)
      ..close();
    canvas.drawPath(
      shoulders,
      paint..color = primaryColor.withOpacity(opacity * 0.6),
    );

    // Helmet crest suggestion (triangle above center)
    final crest = Path()
      ..moveTo(centerX, size.height * 0.10)
      ..lineTo(centerX - 14, size.height * 0.18)
      ..lineTo(centerX + 14, size.height * 0.18)
      ..close();
    canvas.drawPath(
      crest,
      paint..color = primaryColor.withOpacity(opacity * 0.8),
    );

    // Subtle vertical light lines (like pillar edges)
    final linePaint = Paint()
      ..color = primaryColor.withOpacity(opacity * 0.4)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(centerX - size.width * 0.18, size.height * 0.3),
      Offset(centerX - size.width * 0.15, size.height * 0.7),
      linePaint,
    );
    canvas.drawLine(
      Offset(centerX + size.width * 0.18, size.height * 0.3),
      Offset(centerX + size.width * 0.15, size.height * 0.7),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WarriorAtmospherePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
