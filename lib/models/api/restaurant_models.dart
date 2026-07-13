class ApiRestaurant {
  final String id;
  final String name;
  final String? ownerName;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? gstNumber;
  final String? fssaiNumber;
  final String? coverPhotoUrl;
  final String status;
  final List<String> cuisineTags;

  const ApiRestaurant({
    required this.id,
    required this.name,
    this.ownerName,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.gstNumber,
    this.fssaiNumber,
    this.coverPhotoUrl,
    this.status = 'active',
    this.cuisineTags = const [],
  });

  factory ApiRestaurant.fromJson(Map<String, dynamic> json) => ApiRestaurant(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        ownerName: json['ownerName']?.toString(),
        email: json['email']?.toString(),
        phone: json['phone']?.toString(),
        address: json['address']?.toString(),
        city: json['city']?.toString(),
        state: json['state']?.toString(),
        zipCode: json['zipCode']?.toString(),
        gstNumber: json['gstNumber']?.toString(),
        fssaiNumber: json['fssaiNumber']?.toString(),
        coverPhotoUrl: json['coverPhotoUrl']?.toString(),
        status: json['status']?.toString() ?? 'active',
        cuisineTags: (json['cuisineTags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );

  String get initials {
    final parts = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return 'R';
    return parts.take(2).map((w) => w[0].toUpperCase()).join();
  }

  String get locationLine {
    final bits = <String>[];
    if (city != null && city!.isNotEmpty) bits.add(city!);
    if (address != null && address!.isNotEmpty) {
      final short = address!.split(',').first.trim();
      if (short.isNotEmpty && !bits.contains(short)) bits.insert(0, short);
    }
    return bits.isEmpty ? 'Restaurant' : bits.join(' · ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ownerName': ownerName,
        'email': email,
        'phone': phone,
        'address': address,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'gstNumber': gstNumber,
        'fssaiNumber': fssaiNumber,
        'coverPhotoUrl': coverPhotoUrl,
        'status': status,
        'cuisineTags': cuisineTags,
      };
}

class ApiBranch {
  final String id;
  final String restaurantId;
  final String name;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? openingTime;
  final String? closingTime;
  final double? latitude;
  final double? longitude;
  final bool isOnline;

  const ApiBranch({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.openingTime,
    this.closingTime,
    this.latitude,
    this.longitude,
    this.isOnline = false,
  });

  factory ApiBranch.fromJson(Map<String, dynamic> json) => ApiBranch(
        id: json['id']?.toString() ?? '',
        restaurantId: json['restaurantId']?.toString() ??
            (json['restaurant'] is Map ? json['restaurant']['id']?.toString() : null) ??
            '',
        name: json['name']?.toString() ?? '',
        address: json['address']?.toString(),
        city: json['city']?.toString(),
        state: json['state']?.toString(),
        zipCode: json['zipCode']?.toString(),
        openingTime: json['openingTime']?.toString(),
        closingTime: json['closingTime']?.toString(),
        latitude: _toDouble(json['latitude']),
        longitude: _toDouble(json['longitude']),
        isOnline: _toBool(json['isOnline']),
      );

  ApiBranch copyWith({bool? isOnline, String? openingTime, String? closingTime}) => ApiBranch(
        id: id,
        restaurantId: restaurantId,
        name: name,
        address: address,
        city: city,
        state: state,
        zipCode: zipCode,
        openingTime: openingTime ?? this.openingTime,
        closingTime: closingTime ?? this.closingTime,
        latitude: latitude,
        longitude: longitude,
        isOnline: isOnline ?? this.isOnline,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurantId': restaurantId,
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'openingTime': openingTime,
        'closingTime': closingTime,
        'latitude': latitude,
        'longitude': longitude,
        'isOnline': isOnline,
      };
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final n = value?.toString().toLowerCase();
  return n == 'true' || n == '1' || n == 'yes';
}
