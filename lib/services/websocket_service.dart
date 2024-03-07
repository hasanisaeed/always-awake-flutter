import 'dart:convert';
import 'dart:developer';

import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../.env.dart';

class Websocket {
  WebSocketChannel? channel;

  Websocket() {
    try {
      channel = WebSocketChannel.connect(Uri.parse(WS_URL));
    } catch (e) {
      log(">> Could not connect to the websocket: $WS_URL");
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
