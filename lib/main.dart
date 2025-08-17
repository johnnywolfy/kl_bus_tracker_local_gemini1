import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kl_bus_tracker_local_gemini1/src/core/models/gtfs_models.dart';
import 'package:kl_bus_tracker_local_gemini1/src/core/services/gtfs_realtime_service.dart';
import 'package:kl_bus_tracker_local_gemini1/src/core/services/gtfs_static_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: const TrackingScreen(),
    );
  }
}

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  // Services for fetching data
  final GtfsStaticService _gtfsStaticService = GtfsStaticService();
  final GtfsRealtimeService _gtfsRealtimeService = GtfsRealtimeService();

  // Map and location state
  GoogleMapController? _mapController;
  static const LatLng _kualaLumpurCenter = LatLng(3.1390, 101.6869);
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: _kualaLumpurCenter,
    zoom: 12,
  );

  // App state
  String? _error;
  bool _isStaticDataLoading = true; // Initially loading static data
  Timer? _realtimeDataTimer;

  // Data storage
  GtfsData? _gtfsData;
  List<GtfsRoute> _filteredRoutes = [];
  GtfsRoute? _selectedRoute;
  // **FIX:** Store the trip IDs for the selected route for more reliable matching.
  Set<String> _selectedRouteTripIds = {};
  final Set<Marker> _busMarkers = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  // Clean up the timer when the widget is removed
  @override
  void dispose() {
    _realtimeDataTimer?.cancel();
    super.dispose();
  }

  // Initial setup function
  Future<void> _initialize() async {
    await _determinePosition();
    await _fetchStaticData();
  }

  // Get user's location
  Future<void> _determinePosition() async {
    // ... (Location logic remains the same as in Step 4)
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _error = 'Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _error = 'Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _error = 'Location permissions are permanently denied.');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final newPos = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 15,
      );
      setState(() => _initialCameraPosition = newPos);
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(newPos));
    } catch (e) {
      setState(() => _error = "Failed to get location: $e");
    }
  }

  // Fetch the static GTFS data once
  Future<void> _fetchStaticData() async {
    try {
      final data = await _gtfsStaticService.fetchGtfsData();
      
      // --- Add this block for debugging ---
      print('--- AVAILABLE BUS ROUTES ---');
      // Sort routes alphabetically by their short name for easier reading
      data.routes.sort((a, b) => a.routeShortName.compareTo(b.routeShortName));
      for (final route in data.routes) {
        print('${route.routeShortName.padRight(10)} | ${route.routeLongName}');
      }
      print('--- END OF ROUTE LIST ---');
      // --- End of debugging block ---

      setState(() {
        _gtfsData = data;
        _filteredRoutes = data.routes; // Initially show all routes
        _isStaticDataLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load static data: $e";
        _isStaticDataLoading = false;
      });
    }
  }
  
  // Filter routes based on search input
  void _onSearchChanged(String query) {
    if (_gtfsData == null) return;

    if (query.isEmpty) {
      setState(() => _filteredRoutes = _gtfsData!.routes);
    } else {
      setState(() {
        _filteredRoutes = _gtfsData!.routes
            .where((route) =>
                route.routeShortName.toLowerCase().contains(query.toLowerCase()) ||
                route.routeLongName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  // Handle when a user selects a route from the search results
  void _onRouteSelected(GtfsRoute route) {
    if (_gtfsData == null) return;

    // **FIX:** Find all trip IDs associated with the selected route.
    final tripIds = _gtfsData!.trips
        .where((trip) => trip.routeId == route.routeId)
        .map((trip) => trip.tripId)
        .toSet();

    setState(() {
      _selectedRoute = route;
      _selectedRouteTripIds = tripIds;
      _filteredRoutes = []; // Hide search results
      _busMarkers.clear(); // Clear old markers
    });
    
    // Cancel any existing timer
    _realtimeDataTimer?.cancel();
    // Start fetching realtime data immediately, then every 30 seconds
    _fetchRealtimeData();
    _realtimeDataTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchRealtimeData();
    });
  }
  
  // Fetch live bus data and update map markers
  Future<void> _fetchRealtimeData() async {
    if (_selectedRoute == null) return;
    
    print("Fetching realtime data for route: ${_selectedRoute!.routeShortName}");

    try {
      final vehiclePositions = await _gtfsRealtimeService.fetchVehiclePositions();
      
      // **FIX:** Filter vehicles by checking if their tripId is in our set of valid trip IDs.
      final vehiclesForRoute = vehiclePositions
          .where((v) => _selectedRouteTripIds.contains(v.tripId))
          .toList();
      
      final newMarkers = <Marker>{};
      for (final vehicle in vehiclesForRoute) {
        newMarkers.add(
          Marker(
            markerId: MarkerId(vehicle.vehicleId),
            position: LatLng(vehicle.latitude, vehicle.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
              title: 'Bus on route ${_selectedRoute!.routeShortName}',
              snippet: 'Vehicle ID: ${vehicle.vehicleId}',
            ),
          ),
        );
      }
      
      setState(() => _busMarkers.addAll(newMarkers));

    } catch (e) {
      // Handle error without stopping the timer
      print("Error fetching realtime data: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _busMarkers, // Display the bus markers on the map
          ),
          // Search Bar
          Positioned(
            top: 50,
            left: 15,
            right: 15,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for a bus route (e.g., T580)',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                // Search Results List
                if (_filteredRoutes.isNotEmpty && _filteredRoutes.length != _gtfsData?.routes.length)
                  Container(
                    height: 200,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListView.builder(
                      itemCount: _filteredRoutes.length,
                      itemBuilder: (context, index) {
                        final route = _filteredRoutes[index];
                        return ListTile(
                          title: Text(route.routeShortName),
                          subtitle: Text(route.routeLongName),
                          onTap: () => _onRouteSelected(route),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Loading Indicator for initial static data load
          if (_isStaticDataLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Loading route data...", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
