// lib/src/core/services/gtfs_realtime_service.dart

import 'package:http/http.dart' as http;
import '../models/gtfs_models.dart';
// **FIX:** Import the generated Dart code with a prefix 'pb' to avoid name conflicts.
import 'generated/gtfs-realtime.pb.dart' as pb;

class GtfsRealtimeService {
  // The official API endpoint for RapidKL and GoKL realtime data.
  static const String _realtimeGtfsUrl =
      'https://api.data.gov.my/gtfs-realtime/vehicle-position/prasarana?category=rapid-bus-kl';

  // Fetches and parses the GTFS-Realtime vehicle positions.
  Future<List<VehiclePosition>> fetchVehiclePositions() async {
    try {
      print('Fetching GTFS-Realtime data from $_realtimeGtfsUrl...');
      final response = await http.get(Uri.parse(_realtimeGtfsUrl));

      if (response.statusCode == 200) {
        // The response body is a binary buffer.
        // **FIX:** Use the prefixed 'pb.FeedMessage' class to parse it.
        final feed = pb.FeedMessage.fromBuffer(response.bodyBytes);

        final List<VehiclePosition> vehiclePositions = [];

        // Iterate through each 'entity' in the feed.
        for (final entity in feed.entity) {
          // We only care about entities that have vehicle position data.
          if (entity.hasVehicle()) {
            final vehicle = entity.vehicle;
            // **FIX:** Create an instance of our *custom* VehiclePosition model,
            // not the one from the generated file. This resolves the function call error.
            vehiclePositions.add(
              VehiclePosition(
                vehicleId: vehicle.vehicle.id,
                tripId: vehicle.trip.tripId,
                routeId: vehicle.trip.routeId,
                latitude: vehicle.position.latitude,
                longitude: vehicle.position.longitude,
                speed: vehicle.position.hasSpeed() ? vehicle.position.speed : null,
                timestamp: vehicle.timestamp.toInt(),
              ),
            );
          }
        }
        print('Successfully parsed ${vehiclePositions.length} active vehicles.');
        return vehiclePositions;
      } else {
        throw Exception('Failed to load GTFS-Realtime data: Status code ${response.statusCode}');
      }
    } catch (e) {
      print('An error occurred in fetchVehiclePositions: $e');
      rethrow;
    }
  }
}
