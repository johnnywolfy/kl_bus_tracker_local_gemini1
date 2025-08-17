// lib/src/core/services/gtfs_static_service.dart

import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import '../models/gtfs_models.dart';

// A container for all the parsed static GTFS data.
class GtfsData {
  final List<GtfsRoute> routes;
  final List<GtfsStop> stops;
  final List<GtfsTrip> trips;

  GtfsData({
    required this.routes,
    required this.stops,
    required this.trips,
  });
}

class GtfsStaticService {
  // **MODIFIED:** A list of all static data endpoints we need to fetch.
  static const List<String> _staticGtfsUrls = [
    'https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-kl',
    'https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-mrtfeeder',
  ];

  // Fetches, unzips, and parses the GTFS static data from all sources.
  Future<GtfsData> fetchGtfsData() async {
    // Use Future.wait to fetch all URLs in parallel for better performance.
    final responses = await Future.wait(
        _staticGtfsUrls.map((url) => http.get(Uri.parse(url))));

    final allRoutes = <GtfsRoute>[];
    final allTrips = <GtfsTrip>[];
    // Use a Map for stops to automatically handle duplicates across files.
    final allStops = <String, GtfsStop>{};

    for (final response in responses) {
      if (response.statusCode == 200) {
        print('Download complete. Unzipping and parsing...');
        final archive = ZipDecoder().decodeBytes(response.bodyBytes);

        // Parse each file and add its contents to our combined lists.
        allRoutes.addAll(_parseCsvFile(
            archive, 'routes.txt', (row) => GtfsRoute.fromCsv(row)));
        allTrips.addAll(
            _parseCsvFile(archive, 'trips.txt', (row) => GtfsTrip.fromCsv(row)));
        
        final stops = _parseCsvFile(
            archive, 'stops.txt', (row) => GtfsStop.fromCsv(row));
        for (final stop in stops) {
          allStops[stop.stopId] = stop;
        }
      } else {
        throw Exception(
            'Failed to load GTFS data: Status code ${response.statusCode} from ${response.request?.url}');
      }
    }

    print('All static data parsing complete!');
    return GtfsData(
      routes: allRoutes,
      stops: allStops.values.toList(), // Convert the map values back to a list.
      trips: allTrips,
    );
  }

  // A generic helper function to find a file in the archive, decode it,
  // and parse its CSV content into a list of model objects.
  List<T> _parseCsvFile<T>(
      Archive archive, String fileName, T Function(List<String>) fromCsv) {
    final file = archive.findFile(fileName);
    if (file == null) {
      print('Warning: $fileName not found in an archive. Skipping.');
      return []; // Return an empty list if a file (like shapes.txt) is missing.
    }

    // Decode the file content from UTF-8.
    final csvString = utf8.decode(file.content);
    final lines = csvString.split('\n');

    final List<T> results = [];
    // Skip the header row (the first line).
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        // Simple CSV parsing by splitting on commas.
        final values = line.split(',');
        results.add(fromCsv(values));
      }
    }
    return results;
  }
}
