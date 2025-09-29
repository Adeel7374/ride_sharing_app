import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/ride_request.dart';
import '../bloc/ride_bloc.dart';
import '../bloc/ride_event.dart';
import '../bloc/ride_state.dart';
import 'ride_tracking_screen.dart';

class MapScreen extends StatefulWidget {
  final String userRole;
  final String userId;

  const MapScreen({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  
  // Track accepted rides to prevent duplicate navigation
  final Set<String> _acceptedRides = {};
  
  // Debug mode to show all rides
  bool _showAllRides = false;

  @override
  void initState() {
    super.initState();
    print('📍 [MAP] initState called');
    context.read<RideBloc>().add(const GetCurrentLocation());
    if (widget.userRole == 'DRIVER') {
      print('👀 [MAP] Starting to watch ride requests in initState');
      context.read<RideBloc>().add(const WatchRideRequests());
    }
  }

  @override
  void dispose() {
    print('🗑️ [MAP] Disposing MapScreen');
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userRole} Map'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<RideBloc, RideState>(
        listener: (context, state) {
          print('🎧 [LISTENER] State changed: ${state.runtimeType}');
          if (state is CurrentLocationLoaded) {
            _currentLocation = state.location;
            _updateMapCamera();
          } else if (state is RideRequestCreated) {
            _showSnackBar('Ride request created successfully!');
            _resetSelections();
            if (widget.userRole == 'PASSENGER') {
              // Navigate to RideTrackingScreen for passengers
              // Pass the existing RideBloc to the new screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: context.read<RideBloc>(),
                    child: RideTrackingScreen(
                      rideId: state.rideId,
                      userRole: widget.userRole,
                    ),
                  ),
                ),
              );
            }
          } else if (state is RideRequestAccepted) {
            // Prevent duplicate navigation
            if (!_acceptedRides.contains(state.rideRequest.id)) {
              _acceptedRides.add(state.rideRequest.id);
              _showSnackBar('Ride request accepted!');
              _updateDriverLocation(state.rideRequest);
              if (widget.userRole == 'DRIVER') {
                // Navigate to RideTrackingScreen for drivers
                // Pass the existing RideBloc to the new screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<RideBloc>(),
                      child: RideTrackingScreen(
                        rideId: state.rideRequest.id,
                        userRole: widget.userRole,
                      ),
                    ),
                  ),
                ).then((_) {
                  // Remove from set when returning from tracking screen
                  _acceptedRides.remove(state.rideRequest.id);
                });
              }
            }
          } else if (state is RideError) {
            _showSnackBar('Error: ${state.message}');
          } else if (state is RideRequestsLoaded) {
            print('📦 [LISTENER] Received ${state.rideRequests.length} rides');
          }
        },
        child: BlocBuilder<RideBloc, RideState>(
          buildWhen: (previous, current) {
            if (widget.userRole == 'PASSENGER') {
              return current is RideLoading ||
                     current is CurrentLocationLoaded ||
                     current is RideError ||
                     current is RideRequestCreated;
            }
            return current is RideLoading ||
                   current is RideRequestsLoaded ||
                   current is RideError ||
                   current is RideRequestCreated;
          },
          builder: (context, state) {
            print('🏗️ [BUILDER] Building with state: ${state.runtimeType}');
            if (state is RideLoading && widget.userRole != 'PASSENGER') {
              return const Center(child: CircularProgressIndicator());
            }

            return Stack(
              children: [
                GoogleMap(
                  key: const ValueKey('google_map'),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    print('🗺️ [MAP] Map controller created');
                    if (_currentLocation != null) {
                      _updateMapCamera();
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation ?? const LatLng(0, 0),
                    zoom: 15.0,
                  ),
                  markers: markers,
                  polylines: polylines,
                  onTap: widget.userRole == 'PASSENGER' ? _onMapTapped : null,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
                if (widget.userRole == 'PASSENGER') _buildPassengerControls(),
                if (widget.userRole == 'DRIVER') _buildDriverControls(state),
              ],
            );
          },
        ),
      ),
    );
  }

  void _resetSelections() {
    setState(() {
      _pickupLocation = null;
      _dropoffLocation = null;
      markers.clear();
      polylines.clear();
    });
  }

  Widget _buildPassengerControls() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Column(
        children: [
          if (_pickupLocation != null && _dropoffLocation != null)
            ElevatedButton(
              onPressed: _createRideRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('Request Ride'),
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup: ${_pickupLocation != null ? "Selected" : "Tap to select"}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dropoff: ${_dropoffLocation != null ? "Selected" : "Tap to select"}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<RideRequest> _getCurrentRideRequests(RideState state) {
    final bloc = context.read<RideBloc>();
    if (bloc.state is RideRequestsLoaded) {
      return (bloc.state as RideRequestsLoaded).rideRequests;
    }
    return [];
  }

  Widget _buildDriverControls(RideState state) {
    List<RideRequest> rideRequests = _getCurrentRideRequests(state);
    
    // Debug: Print all rides and their statuses
    print('🔍 [DEBUG] Total rides: ${rideRequests.length}');
    for (var ride in rideRequests) {
      print('🔍 [DEBUG] Ride ${ride.id}: status="${ride.status}", driverId="${ride.driverId}"');
    }
    
    // Filter rides based on debug mode
    final pendingRides = _showAllRides 
        ? rideRequests 
        : rideRequests.where((ride) {
            final status = ride.status?.toUpperCase() ?? '';
            return status == 'REQUESTED' || status == 'PENDING' || 
                   ride.driverId == null || ride.driverId!.isEmpty;
          }).toList();
    
    print('🔍 [DEBUG] Pending rides after filter: ${pendingRides.length}');

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4, // Max 40% of screen height
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Debug Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Ride Requests',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                      if (pendingRides.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${pendingRides.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Debug Toggle
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Show All Rides (Debug)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      Switch(
                        value: _showAllRides,
                        onChanged: (value) {
                          setState(() {
                            _showAllRides = value;
                          });
                        },
                        activeColor: Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Scrollable List
            Flexible(
              child: pendingRides.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: pendingRides.length,
                      itemBuilder: (context, index) {
                        final ride = pendingRides[index];
                        return _buildRideCard(ride);
                      },
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_taxi,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state is RideLoading
                                ? 'Loading rides...'
                                : 'No available rides',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                          if (rideRequests.isNotEmpty && pendingRides.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '(${rideRequests.length} rides filtered out)',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(RideRequest ride) {
    return Card(
      key: ValueKey(ride.id),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, size: 18, color: Colors.blue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ride.passengerName ?? 'Unknown Passenger',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ride #${_formatRideId(ride.id)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ride.status,
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ride.pickupAddress ?? 'Pickup Location',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.flag, size: 16, color: Colors.red.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ride.dropoffAddress ?? 'Dropoff Location',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _acceptRideRequest(ride.id),
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('Accept Ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRideId(String? rideId) {
    if (rideId == null || rideId.isEmpty) {
      return 'Unknown';
    }
    return rideId.length > 8 ? rideId.substring(0, 8) : rideId;
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      if (_pickupLocation == null) {
        _pickupLocation = location;
        _addMarker(location, 'Pickup', BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen));
      } else if (_dropoffLocation == null) {
        _dropoffLocation = location;
        _addMarker(location, 'Dropoff', BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed));
        _drawRoute();
      } else {
        _pickupLocation = location;
        _dropoffLocation = null;
        markers.clear();
        polylines.clear();
        _addMarker(location, 'Pickup', BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen));
      }
    });
  }

  void _addMarker(LatLng location, String title, BitmapDescriptor icon) {
    setState(() {
      markers.add(Marker(
        markerId: MarkerId(title),
        position: location,
        infoWindow: InfoWindow(title: title),
        icon: icon,
      ));
    });
  }

  void _drawRoute() {
    if (_pickupLocation != null && _dropoffLocation != null) {
      setState(() {
        polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: [_pickupLocation!, _dropoffLocation!],
          color: Colors.blue,
          width: 5,
        ));
      });
    }
  }

  void _createRideRequest() {
    if (_pickupLocation != null && _dropoffLocation != null) {
      context.read<RideBloc>().add(CreateRideRequest(
        passengerId: widget.userId,
        pickupLocation: _pickupLocation!,
        dropoffLocation: _dropoffLocation!,
        pickupAddress: 'Pickup Location',
        dropoffAddress: 'Dropoff Location',
        passengerName: 'Passenger',
      ));
    }
  }

  void _acceptRideRequest(String rideId) {
    print('🚗 [ACCEPT] Accepting ride: $rideId');
    context.read<RideBloc>().add(AcceptRideRequest(
      rideId: rideId,
      driverId: widget.userId,
    ));
  }

  void _updateMapCamera() {
    if (_mapController != null && _currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_currentLocation!),
      );
    }
  }

  void _updateDriverLocation(RideRequest rideRequest) {
    if (_currentLocation != null && widget.userRole == 'DRIVER') {
      markers.removeWhere((marker) => marker.markerId.value == 'driver');
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _currentLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Driver Location'),
      ));

      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          rideRequest.pickupLocation.latitude,
          rideRequest.pickupLocation.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ));

      markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(
          rideRequest.dropoffLocation.latitude,
          rideRequest.dropoffLocation.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Dropoff Location'),
      ));

      polylines.clear();
      polylines.add(Polyline(
        polylineId: const PolylineId('driverRoute'),
        points: [
          _currentLocation!,
          LatLng(
            rideRequest.pickupLocation.latitude,
            rideRequest.pickupLocation.longitude,
          ),
          LatLng(
            rideRequest.dropoffLocation.latitude,
            rideRequest.dropoffLocation.longitude,
          ),
        ],
        color: Colors.blue,
        width: 5,
      ));

      setState(() {});
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
