import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_sharing_app/features/ride/domain/entities/ride_request.dart';
import '../../domain/usecases/create_ride_request.dart' as usecase;
import '../../domain/usecases/accept_ride_request.dart' as usecase;
import '../../domain/usecases/update_ride_status.dart' as usecase;
import '../../domain/repositories/ride_repository.dart';
import 'ride_event.dart';
import 'ride_state.dart';

class RideBloc extends Bloc<RideEvent, RideState> {
  final usecase.CreateRideRequest createRideRequest;
  final usecase.AcceptRideRequest acceptRideRequest;
  final usecase.UpdateRideStatus updateRideStatus;
  final RideRepository rideRepository;
  
  StreamSubscription<List<RideRequest>>? _ridesStreamSubscription;

  RideBloc({
    required this.createRideRequest,
    required this.acceptRideRequest,
    required this.updateRideStatus,
    required this.rideRepository,
  }) : super(const RideInitial()) {
    on<LoadRideRequests>(_onLoadRideRequests);
    on<CreateRideRequest>(_onCreateRideRequest);
    on<AcceptRideRequest>(_onAcceptRideRequest);
    on<UpdateRideStatus>(_onUpdateRideStatus);
    on<UpdateDriverLocation>(_onUpdateDriverLocation);
    on<GetCurrentLocation>(_onGetCurrentLocation);
    on<CalculateFare>(_onCalculateFare);
    on<WatchRideRequest>(_onWatchRideRequest);
    on<WatchRideRequests>(_onWatchRideRequests);
    on<RideRequestsUpdated>(_onRideRequestsUpdated);
    on<RideErrorOccurred>(_onRideErrorOccurred);
  }

  // Add all the missing event handlers:

  Future<void> _onLoadRideRequests(
    LoadRideRequests event,
    Emitter<RideState> emit,
  ) async {
    emit(const RideLoading());
    try {
      final rideRequests = await rideRepository.getAvailableRideRequests();
      print('📋 Loaded ${rideRequests.length} available ride requests');
      emit(RideRequestsLoaded(rideRequests: rideRequests));
    } catch (e) {
      print('❌ Error loading ride requests: $e');
      emit(RideError(message: e.toString()));
    }
  }

  Future<void> _onCreateRideRequest(
    CreateRideRequest event,
    Emitter<RideState> emit,
  ) async {
    emit(const RideLoading());
    try {
      final rideId = await createRideRequest(
        passengerId: event.passengerId,
        pickupLocation: event.pickupLocation,
        dropoffLocation: event.dropoffLocation,
        pickupAddress: event.pickupAddress,
        dropoffAddress: event.dropoffAddress,
        passengerName: event.passengerName,
      );
      print('✅ Ride request created: $rideId');
      emit(RideRequestCreated(rideId: rideId));
    } catch (e) {
      print('❌ Error creating ride request: $e');
      emit(RideError(message: e.toString()));
    }
  }

  Future<void> _onAcceptRideRequest(
    AcceptRideRequest event,
    Emitter<RideState> emit,
  ) async {
    emit(const RideLoading());
    try {
      print('🚗 Attempting to accept ride ${event.rideId} by driver ${event.driverId}');
      
      await acceptRideRequest(
        rideId: event.rideId,
        driverId: event.driverId,
      );
      
      final rideRequest = await rideRepository.getRideRequest(event.rideId);
      if (rideRequest != null) {
        print('✅ Ride accepted successfully');
        emit(RideRequestAccepted(rideRequest: rideRequest));
      } else {
        throw Exception('Ride request not found after acceptance');
      }
    } catch (e) {
      print('❌ Error accepting ride: $e');
      
      String errorMessage = 'Failed to accept ride';
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('no longer available') || 
          errorStr.contains('not found')) {
        errorMessage = 'This ride is no longer available';
      } else if (errorStr.contains('already been accepted') || 
                 errorStr.contains('another driver')) {
        errorMessage = 'This ride has been accepted by another driver';
      }
      
      emit(RideError(message: errorMessage));
    }
  }

  Future<void> _onUpdateRideStatus(
    UpdateRideStatus event,
    Emitter<RideState> emit,
  ) async {
    emit(const RideLoading());
    try {
      await updateRideStatus(
        rideId: event.rideId,
        status: event.status,
      );
      emit(RideStatusUpdated(status: event.status));
    } catch (e) {
      emit(RideError(message: e.toString()));
    }
  }

  Future<void> _onUpdateDriverLocation(
    UpdateDriverLocation event,
    Emitter<RideState> emit,
  ) async {
    try {
      await rideRepository.updateDriverLocation(
        event.driverId,
        event.location,
      );
      // Don't emit state here to avoid interfering with other states
    } catch (e) {
      print('❌ Error updating driver location: $e');
    }
  }

  Future<void> _onGetCurrentLocation(
    GetCurrentLocation event,
    Emitter<RideState> emit,
  ) async {
    emit(const RideLoading());
    try {
      final location = await rideRepository.getCurrentLocation();
      emit(CurrentLocationLoaded(location: location));
    } catch (e) {
      emit(RideError(message: e.toString()));
    }
  }

  Future<void> _onCalculateFare(
    CalculateFare event,
    Emitter<RideState> emit,
  ) async {
    emit(const RideLoading());
    try {
      final fare = await rideRepository.calculateFare(
        event.pickup,
        event.dropoff,
      );
      emit(FareCalculated(fare: fare));
    } catch (e) {
      emit(RideError(message: e.toString()));
    }
  }

  Future<void> _onWatchRideRequest(
    WatchRideRequest event,
    Emitter<RideState> emit,
  ) async {
    try {
      await emit.forEach(
        rideRepository.watchRideRequest(event.rideId),
        onData: (rideRequest) => RideRequestWatched(rideRequest: rideRequest),
        onError: (error, stackTrace) {
          print('❌ Error watching ride request: $error');
          return RideError(message: error.toString());
        },
      );
    } catch (e) {
      emit(RideError(message: e.toString()));
    }
  }

  Future<void> _onWatchRideRequests(
    WatchRideRequests event,
    Emitter<RideState> emit,
  ) async {
    print('👀 [BLOC] WatchRideRequests event received');
    
    // Cancel any existing subscription first
    await _ridesStreamSubscription?.cancel();
    _ridesStreamSubscription = null;

    try {
      // Use manual stream subscription instead of emit.forEach
      _ridesStreamSubscription = rideRepository.watchRideRequests().listen(
        (rideRequests) {
          print('📡 [BLOC] Stream update: ${rideRequests.length} rides available');
          add(RideRequestsUpdated(rideRequests: rideRequests));
        },
        onError: (error) {
          print('❌ [BLOC] Error in ride requests stream: $error');
          add(RideErrorOccurred(error.toString()));
        },
        cancelOnError: false,
      );

      print('✅ [BLOC] Ride requests stream subscription started');
      
    } catch (e) {
      print('❌ [BLOC] Error setting up ride requests stream: $e');
      emit(RideError(message: e.toString()));
    }
  }

  void _onRideRequestsUpdated(
    RideRequestsUpdated event,
    Emitter<RideState> emit,
  ) {
    print('🔄 [BLOC] RideRequestsUpdated: ${event.rideRequests.length} rides');
    emit(RideRequestsLoaded(rideRequests: event.rideRequests));
  }

  void _onRideErrorOccurred(
    RideErrorOccurred event,
    Emitter<RideState> emit,
  ) {
    emit(RideError(message: event.message));
  }

  @override
  Future<void> close() {
    print('🔕 [BLOC] Closing bloc, cancelling subscriptions');
    _ridesStreamSubscription?.cancel();
    return super.close();
  }
}