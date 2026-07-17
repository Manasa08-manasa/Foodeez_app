import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../models/order_view.dart';
import '../controllers/auth_controller.dart';
import '../controllers/earnings_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/orders_controller.dart';
import '../controllers/reviews_controller.dart';
import '../utils/theme.dart';
import '../utils/utils.dart';
import '../widgets/common.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navigationControllerProvider);
    final orders = ref.watch(ordersControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final earnings = ref.watch(earningsControllerProvider);
    final reviews = ref.watch(reviewsControllerProvider);
    final live = orders.liveOrders;
    final todayLabel = DateFormat('EEE, d MMM').format(DateTime.now());
    final todayEarn = earnings.currentEarningsPeriod;
    final earnValue = earnings.usingApi ? earnings.apiNet : orders.gmvToday;
    final ratingLabel = reviews.usingApi ? reviews.averageRating.toStringAsFixed(1) : '4.5';
    final prepMins = live.isEmpty
        ? 16
        : (live.map((o) => o.prepMinutes).fold<int>(0, (a, b) => a + b) / live.length).round();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.display(size: 20, letterSpacing: -0.3)),
                      Text(auth.locationLine, style: AppText.body(size: 12.5, color: AppColors.bodyGrey)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: nav.toSettings,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.maroonTint, border: Border.all(color: AppColors.maroonTintBorder, width: 1.5)),
                    alignment: Alignment.center,
                    child: Text(auth.initials, style: AppText.body(size: 15, weight: FontWeight.w800, color: AppColors.accent)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: orders.toggleOnline,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                decoration: BoxDecoration(
                  color: orders.online ? AppColors.greenPaleBg : AppColors.redPaleBg,
                  border: Border.all(color: orders.online ? AppColors.greenPaleBorder : AppColors.redPaleBorder, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(width: 11, height: 11, decoration: BoxDecoration(shape: BoxShape.circle, color: orders.online ? AppColors.green : AppColors.red)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(orders.online ? 'Online — accepting orders' : 'Offline', style: AppText.body(size: 15, weight: FontWeight.w800, color: orders.online ? AppColors.greenDark : AppColors.redDark)),
                          Text(orders.online ? 'Customers can order right now' : 'You will not receive new orders', style: AppText.body(size: 12, color: AppColors.bodyGrey)),
                        ],
                      ),
                    ),
                    ToggleSwitch(on: orders.online, onTap: orders.toggleOnline, width: 46, height: 27),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TODAY', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey, letterSpacing: 1)),
                Text(todayLabel, style: AppText.body(size: 12, weight: FontWeight.w600, color: AppColors.bodyGrey)),
              ],
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                GestureDetector(
                  onTap: nav.toEarnings,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(18)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Earnings', style: AppText.body(size: 12, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85))),
                            Text('→', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                          ],
                        ),
                        Text(moneyFmt(earnValue), style: AppText.display(size: 22, color: Colors.white)),
                        Text(
                          earnings.usingApi ? '${todayEarn.orders} orders today' : '▲ 12% vs yesterday',
                          style: AppText.body(size: 11, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                ),
                _statCard('Orders', (earnings.usingApi ? earnings.apiOrderCount : orders.todayOrdersCount).toString(), sub: '${live.length} live now', subColor: AppColors.green),
                _statCard('Avg prep time', '$prepMins min'),
                GestureDetector(
                  onTap: nav.toReviews,
                  child: _statCard('Rating', ratingLabel, star: true),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Live orders', style: AppText.display(size: 16)),
                GestureDetector(onTap: nav.toOrders, child: Text('View all →', style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.accent))),
              ],
            ),
            const SizedBox(height: 11),
            if (live.isEmpty)
              SizedBox(
                width: double.infinity,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('No live orders', style: AppText.body(size: 14, weight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(
                        'New orders appear here instantly.',
                        textAlign: TextAlign.center,
                        style: AppText.body(size: 12.5, color: AppColors.bodyGrey),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: orders.loading ? null : orders.simulate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(11)),
                          child: Text(
                            orders.loading
                                ? 'Loading orders…'
                                : (orders.usingApi ? 'Refresh live orders' : 'Simulate a new order'),
                            style: AppText.body(size: 12.5, weight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: live.take(4).map((o) => _LiveOrderCard(order: o)).toList(),
              ),
            const SizedBox(height: 22),
            Text('Manage', style: AppText.display(size: 16)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3.2,
              children: [
                
                _QuickAction(label: 'Menu', icon: const Icon(Icons.restaurant_menu_outlined, size: 18, color: AppColors.accent), tint: AppColors.maroonTint, onTap: () => nav.tab('menu')),
                _QuickAction(label: 'Bookings', icon: const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.accent), tint: AppColors.bluePaleBg2, onTap: () => nav.go('bookings')),
                _QuickAction(label: 'Offers', icon: const Icon(Icons.local_offer_outlined, size: 18, color: AppColors.accent), tint: AppColors.amberPaleBg, onTap: nav.toOffers),
                _QuickAction(label: 'Plan', icon: const Icon(Icons.credit_card_outlined, size: 18, color: AppColors.accent), tint: AppColors.neutralTint3, onTap: nav.toSubscription),
                _QuickAction(label: 'Earnings', icon: const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.accent), tint: AppColors.greenPaleBg2, onTap: nav.toEarnings),
                _QuickAction(label: 'Reviews', icon: const Icon(Icons.star_outline, size: 18, color: AppColors.accent), tint: AppColors.starPaleBg, onTap: nav.toReviews),
                _QuickAction(label: 'Insights', icon: const Icon(Icons.bar_chart_outlined, size: 18, color: AppColors.accent), tint: AppColors.neutralTint3, onTap: () => nav.tab('insights')),
                _QuickAction(label: 'Settings', icon: const Icon(Icons.settings_outlined, size: 18, color: AppColors.accent), tint: AppColors.cardBorder, onTap: nav.toSettings),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, {String? sub, Color? subColor, bool star = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.body(size: 12, weight: FontWeight.w600, color: AppColors.bodyGrey)),
          Row(
            children: [
              Text(value, style: AppText.display(size: 21)),
              if (star) ...[const SizedBox(width: 4), const Text('★', style: TextStyle(color: AppColors.star, fontSize: 16))],
            ],
          ),
          if (sub != null) Text(sub, style: AppText.body(size: 11, weight: FontWeight.w600, color: subColor ?? AppColors.bodyGrey)),
        ],
      ),
    );
  }
}

class _LiveOrderCard extends ConsumerWidget {
  final Order order;
  const _LiveOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.read(ordersControllerProvider);
    final v = OrderView.of(order);
    return GestureDetector(
      onTap: () => orders.openOrder(order.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusBadge(label: v.statusLabel, fg: v.statusFg, bg: v.statusBg),
                const SizedBox(width: 9),
                Text('#${order.id}', style: AppText.body(size: 13, weight: FontWeight.w700)),
                const Spacer(),
                Text(order.placed, style: AppText.body(size: 12, color: AppColors.bodyGrey)),
              ],
            ),
            const SizedBox(height: 7),
            Text(v.itemsSummary, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 12.5, color: AppColors.midGrey)),
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${v.totalStr} · ${order.type}', style: AppText.body(size: 13, weight: FontWeight.w700)),
                GestureDetector(
                  onTap: () => v.isIncoming ? orders.askPrep(order.id) : orders.advance(order.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(color: v.actionColor, borderRadius: BorderRadius.circular(10)),
                    child: Text(v.actionLabel, style: AppText.body(size: 12.5, weight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final Widget icon;
  final Color tint;
  final VoidCallback? onTap;
  const _QuickAction({required this.label, required this.icon, required this.tint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(11)),
              alignment: Alignment.center,
              child: icon,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(size: 13, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
