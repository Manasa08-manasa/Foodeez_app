import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/utils/api_mappers.dart';
import '../models/models.dart';
import '../repositories/restaurant_repository.dart';
import '../services/mock_data.dart';
import '../utils/theme.dart';
import 'auth_controller.dart';
import 'navigation_controller.dart';

/// Owns the restaurant's own promo offers plus the "New coupon" builder form.
class OffersController extends ChangeNotifier {
  OffersController(this.ref) {
    _authSub = ref.listen<AuthController>(authControllerProvider, (prev, next) {
      if (next.isAuthenticated) refresh();
    });
    if (ref.read(authControllerProvider).isAuthenticated) refresh();
  }

  final Ref ref;
  ProviderSubscription<AuthController>? _authSub;
  NavigationController get _nav => ref.read(navigationControllerProvider);

  List<RestaurantOffer> offers = seedOffers();
  bool usingApi = false;

  String couponType = 'flat';
  String couponCode = '';
  int couponPercent = 20;
  int couponValue = 100;
  int couponCap = 120;
  int couponMinOrder = 0;
  int couponValidDays = 30;
  int couponLimitTotal = 500;
  bool couponFirstOnly = false;
  String couponFreeItemId = 'gulab';

  @override
  void dispose() {
    _authSub?.close();
    super.dispose();
  }

  Future<void> refresh() async {
    final rid = ref.read(authControllerProvider).restaurantId;
    if (rid == null) return;
    try {
      final list = await ref.read(restaurantRepositoryProvider).getCoupons(rid);
      if (list.isEmpty) return;
      offers = list.map<RestaurantOffer>(ApiMappers.couponToOffer).toList();
      usingApi = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[Offers] refresh failed: $e');
    }
  }

  void _set(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  void pickCouponType(String t) => _set(() => couponType = t);
  void setCouponCode(String v) => _set(() => couponCode = v);
  void setCouponFreeItem(String id) => _set(() => couponFreeItemId = id);
  void toggleCouponFirstOnly() => _set(() => couponFirstOnly = !couponFirstOnly);

  void bumpCouponValue(int delta) => _set(() => couponValue = (couponValue + delta).clamp(10, 2000));
  void bumpCouponPercent(int delta) => _set(() => couponPercent = (couponPercent + delta).clamp(5, 90));
  void bumpCouponCap(int delta) => _set(() => couponCap = (couponCap + delta).clamp(20, 1000));
  void bumpCouponMinOrder(int delta) => _set(() => couponMinOrder = (couponMinOrder + delta).clamp(0, 3000));
  void bumpCouponValidDays(int delta) => _set(() {
        final step = delta > 0 ? (couponValidDays >= 7 ? 7 : 1) : (couponValidDays > 7 ? -7 : -1);
        couponValidDays = (couponValidDays + step).clamp(1, 180);
      });
  void bumpCouponLimitTotal(int delta) => _set(() => couponLimitTotal = (couponLimitTotal + delta).clamp(50, 9999));

  String get suggestedCouponCode => switch (couponType) {
        'flat' => 'SAVE$couponValue',
        'percent' => 'GET${couponPercent}PCT',
        'freedelivery' => 'FREESHIP',
        'freeitem' => 'FREEBITE',
        _ => 'FOODEEZ',
      };

  ({String title, String sub, String code, List<Color> gradient}) buildCouponPreview() {
    final item = couponType == 'freeitem' ? menuItemById(couponFreeItemId) : null;
    String title;
    final parts = <String>[];
    switch (couponType) {
      case 'flat':
        title = 'Flat ₹$couponValue OFF';
        break;
      case 'percent':
        title = '$couponPercent% OFF';
        parts.add('up to ₹$couponCap');
        break;
      case 'freedelivery':
        title = 'FREE DELIVERY';
        break;
      default:
        final nm = item?.name.replaceAll(RegExp(r'\s*\(.*\)'), '') ?? 'item';
        title = 'Free $nm';
    }
    parts.add(couponMinOrder > 0 ? 'on orders above ₹$couponMinOrder' : 'no minimum');
    if (couponFirstOnly) parts.add('first order only');
    final code = (couponCode.isEmpty ? suggestedCouponCode : couponCode).toUpperCase().replaceAll(RegExp(r'\s+'), '');
    final gradient = switch (couponType) {
      'flat' => const [AppColors.gold, AppColors.goldDark],
      'percent' => const [AppColors.accent, AppColors.accentLight],
      'freedelivery' => const [AppColors.green, AppColors.greenDark],
      _ => const [AppColors.accentDeep, AppColors.accentDeep2],
    };
    return (title: title, sub: parts.join(' · '), code: code, gradient: gradient);
  }

  Future<void> createCoupon() async {
    final b = buildCouponPreview();
    final rid = ref.read(authControllerProvider).restaurantId;

    if (usingApi && rid != null) {
      try {
        final now = DateTime.now();
        final until = now.add(Duration(days: couponValidDays));
        final type = switch (couponType) {
          'percent' => 'PERCENTAGE',
          'freedelivery' => 'FREE_DELIVERY',
          _ => 'FLAT',
        };
        await ref.read(restaurantRepositoryProvider).createCoupon(rid, {
          'code': b.code,
          'title': b.title,
          'type': type,
          'discountValue': couponType == 'percent' ? couponPercent : couponValue,
          if (couponType == 'percent') 'maxDiscountCap': couponCap,
          if (couponMinOrder > 0) 'minOrderValue': couponMinOrder,
          'totalUsageLimit': couponLimitTotal,
          'validFrom': DateFormat('yyyy-MM-dd').format(now),
          'validUntil': DateFormat('yyyy-MM-dd').format(until),
        });
        await refresh();
      } catch (e) {
        debugPrint('[Offers] create failed: $e');
        offers = [
          RestaurantOffer(title: b.title, sub: b.sub, code: b.code, gradient: b.gradient, live: true, redeemed: 0),
          ...offers,
        ];
      }
    } else {
      offers = [
        RestaurantOffer(title: b.title, sub: b.sub, code: b.code, gradient: b.gradient, live: true, redeemed: 0),
        ...offers,
      ];
    }

    couponCode = '';
    _nav.back();
    _nav.tab('offers');
    notifyListeners();
  }

  void toggleOfferLive(int index) {
    offers = offers.asMap().entries.map((e) => e.key == index ? e.value.copyWith(live: !e.value.live) : e.value).toList();
    notifyListeners();
  }
}

final offersControllerProvider =
    ChangeNotifierProvider<OffersController>((ref) => OffersController(ref));
