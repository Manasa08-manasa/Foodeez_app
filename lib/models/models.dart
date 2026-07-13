import 'package:flutter/material.dart';

class MenuItem {
  final String id;
  final String section;
  final String name;
  final int basePrice;
  final bool veg;
  final int soldThisWeek;
  final bool baseAvail;
  final String photoKey;
  /// When set (from API), used as the image source instead of [photoKey].
  final String? imageUrl;

  const MenuItem({
    required this.id,
    required this.section,
    required this.name,
    required this.basePrice,
    required this.veg,
    required this.soldThisWeek,
    required this.photoKey,
    this.baseAvail = true,
    this.imageUrl,
  });
}

class OrderLine {
  final String name;
  final int qty;
  final int price;
  final bool veg;

  const OrderLine({required this.name, required this.qty, required this.price, required this.veg});

  int get lineTotal => price * qty;
}

/// Order lifecycle: incoming -> preparing -> ready -> (delivery only: outForDelivery ->) completed.
enum OrderStatus { incoming, preparing, ready, outForDelivery, completed }

/// Matches the design's raw `type` strings: 'Delivery' | 'Takeaway' | 'Dining'.
class OrderType {
  static const delivery = 'Delivery';
  static const takeaway = 'Takeaway';
  static const dining = 'Dining';
}

class Order {
  final String id;
  final OrderStatus status;
  final String type;
  final String customer;
  final String dist; // e.g. "2.1 km", empty for non-delivery
  final String placed;
  final int prepMinutes;
  final String payLabel;
  final List<OrderLine> lines;

  const Order({
    required this.id,
    required this.status,
    required this.type,
    required this.customer,
    required this.dist,
    required this.placed,
    required this.prepMinutes,
    required this.payLabel,
    required this.lines,
  });

  int get total => lines.fold(0, (a, l) => a + l.lineTotal);

  Order copyWith({OrderStatus? status, String? placed, int? prepMinutes}) => Order(
        id: id,
        status: status ?? this.status,
        type: type,
        customer: customer,
        dist: dist,
        placed: placed ?? this.placed,
        prepMinutes: prepMinutes ?? this.prepMinutes,
        payLabel: payLabel,
        lines: lines,
      );
}

class TableBooking {
  final String id;
  final String name;
  final String date;
  final String time;
  final int party;
  final String ref;
  final String status; // Confirmed | Completed | Cancelled
  final bool paid;
  final int amount;
  final String note;

  const TableBooking({
    required this.id,
    required this.name,
    required this.date,
    required this.time,
    required this.party,
    required this.ref,
    required this.status,
    required this.paid,
    required this.amount,
    required this.note,
  });
}

class PaymentTxn {
  final String id;
  final String label;
  final String method;
  final int amount;
  final String when;
  final String kind; // credit | debit | paid

  const PaymentTxn({
    required this.id,
    required this.label,
    required this.method,
    required this.amount,
    required this.when,
    required this.kind,
  });
}

class Review {
  final String name;
  final int rating;
  final String when;
  final String item;
  final String text;
  final String reply;

  const Review({
    required this.name,
    required this.rating,
    required this.when,
    required this.item,
    required this.text,
    this.reply = '',
  });
}

/// A promo the restaurant itself runs (distinct from the customer app's
/// platform-level Coupon model) — created via the New Coupon builder,
/// paused/resumed from the Offers screen.
class RestaurantOffer {
  final String title;
  final String sub;
  final String code;
  final List<Color> gradient;
  final bool live;
  final int redeemed;

  const RestaurantOffer({
    required this.title,
    required this.sub,
    required this.code,
    required this.gradient,
    required this.live,
    required this.redeemed,
  });

  RestaurantOffer copyWith({bool? live}) => RestaurantOffer(
        title: title,
        sub: sub,
        code: code,
        gradient: gradient,
        live: live ?? this.live,
        redeemed: redeemed,
      );
}

/// One day's settlement — backend supplies the raw fields, the app computes
/// gross / total deductions / net. Mirrors the design's payout breakdown.
class Settlement {
  final String id;
  final String week;
  final String date;
  final int agoDays;
  final int orders;
  final String tierLabel;
  final int itemSales;
  final int packaging;
  final int gst;
  final int discount;
  final int ads;
  final int delivery;
  final int subscriptionFee;
  final int tcs;
  final int tds;

  const Settlement({
    required this.id,
    required this.week,
    required this.date,
    required this.agoDays,
    required this.orders,
    required this.tierLabel,
    required this.itemSales,
    required this.packaging,
    required this.gst,
    required this.discount,
    required this.ads,
    required this.delivery,
    required this.subscriptionFee,
    required this.tcs,
    required this.tds,
  });

  int get gross => itemSales + packaging;

  int get totalDeductions => discount + subscriptionFee + ads + delivery + tcs + tds;

  int get net => gross - totalDeductions;
}

/// One period's earnings summary (Today / This week / This month).
class EarningsPeriod {
  final String label;
  final String span;
  final int orders;
  final int gmv;
  final int subscriptionFee;
  final String subNote;

  const EarningsPeriod({
    required this.label,
    required this.span,
    required this.orders,
    required this.gmv,
    required this.subscriptionFee,
    required this.subNote,
  });

  int get net => gmv - subscriptionFee;

  int get aggregatorWouldTake => (gmv * 0.30).round();

  int get saved => aggregatorWouldTake - subscriptionFee;
}

class SubscriptionTier {
  final int n;
  final String range;
  final int fee;

  const SubscriptionTier({required this.n, required this.range, required this.fee});
}
