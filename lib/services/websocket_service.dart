import 'dart:convert';
import 'dart:developer';

import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../.env.dart';

class Websocket {
  WebSocketChannel? channel;

  Websocket({required String path, Map<String, dynamic>? params}) {
    // Convert the params Map into a URL query string if it's not null
    String queryString = params != null ? _mapToQueryString(params) : "";

    String uriString = "$protocol://$host/$path" +
        (queryString.isNotEmpty ? "?$queryString" : "");

    try {
      channel = WebSocketChannel.connect(Uri.parse(uriString));
    } catch (e) {
      log(">> Could not connect to the websocket: $uriString");
    }
  }

  void disconnect() {
    channel?.sink.close(status.goingAway);
  }

  void listen(void Function(String message) onMessageReceived) {
    channel?.stream.listen(onMessageReceived as void Function(dynamic event)?);
  }

  void sendMessage(dynamic message) {
    // Check if the message needs to be encoded to JSON
    final String messageToSend =
        message is String ? message : json.encode(message);

    if (messageToSend.isNotEmpty) {
      channel?.sink.add(messageToSend);
    }
  }

  bool isConnected() {
    return channel?.closeCode == null;
  }
}

/// Helper function to convert Map<String, dynamic> to a query string
String _mapToQueryString(Map<String, dynamic> params) {
  return params.entries
      .map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
      .join('&');
}
