import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../models/order_view.dart';
import '../controllers/orders_controller.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  static const _tabs = ['ongoing', 'ready', 'completed'];
  static const _tabLabels = ['Ongoing', 'Ready', 'History'];
  static const _typeChips = [
    ('all', 'All'),
    (OrderType.delivery, 'Delivery'),
    (OrderType.takeaway, 'Takeaway'),
    (OrderType.dining, 'Dine-in'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersControllerProvider);
    final selectedTabIx = _tabs.indexOf(orders.ordersTab);
    final list = orders.tabOrders(orders.ordersTab);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Orders', style: AppText.display(size: 20)),
                const SizedBox(height: 14),
                SegmentedPills(
                  labels: _tabLabels,
                  counts: [orders.newCount + orders.prepCount, orders.readyCount, 0],
                  selectedIndex: selectedTabIx < 0 ? 0 : selectedTabIx,
                  onSelect: (i) => orders.setOrdersTab(_tabs[i]),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: _typeChips
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FzChip(label: c.$2, selected: orders.orderTypeFilter == c.$1, onTap: () => orders.setOrderTypeFilter(c.$1)),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Nothing here yet', style: AppText.body(size: 15, weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            orders.ordersTab == 'ready'
                                ? 'Orders marked ready will show here.'
                                : (orders.ordersTab == 'completed' ? 'Completed orders will appear here.' : 'New and preparing orders will show here.'),
                            textAlign: TextAlign.center,
                            style: AppText.body(size: 12.5, color: AppColors.bodyGrey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                    children: list.map((o) => _OrderCard(order: o)).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.read(ordersControllerProvider);
    final v = OrderView.of(order);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => orders.openOrder(order.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusBadge(label: v.statusLabel, fg: v.statusFg, bg: v.statusBg),
                      const SizedBox(width: 9),
                      Text('#${order.id}', style: AppText.body(size: 14, weight: FontWeight.w700)),
                      const Spacer(),
                      Text(order.placed, style: AppText.body(size: 12, color: AppColors.bodyGrey)),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.maroonTint),
                        alignment: Alignment.center,
                        child: Text(v.custInitials, style: AppText.body(size: 11, weight: FontWeight.w800, color: AppColors.accent)),
                      ),
                      const SizedBox(width: 8),
                      Text(order.customer, style: AppText.body(size: 13, weight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      Text('· ${v.typeLine}', style: AppText.body(size: 11.5, weight: FontWeight.w600, color: AppColors.bodyGrey)),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline, width: 1))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: order.lines
                          .map((l) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.5),
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
                  const SizedBox(height: 11),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(v.totalStr, style: AppText.body(size: 14, weight: FontWeight.w800)),
                      Text(order.payLabel, style: AppText.body(size: 11.5, weight: FontWeight.w600, color: AppColors.bodyGrey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (v.isIncoming)
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => orders.reject(order.id),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: const RoundedRectangleBorder(), backgroundColor: Colors.white),
                    child: Text('Reject', style: AppText.body(size: 13.5, weight: FontWeight.w800, color: AppColors.red)),
                  ),
                ),
                Container(width: 1, height: 44, color: AppColors.cardBorder),
                Expanded(
                  flex: 2,
                  child: TextButton(
                    onPressed: () => orders.askPrep(order.id),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: const RoundedRectangleBorder(), backgroundColor: AppColors.green),
                    child: Text('Accept order', style: AppText.body(size: 13.5, weight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ],
            )
          else if (v.hasAdvance)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => orders.advance(order.id),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(),
                  backgroundColor: v.actionColor,
                ),
                child: Text(v.actionLabel, style: AppText.body(size: 13.5, weight: FontWeight.w800, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}
