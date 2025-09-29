import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String role; // PASSENGER or DRIVER
  final String? phoneNumber;
  final String? profileImageUrl;
  final LatLng? currentLocation;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? vehicleInfo; // For drivers
  final double? rating; // For drivers

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.profileImageUrl,
    this.currentLocation,
    this.isOnline = false,
    this.lastSeen,
    this.vehicleInfo,
    this.rating,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        role,
        phoneNumber,
        profileImageUrl,
        currentLocation,
        isOnline,
        lastSeen,
        vehicleInfo,
        rating,
      ];

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phoneNumber,
    String? profileImageUrl,
    LatLng? currentLocation,
    bool? isOnline,
    DateTime? lastSeen,
    String? vehicleInfo,
    double? rating,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      currentLocation: currentLocation ?? this.currentLocation,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      rating: rating ?? this.rating,
    );
  }

  bool get isDriver => role == 'DRIVER';
  bool get isPassenger => role == 'PASSENGER';
}
