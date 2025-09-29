import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/ride_request.dart';

abstract class RideState extends Equatable {
  const RideState();

  @override
  List<Object?> get props => [];
}

class RideInitial extends RideState {
  const RideInitial();
}

class RideLoading extends RideState {
  const RideLoading();
}

class RideRequestsLoaded extends RideState {
  final List<RideRequest> rideRequests;

  const RideRequestsLoaded({required this.rideRequests});

  @override
  List<Object> get props => [rideRequests];
}

class RideRequestCreated extends RideState {
  final String rideId;

  const RideRequestCreated({required this.rideId});

  @override
  List<Object> get props => [rideId];
}

class RideRequestAccepted extends RideState {
  final RideRequest rideRequest;

  const RideRequestAccepted({required this.rideRequest});

  @override
  List<Object> get props => [rideRequest];
}

class RideStatusUpdated extends RideState {
  final String status;

  const RideStatusUpdated({required this.status});

  @override
  List<Object> get props => [status];
}

class DriverLocationUpdated extends RideState {
  final LatLng location;

  const DriverLocationUpdated({required this.location});

  @override
  List<Object> get props => [location];
}

class CurrentLocationLoaded extends RideState {
  final LatLng location;

  const CurrentLocationLoaded({required this.location});

  @override
  List<Object> get props => [location];
}

class FareCalculated extends RideState {
  final double fare;

  const FareCalculated({required this.fare});

  @override
  List<Object> get props => [fare];
}

class RideRequestWatched extends RideState {
  final RideRequest? rideRequest;

  const RideRequestWatched({this.rideRequest});

  @override
  List<Object?> get props => [rideRequest];
}

class RideError extends RideState {
  final String message;

  const RideError({required this.message});

  @override
  List<Object> get props => [message];
}
