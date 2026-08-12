import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Owns the screen-stack navigation state: mirrors the design prototype's
/// `Component` state machine — a screen stack for push/pop flows, plus a
/// "tab reset" mode for the 5 bottom-dock destinations.
class NavigationController extends ChangeNotifier {
  List<String> stack = ['splash'];
  String get screen => stack.last;

  bool _isAuthenticated = false;

  /// Kept in sync from [AppShell] so back/tab/go respect login state.
  void syncAuthSession(bool authenticated) {
    _isAuthenticated = authenticated;
  }

  static const publicScreens = {'splash', 'login', 'register'};

  static bool isPublicScreen(String s) => publicScreens.contains(s);

  void go(String s) {
    if (!_isAuthenticated && !isPublicScreen(s)) {
      tab('login');
      return;
    }
    stack = [...stack, s];
    notifyListeners();
  }

  void back() {
    if (stack.length > 1) {
      stack = stack.sublist(0, stack.length - 1);
      if (!_isAuthenticated && !isPublicScreen(screen)) {
        stack = ['login'];
      }
      notifyListeners();
      return;
    }

    // Root screen — system back must not open dashboard without login.
    if (!_isAuthenticated) {
      if (screen == 'register') {
        stack = ['login'];
        notifyListeners();
      }
      return;
    }

    // Authenticated root tab: go back to dashboard.
    // (Orders/Menu/Branches/Settings are top-level tabs, so "back" should
    // return to dashboard instead of doing nothing.)
    if (screen != 'dashboard') {
      stack = ['dashboard'];
      notifyListeners();
    }
  }

  void tab(String s) {
    if (!_isAuthenticated && !isPublicScreen(s)) {
      stack = ['login'];
      notifyListeners();
      return;
    }
    stack = [s];
    notifyListeners();
  }

  void toDashboard() => tab('dashboard');
  void toOrders() => tab('orders');
  void toBranches() => tab('branches');
  void toSettings() => tab('settings');
  void toReviews() => go('reviews');
  void toEarnings() => go('earnings');
  void toSubscription() => go('subscription');
  void toOffers() => go('offers');
  void toNewCoupon() => go('newCoupon');

  void logout() {
    _isAuthenticated = false;
    stack = ['login'];
    notifyListeners();
  }

  static const _hideTabScreens = {
    'splash', 'login', 'register', 'detail', 'support', 'hours', 'earnings', 'offers', 'reviews',
    'address', 'fssai', 'bookings', 'subscription', 'newCoupon',
  };

  bool get showTabBar => !_hideTabScreens.contains(screen);

  static const _activeTabFor = {
    'dashboard': 'dashboard', 'orders': 'orders', 'detail': 'orders', 'menu': 'menu',
    'branches': 'branches', 'insights': 'insights', 'earnings': 'settings', 'reviews': 'settings',
    'offers': 'settings', 'settings': 'settings', 'team': 'settings', 'subscription': 'settings', 'newCoupon': 'settings',
  };

  String get activeTab => _activeTabFor[screen] ?? '';
}

final navigationControllerProvider =
    ChangeNotifierProvider<NavigationController>((ref) => NavigationController());
