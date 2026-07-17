import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../models/order_view.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/orders_controller.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navigationControllerProvider);
    final orders = ref.watch(ordersControllerProvider);
    final order = orders.oid != null ? orders.orderById(orders.oid!) : null;
    if (order == null) {
      return SafeArea(child: Center(child: Text('Order not found', style: AppText.body(size: 14))));
    }
    final v = OrderView.of(order);
    final tax = (order.total * 0.05).round();
    final grand = order.total + tax;
    final totalQty = order.lines.fold(0, (a, l) => a + l.qty);
    final custMeta = order.type == OrderType.dining ? 'Dine-in' : (order.dist.isNotEmpty ? '${order.dist} away · $totalQty items' : '$totalQty items');
    final showRider = (order.status == OrderStatus.ready || order.status == OrderStatus.outForDelivery) && order.type == OrderType.delivery;
    final riderMeta = order.status == OrderStatus.outForDelivery ? 'OTP verified · on the way to customer' : 'Arriving at your kitchen · 4 min';
    final showFooter = order.status == OrderStatus.incoming || order.status == OrderStatus.preparing || order.status == OrderStatus.ready;

    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 4, 16, showFooter ? 110 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScreenHeader(
                        title: 'Order #${order.id}',
                        onBack: nav.back,
                        trailing: StatusBadge(label: v.statusLabel, fg: v.statusFg, bg: v.statusBg),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 2),
                        child: Text('${order.placed} · ${v.typeLine}', style: AppText.body(size: 12, color: AppColors.bodyGrey)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.maroonTint),
                        alignment: Alignment.center,
                        child: Text(v.custInitials, style: AppText.body(size: 16, weight: FontWeight.w800, color: AppColors.accent)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.customer, style: AppText.body(size: 15, weight: FontWeight.w800)),
                            Text(custMeta, style: AppText.body(size: 12, color: AppColors.bodyGrey)),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.greenPaleBg2, borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: const Icon(Icons.phone_outlined, size: 18, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    children: [
                      ...order.lines.map((l) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(border: Border.all(color: l.veg ? AppColors.vegDot : AppColors.nonVegDot, width: 2), borderRadius: BorderRadius.circular(4)),
                                  alignment: Alignment.center,
                                  child: Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: l.veg ? AppColors.vegDot : AppColors.nonVegDot)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text('${l.qty} × ${l.name}', style: AppText.body(size: 13.5, weight: FontWeight.w700))),
                                Text('₹${l.lineTotal}', style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.midGrey)),
                              ],
                            ),
                          )),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            _billRow('Item total', '₹${order.total}'),
                            _billRow('Taxes & charges', '₹$tax'),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.only(top: 8),
                              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline, style: BorderStyle.solid))),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total bill', style: AppText.body(size: 15, weight: FontWeight.w800)),
                                  Text('₹$grand', style: AppText.body(size: 15, weight: FontWeight.w800)),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(order.payLabel, style: AppText.body(size: 12, weight: FontWeight.w600, color: AppColors.green)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (v.showOtp) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(gradient: AppColors.heroGradientDeep, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Pickup OTP', style: AppText.body(size: 12, color: Colors.white.withValues(alpha: 0.9))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                              child: Text('RIDER ENTERS THIS', style: AppText.body(size: 10, weight: FontWeight.w700, color: Colors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child: Text(v.otp, style: AppText.display(size: 22, color: Colors.white, letterSpacing: 2)),
                        ),
                        const SizedBox(height: 9),
                        Text('Share only with the assigned Foodeez rider at handover.', style: AppText.body(size: 11, color: Colors.white.withValues(alpha: 0.82))),
                      ],
                    ),
                  ),
                ],
                if (showRider) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: [
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.amberPaleBg, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: const Icon(Icons.delivery_dining_outlined, size: 18, color: AppColors.ink)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Suresh · Foodeez rider', style: AppText.body(size: 13.5, weight: FontWeight.w700)),
                              Text(riderMeta, style: AppText.body(size: 12, color: AppColors.bodyGrey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (v.isOutForDelivery) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                    decoration: BoxDecoration(color: AppColors.bluePaleBg, border: Border.all(color: AppColors.bluePaleBorder), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18, color: AppColors.blue),
                            const SizedBox(width: 9),
                            Text('Rider is delivering to customer', style: AppText.body(size: 12.5, weight: FontWeight.w800, color: AppColors.blue)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text('The rider closes this in their app once the customer receives it — it will then show as Delivered.', style: AppText.body(size: 11.5, color: const Color(0xFF5C6B78), height: 1.45)),
                        const SizedBox(height: 11),
                        GestureDetector(
                          onTap: () => orders.advance(order.id),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFA9CBEA), width: 1.5), borderRadius: BorderRadius.circular(11)),
                            alignment: Alignment.center,
                            child: Text('▸ Simulate: rider delivered', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.blue)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showFooter)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                decoration: BoxDecoration(color: Colors.white, border: const Border(top: BorderSide(color: AppColors.hairline)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, -6))]),
                child: v.isIncoming
                    ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => orders.reject(order.id),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.redPaleBorder, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              child: Text('Reject', style: AppText.body(size: 14, weight: FontWeight.w800, color: AppColors.red)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () => orders.askPrep(order.id),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              child: Text('Accept order', style: AppText.body(size: 14, weight: FontWeight.w800, color: Colors.white)),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => orders.openKot(order.id),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.maroonTintBorder, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              child: Text('🧾 KOT', style: AppText.body(size: 14, weight: FontWeight.w800, color: AppColors.accent)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () => orders.advance(order.id),
                              style: ElevatedButton.styleFrom(backgroundColor: v.actionColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              child: Text(v.actionLabel, style: AppText.body(size: 15, weight: FontWeight.w800, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.bodyGrey)),
            Text(value, style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.bodyGrey)),
          ],
        ),
      );
}
