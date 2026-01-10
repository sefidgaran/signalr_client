import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'ihub_protocol.dart';
import 'itransport.dart';
import 'web_socket_transport_stub.dart';

/// IO-specific WebSocket transport implementation.
/// Uses dart:io WebSocket which supports custom headers.
class WebSocketTransportIO extends WebSocketTransportBase {
  WebSocketTransportIO(
    AccessTokenFactory? accessTokenFactory,
    Logger? logger,
    bool logMessageContent,
    MessageHeaders? headers,
  ) : super(
          accessTokenFactory,
          logger,
          logMessageContent,
          headers,
          _createIOWebSocketChannel,
          useQueryParamAuth: false, // IO supports headers
        );

  static Future<WebSocketChannel> _createIOWebSocketChannel(
    String url,
    Map<String, String> headers,
  ) async {
    final webSocket = await io.WebSocket.connect(url, headers: headers);
    return IOWebSocketChannel(webSocket);
  }
}

/// Factory function to create the IO-specific WebSocket transport.
WebSocketTransportBase createWebSocketTransport(
  AccessTokenFactory? accessTokenFactory,
  Logger? logger,
  bool logMessageContent,
  MessageHeaders? headers,
) {
  return WebSocketTransportIO(
    accessTokenFactory,
    logger,
    logMessageContent,
    headers,
  );
}
