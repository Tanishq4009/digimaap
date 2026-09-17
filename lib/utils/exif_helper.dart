import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_exif/native_exif.dart';

export 'package:geolocator/geolocator.dart' show Position;

/// Gets the current device GPS position, handling permissions gracefully.
Future<Position?> getCurrentDeviceLocation() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled on device.');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 8),
      ),
    );
  } catch (e) {
    debugPrint('Error getting current location: $e');
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }
}

/// Writes GPS latitude and longitude into the image's EXIF metadata.
Future<bool> writeGeoLocationToImage(
  String imagePath,
  double latitude,
  double longitude,
) async {
  Exif? exif;
  try {
    exif = await Exif.fromPath(imagePath);
    await exif.writeAttributes({
      'GPSLatitude': latitude,
      'GPSLongitude': longitude,
    });
    return true;
  } catch (e) {
    debugPrint("Error writing GPS to EXIF: $e");
    return false;
  } finally {
    await exif?.close();
  }
}

/// Reads EXIF metadata using native iOS/Android APIs and extracts GPS latitude and longitude.
Future<Map<String, double?>?> getGeoLocationFromImage(String imagePath) async {
  Exif? exif;
  try {
    exif = await Exif.fromPath(imagePath);
    final latLong = await exif.getLatLong();

    if (latLong == null) {
      debugPrint("GPS metadata is missing from the image.");
      return null;
    }

    return {
      'latitude': latLong.latitude,
      'longitude': latLong.longitude,
    };
  } catch (e) {
    debugPrint("Error reading EXIF with native_exif: $e");
    return null;
  } finally {
    await exif?.close();
  }
}

/// Helper to get the original date and time from EXIF metadata.
Future<DateTime?> getImageOriginalDate(String imagePath) async {
  Exif? exif;
  try {
    exif = await Exif.fromPath(imagePath);
    return await exif.getOriginalDate();
  } catch (e) {
    debugPrint("Error reading date from EXIF: $e");
    return null;
  } finally {
    await exif?.close();
  }
}
