import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/api_mappers.dart';
import '../models/models.dart';
import '../repositories/restaurant_repository.dart';
import '../services/mock_data.dart';
import 'auth_controller.dart';

/// Owns menu-item availability/price overrides and Menu screen filters.
class MenuController extends ChangeNotifier {
  MenuController(this.ref) {
    // ChangeNotifierProvider reuses the same instance for prev/next — track
    // branch/session ourselves so we actually refetch after login/bootstrap.
    _authSub = ref.listen<AuthController>(authControllerProvider, (prev, next) {
      _onAuthChanged(next);
    });
    _onAuthChanged(ref.read(authControllerProvider));
  }

  final Ref ref;
  ProviderSubscription<AuthController>? _authSub;

  bool _wasAuthenticated = false;
  String? _lastBranchId;

  List<MenuItem> items = List<MenuItem>.from(menuItems);
  List<String> sectionOrder = List<String>.from(menuSectionOrder);

  final Map<String, int> priceOverrides = {};
  final Map<String, bool> availOverrides = {};
  String menuCat = 'all';
  String menuDiet = 'all';
  bool loading = false;
  bool usingApi = false;
  String? error;

  void _onAuthChanged(AuthController auth) {
    if (auth.bootstrapping) return;

    if (auth.isAuthenticated && auth.branchId != null) {
      final branchChanged = auth.branchId != _lastBranchId;
      final justLoggedIn = !_wasAuthenticated;
      _wasAuthenticated = true;
      _lastBranchId = auth.branchId;
      if (justLoggedIn || branchChanged || !usingApi) {
        refresh();
      }
    } else if (!auth.isAuthenticated && _wasAuthenticated) {
      _wasAuthenticated = false;
      _lastBranchId = null;
      _resetToMock();
    }
  }

  @override
  void dispose() {
    _authSub?.close();
    super.dispose();
  }

  void _resetToMock() {
    items = List<MenuItem>.from(menuItems);
    sectionOrder = List<String>.from(menuSectionOrder);
    priceOverrides.clear();
    availOverrides.clear();
    usingApi = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated || auth.bootstrapping) return;
    final branchId = auth.branchId;
    if (branchId == null) {
      debugPrint('[Menu] refresh skipped: no branchId yet');
      return;
    }

    loading = true;
    error = null;
    notifyListeners();
    try {
      final repo = ref.read(restaurantRepositoryProvider);

      // Same pair restaurant-admin uses:
      // GET /branches/{branchId}/menu-categories
      // GET /branches/{branchId}/menu-items
      final catsFut = repo.getCategories(branchId);
      final itemsFut = repo.getMenuItems(branchId);
      final categories = await catsFut;
      final apiItems = await itemsFut;

      debugPrint(
        '[Menu] branches/$branchId/menu-categories → ${categories.length}; '
        'menu-items → ${apiItems.length}',
      );

      final catLabelById = <String, String>{};
      for (final c in categories) {
        final label = c.displayName.isNotEmpty ? c.displayName : c.name;
        if (c.id.isNotEmpty && label.isNotEmpty) {
          catLabelById[c.id] = label;
        }
      }

      // Category chip / section order follows menu-categories API order.
      final orderedSections = <String>[];
      for (final c in categories) {
        final label = catLabelById[c.id];
        if (label != null && !orderedSections.contains(label)) {
          orderedSections.add(label);
        }
      }

      items = apiItems.map((api) {
        final fromCat = catLabelById[api.categoryId];
        final section = (fromCat != null && fromCat.isNotEmpty)
            ? fromCat
            : (api.categoryName.isNotEmpty ? api.categoryName : 'Menu');
        if (!orderedSections.contains(section)) {
          orderedSections.add(section);
        }
        return ApiMappers.toUiMenuItem(api, sectionOverride: section);
      }).toList();

      sectionOrder = orderedSections.isNotEmpty ? orderedSections : <String>['Menu'];
      priceOverrides.clear();
      availOverrides.clear();
      usingApi = true;
      error = null;
      _lastBranchId = branchId;
    } catch (e) {
      debugPrint('[Menu] refresh failed: $e');
      error = e.toString();
      // Keep last good API data; only seed mock if we never loaded API.
      if (!usingApi) _resetToMock();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  bool isAvail(MenuItem m) => availOverrides[m.id] ?? m.baseAvail;
  int priceOf(MenuItem m) => priceOverrides[m.id] ?? m.basePrice;

  Future<void> toggleAvail(String id) async {
    final m = items.firstWhere((e) => e.id == id, orElse: () => menuItemById(id));
    final next = !isAvail(m);
    availOverrides[id] = next;
    notifyListeners();

    if (!usingApi) return;
    try {
      await ref.read(restaurantRepositoryProvider).updateMenuItem(id, {
        'isInStock': next,
      });
    } catch (e) {
      availOverrides[id] = !next;
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> changePrice(String id, int delta) async {
    final m = items.firstWhere((e) => e.id == id, orElse: () => menuItemById(id));
    final cur = priceOverrides[id] ?? m.basePrice;
    final next = (cur + delta).clamp(10, 1 << 30);
    priceOverrides[id] = next;
    notifyListeners();

    if (!usingApi) return;
    try {
      await ref.read(restaurantRepositoryProvider).updateMenuItem(id, {'price': next});
    } catch (e) {
      priceOverrides[id] = cur;
      error = e.toString();
      notifyListeners();
    }
  }

  void _set(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  void setMenuCat(String c) => _set(() => menuCat = c);
  void setMenuDiet(String d) => _set(() => menuDiet = d);

  bool _passDiet(MenuItem m) {
    switch (menuDiet) {
      case 'veg':
        return m.veg;
      case 'nonveg':
        return !m.veg;
      case 'in':
        return isAvail(m);
      case 'out':
        return !isAvail(m);
      default:
        return true;
    }
  }

  List<({String name, List<MenuItem> items})> get menuSections {
    final cats = menuCat == 'all' ? sectionOrder : [menuCat];
    return cats
        .map((name) => (name: name, items: items.where((m) => m.section == name && _passDiet(m)).toList()))
        .where((s) => s.items.isNotEmpty)
        .toList();
  }

  int get menuAvailableCount => items.where(isAvail).length;
}

final menuControllerProvider = ChangeNotifierProvider<MenuController>((ref) => MenuController(ref));
