import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api/auth_models.dart';
import '../models/api/restaurant_models.dart';
import '../repositories/auth_repository.dart';
import '../repositories/restaurant_repository.dart';
import '../services/mock_data.dart' as mock;
import 'navigation_controller.dart';

/// Session + restaurant/branch context loaded after authentication.
class AuthController extends ChangeNotifier {
  AuthController(this.ref);

  final Ref ref;

  AuthUser? user;
  ApiRestaurant? restaurant;
  ApiBranch? activeBranch;
  bool bootstrapping = true;
  bool loading = false;
  String? error;

  bool get isAuthenticated => user != null;
  String? get restaurantId => user?.restaurantId ?? restaurant?.id;
  String? get branchId => activeBranch?.id;

  String get displayName => restaurant?.name ?? mock.restaurantName;
  String get locationLine {
    final branch = activeBranch;
    if (branch != null) {
      final bits = <String>[
        if (branch.city != null && branch.city!.isNotEmpty) branch.city!,
        if (branch.name.isNotEmpty) branch.name,
      ];
      if (bits.isNotEmpty) return bits.join(' · ');
    }
    return restaurant?.locationLine ?? mock.restaurantLocationLine;
  }

  String get initials => restaurant?.initials ?? mock.restaurantInitials;
  bool get isOnline => activeBranch?.isOnline ?? true;

  Future<void> bootstrap() async {
    bootstrapping = true;
    notifyListeners();
    try {
      final stored = await ref.read(authRepositoryProvider).getStoredUser();
      if (stored == null) {
        user = null;
        restaurant = null;
        activeBranch = null;
        return;
      }
      user = stored;
      await _enrichProfile();
      await _loadRestaurantContext();
      ref.read(navigationControllerProvider).tab('dashboard');
    } catch (e) {
      debugPrint('[AuthController] bootstrap failed: $e');
      user = null;
    } finally {
      bootstrapping = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      user = await ref.read(authRepositoryProvider).login(email, password);
      await _enrichProfile();
      await _loadRestaurantContext();
      loading = false;
      notifyListeners();
      ref.read(navigationControllerProvider).tab('dashboard');
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    user = null;
    restaurant = null;
    activeBranch = null;
    error = null;
    notifyListeners();
    ref.read(navigationControllerProvider).logout();
  }

  Future<void> _enrichProfile() async {
    if (user == null) return;
    try {
      final profile = await ref.read(authRepositoryProvider).getMe();
      user = user!.copyWith(
        displayName: profile.displayName.isNotEmpty ? profile.displayName : user!.displayName,
        restaurantId: profile.restaurantId ?? user!.restaurantId,
        email: profile.email.isNotEmpty ? profile.email : user!.email,
        role: profile.role.isNotEmpty ? profile.role : user!.role,
      );
    } catch (e) {
      debugPrint('[AuthController] getMe failed: $e');
    }
  }

  Future<void> _loadRestaurantContext() async {
    final rid = user?.restaurantId;
    if (rid == null || rid.isEmpty) return;
    final repo = ref.read(restaurantRepositoryProvider);
    try {
      restaurant = await repo.getRestaurant(rid);
    } catch (e) {
      debugPrint('[AuthController] restaurant load failed: $e');
    }
    try {
      final branches = await repo.getBranches(rid);
      if (branches.isNotEmpty) {
        activeBranch = branches.firstWhere(
          (b) => b.isOnline,
          orElse: () => branches.first,
        );
      }
    } catch (e) {
      debugPrint('[AuthController] branches load failed: $e');
    }
  }

  Future<void> refreshContext() async {
    await _loadRestaurantContext();
    notifyListeners();
  }

  Future<void> setOnline(bool online) async {
    final rid = restaurantId;
    final bid = branchId;
    if (rid == null || bid == null) {
      // Offline/mock mode — flip local flag via a synthetic branch.
      if (activeBranch != null) {
        activeBranch = activeBranch!.copyWith(isOnline: online);
      }
      notifyListeners();
      return;
    }
    try {
      activeBranch = await ref.read(restaurantRepositoryProvider).toggleOnline(rid, bid, online);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final c = AuthController(ref);
  // Kick off session restore once.
  Future.microtask(c.bootstrap);
  return c;
});
