import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/ride/data/datasources/ride_remote_datasource.dart';
import 'features/ride/data/repositories/ride_repository_impl.dart';
import 'features/ride/domain/usecases/create_ride_request.dart';
import 'features/ride/domain/usecases/accept_ride_request.dart';
import 'features/ride/domain/usecases/update_ride_status.dart';
import 'features/ride/presentation/bloc/ride_bloc.dart';
import 'features/ride/presentation/pages/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create repository instances once
    final remoteDataSource = RideRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
      realtimeDatabase: FirebaseDatabase.instance,
    );
    
    final repository = RideRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    return BlocProvider(
      // Provide RideBloc at the app level so it's available everywhere
      create: (context) => RideBloc(
        createRideRequest: CreateRideRequest(repository),
        acceptRideRequest: AcceptRideRequest(repository),
        updateRideStatus: UpdateRideStatus(repository),
        rideRepository: repository,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ride Sharing App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: GoogleFonts.robotoTextTheme(),
          useMaterial3: true,
        ),
        home: const RoleSelectionScreen(),
      ),
    );
  }
}

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String _selectedRole = 'PASSENGER';
  final TextEditingController _userIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userIdController.text = 'user_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Ride Sharing App'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_taxi,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 32),
            const Text(
              'Welcome to Ride Sharing App',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Select your role to continue',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'User ID',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _userIdController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter your user ID',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Role',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text(
                              'Passenger',
                              style: TextStyle(fontSize: 12.0),
                            ),
                            value: 'PASSENGER',
                            groupValue: _selectedRole,
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text(
                              'Driver',
                              style: TextStyle(fontSize: 12.0),
                            ),
                            value: 'DRIVER',
                            groupValue: _selectedRole,
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _navigateToMap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMap() {
    if (_userIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a user ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Simply navigate - BLoC is already provided at app level
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          userRole: _selectedRole,
          userId: _userIdController.text.trim(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }
}