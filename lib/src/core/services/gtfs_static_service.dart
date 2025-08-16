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
  // The official API endpoint for RapidKL and GoKL static data.
  static const String _staticGtfsUrl =
      'https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-kl';

  // Fetches, unzips, and parses the GTFS static data.
  Future<GtfsData> fetchGtfsData() async {
    try {
      print('Fetching GTFS static data from $_staticGtfsUrl...');
      final response = await http.get(Uri.parse(_staticGtfsUrl));

      if (response.statusCode == 200) {
        print('Download complete. Unzipping and parsing...');
        // Use the 'archive' package to decode the zip file from the response bytes.
        final archive = ZipDecoder().decodeBytes(response.bodyBytes);

        // Parse each required file from the archive.
        final routes = _parseCsvFile(archive, 'routes.txt', (row) => GtfsRoute.fromCsv(row));
        final stops = _parseCsvFile(archive, 'stops.txt', (row) => GtfsStop.fromCsv(row));
        final trips = _parseCsvFile(archive, 'trips.txt', (row) => GtfsTrip.fromCsv(row));

        print('Parsing complete!');
        return GtfsData(routes: routes, stops: stops, trips: trips);
      } else {
        // Handle server errors.
        throw Exception('Failed to load GTFS data: Status code ${response.statusCode}');
      }
    } catch (e) {
      // Handle network or other errors.
      print('An error occurred in fetchGtfsData: $e');
      rethrow;
    }
  }

  // A generic helper function to find a file in the archive, decode it,
  // and parse its CSV content into a list of model objects.
  List<T> _parseCsvFile<T>(
      Archive archive, String fileName, T Function(List<String>) fromCsv) {
    final file = archive.findFile(fileName);
    if (file == null) {
      throw Exception('$fileName not found in the archive.');
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
        // Note: This is a basic implementation and might fail on complex CSVs with quoted commas.
        // For this GTFS data, it's sufficient.
        final values = line.split(',');
        results.add(fromCsv(values));
      }
    }
    return results;
  }
}
