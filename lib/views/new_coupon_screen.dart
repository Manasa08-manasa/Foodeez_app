import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mock_data.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/offers_controller.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class NewCouponScreen extends ConsumerWidget {
  const NewCouponScreen({super.key});

  static const List<(String key, String label, IconData icon, String suffix)> _types = [
    ('flat', 'Flat ₹ off', Icons.currency_rupee, '₹'),
    ('percent', '% off', Icons.percent_outlined, '%'),
    ('freedelivery', 'Free delivery', Icons.delivery_dining_outlined, '🛵'),
    ('freeitem', 'Free item', Icons.card_giftcard_outlined, '🎁'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navigationControllerProvider);
    final offersCtrl = ref.watch(offersControllerProvider);
    final preview = offersCtrl.buildCouponPreview();

    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScreenHeader(title: 'New coupon', onBack: nav.back),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 22, offset: const Offset(0, 10))]),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: preview.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(preview.title, style: AppText.display(size: 22, color: Colors.white))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(20)),
                              child: Text('PREVIEW', style: AppText.body(size: 10, weight: FontWeight.w800, color: Colors.white)),
                            ),
                          ],
                        ),
                        Padding(padding: const EdgeInsets.only(top: 3), child: Text(preview.sub, style: AppText.body(size: 12.5, color: Colors.white.withValues(alpha: 0.9)))),
                        Container(
                          margin: const EdgeInsets.only(top: 11),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.5), borderRadius: BorderRadius.circular(9)),
                          child: Text(preview.code, style: AppText.body(size: 12, weight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(padding: const EdgeInsets.fromLTRB(2, 18, 2, 9), child: Text('DISCOUNT TYPE', style: AppText.body(size: 12, weight: FontWeight.w800, color: AppColors.bodyGrey, letterSpacing: 0.4))),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 3.2,
                  children: _types.map((t) {
                    final (key, label, icon, suffix) = t;
                    final selected = offersCtrl.couponType == key;
                    return GestureDetector(
                      onTap: () => offersCtrl.pickCouponType(key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(color: selected ? AppColors.accent : Colors.white, border: Border.all(color: selected ? AppColors.accent : AppColors.chipBorder, width: 1.5), borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            Icon(icon, size: 18, color: selected ? AppColors.goldBright : AppColors.accent),
                            const SizedBox(width: 9),
                            Text(label, style: AppText.body(size: 12.5, weight: FontWeight.w800, color: selected ? Colors.white : AppColors.midGrey)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                Padding(padding: const EdgeInsets.fromLTRB(2, 18, 2, 9), child: Text('COUPON CODE', style: AppText.body(size: 12, weight: FontWeight.w800, color: AppColors.bodyGrey, letterSpacing: 0.4))),
                TextField(
                  onChanged: offersCtrl.setCouponCode,
                  textCapitalization: TextCapitalization.characters,
                  style: AppText.body(size: 15, weight: FontWeight.w800, letterSpacing: 1),
                  decoration: InputDecoration(
                    hintText: offersCtrl.suggestedCouponCode,
                    hintStyle: AppText.body(size: 15, weight: FontWeight.w800, color: AppColors.lightGreyText, letterSpacing: 1),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
                  ),
                ),
                if (offersCtrl.couponType == 'flat') ...[
                  const SizedBox(height: 14),
                  LabeledStepperRow(label: 'Discount amount', sub: 'Flat off the bill', valueStr: '₹${offersCtrl.couponValue}', onDec: () => offersCtrl.bumpCouponValue(-10), onInc: () => offersCtrl.bumpCouponValue(10)),
                ],
                if (offersCtrl.couponType == 'percent') ...[
                  const SizedBox(height: 14),
                  LabeledStepperRow(label: 'Discount percent', sub: '% off the item total', valueStr: '${offersCtrl.couponPercent}%', onDec: () => offersCtrl.bumpCouponPercent(-5), onInc: () => offersCtrl.bumpCouponPercent(5)),
                  const SizedBox(height: 10),
                  LabeledStepperRow(label: 'Max discount cap', sub: 'Upper limit on the % off', valueStr: '₹${offersCtrl.couponCap}', onDec: () => offersCtrl.bumpCouponCap(-10), onInc: () => offersCtrl.bumpCouponCap(10)),
                ],
                if (offersCtrl.couponType == 'freedelivery') ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                    decoration: BoxDecoration(color: AppColors.greenPaleBg2, border: Border.all(color: AppColors.greenPaleBorder), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const Icon(Icons.delivery_dining_outlined, size: 18, color: AppColors.greenDark),
                        const SizedBox(width: 11),
                        Expanded(child: Text('Delivery fee is waived for the customer. Foodeez still pays the rider — you pay ₹0.', style: AppText.body(size: 12, weight: FontWeight.w600, color: AppColors.greenDark, height: 1.45))),
                      ],
                    ),
                  ),
                ],
                if (offersCtrl.couponType == 'freeitem') ...[
                  Padding(padding: const EdgeInsets.fromLTRB(2, 18, 2, 9), child: Text('FREE ITEM', style: AppText.body(size: 12, weight: FontWeight.w800, color: AppColors.bodyGrey, letterSpacing: 0.4))),
                  ...menuItems.map((m) {
                    final selected = offersCtrl.couponFreeItemId == m.id;
                    return GestureDetector(
                      onTap: () => offersCtrl.setCouponFreeItem(m.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                        decoration: BoxDecoration(color: selected ? AppColors.maroonTint : Colors.white, border: Border.all(color: selected ? AppColors.accent : AppColors.chipBorder, width: 1.5), borderRadius: BorderRadius.circular(13)),
                        child: Row(
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(9), child: FoodImage(photoKey: m.photoKey, width: 36, height: 36)),
                            const SizedBox(width: 11),
                            Expanded(child: Text(m.name, style: AppText.body(size: 13, weight: FontWeight.w700))),
                            Text('₹${m.basePrice}', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey)),
                            const SizedBox(width: 10),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? AppColors.accent : AppColors.lightGreyText, width: 2)),
                              alignment: Alignment.center,
                              child: selected ? Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent)) : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                Padding(padding: const EdgeInsets.fromLTRB(2, 18, 2, 9), child: Text('CONDITIONS', style: AppText.body(size: 12, weight: FontWeight.w800, color: AppColors.bodyGrey, letterSpacing: 0.4))),
                LabeledStepperRow(
                  label: 'Minimum order',
                  sub: 'Cart must reach this to apply',
                  valueStr: offersCtrl.couponMinOrder > 0 ? '₹${offersCtrl.couponMinOrder}' : 'No min',
                  onDec: () => offersCtrl.bumpCouponMinOrder(-50),
                  onInc: () => offersCtrl.bumpCouponMinOrder(50),
                ),
                const SizedBox(height: 10),
                LabeledStepperRow(label: 'Valid for', sub: 'Days from launch', valueStr: '${offersCtrl.couponValidDays} d', onDec: () => offersCtrl.bumpCouponValidDays(-1), onInc: () => offersCtrl.bumpCouponValidDays(1)),
                const SizedBox(height: 10),
                LabeledStepperRow(
                  label: 'Total redemptions',
                  sub: 'Cap across all customers',
                  valueStr: offersCtrl.couponLimitTotal >= 9999 ? 'Unlimited' : '${offersCtrl.couponLimitTotal}',
                  onDec: () => offersCtrl.bumpCouponLimitTotal(-100),
                  onInc: () => offersCtrl.bumpCouponLimitTotal(100),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.chipBorder, width: 1.5), borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_outlined, size: 17, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('First order only', style: AppText.body(size: 13, weight: FontWeight.w700)),
                            Text('New customers, first Foodeez order', style: AppText.body(size: 11, color: AppColors.bodyGrey)),
                          ],
                        ),
                      ),
                      ToggleSwitch(on: offersCtrl.couponFirstOnly, onTap: offersCtrl.toggleCouponFirstOnly),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              decoration: BoxDecoration(color: Colors.white, border: const Border(top: BorderSide(color: AppColors.hairline)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, -6))]),
              child: PrimaryButton(label: 'Create coupon', onTap: offersCtrl.createCoupon),
            ),
          ),
        ],
      ),
    );
  }
}
