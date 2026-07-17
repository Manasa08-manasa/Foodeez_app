import 'package:flutter/material.dart';
import 'models.dart';
import '../core/utils/order_status_utils.dart';
import '../utils/theme.dart';
import '../utils/utils.dart';

/// Computed/derived presentation data for an [Order] — mirrors the design's
/// `decorate(order)` helper: status colors/labels, action button, OTP, ETA, totals.
class OrderView {
  final Order order;
  final String statusLabel;
  final Color statusFg;
  final Color statusBg;
  final String actionLabel;
  final Color actionColor;
  final bool isIncoming;
  final bool hasAdvance;
  final bool isOutForDelivery;
  final bool showOtp;
  final String otp;
  final String etaStr;
  final String custInitials;
  final String typeLine;
  final String itemsSummary;
  final String totalStr;

  OrderView._({
    required this.order,
    required this.statusLabel,
    required this.statusFg,
    required this.statusBg,
    required this.actionLabel,
    required this.actionColor,
    required this.isIncoming,
    required this.hasAdvance,
    required this.isOutForDelivery,
    required this.showOtp,
    required this.otp,
    required this.etaStr,
    required this.custInitials,
    required this.typeLine,
    required this.itemsSummary,
    required this.totalStr,
  });

  factory OrderView.of(Order o, {String? apiStatus}) {
    final label = apiStatus != null ? OrderStatusUtils.displayLabel(apiStatus) : null;
    final meta = _statusMeta(o.status);
    final completedLabel = o.type == OrderType.delivery ? 'DELIVERED' : (o.type == OrderType.dining ? 'SERVED' : 'PICKED UP');
    final act = _actionMeta(o.status, o.type, apiStatus: apiStatus);
    final raw = OrderStatusUtils.norm(apiStatus);
    return OrderView._(
      order: o,
      statusLabel: o.status == OrderStatus.completed ? completedLabel : (label ?? meta.label),
      statusFg: meta.fg,
      statusBg: meta.bg,
      actionLabel: act?.label ?? '',
      actionColor: act?.color ?? AppColors.bodyGrey,
      isIncoming: OrderStatusUtils.isPlaced(apiStatus) || o.status == OrderStatus.incoming,
      hasAdvance: OrderStatusUtils.canPartnerMarkReady(apiStatus),
      isOutForDelivery: raw == 'PICKED_UP' || raw == 'ON_THE_WAY' || o.status == OrderStatus.outForDelivery,
      showOtp: o.status == OrderStatus.ready && o.type == OrderType.delivery,
      otp: otpFor(o.id),
      etaStr: etaStrFor(o),
      custInitials: o.customer.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase(),
      typeLine: o.type + (o.dist.isNotEmpty ? ' · ${o.dist}' : ''),
      itemsSummary: o.lines.map((l) => '${l.qty}× ${l.name}').join(', '),
      totalStr: moneyFmt(o.total),
    );
  }
}

class _StatusMeta {
  final String label;
  final Color fg;
  final Color bg;
  const _StatusMeta(this.label, this.fg, this.bg);
}

_StatusMeta _statusMeta(OrderStatus s) => switch (s) {
      OrderStatus.incoming => const _StatusMeta('NEW', AppColors.amber, AppColors.amberPaleBg),
      OrderStatus.preparing => const _StatusMeta('PREPARING', AppColors.accent, AppColors.maroonTint),
      OrderStatus.ready => const _StatusMeta('READY', AppColors.green, AppColors.greenPaleBg2),
      OrderStatus.outForDelivery => const _StatusMeta('OUT FOR DELIVERY', AppColors.blue, AppColors.bluePaleBg),
      OrderStatus.completed => const _StatusMeta('COMPLETED', AppColors.bodyGrey, AppColors.cardBorder),
    };

class _ActionMeta {
  final String label;
  final Color color;
  const _ActionMeta(this.label, this.color);
}

_ActionMeta? _actionMeta(OrderStatus s, String type, {String? apiStatus}) {
  if (OrderStatusUtils.canPartnerMarkReady(apiStatus)) {
    return const _ActionMeta('Mark ready', AppColors.green);
  }
  return switch (s) {
      OrderStatus.incoming => const _ActionMeta('Accept', AppColors.green),
      OrderStatus.preparing => null,
      OrderStatus.ready => _ActionMeta(
          type == OrderType.delivery ? 'Hand to rider' : (type == OrderType.dining ? 'Mark served' : 'Mark picked up'),
          AppColors.accent,
        ),
      _ => null,
    };
}

/// The next status an order moves to when its action button is tapped.
OrderStatus? nextStatus(Order o) => switch (o.status) {
      OrderStatus.incoming => OrderStatus.preparing,
      OrderStatus.preparing => OrderStatus.ready,
      OrderStatus.ready => o.type == OrderType.delivery ? OrderStatus.outForDelivery : OrderStatus.completed,
      OrderStatus.outForDelivery => OrderStatus.completed,
      OrderStatus.completed => null,
    };

String otpFor(String id) {
  final n = int.tryParse(id.replaceAll(RegExp(r'\D'), '')) ?? 0;
  return (1000 + (n * 37) % 9000).toString();
}

int travelMinsFor(Order o) {
  if (o.type != OrderType.delivery) return 0;
  final d = double.tryParse(o.dist.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1.5;
  return (d * 3).round() + 7;
}

String etaStrFor(Order o) {
  final p = o.prepMinutes;
  if (o.type == OrderType.delivery) return 'Prep $p min · Delivery ~${p + travelMinsFor(o)} min';
  return o.type == OrderType.takeaway ? 'Ready in $p min · Takeaway' : 'Ready in $p min · Dine-in';
}
