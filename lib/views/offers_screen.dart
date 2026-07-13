import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/offers_controller.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navigationControllerProvider);
    final offersCtrl = ref.watch(offersControllerProvider);
    return SafeArea(
      child: Column(
        children: [
          ScreenHeader(
            title: 'Offers',
            onBack: nav.back,
            trailing: GestureDetector(onTap: nav.toNewCoupon, child: Text('+ New', style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.accent))),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              children: offersCtrl.offers.asMap().entries.map((e) {
                final i = e.key;
                final o = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 22, offset: const Offset(0, 10))]),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(gradient: LinearGradient(colors: o.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(o.title, style: AppText.display(size: 22, color: Colors.white))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(color: o.live ? Colors.white.withValues(alpha: 0.24) : Colors.black.withValues(alpha: 0.28), borderRadius: BorderRadius.circular(20)),
                                  child: Text(o.live ? 'ACTIVE' : 'PAUSED', style: AppText.body(size: 10, weight: FontWeight.w800, color: Colors.white)),
                                ),
                              ],
                            ),
                            Padding(padding: const EdgeInsets.only(top: 3), child: Text(o.sub, style: AppText.body(size: 12.5, color: Colors.white.withValues(alpha: 0.9)))),
                            Container(
                              margin: const EdgeInsets.only(top: 11),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.5, style: BorderStyle.solid), borderRadius: BorderRadius.circular(9)),
                              child: Text(o.code, style: AppText.body(size: 12, weight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${o.redeemed} redeemed', style: AppText.body(size: 12, weight: FontWeight.w600, color: AppColors.bodyGrey)),
                            GestureDetector(onTap: () => offersCtrl.toggleOfferLive(i), child: Text(o.live ? 'Pause' : 'Resume', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.accent))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
