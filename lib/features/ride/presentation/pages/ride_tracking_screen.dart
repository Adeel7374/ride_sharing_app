// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import '../bloc/ride_bloc.dart';
// import '../bloc/ride_event.dart';
// import '../bloc/ride_state.dart';

// class RideTrackingScreen extends StatefulWidget {
//   final String rideId;
//   final String userRole;

//   const RideTrackingScreen({
//     Key? key,
//     required this.rideId,
//     required this.userRole,
//   }) : super(key: key);

//   @override
//   State<RideTrackingScreen> createState() => _RideTrackingScreenState();
// }

// class _RideTrackingScreenState extends State<RideTrackingScreen> {
//   GoogleMapController? _mapController;
//   Set<Marker> _markers = {};
//   Set<Polyline> _polylines = {};
//   String _currentStatus = 'REQUESTED';

//   @override
//   void initState() {
//     super.initState();
//     context.read<RideBloc>().add(WatchRideRequest(rideId: widget.rideId));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Ride Tracking'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//       ),
//       body: BlocListener<RideBloc, RideState>(
//         listener: (context, state) {
//           if (state is RideRequestWatched && state.rideRequest != null) {
//             _updateRideInfo(state.rideRequest!);
//           } else if (state is RideStatusUpdated) {
//             setState(() {
//               _currentStatus = state.status;
//             });
//             _showStatusUpdate(state.status);
//           }
//         },
//         child: BlocBuilder<RideBloc, RideState>(
//           builder: (context, state) {
//             if (state is RideLoading) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             return Column(
//               children: [
//                 Expanded(
//                   child: GoogleMap(
//                     onMapCreated: (GoogleMapController controller) {
//                       _mapController = controller;
//                     },
//                     initialCameraPosition: const CameraPosition(
//                       target: LatLng(0, 0),
//                       zoom: 15.0,
//                     ),
//                     markers: _markers,
//                     polylines: _polylines,
//                     myLocationEnabled: true,
//                     myLocationButtonEnabled: true,
//                   ),
//                 ),
//                 _buildRideInfo(state),
//                 if (widget.userRole == 'DRIVER') _buildDriverControls(),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildRideInfo(RideState state) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.3),
//             spreadRadius: 1,
//             blurRadius: 5,
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Ride Status: $_currentStatus',
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 10),
//           if (state is RideRequestWatched && state.rideRequest != null)
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Ride ID: ${state.rideRequest!.id.substring(0, 8)}'),
//                 Text('Passenger: ${state.rideRequest!.passengerName ?? 'Unknown'}'),
//                 if (state.rideRequest!.driverName != null)
//                   Text('Driver: ${state.rideRequest!.driverName}'),
//                 if (state.rideRequest!.fare != null)
//                   Text('Fare: \$${state.rideRequest!.fare!.toStringAsFixed(2)}'),
//               ],
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDriverControls() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           if (_currentStatus == 'ACCEPTED')
//             ElevatedButton(
//               onPressed: () => _updateRideStatus('ARRIVED'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text('Mark as Arrived'),
//             ),
//           if (_currentStatus == 'ARRIVED')
//             ElevatedButton(
//               onPressed: () => _updateRideStatus('STARTED'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text('Start Ride'),
//             ),
//           if (_currentStatus == 'STARTED')
//             ElevatedButton(
//               onPressed: () => _updateRideStatus('FINISHED'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text('Finish Ride'),
//             ),
//         ],
//       ),
//     );
//   }

//   void _updateRideInfo(dynamic rideRequest) {
//     setState(() {
//       _currentStatus = rideRequest.status;
//     });

//     // Add markers for pickup and dropoff locations
//     _markers.clear();
//     _markers.add(Marker(
//       markerId: const MarkerId('pickup'),
//       position: rideRequest.pickupLocation,
//       infoWindow: const InfoWindow(title: 'Pickup Location'),
//       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//     ));
//     _markers.add(Marker(
//       markerId: const MarkerId('dropoff'),
//       position: rideRequest.dropoffLocation,
//       infoWindow: const InfoWindow(title: 'Dropoff Location'),
//       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//     ));

//     // Draw route
//     _polylines.clear();
//     _polylines.add(Polyline(
//       polylineId: const PolylineId('route'),
//       points: [rideRequest.pickupLocation, rideRequest.dropoffLocation],
//       color: Colors.blue,
//       width: 5,
//     ));

//     // Update camera position
//     if (_mapController != null) {
//       _mapController!.animateCamera(
//         CameraUpdate.newLatLngBounds(
//           LatLngBounds(
//             southwest: LatLng(
//               rideRequest.pickupLocation.latitude < rideRequest.dropoffLocation.latitude
//                   ? rideRequest.pickupLocation.latitude
//                   : rideRequest.dropoffLocation.latitude,
//               rideRequest.pickupLocation.longitude < rideRequest.dropoffLocation.longitude
//                   ? rideRequest.pickupLocation.longitude
//                   : rideRequest.dropoffLocation.longitude,
//             ),
//             northeast: LatLng(
//               rideRequest.pickupLocation.latitude > rideRequest.dropoffLocation.latitude
//                   ? rideRequest.pickupLocation.latitude
//                   : rideRequest.dropoffLocation.latitude,
//               rideRequest.pickupLocation.longitude > rideRequest.dropoffLocation.longitude
//                   ? rideRequest.pickupLocation.longitude
//                   : rideRequest.dropoffLocation.longitude,
//             ),
//           ),
//           100.0,
//         ),
//       );
//     }
//   }

//   void _updateRideStatus(String status) {
//     context.read<RideBloc>().add(UpdateRideStatus(
//       rideId: widget.rideId,
//       status: status,
//     ));
//   }

//   void _showStatusUpdate(String status) {
//     String message;
//     switch (status) {
//       case 'ACCEPTED':
//         message = 'Ride request accepted!';
//         break;
//       case 'ARRIVED':
//         message = 'Driver has arrived!';
//         break;
//       case 'STARTED':
//         message = 'Ride has started!';
//         break;
//       case 'FINISHED':
//         message = 'Ride completed!';
//         break;
//       default:
//         message = 'Status updated to $status';
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_sharing_app/features/ride/domain/entities/ride_request.dart';
import '../bloc/ride_bloc.dart';
import '../bloc/ride_event.dart';
import '../bloc/ride_state.dart';

class RideTrackingScreen extends StatefulWidget {
  final String rideId;
  final String userRole;

  const RideTrackingScreen({
    Key? key,
    required this.rideId,
    required this.userRole,
  }) : super(key: key);

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String _currentStatus = 'REQUESTED';
  LatLng? _driverLocation;

  @override
  void initState() {
    super.initState();
    print('🚗 [RideTrackingScreen] initState called, triggering WatchRideRequest');
    context.read<RideBloc>().add(WatchRideRequest(rideId: widget.rideId));
    if (widget.userRole == 'DRIVER') {
      // Periodically update driver location
      context.read<RideBloc>().add(GetCurrentLocation());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Tracking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<RideBloc, RideState>(
        listener: (context, state) {
          if (state is RideRequestWatched && state.rideRequest != null) {
            _updateRideInfo(state.rideRequest!);
          } else if (state is RideRequestWatched && state.rideRequest == null) {
            _showSnackBar('Error: Ride not found');
            Navigator.pop(context);
          } else if (state is RideStatusUpdated) {
            setState(() {
              _currentStatus = state.status;
            });
            _showStatusUpdate(state.status);
            if (state.status == 'FINISHED') {
              Navigator.pop(context); // Return to MapScreen after ride completion
            }
          } else if (state is DriverLocationUpdated && widget.userRole == 'PASSENGER') {
            _driverLocation = state.location;
            _updateDriverMarker(state.location);
          } else if (state is CurrentLocationLoaded && widget.userRole == 'DRIVER') {
            _driverLocation = state.location;
            _updateDriverMarker(state.location);
            context.read<RideBloc>().add(UpdateDriverLocation(
              driverId: widget.rideId, // Use rideId as driverId for simplicity
              location: state.location,
            ));
          }
        },
        child: BlocBuilder<RideBloc, RideState>(
          builder: (context, state) {
            if (state is RideLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(0, 0),
                      zoom: 15.0,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
                _buildRideInfo(state),
                if (widget.userRole == 'DRIVER') _buildDriverControls(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRideInfo(RideState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
            'Ride Status: $_currentStatus',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (state is RideRequestWatched && state.rideRequest != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ride ID: ${state.rideRequest!.id.substring(0, 8)}'),
                Text('Passenger: ${state.rideRequest!.passengerName ?? 'Unknown'}'),
                if (state.rideRequest!.driverName != null)
                  Text('Driver: ${state.rideRequest!.driverName}'),
                if (state.rideRequest!.fare != null)
                  Text('Fare: \$${state.rideRequest!.fare!.toStringAsFixed(2)}'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDriverControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_currentStatus == 'ACCEPTED')
            ElevatedButton(
              onPressed: () => _updateRideStatus('ARRIVED'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark as Arrived'),
            ),
          if (_currentStatus == 'ARRIVED')
            ElevatedButton(
              onPressed: () => _updateRideStatus('STARTED'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Ride'),
            ),
          if (_currentStatus == 'STARTED')
            ElevatedButton(
              onPressed: () => _updateRideStatus('FINISHED'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Finish Ride'),
            ),
        ],
      ),
    );
  }

  void _updateRideInfo(RideRequest rideRequest) {
    setState(() {
      _currentStatus = rideRequest.status;
    });

    _markers.clear();
    _markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: rideRequest.pickupLocation,
      infoWindow: const InfoWindow(title: 'Pickup Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ));
    _markers.add(Marker(
      markerId: const MarkerId('dropoff'),
      position: rideRequest.dropoffLocation,
      infoWindow: const InfoWindow(title: 'Dropoff Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));

    _polylines.clear();
    if (_driverLocation != null) {
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: [
          _driverLocation!,
          rideRequest.pickupLocation,
          rideRequest.dropoffLocation,
        ],
        color: Colors.blue,
        width: 5,
      ));
    } else {
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: [rideRequest.pickupLocation, rideRequest.dropoffLocation],
        color: Colors.blue,
        width: 5,
      ));
    }

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              rideRequest.pickupLocation.latitude < rideRequest.dropoffLocation.latitude
                  ? rideRequest.pickupLocation.latitude
                  : rideRequest.dropoffLocation.latitude,
              rideRequest.pickupLocation.longitude < rideRequest.dropoffLocation.longitude
                  ? rideRequest.pickupLocation.longitude
                  : rideRequest.dropoffLocation.longitude,
            ),
            northeast: LatLng(
              rideRequest.pickupLocation.latitude > rideRequest.dropoffLocation.latitude
                  ? rideRequest.pickupLocation.latitude
                  : rideRequest.dropoffLocation.latitude,
              rideRequest.pickupLocation.longitude > rideRequest.dropoffLocation.longitude
                  ? rideRequest.pickupLocation.longitude
                  : rideRequest.dropoffLocation.longitude,
            ),
          ),
          100.0,
        ),
      );
    }
  }

  void _updateDriverMarker(LatLng location) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'driver');
      _markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: location,
        infoWindow: const InfoWindow(title: 'Driver Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    });
  }

  void _updateRideStatus(String status) {
    context.read<RideBloc>().add(UpdateRideStatus(
      rideId: widget.rideId,
      status: status,
    ));
  }

  void _showStatusUpdate(String status) {
    String message;
    switch (status) {
      case 'ACCEPTED':
        message = 'Ride request accepted!';
        break;
      case 'ARRIVED':
        message = 'Driver has arrived!';
        break;
      case 'STARTED':
        message = 'Ride has started!';
        break;
      case 'FINISHED':
        message = 'Ride completed!';
        break;
      default:
        message = 'Status updated to $status';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}