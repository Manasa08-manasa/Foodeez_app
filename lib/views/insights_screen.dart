import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/navigation_controller.dart';
import '../services/mock_data.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navigationControllerProvider);
    final r = AppResponsive.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: r.scrollPadding(showDock: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: 'Insights', onBack: nav.back),
            const SizedBox(height: 10),
            Text('Last 7 days', style: AppText.body(size: 12.5, color: AppColors.bodyGrey)),

            GridView.count(
              crossAxisCount: r.gridColumns(phone: 2, tablet: 3, wide: 4),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: r.isTablet ? 1.9 : 1.55,
              children: insightsKpis
                  .map((k) => Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(k.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 11.5, weight: FontWeight.w600, color: AppColors.bodyGrey)),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(k.value, style: AppText.display(size: 21)),
                            ),
                            Text(k.delta, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 11, weight: FontWeight.w600, color: k.up ? AppColors.green : AppColors.red)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sales by day', style: AppText.body(size: 14, weight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(salesByDayPct.length, (i) {
                        final isToday = i == salesByDayTodayIndex;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: FractionallySizedBox(
                                      heightFactor: salesByDayPct[i] / 100,
                                      widthFactor: 1,
                                      child: Container(decoration: BoxDecoration(color: isToday ? AppColors.accent : const Color(0xFFB8D4C8), borderRadius: const BorderRadius.vertical(top: Radius.circular(7)))),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(salesByDayLabels[i], style: AppText.body(size: 10, weight: FontWeight.w700, color: AppColors.bodyGrey)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('Top sellers', style: AppText.body(size: 14, weight: FontWeight.w800))),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
              child: Column(
                children: topSellers().asMap().entries.map((e) {
                  final i = e.key, t = e.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(border: i == topSellers().length - 1 ? null : const Border(bottom: BorderSide(color: AppColors.hairline))),
                    child: Row(
                      children: [
                        SizedBox(width: 16, child: Text('${i + 1}', style: AppText.display(size: 13, color: AppColors.lightGreyText))),
                        const SizedBox(width: 12),
                        ClipRRect(borderRadius: BorderRadius.circular(9), child: FoodImage(photoKey: t.photoKey, width: 34, height: 34)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(t.name, style: AppText.body(size: 13, weight: FontWeight.w700))),
                        Text(t.count, style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.bodyGrey)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
