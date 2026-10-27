class ImageModel {
  final int id;
  final String url;

  ImageModel({required this.id, required this.url});

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      url: json['url'] ?? '',
    );
  }
}

class AmenityModel {
  final int id;
  final String name;

  AmenityModel({required this.id, required this.name});

  factory AmenityModel.fromJson(Map<String, dynamic> json) {
    return AmenityModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class RoomModel {
  final int id;
  final int? propertyId;
  final String roomNumber;
  final int bedrooms;
  final int bathrooms;
  final double size;
  final double price;
  final String status; // 'AVAILABLE', 'RESERVED', 'OCCUPIED'

  RoomModel({
    required this.id,
    this.propertyId,
    required this.roomNumber,
    required this.bedrooms,
    required this.bathrooms,
    required this.size,
    required this.price,
    required this.status,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      propertyId: (json['propertyId'] as num?)?.toInt(),
      roomNumber: json['roomNumber'] ?? '',
      bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 1,
      bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 1,
      size: (json['size'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'AVAILABLE',
    );
  }
}

class PropertyModel {
  final int id;
  final int? landlordId;
  final String? landlordName;
  final String title;
  final String? description;
  final String propertyType; // 'APARTMENT', 'HOUSE', 'CONDO', 'STUDIO', 'ROOM', 'VILLA', 'SHOPHOUSE'
  final String address;
  final double? latitude;
  final double? longitude;
  final double price;
  final String status; // 'DRAFT', 'PUBLISHED', 'RENTED', 'UNPUBLISHED'
  final String? createdAt;
  final List<ImageModel> images;
  final List<AmenityModel> amenities;
  final List<RoomModel> rooms;

  PropertyModel({
    required this.id,
    this.landlordId,
    this.landlordName,
    required this.title,
    this.description,
    required this.propertyType,
    required this.address,
    this.latitude,
    this.longitude,
    required this.price,
    required this.status,
    this.createdAt,
    required this.images,
    required this.amenities,
    required this.rooms,
  });

  String? get primaryImageUrl => images.isNotEmpty ? images.first.url : null;

  int get totalBedrooms => rooms.fold(0, (sum, r) => sum + r.bedrooms);
  int get totalBathrooms => rooms.fold(0, (sum, r) => sum + r.bathrooms);
  int get availableRoomsCount => rooms.where((r) => r.status == 'AVAILABLE').length;

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    List<ImageModel> parsedImages = [];
    if (json['images'] != null && json['images'] is List) {
      parsedImages = (json['images'] as List)
          .map((i) => ImageModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    List<AmenityModel> parsedAmenities = [];
    if (json['amenities'] != null && json['amenities'] is List) {
      parsedAmenities = (json['amenities'] as List)
          .map((a) => AmenityModel.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    List<RoomModel> parsedRooms = [];
    if (json['rooms'] != null && json['rooms'] is List) {
      parsedRooms = (json['rooms'] as List)
          .map((r) => RoomModel.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return PropertyModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      landlordId: (json['landlordId'] as num?)?.toInt(),
      landlordName: json['landlordName'],
      title: json['title'] ?? '',
      description: json['description'],
      propertyType: json['propertyType'] ?? 'ROOM',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'DRAFT',
      createdAt: json['createdAt'],
      images: parsedImages,
      amenities: parsedAmenities,
      rooms: parsedRooms,
    );
  }
}
