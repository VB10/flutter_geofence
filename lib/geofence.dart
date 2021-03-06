import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_geofence/Geolocation.dart';

export 'Geolocation.dart';

typedef void GeofenceCallback(Geolocation foo);

class Coordinate {
  final double latitude;
  final double longitude;

  Coordinate(this.latitude, this.longitude);
}

class Geofence {
  static const MethodChannel _channel = const MethodChannel('geofence');

  static GeofenceCallback _entryCallback;
  static GeofenceCallback _exitCallback;

  //ignore: close_sinks
  static StreamController<Coordinate> _userLocationUpdated =
      new StreamController<Coordinate>();
  static Stream<Coordinate> _broadcastLocationStream;

  /// Adds a geolocation for a certain geo-event
  static Future<void> addGeolocation(
      Geolocation geolocation, GeolocationEvent event) {
    return _channel.invokeMethod("addRegion", {
      "lng": geolocation.longitude,
      "lat": geolocation.latitude,
      "id": geolocation.id,
      "radius": geolocation.radius,
      "event": event.toString(),
    });
  }

  /// Stops listening to a geolocation for a certain geo-event
  static Future<void> removeGeolocation(Geolocation geolocation, GeolocationEvent event) {
    return _channel.invokeMethod("removeRegion", {
      "lng": geolocation.longitude,
      "lat": geolocation.latitude,
      "id": geolocation.id,
      "radius": geolocation.radius,
      "event": event.toString(),
    });
  }

  /// Get the latest location the user has been.
  static Future<Coordinate> getCurrentLocation() async {
    _channel.invokeMethod("getUserLocation", null);
    return _broadcastLocationStream.first;
  }

  static void requestPermissions() {
    _channel.invokeMethod("requestPermissions", null);
  }

  /// Startup; needed to setup all callbacks and prevent race-issues.
  static void initialize() {
    var completer = new Completer<void>();
    _broadcastLocationStream = _userLocationUpdated.stream.asBroadcastStream();
    _channel.setMethodCallHandler((call) async {
      if (call.method == "entry") {
        Geolocation location = Geolocation(
            latitude: call.arguments["latitude"] as double,
            longitude: call.arguments["longitude"] as double,
            radius: call.arguments["radius"] as double,
            id: call.arguments["id"] as String);
        _entryCallback(location);
      } else if (call.method == "exit") {
        Geolocation location = Geolocation(
            latitude: call.arguments["latitude"] as double,
            longitude: call.arguments["longitude"] as double,
            radius: call.arguments["radius"] as double,
            id: call.arguments["id"] as String);
        _exitCallback(location);
      } else if (call.method == "userLocationUpdated") {
        Coordinate coordinate =
            Coordinate(call.arguments["lat"], call.arguments["lng"]);
        _userLocationUpdated.sink.add(coordinate);
      }
      completer.complete();
    });
  }

  /// Set a callback block for a specific geo-event
  static void startListening(GeolocationEvent event, GeofenceCallback entry) {
    switch (event) {
      case GeolocationEvent.entry:
        _entryCallback = entry;
        break;
      case GeolocationEvent.exit:
        _exitCallback = entry;
        break;
    }
  }
}
