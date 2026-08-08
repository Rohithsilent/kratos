import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/data/auth_repository.dart';
import '../data/razorpay_service.dart';
import '../data/subscription_service.dart';

const _goldDark = Color(0xFFD4AF37);
const _goldLight = Color(0xFFFFDF73);
const _goldGradient = LinearGradient(
  colors: [_goldDark, _goldLight],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen>
    with TickerProviderStateMixin {
  bool _isProcessing = false;
  late final AnimationController _staggerController;
  late final List<Animation<double>> _cardFades;
  late final List<Animation<Offset>> _cardSlides;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );
    _cardFades = List.generate(2, (i) {
      final start = i * 0.25;
      return CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOut),
      );
    });
    _cardSlides = List.generate(2, (i) {
      final start = i * 0.25;
      return Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOut),
      ));
    });
    _staggerController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rp = ref.read(razorpayServiceProvider);
      rp.onPaymentSuccessCallback = (msg) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: context.customColors.success),
        );
      };
      rp.onPaymentErrorCallback = (err) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: context.colors.error),
        );
      };
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _upgradeTier(String planId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please sign in to upgrade.'), backgroundColor: context.colors.error),
      );
      return;
    }
    final userData = await ref.read(authRepositoryProvider).getUserData(user.uid);
    await ref.read(razorpayServiceProvider).createSubscription(
      planId: planId,
      uid: user.uid,
      contact: userData?.phone ?? '',
      email: userData?.email ?? user.email ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : context.customColors.grey900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              floating: true, snap: true, elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    color: isDark ? Colors.white70 : context.customColors.grey700, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              centerTitle: true,
              title: Text('Choose Your Plan',
                style: AppTypography.headlineSmall.copyWith(
                  color: fgColor, fontSize: 19, fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, child) {
                  final subAsync = ref.watch(currentSubscriptionProvider);
                  return subAsync.when(
                    data: (subscription) {
                      final service = ref.watch(subscriptionServiceProvider);
                      String currentTier = 'base';
                      if (subscription != null && subscription.isActive) {
                        if (service.isPlanPro(subscription.planId)) {
                          currentTier = 'pro';
                        } else if (service.isPlanPremium(subscription.planId)) {
                          currentTier = 'premium';
                        }
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Current plan banner ──
                            _CurrentPlanBanner(currentTier: currentTier),
                            const SizedBox(height: 20),
                            // ── Pro ──
                            SlideTransition(
                              position: _cardSlides[0],
                              child: FadeTransition(opacity: _cardFades[0],
                                child: _PaidTierCard(
                                  tierName: 'Pro',
                                  icon: Icons.bolt_rounded,
                                  monthlyPrice: '₹5',
                                  yearlyPrice: '₹40',
                                  yearlyPerMonth: '₹3.3',
                                  originalYearly: '₹60',
                                  features: const [
                                    'Unlimited history tracking',
                                    'Premium workout plans',
                                    'Advanced analytics',
                                    'Ad-free experience',
                                  ],
                                  isPopular: true,
                                  isCurrentTier: currentTier == 'pro',
                                  isDowngrade: currentTier == 'premium',
                                  accentColor: context.colors.primary,
                                  gradient: context.customColors.primaryGradient,
                                  glowColor: context.glow.redGlow,
                                  onUpgrade: (isYearly) => _upgradeTier(
                                    isYearly
                                        ? dotenv.env['RAZORPAY_PLAN_PRO_YEARLY']!
                                        : dotenv.env['RAZORPAY_PLAN_PRO_MONTHLY']!,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // ── Premium ──
                            SlideTransition(
                              position: _cardSlides[1],
                              child: FadeTransition(opacity: _cardFades[1],
                                child: _PaidTierCard(
                                  tierName: 'Premium',
                                  icon: Icons.workspace_premium_rounded,
                                  monthlyPrice: '₹10',
                                  yearlyPrice: '₹90',
                                  yearlyPerMonth: '₹7.5',
                                  originalYearly: '₹120',
                                  features: const [
                                    'All Pro features',
                                    'Early access to new features',
                                    'Priority support',
                                    'Personalized AI insights',
                                  ],
                                  isPopular: false,
                                  isCurrentTier: currentTier == 'premium',
                                  isDowngrade: false,
                                  accentColor: isDark ? _goldLight : _goldDark,
                                  gradient: _goldGradient,
                                  glowColor: _goldDark.withOpacity(0.35),
                                  isPremium: true,
                                  onUpgrade: (isYearly) => _upgradeTier(
                                    isYearly
                                        ? dotenv.env['RAZORPAY_PLAN_PREMIUM_YEARLY']!
                                        : dotenv.env['RAZORPAY_PLAN_PREMIUM_MONTHLY']!,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    },
                    loading: () => Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator(color: context.colors.primary)),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text('Error: $e', style: TextStyle(color: fgColor))),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CURRENT PLAN BANNER (minimal — not a full card)
// ═══════════════════════════════════════════════════════════════
class _CurrentPlanBanner extends StatelessWidget {
  final String currentTier;
  const _CurrentPlanBanner({required this.currentTier});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = currentTier == 'free' || currentTier == 'base'
        ? 'Base (Free)'
        : currentTier == 'pro'
            ? 'Pro'
            : 'Premium';
    final icon = currentTier == 'premium'
        ? Icons.workspace_premium_rounded
        : currentTier == 'pro'
            ? Icons.bolt_rounded
            : Icons.shield_outlined;
    final color = currentTier == 'premium'
        ? (isDark ? _goldLight : _goldDark)
        : currentTier == 'pro'
            ? context.colors.primary
            : (isDark ? Colors.white38 : context.customColors.grey400);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.08 : 0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(isDark ? 0.15 : 0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CURRENT PLAN', style: AppTypography.caption.copyWith(
                  color: isDark ? Colors.white38 : context.customColors.grey400,
                  fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5,
                )),
                const SizedBox(height: 2),
                Text(label, style: AppTypography.labelBold.copyWith(
                  color: isDark ? Colors.white : context.customColors.grey900,
                  fontSize: 15, letterSpacing: 0.5,
                )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('ACTIVE', style: AppTypography.caption.copyWith(
              color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1,
            )),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PAID TIER CARD (Pro / Premium) with inline billing toggle
// ═══════════════════════════════════════════════════════════════
class _PaidTierCard extends StatefulWidget {
  final String tierName;
  final IconData icon;
  final String monthlyPrice, yearlyPrice, yearlyPerMonth, originalYearly;
  final List<String> features;
  final bool isPopular, isCurrentTier, isDowngrade, isPremium;
  final Color accentColor, glowColor;
  final LinearGradient gradient;
  final void Function(bool isYearly) onUpgrade;

  const _PaidTierCard({
    required this.tierName,
    required this.icon,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.yearlyPerMonth,
    required this.originalYearly,
    required this.features,
    required this.isPopular,
    required this.isCurrentTier,
    required this.isDowngrade,
    required this.accentColor,
    required this.gradient,
    required this.glowColor,
    required this.onUpgrade,
    this.isPremium = false,
  });

  @override
  State<_PaidTierCard> createState() => _PaidTierCardState();
}

class _PaidTierCardState extends State<_PaidTierCard>
    with SingleTickerProviderStateMixin {
  bool _isYearly = true; // default to yearly (better value)
  AnimationController? _shimmerController;

  @override
  void initState() {
    super.initState();
    if (widget.isPremium) {
      _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _shimmerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : context.customColors.grey900;
    final mutedColor = isDark ? Colors.white70 : context.customColors.grey500;
    final accent = widget.accentColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          backgroundColor: isDark
              ? accent.withOpacity(0.06)
              : context.colors.surface,
          borderColor: accent.withOpacity(isDark ? 0.18 : 0.25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isPopular) const SizedBox(height: 6),

              // ── Title ──
              Row(children: [
                Icon(widget.icon, color: accent, size: 24),
                const SizedBox(width: 10),
                widget.isPremium && _shimmerController != null
                    ? AnimatedBuilder(
                        animation: _shimmerController!,
                        builder: (context, _) => ShaderMask(
                          shaderCallback: (bounds) {
                            final dx = _shimmerController!.value * 3 - 1;
                            return LinearGradient(
                              colors: const [_goldDark, _goldLight, _goldDark],
                              stops: const [0.0, 0.5, 1.0],
                              begin: Alignment(dx, 0),
                              end: Alignment(dx + 1, 0),
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcIn,
                          child: Text(widget.tierName,
                            style: AppTypography.headlineMedium.copyWith(
                              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    : Text(widget.tierName,
                        style: AppTypography.headlineMedium.copyWith(
                          color: fgColor, fontSize: 24, fontWeight: FontWeight.w800,
                        ),
                      ),
              ]),
              const SizedBox(height: 18),

              // ── Inline Billing Toggle ──
              _buildBillingToggle(isDark, accent),
              const SizedBox(height: 18),

              // ── Price Display ──
              _buildPriceDisplay(isDark, fgColor, mutedColor, accent),
              const SizedBox(height: 22),

              // ── Features ──
              ...widget.features.map((f) => _FeatureRow(text: f, checkColor: accent)),
              const SizedBox(height: 22),

              // ── CTA ──
              _buildCTA(isDark),
            ],
          ),
        ),

        // "Most Popular" badge
        if (widget.isPopular)
          Positioned(
            top: -12, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: widget.glowColor, blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Text('MOST POPULAR', style: AppTypography.caption.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.5,
                )),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBillingToggle(bool isDark, Color accent) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          _billingOption('Monthly', !_isYearly, isDark, accent),
          _billingOption('Yearly', _isYearly, isDark, accent, showSave: true),
        ],
      ),
    );
  }

  Widget _billingOption(String label, bool selected, bool isDark, Color accent, {bool showSave = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isYearly = label == 'Yearly'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? accent.withOpacity(isDark ? 0.15 : 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: accent.withOpacity(isDark ? 0.3 : 0.35))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: AppTypography.labelSmall.copyWith(
                color: selected
                    ? (isDark ? Colors.white : context.customColors.grey900)
                    : (isDark ? Colors.white38 : context.customColors.grey400),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              )),
              if (showSave && selected) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.customColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('~33%', style: AppTypography.caption.copyWith(
                    color: context.customColors.success, fontSize: 8, fontWeight: FontWeight.w800,
                  )),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceDisplay(bool isDark, Color fgColor, Color mutedColor, Color accent) {
    final price = _isYearly ? widget.yearlyPrice : widget.monthlyPrice;
    final period = _isYearly ? '/ year' : '/ month';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(price, style: AppTypography.display.copyWith(
              color: accent, fontSize: 36,
            )),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(period, style: AppTypography.bodySmall.copyWith(color: mutedColor)),
            ),
            if (_isYearly) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(widget.originalYearly, style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white24 : context.customColors.grey300,
                  decoration: TextDecoration.lineThrough,
                )),
              ),
            ],
          ],
        ),
        if (_isYearly)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('That\'s just ${widget.yearlyPerMonth}/month',
              style: AppTypography.caption.copyWith(
                color: context.customColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCTA(bool isDark) {
    if (widget.isCurrentTier) {
      return _DisabledButton(label: 'Current Plan');
    }
    if (widget.isDowngrade) {
      return _DisabledButton(label: 'Included in your plan');
    }
    return _GradientButton(
      label: 'Upgrade to ${widget.tierName}',
      gradient: widget.gradient,
      glowColor: widget.glowColor,
      textColor: widget.isPremium ? Colors.black87 : Colors.white,
      onTap: () => widget.onUpgrade(_isYearly),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════

class _FeatureRow extends StatelessWidget {
  final String text;
  final Color checkColor;
  const _FeatureRow({required this.text, required this.checkColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, color: checkColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white.withOpacity(0.85) : context.customColors.grey700,
              fontSize: 14,
            )),
          ),
        ],
      ),
    );
  }
}

class _DisabledButton extends StatelessWidget {
  final String label;
  const _DisabledButton({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.10),
        ),
      ),
      child: Center(
        child: Text(label, style: AppTypography.labelBold.copyWith(
          color: isDark ? Colors.white38 : context.customColors.grey400,
          fontSize: 14, letterSpacing: 1,
        )),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback? onTap;
  final Color textColor;

  const _GradientButton({
    required this.label,
    required this.gradient,
    required this.glowColor,
    this.onTap,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: glowColor, blurRadius: 16, offset: const Offset(0, 6), spreadRadius: -2),
          ],
        ),
        child: Center(
          child: Text(label, style: AppTypography.labelBold.copyWith(
            color: textColor, fontSize: 14, letterSpacing: 1,
          )),
        ),
      ),
    );
  }
}
