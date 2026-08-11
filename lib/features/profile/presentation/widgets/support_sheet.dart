import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_typography.dart';

/// Support bottom sheet with FAQs, Feedback, and Help sections.
class SupportSheet extends StatefulWidget {
  const SupportSheet({super.key});

  @override
  State<SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends State<SupportSheet> {
  int? _expandedFaqIndex;

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'How do I create a custom workout?',
      answer: 'Go to the Workouts tab, tap the + button, and use the workout builder to add exercises, sets, and reps. You can name and save your workout for future use.',
    ),
    _FaqItem(
      question: 'How does the streak system work?',
      answer: 'Your streak counts consecutive days with at least one completed workout. If you miss a day, the streak resets. You\'ll get a notification before your streak is about to expire.',
    ),
    _FaqItem(
      question: 'Can I change my subscription plan?',
      answer: 'Yes! Go to Preferences → Subscription to view available plans. You can upgrade or downgrade your plan anytime. Changes take effect at the next billing cycle.',
    ),
    _FaqItem(
      question: 'How is BMI calculated?',
      answer: 'BMI is calculated using your height and weight: weight (kg) ÷ height (m)². Keep your body metrics updated for accurate readings.',
    ),
    _FaqItem(
      question: 'Is my data synced across devices?',
      answer: 'Yes, your workout history, planner, and profile data are stored in the cloud and synced across all devices where you\'re logged in with the same account.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: context.glassmorphism.borderColor,
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? context.customColors.grey700 : context.customColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: isDark ? 0.15 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.help_outline_rounded, color: context.colors.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'SUPPORT',
                    style: AppTypography.labelBold.copyWith(
                      color: isDark ? Colors.white : context.customColors.grey900,
                      letterSpacing: 2,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── FAQs ──
              _sectionHeader(context, isDark, 'FREQUENTLY ASKED QUESTIONS'),
              const SizedBox(height: 12),
              ...List.generate(_faqs.length, (i) {
                final faq = _faqs[i];
                final isExpanded = _expandedFaqIndex == i;
                return _faqTile(context, isDark, faq, isExpanded, () {
                  setState(() => _expandedFaqIndex = isExpanded ? null : i);
                });
              }),

              const SizedBox(height: 28),

              // ── Feedback ──
              _sectionHeader(context, isDark, 'FEEDBACK'),
              const SizedBox(height: 12),
              _actionTile(
                context, isDark,
                icon: Icons.rate_review_rounded,
                title: 'Send Feedback',
                subtitle: 'Help us improve Kratos',
                onTap: () => _showFeedbackDialog(context, isDark),
              ),
              const SizedBox(height: 8),
              _actionTile(
                context, isDark,
                icon: Icons.star_rounded,
                title: 'Rate the App',
                subtitle: 'Share your experience',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('App store rating coming soon!', style: TextStyle(fontSize: 12)),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: isDark ? const Color(0xFF2A2A2A) : context.customColors.grey900,
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // ── Help ──
              _sectionHeader(context, isDark, 'HELP'),
              const SizedBox(height: 12),
              _actionTile(
                context, isDark,
                icon: Icons.email_rounded,
                title: 'Contact Support',
                subtitle: 'support@kratos.fitness',
                onTap: () async {
                  final uri = Uri(scheme: 'mailto', path: 'support@kratos.fitness', queryParameters: {
                    'subject': 'Kratos App Support',
                  });
                  try {
                    await launchUrl(uri);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Could not open email client', style: TextStyle(fontSize: 12)),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: isDark ? const Color(0xFF2A2A2A) : context.customColors.grey900,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
              _actionTile(
                context, isDark,
                icon: Icons.description_rounded,
                title: 'Terms & Privacy',
                subtitle: 'View policies',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Terms & Privacy coming soon!', style: TextStyle(fontSize: 12)),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: isDark ? const Color(0xFF2A2A2A) : context.customColors.grey900,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _actionTile(
                context, isDark,
                icon: Icons.info_outline_rounded,
                title: 'App Version',
                subtitle: 'Kratos v1.0',
                onTap: null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(BuildContext context, bool isDark, String title) {
    return Row(
      children: [
        Container(
          width: 3, height: 12,
          decoration: BoxDecoration(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: isDark ? context.customColors.grey500 : context.customColors.grey400,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _faqTile(BuildContext context, bool isDark, _FaqItem faq, bool isExpanded, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isExpanded
              ? context.colors.primary.withValues(alpha: isDark ? 0.08 : 0.04)
              : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded
                ? context.colors.primary.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    faq.question,
                    style: TextStyle(
                      color: isDark ? Colors.white : context.customColors.grey900,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark ? context.customColors.grey500 : context.customColors.grey400,
                    size: 20,
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              Text(
                faq.answer,
                style: TextStyle(
                  color: isDark ? context.customColors.grey400 : context.customColors.grey600,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: context.colors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(
                  color: isDark ? Colors.white : context.customColors.grey900,
                  fontSize: 14, fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(
                  color: isDark ? context.customColors.grey500 : context.customColors.grey400,
                  fontSize: 11,
                )),
              ]),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: isDark ? context.customColors.grey700 : context.customColors.grey300, size: 18),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, bool isDark) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Send Feedback',
          style: TextStyle(
            color: isDark ? Colors.white : context.customColors.grey900,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          style: TextStyle(
            color: isDark ? Colors.white : context.customColors.grey900,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Tell us what you think...',
            hintStyle: TextStyle(
              color: isDark ? context.customColors.grey600 : context.customColors.grey300,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.colors.primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: isDark ? context.customColors.grey500 : context.customColors.grey400)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (ctrl.text.trim().isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Thanks for your feedback! 🙏', style: TextStyle(fontSize: 12)),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: context.colors.primary,
                  ),
                );
              }
            },
            child: Text('Send', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}
