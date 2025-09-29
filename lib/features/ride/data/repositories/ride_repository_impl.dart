import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/ride_request.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/ride_repository.dart';
import '../datasources/ride_remote_datasource.dart';
import '../../../../core/errors/failures.dart';

class RideRepositoryImpl implements RideRepository {
  final RideRemoteDataSource remoteDataSource;

  RideRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> createRideRequest(RideRequest rideRequest) async {
    try {
      
      return await remoteDataSource.createRideRequest(rideRequest);
    } catch (e) {
      throw ServerFailure('Failed to create ride request: ${e.toString()}');
    }
  }

  @override
  Future<void> updateRideRequest(String rideId, Map<String, dynamic> updates) async {
    try {
      await remoteDataSource.updateRideRequest(rideId, updates);
    } catch (e) {
      throw ServerFailure('Failed to update ride request: ${e.toString()}');
    }
  }

  @override
  Future<RideRequest?> getRideRequest(String rideId) async {
    try {
      return await remoteDataSource.getRideRequest(rideId);
    } catch (e) {
      throw ServerFailure('Failed to get ride request: ${e.toString()}');
    }
  }

  @override
  Future<List<RideRequest>> getAvailableRideRequests() async {
    try {
      return await remoteDataSource.getAvailableRideRequests();
    } catch (e) {
      throw ServerFailure('Failed to get available ride requests: ${e.toString()}');
    }
  }

  @override
  Future<List<RideRequest>> getUserRideRequests(String userId) async {
    try {
      return await remoteDataSource.getUserRideRequests(userId);
    } catch (e) {
      throw ServerFailure('Failed to get user ride requests: ${e.toString()}');
    }
  }

  @override
  Stream<List<RideRequest>> watchRideRequests() {
    try {
      return remoteDataSource.watchRideRequests();
    } catch (e) {
      throw ServerFailure('Failed to watch ride requests: ${e.toString()}');
    }
  }

  @override
  Stream<RideRequest?> watchRideRequest(String rideId) {
    try {
      return remoteDataSource.watchRideRequest(rideId);
    } catch (e) {
      throw ServerFailure('Failed to watch ride request: ${e.toString()}');
    }
  }

  @override
  Future<void> acceptRideRequest(String rideId, String driverId) async {
    try {
      await remoteDataSource.acceptRideRequest(rideId, driverId);
    } catch (e) {
      throw ServerFailure('Failed to accept ride request: ${e.toString()}');
    }
  }

  @override
  Future<void> updateDriverLocation(String driverId, LatLng location) async {
    try {
      await remoteDataSource.updateDriverLocation(driverId, location);
    } catch (e) {
      throw ServerFailure('Failed to update driver location: ${e.toString()}');
    }
  }

  @override
  Future<void> updateRideStatus(String rideId, String status) async {
    try {
      await remoteDataSource.updateRideStatus(rideId, status);
    } catch (e) {
      throw ServerFailure('Failed to update ride status: ${e.toString()}');
    }
  }

  @override
  Future<LatLng> getCurrentLocation() async {
    try {
      return await remoteDataSource.getCurrentLocation();
    } catch (e) {
      throw LocationFailure('Failed to get current location: ${e.toString()}');
    }
  }

  @override
  Future<String> getAddressFromLatLng(LatLng latLng) async {
    try {
      return await remoteDataSource.getAddressFromLatLng(latLng);
    } catch (e) {
      throw LocationFailure('Failed to get address: ${e.toString()}');
    }
  }

  @override
  Future<List<LatLng>> getRoutePoints(LatLng origin, LatLng destination) async {
    try {
      return await remoteDataSource.getRoutePoints(origin, destination);
    } catch (e) {
      throw LocationFailure('Failed to get route points: ${e.toString()}');
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      return await remoteDataSource.getCurrentUser();
    } catch (e) {
      throw AuthFailure('Failed to get current user: ${e.toString()}');
    }
  }

  @override
  Future<void> updateUserLocation(String userId, LatLng location) async {
    try {
      await remoteDataSource.updateUserLocation(userId, location);
    } catch (e) {
      throw ServerFailure('Failed to update user location: ${e.toString()}');
    }
  }

  @override
  Future<void> updateUserStatus(String userId, bool isOnline) async {
    try {
      await remoteDataSource.updateUserStatus(userId, isOnline);
    } catch (e) {
      throw ServerFailure('Failed to update user status: ${e.toString()}');
    }
  }

  @override
  Future<double> calculateFare(LatLng pickup, LatLng dropoff) async {
    try {
      return await remoteDataSource.calculateFare(pickup, dropoff);
    } catch (e) {
      throw ServerFailure('Failed to calculate fare: ${e.toString()}');
    }
  }
}
