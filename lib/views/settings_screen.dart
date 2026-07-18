import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/settings_controller.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const List<(String key, IconData icon, String title, String subtitle)> _toggles = [
    ('autoAccept', Icons.flash_on_outlined, 'Auto-accept orders', 'Skip the manual accept step'),
    ('busyMode', Icons.timer_outlined, 'Busy mode', 'Add +10 min to prep times'),
    ('veg', Icons.eco_outlined, 'Pure-veg badge', 'Show veg-only on your listing'),
    ('petpooja', Icons.link_outlined, 'Petpooja POS', 'Sync menu & orders with Petpooja'),
    ('kotPrinter', Icons.print_outlined, 'KOT printer', 'Auto-print kitchen tickets on accept'),
  ];

  static const List<(IconData icon, String title, String route)> _links = [
    (Icons.credit_card_outlined, 'Subscription & billing', 'subscription'),
    (Icons.local_offer_outlined, 'Offers & coupons', 'offers'),
    (Icons.schedule_outlined, 'Operating hours', 'hours'),
    (Icons.location_on_outlined, 'Address & location', 'address'),
    (Icons.description_outlined, 'FSSAI & documents', 'fssai'),
    (Icons.account_balance_outlined, 'Bank & payouts', 'earnings'),
    (Icons.help_outline, 'Help & support', 'support'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navigationControllerProvider);
    final settingsCtrl = ref.watch(settingsControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final fssaiOk = auth.restaurant?.fssaiNumber != null && auth.restaurant!.fssaiNumber!.isNotEmpty;
    return SafeArea(
      child: SingleChildScrollView(
        padding: AppResponsive.of(context).scrollPadding(showDock: true, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: 'Restaurant', onBack: nav.back),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Container(width: 54, height: 54, decoration: BoxDecoration(color: AppColors.maroonTint, borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: Text(auth.initials, style: AppText.body(size: 20, weight: FontWeight.w800, color: AppColors.accent))),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.displayName, style: AppText.display(size: 16)),
                        Text(auth.locationLine, style: AppText.body(size: 12, color: AppColors.bodyGrey)),
                        Padding(padding: const EdgeInsets.only(top: 3), child: Text(fssaiOk ? 'FSSAI verified ✓' : 'FSSAI pending', style: AppText.body(size: 11.5, weight: FontWeight.w600, color: fssaiOk ? AppColors.green : AppColors.amber))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: _toggles.map((t) {
                  final (key, icon, title, subtitle) = t;
                  final on = settingsCtrl.settings[key] ?? false;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
                    child: Row(
                      children: [
                        Icon(icon, size: 17, color: AppColors.ink),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AppText.body(size: 13.5, weight: FontWeight.w700)),
                              Text(subtitle, style: AppText.body(size: 11.5, color: AppColors.bodyGrey)),
                            ],
                          ),
                        ),
                        ToggleSwitch(on: on, onTap: () => settingsCtrl.toggleSetting(key)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: _links.map((l) {
                      final (icon, title, route) = l;
                      return GestureDetector(
                        onTap: () => nav.go(route),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
                          child: Row(
                            children: [
                              Icon(icon, size: 20, color: AppColors.ink),
                              const SizedBox(width: 12),
                              Expanded(child: Text(title, style: AppText.body(size: 13.5, weight: FontWeight.w700))),
                              const Icon(Icons.chevron_right, size: 18, color: AppColors.chevronGrey),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => ref.read(authControllerProvider).logout(),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.redPaleBorder, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('Log out', style: AppText.body(size: 14, weight: FontWeight.w800, color: AppColors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
