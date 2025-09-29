import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../domain/entities/ride_request.dart';
import '../../domain/entities/user.dart';
import '../models/ride_request_model.dart';
import '../../../../core/constants/app_constants.dart';

abstract class RideRemoteDataSource {
  Future<String> createRideRequest(RideRequest rideRequest);
  Future<void> updateRideRequest(String rideId, Map<String, dynamic> updates);
  Future<RideRequest?> getRideRequest(String rideId);
  Future<List<RideRequest>> getAvailableRideRequests();
  Future<List<RideRequest>> getUserRideRequests(String userId);
  Stream<List<RideRequest>> watchRideRequests();
  Stream<RideRequest?> watchRideRequest(String rideId);

  Future<void> acceptRideRequest(String rideId, String driverId);
  Future<void> updateDriverLocation(String driverId, LatLng location);
  Future<void> updateRideStatus(String rideId, String status);

  Future<LatLng> getCurrentLocation();
  Future<String> getAddressFromLatLng(LatLng latLng);
  Future<List<LatLng>> getRoutePoints(LatLng origin, LatLng destination);

  Future<User?> getCurrentUser();
  Future<void> updateUserLocation(String userId, LatLng location);
  Future<void> updateUserStatus(String userId, bool isOnline);

  Future<double> calculateFare(LatLng pickup, LatLng dropoff);
}

class RideRemoteDataSourceImpl implements RideRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseDatabase realtimeDatabase;

  RideRemoteDataSourceImpl({
    required this.firestore,
    required this.realtimeDatabase,
  });

  @override
  Future<String> createRideRequest(RideRequest rideRequest) async {
    try {
      print('🚗 Creating ride request with status: ${rideRequest.status}');

      // Use String dates to match your model's expectations
      final rideData = {
        'passengerId': rideRequest.passengerId,
        'driverId': rideRequest.driverId,
        'pickupLocation': {
          'latitude': rideRequest.pickupLocation.latitude,
          'longitude': rideRequest.pickupLocation.longitude,
        },
        'dropoffLocation': {
          'latitude': rideRequest.dropoffLocation.latitude,
          'longitude': rideRequest.dropoffLocation.longitude,
        },
        // 'status': rideRequest.status,
        'status':'PENDING',
        'createdAt': DateTime.now().toIso8601String(), // Use String format
        'updatedAt': null,
        'fare': rideRequest.fare,
        'pickupAddress': rideRequest.pickupAddress,
        'dropoffAddress': rideRequest.dropoffAddress,
        'passengerName': rideRequest.passengerName,
        'driverName': rideRequest.driverName,
      };

      print('📦 Ride data to save: $rideData');

      final docRef = await firestore.collection('ride_requests').add(rideData);

      // Update with the generated ID
      await docRef.update({
        'id': docRef.id,
      });

      print('✅ Ride request created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Failed to create ride request: $e');
      throw Exception('Failed to create ride request: $e');
    }
  }

  @override
  Future<void> updateRideRequest(
      String rideId, Map<String, dynamic> updates) async {
    try {
      await firestore
          .collection(AppConstants.rideRequestsCollection)
          .doc(rideId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update ride request: $e');
    }
  }

  @override
  Future<RideRequest?> getRideRequest(String rideId) async {
    try {
      final doc = await firestore
          .collection(AppConstants.rideRequestsCollection)
          .doc(rideId)
          .get();

      if (doc.exists) {
        return RideRequestModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get ride request: $e');
    }
  }

  @override
  Future<List<RideRequest>> getAvailableRideRequests() async {
    try {
      print('📥 Fetching available ride requests...');

      final snapshot = await firestore
          .collection('ride_requests')
          .where('status', isEqualTo: 'PENDING')
          .orderBy('createdAt', descending: true)
          .get();

      print('📦 Received ${snapshot.docs.length} documents from Firestore');

      final rides = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();

              if (!data.containsKey('passengerId') ||
                  !data.containsKey('pickupLocation') ||
                  !data.containsKey('dropoffLocation')) {
                print('⚠️ Skipping incomplete ride: ${doc.id}');
                return null;
              }

              final pickupData =
                  data['pickupLocation'] as Map<String, dynamic>?;
              final dropoffData =
                  data['dropoffLocation'] as Map<String, dynamic>?;

              if (pickupData == null || dropoffData == null) {
                return null;
              }

              // FIX: Handle createdAt field (could be String or Timestamp)
              DateTime createdAt;
              final createdAtValue = data['createdAt'];
              if (createdAtValue is Timestamp) {
                createdAt = createdAtValue.toDate();
              } else if (createdAtValue is String) {
                createdAt = DateTime.parse(createdAtValue);
              } else {
                createdAt = DateTime.now();
                print('⚠️ Using current time for createdAt in ${doc.id}');
              }

              // FIX: Handle updatedAt field (could be String, Timestamp, or null)
              DateTime? updatedAt;
              final updatedAtValue = data['updatedAt'];
              if (updatedAtValue is Timestamp) {
                updatedAt = updatedAtValue.toDate();
              } else if (updatedAtValue is String) {
                updatedAt = DateTime.parse(updatedAtValue);
              }
              // If it's null, leave it as null

              return RideRequestModel(
                id: doc.id,
                passengerId: data['passengerId'] as String,
                driverId: data['driverId'] as String?,
                pickupLocation: LatLng(
                  (pickupData['latitude'] as num).toDouble(),
                  (pickupData['longitude'] as num).toDouble(),
                ),
                dropoffLocation: LatLng(
                  (dropoffData['latitude'] as num).toDouble(),
                  (dropoffData['longitude'] as num).toDouble(),
                ),
                status: data['status'] as String,
                createdAt: createdAt,
                updatedAt: updatedAt,
                fare: (data['fare'] as num?)?.toDouble(),
                pickupAddress: data['pickupAddress'] as String?,
                dropoffAddress: data['dropoffAddress'] as String?,
                passengerName: data['passengerName'] as String?,
                driverName: data['driverName'] as String?,
              );
            } catch (e) {
              print('❌ Error parsing ride ${doc.id}: $e');
              return null;
            }
          })
          .whereType<RideRequestModel>()
          .toList();

      print('✅ Returning ${rides.length} valid ride requests');
      return rides;
    } catch (e) {
      print('❌ Error fetching ride requests: $e');
      rethrow;
    }
  }

  @override
  Future<List<RideRequest>> getUserRideRequests(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection(AppConstants.rideRequestsCollection)
          .where('passengerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RideRequestModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user ride requests: $e');
    }
  }

  @override
  Stream<List<RideRequest>> watchRideRequests() {
    print('👀 Starting to watch ride requests stream');

    return firestore
        .collection('ride_requests')
        .where('status', isEqualTo: 'PENDING')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('📡 Firestore raw response:');
      print('   - Documents found: ${snapshot.docs.length}');

      final rides = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              print('🔄 Processing document: ${doc.id}');
              print('   Status: ${data['status']}'); // Add this for debugging

              // Use the corrected model parsing
              return RideRequestModel.fromJson(data);
            } catch (e) {
              print('❌ Error parsing ride ${doc.id}: $e');
              print('Stack trace: ${StackTrace.current}');
              return null;
            }
          })
          .whereType<RideRequestModel>()
          .toList();

      print('🎯 Final result: ${rides.length} valid rides');
      print('===========================================');
      return rides;
    });
  }

  @override
  Stream<RideRequest?> watchRideRequest(String rideId) {
    return firestore
        .collection(AppConstants.rideRequestsCollection)
        .doc(rideId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return RideRequestModel.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  @override
  Future<void> acceptRideRequest(String rideId, String driverId) async {
    try {
      final rideRef = firestore.collection('ride_requests').doc(rideId);

      // Use Firestore transaction to ensure atomicity
      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(rideRef);

        if (!snapshot.exists) {
          throw Exception('Ride request not found');
        }

        final data = snapshot.data();
        final currentStatus = data?['status'] as String?;
        final currentDriverId = data?['driverId'] as String?;

        // Check if ride is still available
        if (currentStatus != 'PENDING') {
          throw Exception(
              'Ride is no longer available. Current status: $currentStatus');
        }

        // Check if another driver already accepted
        if (currentDriverId != null && currentDriverId != driverId) {
          throw Exception('Ride has already been accepted by another driver');
        }

        // Update the ride with driver info and status
        transaction.update(rideRef, {
          'driverId': driverId,
          'status': 'ACCEPTED',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Also update in Realtime Database for live updates
      await realtimeDatabase.ref('ride_requests/$rideId').update({
        'driverId': driverId,
        'status': 'ACCEPTED',
        'updatedAt': ServerValue.timestamp,
      });

      print('✅ Ride $rideId accepted successfully by driver $driverId');
    } catch (e) {
      print('❌ Error accepting ride: $e');
      rethrow;
    }
  }
  
@override
  Future<void> updateDriverLocation(String driverId, LatLng location) async {
    await realtimeDatabase.ref('driver_locations/$driverId').set({
      'latitude': location.latitude,
      'longitude': location.longitude,
      'updatedAt': ServerValue.timestamp,
    });
  }
  // @override
  // Future<void> updateDriverLocation(String driverId, LatLng location) async {
  //   try {
  //     await realtimeDatabase
  //         .ref()
  //         .child('driver_locations')
  //         .child(driverId)
  //         .set({
  //       'latitude': location.latitude,
  //       'longitude': location.longitude,
  //       'timestamp': DateTime.now().millisecondsSinceEpoch,
  //     });
  //   } catch (e) {
  //     throw Exception('Failed to update driver location: $e');
  //   }
  // }

  @override
  Future<void> updateRideStatus(String rideId, String status) async {
    try {
      await firestore.collection('ride_requests').doc(rideId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await realtimeDatabase.ref('ride_requests/$rideId').update({
        'status': status,
        'updatedAt': ServerValue.timestamp,
      });

      print('✅ Ride status updated to: $status');
    } catch (e) {
      print('❌ Error updating ride status: $e');
      rethrow;
    }
  }

  @override
  Future<LatLng> getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  @override
  Future<String> getAddressFromLatLng(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
      }
      return 'Unknown location';
    } catch (e) {
      throw Exception('Failed to get address: $e');
    }
  }

  @override
  Future<List<LatLng>> getRoutePoints(LatLng origin, LatLng destination) async {
    // This would typically use Google Directions API
    // For now, return a simple straight line
    return [origin, destination];
  }

  @override
  Future<User?> getCurrentUser() async {
    // This would get the current authenticated user
    // Implementation depends on your auth setup
    return null;
  }

  @override
  Future<void> updateUserLocation(String userId, LatLng location) async {
    try {
      await firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'currentLocation': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        'lastSeen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update user location: $e');
    }
  }

  @override
  Future<void> updateUserStatus(String userId, bool isOnline) async {
    try {
      await firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  @override
  Future<double> calculateFare(LatLng pickup, LatLng dropoff) async {
    try {
      final distance = Geolocator.distanceBetween(
        pickup.latitude,
        pickup.longitude,
        dropoff.latitude,
        dropoff.longitude,
      );

      final distanceKm = distance / 1000;
      final fare =
          AppConstants.baseFare + (distanceKm * AppConstants.perKmRate);

      return fare;
    } catch (e) {
      throw Exception('Failed to calculate fare: $e');
    }
  }
}
