import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/ride_request.dart';

abstract class RideEvent extends Equatable {
  const RideEvent();

  @override
  List<Object?> get props => [];
}

class LoadRideRequests extends RideEvent {
  const LoadRideRequests();
}
// Add this to your RideEvent file
class RideErrorOccurred extends RideEvent {
  final String message;

  const RideErrorOccurred(this.message);

  @override
  List<Object> get props => [message];
}
class CreateRideRequest extends RideEvent {
  final String passengerId;
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final String? pickupAddress;
  final String? dropoffAddress;
  final String? passengerName;

  const CreateRideRequest({
    required this.passengerId,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.pickupAddress,
    this.dropoffAddress,
    this.passengerName,
  });

  @override
  List<Object?> get props => [
        passengerId,
        pickupLocation,
        dropoffLocation,
        pickupAddress,
        dropoffAddress,
        passengerName,
      ];
}

class AcceptRideRequest extends RideEvent {
  final String rideId;
  final String driverId;

  const AcceptRideRequest({
    required this.rideId,
    required this.driverId,
  });

  @override
  List<Object> get props => [rideId, driverId];
}

class UpdateRideStatus extends RideEvent {
  final String rideId;
  final String status;

  const UpdateRideStatus({
    required this.rideId,
    required this.status,
  });

  @override
  List<Object> get props => [rideId, status];
}

class UpdateDriverLocation extends RideEvent {
  final String driverId;
  final LatLng location;

  const UpdateDriverLocation({
    required this.driverId,
    required this.location,
  });

  @override
  List<Object> get props => [driverId, location];
}

class GetCurrentLocation extends RideEvent {
  const GetCurrentLocation();
}

class CalculateFare extends RideEvent {
  final LatLng pickup;
  final LatLng dropoff;

  const CalculateFare({
    required this.pickup,
    required this.dropoff,
  });

  @override
  List<Object> get props => [pickup, dropoff];
}

class WatchRideRequest extends RideEvent {
  final String rideId;

  const WatchRideRequest({required this.rideId});

  @override
  List<Object> get props => [rideId];
}

class WatchRideRequests extends RideEvent {
  const WatchRideRequests();
}

// Internal event for stream updates
class RideRequestsUpdated extends RideEvent {
  final List<RideRequest> rideRequests;

  const RideRequestsUpdated({required this.rideRequests});

  @override
  List<Object> get props => [rideRequests];
}