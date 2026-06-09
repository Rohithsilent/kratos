import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/animated_gradient_bg.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/data/auth_repository.dart';
import '../data/razorpay_service.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isYearly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final razorpayService = ref.read(razorpayServiceProvider);
      razorpayService.onPaymentSuccessCallback = (message) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ));
      };
      razorpayService.onPaymentErrorCallback = (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ));
      };
    });
  }

  void _upgradeTier(String tierName, int amountInPaise, String description) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to upgrade.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final userData = await ref.read(authRepositoryProvider).getUserData(user.uid);

    ref.read(razorpayServiceProvider).openCheckout(
      amountInPaise: amountInPaise,
      tierName: tierName,
      name: 'Kratos Subscription',
      description: description,
      contact: userData?.phone ?? '',
      email: userData?.email ?? user.email ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.black,
              floating: true,
              snap: true,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              centerTitle: true,
              title: Text(
                'Unlock Your Potential',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyToggleDelegate(
                child: _buildToggle(),
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder(
                future: ref.read(authRepositoryProvider).getUserData(
                  ref.read(authRepositoryProvider).currentUser?.uid ?? ''
                ),
                builder: (context, snapshot) {
                  final currentTier = snapshot.data?.subscriptionTier ?? 'base';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTierCard(
                          title: 'Base',
                          price: '₹0',
                          duration: 'Forever',
                          features: [
                            'Basic workout tracking',
                            'Standard exercise library',
                            'Limited history',
                          ],
                          isCurrentTier: currentTier == 'free' || currentTier == 'base',
                          onTap: null,
                        ),
                        const SizedBox(height: 24),
                        _buildTierCard(
                          title: 'Pro',
                          price: _isYearly ? '₹40' : '₹5',
                          duration: _isYearly ? '/ year' : '/ month',
                          originalPrice: _isYearly ? '₹60' : null,
                          features: [
                            'Unlimited history tracking',
                            'Premium workout plans',
                            'Advanced analytics',
                            'Ad-free experience',
                          ],
                          isPopular: true,
                          isCurrentTier: currentTier == 'pro',
                          onTap: currentTier == 'premium' 
                            ? null 
                            : () => _upgradeTier('pro', _isYearly ? 4000 : 500, _isYearly ? 'Pro Yearly Subscription' : 'Pro Monthly Subscription'),
                        ),
                        const SizedBox(height: 24),
                        _buildTierCard(
                          title: 'Premium',
                          price: _isYearly ? '₹90' : '₹10',
                          duration: _isYearly ? '/ year' : '/ month',
                          originalPrice: _isYearly ? '₹120' : null,
                          features: [
                            'All Pro features',
                            'Save big annually',
                            'Early access to new features',
                            'Priority support',
                            'Personalized AI insights',
                          ],
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD4AF37), Color(0xFFFFDF73)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          isCurrentTier: currentTier == 'premium',
                          onTap: () => _upgradeTier('premium', _isYearly ? 9000 : 1000, _isYearly ? 'Premium Yearly Subscription' : 'Premium Monthly Subscription'),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleOption(title: 'Monthly', isSelected: !_isYearly),
            _buildToggleOption(title: 'Yearly', isSelected: _isYearly, discount: 'Save ~33%'),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption({required String title, required bool isSelected, String? discount}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isYearly = title == 'Yearly';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.redAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (discount != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? Colors.white.withOpacity(0.3) : Colors.greenAccent.withOpacity(0.3)),
                ),
                child: Text(
                  discount,
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required String title,
    required String price,
    required String duration,
    required List<String> features,
    String? originalPrice,
    bool isPopular = false,
    bool isCurrentTier = false,
    LinearGradient? gradient,
    VoidCallback? onTap,
  }) {
    final titleColor = gradient != null ? Colors.white : Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPopular) const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(
                    price,
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: gradient != null ? const Color(0xFFFFDF73) : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      duration,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  if (originalPrice != null) ...[
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        originalPrice,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: Colors.white38,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 24),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: gradient != null ? const Color(0xFFFFDF73) : Colors.redAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isCurrentTier ? null : onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrentTier 
                      ? Colors.white24 
                      : (gradient != null ? const Color(0xFFD4AF37) : Colors.redAccent),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: isCurrentTier ? 0 : 4,
                  ),
                  child: Text(
                    isCurrentTier ? 'Current Plan' : (onTap == null ? 'Unavailable' : 'Upgrade to $title'),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isPopular)
          Positioned(
            top: -12,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.redAccent, Colors.orangeAccent],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Most Popular',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StickyToggleDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyToggleDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  double get maxExtent => 85.0;

  @override
  double get minExtent => 85.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
