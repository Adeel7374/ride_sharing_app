import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../entities/ride_request.dart';
import '../entities/user.dart';

abstract class RideRepository {
  // Ride Request Operations
  Future<String> createRideRequest(RideRequest rideRequest);
  Future<void> updateRideRequest(String rideId, Map<String, dynamic> updates);
  Future<RideRequest?> getRideRequest(String rideId);
  Future<List<RideRequest>> getAvailableRideRequests();
  Future<List<RideRequest>> getUserRideRequests(String userId);
  Stream<List<RideRequest>> watchRideRequests();
  Stream<RideRequest?> watchRideRequest(String rideId);
  
  // Driver Operations
  Future<void> acceptRideRequest(String rideId, String driverId);
  Future<void> updateDriverLocation(String driverId, LatLng location);
  Future<void> updateRideStatus(String rideId, String status);
  
  // Location Operations
  Future<LatLng> getCurrentLocation();
  Future<String> getAddressFromLatLng(LatLng latLng);
  Future<List<LatLng>> getRoutePoints(LatLng origin, LatLng destination);
  
  // User Operations
  Future<User?> getCurrentUser();
  Future<void> updateUserLocation(String userId, LatLng location);
  Future<void> updateUserStatus(String userId, bool isOnline);
  
  // Fare Calculation
  Future<double> calculateFare(LatLng pickup, LatLng dropoff);
}
