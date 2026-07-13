import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/api_mappers.dart';
import '../models/api/order_models.dart';
import '../models/models.dart';
import '../models/order_view.dart';
import '../repositories/orders_repository.dart';
import '../services/mock_data.dart';
import 'auth_controller.dart';
import 'navigation_controller.dart';

/// Owns the live order pool: incoming/preparing/ready lifecycle, alerts,
/// prep-time confirmation, KOT modal, and today's counters.
class OrdersController extends ChangeNotifier {
  OrdersController(this.ref) {
    // ChangeNotifierProvider passes the same instance as prev/next, so
    // prev.isAuthenticated == next.isAuthenticated after notifyListeners.
    // Track auth ourselves and refresh whenever the session is ready.
    _authSub = ref.listen<AuthController>(authControllerProvider, (prev, next) {
      _onAuthChanged(next);
    });
    _onAuthChanged(ref.read(authControllerProvider));
  }

  final Ref ref;
  ProviderSubscription<AuthController>? _authSub;
  NavigationController get _nav => ref.read(navigationControllerProvider);
  AuthController get _auth => ref.read(authControllerProvider);

  bool _wasAuthenticated = false;
  String? _lastRestaurantId;

  bool online = true;
  bool alertOpen = true;
  int alertCountdown = 38;
  Timer? _alertTimer;
  Timer? _pollTimer;

  List<Order> orders = seedOrders();
  /// Maps UI order id → API order id for mutations.
  final Map<String, String> _apiIds = {};
  /// Raw API status by UI order id (for correct next-status transitions).
  final Map<String, String> _apiStatuses = {};

  int _poolIx = 0;
  bool loading = false;
  String? error;
  bool usingApi = false;

  void _onAuthChanged(AuthController auth) {
    if (auth.bootstrapping) return;

    final authed = auth.isAuthenticated;
    final rid = auth.restaurantId;

    if (authed) {
      final sessionChanged = !_wasAuthenticated || rid != _lastRestaurantId;
      _wasAuthenticated = true;
      _lastRestaurantId = rid;
      if (sessionChanged || _pollTimer == null) {
        refresh();
        _startPolling();
      }
    } else if (_wasAuthenticated) {
      _wasAuthenticated = false;
      _lastRestaurantId = null;
      _stopPolling();
      _useMock();
    }
  }

  String? oid;
  String? prepFor;
  int prepChoice = 20;
  String? kotFor;

  String ordersTab = 'ongoing';
  String orderTypeFilter = 'all';

  int doneToday = 33;
  int gmvToday = 11550;

  @override
  void dispose() {
    _alertTimer?.cancel();
    _pollTimer?.cancel();
    _authSub?.close();
    super.dispose();
  }

  void _useMock() {
    usingApi = false;
    orders = seedOrders();
    _apiIds.clear();
    _apiStatuses.clear();
    doneToday = 33;
    gmvToday = 11550;
    notifyListeners();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(AppConstants.ordersPollInterval, (_) {
      if (_auth.isAuthenticated) refresh(silent: true);
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> refresh({bool silent = false}) async {
    if (!_auth.isAuthenticated || _auth.bootstrapping) return;
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final repo = ref.read(ordersRepositoryProvider);
      List<ApiOrder> live = [];
      var usedPartnerEndpoint = false;
      try {
        live = await repo.getLiveOrders();
        usedPartnerEndpoint = true;
        debugPrint('[Orders] partner/orders → ${live.length} order(s)');
      } catch (e) {
        debugPrint('[Orders] partner/orders failed, falling back to restaurant/orders: $e');
        live = await repo.getRestaurantOrders(limit: 50);
        debugPrint('[Orders] restaurant/orders → ${live.length} order(s)');
      }

      // KDS-style live set: active kitchen statuses (+ ready/in-transit).
      const liveStatuses = {
        'PLACED',
        'ACCEPTED',
        'CONFIRMED',
        'PREPARING',
        'READY',
        'READY_FOR_PICKUP',
        'PICKED_UP',
        'ON_THE_WAY',
      };
      final liveFiltered = usedPartnerEndpoint
          ? live // partner endpoint already returns the live pool
          : live.where((o) => liveStatuses.contains(o.status.toUpperCase())).toList();

      final mapped = <Order>[];
      _apiIds.clear();
      _apiStatuses.clear();
      for (final api in liveFiltered) {
        final ui = ApiMappers.toUiOrder(api);
        mapped.add(ui);
        _apiIds[ui.id] = api.id;
        _apiStatuses[ui.id] = api.status;
      }

      // Merge completed/cancelled from restaurant orders for the completed tab.
      try {
        final history = await repo.getRestaurantOrders(limit: 30);
        for (final api in history) {
          final status = api.status.toUpperCase();
          if (!['DELIVERED', 'COMPLETED', 'CANCELLED', 'FAILED', 'REJECTED'].contains(status)) {
            continue;
          }
          final ui = ApiMappers.toUiOrder(api);
          if (mapped.any((o) => o.id == ui.id || _apiIds[o.id] == api.id)) continue;
          mapped.add(ui);
          _apiIds[ui.id] = api.id;
          _apiStatuses[ui.id] = api.status;
        }
      } catch (e) {
        debugPrint('[Orders] history merge skipped: $e');
      }

      // Always replace mock with API result (including empty).
      orders = mapped;
      usingApi = true;
      online = _auth.isOnline;
      error = null;

      // Settlement counters
      try {
        final summary = await repo.getSettlementToday();
        doneToday = summary.orderCount;
        gmvToday = summary.totalItemValue.round();
      } catch (_) {}

      final hasIncoming = orders.any((o) => o.status == OrderStatus.incoming);
      if (hasIncoming && !alertOpen && _nav.screen != 'login') {
        alertOpen = true;
        alertCountdown = 38;
        _startAlertCountdown();
      } else if (!hasIncoming) {
        alertOpen = false;
        _alertTimer?.cancel();
      }
    } catch (e) {
      debugPrint('[Orders] refresh failed: $e');
      error = e.toString();
      // Keep last good API data; only seed mock if we never loaded API.
      if (!usingApi) _useMock();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  String _apiId(String uiId) => _apiIds[uiId] ?? uiId;

  void openOrder(String id) {
    oid = id;
    _nav.go('detail');
    notifyListeners();
  }

  Order? orderById(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  List<Order> get liveOrders =>
      orders.where((o) => o.status == OrderStatus.incoming || o.status == OrderStatus.preparing || o.status == OrderStatus.ready).toList();

  int get newCount => orders.where((o) => o.status == OrderStatus.incoming).length;
  int get prepCount => orders.where((o) => o.status == OrderStatus.preparing).length;
  int get readyCount => orders.where((o) => o.status == OrderStatus.ready || o.status == OrderStatus.outForDelivery).length;
  int get todayOrdersCount => orders.where((o) => o.status != OrderStatus.incoming).length;

  List<Order> tabOrders(String tab) {
    bool Function(Order) filter = switch (tab) {
      'ready' => (o) => o.status == OrderStatus.ready || o.status == OrderStatus.outForDelivery,
      'completed' => (o) => o.status == OrderStatus.completed,
      _ => (o) => o.status == OrderStatus.incoming || o.status == OrderStatus.preparing,
    };
    return orders.where(filter).where((o) => orderTypeFilter == 'all' || o.type == orderTypeFilter).toList();
  }

  void setOrdersTab(String t) => _set(() => ordersTab = t);
  void setOrderTypeFilter(String t) => _set(() => orderTypeFilter = t);

  void _set(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  Future<void> toggleOnline() async {
    final next = !online;
    online = next;
    notifyListeners();
    try {
      await _auth.setOnline(next);
      online = _auth.isOnline;
    } catch (e) {
      online = !next;
      error = e.toString();
    }
    notifyListeners();
  }

  void _setStatus(String id, OrderStatus status) {
    final prev = orderById(id);
    final wasCompleted = prev?.status == OrderStatus.completed;
    orders = orders
        .map((o) => o.id == id ? o.copyWith(status: status, placed: status == OrderStatus.preparing ? 'Just now' : o.placed) : o)
        .toList();
    if (status == OrderStatus.completed && !wasCompleted) {
      final amt = prev?.total ?? 350;
      doneToday += 1;
      gmvToday += amt;
    }
  }

  Future<void> advance(String id) async {
    final o = orderById(id);
    if (o == null) return;

    if (!usingApi) {
      final next = nextStatus(o);
      if (next != null) _setStatus(id, next);
      notifyListeners();
      return;
    }

    final repo = ref.read(ordersRepositoryProvider);
    final apiId = _apiId(id);
    try {
      if (o.status == OrderStatus.preparing) {
        await repo.markReady(apiId);
        _setStatus(id, OrderStatus.ready);
        _apiStatuses[id] = 'READY';
      } else if (o.status == OrderStatus.ready) {
        await repo.updateStatus(apiId, o.type == OrderType.delivery ? 'PICKED_UP' : 'DELIVERED');
        _setStatus(id, o.type == OrderType.delivery ? OrderStatus.outForDelivery : OrderStatus.completed);
      } else if (o.status == OrderStatus.outForDelivery) {
        await repo.updateStatus(apiId, 'DELIVERED');
        _setStatus(id, OrderStatus.completed);
      } else if (o.status == OrderStatus.incoming) {
        askPrep(id);
        return;
      }
    } catch (e) {
      error = e.toString();
      debugPrint('[Orders] advance failed: $e');
    }
    notifyListeners();
  }

  Future<void> reject(String id) async {
    if (usingApi) {
      try {
        await ref.read(ordersRepositoryProvider).rejectOrder(_apiId(id));
      } catch (e) {
        error = e.toString();
        notifyListeners();
        return;
      }
    }
    orders = orders.where((o) => o.id != id).toList();
    _apiIds.remove(id);
    _apiStatuses.remove(id);
    alertOpen = false;
    _alertTimer?.cancel();
    if (_nav.screen == 'detail') _nav.tab('orders');
    notifyListeners();
  }

  void acceptAlert() {
    final inc = orders.where((o) => o.status == OrderStatus.incoming).toList();
    if (inc.isNotEmpty) {
      askPrep(inc.first.id);
    } else {
      alertOpen = false;
      notifyListeners();
    }
  }

  void rejectAlert() {
    final inc = orders.where((o) => o.status == OrderStatus.incoming).toList();
    if (inc.isNotEmpty) reject(inc.first.id);
  }

  void askPrep(String id) {
    final o = orderById(id);
    prepFor = id;
    prepChoice = o?.prepMinutes ?? 20;
    alertOpen = false;
    _alertTimer?.cancel();
    notifyListeners();
  }

  Future<void> confirmPrep() async {
    final id = prepFor;
    final mins = prepChoice;
    if (id == null) return;

    if (usingApi) {
      try {
        await ref.read(ordersRepositoryProvider).acceptOrder(_apiId(id), mins);
        _apiStatuses[id] = 'ACCEPTED';
      } catch (e) {
        error = e.toString();
        notifyListeners();
        return;
      }
    }

    orders = orders
        .map((o) => o.id == id ? o.copyWith(status: OrderStatus.preparing, prepMinutes: mins, placed: 'Just now') : o)
        .toList();
    prepFor = null;
    notifyListeners();
  }

  void cancelPrep() => _set(() => prepFor = null);
  void bumpPrep(int delta) => _set(() => prepChoice = (prepChoice + delta).clamp(1, 90));
  void openKot(String id) => _set(() => kotFor = id);
  void closeKot() => _set(() => kotFor = null);

  void simulate() {
    if (usingApi) {
      refresh();
      return;
    }
    final t = simulationPool[_poolIx % simulationPool.length];
    _poolIx++;
    final id = 'FZ${8843 + _poolIx}';
    orders = [
      Order(id: id, status: OrderStatus.incoming, type: t.type, customer: t.customer, dist: t.dist, placed: 'Just now', prepMinutes: t.prepMinutes, payLabel: t.payLabel, lines: t.lines),
      ...orders,
    ];
    online = true;
    alertOpen = true;
    alertCountdown = 38;
    _startAlertCountdown();
    notifyListeners();
  }

  void _startAlertCountdown() {
    _alertTimer?.cancel();
    _alertTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (alertCountdown <= 0 || !alertOpen) {
        t.cancel();
        return;
      }
      alertCountdown -= 1;
      notifyListeners();
    });
  }

  bool get showAlert => online && alertOpen && orders.any((o) => o.status == OrderStatus.incoming) && _nav.screen != 'login';
}

final ordersControllerProvider = ChangeNotifierProvider<OrdersController>((ref) => OrdersController(ref));
