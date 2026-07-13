import '../../models/api/menu_models.dart';
import '../../models/api/order_models.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import 'media_url.dart';

/// Maps restaurant-admin API DTOs onto the existing Foodeez Partner UI models
/// so views stay unchanged.
class ApiMappers {
  static OrderStatus mapOrderStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
        return OrderStatus.incoming;
      case 'ACCEPTED':
      case 'CONFIRMED':
      case 'PREPARING':
        return OrderStatus.preparing;
      case 'READY':
      case 'READY_FOR_PICKUP':
        return OrderStatus.ready;
      case 'PICKED_UP':
      case 'ON_THE_WAY':
        return OrderStatus.outForDelivery;
      case 'DELIVERED':
      case 'COMPLETED':
      case 'CANCELLED':
      case 'REJECTED':
      case 'FAILED':
        return OrderStatus.completed;
      default:
        return OrderStatus.incoming;
    }
  }

  static String mapOrderType(ApiOrder o) {
    if (o.deliveryAddress != null && o.deliveryAddress!.isNotEmpty) {
      return OrderType.delivery;
    }
    if (o.deliveryFee > 0) return OrderType.delivery;
    return OrderType.takeaway;
  }

  static String relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays}d ago';
  }

  static Order toUiOrder(ApiOrder o) {
    final lines = o.items
        .map(
          (i) => OrderLine(
            name: i.addonNames.isEmpty ? i.name : '${i.name} (+${i.addonNames.join(', ')})',
            qty: i.quantity,
            price: i.unitPrice.round(),
            veg: true,
          ),
        )
        .toList();

    if (lines.isEmpty && o.grandTotal > 0) {
      lines.add(OrderLine(name: 'Order total', qty: 1, price: o.grandTotal.round(), veg: true));
    }

    final payBits = <String>[];
    if (o.paymentStatus != null && o.paymentStatus!.isNotEmpty) {
      payBits.add(o.paymentStatus!);
    } else {
      payBits.add('Paid');
    }
    if (o.paymentMethod != null && o.paymentMethod!.isNotEmpty) {
      payBits.add(o.paymentMethod!);
    }

    final dist = o.distanceKm != null ? '${o.distanceKm!.toStringAsFixed(1)} km' : '';

    return Order(
      id: o.orderNumber.isNotEmpty ? o.orderNumber : o.id,
      status: mapOrderStatus(o.status),
      type: mapOrderType(o),
      customer: o.customerName?.isNotEmpty == true ? o.customerName! : 'Customer',
      dist: dist,
      placed: relativeTime(o.createdAt),
      prepMinutes: o.prepTimeMinutes ?? 20,
      payLabel: payBits.join(' · '),
      lines: lines,
    );
  }

  static String apiIdOf(ApiOrder o) => o.id;

  static MenuItem toUiMenuItem(ApiMenuItem item) {
    return MenuItem(
      id: item.id,
      section: item.categoryName.isNotEmpty ? item.categoryName : 'Menu',
      name: item.name,
      basePrice: item.price.round(),
      veg: item.isVeg ?? true,
      soldThisWeek: 0,
      photoKey: 'biryani',
      baseAvail: item.isInStock && item.isVisible,
      imageUrl: resolveMediaUrl(item.imageUrl),
    );
  }

  static RestaurantOffer couponToOffer(ApiCoupon c) {
    final gradient = switch (c.type.toUpperCase()) {
      'PERCENTAGE' => const [AppColors.accent, AppColors.accentLight],
      'FREE_DELIVERY' => const [AppColors.green, AppColors.greenDark],
      'CASHBACK' => const [AppColors.accentDeep, AppColors.accentDeep2],
      _ => const [AppColors.gold, AppColors.goldDark],
    };
    final title = switch (c.type.toUpperCase()) {
      'PERCENTAGE' => '${c.discountValue.round()}% OFF',
      'FREE_DELIVERY' => 'FREE DELIVERY',
      'CASHBACK' => '₹${c.discountValue.round()} cashback',
      _ => 'Flat ₹${c.discountValue.round()} OFF',
    };
    final parts = <String>[];
    if (c.minOrderValue != null && c.minOrderValue! > 0) {
      parts.add('on orders above ₹${c.minOrderValue!.round()}');
    }
    if (c.maxDiscountCap != null && c.maxDiscountCap! > 0) {
      parts.add('up to ₹${c.maxDiscountCap!.round()}');
    }
    parts.add(c.status);
    return RestaurantOffer(
      title: c.title.isNotEmpty ? c.title : title,
      sub: parts.join(' · '),
      code: c.code,
      gradient: gradient,
      live: c.status.toUpperCase() == 'ACTIVE',
      redeemed: c.redeemed,
    );
  }
}
