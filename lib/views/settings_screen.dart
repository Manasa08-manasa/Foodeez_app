import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/settings_controller.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _toggles = [
    ('autoAccept', '⚡', 'Auto-accept orders', 'Skip the manual accept step'),
    ('busyMode', '⏱️', 'Busy mode', 'Add +10 min to prep times'),
    ('veg', '🌿', 'Pure-veg badge', 'Show veg-only on your listing'),
    ('petpooja', '🔗', 'Petpooja POS', 'Sync menu & orders with Petpooja'),
    ('kotPrinter', '🖨️', 'KOT printer', 'Auto-print kitchen tickets on accept'),
  ];

  static const _links = [
    ('💳', 'Subscription & billing', 'subscription'),
    ('🎁', 'Offers & coupons', 'offers'),
    ('🕑', 'Operating hours', 'hours'),
    ('📍', 'Address & location', 'address'),
    ('📄', 'FSSAI & documents', 'fssai'),
    ('🏦', 'Bank & payouts', 'earnings'),
    ('💬', 'Help & support', 'support'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navigationControllerProvider);
    final settingsCtrl = ref.watch(settingsControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final fssaiOk = auth.restaurant?.fssaiNumber != null && auth.restaurant!.fssaiNumber!.isNotEmpty;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 12), child: Text('Restaurant', style: AppText.display(size: 20))),
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
                  final on = settingsCtrl.settings[t.$1] ?? false;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
                    child: Row(
                      children: [
                        Text(t.$2, style: const TextStyle(fontSize: 17)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.$3, style: AppText.body(size: 13.5, weight: FontWeight.w700)),
                              Text(t.$4, style: AppText.body(size: 11.5, color: AppColors.bodyGrey)),
                            ],
                          ),
                        ),
                        ToggleSwitch(on: on, onTap: () => settingsCtrl.toggleSetting(t.$1)),
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
                children: _links.map((l) => GestureDetector(
                      onTap: () => nav.go(l.$3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
                        child: Row(
                          children: [
                            Text(l.$1, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(l.$2, style: AppText.body(size: 13.5, weight: FontWeight.w700))),
                            const Icon(Icons.chevron_right, size: 18, color: AppColors.chevronGrey),
                          ],
                        ),
                      ),
                    ))
                    .toList(),
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
