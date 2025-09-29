import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/ride_request.dart';

class RideRequestModel extends RideRequest {
  const RideRequestModel({
    required super.id,
    required super.passengerId,
    super.driverId,
    required super.pickupLocation,
    required super.dropoffLocation,
    required super.status,
    required super.createdAt,
    super.updatedAt,
    super.fare,
    super.pickupAddress,
    super.dropoffAddress,
    super.passengerName,
    super.driverName,
  });

  factory RideRequestModel.fromJson(Map<String, dynamic> json) {
    // Handle createdAt field - could be String or Timestamp
    DateTime createdAt;
    final createdAtValue = json['createdAt'];
    
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is String) {
      createdAt = DateTime.parse(createdAtValue);
    } else {
      createdAt = DateTime.now(); // fallback
    }
    
    // Handle updatedAt field - could be String, Timestamp, or null
    DateTime? updatedAt;
    final updatedAtValue = json['updatedAt'];
    
    if (updatedAtValue is Timestamp) {
      updatedAt = updatedAtValue.toDate();
    } else if (updatedAtValue is String) {
      updatedAt = DateTime.parse(updatedAtValue);
    }
    // If it's null, leave it as null
    
    return RideRequestModel(
      id: json['id'] ?? '',
      passengerId: json['passengerId'] ?? '',
      driverId: json['driverId'],
      pickupLocation: LatLng(
        (json['pickupLocation']['latitude'] ?? 0.0) as double,
        (json['pickupLocation']['longitude'] ?? 0.0) as double,
      ),
      dropoffLocation: LatLng(
        (json['dropoffLocation']['latitude'] ?? 0.0) as double,
        (json['dropoffLocation']['longitude'] ?? 0.0) as double,
      ),
      status: json['status'] ?? 'REQUESTED',
      createdAt: createdAt,
      updatedAt: updatedAt,
      fare: json['fare'] != null ? (json['fare'] as num).toDouble() : null,
      pickupAddress: json['pickupAddress'],
      dropoffAddress: json['dropoffAddress'],
      passengerName: json['passengerName'],
      driverName: json['driverName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passengerId': passengerId,
      'driverId': driverId,
      'pickupLocation': {
        'latitude': pickupLocation.latitude,
        'longitude': pickupLocation.longitude,
      },
      'dropoffLocation': {
        'latitude': dropoffLocation.latitude,
        'longitude': dropoffLocation.longitude,
      },
      'status': status,
      'createdAt': createdAt.toIso8601String(), // Keep as String for consistency
      'updatedAt': updatedAt?.toIso8601String(),
      'fare': fare,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'passengerName': passengerName,
      'driverName': driverName,
    };
  }

  factory RideRequestModel.fromEntity(RideRequest entity) {
    return RideRequestModel(
      id: entity.id,
      passengerId: entity.passengerId,
      driverId: entity.driverId,
      pickupLocation: entity.pickupLocation,
      dropoffLocation: entity.dropoffLocation,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      fare: entity.fare,
      pickupAddress: entity.pickupAddress,
      dropoffAddress: entity.dropoffAddress,
      passengerName: entity.passengerName,
      driverName: entity.driverName,
    );
  }
}