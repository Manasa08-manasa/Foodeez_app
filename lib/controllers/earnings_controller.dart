import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../repositories/orders_repository.dart';
import '../services/mock_data.dart';
import 'auth_controller.dart';
import 'orders_controller.dart';

/// Owns the Earnings screen's period selector, settlements list, report
/// downloads, and the subscription-tier figures derived from today's orders.
class EarningsController extends ChangeNotifier {
  EarningsController(this.ref) {
    _authSub = ref.listen<AuthController>(authControllerProvider, (prev, next) {
      if (next.isAuthenticated) refresh();
    });
    if (ref.read(authControllerProvider).isAuthenticated) refresh();
  }

  final Ref ref;
  ProviderSubscription<AuthController>? _authSub;
  OrdersController get _orders => ref.read(ordersControllerProvider);

  String earnPeriod = 'today';
  String settleRange = 'all';
  String? openSettleId = 'S1';
  String reportPeriod = 'month';
  final Map<String, String> reportDlState = {};

  List<Settlement> settlements = seedSettlements();
  bool usingApi = false;
  int apiOrderCount = 0;
  int apiGmv = 0;
  int apiNet = 0;

  @override
  void dispose() {
    _authSub?.close();
    super.dispose();
  }

  Future<void> refresh() async {
    if (!ref.read(authControllerProvider).isAuthenticated) return;
    try {
      final summary = await ref.read(ordersRepositoryProvider).getSettlementToday();
      apiOrderCount = summary.orderCount;
      apiGmv = summary.totalItemValue.round();
      apiNet = summary.totalRestaurantShare.round();

      final orders = await ref.read(ordersRepositoryProvider).getSettlementTodayOrders();
      if (orders.isNotEmpty || summary.orderCount > 0) {
        final today = DateFormat('EEE, d MMM').format(DateTime.now());
        settlements = [
          Settlement(
            id: 'API-TODAY',
            week: 'Today',
            date: today,
            agoDays: 0,
            orders: summary.orderCount,
            tierLabel: 'Live',
            itemSales: summary.totalItemValue.round(),
            packaging: 0,
            gst: 0,
            discount: 0,
            ads: 0,
            delivery: 0,
            subscriptionFee: 0,
            tcs: 0,
            tds: summary.totalCommission.round(),
          ),
          ...seedSettlements().where((s) => s.id != 'S1'),
        ];
        openSettleId = 'API-TODAY';
      }
      usingApi = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[Earnings] refresh failed: $e');
    }
  }

  void _set(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  EarningsPeriod get currentEarningsPeriod => switch (earnPeriod) {
        'week' => earningsWeek,
        'month' => earningsMonth,
        _ => EarningsPeriod(
            label: 'Today',
            span: DateFormat('EEE, d MMM').format(DateTime.now()),
            orders: usingApi ? apiOrderCount : _orders.doneToday,
            gmv: usingApi ? apiGmv : _orders.gmvToday,
            subscriptionFee: usingApi ? (apiGmv - apiNet).clamp(0, 1 << 30) : tierFeeFor(_orders.doneToday),
            subNote: usingApi ? 'Live settlement' : 'Tier ${tierOf(_orders.doneToday)}',
          ),
      };

  void setEarnPeriod(String p) => _set(() => earnPeriod = p);
  void setSettleRange(String r) => _set(() => settleRange = r);
  void toggleSettle(String id) => _set(() => openSettleId = openSettleId == id ? null : id);

  List<Settlement> get visibleSettlements {
    if (settleRange == 'all') return settlements;
    final maxAgo = int.parse(settleRange);
    return settlements.where((s) => s.agoDays <= maxAgo).toList();
  }

  void setReportPeriod(String p) => _set(() => reportPeriod = p);
  String reportState(String id) => reportDlState[id] ?? 'idle';

  void downloadReport(String id) {
    if (reportState(id) != 'idle') return;
    reportDlState[id] = 'loading';
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 1100), () {
      reportDlState[id] = 'done';
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 1800), () {
        reportDlState[id] = 'idle';
        notifyListeners();
      });
    });
  }

  int get subscriptionTierToday => tierOf(usingApi ? apiOrderCount : _orders.doneToday);
  int get subscriptionFeeToday =>
      usingApi ? (apiGmv - apiNet).clamp(0, 1 << 30) : tierFeeFor(_orders.doneToday);
}

final earningsControllerProvider =
    ChangeNotifierProvider<EarningsController>((ref) => EarningsController(ref));
