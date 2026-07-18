import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/storage/token_storage.dart';
import '../core/utils/api_mappers.dart';
import '../core/utils/order_status_utils.dart';
import '../models/api/order_models.dart';
import '../models/models.dart';
import '../repositories/orders_repository.dart';
import '../services/partner_orders_socket.dart';
import 'auth_controller.dart';
import 'navigation_controller.dart';

enum _OrderPool { screen, home }

/// Owns the live order pool: incoming/preparing/ready lifecycle, alerts,
/// prep-time confirmation, KOT modal, and today's counters.
class OrdersController extends ChangeNotifier {
  OrdersController(this.ref) {
    _authSub = ref.listen<AuthController>(authControllerProvider, (prev, next) {
      _onAuthChanged(next);
    });
    _onAuthChanged(ref.read(authControllerProvider));
  }

  final Ref ref;
  final PartnerOrdersSocket _socket = PartnerOrdersSocket();
  ProviderSubscription<AuthController>? _authSub;
  NavigationController get _nav => ref.read(navigationControllerProvider);
  AuthController get _auth => ref.read(authControllerProvider);

  bool _wasAuthenticated = false;
  String? _lastRestaurantId;
  bool _initialLoadDone = false;
  final Set<String> _knownApiIds = {};

  bool online = true;
  bool alertOpen = false;
  int alertCountdown = AppConstants.autoRejectSeconds;
  String? _alertOrderId;
  Timer? _alertTimer;
  Timer? _pollTimer;

  List<Order> orders = [];
  List<Order> homeLiveOrders = [];
  final Map<String, String> _apiIds = {};
  final Map<String, String> _apiStatuses = {};
  final Map<String, String> _autoRejectAt = {};
  final Map<String, DateTime> _createdAt = {};

  String? oid;
  String? prepFor;
  int prepChoice = AppConstants.defaultPrepMinutes;
  String? kotFor;

  String ordersTab = 'new';
  String orderTypeFilter = 'all';

  int doneToday = 0;
  int gmvToday = 0;

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
      if (sessionChanged) {
        _resetSession();
        refresh();
        _startPolling();
        _connectSocket();
      } else if (_pollTimer == null) {
        refresh();
        _startPolling();
        _connectSocket();
      }
    } else if (_wasAuthenticated) {
      _wasAuthenticated = false;
      _lastRestaurantId = null;
      _resetSession();
    }
  }

  void _resetSession() {
    _stopPolling();
    _socket.disconnect();
    _alertTimer?.cancel();
    alertOpen = false;
    _alertOrderId = null;
    _initialLoadDone = false;
    _knownApiIds.clear();
    orders = [];
    homeLiveOrders = [];
    _apiIds.clear();
    _apiStatuses.clear();
    _autoRejectAt.clear();
    _createdAt.clear();
    usingApi = false;
    doneToday = 0;
    gmvToday = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    _pollTimer?.cancel();
    _socket.disconnect();
    _authSub?.close();
    super.dispose();
  }

  Future<void> _connectSocket() async {
    final rid = _auth.restaurantId;
    if (rid == null || rid.isEmpty) return;
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) return;

    _socket.connect(
      token: token,
      restaurantId: rid,
      onNewOrder: _onSocketNewOrder,
      onOrderCancelled: _onSocketOrderCancelled,
    );
  }

  void _onSocketNewOrder(ApiOrder api) {
    _upsertApiOrder(api, isNew: true);
    if (api.status.toUpperCase() == 'PLACED') {
      _openAlertFor(api);
    }
    notifyListeners();
  }

  void _onSocketOrderCancelled(String apiOrderId) {
    _removeByApiId(apiOrderId);
    if (_alertOrderId != null && _apiIds[_alertOrderId] == apiOrderId) {
      _dismissAlert();
    }
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

      // Orders screen — partner KDS pool (PLACED, ACCEPTED, PREPARING).
      final partnerActive = await repo.getPartnerActiveOrders();
      debugPrint('[Orders] partner/orders → ${partnerActive.length}');

      // Home live orders — restaurant pool.
      List<ApiOrder> homeRaw = [];
      try {
        homeRaw = await repo.getHomeLiveOrders();
        debugPrint('[Orders] restaurant/orders (home live) → ${homeRaw.length}');
      } catch (e) {
        debugPrint('[Orders] home live fetch skipped: $e');
      }

      // Orders screen — out for delivery + completed (not in partner/orders).
      List<ApiOrder> ready = [];
      List<ApiOrder> completed = [];
      try {
        ready = await repo.getReadyOrders();
        debugPrint('[Orders] restaurant/orders (out for delivery) → ${ready.length}');
      } catch (e) {
        debugPrint('[Orders] ready fetch skipped: $e');
      }
      try {
        completed = await repo.getCompletedOrders();
        debugPrint('[Orders] restaurant/orders (completed today) → ${completed.length}');
      } catch (e) {
        debugPrint('[Orders] completed fetch skipped: $e');
      }

      final screenMerged = _mergeApiOrders([...partnerActive, ...ready, ...completed]);
      final homeMerged = _mergeApiOrders(homeRaw);

      _apiIds.clear();
      _apiStatuses.clear();
      _autoRejectAt.clear();
      _createdAt.clear();

      _applyApiOrderList(screenMerged, target: _OrderPool.screen);
      _applyApiOrderList(homeMerged, target: _OrderPool.home);

      final allForAlerts = _mergeApiOrders([...screenMerged, ...homeMerged]);

      if (_initialLoadDone) {
        for (final api in allForAlerts) {
          if (!OrderStatusUtils.isPlaced(api.status)) continue;
          if (_knownApiIds.contains(api.id)) continue;
          _openAlertFor(api);
        }
      } else {
        for (final api in allForAlerts) {
          _knownApiIds.add(api.id);
        }
        _initialLoadDone = true;
      }

      for (final api in allForAlerts) {
        _knownApiIds.add(api.id);
      }

      usingApi = true;
      online = _auth.isOnline;
      error = null;

      try {
        final summary = await repo.getSettlementToday();
        doneToday = summary.orderCount;
        gmvToday = summary.totalItemValue.round();
      } catch (_) {}

      if (!orders.any((o) => OrderStatusUtils.isPlaced(_apiStatuses[o.id])) &&
          !homeLiveOrders.any((o) => OrderStatusUtils.isPlaced(_apiStatuses[o.id]))) {
        _dismissAlert();
      }
    } catch (e) {
      debugPrint('[Orders] refresh failed: $e');
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _registerApiOrder(ApiOrder api) {
    final ui = ApiMappers.toUiOrder(api);
    _apiIds[ui.id] = api.id;
    _apiStatuses[ui.id] = api.status;
    _createdAt[ui.id] = api.createdAt;
    if (api.autoRejectAt != null && api.autoRejectAt!.isNotEmpty) {
      _autoRejectAt[ui.id] = api.autoRejectAt!;
    }
  }

  void _applyApiOrderList(List<ApiOrder> apis, {required _OrderPool target}) {
    final mapped = <Order>[];
    for (final api in apis) {
      final ui = ApiMappers.toUiOrder(api);
      mapped.add(ui);
      _registerApiOrder(api);
    }
    if (target == _OrderPool.screen) {
      orders = mapped;
    } else {
      homeLiveOrders = mapped;
    }
  }

  List<ApiOrder> _mergeApiOrders(List<ApiOrder> list) {
    final byId = <String, ApiOrder>{};
    for (final o in list) {
      final existing = byId[o.id];
      if (existing == null || OrderStatusUtils.rank(o.status) >= OrderStatusUtils.rank(existing.status)) {
        byId[o.id] = o;
      }
    }
    return byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _upsertApiOrder(ApiOrder api, {bool isNew = false}) {
    final ui = ApiMappers.toUiOrder(api);
    _registerApiOrder(api);

    final ordersIx = orders.indexWhere((o) => _apiIds[o.id] == api.id || o.id == ui.id);
    if (ordersIx >= 0) {
      orders = [...orders]..[ordersIx] = ui;
    } else if (_belongsOnScreen(api.status)) {
      orders = [ui, ...orders];
    }

    final homeIx = homeLiveOrders.indexWhere((o) => _apiIds[o.id] == api.id || o.id == ui.id);
    if (_belongsOnHome(api.status)) {
      if (homeIx >= 0) {
        homeLiveOrders = [...homeLiveOrders]..[homeIx] = ui;
      } else {
        homeLiveOrders = [ui, ...homeLiveOrders];
      }
    } else if (homeIx >= 0) {
      homeLiveOrders = homeLiveOrders.where((o) => o.id != ui.id).toList();
    }

    _knownApiIds.add(api.id);
    if (isNew) debugPrint('[Orders] new order via socket: ${api.orderNumber}');
  }

  bool _belongsOnScreen(String status) =>
      OrderStatusUtils.isOngoing(status) || OrderStatusUtils.isReady(status) || OrderStatusUtils.isCompleted(status);

  bool _belongsOnHome(String status) => OrderStatusUtils.isHomeLive(status);

  void _removeByApiId(String apiOrderId) {
    String? uiId;
    for (final e in _apiIds.entries) {
      if (e.value == apiOrderId) {
        uiId = e.key;
        break;
      }
    }
    if (uiId == null) return;
    orders = orders.where((o) => o.id != uiId).toList();
    homeLiveOrders = homeLiveOrders.where((o) => o.id != uiId).toList();
    _apiIds.remove(uiId);
    _apiStatuses.remove(uiId);
    _autoRejectAt.remove(uiId);
    _createdAt.remove(uiId);
    _knownApiIds.remove(apiOrderId);
  }

  void _openAlertFor(ApiOrder api) {
    final ui = ApiMappers.toUiOrder(api);
    _alertOrderId = ui.id;
    alertOpen = true;
    alertCountdown = _secondsUntilAutoReject(ui.id);
    _startAlertCountdown();
  }

  int _secondsUntilAutoReject(String uiId) {
    final raw = _autoRejectAt[uiId];
    if (raw != null) {
      final at = DateTime.tryParse(raw);
      if (at != null) {
        return at.difference(DateTime.now()).inSeconds.clamp(0, AppConstants.autoRejectSeconds);
      }
    }
    return AppConstants.autoRejectSeconds;
  }

  void _dismissAlert() {
    alertOpen = false;
    _alertOrderId = null;
    _alertTimer?.cancel();
  }

  void _startAlertCountdown() {
    _alertTimer?.cancel();
    _alertTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!alertOpen || _alertOrderId == null) {
        t.cancel();
        return;
      }
      alertCountdown = _secondsUntilAutoReject(_alertOrderId!);
      if (alertCountdown <= 0) {
        t.cancel();
        _dismissAlert();
      }
      notifyListeners();
    });
  }

  String _apiId(String uiId) => _apiIds[uiId] ?? uiId;

  String? apiStatus(String uiId) => _apiStatuses[uiId];

  bool canMarkReady(String uiId) => OrderStatusUtils.canPartnerMarkReady(_apiStatuses[uiId]);

  void openOrder(String id) {
    oid = id;
    _nav.go('detail');
    notifyListeners();
  }

  Order? orderById(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    for (final o in homeLiveOrders) {
      if (o.id == id) return o;
    }
    return null;
  }

  bool _isToday(String uiId) {
    final dt = _createdAt[uiId];
    if (dt == null) return true;
    final now = DateTime.now();
    final local = dt.toLocal();
    return local.year == now.year && local.month == now.month && local.day == now.day;
  }

  List<Order> get liveOrders => homeLiveOrders;

  int get newCount => orders.where((o) => OrderStatusUtils.isPlaced(_apiStatuses[o.id])).length;
  int get prepCount => orders.where((o) => OrderStatusUtils.isPreparing(_apiStatuses[o.id])).length;
  int get readyCount => orders.where((o) => OrderStatusUtils.isReady(_apiStatuses[o.id])).length;
  int get completedCount =>
      orders.where((o) => OrderStatusUtils.isCompleted(_apiStatuses[o.id]) && _isToday(o.id)).length;
  int get todayOrdersCount => orders.where((o) => !OrderStatusUtils.isPlaced(_apiStatuses[o.id])).length;

  List<Order> tabOrders(String tab) {
    bool matchesTab(Order o) {
      final raw = _apiStatuses[o.id];
      return switch (tab) {
        'new' => OrderStatusUtils.isPlaced(raw),
        'preparing' => OrderStatusUtils.isPreparing(raw),
        'outForDelivery' => OrderStatusUtils.isReady(raw),
        'completed' => OrderStatusUtils.isCompleted(raw) && _isToday(o.id),
        _ => OrderStatusUtils.isOngoing(raw),
      };
    }
    return orders.where(matchesTab).where((o) => orderTypeFilter == 'all' || o.type == orderTypeFilter).toList();
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

  Future<void> advance(String id) async {
    final o = orderById(id);
    if (o == null || !usingApi) return;

    final repo = ref.read(ordersRepositoryProvider);
    final apiId = _apiId(id);

    try {
      if (OrderStatusUtils.isPlaced(_apiStatuses[id])) {
        askPrep(id);
        return;
      }
      if (OrderStatusUtils.isOngoing(_apiStatuses[id]) && canMarkReady(id)) {
        final updated = await repo.markReady(apiId);
        _upsertApiOrder(updated);
      }
    } catch (e) {
      error = e.toString();
      debugPrint('[Orders] advance failed: $e');
    }
    notifyListeners();
  }

  Future<void> reject(String id, {String? reason}) async {
    if (usingApi) {
      try {
        await ref.read(ordersRepositoryProvider).rejectOrder(_apiId(id), reason: reason);
      } catch (e) {
        error = e.toString();
        notifyListeners();
        return;
      }
    }
    final apiId = _apiId(id);
    orders = orders.where((o) => o.id != id).toList();
    homeLiveOrders = homeLiveOrders.where((o) => o.id != id).toList();
    _apiIds.remove(id);
    _apiStatuses.remove(id);
    _autoRejectAt.remove(id);
    _knownApiIds.remove(apiId);
    if (_alertOrderId == id) _dismissAlert();
    if (_nav.screen == 'detail') _nav.tab('orders');
    notifyListeners();
  }

  void acceptAlert() {
    final inc = [
      ...orders.where((o) => OrderStatusUtils.isPlaced(_apiStatuses[o.id])),
      ...homeLiveOrders.where((o) => OrderStatusUtils.isPlaced(_apiStatuses[o.id])),
    ];
    if (inc.isNotEmpty) {
      askPrep(inc.first.id);
    } else {
      _dismissAlert();
      notifyListeners();
    }
  }

  void rejectAlert() {
    final inc = [
      ...orders.where((o) => OrderStatusUtils.isPlaced(_apiStatuses[o.id])),
      ...homeLiveOrders.where((o) => OrderStatusUtils.isPlaced(_apiStatuses[o.id])),
    ];
    if (inc.isNotEmpty) reject(inc.first.id);
  }

  void askPrep(String id) {
    final o = orderById(id);
    prepFor = id;
    prepChoice = o?.prepMinutes ?? AppConstants.defaultPrepMinutes;
    if (prepChoice < AppConstants.minPrepMinutes || prepChoice > AppConstants.maxPrepMinutes) {
      prepChoice = AppConstants.defaultPrepMinutes;
    }
    _dismissAlert();
    notifyListeners();
  }

  Future<void> confirmPrep() async {
    final id = prepFor;
    final mins = prepChoice.clamp(AppConstants.minPrepMinutes, AppConstants.maxPrepMinutes);
    if (id == null) return;

    if (usingApi) {
      try {
        final updated = await ref.read(ordersRepositoryProvider).acceptOrder(_apiId(id), mins);
        _upsertApiOrder(updated);
      } catch (e) {
        error = e.toString();
        notifyListeners();
        return;
      }
    } else {
      orders = orders
          .map((o) => o.id == id ? o.copyWith(status: OrderStatus.preparing, prepMinutes: mins, placed: 'Just now') : o)
          .toList();
      _apiStatuses[id] = 'ACCEPTED';
    }

    prepFor = null;
    notifyListeners();
  }

  void cancelPrep() => _set(() => prepFor = null);
  void setPrepChoice(int mins) => _set(() => prepChoice = mins.clamp(AppConstants.minPrepMinutes, AppConstants.maxPrepMinutes));
  void bumpPrep(int delta) => _set(() => prepChoice = (prepChoice + delta).clamp(AppConstants.minPrepMinutes, AppConstants.maxPrepMinutes));
  void openKot(String id) => _set(() => kotFor = id);
  void closeKot() => _set(() => kotFor = null);

  bool get showAlert =>
      _auth.isAuthenticated &&
      online &&
      alertOpen &&
      alertOrderId != null &&
      (orders.any((o) => o.id == alertOrderId && OrderStatusUtils.isPlaced(_apiStatuses[o.id])) ||
          homeLiveOrders.any((o) => o.id == alertOrderId && OrderStatusUtils.isPlaced(_apiStatuses[o.id]))) &&
      _nav.screen != 'login';

  String? get alertOrderId => _alertOrderId;
}

final ordersControllerProvider = ChangeNotifierProvider<OrdersController>((ref) => OrdersController(ref));
