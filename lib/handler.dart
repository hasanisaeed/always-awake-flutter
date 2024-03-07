import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:always_awake_flutter/database/repository.dart';
import 'package:always_awake_flutter/services/location_service.dart';
import 'package:always_awake_flutter/services/websocket_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/intl.dart';

class CustomTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  late Websocket websocket = Websocket();
  final LocationService locationService = LocationService();
  final LocationRepository locationRepository = LocationRepository();

  int count = 1;

  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    log(">> Initialing task...");
    _sendPort = sendPort;
    _initWebsocket();
  }

  void _initWebsocket() {
    websocket = Websocket();

    _wsListen(
        _processWSResponse); // Listen to messages that came from the socket
  }

  void _wsListen(void Function(dynamic message) onMessageReceived) {
    websocket.listen((dynamic event) {
      Map<String, dynamic> jsonData = json.decode(event);
      onMessageReceived(jsonData);
    });
  }

  void _processWSResponse(dynamic data) {
    log(">> Received message: $data");

    final latitude = data['message']['latitude'].toString();
    final longitude = data['message']['longitude'].toString();
    final speed = data['message']['speed'].toString();
    final createdAt = data['message']['created_at'];

    switch (data['status']) {
      case 'success':
        locationRepository
            .deleteRecord(
                latitude: latitude,
                longitude: longitude,
                speed: speed,
                createdAt: createdAt)
            .then((_) => log(">> Record deleted successfully"))
            .catchError((error) => log(">> Error deleting record: $error"));
        break;
      case 'error':
        locationRepository
            .insertRecord(
                latitude: latitude,
                longitude: longitude,
                speed: speed,
                createdAt: createdAt)
            .then((_) => log(">> Record inserted successfully"))
            .catchError((error) => log(">> Error inserting record: $error"));
        break;
      default:
        log(">> Unknown action received in message.");
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    final locationData = await locationService.getCurrentLocation();
    if (locationData != null) {
      log(">> Current Location: (${locationData.latitude}, ${locationData.longitude})");
      FlutterForegroundTask.updateService(
        notificationTitle:
            'Current Location ($count): (${locationData.latitude}, ${locationData.longitude})',
      );

      final formattedTimestamp =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
      final locationMap = {
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
        'speed': locationData.speed,
        'created_at': formattedTimestamp.toString()
      };
      final hasInternetConnection = await checkInternetConnection();
      if (hasInternetConnection) {
        log(">> Send via websocket.");
        _initWebsocket();
        websocket.sendMessage(locationMap);
      } else {
        locationRepository
            .insertRecord(
              speed: locationMap['speed'].toString(),
              latitude: locationMap['latitude'].toString(),
              longitude: locationMap['longitude'].toString(),
              createdAt: locationMap['created_at'].toString(),
            )
            .then((_) => log(">> Record inserted successfully"))
            .catchError((error) => log(">> Error inserting record: $error"));
      }

      sendPort?.send(locationMap);
      count++;
    }
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {
    log('>> onDestroy called.');
    websocket.disconnect();
  }

  @override
  void onNotificationButtonPressed(String id) {
    log('>> onNotificationButtonPressed with ID: $id');
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp("/resume");
    _sendPort?.send('onNotificationPressed');
  }
}

Future<bool> checkInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException {
    return false;
  }
}
