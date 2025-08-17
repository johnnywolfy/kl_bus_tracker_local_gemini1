// lib/src/core/services/gtfs_realtime_service.dart

import 'package:http/http.dart' as http;
import '../models/gtfs_models.dart';
import 'generated/gtfs-realtime.pb.dart' as pb;

class GtfsRealtimeService {
  // **MODIFIED:** A list of all realtime data endpoints.
  static const List<String> _realtimeGtfsUrls = [
    'https://api.data.gov.my/gtfs-realtime/vehicle-position/prasarana?category=rapid-bus-kl',
    'https://api.data.gov.my/gtfs-realtime/vehicle-position/prasarana?category=rapid-bus-mrtfeeder',
  ];

  // Fetches and parses the GTFS-Realtime vehicle positions from all sources.
  Future<List<VehiclePosition>> fetchVehiclePositions() async {
    // Fetch all URLs in parallel.
    final responses = await Future.wait(
        _realtimeGtfsUrls.map((url) => http.get(Uri.parse(url))));

    final allVehiclePositions = <VehiclePosition>[];

    for (final response in responses) {
      if (response.statusCode == 200) {
        final feed = pb.FeedMessage.fromBuffer(response.bodyBytes);

        for (final entity in feed.entity) {
          if (entity.hasVehicle()) {
            final vehicle = entity.vehicle;
            allVehiclePositions.add(
              VehiclePosition(
                vehicleId: vehicle.vehicle.id,
                tripId: vehicle.trip.tripId,
                routeId: vehicle.trip.routeId,
                latitude: vehicle.position.latitude,
                longitude: vehicle.position.longitude,
                speed:
                    vehicle.position.hasSpeed() ? vehicle.position.speed : null,
                timestamp: vehicle.timestamp.toInt(),
              ),
            );
          }
        }
      } else {
        // Log an error but don't stop the process, so if one feed is down, the other might still work.
        print(
            'Failed to load GTFS-Realtime data from ${response.request?.url}: Status code ${response.statusCode}');
      }
    }

    print(
        'Successfully parsed ${allVehiclePositions.length} active vehicles from all sources.');
    return allVehiclePositions;
  }
}
