class AppConstants {
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String rideRequestsCollection = 'ride_requests';
  static const String driversCollection = 'drivers';
  
  // Ride Status
  static const String statusRequested = 'REQUESTED';
  static const String statusPending = 'PENDING';
  static const String statusAccepted = 'ACCEPTED';
  static const String statusArrived = 'ARRIVED';
  static const String statusStarted = 'STARTED';
  static const String statusFinished = 'FINISHED';
  static const String statusCancelled = 'CANCELLED';
  static const String initialRideStatus = statusPending; // or statusRequested

  // User Roles
  static const String rolePassenger = 'PASSENGER';
  static const String roleDriver = 'DRIVER';
  
  // Map Constants
  static const double defaultZoom = 15.0;
  static const double driverZoom = 18.0;
  
  // Location Constants
  static const double locationUpdateInterval = 5.0; // seconds
  static const double locationAccuracy = 10.0; // meters
  
  // Fare Calculation
  static const double baseFare = 2.0;
  static const double perKmRate = 1.5;
  static const double perMinuteRate = 0.3;
}
