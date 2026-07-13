import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mock_data.dart';
import '../controllers/navigation_controller.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navigationControllerProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: 'Help & support', onBack: nav.back),
            ...supportChannels.map((c) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.maroonTint, borderRadius: BorderRadius.circular(13)), alignment: Alignment.center, child: Text(c.emoji, style: const TextStyle(fontSize: 19))),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.label, style: AppText.body(size: 14, weight: FontWeight.w800)),
                            Text(c.sub, style: AppText.body(size: 12, color: AppColors.bodyGrey)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.chevronGrey),
                    ],
                  ),
                )),
            const SizedBox(height: 10),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('Frequently asked', style: AppText.body(size: 14, weight: FontWeight.w800))),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
              child: Column(
                children: supportFaqs
                    .map((f) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.q, style: AppText.body(size: 13, weight: FontWeight.w700)),
                              Padding(padding: const EdgeInsets.only(top: 5), child: Text(f.a, style: AppText.body(size: 12.5, color: AppColors.bodyGrey, height: 1.5))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
