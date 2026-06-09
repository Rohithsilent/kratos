import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../daily_planner/presentation/controllers/planner_completion_controller.dart';
import '../../../workout/presentation/controllers/workout_controller.dart';
import '../controllers/profile_controller.dart';
import '../widgets/physical_stats_card.dart';
import '../widgets/fitness_progress_chart.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  final bool isTab;
  const ProfileScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: profileState.when(
          data: (user) => _buildBody(context, ref, user, isDark),
          loading: () => Center(child: CircularProgressIndicator(color: context.colors.primary)),
          error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: context.colors.error))),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, UserModel? user, bool isDark) {
    final notifier = ref.read(profileControllerProvider.notifier);
    final streak = ref.watch(plannerStatsProvider).currentStreak;
    final sessions = ref.watch(workoutHistoryProvider).value ?? [];
    final totalCal = sessions.fold<int>(0, (s, e) => s + e.caloriesBurned);
    final totalWorkouts = sessions.length;
    final bmi = _calcBMI(user?.height, user?.weight);

    final now = DateTime.now();
    final dayCal = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final ds = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return sessions.where((s) {
        final sd = '${s.completedAt.year}-${s.completedAt.month.toString().padLeft(2, '0')}-${s.completedAt.day.toString().padLeft(2, '0')}';
        return sd == ds;
      }).fold<double>(0, (sum, s) => sum + s.caloriesBurned.toDouble());
    });
    final labels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return ['', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][d.weekday];
    });

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 12),
          // ═══ HEADER ═══
          _header(context, user, isDark),
          const SizedBox(height: 24),
          // ═══ STAT STRIP ═══
          _statStrip(context, isDark, streak, totalWorkouts, totalCal, bmi),
          const SizedBox(height: 28),
          // ═══ ACTIVITY ═══
          _sectionLabel(context, 'WEEKLY ACTIVITY', isDark),
          const SizedBox(height: 12),
          FitnessProgressChart(dailyCalories: dayCal, labels: labels),
          const SizedBox(height: 28),
          // ═══ BODY METRICS ═══
          _sectionLabel(context, 'BODY METRICS', isDark),
          const SizedBox(height: 12),
          PhysicalStatsCard(
            height: user?.height ?? '', weight: user?.weight ?? '', sex: user?.sex ?? '',
            onHeightChanged: (v) => notifier.updateField('height', v),
            onWeightChanged: (v) => notifier.updateField('weight', v),
            onSexChanged: (v) => notifier.updateField('sex', v),
          ),
          const SizedBox(height: 28),
          // ═══ PERSONAL INFO ═══
          _sectionLabel(context, 'PERSONAL', isDark),
          const SizedBox(height: 12),
          _infoCard(context, isDark, notifier, [
            _InfoRow('Full Name', user?.name ?? '', Icons.person_rounded, (v) => notifier.updateField('name', v)),
            _InfoRow('Email', user?.email ?? '', Icons.email_rounded, null),
            _InfoRow('Phone', user?.phone ?? '', Icons.phone_rounded, (v) => notifier.updateField('phone', v)),
            _InfoRow('Date of Birth', user?.dob ?? '', Icons.cake_rounded, (v) => notifier.updateField('dob', v)),
          ]),
          const SizedBox(height: 28),
          // ═══ ACCOUNT ═══
          _sectionLabel(context, 'ACCOUNT', isDark),
          const SizedBox(height: 12),
          _accountCard(context, isDark, user),
          const SizedBox(height: 28),
          // ═══ PREFERENCES ═══
          _sectionLabel(context, 'PREFERENCES', isDark),
          const SizedBox(height: 12),
          _prefCard(context, ref, isDark),
          const SizedBox(height: 32),
          // ═══ LOGOUT ═══
          _logoutBtn(context, ref, isDark),
          const SizedBox(height: 16),
          // ═══ FOOTER ═══
          Center(child: Text('KRATOS v1.0', style: TextStyle(
            color: isDark ? context.customColors.grey700 : context.customColors.grey300, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5,
          ))),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  // ─── HEADER ───
  Widget _header(BuildContext context, UserModel? user, bool isDark) {
    final name = (user?.name ?? 'Athlete').toUpperCase();
    final email = user?.email ?? '';
    final initial = name.isNotEmpty ? name[0] : '?';
    final img = user?.profileImage;

    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      // Avatar
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: context.customColors.primaryGradient,
          boxShadow: [BoxShadow(color: context.colors.primary.withValues(alpha: 0.25), blurRadius: 16)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.5),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? context.colors.surface : context.colors.surface,
            ),
            child: ClipOval(
              child: img != null && img.isNotEmpty
                  ? Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback(context, initial, isDark))
                  : _avatarFallback(context, initial, isDark),
            ),
          ),
        ),
      ),
      const SizedBox(width: 16),
      // Name + Email
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: AppTypography.headlineLarge.copyWith(
          color: isDark ? Colors.white : context.customColors.grey900, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1,
        )),
        const SizedBox(height: 2),
        Text(email, style: TextStyle(
          color: isDark ? context.customColors.grey500 : context.customColors.grey400, fontSize: 12, fontWeight: FontWeight.w500,
        ), overflow: TextOverflow.ellipsis),
      ])),
      // Badge
      Builder(
        builder: (context) {
          final tierStr = (user?.subscriptionTier ?? 'BASE').toUpperCase();
          final displayTier = tierStr == 'FREE' ? 'BASE' : tierStr;
          Color tierColor = context.colors.primary;
          if (displayTier == 'PREMIUM') {
            tierColor = const Color(0xFFFFDF73); // Gold color for premium
          } else if (displayTier == 'BASE') {
            tierColor = isDark ? Colors.white54 : Colors.black54;
          }
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tierColor.withValues(alpha: 0.25)),
            ),
            child: Text(displayTier, style: TextStyle(
              color: tierColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5,
            )),
          );
        }
      ),
    ]);
  }

  Widget _avatarFallback(BuildContext context, String initial, bool isDark) {
    return Center(child: Text(initial, style: TextStyle(
      color: isDark ? Colors.white : context.customColors.grey900, fontSize: 22, fontWeight: FontWeight.w900,
    )));
  }

  // ─── STAT STRIP ───
  Widget _statStrip(BuildContext context, bool isDark, int streak, int workouts, int cal, double bmi) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: AppDecorations.glassCard(context),
      child: Row(children: [
        _statCell(context, isDark, '$streak', 'STREAK', Icons.local_fire_department_rounded, context.colors.primary),
        _vDiv(isDark),
        _statCell(context, isDark, '$workouts', 'WORKOUTS', Icons.fitness_center_rounded, const Color(0xFF22D3EE)),
        _vDiv(isDark),
        _statCell(context, isDark, '$cal', 'KCAL', Icons.bolt_rounded, const Color(0xFFFBBF24)),
        _vDiv(isDark),
        _statCell(context, isDark, bmi > 0 ? bmi.toStringAsFixed(1) : '—', 'BMI', Icons.monitor_weight_rounded, const Color(0xFFA78BFA)),
      ]),
    );
  }

  Widget _statCell(BuildContext context, bool isDark, String val, String label, IconData icon, Color c) {
    return Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: c, size: 18),
      const SizedBox(height: 6),
      Text(val, style: AppTypography.headlineLarge.copyWith(
        color: isDark ? Colors.white : context.customColors.grey900, fontSize: 18, fontWeight: FontWeight.w900,
      )),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: isDark ? context.customColors.grey500 : context.customColors.grey400, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1)),
    ]));
  }

  Widget _vDiv(bool isDark) => Container(width: 1, height: 40, color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06));

  // ─── SECTION LABEL ───
  Widget _sectionLabel(BuildContext context, String t, bool isDark) {
    return Row(children: [
      Container(width: 3, height: 16, decoration: BoxDecoration(
        color: context.colors.primary, borderRadius: BorderRadius.circular(2),
      )),
      const SizedBox(width: 10),
      Text(t, style: AppTypography.labelBold.copyWith(
        color: isDark ? context.customColors.grey400 : context.customColors.grey600, fontSize: 11, letterSpacing: 2,
      )),
    ]);
  }

  // ─── INFO CARD ───
  Widget _infoCard(BuildContext context, bool isDark, dynamic notifier, List<_InfoRow> rows) {
    return Container(
      decoration: AppDecorations.glassCard(context),
      child: Column(children: [
        for (int i = 0; i < rows.length; i++) ...[
          _infoTile(context, isDark, rows[i]),
          if (i < rows.length - 1) Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04), indent: 56),
        ],
      ]),
    );
  }

  Widget _infoTile(BuildContext context, bool isDark, _InfoRow row) {
    return GestureDetector(
      onTap: row.onSave != null ? () => _showEditSheet(context, isDark, row.label, row.value, row.onSave!) : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(row.icon, color: isDark ? context.customColors.grey500 : context.customColors.grey400, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row.label.toUpperCase(), style: TextStyle(
              color: isDark ? context.customColors.grey600 : context.customColors.grey400, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1,
            )),
            const SizedBox(height: 3),
            Text(row.value.isNotEmpty ? row.value : 'Not set', style: AppTypography.bodyMedium.copyWith(
              color: row.value.isNotEmpty ? (isDark ? Colors.white : context.customColors.grey900) : context.customColors.grey500,
              fontSize: 15, fontWeight: FontWeight.w500,
            )),
          ])),
          if (row.onSave != null) Icon(Icons.chevron_right_rounded, color: isDark ? context.customColors.grey700 : context.customColors.grey300, size: 20),
        ]),
      ),
    );
  }

  void _showEditSheet(BuildContext context, bool isDark, String label, String current, ValueChanged<String> onSave) {
    final ctrl = TextEditingController(text: current);
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? context.customColors.grey700 : context.customColors.grey300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('UPDATE ${label.toUpperCase()}', style: AppTypography.labelBold.copyWith(color: isDark ? Colors.white : context.customColors.grey900, letterSpacing: 2)),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl, autofocus: true, textAlign: TextAlign.center,
              style: AppTypography.headlineSmall.copyWith(color: isDark ? Colors.white : context.customColors.grey900),
              decoration: InputDecoration(
                hintText: label, hintStyle: TextStyle(color: isDark ? context.customColors.grey700 : context.customColors.grey300),
                border: InputBorder.none,
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.colors.primary.withValues(alpha: 0.6), width: 2)),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () { if (ctrl.text.trim().isNotEmpty) onSave(ctrl.text.trim()); Navigator.pop(ctx); },
              child: Container(
                width: double.infinity, height: 48,
                decoration: BoxDecoration(gradient: context.customColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text('SAVE', style: AppTypography.labelBold.copyWith(color: Colors.white, letterSpacing: 1.5))),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── ACCOUNT CARD ───
  Widget _accountCard(BuildContext context, bool isDark, UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.glassCard(context),
      child: Column(children: [
        _metaRow(context, isDark, 'PROVIDER', (user?.authProvider ?? 'unknown').toUpperCase()),
        const SizedBox(height: 10),
        _metaRow(context, isDark, 'MEMBER SINCE', _fmtDate(user?.createdAt)),
        const SizedBox(height: 10),
        _metaRow(context, isDark, 'LAST LOGIN', _fmtDate(user?.lastLogin)),
      ]),
    );
  }

  Widget _metaRow(BuildContext context, bool isDark, String label, String val) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: isDark ? context.customColors.grey600 : context.customColors.grey400, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
      Text(val, style: TextStyle(color: isDark ? Colors.white : context.customColors.grey900, fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
  }

  // ─── PREFERENCES ───
  Widget _prefCard(BuildContext context, WidgetRef ref, bool isDark) {
    final themeMode = ref.watch(themeControllerProvider);
    return Container(
      decoration: AppDecorations.glassCard(context),
      child: Column(children: [
        _prefTile(context, isDark, Icons.star_rounded, 'Subscription', 'Upgrade to Pro/Premium', () => context.push('/subscription')),
        _prefDivider(isDark),
        _prefTile(context, isDark, themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          'Theme', isDark ? 'Dark Mode' : 'Light Mode', () => ref.read(themeControllerProvider.notifier).toggleTheme()),
        _prefDivider(isDark),
        _prefTile(context, isDark, Icons.notifications_rounded, 'Notifications', 'Manage alerts', () {}),
        _prefDivider(isDark),
        _prefTile(context, isDark, Icons.security_rounded, 'Security', 'Credentials', () {}),
        _prefDivider(isDark),
        _prefTile(context, isDark, Icons.devices_rounded, 'Devices', 'Sync wearables', () {}),
        _prefDivider(isDark),
        _prefTile(context, isDark, Icons.help_outline_rounded, 'Support', 'FAQ & help', () {}),
      ]),
    );
  }

  Widget _prefTile(BuildContext context, bool isDark, IconData icon, String title, String sub, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: context.colors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: context.colors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: isDark ? Colors.white : context.customColors.grey900, fontSize: 15, fontWeight: FontWeight.w600)),
            Text(sub, style: TextStyle(color: isDark ? context.customColors.grey500 : context.customColors.grey400, fontSize: 11, fontWeight: FontWeight.w400)),
          ])),
          Icon(Icons.chevron_right_rounded, color: isDark ? context.customColors.grey700 : context.customColors.grey300, size: 20),
        ]),
      ),
    );
  }

  Widget _prefDivider(bool isDark) => Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04), indent: 56);

  // ─── LOGOUT ───
  Widget _logoutBtn(BuildContext context, WidgetRef ref, bool isDark) {
    return GestureDetector(
      onTap: () => ref.read(authControllerProvider.notifier).signOut(),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.logout_rounded, color: context.colors.primary, size: 18),
          const SizedBox(width: 8),
          Text('LOG OUT', style: AppTypography.labelBold.copyWith(color: context.colors.primary, letterSpacing: 1.5)),
        ]),
      ),
    );
  }

  // ─── UTILS ───
  String _fmtDate(String? s) {
    if (s == null || s.isEmpty) return 'N/A';
    try { final d = DateTime.parse(s); return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'; } catch (_) { return s; }
  }

  double _calcBMI(String? h, String? w) {
    if (h == null || w == null || h.isEmpty || w.isEmpty) return 0;
    final wl = w.toLowerCase();
    final wd = double.tryParse(wl.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final wKg = wl.contains('lbs') ? wd * 0.4536 : wd;
    final hl = h.toLowerCase();
    double hM = 1.75;
    if (hl.contains('cm')) { hM = (double.tryParse(hl.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 170) / 100; }
    else if (hl.contains('ft') || hl.contains("'")) {
      try { final p = hl.split("'"); final ft = double.tryParse(p[0].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 5;
        final inch = p.length > 1 ? (double.tryParse(p[1].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0) : 0;
        hM = ((ft * 12) + inch) * 0.0254;
      } catch (_) { hM = 1.75; }
    } else { final r = double.tryParse(hl.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 170; hM = r > 100 ? r / 100 : r > 3 ? r * 0.3048 : 1.75; }
    if (hM <= 0 || wKg <= 0) return 0;
    return wKg / (hM * hM);
  }
}

class _InfoRow {
  final String label, value;
  final IconData icon;
  final ValueChanged<String>? onSave;
  _InfoRow(this.label, this.value, this.icon, this.onSave);
}
