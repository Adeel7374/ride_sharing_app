import '../repositories/ride_repository.dart';
import '../../../../core/errors/failures.dart';

class AcceptRideRequest {
  final RideRepository repository;

  AcceptRideRequest(this.repository);

  Future<void> call({
    required String rideId,
    required String driverId,
  }) async {
    try {
      print('🚗 UseCase: Accepting ride $rideId for driver $driverId');
      
      // First check if ride still exists and is available
      final ride = await repository.getRideRequest(rideId);
      
      if (ride == null) {
        throw ServerFailure('Ride request not found');
      }
      
      if (ride.status != 'PENDING') {
        throw ServerFailure('Ride is no longer available (Status: ${ride.status})');
      }
      
      if (ride.driverId != null && ride.driverId != driverId) {
        throw ServerFailure('Ride has already been accepted by another driver');
      }
      
      // Accept the ride - this method now handles both acceptance and status update atomically
      await repository.acceptRideRequest(rideId, driverId);
      
      print('✅ UseCase: Ride accepted successfully');
      
    } catch (e) {
      print('❌ UseCase error: $e');
      if (e is ServerFailure) {
        rethrow;
      }
      throw ServerFailure('Failed to accept ride request: ${e.toString()}');
    }
  }
}