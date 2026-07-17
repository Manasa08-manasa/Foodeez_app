import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/order_status_utils.dart';
import '../models/models.dart';
import '../models/order_view.dart';
import '../controllers/orders_controller.dart';
import '../utils/theme.dart';

class IncomingOrderAlert extends ConsumerStatefulWidget {
  const IncomingOrderAlert({super.key});

  @override
  ConsumerState<IncomingOrderAlert> createState() => _IncomingOrderAlertState();
}

class _IncomingOrderAlertState extends ConsumerState<IncomingOrderAlert> with SingleTickerProviderStateMixin {
  late final AnimationController _bell;

  @override
  void initState() {
    super.initState();
    _bell = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _bell.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersControllerProvider);
    final alertId = orders.alertOrderId;
    final incoming = orders.orders.where((o) => OrderStatusUtils.isPlaced(orders.apiStatus(o.id))).toList();
    if (incoming.isEmpty) return const SizedBox.shrink();
    final order = alertId != null
        ? orders.orderById(alertId) ?? incoming.first
        : incoming.first;
    if (order.status != OrderStatus.incoming && !OrderStatusUtils.isPlaced(orders.apiStatus(order.id))) return const SizedBox.shrink();
    final v = OrderView.of(order, apiStatus: orders.apiStatus(order.id));

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: AnimatedBuilder(
                  animation: _bell,
                  builder: (context, _) {
                    final t = _bell.value;
                    final ring = (t * 5).floor() % 5;
                    const angles = [0.0, -0.24, 0.21, -0.14, 0.1];
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: (1 - t).clamp(0, 1) * 0.25,
                          child: Transform.scale(scale: 0.7 + t * 1.3, child: Container(width: 56, height: 56, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green))),
                        ),
                        Transform.rotate(
                          angle: angles[ring],
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green),
                            alignment: Alignment.center,
                            child: const Text('🔔', style: TextStyle(fontSize: 26)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text('New order!', style: AppText.display(size: 20)),
              Padding(padding: const EdgeInsets.only(top: 2), child: Text('${v.typeLine} · respond in ${orders.alertCountdown}s', style: AppText.body(size: 12.5, color: AppColors.bodyGrey))),
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('#${order.id} · ${order.customer}', style: AppText.body(size: 14, weight: FontWeight.w800)),
                        Text(v.totalStr, style: AppText.body(size: 14, weight: FontWeight.w800)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        children: order.lines
                            .map((l) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${l.qty}× ${l.name}', style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.midGrey)),
                                      Text('₹${l.lineTotal}', style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.bodyGrey)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(top: 10), child: Text(order.payLabel, style: AppText.body(size: 11.5, weight: FontWeight.w600, color: AppColors.green))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => orders.reject(order.id),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.redPaleBorder, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: Text('Reject', style: AppText.body(size: 14, weight: FontWeight.w800, color: AppColors.red)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => orders.askPrep(order.id),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: Text('Accept order', style: AppText.body(size: 14, weight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
