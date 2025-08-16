import 'package:flutter/material.dart';
import 'src/core/models/gtfs_models.dart';
import 'src/core/services/gtfs_realtime_service.dart';
import 'src/core/services/gtfs_static_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KL Bus Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Instances of our services.
  final GtfsStaticService _gtfsStaticService = GtfsStaticService();
  final GtfsRealtimeService _gtfsRealtimeService = GtfsRealtimeService();

  // State variables
  bool _isLoading = false;
  String? _error;
  GtfsData? _gtfsData;
  List<VehiclePosition>? _vehiclePositions;

  // Fetch static data
  void _fetchStaticData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _gtfsStaticService.fetchGtfsData();
      setState(() {
        _gtfsData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Fetch realtime data
  void _fetchRealtimeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _gtfsRealtimeService.fetchVehiclePositions();
      setState(() {
        _vehiclePositions = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KL Bus Tracker Data Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Display Area
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_error != null)
                Text('Error: $_error', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)
              else
                Column(
                  children: [
                    if (_gtfsData == null && _vehiclePositions == null)
                      const Text('Press a button to fetch data.'),
                    if (_gtfsData != null)
                      Text(
                        'Static Data Loaded:\n'
                        '${_gtfsData!.routes.length} routes\n'
                        '${_gtfsData!.stops.length} stops\n'
                        '${_gtfsData!.trips.length} trips',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    if (_vehiclePositions != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Realtime Data Loaded:\n'
                        '${_vehiclePositions!.length} active buses found.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.green),
                      ),
                    ]
                  ],
                ),
              const SizedBox(height: 30),
              // Buttons
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchStaticData,
                icon: const Icon(Icons.download_for_offline),
                label: const Text('Fetch Static Data'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchRealtimeData,
                icon: const Icon(Icons.track_changes),
                label: const Text('Fetch Realtime Data'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, 
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
