import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mock_data.dart';
import '../models/order_view.dart';
import '../controllers/orders_controller.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';

class KotModal extends ConsumerWidget {
  const KotModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersControllerProvider);
    final order = orders.kotFor != null ? orders.orderById(orders.kotFor!) : null;
    if (order == null) return const SizedBox.shrink();
    final v = OrderView.of(order);
    final maxH = MediaQuery.sizeOf(context).height * 0.85;
    final maxW = AppResponsive.of(context).isTablet ? 420.0 : 340.0;

    return Positioned.fill(
      child: GestureDetector(
        onTap: orders.closeKot,
        child: Container(
          color: Colors.black.withValues(alpha: 0.55),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: GestureDetector(
            onTap: () {},
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                elevation: 12,
                shadowColor: Colors.black.withValues(alpha: 0.4),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 12),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFDDD5D0), width: 2))),
                        child: Column(
                          children: [
                            Text('KITCHEN ORDER TICKET', textAlign: TextAlign.center, style: AppText.display(size: 16, letterSpacing: 1)),
                            Padding(padding: const EdgeInsets.only(top: 3), child: Text('$restaurantName · Outlet #402', textAlign: TextAlign.center, style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.midGrey))),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            Expanded(child: Text('#${order.id}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 13, weight: FontWeight.w700))),
                            Text(order.type, style: AppText.body(size: 13, weight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('${order.placed} · ${order.customer}', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.body(size: 11.5, color: AppColors.bodyGrey)),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.only(top: 10),
                        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFDDD5D0), width: 2))),
                        child: Column(
                          children: order.lines
                              .map((l) => Padding(
                                    padding: const EdgeInsets.only(bottom: 9),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 26, child: Text('${l.qty}×', style: AppText.body(size: 15, weight: FontWeight.w800))),
                                        Expanded(child: Text(l.name, style: AppText.body(size: 15, weight: FontWeight.w800))),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 10),
                        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFDDD5D0), width: 2))),
                        child: Text(v.etaStr, textAlign: TextAlign.center, style: AppText.body(size: 11.5, weight: FontWeight.w600, color: AppColors.midGrey)),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: ElevatedButton(
                            onPressed: orders.closeKot,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: Text('Send to printer', style: AppText.body(size: 13.5, weight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
