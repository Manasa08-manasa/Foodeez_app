class ApiMenuCategory {
  final String id;
  final String name;
  final String displayName;

  const ApiMenuCategory({
    required this.id,
    required this.name,
    required this.displayName,
  });

  factory ApiMenuCategory.fromJson(Map<String, dynamic> json) => ApiMenuCategory(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        displayName: (json['displayName'] ?? json['name'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'displayName': displayName,
      };
}

class ApiMenuItem {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final bool isVisible;
  final bool isInStock;
  final String? imageUrl;
  final String categoryId;
  final String categoryName;
  final bool? isVeg;

  const ApiMenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.currency = 'INR',
    this.isVisible = true,
    this.isInStock = true,
    this.imageUrl,
    required this.categoryId,
    required this.categoryName,
    this.isVeg,
  });

  factory ApiMenuItem.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    String categoryId = (json['categoryId'] ?? json['category_id'] ?? (category is Map ? category['id'] : null))
            ?.toString() ??
        '';
    String categoryName = 'Menu';
    if (category is Map) {
      categoryName = (category['displayName'] ?? category['name'] ?? categoryName).toString();
      categoryId = categoryId.isNotEmpty ? categoryId : (category['id']?.toString() ?? '');
    } else if (json['categoryName'] != null) {
      categoryName = json['categoryName'].toString();
    }
    return ApiMenuItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: _toDouble(json['price']),
      currency: json['currency']?.toString() ?? 'INR',
      isVisible: _toBool(json['isVisible'], fallback: true),
      isInStock: _toBool(json['isInStock'], fallback: true),
      imageUrl: (json['imageUrl'] ?? json['image_url'])?.toString(),
      categoryId: categoryId,
      categoryName: categoryName,
      isVeg: json['isVeg'] is bool
          ? json['isVeg'] as bool
          : (json['veg'] is bool ? json['veg'] as bool : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'currency': currency,
        'isVisible': isVisible,
        'isInStock': isInStock,
        'imageUrl': imageUrl,
        'categoryId': categoryId,
      };
}

class ApiCoupon {
  final String id;
  final String code;
  final String title;
  final String? description;
  final String type;
  final double discountValue;
  final double? maxDiscountCap;
  final double? minOrderValue;
  final String status;
  final String validFrom;
  final String validUntil;
  final String? rejectionReason;
  final int? totalUsageLimit;
  final int redeemed;

  const ApiCoupon({
    required this.id,
    required this.code,
    required this.title,
    this.description,
    required this.type,
    required this.discountValue,
    this.maxDiscountCap,
    this.minOrderValue,
    required this.status,
    required this.validFrom,
    required this.validUntil,
    this.rejectionReason,
    this.totalUsageLimit,
    this.redeemed = 0,
  });

  factory ApiCoupon.fromJson(Map<String, dynamic> json) => ApiCoupon(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        type: json['type']?.toString() ?? 'FLAT',
        discountValue: _toDouble(json['discountValue']),
        maxDiscountCap: json['maxDiscountCap'] == null ? null : _toDouble(json['maxDiscountCap']),
        minOrderValue: json['minOrderValue'] == null ? null : _toDouble(json['minOrderValue']),
        status: json['status']?.toString() ?? 'PENDING',
        validFrom: json['validFrom']?.toString() ?? '',
        validUntil: json['validUntil']?.toString() ?? '',
        rejectionReason: json['rejectionReason']?.toString(),
        totalUsageLimit: json['totalUsageLimit'] is num ? (json['totalUsageLimit'] as num).toInt() : null,
        redeemed: json['redeemed'] is num ? (json['redeemed'] as num).toInt() : 0,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'title': title,
        'description': description,
        'type': type,
        'discountValue': discountValue,
        'maxDiscountCap': maxDiscountCap,
        'minOrderValue': minOrderValue,
        'validFrom': validFrom,
        'validUntil': validUntil,
        'totalUsageLimit': totalUsageLimit,
      };
}

class ApiDocument {
  final String id;
  final String type;
  final String filename;
  final String status;
  final String uploadedAt;
  final String? downloadUrl;
  final String? previewUrl;
  final String? rejectionReason;

  const ApiDocument({
    required this.id,
    required this.type,
    required this.filename,
    required this.status,
    required this.uploadedAt,
    this.downloadUrl,
    this.previewUrl,
    this.rejectionReason,
  });

  factory ApiDocument.fromJson(Map<String, dynamic> json) => ApiDocument(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        filename: (json['filename'] ?? json['fileName'] ?? json['type'] ?? '').toString(),
        status: json['status']?.toString() ?? 'pending',
        uploadedAt: (json['uploadedAt'] ?? json['createdAt'] ?? '').toString(),
        downloadUrl: (json['downloadUrl'] ?? json['fileUrl'])?.toString(),
        previewUrl: json['previewUrl']?.toString(),
        rejectionReason: json['rejectionReason']?.toString(),
      );

  bool get isVerified {
    final s = status.toLowerCase();
    return s == 'verified' || s == 'approved';
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

bool _toBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final n = value.toString().toLowerCase();
  if (['true', '1', 'yes'].contains(n)) return true;
  if (['false', '0', 'no'].contains(n)) return false;
  return fallback;
}
