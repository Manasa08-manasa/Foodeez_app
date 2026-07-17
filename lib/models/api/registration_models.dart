class RegistrationPricing {
  const RegistrationPricing({
    required this.basePrice,
    required this.offerPrice,
    required this.isOfferActive,
    required this.effectivePrice,
    required this.effectiveAmountInPaise,
    required this.currency,
  });

  final double basePrice;
  final double offerPrice;
  final bool isOfferActive;
  final double effectivePrice;
  final int effectiveAmountInPaise;
  final String currency;

  factory RegistrationPricing.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    return RegistrationPricing(
      basePrice: toDouble(json['basePrice']),
      offerPrice: toDouble(json['offerPrice']),
      isOfferActive: json['isOfferActive'] == true,
      effectivePrice: toDouble(json['effectivePrice']),
      effectiveAmountInPaise: json['effectiveAmountInPaise'] is int
          ? json['effectiveAmountInPaise'] as int
          : int.tryParse('${json['effectiveAmountInPaise']}') ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
    );
  }
}

class CreateRegistrationOrderResponse {
  const CreateRegistrationOrderResponse({
    required this.keyId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.basePrice,
    required this.offerPrice,
    required this.isOfferActive,
    required this.restaurantId,
    required this.restaurantName,
  });

  final String keyId;
  final String orderId;
  final int amount;
  final String currency;
  final double basePrice;
  final double offerPrice;
  final bool isOfferActive;
  final String restaurantId;
  final String restaurantName;

  factory CreateRegistrationOrderResponse.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    return CreateRegistrationOrderResponse(
      keyId: json['keyId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      amount: json['amount'] is int ? json['amount'] as int : int.tryParse('${json['amount']}') ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      basePrice: toDouble(json['basePrice']),
      offerPrice: toDouble(json['offerPrice']),
      isOfferActive: json['isOfferActive'] == true,
      restaurantId: json['restaurantId']?.toString() ?? '',
      restaurantName: json['restaurantName']?.toString() ?? '',
    );
  }
}

class MenuScanItem {
  const MenuScanItem({
    required this.name,
    this.description,
    required this.price,
    required this.currency,
  });

  final String name;
  final String? description;
  final String price;
  final String currency;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null && description!.isNotEmpty) 'description': description,
        'price': price,
        'currency': currency,
      };

  factory MenuScanItem.fromJson(Map<String, dynamic> json) => MenuScanItem(
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        price: '${json['price'] ?? 0}',
        currency: json['currency']?.toString() ?? 'INR',
      );
}

class MenuScanCategory {
  const MenuScanCategory({
    required this.name,
    required this.displayName,
    required this.items,
  });

  final String name;
  final String displayName;
  final List<MenuScanItem> items;

  Map<String, dynamic> toJson() => {
        'name': name,
        'displayName': displayName,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory MenuScanCategory.fromJson(Map<String, dynamic> json) => MenuScanCategory(
        name: json['name']?.toString() ?? '',
        displayName: json['displayName']?.toString() ?? '',
        items: (json['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => MenuScanItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class PanVerifyResult {
  const PanVerifyResult({required this.valid, this.name, this.message});

  final bool valid;
  final String? name;
  final String? message;

  factory PanVerifyResult.fromJson(Map<String, dynamic> json) => PanVerifyResult(
        valid: json['valid'] == true,
        name: json['name']?.toString(),
        message: json['message']?.toString(),
      );
}

class PartnerOtpRequestResult {
  const PartnerOtpRequestResult({
    required this.email,
    this.status,
    this.nextStep,
    this.message,
  });

  final String email;
  final String? status;
  final String? nextStep;
  final String? message;

  factory PartnerOtpRequestResult.fromJson(Map<String, dynamic> json) => PartnerOtpRequestResult(
        email: json['email']?.toString() ?? '',
        status: json['status']?.toString(),
        nextStep: json['nextStep']?.toString(),
        message: json['message']?.toString(),
      );
}

class PartnerOtpVerifyResult {
  const PartnerOtpVerifyResult({
    required this.email,
    this.accessToken,
    this.status,
    this.nextStep,
    this.message,
  });

  final String email;
  final String? accessToken;
  final String? status;
  final String? nextStep;
  final String? message;

  factory PartnerOtpVerifyResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json;
    return PartnerOtpVerifyResult(
      email: (data['email'] ?? json['email'])?.toString() ?? '',
      accessToken: (data['accessToken'] ?? json['accessToken'])?.toString(),
      status: (data['status'] ?? json['status'])?.toString(),
      nextStep: (data['nextStep'] ?? json['nextStep'])?.toString(),
      message: (data['message'] ?? json['message'])?.toString(),
    );
  }
}

class PartnerRegisterStepResult {
  const PartnerRegisterStepResult({
    required this.restaurantId,
    this.accessToken,
    this.status,
    this.nextStep,
    this.message,
    this.raw = const {},
  });

  final String restaurantId;
  final String? accessToken;
  final String? status;
  final String? nextStep;
  final String? message;
  final Map<String, dynamic> raw;

  factory PartnerRegisterStepResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json;
    final id = data['id'] ??
        data['restaurantId'] ??
        json['id'] ??
        json['restaurantId'] ??
        (data['restaurant'] is Map ? (data['restaurant'] as Map)['id'] : null);
    return PartnerRegisterStepResult(
      restaurantId: id?.toString() ?? '',
      accessToken: (data['accessToken'] ?? json['accessToken'])?.toString(),
      status: (data['status'] ?? json['status'])?.toString(),
      nextStep: (data['nextStep'] ?? json['nextStep'])?.toString(),
      message: (data['message'] ?? json['message'])?.toString(),
      raw: Map<String, dynamic>.from(data),
    );
  }
}
