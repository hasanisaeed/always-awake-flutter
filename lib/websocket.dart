import 'package:always_awake_flutter/utils.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '.env.dart';

class Websocket {
  WebSocketChannel? channel;

  Websocket({required String path, Map<String, dynamic>? params}) {
    // Convert the params Map into a URL query string if it's not null
    String queryString = params != null ? mapToQueryString(params) : "";

    String uriString = "$protocol://$host/$path" +
        (queryString.isNotEmpty ? "?$queryString" : "");

    channel = WebSocketChannel.connect(Uri.parse(uriString));
  }

  void disconnect() {
    channel?.sink.close(status.goingAway);
  }

  void listen(void Function(String message) onMessageReceived) {
    channel?.stream.listen(onMessageReceived as void Function(dynamic event)?);
  }

  void sendMessage(message) {
    if (message.isNotEmpty) {
      channel?.sink.add(message);
    }
  }

  bool isConnected() {
    return channel?.closeCode == null;
  }
}
