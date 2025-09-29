import '../repositories/ride_repository.dart';
import '../../../../core/errors/failures.dart';

class UpdateRideStatus {
  final RideRepository repository;

  UpdateRideStatus(this.repository);

  Future<void> call({
    required String rideId,
    required String status,
  }) async {
    try {
      
      await repository.updateRideStatus(rideId, status);
    } catch (e) {
      throw ServerFailure('Failed to update ride status: ${e.toString()}');
    }
  }
}
