// lib/src/core/models/gtfs_models.dart

// A simple data model for a bus route, based on routes.txt from GTFS.
class GtfsRoute {
  final String routeId;
  final String routeShortName;
  final String routeLongName;

  GtfsRoute({
    required this.routeId,
    required this.routeShortName,
    required this.routeLongName,
  });

  // A factory constructor to create a GtfsRoute from a CSV row (represented as a list of strings).
  factory GtfsRoute.fromCsv(List<String> csvRow) {
    // Defensive check to ensure the row has enough columns.
    if (csvRow.length < 4) {
      // Return a default/empty route or handle the error as appropriate.
      return GtfsRoute(routeId: 'error', routeShortName: 'Invalid', routeLongName: 'Invalid Data');
    }
    return GtfsRoute(
      routeId: csvRow[0],
      routeShortName: csvRow[2],
      routeLongName: csvRow[3],
    );
  }

  @override
  String toString() {
    return 'Route: $routeShortName ($routeLongName)';
  }
}

// A simple data model for a bus stop, based on stops.txt from GTFS.
class GtfsStop {
  final String stopId;
  final String stopName;
  final double stopLat;
  final double stopLon;

  GtfsStop({
    required this.stopId,
    required this.stopName,
    required this.stopLat,
    required this.stopLon,
  });

  // A factory constructor to create a GtfsStop from a CSV row.
  factory GtfsStop.fromCsv(List<String> csvRow) {
    // **FIX:** Add a defensive check for the number of columns before accessing them.
    // The error occurs when a row has fewer than 6 columns.
    if (csvRow.length < 6) {
       // If the row is malformed, create a Stop object with default values.
      return GtfsStop(
        stopId: csvRow.isNotEmpty ? csvRow[0] : 'unknown',
        stopName: 'Invalid Stop Data',
        stopLat: 0.0,
        stopLon: 0.0,
      );
    }
    return GtfsStop(
      stopId: csvRow[0],
      stopName: csvRow[2],
      stopLat: double.tryParse(csvRow[4]) ?? 0.0,
      stopLon: double.tryParse(csvRow[5]) ?? 0.0,
    );
  }
}

// A simple data model for a trip, based on trips.txt from GTFS.
// This links a route to a specific journey.
class GtfsTrip {
  final String routeId;
  final String tripId;
  final String tripHeadsign;

  GtfsTrip({
    required this.routeId,
    required this.tripId,
    required this.tripHeadsign,
  });

  // A factory constructor to create a GtfsTrip from a CSV row.
  factory GtfsTrip.fromCsv(List<String> csvRow) {
    // Defensive check to ensure the row has enough columns.
    if (csvRow.length < 4) {
      return GtfsTrip(routeId: 'error', tripId: 'error', tripHeadsign: 'Invalid Data');
    }
    return GtfsTrip(
      routeId: csvRow[0],
      tripId: csvRow[2],
      tripHeadsign: csvRow[3],
    );
  }
}

// A new model to represent a single, live vehicle from the realtime feed.
class VehiclePosition {
  final String vehicleId;
  final String tripId;
  final String routeId;
  final double latitude;
  final double longitude;
  final double? speed; // Speed is optional in the feed
  final int timestamp;

  VehiclePosition({
    required this.vehicleId,
    required this.tripId,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    this.speed,
    required this.timestamp,
  });

   @override
  String toString() {
    return 'Vehicle $vehicleId on route $routeId at ($latitude, $longitude)';
  }
}
