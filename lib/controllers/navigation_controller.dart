import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Owns the screen-stack navigation state: mirrors the design prototype's
/// `Component` state machine — a screen stack for push/pop flows, plus a
/// "tab reset" mode for the 5 bottom-dock destinations.
class NavigationController extends ChangeNotifier {
  List<String> stack = ['login'];
  String get screen => stack.last;

  void go(String s) {
    stack = [...stack, s];
    notifyListeners();
  }

  void back() {
    if (stack.length > 1) {
      stack = stack.sublist(0, stack.length - 1);
    } else {
      stack = ['dashboard'];
    }
    notifyListeners();
  }

  void tab(String s) {
    stack = [s];
    notifyListeners();
  }

  void toDashboard() => tab('dashboard');
  void toOrders() => tab('orders');
  void toSettings() => tab('settings');
  void toReviews() => go('reviews');
  void toEarnings() => go('earnings');
  void toSubscription() => go('subscription');
  void toOffers() => go('offers');
  void toNewCoupon() => go('newCoupon');

  void logout() {
    stack = ['login'];
    notifyListeners();
  }

  static const _hideTabScreens = {
    'login', 'detail', 'support', 'hours', 'earnings', 'offers', 'reviews',
    'address', 'fssai', 'bookings', 'subscription', 'newCoupon',
  };

  bool get showTabBar => !_hideTabScreens.contains(screen);

  static const _activeTabFor = {
    'dashboard': 'dashboard', 'orders': 'orders', 'detail': 'orders', 'menu': 'menu',
    'insights': 'insights', 'earnings': 'settings', 'reviews': 'settings',
    'offers': 'settings', 'settings': 'settings', 'subscription': 'settings', 'newCoupon': 'settings',
  };

  String get activeTab => _activeTabFor[screen] ?? '';
}

final navigationControllerProvider =
    ChangeNotifierProvider<NavigationController>((ref) => NavigationController());
