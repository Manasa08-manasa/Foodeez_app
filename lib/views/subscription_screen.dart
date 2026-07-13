import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mock_data.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/orders_controller.dart';
import '../controllers/earnings_controller.dart';
import '../utils/theme.dart';
import '../utils/utils.dart';
import '../widgets/common.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navigationControllerProvider);
    final ordersCtrl = ref.watch(ordersControllerProvider);
    final earningsCtrl = ref.watch(earningsControllerProvider);
    final curTier = earningsCtrl.subscriptionTierToday;
    final curFee = earningsCtrl.subscriptionFeeToday;
    final into = curTier >= 10 ? 10 : ordersCtrl.doneToday % 10;
    final pct = curTier >= 10 ? 1.0 : into / 10;
    final nextNote = curTier < 10 ? '${10 - into} more orders → Tier ${curTier + 1} · ${moneyFmt(tierFees[curTier])}/day' : 'Top tier — capped at ${moneyFmt(999)}/day';
    final history = [...subscriptionDayHistory, (day: 'Today', orders: ordersCtrl.doneToday)];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: 'Subscription', onBack: nav.back),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: AppColors.greenPaleBg2, border: Border.all(color: AppColors.greenPaleBorder), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Text('✅', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Zero commission — you keep 100% of item sales', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.greenDark))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppColors.heroGradientDeep, borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Today's plan · ${subscriptionTiers[curTier - 1].range} orders", style: AppText.body(size: 12, color: Colors.white.withValues(alpha: 0.85))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text('Tier $curTier', style: AppText.body(size: 10, weight: FontWeight.w800, color: Colors.white)),
                      ),
                    ],
                  ),
                  Text('${moneyFmt(curFee)} /day', style: AppText.display(size: 36, color: Colors.white, height: 1.05)),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${ordersCtrl.doneToday} orders so far today', style: AppText.body(size: 11.5, color: Colors.white.withValues(alpha: 0.85))),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: Colors.white.withValues(alpha: 0.18), valueColor: const AlwaysStoppedAnimation(AppColors.gold)),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.only(top: 8), child: Text(nextNote, style: AppText.body(size: 11, color: Colors.white.withValues(alpha: 0.85)))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Your daily tiers · last 7 days', style: AppText.body(size: 14, weight: FontWeight.w800)),
            const SizedBox(height: 10),
            SizedBox(
              height: 132,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: history.map((h) {
                  final t = tierOf(h.orders);
                  final today = h.day == 'Today';
                  return Container(
                    width: 78,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(color: today ? AppColors.accent : Colors.white, border: Border.all(color: today ? AppColors.accent : AppColors.cardBorder, width: 1.5), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Text(h.day, style: AppText.body(size: 11, weight: FontWeight.w700, color: today ? Colors.white.withValues(alpha: 0.85) : AppColors.bodyGrey)),
                        Padding(padding: const EdgeInsets.only(top: 6), child: Text('T$t', style: AppText.display(size: 20, color: today ? Colors.white : AppColors.ink))),
                        Padding(padding: const EdgeInsets.only(top: 2), child: Text('${h.orders} ord', style: AppText.body(size: 10.5, weight: FontWeight.w600, color: today ? Colors.white.withValues(alpha: 0.75) : AppColors.bodyGrey))),
                        Padding(padding: const EdgeInsets.only(top: 6), child: Text(moneyFmt(tierFeeFor(h.orders)), style: AppText.body(size: 11, weight: FontWeight.w800, color: today ? AppColors.goldBright : AppColors.accent))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Text('Daily subscription tiers', style: AppText.body(size: 14, weight: FontWeight.w800)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: subscriptionTiers.map((t) {
                  final isCur = t.n == curTier;
                  final isPast = t.n < curTier;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(color: isCur ? AppColors.maroonTint : Colors.white, border: const Border(bottom: BorderSide(color: AppColors.hairline))),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(color: isCur ? AppColors.accent : (isPast ? AppColors.greenPaleBg2 : AppColors.cardBorder), borderRadius: BorderRadius.circular(9)),
                          alignment: Alignment.center,
                          child: Text('${t.n}', style: AppText.body(size: 12, weight: FontWeight.w800, color: isCur ? Colors.white : (isPast ? AppColors.green : AppColors.lightGreyText))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${t.range} orders / day', style: AppText.body(size: 13, weight: FontWeight.w700, color: isCur ? AppColors.ink : AppColors.midGrey)),
                              if (isCur) Text("● You're here today", style: AppText.body(size: 10.5, weight: FontWeight.w700, color: AppColors.green)),
                            ],
                          ),
                        ),
                        Text('₹${t.fee}${t.n == 10 ? ' MAX' : ''}', style: AppText.body(size: 13.5, weight: FontWeight.w800, color: isCur ? AppColors.accent : AppColors.bodyGrey)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text('Tier is set fresh each day by that day\'s order count — you never pay more than ₹999/day, no matter how busy.', style: AppText.body(size: 11, color: AppColors.bodyGrey, height: 1.45)),
            ),
            const SizedBox(height: 12),
            Text('Who pays for delivery', style: AppText.body(size: 14, weight: FontWeight.w800)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    color: AppColors.rowPressTint,
                    child: Row(
                      children: [
                        Expanded(flex: 14, child: Text('DISTANCE', style: AppText.body(size: 10.5, weight: FontWeight.w800, color: AppColors.bodyGrey, letterSpacing: 0.4))),
                        Expanded(flex: 10, child: Text('CUSTOMER', textAlign: TextAlign.right, style: AppText.body(size: 10.5, weight: FontWeight.w800, color: AppColors.bodyGrey, letterSpacing: 0.4))),
                        Expanded(flex: 10, child: Text('YOU', textAlign: TextAlign.right, style: AppText.body(size: 10.5, weight: FontWeight.w800, color: AppColors.bodyGrey, letterSpacing: 0.4))),
                      ],
                    ),
                  ),
                  ...deliverySlabs.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline))),
                        child: Row(
                          children: [
                            Expanded(flex: 14, child: Text(s.range, style: AppText.body(size: 12.5, weight: FontWeight.w600))),
                            Expanded(flex: 10, child: Text(s.customer, textAlign: TextAlign.right, style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.midGrey))),
                            Expanded(flex: 10, child: Text(s.restaurant, textAlign: TextAlign.right, style: AppText.body(size: 12.5, weight: FontWeight.w800, color: AppColors.green))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: AppColors.greenPaleBg, border: Border.all(color: AppColors.greenPaleBorder), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: const Text('🎉', style: TextStyle(fontSize: 18))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Onboarding fee ₹0', style: AppText.body(size: 13, weight: FontWeight.w800, color: AppColors.greenDark)),
                        Text(onboardingFeeNote, style: AppText.body(size: 11.5, color: const Color(0xFF5C7A63))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.maroonTintBorder, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('Manage billing & GST invoices', style: AppText.body(size: 13.5, weight: FontWeight.w800, color: AppColors.accent)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
