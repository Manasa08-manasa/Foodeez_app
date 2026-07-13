class ApiOrderItem {
  final String id;
  final String name;
  final int quantity;
  final double unitPrice;
  final double itemTotal;
  final String? specialNote;
  final List<String> addonNames;

  const ApiOrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.itemTotal,
    this.specialNote,
    this.addonNames = const [],
  });

  factory ApiOrderItem.fromJson(Map<String, dynamic> json) {
    final qty = _toInt(json['quantity'], fallback: 1);
    final unit = _toDouble(json['unitPrice'] ?? json['price']);
    final total = _toDouble(json['itemTotal'] ?? json['total'] ?? (unit * qty));
    final addons = <String>[];
    final rawAddons = json['selectedAddons'] ?? json['addons'];
    if (rawAddons is List) {
      for (final a in rawAddons) {
        if (a is Map) {
          final n = a['name']?.toString();
          if (n != null && n.isNotEmpty) addons.add(n);
        } else if (a != null) {
          addons.add(a.toString());
        }
      }
    }
    return ApiOrderItem(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? json['menuItem']?['name'] ?? 'Item').toString(),
      quantity: qty,
      unitPrice: unit,
      itemTotal: total,
      specialNote: json['specialNote']?.toString(),
      addonNames: addons,
    );
  }
}

class ApiOrder {
  final String id;
  final String orderNumber;
  final String status;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? branchId;
  final String? restaurantId;
  final List<ApiOrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double packagingFee;
  final double taxAmount;
  final double discount;
  final double grandTotal;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? specialInstructions;
  final String? deliveryAddress;
  final double? distanceKm;
  final int? prepTimeMinutes;
  final DateTime createdAt;
  final String? autoRejectAt;

  const ApiOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.branchId,
    this.restaurantId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.packagingFee,
    required this.taxAmount,
    required this.discount,
    required this.grandTotal,
    this.paymentMethod,
    this.paymentStatus,
    this.specialInstructions,
    this.deliveryAddress,
    this.distanceKm,
    this.prepTimeMinutes,
    required this.createdAt,
    this.autoRejectAt,
  });

  factory ApiOrder.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    final addr = json['deliveryAddressSnapshot'] ?? json['deliveryAddress'] ?? json['address'];
    String? addressStr;
    if (addr is String) {
      addressStr = addr;
    } else if (addr is Map) {
      addressStr = [
        addr['addressLine1'],
        addr['addressLine2'],
        addr['city'],
        addr['state'],
        addr['pincode'],
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    }

    final rawItems = json['items'] ?? json['orderItems'] ?? json['order_items'];
    final items = (rawItems is List)
        ? rawItems
            .whereType<Map>()
            .map((e) => ApiOrderItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <ApiOrderItem>[];

    final rawId = json['id']?.toString() ?? '';
    final fallbackNumber = rawId.length > 6 ? '#${rawId.substring(rawId.length - 6).toUpperCase()}' : (rawId.isEmpty ? '#' : '#$rawId');

    return ApiOrder(
      id: rawId,
      orderNumber: (json['orderNumber'] ?? fallbackNumber).toString(),
      status: json['status']?.toString() ?? 'PLACED',
      customerName: (json['customerName'] ??
              (customer is Map ? customer['name'] ?? customer['displayName'] : null) ??
              json['customer_name'])
          ?.toString(),
      customerPhone: (json['customerPhone'] ?? (customer is Map ? customer['phone'] : null) ?? json['customer_phone'])
          ?.toString(),
      customerEmail: (json['customerEmail'] ?? (customer is Map ? customer['email'] : null))?.toString(),
      branchId: json['branchId']?.toString(),
      restaurantId: json['restaurantId']?.toString(),
      items: items,
      subtotal: _toDouble(json['subtotal'] ?? json['sub_total']),
      deliveryFee: _toDouble(json['deliveryFee'] ?? json['delivery_fee']),
      packagingFee: _toDouble(json['packagingFee'] ?? json['packaging_fee']),
      taxAmount: _toDouble(json['taxAmount'] ?? json['tax']),
      discount: _toDouble(json['couponDiscount'] ?? json['discount'] ?? json['discount_amount']),
      grandTotal: _toDouble(json['grandTotal'] ?? json['totalAmount'] ?? json['amount'] ?? json['total']),
      paymentMethod: json['paymentMethod']?.toString(),
      paymentStatus: json['paymentStatus']?.toString(),
      specialInstructions: json['specialInstructions']?.toString(),
      deliveryAddress: addressStr,
      distanceKm: _toDoubleOrNull(json['estimatedDistanceKm'] ?? json['distanceKm']),
      prepTimeMinutes: _toIntOrNull(json['prepTimeMinutes'] ?? json['prep_time_minutes']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      autoRejectAt: json['autoRejectAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'status': status,
        'grandTotal': grandTotal,
        'createdAt': createdAt.toIso8601String(),
      };
}

class SettlementSummaryDto {
  final String date;
  final int orderCount;
  final double totalItemValue;
  final double totalCommission;
  final double totalRestaurantShare;

  const SettlementSummaryDto({
    required this.date,
    required this.orderCount,
    required this.totalItemValue,
    required this.totalCommission,
    required this.totalRestaurantShare,
  });

  factory SettlementSummaryDto.fromJson(Map<String, dynamic> json) => SettlementSummaryDto(
        date: json['date']?.toString() ?? '',
        orderCount: _toInt(json['orderCount']),
        totalItemValue: _toDouble(json['totalItemValue']),
        totalCommission: _toDouble(json['totalCommission']),
        totalRestaurantShare: _toDouble(json['totalRestaurantShare']),
      );
}

class SettlementOrderDto {
  final String orderId;
  final String orderNumber;
  final String placedAt;
  final double itemValue;
  final String commissionBand;
  final double commission;
  final double restaurantShare;
  final bool capApplied;

  const SettlementOrderDto({
    required this.orderId,
    required this.orderNumber,
    required this.placedAt,
    required this.itemValue,
    required this.commissionBand,
    required this.commission,
    required this.restaurantShare,
    required this.capApplied,
  });

  factory SettlementOrderDto.fromJson(Map<String, dynamic> json) => SettlementOrderDto(
        orderId: json['orderId']?.toString() ?? '',
        orderNumber: json['orderNumber']?.toString() ?? '',
        placedAt: json['placedAt']?.toString() ?? '',
        itemValue: _toDouble(json['itemValue']),
        commissionBand: json['commissionBand']?.toString() ?? '',
        commission: _toDouble(json['commission']),
        restaurantShare: _toDouble(json['restaurantShare']),
        capApplied: json['capApplied'] == true,
      );
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

int? _toIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
