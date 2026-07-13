import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/navigation_controller.dart';
import '../services/mock_data.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class HoursScreen extends ConsumerWidget {
  const HoursScreen({super.key});

  String _fmt(String? t) {
    if (t == null || t.isEmpty) return '';
    // Accept HH:mm or already-formatted strings.
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1].padLeft(2, '0');
    final suffix = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $suffix';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navigationControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final branch = auth.activeBranch;
    final openLabel = branch?.openingTime != null && branch?.closingTime != null
        ? '${_fmt(branch!.openingTime)} – ${_fmt(branch.closingTime)}'
        : null;
    final statusTitle = branch == null
        ? 'Open now · closes 11:30 PM'
        : (branch.isOnline
            ? 'Open now · closes ${_fmt(branch.closingTime)}'
            : 'Closed');
    final rows = openLabel == null
        ? hoursRows
        : hoursRows
            .map((r) => (day: r.day, time: r.open ? openLabel : 'Closed', open: r.open && (branch?.isOnline ?? true)))
            .toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: 'Operating hours', onBack: nav.back),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: (branch?.isOnline ?? true) ? AppColors.greenPaleBg2 : AppColors.redPaleBg,
                border: Border.all(color: (branch?.isOnline ?? true) ? AppColors.greenPaleBorder : AppColors.redPaleBorder),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (branch?.isOnline ?? true) ? AppColors.green : AppColors.red,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(statusTitle, style: AppText.body(size: 13.5, weight: FontWeight.w800, color: (branch?.isOnline ?? true) ? AppColors.greenDark : AppColors.redDark)),
                      Text(
                        (branch?.isOnline ?? true) ? 'Kitchen accepting orders' : 'Not accepting orders',
                        style: AppText.body(size: 11.5, color: const Color(0xFF5C7A63)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: rows
                    .map((r) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
                          child: Row(
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: r.open ? AppColors.green : AppColors.lightGreyText)),
                              const SizedBox(width: 11),
                              Expanded(child: Text(r.day, style: AppText.body(size: 13.5, weight: FontWeight.w700))),
                              Text(r.time, style: AppText.body(size: 12.5, weight: FontWeight.w600, color: r.open ? AppColors.ink : AppColors.nonVegDot)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.maroonTintBorder, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('Edit hours', style: AppText.body(size: 13.5, weight: FontWeight.w800, color: AppColors.accent)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
