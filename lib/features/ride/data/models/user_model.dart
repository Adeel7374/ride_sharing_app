import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.phoneNumber,
    super.profileImageUrl,
    super.currentLocation,
    super.isOnline = false,
    super.lastSeen,
    super.vehicleInfo,
    super.rating,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'PASSENGER',
      phoneNumber: json['phoneNumber'],
      profileImageUrl: json['profileImageUrl'],
      currentLocation: json['currentLocation'] != null
          ? LatLng(
              json['currentLocation']['latitude'] ?? 0.0,
              json['currentLocation']['longitude'] ?? 0.0,
            )
          : null,
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen']) 
          : null,
      vehicleInfo: json['vehicleInfo'],
      rating: json['rating']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'currentLocation': currentLocation != null
          ? {
              'latitude': currentLocation!.latitude,
              'longitude': currentLocation!.longitude,
            }
          : null,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'vehicleInfo': vehicleInfo,
      'rating': rating,
    };
  }

  factory UserModel.fromEntity(User entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      role: entity.role,
      phoneNumber: entity.phoneNumber,
      profileImageUrl: entity.profileImageUrl,
      currentLocation: entity.currentLocation,
      isOnline: entity.isOnline,
      lastSeen: entity.lastSeen,
      vehicleInfo: entity.vehicleInfo,
      rating: entity.rating,
    );
  }
}
