import 'package:football/core/network/media_url.dart';

class FieldOwner {
  final String id;
  final String email;
  final String? phoneNumber;

  const FieldOwner({required this.id, required this.email, this.phoneNumber});

  factory FieldOwner.fromJson(Map<String, dynamic> json) {
    return FieldOwner(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phoneNumber: json['phoneNumber']?.toString(),
    );
  }
}

class FieldImage {
  final String id;
  final String fieldId;
  final String url;
  final bool isPrimary;
  final int order;
  final DateTime? createdAt;

  const FieldImage({
    required this.id,
    required this.fieldId,
    required this.url,
    required this.isPrimary,
    required this.order,
    required this.createdAt,
  });

  factory FieldImage.fromJson(dynamic raw) {
    if (raw is String) {
      return FieldImage(
        id: '',
        fieldId: '',
        url: resolvePublicMediaUrl(raw),
        isPrimary: false,
        order: 0,
        createdAt: null,
      );
    }

    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      int asInt(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;

      final rawUrl = (m['url'] ?? m['path'] ?? '').toString();
      return FieldImage(
        id: (m['id'] ?? '').toString(),
        fieldId: (m['fieldId'] ?? '').toString(),
        url: resolvePublicMediaUrl(rawUrl),
        isPrimary: m['isPrimary'] == true,
        order: asInt(m['order']),
        createdAt: m['createdAt'] == null
            ? null
            : DateTime.tryParse(m['createdAt'].toString()),
      );
    }

    return const FieldImage(
      id: '',
      fieldId: '',
      url: '',
      isPrimary: false,
      order: 0,
      createdAt: null,
    );
  }
}

class FieldModel {
  final String id;
  final String ownerId;
  final String name;
  final String? nameAr;
  final String? description;
  final String? descriptionAr;

  final String address;
  final String? addressAr;

  final double latitude;
  final double longitude;

  final double? basePrice;
  final double? commissionRate;

  final double? averageRating;
  final int totalReviews;

  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<FieldImage> images;
  final FieldOwner? owner;

  const FieldModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.nameAr,
    this.description,
    this.descriptionAr,
    required this.address,
    this.addressAr,
    required this.latitude,
    required this.longitude,
    this.basePrice,
    this.commissionRate,
    this.averageRating,
    required this.totalReviews,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
    this.owner,
  });

  String get displayName {
    if ((nameAr ?? '').trim().isNotEmpty) return nameAr!.trim();
    return name.trim();
  }

  String get displayAddress {
    if ((addressAr ?? '').trim().isNotEmpty) return addressAr!.trim();
    return address.trim();
  }

  String? get primaryImageUrl {
    if (images.isEmpty) return null;

    final sorted = [...images]..sort((a, b) => a.order.compareTo(b.order));

    for (final img in sorted) {
      if (img.isPrimary && img.url.trim().isNotEmpty) {
        return img.url.trim();
      }
    }

    for (final img in sorted) {
      if (img.url.trim().isNotEmpty) return img.url.trim();
    }

    return null;
  }

  factory FieldModel.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) {
      if (v == null) return 0.0;
      return v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    }

    double? asNullableDouble(dynamic v) {
      if (v == null) return null;
      return v is num ? v.toDouble() : double.tryParse(v.toString());
    }

    int asInt(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;

    final imagesRaw = json['images'];
    final List<FieldImage> imgs = (imagesRaw is List)
        ? imagesRaw
              .map((e) => FieldImage.fromJson(e))
              .where((e) => e.url.isNotEmpty)
              .toList()
        : <FieldImage>[];

    return FieldModel(
      id: (json['id'] ?? '').toString(),
      ownerId: (json['ownerId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      nameAr: json['nameAr']?.toString(),
      description: json['description']?.toString(),
      descriptionAr: json['descriptionAr']?.toString(),
      address: (json['address'] ?? '').toString(),
      addressAr: json['addressAr']?.toString(),
      latitude: asDouble(json['latitude']),
      longitude: asDouble(json['longitude']),
      basePrice: asNullableDouble(
        json['basePrice'] ??
            json['pricePerHour'] ??
            json['price'] ??
            json['hourPrice'],
      ),
      commissionRate: asNullableDouble(json['commissionRate']),
      averageRating: json['averageRating'] == null
          ? null
          : asNullableDouble(json['averageRating']),
      totalReviews: asInt(json['totalReviews']),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'].toString()),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
      images: imgs,
      owner: (json['owner'] is Map<String, dynamic>)
          ? FieldOwner.fromJson((json['owner'] as Map).cast<String, dynamic>())
          : null,
    );
  }
}