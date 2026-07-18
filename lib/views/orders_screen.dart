import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/orders_controller.dart';
import '../models/models.dart';
import '../models/order_view.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  static const _tabs = ['new', 'preparing', 'outForDelivery', 'completed'];
  static const _tabLabels = ['New', 'Preparing', 'Out for delivery', 'Completed'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersControllerProvider).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersControllerProvider);
    final selectedTabIx = _tabs.indexOf(orders.ordersTab);
    final list = orders.tabOrders(orders.ordersTab);
    final bottomPad = AppResponsive.of(context).dockClearance(showDock: true);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            title: 'Orders',
            onBack: () => ref.read(navigationControllerProvider).back(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Track incoming, ready, and completed orders in one place.', style: AppText.body(size: 13.5, color: AppColors.bodyGrey)),
              ],
            ),
          ),
          ScrollableTabPills(
            labels: _tabLabels,
            counts: [orders.newCount, orders.prepCount, orders.readyCount, orders.completedCount],
            selectedIndex: selectedTabIx < 0 ? 0 : selectedTabIx,
            onSelect: (i) => orders.setOrdersTab(_tabs[i]),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(ordersControllerProvider).refresh(),
              child: list.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPad),
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Nothing here yet', style: AppText.body(size: 15, weight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(
                                  switch (orders.ordersTab) {
                                    'new' => 'New incoming orders will show here.',
                                    'preparing' => 'Accepted orders being prepared will show here.',
                                    'outForDelivery' => 'Orders marked ready or out with a rider will show here.',
                                    'completed' => 'Orders completed today will appear here.',
                                    _ => 'Orders will show here.',
                                  },
                                  textAlign: TextAlign.center,
                                  style: AppText.body(size: 12.5, color: AppColors.bodyGrey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPad),
                      children: list.map((o) => _OrderCard(order: o)).toList(),
                    ),
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
    final v = OrderView.of(order, apiStatus: orders.apiStatus(order.id));
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
                      Flexible(child: Text('#${order.id}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 14, weight: FontWeight.w700))),
                      const SizedBox(width: 8),
                      Text(order.placed, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 12, color: AppColors.bodyGrey)),
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
                      Flexible(
                        child: Text(order.customer, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 13, weight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text('· ${v.typeLine}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 11.5, weight: FontWeight.w600, color: AppColors.bodyGrey)),
                      ),
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
                                  children: [
                                    Expanded(
                                      child: Text('${l.qty}× ${l.name}', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.midGrey)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('₹${l.lineTotal}', style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.bodyGrey)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Expanded(child: Text(v.totalStr, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 14, weight: FontWeight.w800))),
                      const SizedBox(width: 8),
                      Flexible(child: Text(order.payLabel, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: AppText.body(size: 11.5, weight: FontWeight.w600, color: AppColors.bodyGrey))),
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
