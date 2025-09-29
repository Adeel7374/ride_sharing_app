import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideRequest extends Equatable {
  final String id;
  final String passengerId;
  final String? driverId;
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double? fare;
  final String? pickupAddress;
  final String? dropoffAddress;
  final String? passengerName;
  final String? driverName;

  const RideRequest({
    required this.id,
    required this.passengerId,
    this.driverId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.fare,
    this.pickupAddress,
    this.dropoffAddress,
    this.passengerName,
    this.driverName,
  });

  @override
  List<Object?> get props => [
        id,
        passengerId,
        driverId,
        pickupLocation,
        dropoffLocation,
        status,
        createdAt,
        updatedAt,
        fare,
        pickupAddress,
        dropoffAddress,
        passengerName,
        driverName,
      ];

  RideRequest copyWith({
    String? id,
    String? passengerId,
    String? driverId,
    LatLng? pickupLocation,
    LatLng? dropoffLocation,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? fare,
    String? pickupAddress,
    String? dropoffAddress,
    String? passengerName,
    String? driverName,
  }) {
    return RideRequest(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      driverId: driverId ?? this.driverId,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fare: fare ?? this.fare,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      passengerName: passengerName ?? this.passengerName,
      driverName: driverName ?? this.driverName,
    );
  }
}
