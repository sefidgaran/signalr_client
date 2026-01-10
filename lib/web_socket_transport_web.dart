import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'ihub_protocol.dart';
import 'itransport.dart';
import 'web_socket_transport_stub.dart';

/// Web-specific WebSocket transport implementation.
/// Uses WebSocketChannel.connect which works in browsers.
/// Note: Custom headers are not supported on web platforms.
class WebSocketTransportWeb extends WebSocketTransportBase {
  WebSocketTransportWeb(
    AccessTokenFactory? accessTokenFactory,
    Logger? logger,
    bool logMessageContent,
    MessageHeaders? headers,
  ) : super(
          accessTokenFactory,
          logger,
          logMessageContent,
          headers,
          _createWebWebSocketChannel,
          useQueryParamAuth: true, // Web doesn't support headers
        );

  static Future<WebSocketChannel> _createWebWebSocketChannel(
    String url,
    Map<String, String> headers,
  ) async {
    // On web, we cannot set custom headers for WebSocket connections.
    // Headers parameter is ignored - authentication should be done via query params.
    return WebSocketChannel.connect(Uri.parse(url));
  }
}

/// Factory function to create the web-specific WebSocket transport.
WebSocketTransportBase createWebSocketTransport(
  AccessTokenFactory? accessTokenFactory,
  Logger? logger,
  bool logMessageContent,
  MessageHeaders? headers,
) {
  return WebSocketTransportWeb(
    accessTokenFactory,
    logger,
    logMessageContent,
    headers,
  );
}
